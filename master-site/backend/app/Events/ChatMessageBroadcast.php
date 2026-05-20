<?php

namespace App\Events;

use App\Models\ChatMessage;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Pushed to the recipient's private user channel whenever a chat message is
 * persisted. Carries the full message envelope so the client can append it
 * directly without re-fetching the thread (latency drops from poll interval
 * to one WS hop).
 *
 * Scope: targets exactly one recipient (the user on the other end of the
 * thread). The `scope` field distinguishes order-level chats from application
 * chats so the receiving page can filter messages that belong to a different
 * conversation.
 */
class ChatMessageBroadcast implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $toUserId,
        /** 'order' | 'application' */
        public string $scope,
        public int $scopeId,
        public ChatMessage $message,
    ) {
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel('user.' . $this->toUserId)];
    }

    public function broadcastAs(): string
    {
        return 'chat.message';
    }

    public function broadcastWith(): array
    {
        $m = $this->message->load('sender:id,first_name,last_name,avatar_url')->toArray();
        return [
            'scope'     => $this->scope,
            'scope_id'  => $this->scopeId,
            'message'   => $m,
        ];
    }
}
