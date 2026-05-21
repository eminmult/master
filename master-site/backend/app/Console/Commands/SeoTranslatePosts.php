<?php

namespace App\Console\Commands;

use App\Models\Post;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Translate blog posts into every supported locale via Gemini.
 *
 * Works per (slug, source-locale) — for each post that exists in at least
 * one locale, fills in every missing locale so users see localized content
 * instead of falling through to the AZ/EN copy. The source content is left
 * untouched; only missing locales are produced.
 */
class SeoTranslatePosts extends Command
{
    protected $signature = 'seo:translate-posts
        {--slug= : Translate only this post slug}
        {--source= : Locale to translate from (auto-detect if omitted)}
        {--force : Overwrite existing rows}
        {--dry-run : Print results without saving}';

    protected $description = 'Generate localized versions of blog posts via Gemini.';

    private const TARGET_LOCALES = ['az', 'ru', 'en', 'tr', 'ar'];

    public function handle(): int
    {
        $key = config('services.gemini.key');
        if (!$key) {
            $this->error('GEMINI_KEY missing.');
            return self::FAILURE;
        }

        // Group posts by canonical slug — one row per slug describes the work.
        $slugs = Post::query()
            ->when($this->option('slug'), fn ($q) => $q->where('slug', $this->option('slug')))
            ->distinct()
            ->pluck('slug');

        if ($slugs->isEmpty()) {
            $this->warn('No posts to translate.');
            return self::SUCCESS;
        }

        $ok = 0; $skipped = 0; $failed = 0;
        $bar = $this->output->createProgressBar($slugs->count());
        $bar->start();
        foreach ($slugs as $slug) {
            // Pick a source: explicit flag, then AZ, then EN, then any.
            $sourceLocale = $this->option('source');
            $source = null;
            foreach ([$sourceLocale, 'az', 'en', 'ru', 'tr', 'ar'] as $l) {
                if (!$l) continue;
                $source = Post::where('slug', $slug)->where('locale', $l)->first();
                if ($source) break;
            }
            if (!$source) { $skipped++; $bar->advance(); continue; }

            $existing = Post::where('slug', $slug)->pluck('locale')->all();
            $missing = $this->option('force')
                ? array_diff(self::TARGET_LOCALES, [$source->locale])
                : array_diff(self::TARGET_LOCALES, $existing);
            if (!$missing) {
                $skipped++;
                $bar->advance();
                continue;
            }

            foreach ($missing as $target) {
                try {
                    $translated = $this->translateOne($source, $target, $key);
                    if (!$this->option('dry-run')) {
                        Post::updateOrCreate(
                            ['slug' => $slug, 'locale' => $target],
                            [
                                'title' => $translated['title'] ?? $source->title,
                                'excerpt' => $translated['excerpt'] ?? $source->excerpt,
                                'body_md' => $translated['body_md'] ?? $source->body_md,
                                'hero_url' => $source->hero_url,
                                'author_id' => $source->author_id,
                                'published_at' => $source->published_at,
                            ],
                        );
                    }
                    $this->info(" {$slug} [{$target}] ✓");
                } catch (\Throwable $e) {
                    Log::warning('seo:translate-posts failed', [
                        'slug' => $slug, 'target' => $target, 'err' => $e->getMessage(),
                    ]);
                    $this->error(" {$slug} [{$target}] → " . $e->getMessage());
                    $failed++;
                }
            }
            $ok++;
            $bar->advance();
        }
        $bar->finish();
        $this->newLine();
        $this->info("Done. posts={$ok} skipped={$skipped} failures={$failed}");
        return self::SUCCESS;
    }

    private function translateOne(Post $source, string $target, string $key): array
    {
        $langName = [
            'az' => 'Azerbaijani', 'ru' => 'Russian', 'en' => 'English',
            'tr' => 'Turkish', 'ar' => 'Arabic',
        ][$target];

        $prompt = "Translate this itez.app blog post from " . strtoupper($source->locale)
            . " to {$langName}. Preserve the Markdown structure (headings, links, lists, paragraphs).\n\n"
            . "Source title: {$source->title}\n"
            . "Source excerpt: " . ($source->excerpt ?? '') . "\n"
            . "Source body (Markdown):\n" . $source->body_md
            . "\n\nReturn STRICT JSON only:\n"
            . '{"title":"…","excerpt":"…","body_md":"…"}';

        $model = config('services.gemini.model', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}";

        $response = Http::timeout(120)
            ->retry(4, 1500, throw: false)
            ->asJson()
            ->post($url, [
                'contents' => [['role' => 'user', 'parts' => [['text' => $prompt]]]],
                'generationConfig' => [
                    'temperature' => 0.3,
                    'responseMimeType' => 'application/json',
                    'maxOutputTokens' => 4096,
                ],
            ]);

        if (!$response->ok()) {
            throw new \RuntimeException('Gemini HTTP ' . $response->status() . ': ' . substr($response->body(), 0, 200));
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
