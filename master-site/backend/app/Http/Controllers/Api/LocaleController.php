<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class LocaleController extends Controller
{
    private const CACHE_TTL_MIN = 360;
    private const CACHE_KEY = 'i18n:locales:active';

    /**
     * Public list of active locales — both clients (site + mobile) load
     * this on bootstrap so the language selector and supported set stay
     * in sync without code changes.
     */
    public function index(): JsonResponse
    {
        $locales = Cache::remember(self::CACHE_KEY, now()->addMinutes(self::CACHE_TTL_MIN), function () {
            return DB::table('locales')
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->get(['code', 'name', 'dir', 'is_default', 'sort_order'])
                ->map(fn($l) => [
                    'code' => $l->code,
                    'name' => $l->name,
                    'dir' => $l->dir,
                    'is_default' => (bool) $l->is_default,
                    'sort_order' => (int) $l->sort_order,
                ])
                ->all();
        });

        return response()->json(['locales' => $locales]);
    }

    /**
     * Persist the authenticated user's preferred locale. Both clients call
     * this on every language switch so logging in elsewhere starts in the
     * same language.
     */
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'locale' => 'required|string|max:8',
        ]);

        $exists = DB::table('locales')
            ->where('code', $data['locale'])
            ->where('is_active', true)
            ->exists();

        if (! $exists) {
            return response()->json(['error' => 'unsupported_locale'], 422);
        }

        $user = Auth::user();
        $user->locale = $data['locale'];
        $user->save();

        return response()->json(['locale' => $user->locale]);
    }

    public static function clearCache(): void
    {
        Cache::forget(self::CACHE_KEY);
    }
}
