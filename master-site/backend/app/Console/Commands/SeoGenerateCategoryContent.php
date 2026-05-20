<?php

namespace App\Console\Commands;

use App\Models\Category;
use App\Models\CategoryContent;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Generate long-form SEO content per category × locale.
 *
 * Each body is a JSON blob with the same shape across locales so the page
 * renderer doesn't branch per language. The LLM is asked to fill ALL five
 * locales in one structured response to keep the round-trip count linear in
 * the number of categories.
 */
class SeoGenerateCategoryContent extends Command
{
    protected $signature = 'seo:generate-category-content
        {--only= : Process only the given category id}
        {--force : Overwrite existing rows}
        {--dry-run : Print output without saving}';

    protected $description = 'Generate localized intro/what_included/pricing/faqs/... for each category via Gemini.';

    private const LOCALES = ['az', 'ru', 'en', 'tr', 'ar'];

    public function handle(): int
    {
        $key = config('services.gemini.key');
        if (!$key) {
            $this->error('GEMINI_KEY missing.');
            return self::FAILURE;
        }

        $q = Category::query()->where('is_active', true)->orderBy('sort_order');
        if ($only = $this->option('only')) $q->where('id', $only);
        $categories = $q->get();
        if ($categories->isEmpty()) {
            $this->warn('No categories.');
            return self::SUCCESS;
        }

        $ok = 0; $skipped = 0; $failed = 0;
        $bar = $this->output->createProgressBar($categories->count());
        $bar->start();
        foreach ($categories as $cat) {
            $existingLocales = CategoryContent::where('category_id', $cat->id)->pluck('locale')->all();
            $missing = array_diff(self::LOCALES, $existingLocales);
            if (!$missing && !$this->option('force')) {
                $skipped++;
                $bar->advance();
                continue;
            }
            // One LLM call per locale — the combined-locales prompt blew past
            // gemini-2.5-flash's 8192-token output cap. Per-locale calls fit
            // and let us partial-resume on transient API failures.
            $catOk = true;
            foreach (self::LOCALES as $l) {
                $exists = in_array($l, $existingLocales, true);
                if ($exists && !$this->option('force')) continue;
                try {
                    $content = $this->generateLocale($cat, $l, $key);
                    if (!$this->option('dry-run')) {
                        CategoryContent::updateOrCreate(
                            ['category_id' => $cat->id, 'locale' => $l],
                            ['body' => $content],
                        );
                    }
                    $this->info(" {$cat->id} {$cat->name} [{$l}] ✓");
                } catch (\Throwable $e) {
                    Log::warning('seo:generate-category-content failed', ['id' => $cat->id, 'locale' => $l, 'err' => $e->getMessage()]);
                    $this->error(" {$cat->id} {$cat->name} [{$l}] → " . $e->getMessage());
                    $catOk = false;
                }
            }
            $catOk ? $ok++ : $failed++;
            $bar->advance();
        }
        $bar->finish();
        $this->newLine();
        $this->info("Done. ok={$ok} skipped={$skipped} failed={$failed}");
        return self::SUCCESS;
    }

    private function generateLocale(Category $cat, string $locale, string $key): array
    {
        $name = $cat->nameFor($locale);
        $desc = $cat->descriptionFor($locale);
        $langName = [
            'az' => 'Azerbaijani', 'ru' => 'Russian', 'en' => 'English',
            'tr' => 'Turkish', 'ar' => 'Arabic',
        ][$locale];

        $prompt = "You write SEO-optimized landing-page content for itez.app, a home-services marketplace in Azerbaijan (mostly Baku). Write everything in {$langName}.\n\n"
            . "Service category: {$name}" . ($desc ? " — {$desc}" : '')
            . "\n\nReturn STRICT JSON with these keys:\n"
            . "  intro         : 2-3 short paragraphs in {$langName} introducing the service. Mention Baku/Azerbaijan, pricing transparency, instant booking. 350-500 chars.\n"
            . "  what_included : array of 5-8 concrete tasks the master typically performs (one short sentence each).\n"
            . "  pricing       : 1-2 sentences with a realistic price range in AZN/manat. Be specific (e.g. '25-80 AZN per visit').\n"
            . "  when_needed   : array of 4-6 'when do you need this?' situations (short, second person).\n"
            . "  how_to_choose : array of 5-7 advice points on choosing a good {$name}. Each 1 sentence.\n"
            . "  faqs          : array of 6-10 objects {q,a}. Questions = natural search queries in {$langName}. Answers 1-3 factual sentences.\n"
            . "  related_keywords : array of 10-15 lowercase phrases users type into Google (long-tail keywords) in {$langName}.\n"
            . "  meta_title    : 50-60 char title tag in {$langName}.\n"
            . "  meta_description : 140-158 char meta description in {$langName}.\n";

        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";

        // Gemini frequently returns 503 UNAVAILABLE under load; retry with
        // exponential backoff so a single transient failure doesn't kill the
        // batch.
        $response = Http::timeout(120)
            ->retry(4, 1500, throw: false)
            ->asJson()
            ->post($url, [
                'contents' => [['role' => 'user', 'parts' => [['text' => $prompt]]]],
                'generationConfig' => [
                    'temperature' => 0.6,
                    'responseMimeType' => 'application/json',
                    'maxOutputTokens' => 8192,
                ],
            ]);

        if (!$response->ok()) {
            throw new \RuntimeException('Gemini HTTP ' . $response->status() . ': ' . substr($response->body(), 0, 300));
        }

        $text = $response->json('candidates.0.content.parts.0.text') ?? '';
        $text = preg_replace('/^```json\s*|\s*```$/m', '', trim($text));
        $data = json_decode($text, true);
        if (!is_array($data)) {
            throw new \RuntimeException('Bad JSON: ' . substr($text, 0, 200));
        }
        return $data;
    }
}
