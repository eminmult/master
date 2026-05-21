<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class CategoryController extends Controller
{
    private const CACHE_TTL_MIN = 360; // 6 hours
    private const CACHE_KEY_LIST = 'categories:list';
    private const CACHE_KEY_LIST_FULL = 'categories:list:full';

    public function index(Request $request): JsonResponse
    {
        $withSubs = $request->boolean('include_subcategories');
        $onlyWithMasters = $request->boolean('only_with_masters');
        $locale = app()->getLocale();

        $suffix = ($withSubs ? ':subs' : '') . ($onlyWithMasters ? ':wm' : '') . ':' . $locale;
        $key = 'categories:list' . $suffix;

        $categories = Cache::remember($key, now()->addMinutes(self::CACHE_TTL_MIN), function () use ($withSubs, $onlyWithMasters, $locale) {
            $query = Category::where('is_active', true)->orderBy('sort_order');
            if ($withSubs) {
                $query->with(['subcategories' => fn($q) => $q->where('is_active', true)]);
            }

            $query->withCount([
                'masterProfiles as masters_count' => function ($q) {
                    $q->whereHas('user', fn($u) => $u->where('is_active', true));
                },
            ]);

            if ($onlyWithMasters) {
                $query->whereHas('masterProfiles', fn($q) => $q->whereHas('user', fn($u) => $u->where('is_active', true)));
            }

            return $query->get()->map(fn ($c) => $this->projectCategory($c, $locale, $withSubs))->toArray();
        });

        return response()->json(['categories' => $categories]);
    }

    public function show(Category $category): JsonResponse
    {
        $locale = app()->getLocale();
        $cacheKey = 'categories:show:' . $category->id . ':' . $locale;

        $data = Cache::remember($cacheKey, now()->addMinutes(self::CACHE_TTL_MIN), function () use ($category, $locale) {
            $category->load(['subcategories' => fn($q) => $q->where('is_active', true)]);
            $projected = $this->projectCategory($category, $locale, true);
            // Attach AI-generated long-form content for this locale (falls back
            // to AZ if the target locale hasn't been generated yet).
            $content = \App\Models\CategoryContent::where('category_id', $category->id)
                ->where('locale', $locale)
                ->value('body')
                ?: \App\Models\CategoryContent::where('category_id', $category->id)
                    ->where('locale', 'az')
                    ->value('body');
            $projected['content'] = $content ?: null;
            return $projected;
        });

        return response()->json(['category' => $data]);
    }

    /**
     * Shape a Category for API output with localized name/slug/description.
     * Original AZ values are exposed too so clients can fall back if needed.
     */
    private function projectCategory(Category $c, string $locale, bool $withSubs): array
    {
        // Hybrid strategy: ONE canonical slug across every locale (the AZ
        // value). Page content (name, description) is localized, but URL
        // stays /category/santexnik regardless of language. Google ranks by
        // content + meta, not slug — Bolt/Glovo/Wolt/Yandex.Услуги all
        // localize content, not URLs. Eliminates the bulk of per-locale
        // slug redirect / cache / fallback complexity.
        return [
            'id' => $c->id,
            'name' => $c->nameFor($locale),
            'name_az' => $c->name,
            'slug' => $c->slug, // canonical AZ
            'icon_url' => $c->icon_url,
            'description' => $c->descriptionFor($locale),
            'sort_order' => $c->sort_order,
            'masters_count' => $c->masters_count ?? null,
            'subcategories' => $withSubs && $c->relationLoaded('subcategories')
                ? $c->subcategories->map(fn ($s) => [
                    'id' => $s->id,
                    'name' => $s->name,
                    'slug' => $s->slug,
                ])->toArray()
                : null,
        ];
    }

    public static function clearCache(): void
    {
        Cache::forget(self::CACHE_KEY_LIST);
        Cache::forget(self::CACHE_KEY_LIST_FULL);
    }
}
