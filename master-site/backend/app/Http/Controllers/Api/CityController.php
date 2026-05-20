<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MasterProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class CityController extends Controller
{
    public function index(): JsonResponse
    {
        // Distinct cities from active master profiles, with a slug + count.
        // Cached because the set changes rarely and is consulted on every
        // /:city/:category route navigation.
        $cities = Cache::remember('cities:index', now()->addMinutes(15), function () {
            return MasterProfile::query()
                ->select('city')
                ->whereNotNull('city')
                ->where('city', '!=', '')
                ->whereHas('user', fn ($q) => $q->where('is_active', true))
                ->selectRaw('count(*) as masters_count')
                ->groupBy('city')
                ->get()
                ->map(fn ($row) => [
                    'name' => $row->city,
                    'slug' => Str::slug($row->city),
                    'masters_count' => (int) $row->masters_count,
                ])
                ->filter(fn ($c) => $c['slug'] !== '')
                // Different city spellings ("Bakı", "Baku", "baki") collapse to
                // the same slug; pick the highest-count spelling as the canonical
                // display name and sum the master counts.
                ->groupBy('slug')
                ->map(fn ($group) => [
                    'name' => $group->sortByDesc('masters_count')->first()['name'],
                    'slug' => $group->first()['slug'],
                    'masters_count' => (int) $group->sum('masters_count'),
                ])
                ->sortByDesc('masters_count')
                ->values()
                ->toArray(); // Plain array survives cache round-trips reliably.
        });

        return response()->json(['cities' => $cities]);
    }
}
