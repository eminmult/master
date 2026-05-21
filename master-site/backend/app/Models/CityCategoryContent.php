<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CityCategoryContent extends Model
{
    protected $fillable = ['city_slug', 'category_id', 'locale', 'body'];
    protected $casts = ['body' => 'array'];
}
