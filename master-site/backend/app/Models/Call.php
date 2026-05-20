<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Call extends Model
{
    use HasFactory;

    public const STATUS_RINGING = 'ringing';
    public const STATUS_ACCEPTED = 'accepted';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_MISSED = 'missed';
    public const STATUS_ENDED = 'ended';
    public const STATUS_CANCELLED = 'cancelled';

    public const ACTIVE_STATUSES = [self::STATUS_RINGING, self::STATUS_ACCEPTED];

    protected $fillable = [
        'order_id', 'caller_id', 'callee_id',
        'status', 'started_at', 'accepted_at', 'ended_at',
        'duration_sec', 'end_reason',
    ];

    protected $casts = [
        'started_at'  => 'datetime',
        'accepted_at' => 'datetime',
        'ended_at'    => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function caller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'caller_id');
    }

    public function callee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'callee_id');
    }

    public function isActive(): bool
    {
        return in_array($this->status, self::ACTIVE_STATUSES, true);
    }
}
