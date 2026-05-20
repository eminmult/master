<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserProfileController extends Controller
{
    public function show(string $idOrSlug): JsonResponse
    {
        $id = ctype_digit($idOrSlug)
            ? (int) $idOrSlug
            : (preg_match('/-(\d+)$/', $idOrSlug, $m) ? (int) $m[1] : abort(404));
        $user = User::where('id', $id)->where('is_active', true)->firstOrFail();

        $reviews = $user->reviewsReceived()
            ->with(['reviewer:id,first_name,last_name,avatar_url', 'photos'])
            ->orderByDesc('created_at')
            ->limit(20)
            ->get()
            ->map(fn($r) => [
                'id' => $r->id,
                'rating' => $r->rating,
                'text' => $r->text,
                'photos' => $r->photos->map(fn($p) => ['thumb' => $p->thumb_url, 'medium' => $p->medium_url, 'large' => $p->large_url]),
                'reviewer_name' => $r->reviewer->first_name,
                'created_at' => $r->created_at,
            ]);

        // Locale-aware SEO slug: "{localized-category-slug}-{first}-{last}-{id}".
        $locale = app()->getLocale();
        $primaryCat = $user->isMaster() && $user->masterProfile
            ? $user->masterProfile->load('masterCategories.category')
                ->masterCategories->map(fn ($mc) => $mc->category)->filter()->first()
            : null;
        $slugParts = array_filter([
            $primaryCat ? $primaryCat->slugFor($locale) : null,
            $user->first_name ? \Illuminate\Support\Str::slug($user->first_name) : null,
            $user->last_name ? \Illuminate\Support\Str::slug($user->last_name) : null,
            (string) $user->id,
        ]);
        // Cross-locale slugs for hreflang. Only the category prefix varies.
        $slugTranslations = [];
        if ($primaryCat) {
            $primaryTranslations = ['az' => $primaryCat->slug] + ($primaryCat->slug_translations ?: []);
            foreach (['az', 'ru', 'en', 'tr', 'ar'] as $l) {
                $slugTranslations[$l] = implode('-', array_filter([
                    $primaryTranslations[$l] ?? $primaryCat->slug,
                    $user->first_name ? \Illuminate\Support\Str::slug($user->first_name) : null,
                    $user->last_name ? \Illuminate\Support\Str::slug($user->last_name) : null,
                    (string) $user->id,
                ]));
            }
        }

        $data = [
            'id' => $user->id,
            'slug' => implode('-', $slugParts),
            'slug_translations' => $slugTranslations,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'full_name' => $user->full_name,
            'avatar_url' => $user->avatar_url,
            'role' => $user->role,
            'rating_avg' => $user->rating_avg,
            'rating_count' => $user->rating_count,
            'is_verified' => (bool) $user->is_verified,
            'verified_at' => $user->verified_at?->toIso8601String(),
            'created_at' => $user->created_at,
            'reviews' => $reviews,
        ];

        // Add master-specific data
        if ($user->isMaster() && $user->masterProfile) {
            $profile = $user->masterProfile;
            $profile->load('masterCategories.category', 'skills.category', 'portfolioItems');
            $cats = $profile->masterCategories->map(fn($mc) => $mc->category)->filter()->unique('id')->values();

            $data['master_profile'] = [
                'description' => $profile->description,
                'experience_years' => $profile->experience_years,
                'city' => $profile->city,
                'district' => $profile->district,
                'is_online' => $profile->status === 'online',
                'is_accepting' => $profile->is_accepting_orders,
                'is_verified' => $profile->is_verified,
                'completed_orders' => $profile->completed_orders_count,
                'urgent_available' => $profile->urgent_available,
                'work_radius_km' => $profile->work_radius_km,
                'languages' => $profile->languages,
                'categories' => $cats->map(fn ($c) => [
                    'id' => $c->id,
                    'slug' => $c->slugFor($locale),
                    'name' => $c->nameFor($locale),
                    'icon_url' => $c->icon_url,
                ])->values(),
                'skills' => $profile->skills->groupBy(fn($s) => $s->category?->nameFor($locale) ?? 'Other')->map(fn($group) => $group->map(fn($s) => [
                    'id' => $s->id,
                    'name' => $s->name,
                ])->values())->toArray(),
                'portfolio' => $profile->portfolioItems,
            ];
        }

        // Client stats
        if ($user->isClient()) {
            $data['orders_count'] = $user->clientOrders()->whereIn('status', ['completed', 'closed'])->count();
        }

        return response()->json(['profile' => $data]);
    }
}
