<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MasterSkill extends Model
{
    use \App\Models\Concerns\HasAutoTranslation;

    protected array $translatable = ['name'];

    protected $fillable = ['master_profile_id', 'category_id', 'name', 'is_active', 'sort_order',
        'name_translations', 'content_locale'];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'name_translations' => 'array',
        ];
    }

    public function masterProfile(): BelongsTo
    {
        return $this->belongsTo(MasterProfile::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }
}
