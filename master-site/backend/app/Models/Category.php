<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    protected $fillable = [
        'name', 'slug', 'icon_url', 'description', 'sort_order', 'is_active',
        'name_translations', 'slug_translations', 'description_translations',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'name_translations' => 'array',
            'slug_translations' => 'array',
            'description_translations' => 'array',
        ];
    }

    /**
     * Returns the localized name for the given locale, falling back to the
     * canonical Azeri name when no translation is set.
     */
    public function nameFor(?string $locale = null): string
    {
        $locale = $locale ?: app()->getLocale();
        return $this->name_translations[$locale] ?? $this->name;
    }

    /**
     * Returns the localized SEO slug. Falls back to the canonical slug.
     */
    public function slugFor(?string $locale = null): string
    {
        $locale = $locale ?: app()->getLocale();
        return $this->slug_translations[$locale] ?? $this->slug;
    }

    public function descriptionFor(?string $locale = null): ?string
    {
        $locale = $locale ?: app()->getLocale();
        return $this->description_translations[$locale] ?? $this->description;
    }

    public function subcategories(): HasMany
    {
        return $this->hasMany(Subcategory::class)->orderBy('sort_order');
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function masterProfiles(): BelongsToMany
    {
        return $this->belongsToMany(MasterProfile::class, 'master_categories');
    }

    /**
     * Resolve route-model binding by id when a numeric value is provided, and
     * by slug otherwise — preserves /categories/{id} while enabling
     * /categories/{slug}.
     */
    public function resolveRouteBinding($value, $field = null)
    {
        if ($field) return parent::resolveRouteBinding($value, $field);
        if (ctype_digit((string) $value)) {
            return $this->where('id', $value)->first();
        }
        // Look up by canonical slug OR by any locale slug stored in
        // slug_translations. JSONB containment lets us scan all locales in one
        // index lookup.
        return $this->where('slug', $value)
            ->orWhereRaw('slug_translations::jsonb @> ?', [json_encode([$value])])
            ->orWhereRaw("EXISTS (SELECT 1 FROM jsonb_each_text(slug_translations) WHERE value = ?)", [$value])
            ->first();
    }
}
