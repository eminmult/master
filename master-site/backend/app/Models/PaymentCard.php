<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentCard extends Model
{
    protected $fillable = [
        'user_id', 'brand', 'last4', 'exp_month', 'exp_year',
        'holder_name', 'token', 'is_default',
    ];

    protected $casts = [
        'is_default' => 'boolean',
        'exp_month' => 'integer',
        'exp_year' => 'integer',
    ];

    /** PAN and CVV are never persisted; hide the opaque token from JSON. */
    protected $hidden = ['token'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
