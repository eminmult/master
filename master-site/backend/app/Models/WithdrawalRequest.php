<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WithdrawalRequest extends Model
{
    public const STATUS_PENDING   = 'pending';
    public const STATUS_APPROVED  = 'approved';
    public const STATUS_PAID      = 'paid';
    public const STATUS_REJECTED  = 'rejected';
    public const STATUS_CANCELLED = 'cancelled';

    public const OPEN_STATUSES = [self::STATUS_PENDING, self::STATUS_APPROVED];

    protected $fillable = [
        'user_id', 'amount_cents', 'currency',
        'status', 'iban', 'account_holder',
        'note', 'admin_note',
        'processed_by_admin_id', 'processed_at',
    ];

    protected $casts = [
        'amount_cents' => 'integer',
        'processed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'processed_by_admin_id');
    }
}
