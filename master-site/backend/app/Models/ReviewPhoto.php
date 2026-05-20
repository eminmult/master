<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReviewPhoto extends Model
{
    protected $fillable = ['review_id', 'thumb_url', 'medium_url', 'large_url', 'sort_order'];

    public function review(): BelongsTo
    {
        return $this->belongsTo(Review::class);
    }
}
