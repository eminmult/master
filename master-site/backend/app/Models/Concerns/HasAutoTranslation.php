<?php

namespace App\Models\Concerns;

use App\Jobs\TranslateContentJob;

/**
 * Auto-translate user-generated content to all supported locales.
 *
 * Usage:
 *   class Order extends Model {
 *     use HasAutoTranslation;
 *     protected array $translatable = ['description', 'comment'];
 *   }
 *
 *   Requires columns: {$field}_translations jsonb, content_locale varchar(5)
 *   Returns the localized value via $model->localized('description').
 */
trait HasAutoTranslation
{
    public static function bootHasAutoTranslation(): void
    {
        static::saved(function ($model) {
            $fields = $model->translatable ?? [];
            if (empty($fields)) return;

            // Which translatable fields actually changed in this save?
            $changed = array_values(array_intersect($fields, array_keys($model->getChanges())));
            if (empty($changed)) return;

            // Don't fire if only the *_translations sibling was updated (avoids loop
            // since we use saveQuietly there, but defensive belt-and-suspenders).
            $onlyTranslationMeta = true;
            foreach ($changed as $f) {
                if (str_ends_with($f, '_translations') || $f === 'content_locale') continue;
                $onlyTranslationMeta = false;
                break;
            }
            if ($onlyTranslationMeta) return;

            TranslateContentJob::dispatch(
                static::class,
                $model->getKey(),
                $changed,
                $model->content_locale ?? null,
            );
        });
    }

    /**
     * Resolve localized value for a field. Priority:
     *   1. translations[current_locale]
     *   2. original field value (when current_locale == content_locale or no translation yet)
     *   3. translations[content_locale] (rare)
     *   4. empty string
     */
    public function localized(string $field, ?string $locale = null): string
    {
        $locale = $locale ?: app()->getLocale();
        $source = $this->{$field} ?? '';

        if ($this->content_locale && $locale === $this->content_locale) {
            return (string) $source;
        }

        $translations = $this->{$field . '_translations'} ?? [];
        if (is_array($translations) && isset($translations[$locale]) && $translations[$locale] !== '') {
            return (string) $translations[$locale];
        }

        return (string) $source;
    }

    /**
     * API responses transparently get the localized value in place of source.
     * Frontend continues reading `.description` — server picks locale from
     * Accept-Language header via SetLocaleFromRequest middleware.
     */
    public function toArray()
    {
        $array = $this->attributesToArray();
        foreach ($this->relationsToArray() as $k => $v) $array[$k] = $v;

        foreach ($this->translatable ?? [] as $field) {
            if (array_key_exists($field, $array) && $array[$field] !== null && $array[$field] !== '') {
                $array[$field] = $this->localized($field);
            }
        }
        return $array;
    }
}
