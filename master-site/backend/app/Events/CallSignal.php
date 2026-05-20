<?php

namespace App\Events;

use App\Models\Call;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Generic WebRTC signaling broadcast: offer / answer / ICE candidates.
 *
 * Routed to a private channel per recipient so only the intended peer
 * picks it up; the same event class carries the call lifecycle envelope
 * (ringing, accepted, rejected, ended) as well.
 */
class CallSignal implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $toUserId,
        public int $callId,
        public string $type, // ringing|accepted|rejected|ended|cancelled|offer|answer|ice
        public array $payload = [],
    ) {
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel('user.' . $this->toUserId)];
    }

    public function broadcastAs(): string
    {
        return 'call.' . $this->type;
    }

    public function broadcastWith(): array
    {
        return [
            'call_id' => $this->callId,
            'type'    => $this->type,
            'payload' => $this->payload,
        ];
    }

    public static function fire(Call $call, int $toUserId, string $type, array $payload = []): void
    {
        event(new self($toUserId, $call->id, $type, $payload));
    }
}
