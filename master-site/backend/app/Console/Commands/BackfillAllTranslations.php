<?php

namespace App\Console\Commands;

use App\Jobs\TranslateContentJob;
use App\Models\MasterProfile;
use App\Models\MasterSkill;
use App\Models\Order;
use App\Models\User;
use Illuminate\Console\Command;

/**
 * Dispatch a TranslateContentJob for every record that has a translatable
 * field populated but no translations yet. Runs idempotently — the job
 * itself bails out when translations are already present (via the model's
 * saveQuietly + translation cache).
 *
 * Use this after adding a new translatable field, importing data, or
 * onboarding existing users.
 */
class BackfillAllTranslations extends Command
{
    protected $signature = 'translations:backfill-all
        {--force : Re-dispatch even if translations exist}
        {--sync : Run jobs inline instead of pushing to queue}';

    protected $description = 'Dispatch translation jobs for every record with translatable user-generated text.';

    public function handle(): int
    {
        $totalDispatched = 0;

        $models = [
            ['class' => User::class, 'fields' => ['first_name', 'last_name'], 'query' => fn () => User::query()->whereNotNull('first_name')],
            ['class' => MasterProfile::class, 'fields' => ['description', 'city', 'district'], 'query' => fn () => MasterProfile::query()],
            ['class' => MasterSkill::class, 'fields' => ['name'], 'query' => fn () => MasterSkill::query()->whereNotNull('name')],
            ['class' => Order::class, 'fields' => ['description', 'comment'], 'query' => fn () => Order::query()->whereNotNull('description')],
        ];

        foreach ($models as $m) {
            $cls = $m['class'];
            $rows = $m['query']();
            $count = $rows->count();
            $this->info("{$cls}: {$count} rows");
            $bar = $this->output->createProgressBar($count);
            $bar->start();
            foreach ($rows->cursor() as $row) {
                if ($this->option('sync')) {
                    (new TranslateContentJob($cls, $row->getKey(), $m['fields']))->handle(app(\App\Services\TranslationService::class));
                } else {
                    TranslateContentJob::dispatch($cls, $row->getKey(), $m['fields']);
                }
                $totalDispatched++;
                $bar->advance();
            }
            $bar->finish();
            $this->newLine();
        }

        $this->info("Dispatched {$totalDispatched} translation jobs.");
        return self::SUCCESS;
    }
}
