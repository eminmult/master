<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * Stuck-order safety net. Runs nightly.
 *
 * - awaiting_completion older than 14d → auto-close to STATUS_COMPLETED
 *   (client never came back to confirm; treat master's word as final).
 * - in_progress with no activity 30d → mark disputed for admin review.
 * - searching_master with zero applications and 30d age → cancel as expired.
 */
class AutoEscalateStuckOrders extends Command
{
    protected $signature = 'orders:auto-escalate';
    protected $description = 'Resolve orders stuck in mid-flow states';

    public function handle(): void
    {
        $autoCompleted = 0;
        $disputed = 0;
        $expired = 0;

        // 1. awaiting_completion → completed after 14d of silence
        $stuck = Order::where('status', Order::STATUS_AWAITING_COMPLETION)
            ->where('updated_at', '<', now()->subDays(14))
            ->get();
        foreach ($stuck as $order) {
            $order->update(['status' => Order::STATUS_COMPLETED, 'completed_at' => now()]);
            $order->logStatus(Order::STATUS_COMPLETED, null, null, null, 'Auto-completed after 14d silence');
            NotificationService::send($order->client_id, 'order_auto_completed', [
                'az' => 'Sifariş tamamlandı',
                'ru' => 'Заказ автоматически завершён',
                'en' => 'Order auto-completed',
            ], [
                'az' => "#{$order->id} — 14 gün ərzində cavab gəlmədi",
                'ru' => "#{$order->id} — 14 дней без подтверждения",
                'en' => "#{$order->id} — 14 days without confirmation",
            ], ['order_id' => $order->id]);
            $autoCompleted++;
        }

        // 2. in_progress with no activity → flag for admin
        $stale = Order::where('status', Order::STATUS_IN_PROGRESS)
            ->where('updated_at', '<', now()->subDays(30))
            ->get();
        foreach ($stale as $order) {
            $order->update(['status' => Order::STATUS_DISPUTED]);
            $order->logStatus(Order::STATUS_DISPUTED, null, null, null, 'Auto-flagged: in_progress >30d');
            $disputed++;
        }

        // 3. searching_master with no applications and 30d age → cancel
        $expiredOrders = Order::where('status', Order::STATUS_SEARCHING)
            ->where('created_at', '<', now()->subDays(30))
            ->whereDoesntHave('applications')
            ->get();
        foreach ($expiredOrders as $order) {
            $order->update([
                'status' => Order::STATUS_CANCELED_SYSTEM,
                'canceled_at' => now(),
                'cancel_reason' => 'No applications in 30 days',
            ]);
            $order->logStatus(Order::STATUS_CANCELED_SYSTEM, null, null, null, 'Auto-cancelled: no applicants');
            NotificationService::send($order->client_id, 'order_expired_no_apps', [
                'az' => 'Sifarişə müraciət olmadı',
                'ru' => 'На заказ не было откликов',
                'en' => 'No applications received',
            ], [
                'az' => "#{$order->id} — 30 gün ərzində usta müraciət etmədi",
                'ru' => "#{$order->id} — за 30 дней не пришло ни одного отклика",
                'en' => "#{$order->id} — no master applied in 30 days",
            ], ['order_id' => $order->id]);
            $expired++;
        }

        $this->info("auto-completed={$autoCompleted} disputed={$disputed} expired={$expired}");
    }
}
