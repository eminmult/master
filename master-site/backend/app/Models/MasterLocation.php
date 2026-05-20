<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MasterLocation extends Model
{
    public $timestamps = false;

    protected $fillable = ['order_id', 'master_id', 'lat', 'lng', 'recorded_at'];

    protected function casts(): array
    {
        return ['recorded_at' => 'datetime'];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function master(): BelongsTo
    {
        return $this->belongsTo(User::class, 'master_id');
    }
}
