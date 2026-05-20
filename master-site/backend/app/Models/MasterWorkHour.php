<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MasterWorkHour extends Model
{
    protected $fillable = ['master_profile_id', 'day_of_week', 'start_time', 'end_time'];

    public function masterProfile(): BelongsTo
    {
        return $this->belongsTo(MasterProfile::class);
    }
}
