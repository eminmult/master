<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Mobile push token registration. Mobile app calls /devices/register at sign-in
 * (and on token refresh from FCM/APNs callbacks). On logout — /devices/unregister.
 */
class DeviceController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'platform' => 'required|in:ios,android,web',
            'token' => 'required|string|max:512',
            'app_version' => 'nullable|string|max:20',
            'device_model' => 'nullable|string|max:100',
            'locale' => 'nullable|string|max:5',
        ]);

        // Token is unique — if it already exists (e.g. user logged out and back in)
        // we just rebind it to the current user.
        $device = DeviceToken::updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => $request->user()->id,
                'platform' => $data['platform'],
                'app_version' => $data['app_version'] ?? null,
                'device_model' => $data['device_model'] ?? null,
                'locale' => $data['locale'] ?? null,
                'last_active_at' => now(),
            ]
        );

        return response()->json(['device' => $device]);
    }

    public function unregister(Request $request): JsonResponse
    {
        $data = $request->validate(['token' => 'required|string|max:512']);

        DeviceToken::where('user_id', $request->user()->id)
            ->where('token', $data['token'])
            ->delete();

        return response()->json(['ok' => true]);
    }
}
