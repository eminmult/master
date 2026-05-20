<?php

namespace App\Models;

use App\Models\Concerns\HasAutoTranslation;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MasterProfile extends Model
{
    use HasAutoTranslation;

    protected array $translatable = ['description'];

    protected $fillable = [
        'user_id',
        'description',
        'experience_years',
        'status',
        'is_accepting_orders',
        'is_verified',
        'city',
        'district',
        'transport_type',
        'urgent_available',
        'work_radius_km',
        'languages',
        'current_lat',
        'current_lng',
        'location_updated_at',
        'verified_at',
        'completed_orders_count',
        'canceled_orders_count',
        'description_translations',
        'content_locale',
    ];

    protected $hidden = ['description_translations'];

    protected function casts(): array
    {
        return [
            'is_accepting_orders' => 'boolean',
            'is_verified' => 'boolean',
            'urgent_available' => 'boolean',
            'current_lat' => 'decimal:7',
            'current_lng' => 'decimal:7',
            'location_updated_at' => 'datetime',
            'verified_at' => 'datetime',
            'description_translations' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class, 'master_categories')
            ->withPivot('subcategory_id')
            ->withTimestamps();
    }

    public function masterCategories(): HasMany
    {
        return $this->hasMany(MasterCategory::class);
    }

    public function skills(): HasMany
    {
        return $this->hasMany(MasterSkill::class)->orderBy('sort_order');
    }

    public function workHours(): HasMany
    {
        return $this->hasMany(MasterWorkHour::class);
    }

    public function verificationDocuments(): HasMany
    {
        return $this->hasMany(VerificationDocument::class);
    }

    public function portfolioItems(): HasMany
    {
        return $this->hasMany(PortfolioItem::class);
    }

    public function isOnline(): bool
    {
        return $this->status === 'online' && $this->is_accepting_orders;
    }

    public function updateLocation(float $lat, float $lng): void
    {
        $this->update([
            'current_lat' => $lat,
            'current_lng' => $lng,
            'location_updated_at' => now(),
        ]);
    }
}
