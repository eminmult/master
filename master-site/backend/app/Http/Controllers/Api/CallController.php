<?php

namespace App\Http\Controllers\Api;

use App\Events\CallSignal;
use App\Http\Controllers\Controller;
use App\Models\Call;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CallController extends Controller
{
    /**
     * Statuses during which both parties may initiate an in-app voice call.
     * Phones are never shown to either party — calling is the only direct channel.
     */
    private const CALLABLE_ORDER_STATUSES = [
        Order::STATUS_CONFIRMED,
        Order::STATUS_ACCEPTED,
        Order::STATUS_ON_THE_WAY,
        Order::STATUS_ARRIVED,
        Order::STATUS_IN_PROGRESS,
        Order::STATUS_AWAITING_COMPLETION,
    ];

    /**
     * POST /api/calls
     * Initiate a call. Body: { order_id, callee_id, sdp? (offer) }
     * Returns the call envelope and broadcasts call.ringing to the callee.
     */
    public function initiate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'order_id'  => 'required|integer|exists:orders,id',
            'callee_id' => 'required|integer|exists:users,id',
            'sdp'       => 'nullable|array', // RTCSessionDescription offer
        ]);

        $userId = $request->user()->id;
        $order  = Order::findOrFail($data['order_id']);

        $this->ensureCanCall($order, $userId, (int) $data['callee_id']);

        $call = DB::transaction(function () use ($order, $userId, $data) {
            // Block parallel calls on the same order.
            $active = Call::where('order_id', $order->id)
                ->whereIn('status', Call::ACTIVE_STATUSES)
                ->lockForUpdate()
                ->first();
            if ($active) {
                abort(409, 'Another call is already active on this order');
            }
            return Call::create([
                'order_id'   => $order->id,
                'caller_id'  => $userId,
                'callee_id'  => (int) $data['callee_id'],
                'status'     => Call::STATUS_RINGING,
                'started_at' => now(),
            ]);
        });

        CallSignal::fire($call, $call->callee_id, 'ringing', [
            'order_id'  => $order->id,
            'caller_id' => $userId,
            'caller'    => $this->userBrief($request->user()),
            'sdp'       => $data['sdp'] ?? null,
        ]);

        return response()->json(['call' => $this->present($call)], 201);
    }

    /**
     * POST /api/calls/{call}/accept
     * Body: { sdp } — RTCSessionDescription answer.
     */
    public function accept(Request $request, Call $call): JsonResponse
    {
        $this->ensureParty($request, $call, asCallee: true);
        if ($call->status !== Call::STATUS_RINGING) {
            abort(409, 'Call is not in ringing state');
        }
        $data = $request->validate(['sdp' => 'required|array']);

        $call->update([
            'status'      => Call::STATUS_ACCEPTED,
            'accepted_at' => now(),
        ]);

        CallSignal::fire($call, $call->caller_id, 'accepted', [
            'sdp' => $data['sdp'],
        ]);

        return response()->json(['call' => $this->present($call)]);
    }

    /**
     * POST /api/calls/{call}/reject
     */
    public function reject(Request $request, Call $call): JsonResponse
    {
        $this->ensureParty($request, $call, asCallee: true);
        if ($call->status !== Call::STATUS_RINGING) {
            abort(409, 'Call is not in ringing state');
        }
        $call->update([
            'status'     => Call::STATUS_REJECTED,
            'ended_at'   => now(),
            'end_reason' => 'rejected',
        ]);
        CallSignal::fire($call, $call->caller_id, 'rejected', []);
        return response()->json(['call' => $this->present($call)]);
    }

    /**
     * POST /api/calls/{call}/end
     * Either party may end. If still ringing and caller hangs up → cancelled.
     */
    public function end(Request $request, Call $call): JsonResponse
    {
        $userId = $request->user()->id;
        if (!in_array($userId, [$call->caller_id, $call->callee_id], true)) {
            abort(403);
        }
        if (!$call->isActive()) {
            return response()->json(['call' => $this->present($call)]);
        }
        $reason = $call->status === Call::STATUS_RINGING
            ? ($userId === $call->caller_id ? 'cancelled' : 'rejected')
            : 'ended';
        $finalStatus = $call->status === Call::STATUS_RINGING
            ? ($userId === $call->caller_id ? Call::STATUS_CANCELLED : Call::STATUS_REJECTED)
            : Call::STATUS_ENDED;
        $duration = $call->accepted_at ? max(0, now()->diffInSeconds($call->accepted_at)) : null;

        $call->update([
            'status'       => $finalStatus,
            'ended_at'     => now(),
            'end_reason'   => $reason,
            'duration_sec' => $duration,
        ]);

        $other = $userId === $call->caller_id ? $call->callee_id : $call->caller_id;
        CallSignal::fire($call, $other, $finalStatus === Call::STATUS_CANCELLED ? 'cancelled' : ($finalStatus === Call::STATUS_REJECTED ? 'rejected' : 'ended'), [
            'duration_sec' => $duration,
        ]);

        return response()->json(['call' => $this->present($call)]);
    }

    /**
     * POST /api/calls/{call}/signal
     * Relay WebRTC signaling payload (offer, answer, ICE candidate) to the other party.
     * Body: { type: 'offer'|'answer'|'ice', payload: {...} }
     */
    public function signal(Request $request, Call $call): JsonResponse
    {
        $userId = $request->user()->id;
        if (!in_array($userId, [$call->caller_id, $call->callee_id], true)) {
            abort(403);
        }
        $data = $request->validate([
            'type'    => 'required|string|in:offer,answer,ice',
            'payload' => 'required|array',
        ]);
        $other = $userId === $call->caller_id ? $call->callee_id : $call->caller_id;
        CallSignal::fire($call, $other, $data['type'], $data['payload']);
        return response()->json(['ok' => true]);
    }

    /**
     * GET /api/calls/{call}
     */
    public function show(Request $request, Call $call): JsonResponse
    {
        $userId = $request->user()->id;
        if (!in_array($userId, [$call->caller_id, $call->callee_id], true)) {
            abort(403);
        }
        return response()->json(['call' => $this->present($call->load(['caller', 'callee']))]);
    }

    /**
     * GET /api/calls?order_id=&limit=
     * History for the current user (optionally scoped to one order).
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $q = Call::query()
            ->where(function ($q) use ($userId) {
                $q->where('caller_id', $userId)->orWhere('callee_id', $userId);
            })
            ->with(['caller', 'callee'])
            ->orderByDesc('id');
        if ($oid = (int) $request->query('order_id', 0)) {
            $q->where('order_id', $oid);
        }
        $items = $q->limit(min(50, (int) $request->query('limit', 20)))->get();
        return response()->json(['calls' => $items->map(fn ($c) => $this->present($c))->values()]);
    }

    // ---------- helpers ----------

    private function ensureCanCall(Order $order, int $userId, int $calleeId): void
    {
        // Order must be live and parties must match.
        if (!in_array($order->status, self::CALLABLE_ORDER_STATUSES, true)) {
            abort(403, 'In-app calls are available only after the order is confirmed');
        }
        $parties = array_filter([$order->client_id, $order->master_id]);
        if (!in_array($userId, $parties, true) || !in_array($calleeId, $parties, true) || $userId === $calleeId) {
            abort(403, 'Only the order parties may call each other');
        }
    }

    private function ensureParty(Request $request, Call $call, bool $asCallee = false): void
    {
        $userId = $request->user()->id;
        if ($asCallee ? $userId !== $call->callee_id : !in_array($userId, [$call->caller_id, $call->callee_id], true)) {
            abort(403);
        }
    }

    private function userBrief($u): array
    {
        return [
            'id'         => $u->id,
            'first_name' => $u->first_name,
            'last_name'  => $u->last_name,
            'avatar_url' => $u->avatar_url,
        ];
    }

    private function present(Call $call): array
    {
        return [
            'id'           => $call->id,
            'order_id'     => $call->order_id,
            'caller_id'    => $call->caller_id,
            'callee_id'    => $call->callee_id,
            'status'       => $call->status,
            'started_at'   => optional($call->started_at)->toIso8601String(),
            'accepted_at'  => optional($call->accepted_at)->toIso8601String(),
            'ended_at'     => optional($call->ended_at)->toIso8601String(),
            'duration_sec' => $call->duration_sec,
            'end_reason'   => $call->end_reason,
            'caller'       => $call->relationLoaded('caller') && $call->caller ? $this->userBrief($call->caller) : null,
            'callee'       => $call->relationLoaded('callee') && $call->callee ? $this->userBrief($call->callee) : null,
        ];
    }
}
