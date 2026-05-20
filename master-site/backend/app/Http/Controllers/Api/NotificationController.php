<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $limit = (int) $request->query('limit', 20);
        $offset = (int) $request->query('offset', 0);

        $query = Notification::where('user_id', $request->user()->id)
            ->orderByDesc('created_at');

        $total = $query->count();
        $unread = Notification::where('user_id', $request->user()->id)->where('is_read', false)->count();

        $notifications = $query->skip($offset)->take($limit)->get()->map(function ($n) {
            $titles = json_decode($n->title, true);
            $bodies = json_decode($n->body, true);

            return [
                'id' => $n->id,
                'type' => $n->type,
                'titles' => is_array($titles) ? $titles : ['az' => $n->title],
                'bodies' => is_array($bodies) ? $bodies : ['az' => $n->body],
                'data' => $n->data,
                'is_read' => $n->is_read,
                'created_at' => $n->created_at,
            ];
        });

        return response()->json([
            'notifications' => $notifications,
            'total' => $total,
            'unread' => $unread,
            'has_more' => ($offset + $limit) < $total,
        ]);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $count = Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->count();

        return response()->json(['unread' => $count]);
    }

    public function markRead(Request $request, Notification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $notification->update(['is_read' => true]);

        return response()->json(['ok' => true]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['ok' => true]);
    }
}
