<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletTransaction extends Model
{
    public const UPDATED_AT = null; // immutable ledger

    public const DIR_DEBIT  = 'debit';
    public const DIR_CREDIT = 'credit';

    public const ACCOUNT_USER     = 'user_balance';
    public const ACCOUNT_PLATFORM = 'platform_revenue';
    public const ACCOUNT_CARD     = 'external_card';

    public const KIND_CALLOUT_FEE      = 'callout_fee';
    public const KIND_CALLOUT_REFUND   = 'callout_refund';
    public const KIND_MASTER_PENALTY   = 'master_penalty';
    public const KIND_WITHDRAWAL_HOLD  = 'withdrawal_hold';
    public const KIND_WITHDRAWAL_PAID  = 'withdrawal_paid';
    public const KIND_WITHDRAWAL_RESTORE = 'withdrawal_restore';
    public const KIND_MANUAL_ADJUST    = 'manual_adjust';

    protected $fillable = [
        'transaction_uuid', 'account_type', 'account_user_id',
        'direction', 'amount_cents', 'currency',
        'order_id', 'kind', 'idempotency_key',
        'metadata', 'created_by_user_id',
    ];

    protected $casts = [
        'metadata'    => 'array',
        'created_at'  => 'datetime',
        'amount_cents'=> 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'account_user_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
