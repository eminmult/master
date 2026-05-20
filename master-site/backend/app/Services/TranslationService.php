<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * AI translation via Gemini Flash.
 * All user-generated content is translated to 5 locales (az/ru/en/tr/ar).
 * Source locale is auto-detected when not provided.
 */
class TranslationService
{
    public const LOCALES = ['az', 'ru', 'en', 'tr', 'ar'];

    public const LOCALE_NAMES = [
        'az' => 'Azerbaijani',
        'ru' => 'Russian',
        'en' => 'English',
        'tr' => 'Turkish',
        'ar' => 'Arabic',
    ];

    public function isEnabled(): bool
    {
        return (bool) config('services.gemini.key');
    }

    /**
     * Detect source locale code of a text. Returns one of LOCALES or 'az' fallback.
     * Result is cached by md5(text) for 7 days.
     */
    public function detect(string $text): string
    {
        $text = trim($text);
        if ($text === '') return 'az';

        // Cheap heuristic first — avoids LLM call for clear signals
        if (preg_match('/[\x{0600}-\x{06FF}]/u', $text)) return 'ar';
        if (preg_match('/[\x{0400}-\x{04FF}]/u', $text)) return 'ru';

        $cacheKey = 'lang-detect:' . md5($text);
        return Cache::remember($cacheKey, now()->addDays(7), function () use ($text) {
            if (!$this->isEnabled()) return 'az';
            try {
                $resp = $this->call(
                    "You will be given a short user-written text. Return ONLY the 2-letter ISO 639-1 code " .
                    "of its language from this list: az, ru, en, tr, ar. " .
                    "If mixed, return the dominant one. Output one code, no quotes, no explanation.\n\n" .
                    "TEXT: <<<{$text}>>>"
                );
                $code = strtolower(trim(preg_replace('/[^a-z]/i', '', (string) $resp)));
                return in_array($code, self::LOCALES, true) ? $code : 'az';
            } catch (\Throwable $e) {
                Log::warning('translation_detect_failed', ['err' => $e->getMessage()]);
                return 'az';
            }
        });
    }

    /**
     * Translate a text to all target locales (excluding source).
     * Returns ['ru' => '…', 'en' => '…', …]. Missing/failed locales are skipped.
     */
    public function translateToAll(string $text, string $sourceLocale): array
    {
        $text = trim($text);
        if ($text === '') return [];

        $targets = array_values(array_diff(self::LOCALES, [$sourceLocale]));
        if (empty($targets)) return [];

        if (!$this->isEnabled()) {
            Log::warning('translation_service_disabled_no_key');
            return [];
        }

        $cacheKey = 'translate:' . md5($sourceLocale . '|' . $text);
        return Cache::remember($cacheKey, now()->addDays(30), function () use ($text, $sourceLocale, $targets) {
            $sourceName = self::LOCALE_NAMES[$sourceLocale] ?? $sourceLocale;
            $targetList = array_map(fn($t) => self::LOCALE_NAMES[$t] . " ({$t})", $targets);
            $targetStr = implode(', ', $targetList);

            $prompt = "You are a professional translator for a home services marketplace. " .
                "Translate the user-written text from {$sourceName} to: {$targetStr}. " .
                "RULES:\n" .
                "- Keep the tone natural and conversational (not formal legalese).\n" .
                "- Preserve URLs, @mentions, #tags, numbers, emoji, and line breaks exactly.\n" .
                "- Preserve technical terms (kilowatt, voltage, brand names) untranslated when appropriate.\n" .
                "- Do NOT add commentary, notes, or extra quotes.\n" .
                "- Return ONLY a strict JSON object keyed by the 2-letter ISO code, no markdown, no code fence.\n" .
                "- Example output: {\"ru\":\"…\",\"en\":\"…\",\"tr\":\"…\",\"ar\":\"…\"}\n\n" .
                "TEXT TO TRANSLATE: <<<{$text}>>>";

            try {
                $raw = $this->call($prompt);
                $json = $this->extractJson($raw);
                if (!is_array($json)) {
                    Log::warning('translation_bad_json', ['raw' => substr($raw ?? '', 0, 500)]);
                    return [];
                }
                $result = [];
                foreach ($targets as $t) {
                    if (!empty($json[$t]) && is_string($json[$t])) {
                        $result[$t] = trim($json[$t]);
                    }
                }
                return $result;
            } catch (\Throwable $e) {
                Log::warning('translation_failed', ['err' => $e->getMessage(), 'source' => $sourceLocale]);
                return [];
            }
        });
    }

    private function call(string $prompt): ?string
    {
        $key = config('services.gemini.key');
        $model = config('services.gemini.model', 'gemini-2.5-flash');

        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";

        $resp = Http::timeout(20)->retry(2, 500)->post($url, [
            'contents' => [[
                'parts' => [['text' => $prompt]],
            ]],
            'generationConfig' => [
                'temperature' => 0.2,
                'topP' => 0.9,
                'maxOutputTokens' => 2048,
            ],
        ]);

        if (!$resp->successful()) {
            Log::warning('gemini_http_error', ['status' => $resp->status(), 'body' => substr($resp->body(), 0, 500)]);
            return null;
        }

        $data = $resp->json();
        return $data['candidates'][0]['content']['parts'][0]['text'] ?? null;
    }

    private function extractJson(?string $raw): ?array
    {
        if (!$raw) return null;
        $raw = trim($raw);
        // Strip markdown code fences if present
        $raw = preg_replace('/^```(?:json)?\s*/i', '', $raw);
        $raw = preg_replace('/\s*```$/', '', $raw);
        // Find the first { and last } to be safe
        $start = strpos($raw, '{');
        $end = strrpos($raw, '}');
        if ($start === false || $end === false) return null;
        $json = substr($raw, $start, $end - $start + 1);
        $decoded = json_decode($json, true);
        return is_array($decoded) ? $decoded : null;
    }
}
