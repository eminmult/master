<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrderApplication extends Model
{
    // Negotiation-level statuses:
    //   pending     — master applied, client hasn't engaged yet
    //   discussing  — client opened chat with this master; both can message
    //   proposed    — master sent a formal proposal (date + price) awaiting client
    //   accepted    — client accepted the proposal → order closes here (final)
    //   rejected    — client rejected OR another master was chosen
    //   withdrawn   — master pulled back their application
    //   expired     — (reserved) announcement canceled or timed out
    const STATUS_PENDING = 'pending';
    const STATUS_DISCUSSING = 'discussing';
    const STATUS_PROPOSED = 'proposed';
    const STATUS_ACCEPTED = 'accepted';
    const STATUS_REJECTED = 'rejected';
    const STATUS_WITHDRAWN = 'withdrawn';
    const STATUS_EXPIRED = 'expired';

    // Statuses where chat is available (master ↔ client pre-agreement)
    const CHAT_STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_DISCUSSING,
        self::STATUS_PROPOSED,
    ];

    protected $fillable = [
        'order_id', 'master_id', 'status', 'message',
        'proposed_price', 'proposed_date', 'responded_at',
    ];

    protected function casts(): array
    {
        return [
            'responded_at' => 'datetime',
            'proposed_date' => 'datetime',
            'proposed_price' => 'decimal:2',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function master(): BelongsTo
    {
        return $this->belongsTo(User::class, 'master_id');
    }

    public function chatMessages(): HasMany
    {
        return $this->hasMany(ChatMessage::class, 'application_id')->orderBy('created_at');
    }

    public function canChat(): bool
    {
        return in_array($this->status, self::CHAT_STATUSES, true);
    }
}
