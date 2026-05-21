<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Hard-cancel stale orders. Different deadlines per status:
//   pending_master  → 24 h  (master must reply; client is waiting on them)
//   searching_master → 30 d (open announcement TTL, matches public feed window)
// The command takes both windows as flags so this stays the single source of truth.
Schedule::command('orders:expire-pending --pending-minutes=1440 --searching-minutes=43200')
    ->everyMinute()
    ->withoutOverlapping();

// Nightly safety net: auto-complete stuck awaiting_completion (14d),
// dispute stuck in_progress (30d), cancel orphan searching_master (30d, 0 apps).
Schedule::command('orders:auto-escalate')
    ->dailyAt('03:00')
    ->withoutOverlapping();

// One-time review-request nudge for completed orders without a review.
// SEO-critical: AggregateRating in SERPs is driven by review volume.
Schedule::command('reviews:remind')
    ->dailyAt('10:00')
    ->withoutOverlapping();
