<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, \App\Models\Concerns\HasAutoTranslation;

    /**
     * Auto-translate first/last name across all locales. Names are proper
     * nouns — the TranslationService prompt transliterates them into the
     * target script ("Rəşad" → "Rashad" / "Рашад" / "رشاد").
     */
    protected array $translatable = ['first_name', 'last_name'];

    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'phone',
        'password',
        'role',
        'avatar_url',
        'locale',
        'is_active',
        'subscription_active',
        'subscription_expires_at',
        'registration_paid_at',
        'first_name_translations',
        'last_name_translations',
        'content_locale',
    ];


    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'is_verified' => 'boolean',
            'verified_at' => 'datetime',
            'is_active' => 'boolean',
            'subscription_active' => 'boolean',
            'subscription_expires_at' => 'datetime',
            'registration_paid_at' => 'datetime',
            'rating_avg' => 'decimal:2',
            'password' => 'hashed',
            'first_name_translations' => 'array',
            'last_name_translations' => 'array',
        ];
    }

    /**
     * True iff master can take orders / chat / propose. Honors the global
     * MASTER_SUBSCRIPTION_REQUIRED flag — when off, all masters pass.
     */
    public function canOperateAsMaster(): bool
    {
        if (!$this->isMaster()) return false;
        if (!$this->is_active) return false;
        if (!config('master.subscription_required', false)) return true;
        if (!$this->subscription_active) return false;
        if ($this->subscription_expires_at && $this->subscription_expires_at->isPast()) return false;
        return true;
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(MasterSubscription::class, 'master_id');
    }

    public function isClient(): bool { return $this->role === 'client'; }
    public function isMaster(): bool { return $this->role === 'master'; }
    public function isAdmin(): bool { return $this->role === 'admin'; }

    public function getFullNameAttribute(): string
    {
        return trim("{$this->localized('first_name')} {$this->localized('last_name')}");
    }

    /**
     * SEO slug for public master profile: "{category}-{first}-{last}-{id}".
     * The trailing -{id} guarantees uniqueness and lets the router resolve
     * the user even after a rename. Falls back gracefully when category /
     * profile is missing.
     */
    public function getSlugAttribute(): string
    {
        $parts = [];
        $primary = $this->masterProfile?->categories?->first();
        if ($primary?->slug) $parts[] = $primary->slug;
        if ($this->first_name) $parts[] = \Illuminate\Support\Str::slug($this->first_name);
        if ($this->last_name) $parts[] = \Illuminate\Support\Str::slug($this->last_name);
        $parts[] = (string) $this->id;
        return implode('-', array_filter($parts, fn ($p) => $p !== ''));
    }

    /**
     * Resolve a master by slug. Accepts either a pure id or any slug
     * containing a trailing "-{id}" segment.
     */
    public static function findBySlug(string $slug): ?self
    {
        $slug = trim($slug, '/');
        if (ctype_digit($slug)) return self::find((int) $slug);
        if (preg_match('/-(\d+)$/', $slug, $m)) {
            return self::find((int) $m[1]);
        }
        return null;
    }

    public function masterProfile(): HasOne
    {
        return $this->hasOne(MasterProfile::class);
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(Address::class);
    }

    public function clientOrders(): HasMany
    {
        return $this->hasMany(Order::class, 'client_id');
    }

    public function masterOrders(): HasMany
    {
        return $this->hasMany(Order::class, 'master_id');
    }

    public function reviewsGiven(): HasMany
    {
        return $this->hasMany(Review::class, 'reviewer_id');
    }

    public function reviewsReceived(): HasMany
    {
        return $this->hasMany(Review::class, 'reviewee_id');
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class);
    }

    public function recalculateRating(): void
    {
        $stats = $this->reviewsReceived()
            ->selectRaw('AVG(rating) as avg, COUNT(*) as cnt')
            ->first();

        $this->update([
            'rating_avg' => round($stats->avg ?? 0, 2),
            'rating_count' => $stats->cnt ?? 0,
        ]);
    }
}
