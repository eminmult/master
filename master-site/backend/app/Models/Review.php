<?php

namespace App\Models;

use App\Models\Concerns\HasAutoTranslation;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Review extends Model
{
    use HasAutoTranslation;

    protected array $translatable = ['text'];

    protected $fillable = [
        'order_id', 'reviewer_id', 'reviewee_id', 'rating', 'text', 'tags',
        'text_translations', 'content_locale',
    ];

    protected $hidden = ['text_translations'];

    protected function casts(): array
    {
        return [
            'tags' => 'array',
            'text_translations' => 'array',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }

    public function reviewee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewee_id');
    }

    public function photos(): HasMany
    {
        return $this->hasMany(ReviewPhoto::class)->orderBy('sort_order');
    }
}
