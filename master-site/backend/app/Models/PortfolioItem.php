<?php

namespace App\Models;

use App\Models\Concerns\HasAutoTranslation;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PortfolioItem extends Model
{
    use HasAutoTranslation;

    protected array $translatable = ['description'];

    protected $fillable = [
        'master_profile_id', 'image_url', 'description',
        'description_translations', 'content_locale',
    ];

    protected $hidden = ['description_translations'];

    protected function casts(): array
    {
        return ['description_translations' => 'array'];
    }

    public function masterProfile(): BelongsTo
    {
        return $this->belongsTo(MasterProfile::class);
    }
}
