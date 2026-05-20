<?php

namespace App\Services;

use App\Models\Category;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SmartSearchService
{
    /**
     * Classify a user's problem into one of the existing categories.
     *
     * @param string      $description    Free-text description of the issue.
     * @param string|null $imageBase64    Optional base64-encoded photo (no data: prefix).
     * @param string|null $imageMime      Mime type of the photo (image/jpeg, image/png, etc.).
     * @return array{category_id:?int,category_name:?string,title:?string,description:?string,confidence:?float,raw:?array}
     */
    public function classify(string $description, ?string $imageBase64 = null, ?string $imageMime = null): array
    {
        $key = config('services.gemini.key');
        if (!$key) {
            return ['category_id' => null, 'category_name' => null, 'title' => null, 'description' => $description, 'confidence' => 0, 'raw' => null];
        }

        $categories = Category::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['id', 'name', 'slug', 'description']);

        $catLines = $categories->map(fn($c) => "- id={$c->id}: {$c->name}" . ($c->description ? " — {$c->description}" : ''))->implode("\n");

        $systemPrompt = "You are an expert dispatcher for a home-services marketplace. "
            . "Given a user's problem description (in Azerbaijani, Russian, English or Turkish) and possibly a photo, "
            . "pick the SINGLE most relevant service category from the list. "
            . "Respond with STRICT JSON only (no markdown fences, no prose), with keys: "
            . "category_id (integer, MUST be one of the provided ids), "
            . "title (short title of the problem, max 50 chars, in the same language as input), "
            . "description (cleaned-up description, 1-2 sentences, in the same language as input), "
            . "confidence (float 0..1).\n\n"
            . "Categories:\n{$catLines}";

        $userText = "Problem description:\n" . trim($description ?: '(no text, only photo)');

        $parts = [
            ['text' => $systemPrompt . "\n\n" . $userText],
        ];

        if ($imageBase64 && $imageMime) {
            $parts[] = [
                'inline_data' => [
                    'mime_type' => $imageMime,
                    'data' => $imageBase64,
                ],
            ];
        }

        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";

        try {
            $response = Http::timeout(20)
                ->acceptJson()
                ->asJson()
                ->post($url, [
                    'contents' => [['role' => 'user', 'parts' => $parts]],
                    'generationConfig' => [
                        'temperature' => 0.2,
                        'responseMimeType' => 'application/json',
                    ],
                ]);

            if (!$response->ok()) {
                Log::warning('Gemini classify failed', ['status' => $response->status(), 'body' => $response->body()]);
                return ['category_id' => null, 'category_name' => null, 'title' => null, 'description' => $description, 'confidence' => 0, 'raw' => null];
            }

            $data = $response->json();
            $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';

            // Strip accidental markdown fences if the model returns any.
            $text = trim(preg_replace('/^```(?:json)?\s*|\s*```$/mi', '', $text));
            $parsed = json_decode($text, true);

            if (!is_array($parsed)) {
                Log::warning('Gemini classify non-JSON response', ['text' => $text]);
                return ['category_id' => null, 'category_name' => null, 'title' => null, 'description' => $description, 'confidence' => 0, 'raw' => $data];
            }

            $catId = isset($parsed['category_id']) ? (int) $parsed['category_id'] : null;
            $valid = $categories->firstWhere('id', $catId);

            return [
                'category_id' => $valid ? $valid->id : null,
                'category_name' => $valid ? $valid->name : null,
                'title' => isset($parsed['title']) ? (string) $parsed['title'] : null,
                'description' => isset($parsed['description']) ? (string) $parsed['description'] : $description,
                'confidence' => isset($parsed['confidence']) ? (float) $parsed['confidence'] : 0,
                'raw' => $parsed,
            ];
        } catch (\Throwable $e) {
            Log::error('Gemini classify threw', ['e' => $e->getMessage()]);
            return ['category_id' => null, 'category_name' => null, 'title' => null, 'description' => $description, 'confidence' => 0, 'raw' => null];
        }
    }
}
