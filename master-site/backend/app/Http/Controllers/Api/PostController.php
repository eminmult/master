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
        // Direct match: requested locale + slug. The common path.
        $post = Post::query()
            ->where('slug', $slug)
            ->where('locale', $locale)
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->with('author:id,first_name,last_name,avatar_url')
            ->first();
        // Slug from a different locale on this URL — find the group and
        // hand back the current-locale row so the page renders in the
        // visitor's language. The frontend uses post.slug to redirect to
        // the canonical localized URL.
        if (!$post) {
            $other = Post::where('slug', $slug)->whereNotNull('published_at')->first();
            if ($other && $other->group_id) {
                $post = Post::where('group_id', $other->group_id)
                    ->where('locale', $locale)
                    ->whereNotNull('published_at')
                    ->where('published_at', '<=', now())
                    ->with('author:id,first_name,last_name,avatar_url')
                    ->first();
            }
            // Still nothing in current locale → graceful fallback to any
            // published version so URLs don't 404 mid-translation rollout.
            if (!$post && $other) {
                $post = $other->load('author:id,first_name,last_name,avatar_url');
            }
        }
        if (!$post) abort(404);

        // Per-locale slug map so the frontend can build hreflang alternates
        // and the language switcher points at the right localised URL.
        $slugTranslations = [];
        if ($post->group_id) {
            $slugTranslations = Post::where('group_id', $post->group_id)
                ->whereNotNull('published_at')
                ->where('published_at', '<=', now())
                ->pluck('slug', 'locale')->all();
        }
        $data = $post->toArray();
        $data['slug_translations'] = $slugTranslations;
        return response()->json(['post' => $data]);
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
