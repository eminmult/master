<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderPhoto extends Model
{
    protected $fillable = ['order_id', 'url', 'type', 'uploaded_by'];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }
}
