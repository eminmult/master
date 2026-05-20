<?php

namespace App\Models;

use App\Models\Concerns\HasAutoTranslation;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CategorySuggestion extends Model
{
    use HasAutoTranslation;

    protected array $translatable = ['name', 'description'];

    protected $fillable = [
        'user_id', 'name', 'description', 'suggested_icon',
        'status', 'reviewed_by', 'reviewed_at', 'admin_note', 'category_id',
        'name_translations', 'description_translations', 'content_locale',
    ];

    protected $hidden = ['name_translations', 'description_translations'];

    protected $casts = [
        'reviewed_at' => 'datetime',
        'name_translations' => 'array',
        'description_translations' => 'array',
    ];

    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function reviewer(): BelongsTo { return $this->belongsTo(User::class, 'reviewed_by'); }
    public function category(): BelongsTo { return $this->belongsTo(Category::class); }
}
