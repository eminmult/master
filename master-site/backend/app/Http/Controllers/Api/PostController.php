<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index(): JsonResponse
    {
        $locale = app()->getLocale();
        $posts = Post::query()
            ->where('locale', $locale)
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->orderByDesc('published_at')
            ->limit(50)
            ->get(['id', 'slug', 'title', 'excerpt', 'hero_url', 'published_at']);
        return response()->json(['posts' => $posts]);
    }

    public function show(string $slug): JsonResponse
    {
        $locale = app()->getLocale();
        // Prefer the requested locale; if the post hasn't been translated
        // there yet, fall back to any other published version so the URL
        // doesn't 404 mid-rollout. Order puts canonical AZ first, then EN, RU.
        $fallbackOrder = array_unique([$locale, 'az', 'en', 'ru', 'tr', 'ar']);
        $post = null;
        foreach ($fallbackOrder as $l) {
            $post = Post::query()
                ->where('slug', $slug)
                ->where('locale', $l)
                ->whereNotNull('published_at')
                ->where('published_at', '<=', now())
                ->with('author:id,first_name,last_name,avatar_url')
                ->first();
            if ($post) break;
        }
        if (!$post) abort(404);
        return response()->json(['post' => $post]);
    }

    // Admin-only create/update. Reuses the existing role middleware mounted in
    // routes/api.php so this controller stays free of permission checks.
    public function upsert(Request $request): JsonResponse
    {
        $data = $request->validate([
            'slug' => 'required|string|max:191|regex:/^[a-z0-9-]+$/',
            'locale' => 'required|string|in:az,ru,en,tr,ar',
            'title' => 'required|string|max:200',
            'excerpt' => 'nullable|string|max:320',
            'body_md' => 'required|string',
            'hero_url' => 'nullable|url|max:512',
            'published_at' => 'nullable|date',
        ]);
        $data['author_id'] = $request->user()->id;
        $post = Post::updateOrCreate(
            ['slug' => $data['slug'], 'locale' => $data['locale']],
            $data,
        );
        return response()->json(['post' => $post], 201);
    }

    public function destroy(Request $request, string $slug, string $locale): JsonResponse
    {
        Post::where('slug', $slug)->where('locale', $locale)->delete();
        return response()->json(['ok' => true]);
    }
}
