<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MasterSubscription extends Model
{
    protected $fillable = [
        'master_id', 'plan', 'amount', 'currency', 'status',
        'payment_provider', 'payment_id', 'starts_at', 'expires_at', 'meta',
    ];

    protected $casts = [
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
        'meta' => 'array',
        'amount' => 'decimal:2',
    ];

    public function master(): BelongsTo
    {
        return $this->belongsTo(User::class, 'master_id');
    }
}
