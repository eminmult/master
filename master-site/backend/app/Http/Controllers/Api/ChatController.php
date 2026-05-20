<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use App\Models\Order;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function messages(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if ($user->id !== $order->client_id && $user->id !== $order->master_id && !$user->isAdmin()) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $limit = (int) $request->query('limit', 30);
        $before = (int) $request->query('before', 0);
        // `since=<id>` returns only newer messages — used by the 1s polling
        // loop so idle conversations stream nothing but a tiny empty payload.
        $since  = (int) $request->query('since', 0);

        if ($since > 0) {
            $hasNew = ChatMessage::where('order_id', $order->id)
                ->whereNull('application_id')
                ->where('id', '>', $since)
                ->exists();
            if (!$hasNew) {
                ChatMessage::where('order_id', $order->id)
                    ->whereNull('application_id')
                    ->where('sender_id', '!=', $user->id)
                    ->whereNull('read_at')
                    ->update(['read_at' => now()]);
                return response()->json(['messages' => [], 'has_more' => false]);
            }
        }

        // Main order chat = messages without application_id (post-agreement).
        // Per-application pre-agreement chat is served from a separate endpoint.
        $query = $order->chatMessages()
            ->whereNull('application_id')
            ->reorder()
            ->with('sender:id,first_name,last_name,role');

        if ($before) {
            $query->where('id', '<', $before);
        }
        if ($since) {
            $query->where('id', '>', $since);
        }

        $messages = $query->orderByDesc('id')->limit($limit)->get()->sortBy('id')->values();

        // Mark unread as read (main chat only — application-scoped messages are
        // marked via the application messages endpoint)
        ChatMessage::where('order_id', $order->id)
            ->whereNull('application_id')
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'messages' => $messages->map(fn($m) => [
                'id' => $m->id,
                'text' => $m->text,
                'photo_url' => $m->photo_url,
                'photo_thumb_url' => $m->photo_thumb_url,
                'sender_id' => $m->sender_id,
                'sender_name' => $m->sender->first_name,
                'sender_role' => $m->sender->role,
                'is_mine' => $m->sender_id === $user->id,
                'read_at' => $m->read_at,
                'created_at' => $m->created_at,
            ]),
            'has_more' => $messages->count() === $limit,
        ]);
    }

    public function send(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if ($user->id !== $order->client_id && $user->id !== $order->master_id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        // Chat only for active orders with discussion
        if (!in_array($order->status, Order::CHAT_STATUSES)) {
            return response()->json(['message' => 'Bu statusda mesaj göndərmək mümkün deyil.'], 422);
        }

        // Either text or photo (or both). Photo is base64-encoded; the text
        // becomes a caption in that case.
        $request->validate([
            'text' => 'nullable|string|max:2000',
            'photo' => 'nullable|string', // base64 (data-url or raw)
        ]);
        if (!$request->filled('text') && !$request->filled('photo')) {
            return response()->json(['message' => 'Mesaj boş ola bilməz.'], 422);
        }

        $photoUrl = null;
        $photoThumbUrl = null;
        if ($request->filled('photo')) {
            $urls = \App\Services\ImageService::processBase64(
                $request->input('photo'),
                'chat/' . $order->id,
            );
            if ($urls) {
                $photoUrl = $urls['large'] ?? $urls['medium'] ?? $urls['original'] ?? null;
                $photoThumbUrl = $urls['thumb'] ?? $urls['medium'] ?? $photoUrl;
            }
        }

        $message = ChatMessage::create([
            'order_id' => $order->id,
            'sender_id' => $user->id,
            'text' => (string) $request->input('text'),
            'photo_url' => $photoUrl,
            'photo_thumb_url' => $photoThumbUrl,
        ]);

        $message->load('sender:id,first_name,last_name,role');

        // Notify the other party
        $receiverId = $user->id === $order->client_id ? $order->master_id : $order->client_id;
        if ($receiverId) {
            NotificationService::newMessage($order->id, $user->id, $receiverId, $user->first_name);
            // Realtime push — Reverb (WebSocket) for clients that can reach it,
            // and Redis pub/sub for the SSE relay. SSE works through CF
            // Flexible SSL where WSS would be downgraded.
            event(new \App\Events\ChatMessageBroadcast(
                toUserId: $receiverId,
                scope: 'order',
                scopeId: $order->id,
                message: $message,
            ));
            \Illuminate\Support\Facades\Redis::publish("realtime:user:{$receiverId}", json_encode([
                'type'     => 'chat.message',
                'scope'    => 'order',
                'scope_id' => $order->id,
                'message'  => $message->fresh(['sender:id,first_name,last_name,avatar_url'])->toArray(),
            ], JSON_UNESCAPED_UNICODE));
        }

        return response()->json([
            'message' => [
                'id' => $message->id,
                'text' => $message->text,
                'photo_url' => $message->photo_url,
                'photo_thumb_url' => $message->photo_thumb_url,
                'sender_id' => $message->sender_id,
                'sender_name' => $message->sender->first_name,
                'sender_role' => $message->sender->role,
                'is_mine' => true,
                'read_at' => null,
                'created_at' => $message->created_at,
            ],
        ], 201);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();

        $count = ChatMessage::where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->whereHas('order', function ($q) use ($user) {
                $q->where('client_id', $user->id)->orWhere('master_id', $user->id);
            })
            ->count();

        return response()->json(['unread' => $count]);
    }
}
