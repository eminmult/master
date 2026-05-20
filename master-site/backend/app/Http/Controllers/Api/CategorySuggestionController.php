<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\CategoryController;
use App\Models\Category;
use App\Models\CategorySuggestion;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CategorySuggestionController extends Controller
{
    /**
     * User submits a new category suggestion.
     * Available to any authenticated user (client or master).
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|min:2|max:80',
            'description' => 'nullable|string|max:500',
            'suggested_icon' => 'nullable|string|max:64',
        ]);

        $user = $request->user();

        // Soft dedupe: same user can't submit identical pending name
        $existing = CategorySuggestion::where('user_id', $user->id)
            ->where('name', $data['name'])
            ->where('status', CategorySuggestion::STATUS_PENDING)
            ->first();

        if ($existing) {
            return response()->json([
                'message' => 'Bu təklif artıq göndərilib və nəzərdən keçirilir.',
                'suggestion' => $existing,
            ], 200);
        }

        $suggestion = CategorySuggestion::create([
            'user_id' => $user->id,
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'suggested_icon' => $data['suggested_icon'] ?? null,
            'status' => CategorySuggestion::STATUS_PENDING,
        ]);

        return response()->json([
            'message' => 'Təklif göndərildi — admin baxışından sonra əlavə ediləcək.',
            'suggestion' => $suggestion,
        ], 201);
    }

    /**
     * Current user's own submissions.
     */
    public function mine(Request $request): JsonResponse
    {
        $user = $request->user();
        $list = CategorySuggestion::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return response()->json(['suggestions' => $list]);
    }

    /**
     * Admin list — all suggestions, filterable by status.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin()) return response()->json(['message' => 'İcazə yoxdur.'], 403);

        $q = CategorySuggestion::with(['user:id,first_name,last_name,role', 'reviewer:id,first_name']);
        if ($status = $request->query('status')) {
            $q->where('status', $status);
        }
        $suggestions = $q->orderByDesc('created_at')->limit(200)->get();
        $pendingCount = CategorySuggestion::where('status', CategorySuggestion::STATUS_PENDING)->count();

        return response()->json([
            'suggestions' => $suggestions,
            'pending_count' => $pendingCount,
        ]);
    }

    /**
     * Admin approves a suggestion → creates a Category, links it.
     */
    public function approve(Request $request, CategorySuggestion $suggestion): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin()) return response()->json(['message' => 'İcazə yoxdur.'], 403);

        if ($suggestion->status !== CategorySuggestion::STATUS_PENDING) {
            return response()->json(['message' => 'Bu təklif artıq nəzərdən keçirilib.'], 422);
        }

        $data = $request->validate([
            'name' => 'nullable|string|max:80',
            'icon_url' => 'nullable|string|max:64',
            'admin_note' => 'nullable|string|max:500',
        ]);

        $name = $data['name'] ?? $suggestion->name;
        $icon = $data['icon_url'] ?? $suggestion->suggested_icon ?? 'category';
        $baseSlug = Str::slug($name);
        $slug = $baseSlug;
        $suffix = 2;
        while (Category::where('slug', $slug)->exists()) {
            $slug = $baseSlug . '-' . $suffix++;
        }

        $category = Category::create([
            'name' => $name,
            'slug' => $slug,
            'icon_url' => $icon,
            'description' => $suggestion->description,
            'sort_order' => (int) Category::max('sort_order') + 1,
            'is_active' => true,
        ]);

        $suggestion->update([
            'status' => CategorySuggestion::STATUS_APPROVED,
            'reviewed_by' => $user->id,
            'reviewed_at' => now(),
            'admin_note' => $data['admin_note'] ?? null,
            'category_id' => $category->id,
        ]);

        CategoryController::clearCache();

        return response()->json([
            'message' => 'Təklif təsdiqləndi — kateqoriya əlavə olundu.',
            'category' => $category,
            'suggestion' => $suggestion->fresh(),
        ]);
    }

    public function reject(Request $request, CategorySuggestion $suggestion): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin()) return response()->json(['message' => 'İcazə yoxdur.'], 403);

        if ($suggestion->status !== CategorySuggestion::STATUS_PENDING) {
            return response()->json(['message' => 'Bu təklif artıq nəzərdən keçirilib.'], 422);
        }

        $data = $request->validate([
            'admin_note' => 'nullable|string|max:500',
        ]);

        $suggestion->update([
            'status' => CategorySuggestion::STATUS_REJECTED,
            'reviewed_by' => $user->id,
            'reviewed_at' => now(),
            'admin_note' => $data['admin_note'] ?? null,
        ]);

        return response()->json([
            'message' => 'Təklif rədd edildi.',
            'suggestion' => $suggestion->fresh(),
        ]);
    }
}
