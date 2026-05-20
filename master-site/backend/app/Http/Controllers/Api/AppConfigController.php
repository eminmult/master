<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Mobile bootstrap config. Mobile clients fetch on app open to:
 *   - Decide if they should force the user to update.
 *   - Pick up dynamic feature flags without a release.
 *   - Show maintenance banner if the API is degraded.
 *
 * Versions are simple semver strings; mobile compares its own bundle version
 * against `min_supported_version` and shows a hard wall if behind.
 */
class AppConfigController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json([
            'min_supported_version' => [
                'ios' => env('APP_MIN_VERSION_IOS', '1.0.0'),
                'android' => env('APP_MIN_VERSION_ANDROID', '1.0.0'),
            ],
            'latest_version' => [
                'ios' => env('APP_LATEST_VERSION_IOS', '1.0.0'),
                'android' => env('APP_LATEST_VERSION_ANDROID', '1.0.0'),
            ],
            'force_update' => (bool) env('APP_FORCE_UPDATE', false),
            'maintenance' => (bool) env('APP_MAINTENANCE', false),
            'maintenance_message' => env('APP_MAINTENANCE_MESSAGE'),
            'store_urls' => [
                'ios' => env('APP_STORE_URL_IOS'),
                'android' => env('APP_STORE_URL_ANDROID'),
            ],
            'features' => [
                'subscription_required' => (bool) config('master.subscription_required', false),
                'free_launch_until' => config('master.free_launch_until'),
                'reverb_enabled' => env('REVERB_APP_KEY') !== null && env('REVERB_APP_KEY') !== '',
            ],
            'support' => [
                'email' => env('SUPPORT_EMAIL', 'support@itez.app'),
                'phone' => env('SUPPORT_PHONE'),
                'whatsapp' => env('SUPPORT_WHATSAPP'),
            ],
            'urls' => [
                'web' => env('FRONTEND_URL', 'https://itez.app'),
                'terms' => rtrim(env('FRONTEND_URL', 'https://itez.app'), '/') . '/terms',
                'privacy' => rtrim(env('FRONTEND_URL', 'https://itez.app'), '/') . '/privacy',
            ],
            'server_time' => now()->toIso8601String(),
        ]);
    }
}
