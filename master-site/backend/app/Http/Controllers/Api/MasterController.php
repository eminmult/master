<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MasterController extends Controller
{
    public function updateProfile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'nullable|email|unique:users,email,' . $request->user()->id,
            'description' => 'nullable|string|max:2000',
            'city' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'experience_years' => 'nullable|integer|min:0|max:50',
            'category_ids' => 'nullable|array',
            'category_ids.*' => 'exists:categories,id',
        ]);

        $request->user()->update([
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'email' => $data['email'] ?? null,
        ]);

        $profile = $request->user()->masterProfile;
        if ($profile) {
            $profile->update([
                'description' => $data['description'] ?? $profile->description,
                'city' => $data['city'] ?? $profile->city,
                'district' => $data['district'] ?? $profile->district,
                'experience_years' => $data['experience_years'] ?? $profile->experience_years,
            ]);

            // Update categories
            if (isset($data['category_ids'])) {
                $profile->masterCategories()->delete();
                foreach ($data['category_ids'] as $catId) {
                    $profile->masterCategories()->create(['category_id' => $catId]);
                }
            }
        }

        return response()->json(['user' => $request->user()->fresh()->load('masterProfile.masterCategories.category')]);
    }

    public function updateStatus(Request $request): JsonResponse
    {
        $request->validate(['status' => 'required|in:online,offline,busy']);

        $profile = $request->user()->masterProfile;
        if (!$profile) {
            return response()->json(['message' => 'Profil tapılmadı.'], 404);
        }

        $profile->update([
            'status' => $request->status,
            'is_accepting_orders' => $request->status === 'online',
        ]);

        return response()->json(['status' => $request->status]);
    }

    public function updateLocation(Request $request): JsonResponse
    {
        $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
        ]);

        $profile = $request->user()->masterProfile;
        if ($profile) {
            $profile->updateLocation($request->lat, $request->lng);
        }

        return response()->json(['ok' => true]);
    }
}
