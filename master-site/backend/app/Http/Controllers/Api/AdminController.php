<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Dispute;
use App\Models\Order;
use App\Models\Review;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    private function paginate($query, Request $request): array
    {
        $perPage = min(max((int) $request->query('per_page', 50), 1), 200);
        $page = max((int) $request->query('page', 1), 1);
        $total = (clone $query)->count();
        $items = $query->forPage($page, $perPage)->get();
        return [
            'items' => $items,
            'total' => $total,
            'page' => $page,
            'per_page' => $perPage,
            'has_more' => $page * $perPage < $total,
        ];
    }

    private function userDto(User $u): array
    {
        return [
            'id' => $u->id,
            'first_name' => $u->first_name,
            'last_name' => $u->last_name,
            'full_name' => trim("{$u->first_name} {$u->last_name}"),
            'email' => $u->email,
            'phone' => $u->phone,
            'role' => $u->role,
            'avatar_url' => $u->avatar_url,
            'rating_avg' => $u->rating_avg,
            'rating_count' => $u->rating_count,
            'is_active' => $u->is_active,
            'subscription_active' => (bool) $u->subscription_active,
            'subscription_expires_at' => $u->subscription_expires_at,
            'registration_paid_at' => $u->registration_paid_at,
            'email_verified_at' => $u->email_verified_at,
            'phone_verified_at' => $u->phone_verified_at,
            'created_at' => $u->created_at,
        ];
    }

    public function extendSubscription(Request $request, User $user): JsonResponse
    {
        if (!$user->isMaster()) {
            return response()->json(['message' => 'Only masters have subscriptions'], 422);
        }
        $data = $request->validate([
            'days' => 'required|integer|min:1|max:3650',
            'plan' => 'nullable|in:registration,monthly,yearly,lifetime,manual',
            'note' => 'nullable|string|max:500',
        ]);

        $base = ($user->subscription_expires_at && $user->subscription_expires_at->isFuture())
            ? $user->subscription_expires_at
            : now();

        $expires = $base->copy()->addDays($data['days']);

        $user->update([
            'subscription_active' => true,
            'subscription_expires_at' => $expires,
        ]);

        \App\Models\MasterSubscription::create([
            'master_id' => $user->id,
            'plan' => $data['plan'] ?? 'manual',
            'amount' => 0,
            'status' => 'manual',
            'starts_at' => $base,
            'expires_at' => $expires,
            'meta' => ['admin_note' => $data['note'] ?? null, 'granted_by' => $request->user()->id],
        ]);

        return response()->json(['user' => $this->userDto($user->fresh())]);
    }

    public function deactivateSubscription(User $user): JsonResponse
    {
        if (!$user->isMaster()) {
            return response()->json(['message' => 'Only masters have subscriptions'], 422);
        }
        $user->update(['subscription_active' => false, 'subscription_expires_at' => now()]);
        return response()->json(['user' => $this->userDto($user->fresh())]);
    }

    public function users(Request $request): JsonResponse
    {
        $query = User::query();

        if ($role = $request->query('role')) {
            $query->where('role', $role);
        }

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'ilike', "%{$search}%")
                  ->orWhere('last_name', 'ilike', "%{$search}%")
                  ->orWhere('phone', 'ilike', "%{$search}%")
                  ->orWhere('email', 'ilike', "%{$search}%");
            });
        }

        $paged = $this->paginate($query->orderByDesc('created_at'), $request);
        return response()->json([
            'users' => $paged['items']->map(fn(User $u) => $this->userDto($u)),
            'total' => $paged['total'],
            'page' => $paged['page'],
            'per_page' => $paged['per_page'],
            'has_more' => $paged['has_more'],
        ]);
    }

    public function orders(Request $request): JsonResponse
    {
        $query = Order::with(['client', 'master', 'category']);

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('id', 'ilike', "%{$search}%")
                  ->orWhere('full_address', 'ilike', "%{$search}%")
                  ->orWhere('contact_phone', 'ilike', "%{$search}%")
                  ->orWhereHas('client', fn($cq) => $cq->where('first_name', 'ilike', "%{$search}%"))
                  ->orWhereHas('master', fn($mq) => $mq->where('first_name', 'ilike', "%{$search}%"));
            });
        }

        $paged = $this->paginate($query->orderByDesc('created_at'), $request);
        return response()->json([
            'orders' => $paged['items'],
            'total' => $paged['total'],
            'page' => $paged['page'],
            'per_page' => $paged['per_page'],
            'has_more' => $paged['has_more'],
        ]);
    }

    public function categories(): JsonResponse
    {
        $categories = Category::with('subcategories')->orderBy('sort_order')->get();

        return response()->json(['categories' => $categories]);
    }

    public function reviews(Request $request): JsonResponse
    {
        $query = Review::with(['reviewer', 'reviewee'])->orderByDesc('created_at');
        $paged = $this->paginate($query, $request);
        return response()->json([
            'reviews' => $paged['items'],
            'total' => $paged['total'],
            'page' => $paged['page'],
            'per_page' => $paged['per_page'],
            'has_more' => $paged['has_more'],
        ]);
    }

    public function disputes(Request $request): JsonResponse
    {
        $query = Dispute::with(['reporter', 'order'])->orderByDesc('created_at');
        $paged = $this->paginate($query, $request);
        return response()->json([
            'disputes' => $paged['items'],
            'total' => $paged['total'],
            'page' => $paged['page'],
            'per_page' => $paged['per_page'],
            'has_more' => $paged['has_more'],
        ]);
    }

    public function analytics(): JsonResponse
    {
        $stats = [
            'total_clients' => User::where('role', 'client')->count(),
            'total_masters' => User::where('role', 'master')->count(),
            'total_orders' => Order::count(),
            'completed_orders' => Order::where('status', 'completed')->orWhere('status', 'closed')->count(),
            'canceled_orders' => Order::whereIn('status', ['canceled_by_client', 'canceled_by_master', 'canceled_by_system'])->count(),
            'avg_master_rating' => number_format(
                User::where('role', 'master')->where('rating_count', '>', 0)->avg('rating_avg') ?? 0,
                2
            ),
        ];

        return response()->json(['stats' => $stats]);
    }

    public function toggleBlock(Request $request, User $user): JsonResponse
    {
        $user->update(['is_active' => !$user->is_active]);
        return response()->json(['user' => $this->userDto($user->fresh()), 'is_active' => $user->is_active]);
    }

    public function verifyMaster(Request $request, User $user): JsonResponse
    {
        $profile = $user->masterProfile;
        if (!$profile) return response()->json(['message' => 'Not a master'], 422);

        $profile->update([
            'is_verified' => !$profile->is_verified,
            'verified_at' => $profile->is_verified ? null : now(),
        ]);

        return response()->json(['is_verified' => $profile->fresh()->is_verified]);
    }

    public function updateOrderStatus(Request $request, Order $order): JsonResponse
    {
        $request->validate([
            'status' => 'required|string|in:' . implode(',', Order::ALL_STATUSES),
            'reason' => 'nullable|string|max:500',
        ]);

        // Even admins shouldn't resurrect terminal orders — it silently breaks
        // notifications, payouts and reviews. Only allow closed/completed →
        // disputed (for post-hoc issue investigation). Canceled/closed stay terminal.
        $terminal = [
            Order::STATUS_COMPLETED, Order::STATUS_CLOSED,
            Order::STATUS_CANCELED_CLIENT, Order::STATUS_CANCELED_MASTER,
            Order::STATUS_CANCELED_SYSTEM,
        ];
        if (in_array($order->status, $terminal, true) && $request->status !== Order::STATUS_DISPUTED) {
            return response()->json([
                'message' => 'Terminal sifarişin statusunu dəyişmək olmaz.',
            ], 422);
        }

        $order->update(['status' => $request->status]);
        $order->logStatus($request->status, $request->user()->id, null, null, $request->reason ?? 'Admin override');
        return response()->json(['order' => $order]);
    }

    public function deleteReview(Request $request, Review $review): JsonResponse
    {
        $revieweeId = $review->reviewee_id;
        $orderId = $review->order_id;
        $review->delete();

        // Recalculate reviewee rating
        $reviewee = User::find($revieweeId);
        if ($reviewee) {
            $reviewee->recalculateRating();
        }

        // Unmark the "reviewed" flag on the order so the user can leave a new review
        $order = Order::find($orderId);
        if ($order) {
            if ($review->reviewer_id === $order->client_id) {
                $order->update(['client_reviewed' => false]);
            } elseif ($review->reviewer_id === $order->master_id) {
                $order->update(['master_reviewed' => false]);
            }
        }

        return response()->json(['deleted' => true]);
    }

    public function resolveDispute(Request $request, Dispute $dispute): JsonResponse
    {
        $data = $request->validate([
            'resolution' => 'required|string|in:client_win,master_win,warning,no_action',
            'admin_note' => 'nullable|string|max:2000',
            'ban_master' => 'sometimes|boolean',
            'ban_client' => 'sometimes|boolean',
        ]);

        $dispute->update([
            'status' => 'resolved',
            'admin_note' => $data['admin_note'] ?? null,
            'resolved_by' => $request->user()->id,
            'resolved_at' => now(),
        ]);

        $order = $dispute->order;

        if (!empty($data['ban_master']) && $order?->master) {
            $order->master->update(['is_active' => false]);
        }
        if (!empty($data['ban_client']) && $order?->client) {
            $order->client->update(['is_active' => false]);
        }

        // Notify both sides in their language
        $titles = [
            'az' => 'Şikayət həll edildi',
            'ru' => 'Спор решён',
            'en' => 'Dispute resolved',
        ];
        $bodies = [
            'az' => "#{$dispute->order_id} üzrə şikayət həll edildi.",
            'ru' => "Спор по заказу #{$dispute->order_id} решён.",
            'en' => "Dispute on order #{$dispute->order_id} has been resolved.",
        ];
        $meta = ['order_id' => $dispute->order_id, 'resolution' => $data['resolution']];

        if ($order?->client_id) NotificationService::send($order->client_id, 'dispute_resolved', $titles, $bodies, $meta);
        if ($order?->master_id) NotificationService::send($order->master_id, 'dispute_resolved', $titles, $bodies, $meta);

        return response()->json(['dispute' => $dispute->fresh(['order', 'reporter', 'resolver'])]);
    }
}
