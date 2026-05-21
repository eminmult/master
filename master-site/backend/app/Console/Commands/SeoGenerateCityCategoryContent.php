<?php

namespace App\Console\Commands;

use App\Models\Category;
use App\Models\CityCategoryContent;
use App\Models\MasterProfile;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Per-(city, category, locale) SEO content. Only generates for combinations
 * that have at least one active master so we don't produce thin pages that
 * Google would penalise.
 */
class SeoGenerateCityCategoryContent extends Command
{
    protected $signature = 'seo:generate-city-category-content
        {--only-city= : Generate only for the given city slug}
        {--only-category= : Generate only for the given category id}
        {--force : Overwrite existing rows}
        {--dry-run : Print output without saving}';

    protected $description = 'Generate localized intro + FAQs for each city × category × locale pair via Gemini.';

    private const LOCALES = ['az', 'ru', 'en', 'tr', 'ar'];

    public function handle(): int
    {
        $key = config('services.gemini.key');
        if (!$key) {
            $this->error('GEMINI_KEY missing.');
            return self::FAILURE;
        }

        // Build the (city, category) work list from real master coverage.
        $pairs = MasterProfile::query()
            ->whereNotNull('city')
            ->where('city', '!=', '')
            ->whereHas('user', fn ($q) => $q->where('is_active', true))
            ->with('masterCategories.category')
            ->get()
            ->flatMap(function ($p) {
                $citySlug = Str::slug($p->city);
                return $p->masterCategories->map(
                    fn ($mc) => $mc->category ? ['city_slug' => $citySlug, 'city_name' => $p->city, 'category' => $mc->category] : null
                )->filter();
            })
            ->unique(fn ($x) => $x['city_slug'] . ':' . $x['category']->id)
            ->values();

        if ($onlyCity = $this->option('only-city')) {
            $pairs = $pairs->filter(fn ($x) => $x['city_slug'] === $onlyCity);
        }
        if ($onlyCat = $this->option('only-category')) {
            $pairs = $pairs->filter(fn ($x) => (string) $x['category']->id === (string) $onlyCat);
        }

        if ($pairs->isEmpty()) {
            $this->warn('No city × category pairs to process.');
            return self::SUCCESS;
        }

        $ok = 0; $skipped = 0; $failed = 0;
        $bar = $this->output->createProgressBar($pairs->count());
        $bar->start();
        foreach ($pairs as $pair) {
            $city = $pair['city_name'];
            $citySlug = $pair['city_slug'];
            $cat = $pair['category'];
            $existing = CityCategoryContent::where('city_slug', $citySlug)
                ->where('category_id', $cat->id)
                ->pluck('locale')->all();
            $missing = array_diff(self::LOCALES, $existing);
            if (!$missing && !$this->option('force')) {
                $skipped++;
                $bar->advance();
                continue;
            }

            foreach (self::LOCALES as $l) {
                if (in_array($l, $existing, true) && !$this->option('force')) continue;
                try {
                    $content = $this->generateOne($city, $cat, $l, $key);
                    if (!$this->option('dry-run')) {
                        CityCategoryContent::updateOrCreate(
                            ['city_slug' => $citySlug, 'category_id' => $cat->id, 'locale' => $l],
                            ['body' => $content],
                        );
                    }
                    $this->info(" {$citySlug}/{$cat->slug} [{$l}] ✓");
                } catch (\Throwable $e) {
                    Log::warning('seo:gen-citycat failed', [
                        'city' => $citySlug, 'category' => $cat->id, 'locale' => $l, 'err' => $e->getMessage(),
                    ]);
                    $this->error(" {$citySlug}/{$cat->slug} [{$l}] → " . $e->getMessage());
                    $failed++;
                }
            }
            $ok++;
            $bar->advance();
        }
        $bar->finish();
        $this->newLine();
        $this->info("Done. pairs={$ok} skipped={$skipped} failures={$failed}");
        return self::SUCCESS;
    }

    private function generateOne(string $city, Category $cat, string $locale, string $key): array
    {
        $name = $cat->nameFor($locale);
        $langName = [
            'az' => 'Azerbaijani', 'ru' => 'Russian', 'en' => 'English',
            'tr' => 'Turkish', 'ar' => 'Arabic',
        ][$locale];

        $prompt = "Write {$langName}-language SEO content for itez.app's '{$name} in {$city}' landing page.\n\n"
            . "Return STRICT JSON with:\n"
            . "  intro       : 2-3 short paragraphs (350-500 chars) mentioning {$city} specifically. Cover availability, response time, pricing.\n"
            . "  pricing     : 1-2 sentences with realistic AZN price range for {$city}.\n"
            . "  faqs        : 5-8 {q,a} objects. Questions should be city-specific search queries (e.g. '{$name} в {$city} цена').\n"
            . "  meta_title  : 50-60 char title tag.\n"
            . "  meta_description : 140-158 char meta description.\n";

        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";

        $response = Http::timeout(120)
            ->retry(4, 1500, throw: false)
            ->asJson()
            ->post($url, [
                'contents' => [['role' => 'user', 'parts' => [['text' => $prompt]]]],
                'generationConfig' => [
                    'temperature' => 0.6,
                    'responseMimeType' => 'application/json',
                    'maxOutputTokens' => 4096,
                ],
            ]);

        if (!$response->ok()) {
            throw new \RuntimeException('Gemini HTTP ' . $response->status());
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
