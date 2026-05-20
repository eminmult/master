<?php

namespace App\Console\Commands;

use App\Models\Category;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Translate category names + descriptions and produce a Latin SEO slug for
 * each locale (az/ru/en/tr/ar). One LLM call per category covers all four
 * non-canonical locales. Idempotent: pass --only=<id> or --force to overwrite.
 */
class SeoTranslateCategories extends Command
{
    protected $signature = 'seo:translate-categories
        {--only= : Translate only the given category id}
        {--force : Overwrite existing translations}
        {--dry-run : Print results without saving}';

    protected $description = 'Generate localized name, description and SEO slug for each category via Gemini.';

    private const TARGET_LOCALES = ['ru', 'en', 'tr', 'ar'];

    public function handle(): int
    {
        $key = config('services.gemini.key');
        if (!$key) {
            $this->error('GEMINI_KEY missing. Set services.gemini.key in config or .env.');
            return self::FAILURE;
        }

        $q = Category::query()->where('is_active', true)->orderBy('sort_order');
        if ($only = $this->option('only')) $q->where('id', $only);
        $categories = $q->get();
        if ($categories->isEmpty()) {
            $this->warn('No categories to process.');
            return self::SUCCESS;
        }

        $bar = $this->output->createProgressBar($categories->count());
        $bar->start();
        $ok = 0; $skipped = 0; $failed = 0;
        foreach ($categories as $cat) {
            // Skip when already populated and not forcing.
            $hasAll = collect(self::TARGET_LOCALES)->every(
                fn ($l) => isset($cat->name_translations[$l]) && isset($cat->slug_translations[$l]),
            );
            if ($hasAll && !$this->option('force')) {
                $skipped++;
                $bar->advance();
                continue;
            }

            try {
                $result = $this->translateOne($cat, $key);
                if (!$this->option('dry-run')) {
                    // Always anchor AZ to the canonical values so the model
                    // can't accidentally overwrite them.
                    $nameT = ($cat->name_translations ?: []) + ['az' => $cat->name];
                    $slugT = ($cat->slug_translations ?: []) + ['az' => $cat->slug];
                    $descT = ($cat->description_translations ?: []) + ['az' => $cat->description];
                    foreach (self::TARGET_LOCALES as $l) {
                        if (!empty($result[$l]['name'])) $nameT[$l] = $result[$l]['name'];
                        if (!empty($result[$l]['slug'])) $slugT[$l] = Str::slug($result[$l]['slug']);
                        if (!empty($result[$l]['description'])) $descT[$l] = $result[$l]['description'];
                    }
                    $cat->update([
                        'name_translations' => $nameT,
                        'slug_translations' => $slugT,
                        'description_translations' => $descT,
                    ]);
                }
                $this->info(" {$cat->id} {$cat->name} → " . json_encode(
                    array_map(fn ($l) => $result[$l]['slug'] ?? '?', self::TARGET_LOCALES),
                    JSON_UNESCAPED_UNICODE,
                ));
                $ok++;
            } catch (\Throwable $e) {
                Log::warning('seo:translate-categories failed', ['id' => $cat->id, 'err' => $e->getMessage()]);
                $this->error(" {$cat->id} {$cat->name} → " . $e->getMessage());
                $failed++;
            }
            $bar->advance();
        }
        $bar->finish();
        $this->newLine();
        $this->info("Done. ok={$ok} skipped={$skipped} failed={$failed}");

        // Bust the per-locale categories cache so the new translations show up
        // on the next request.
        \App\Http\Controllers\Api\CategoryController::clearCache();
        \Illuminate\Support\Facades\Cache::flush();
        return self::SUCCESS;
    }

    /**
     * Ask Gemini for all four target locales in one structured response.
     * Returns an array keyed by locale → ['name', 'slug', 'description'].
     */
    private function translateOne(Category $cat, string $key): array
    {
        $prompt = "You translate service-category names for itez.app, a home-services marketplace.\n\n"
            . "Source (Azerbaijani):\n"
            . "  name: {$cat->name}\n"
            . ($cat->description ? "  description: {$cat->description}\n" : '')
            . "\nFor EACH of the locales ru, en, tr, ar produce:\n"
            . "  - name: the natural-sounding translation of the category name (e.g., 'Santexnik' → ru:'Сантехник', en:'Plumber', tr:'Tesisatçı', ar:'سباك').\n"
            . "  - description: a 1-sentence translation of the description (or a fresh 1-sentence service description if none was given). 50-120 chars.\n"
            . "  - slug: a SHORT lowercase Latin (ASCII) slug suitable for URLs, derived from the translated name. ALWAYS Latin even for ru/ar — use 'santehnik', not 'сантехник'. 2-4 words max, hyphens between words. No diacritics. Examples: 'plumber', 'santehnik', 'tesisatci', 'sabbak'.\n\n"
            . "Return STRICT JSON only (no markdown), shape:\n"
            . '{"ru":{"name":"…","description":"…","slug":"…"},"en":{…},"tr":{…},"ar":{…}}';

        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";

        $response = Http::timeout(40)->asJson()->post($url, [
            'contents' => [['role' => 'user', 'parts' => [['text' => $prompt]]]],
            'generationConfig' => [
                'temperature' => 0.3,
                'responseMimeType' => 'application/json',
            ],
        ]);

        if (!$response->ok()) {
            throw new \RuntimeException('Gemini HTTP ' . $response->status() . ': ' . substr($response->body(), 0, 200));
        }

        $text = $response->json('candidates.0.content.parts.0.text') ?? '';
        $text = preg_replace('/^```json\s*|\s*```$/m', '', trim($text));
        $data = json_decode($text, true);
        if (!is_array($data)) {
            throw new \RuntimeException('Bad JSON from model: ' . substr($text, 0, 200));
        }

        $out = [];
        foreach (self::TARGET_LOCALES as $l) {
            if (!isset($data[$l]) || !is_array($data[$l])) continue;
            $out[$l] = [
                'name' => trim((string) ($data[$l]['name'] ?? '')),
                'slug' => Str::slug((string) ($data[$l]['slug'] ?? '')),
                'description' => trim((string) ($data[$l]['description'] ?? '')),
            ];
        }
        return $out;
    }
}
