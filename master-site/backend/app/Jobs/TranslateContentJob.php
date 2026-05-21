<?php

namespace App\Jobs;

use App\Services\TranslationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Translates the given fields of a model to all supported locales.
 * Dispatched by HasAutoTranslation trait when a translatable field changes.
 */
class TranslateContentJob implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [30, 120, 300];
    public int $uniqueFor = 300;

    public function __construct(
        public string $modelClass,
        public int $modelId,
        public array $fields,
        public ?string $sourceLocale = null,
    ) {
        $this->onQueue('translations');
    }

    public function uniqueId(): string
    {
        return $this->modelClass . ':' . $this->modelId . ':' . implode(',', $this->fields);
    }

    public function handle(TranslationService $svc): void
    {
        if (!class_exists($this->modelClass)) return;

        /** @var \Illuminate\Database\Eloquent\Model|null $model */
        $model = $this->modelClass::find($this->modelId);
        if (!$model) return;

        if (!$svc->isEnabled()) {
            Log::warning('translate_job_skipped_disabled', [
                'model' => $this->modelClass, 'id' => $this->modelId,
            ]);
            return;
        }

        // Resolve source locale once for this pass
        $source = $this->sourceLocale ?: ($model->content_locale ?? null);

        $updates = [];
        foreach ($this->fields as $field) {
            $value = (string) ($model->{$field} ?? '');
            $value = trim($value);
            if ($value === '') continue;

            // Skip structured chat messages (e.g., {"_type":"proposal",...})
            if ($this->isStructuredJson($value)) continue;

            $src = $source ?: $svc->detect($value);
            if (!$source) $source = $src;

            // Cleanup pass for long-form text only. Short fields (names,
            // city names) are proper nouns or single-token values where
            // "fixing typos" would erase valid spellings; we go straight to
            // translation/transliteration for those.
            if (mb_strlen($value) >= 50) {
                $cleaned = $this->cleanupText($value, $src);
                if ($cleaned && $cleaned !== $value) {
                    $updates[$field] = $cleaned;
                    $value = $cleaned;
                }
            }

            $translations = $svc->translateToAll($value, $src);
            if (!empty($translations) || $value !== '') {
                // Seed the source locale with the cleaned text so reading
                // translations[$current_locale] always works.
                $translations[$src] = $value;
                $updates[$field . '_translations'] = $translations;
            }
        }

        if ($source) {
            $updates['content_locale'] = $source;
        }

        if (!empty($updates)) {
            // saveQuietly — avoid re-triggering saved() event and infinite loop
            $model->forceFill($updates)->saveQuietly();
        }
    }

    /**
     * Light cleanup of user-supplied text in its original language:
     * typos, grammar, capitalisation, punctuation. Returns null on any LLM
     * failure (caller falls back to the unchanged source).
     */
    private function cleanupText(string $text, string $locale): ?string
    {
        $key = config('services.gemini.key');
        if (!$key) return null;
        $langName = TranslationService::LOCALE_NAMES[$locale] ?? $locale;
        $prompt = "You are an editor for itez.app, a home-services marketplace. "
            . "A tradesperson wrote the text below in {$langName}. Fix typos, grammar, "
            . "capitalisation and punctuation. Keep the original wording and tone — do "
            . "not add new content, do not restructure. Output ONLY the cleaned text in "
            . "{$langName} (no quotes, no commentary).\n\nTEXT:\n<<<\n{$text}\n>>>";
        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";
        try {
            $resp = \Illuminate\Support\Facades\Http::timeout(40)
                ->retry(2, 1500, throw: false)
                ->asJson()
                ->post($url, [
                    'contents' => [['parts' => [['text' => $prompt]]]],
                    'generationConfig' => ['temperature' => 0.1, 'maxOutputTokens' => 4096],
                ]);
            if (!$resp->ok()) return null;
            $clean = $resp->json('candidates.0.content.parts.0.text');
            $clean = is_string($clean) ? trim($clean) : null;
            // Guard: drop suspiciously-grown output (>30% larger) — likely
            // the model added commentary.
            if (!$clean || mb_strlen($clean) > mb_strlen($text) * 1.3) return null;
            return $clean;
        } catch (\Throwable $e) {
            Log::warning('translate_cleanup_failed', ['err' => $e->getMessage()]);
            return null;
        }
    }

    private function isStructuredJson(string $value): bool
    {
        $t = ltrim($value);
        if (!str_starts_with($t, '{')) return false;
        $decoded = json_decode($t, true);
        return is_array($decoded) && isset($decoded['_type']);
    }
}
