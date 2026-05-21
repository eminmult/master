<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MasterProfile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MasterListController extends Controller
{
    /**
     * Accept either a numeric id or a slug ending in "-{id}".
     * Throws 404 if neither form yields a valid id.
     */
    private function resolveId(string $idOrSlug): int
    {
        $idOrSlug = trim($idOrSlug, '/');
        if (ctype_digit($idOrSlug)) return (int) $idOrSlug;
        if (preg_match('/-(\d+)$/', $idOrSlug, $m)) return (int) $m[1];
        abort(404);
    }

    /**
     * Rewrite Unsplash CDN URLs to ask for WebP at a sane width. Unsplash
     * supports query-string transforms (`fm=webp`, `w=400`, `q=80`, `auto=format`)
     * and serves AVIF where the client's Accept header allows it. Saves
     * 30-50% bandwidth vs the default JPEG without any server-side cost.
     */
    private function optimizeImageUrl(?string $url, int $width = 400): ?string
    {
        if (!$url) return $url;
        if (!str_contains($url, 'images.unsplash.com')) return $url;
        // Drop any existing w= and add ours; force WebP via fm=.
        $url = preg_replace('/([?&])w=\d+/', '$1w=' . $width, $url) ?? $url;
        if (!str_contains($url, 'fm=')) {
            $sep = str_contains($url, '?') ? '&' : '?';
            $url .= $sep . 'fm=webp&q=80&auto=format';
        }
        return $url;
    }

    private function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $R = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return 2 * $R * asin(min(1.0, sqrt($a)));
    }

    public function index(Request $request): JsonResponse
    {
        $query = MasterProfile::with(['user', 'masterCategories.category'])
            ->whereHas('user', fn($q) => $q->where('users.is_active', true));
        // Verification is a badge, not a gate — show all active masters regardless.

        // Search by name
        if ($search = $request->query('search')) {
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('first_name', 'ilike', "%{$search}%")
                  ->orWhere('last_name', 'ilike', "%{$search}%");
            });
        }

        // Filter by category id or slug
        if ($categoryId = $request->query('category_id')) {
            $query->whereHas('masterCategories', fn($q) => $q->where('category_id', $categoryId));
        } elseif ($categorySlug = $request->query('category_slug')) {
            // Match the canonical AZ slug OR any per-locale slug stored in
            // slug_translations. Without the JSONB-scan branch a URL like
            // /ru/category/santehnik (Russian slug) wouldn't find category 1
            // (canonical slug "santexnik") and the listing came back empty.
            $query->whereHas(
                'masterCategories.category',
                fn ($q) => $q
                    ->where('slug', $categorySlug)
                    ->orWhereRaw(
                        "EXISTS (SELECT 1 FROM jsonb_each_text(slug_translations) WHERE value = ?)",
                        [$categorySlug],
                    ),
            );
        }

        // Filter by city (free-text). city_slug is honored in a PHP post-pass
        // below since PostgreSQL here lacks the unaccent extension.
        if ($city = $request->query('city')) {
            $query->where('city', 'ilike', "%{$city}%");
        }
        $citySlug = $request->query('city_slug');

        // Filter by district
        if ($district = $request->query('district')) {
            $query->where('district', 'ilike', "%{$district}%");
        }

        // Filter online only
        if ($request->query('online')) {
            $query->where('status', 'online')->where('is_accepting_orders', true);
        }

        // Filter by minimum rating
        if ($minRating = $request->query('min_rating')) {
            $query->whereHas('user', fn($q) => $q->where('rating_avg', '>=', $minRating));
        }

        // Geo
        $userLat = $request->filled('lat') ? (float) $request->query('lat') : null;
        $userLng = $request->filled('lng') ? (float) $request->query('lng') : null;
        $hasGeo = $userLat !== null && $userLng !== null;

        // Sort
        $sort = $request->query('sort', 'orders');
        match ($sort) {
            'rating' => $query->join('users', 'users.id', '=', 'master_profiles.user_id')
                ->orderByDesc('users.rating_avg')
                ->select('master_profiles.*'),
            'orders' => $query->orderByDesc('completed_orders_count'),
            'experience' => $query->orderByDesc('experience_years'),
            'newest' => $query->orderByDesc('created_at'),
            'distance' => $query->orderByDesc('completed_orders_count'), // pre-sort, real sort happens in PHP below
            default => $query->orderByDesc('completed_orders_count'),
        };

        // Fetch more rows when geo sorting (so we can re-order in PHP) or when
        // city_slug filtering is requested (post-filtering trims the set).
        $limit = ($hasGeo && $sort === 'distance') || $citySlug ? 150 : 50;
        $profiles = $query->limit($limit)->get();

        if ($citySlug) {
            $profiles = $profiles->filter(
                fn ($p) => $p->city && \Illuminate\Support\Str::slug($p->city) === $citySlug
            )->take(50);
        }

        $locale = app()->getLocale();
        $masters = $profiles->map(function ($profile) use ($userLat, $userLng, $hasGeo, $locale) {
            $user = $profile->user;
            $cats = $profile->masterCategories->map(fn($mc) => $mc->category)->filter()->unique('id')->values();

            $distanceKm = null;
            if ($hasGeo && $profile->current_lat !== null && $profile->current_lng !== null) {
                $distanceKm = $this->haversineKm(
                    $userLat, $userLng,
                    (float) $profile->current_lat, (float) $profile->current_lng
                );
            }

            // Locale-aware slug: "{localized-category-slug}-{first}-{last}-{id}"
            $primaryCat = $cats->first();
            $slugParts = array_filter([
                $primaryCat ? $primaryCat->slugFor($locale) : null,
                $user->first_name ? \Illuminate\Support\Str::slug($user->first_name) : null,
                $user->last_name ? \Illuminate\Support\Str::slug($user->last_name) : null,
                (string) $user->id,
            ]);

            // Project localized category names alongside originals.
            $catsOut = $cats->map(fn ($c) => [
                'id' => $c->id,
                'slug' => $c->slugFor($locale),
                'name' => $c->nameFor($locale),
                'icon_url' => $c->icon_url,
            ])->values();

            return [
                'id' => $user->id,
                'slug' => implode('-', $slugParts),
                'first_name' => $user->localized('first_name'),
                'last_name' => $user->localized('last_name'),
                'full_name' => $user->full_name,
                'avatar_url' => $this->optimizeImageUrl($user->avatar_url, 400),
                'rating_avg' => $user->rating_avg,
                'rating_count' => $user->rating_count,
                'description' => $profile->localized('description'),
                'experience_years' => $profile->experience_years,
                'city' => $profile->localized('city'),
                'district' => $profile->localized('district'),
                'is_online' => $profile->status === 'online',
                'is_accepting' => $profile->is_accepting_orders,
                'is_verified' => $profile->is_verified,
                'completed_orders' => $profile->completed_orders_count,
                'categories' => $catsOut,
                'distance_km' => $distanceKm !== null ? round($distanceKm, 1) : null,
            ];
        });

        if ($hasGeo && $sort === 'distance') {
            // Masters without coords go to the end; accepting/online masters get a small bonus.
            $masters = $masters->sort(function ($a, $b) {
                $ad = $a['distance_km'] ?? PHP_FLOAT_MAX;
                $bd = $b['distance_km'] ?? PHP_FLOAT_MAX;
                // Bonus for actively accepting masters: 5 km credit.
                if (!empty($a['is_accepting']) && !empty($a['is_online'])) $ad -= 5;
                if (!empty($b['is_accepting']) && !empty($b['is_online'])) $bd -= 5;
                return $ad <=> $bd;
            })->values()->take(50);
        }

        return response()->json(['masters' => $masters]);
    }

    public function show(string $idOrSlug): JsonResponse
    {
        $id = $this->resolveId($idOrSlug);
        $profile = MasterProfile::with(['user', 'masterCategories.category', 'portfolioItems', 'skills.category'])
            ->whereHas('user', fn($q) => $q->where('id', $id)->where('is_active', true))
            ->firstOrFail();

        $user = $profile->user;
        $cats = $profile->masterCategories->map(fn($mc) => $mc->category)->filter()->unique('id')->values();
        $locale = app()->getLocale();
        $primaryCat = $cats->first();
        $slugParts = array_filter([
            $primaryCat ? $primaryCat->slugFor($locale) : null,
            $user->first_name ? \Illuminate\Support\Str::slug($user->first_name) : null,
            $user->last_name ? \Illuminate\Support\Str::slug($user->last_name) : null,
            (string) $user->id,
        ]);
        // Per-locale master slugs (drives hreflang alternates on the SSR'd
        // master page). Only the category prefix changes per language; first
        // / last names stay ASCII-Latin and the id-suffix is invariant.
        $slugTranslations = [];
        if ($primaryCat) {
            $primaryTranslations = ['az' => $primaryCat->slug] + ($primaryCat->slug_translations ?: []);
            foreach (['az', 'ru', 'en', 'tr', 'ar'] as $l) {
                $catPart = $primaryTranslations[$l] ?? $primaryCat->slug;
                $slugTranslations[$l] = implode('-', array_filter([
                    $catPart,
                    $user->first_name ? \Illuminate\Support\Str::slug($user->first_name) : null,
                    $user->last_name ? \Illuminate\Support\Str::slug($user->last_name) : null,
                    (string) $user->id,
                ]));
            }
        }
        $catsOut = $cats->map(fn ($c) => [
            'id' => $c->id,
            'slug' => $c->slugFor($locale),
            'slug_translations' => ['az' => $c->slug] + ($c->slug_translations ?: []),
            'name' => $c->nameFor($locale),
            'icon_url' => $c->icon_url,
            'base_price' => $c->pivot->base_price ?? null,
        ])->values();

        return response()->json([
            'master' => [
                'id' => $user->id,
                'slug' => implode('-', $slugParts),
                'slug_translations' => $slugTranslations,
                'first_name' => $user->localized('first_name'),
                'last_name' => $user->localized('last_name'),
                'full_name' => $user->full_name,
                'avatar_url' => $this->optimizeImageUrl($user->avatar_url, 400),
                'rating_avg' => $user->rating_avg,
                'rating_count' => $user->rating_count,
                'description' => $profile->localized('description'),
                'experience_years' => $profile->experience_years,
                'city' => $profile->localized('city'),
                'district' => $profile->localized('district'),
                'is_online' => $profile->status === 'online',
                'is_accepting' => $profile->is_accepting_orders,
                'is_verified' => $profile->is_verified,
                'completed_orders' => $profile->completed_orders_count,
                'urgent_available' => $profile->urgent_available,
                'work_radius_km' => $profile->work_radius_km,
                'languages' => $profile->languages,
                'categories' => $catsOut,
                'skills' => $profile->skills->groupBy(fn($s) => $s->category?->nameFor($locale) ?? 'Digər')->map(fn($group) => $group->map(fn($s) => [
                    'id' => $s->id,
                    'name' => $s->localized('name'),
                    'is_active' => $s->is_active,
                ])->values())->toArray(),
                'portfolio' => $profile->portfolioItems,
            ],
        ]);
    }

    public function reviews(Request $request, string $idOrSlug): JsonResponse
    {
        $id = $this->resolveId($idOrSlug);
        $user = User::where('id', $id)->where('is_active', true)->firstOrFail();

        $limit = (int) $request->query('limit', 5);
        $offset = (int) $request->query('offset', 0);

        $total = $user->reviewsReceived()->count();

        $reviews = $user->reviewsReceived()
            ->with(['reviewer', 'photos'])
            ->orderByDesc('created_at')
            ->skip($offset)
            ->take($limit)
            ->get()
            ->map(fn($r) => [
                'id' => $r->id,
                'rating' => $r->rating,
                'text' => $r->text,
                'reviewer_name' => $r->reviewer->first_name,
                'created_at' => $r->created_at,
                'photos' => $r->photos->map(fn($p) => [
                    'thumb' => $p->thumb_url,
                    'medium' => $p->medium_url,
                    'large' => $p->large_url,
                ]),
            ]);

        return response()->json([
            'reviews' => $reviews,
            'total' => $total,
            'has_more' => ($offset + $limit) < $total,
        ]);
    }
}
