<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Models\Review;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * Nudge clients who completed an order 24+ hours ago but haven't left a
 * review yet. One reminder per order, capped at 7 days post-completion so we
 * don't spam users about stale jobs. Aggregate rating in SERPs depends on
 * review volume, so this materially affects SEO.
 */
class RemindReviews extends Command
{
    protected $signature = 'reviews:remind';
    protected $description = 'Send a single review-request reminder for orders completed 24-168h ago without a review.';

    public function handle(): int
    {
        $candidates = Order::query()
            ->whereIn('status', [Order::STATUS_COMPLETED, Order::STATUS_CLOSED])
            ->whereBetween('completed_at', [now()->subDays(7), now()->subHours(24)])
            ->whereDoesntHave('reviews', fn ($q) => null) // placeholder, see below
            ->limit(500)
            ->get();

        $sent = 0;
        foreach ($candidates as $order) {
            // Only nudge when the client hasn't written a review of the master
            // yet. (Master's review of the client is separate; we don't gate
            // on it because it's not SEO-relevant.)
            $hasReview = Review::where('order_id', $order->id)
                ->where('reviewer_id', $order->client_id)
                ->exists();
            if ($hasReview) continue;
            // De-dupe: skip if we've already sent one reminder for this order.
            $alreadyNotified = \App\Models\Notification::where('user_id', $order->client_id)
                ->where('type', 'review_reminder')
                ->whereJsonContains('data->order_id', $order->id)
                ->exists();
            if ($alreadyNotified) continue;

            NotificationService::send(
                $order->client_id,
                'review_reminder',
                [
                    'az' => 'Rəyinizi unutmayın',
                    'ru' => 'Не забудьте оставить отзыв',
                    'en' => "Don't forget to leave a review",
                    'tr' => 'Yorumunuzu unutmayın',
                    'ar' => 'لا تنسَ ترك تقييم',
                ],
                [
                    'az' => "#{$order->id} — ustaya rəy yazın, başqalarına kömək edin",
                    'ru' => "#{$order->id} — оцените мастера, помогите другим клиентам",
                    'en' => "#{$order->id} — rate the master, help other clients",
                    'tr' => "#{$order->id} — ustayı değerlendirin",
                    'ar' => "#{$order->id} — قيّم الحرفي",
                ],
                ['order_id' => $order->id],
            );
            $sent++;
        }
        $this->info("Sent {$sent} review reminders.");
        return self::SUCCESS;
    }
}
