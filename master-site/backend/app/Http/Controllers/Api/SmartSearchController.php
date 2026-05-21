<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\SmartSearchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SmartSearchController extends Controller
{
    public function classify(Request $request, SmartSearchService $service): JsonResponse
    {
        $data = $request->validate([
            'description' => 'required_without:image|nullable|string|max:2000',
            'image' => 'nullable|string', // data-url or base64
            'image_mime' => 'nullable|string|max:80',
        ]);

        $description = $data['description'] ?? '';
        $imageB64 = $data['image'] ?? null;
        $imageMime = $data['image_mime'] ?? null;

        if ($imageB64 && str_starts_with($imageB64, 'data:')) {
            // data:image/jpeg;base64,....
            if (preg_match('/^data:([^;]+);base64,(.*)$/', $imageB64, $m)) {
                $imageMime = $imageMime ?: $m[1];
                $imageB64 = $m[2];
            }
        }

        // Hard cap on image size (5MB raw ≈ ~6.7MB base64).
        if ($imageB64 && strlen($imageB64) > 7 * 1024 * 1024) {
            return response()->json(['message' => 'Image too large'], 413);
        }

        $result = $service->classify($description, $imageB64, $imageMime);

        $categorySlug = $result['category_id']
            ? \App\Models\Category::where('id', $result['category_id'])->value('slug')
            : null;

        return response()->json([
            'category_id' => $result['category_id'],
            'category_slug' => $categorySlug,
            'category_name' => $result['category_name'],
            'title' => $result['title'],
            'description' => $result['description'],
            'confidence' => $result['confidence'],
        ]);
    }
}
