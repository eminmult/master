<?php

namespace App\Console\Commands;

use App\Models\MasterProfile;
use App\Services\TranslationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Backfill description_translations for every master profile that has a
 * non-empty description. Pre-existing masters never tripped the
 * HasAutoTranslation trait (rows existed before the trait was added or the
 * description was saved through a raw query), so /ru/master/X showed
 * the bio in whatever language the master originally typed.
 *
 * Runs inline (sync) so we can ship localized content immediately. Future
 * description edits go through TranslateContentJob via the saved() hook.
 */
class BackfillMasterTranslations extends Command
{
    protected $signature = 'translations:backfill-masters
        {--only= : Process only master profile with the given id}
        {--force : Re-translate even if translations already exist}';

    protected $description = 'Translate every master profile description into all supported locales via Gemini.';

    public function handle(TranslationService $svc): int
    {
        if (!$svc->isEnabled()) {
            $this->error('GEMINI_KEY missing.');
            return self::FAILURE;
        }

        $q = MasterProfile::query()->whereNotNull('description')->where('description', '!=', '');
        if ($only = $this->option('only')) $q->where('id', $only);
        $profiles = $q->get();

        if ($profiles->isEmpty()) {
            $this->warn('No master profiles with description.');
            return self::SUCCESS;
        }

        $ok = 0; $skipped = 0; $failed = 0;
        $bar = $this->output->createProgressBar($profiles->count());
        $bar->start();
        foreach ($profiles as $p) {
            $existing = $p->description_translations ?? [];
            $needed = array_diff(TranslationService::LOCALES, array_keys(is_array($existing) ? $existing : []));
            if (empty($needed) && !$this->option('force')) {
                $skipped++;
                $bar->advance();
                continue;
            }

            try {
                $source = $p->content_locale ?: $svc->detect($p->description);
                // Translate one locale at a time — TranslationService's
                // combined-all-locales prompt hits its 2048-token output cap
                // for ~700+ char bios and returns []. Per-locale calls fit.
                $translations = [];
                foreach (array_diff(TranslationService::LOCALES, [$source]) as $target) {
                    $r = $this->translateSingleLocale($p->description, $source, $target);
                    if ($r) $translations[$target] = $r;
                }
                // Always seed the source locale with the original so callers
                // can read translations[$locale] uniformly.
                $translations[$source] = $p->description;
                $merged = is_array($existing) ? array_merge($existing, $translations) : $translations;

                $p->forceFill([
                    'description_translations' => $merged,
                    'content_locale' => $source,
                ])->saveQuietly(); // saveQuietly avoids re-triggering the auto-translation hook
                $ok++;
                $this->info(" #{$p->id} ({$source}) → " . implode(',', array_keys($translations)));
            } catch (\Throwable $e) {
                Log::warning('backfill master translation failed', ['id' => $p->id, 'err' => $e->getMessage()]);
                $this->error(" #{$p->id} → " . $e->getMessage());
                $failed++;
            }
            $bar->advance();
        }
        $bar->finish();
        $this->newLine();
        $this->info("Done. ok={$ok} skipped={$skipped} failed={$failed}");
        return self::SUCCESS;
    }

    /**
     * One Gemini call per target locale. The shared TranslationService caps
     * output at 2048 tokens for an all-locales call, which truncates ~700+
     * char bios into empty JSON; splitting the work fits the cap and lets us
     * retry per-locale on transient failures.
     */
    private function translateSingleLocale(string $text, string $source, string $target): ?string
    {
        $sourceName = TranslationService::LOCALE_NAMES[$source] ?? $source;
        $targetName = TranslationService::LOCALE_NAMES[$target] ?? $target;
        $prompt = "You are a professional translator for itez.app, a home-services marketplace. "
            . "Translate the master's bio from {$sourceName} to {$targetName}.\n\n"
            . "RULES:\n"
            . "- Tone: natural, professional, conversational. Light cleanup of obvious grammar/typo issues is allowed.\n"
            . "- Preserve URLs, @mentions, #tags, numbers, emoji and line breaks.\n"
            . "- Preserve brand names (GROHE, Hansgrohe, Bosch, etc.) untranslated.\n"
            . "- Output ONLY the translated text — no quotes, no explanation, no markdown.\n\n"
            . "SOURCE BIO:\n<<<\n{$text}\n>>>";

        $key = config('services.gemini.key');
        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";

        $resp = Http::timeout(60)
            ->retry(3, 1500, throw: false)
            ->asJson()
            ->post($url, [
                'contents' => [['parts' => [['text' => $prompt]]]],
                'generationConfig' => [
                    'temperature' => 0.3,
                    'maxOutputTokens' => 4096,
                ],
            ]);

        if (!$resp->ok()) {
            Log::warning('master_translation_http_error', [
                'status' => $resp->status(), 'target' => $target,
                'body' => substr($resp->body(), 0, 200),
            ]);
            return null;
        }

        $text = $resp->json('candidates.0.content.parts.0.text');
        return is_string($text) && trim($text) !== '' ? trim($text) : null;
    }
}
