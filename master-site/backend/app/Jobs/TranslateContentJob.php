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
                $cleaned = $this->cleanupText($value, $src, $this->modelClass, $field);
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
     * Polish user-supplied text in its original language. Prompt is chosen
     * by the model class — master bios get the marketing structure, client
     * orders get a clarifying rewrite that preserves the problem statement.
     * Result REPLACES the canonical column so future edits show the polish.
     */
    private function cleanupText(string $text, string $locale, string $modelClass = '', string $field = ''): ?string
    {
        $key = config('services.gemini.key');
        if (!$key) return null;
        $langName = TranslationService::LOCALE_NAMES[$locale] ?? $locale;
        // Order description/comment have very different shape from master
        // bios — keep them concise problem statements, not marketing copy.
        $isOrder = is_a($modelClass, \App\Models\Order::class, true);
        $prompt = $isOrder
            ? $this->orderCleanupPrompt($langName, $text, $field)
            : $this->masterBioCleanupPrompt($langName, $text);
        $cfg = $isOrder
            ? ['temperature' => 0.2, 'maxOutputTokens' => 2048]
            : ['temperature' => 0.4, 'maxOutputTokens' => 4096];
        $maxLen = $isOrder ? 1000 : 2000;

        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";
        try {
            $resp = \Illuminate\Support\Facades\Http::timeout(60)
                ->retry(2, 1500, throw: false)
                ->asJson()
                ->post($url, [
                    'contents' => [['parts' => [['text' => $prompt]]]],
                    'generationConfig' => $cfg,
                ]);
            if (!$resp->ok()) return null;
            $clean = $resp->json('candidates.0.content.parts.0.text');
            $clean = is_string($clean) ? trim($clean) : null;
            // Orders shouldn't shrink (don't drop key facts); bios may
            // elaborate but cap at $maxLen to block runaway hallucination.
            if (!$clean || mb_strlen($clean) > $maxLen) return null;
            if (!$isOrder && mb_strlen($clean) < mb_strlen($text)) return null;
            return $clean;
        } catch (\Throwable $e) {
            Log::warning('translate_cleanup_failed', ['err' => $e->getMessage()]);
            return null;
        }
    }

    private function masterBioCleanupPrompt(string $langName, string $text): string
    {
        return "You are a copywriter for itez.app, a home-services marketplace in Azerbaijan. "
            . "A tradesperson has written their bio in {$langName} below. It may be a bare list "
            . "of services, a few keywords, or a half-finished sentence. Rewrite it into a polished, "
            . "professional bio in {$langName} with the EXACT structure described below.\n\n"
            . "STRUCTURE (mandatory, render exactly this shape):\n"
            . "1. An opening paragraph (2-3 sentences) introducing the master — experience, qualification, "
            . "approach to work. No bullet points here.\n"
            . "2. A blank line, then a short header like 'Services:' (use the {$langName} equivalent).\n"
            . "3. A list of services, ONE PER LINE, each starting with '• ' (a bullet character and a space). "
            . "Each item is a short noun phrase, NOT a sentence.\n"
            . "4. A blank line, then a short closing line (one sentence) — availability, response time, or a "
            . "call to action.\n\n"
            . "RULES:\n"
            . "- Preserve every concrete fact (services, years, brands). Do NOT invent.\n"
            . "- Use bullet character '• ' (U+2022 + space), not '-' or '*'.\n"
            . "- Target 400-900 characters. Confident but not boastful.\n"
            . "- Preserve brand names (GROHE, Bosch, Hansgrohe) untranslated.\n"
            . "- Output ONLY the bio in {$langName}. No quotes, no commentary, no Markdown headers.\n\n"
            . "SOURCE BIO:\n<<<\n{$text}\n>>>";
    }

    /**
     * Order/announcement cleanup — turn a few keywords into a clear,
     * concise problem statement so masters know what they're being asked
     * to do. NO marketing flourish, NO invented details.
     */
    private function orderCleanupPrompt(string $langName, string $text, string $field): string
    {
        $kind = $field === 'comment' ? 'client comment' : 'order description';
        return "You are an editor for itez.app, a home-services marketplace. A client wrote the {$kind} below "
            . "in {$langName}. Rewrite it into a clear, concise problem statement in {$langName} that a "
            . "tradesperson can quote on. RULES:\n"
            . "- Fix typos, grammar, capitalisation, punctuation.\n"
            . "- Add only natural connective sentences. Do NOT invent facts (no fake dimensions, no fake "
            . "deadlines, no fake brands or models).\n"
            . "- Keep the original language ({$langName}). Keep the client's tone (informal stays informal).\n"
            . "- 1-3 short paragraphs, total 50-400 characters typically. No bullet lists.\n"
            . "- Preserve URLs, numbers, prices, addresses, dimensions exactly.\n"
            . "- Output ONLY the rewritten {$kind} in {$langName}. No quotes, no commentary.\n\n"
            . "SOURCE:\n<<<\n{$text}\n>>>";
    }

    private function isStructuredJson(string $value): bool
    {
        $t = ltrim($value);
        if (!str_starts_with($t, '{')) return false;
        $decoded = json_decode($t, true);
        return is_array($decoded) && isset($decoded['_type']);
    }
}
