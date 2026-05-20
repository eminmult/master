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

            $translations = $svc->translateToAll($value, $src);
            if (!empty($translations)) {
                $updates[$field . '_translations'] = $translations;
            }
        }

        if ($source) {
            $updates['content_locale'] = $source;
        }

        if (!empty($updates)) {
            // updateQuietly — avoid re-triggering saved() event and infinite loop
            $model->forceFill($updates)->saveQuietly();
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
