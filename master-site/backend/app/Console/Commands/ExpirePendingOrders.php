<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * Hard-cancel stale orders. Two timeouts apply:
 *  - pending_master  (direct request to a specific master) → 24 h.
 *    A picked master should reply within a day; otherwise the order is
 *    auto-canceled and the client is told to try again.
 *  - searching_master (open announcement, public pool) → 30 d.
 *    These are long-lived listings; we keep them around so masters who
 *    swing by later can still apply. The 30-day window matches the public
 *    feed's cut-off in OrderController::publicIndex().
 */
class ExpirePendingOrders extends Command
{
    protected $signature = 'orders:expire-pending'
        . ' {--pending-minutes=1440}'      // 24 h
        . ' {--searching-minutes=43200}';  // 30 d
    protected $description = 'Hard-cancel pending_master after 24h and searching_master after 30d.';

    public function handle(): void
    {
        $pendingMinutes = (int) $this->option('pending-minutes');
        $searchingMinutes = (int) $this->option('searching-minutes');

        $pending = Order::where('status', Order::STATUS_PENDING_MASTER)
            ->where('created_at', '<', now()->subMinutes($pendingMinutes))
            ->get();

        $searching = Order::where('status', Order::STATUS_SEARCHING)
            ->where('created_at', '<', now()->subMinutes($searchingMinutes))
            ->get();

        foreach ($pending as $order) {
            $this->cancel($order, "Auto-expired after {$pendingMinutes}m (no master response)");
        }
        foreach ($searching as $order) {
            $this->cancel($order, "Auto-expired after {$searchingMinutes}m (announcement TTL reached)");
        }

        $this->info(sprintf(
            'Cancelled: %d pending_master (>%dm), %d searching_master (>%dm).',
            $pending->count(), $pendingMinutes,
            $searching->count(), $searchingMinutes,
        ));
    }

    private function cancel(Order $order, string $note): void
    {
        $order->update([
            'status' => Order::STATUS_CANCELED_SYSTEM,
            'canceled_at' => now(),
            'cancel_reason' => 'Timeout',
        ]);
        $order->logStatus(Order::STATUS_CANCELED_SYSTEM, null, null, null, $note);

        NotificationService::send($order->client_id, 'order_expired', [
            'az' => 'Sifariş vaxtı keçdi',
            'ru' => 'Время заказа истекло',
            'en' => 'Order expired',
        ], [
            'az' => "#{$order->id} — usta tapılmadı. Yeni sifariş yarada bilərsiniz.",
            'ru' => "#{$order->id} — мастер не найден. Вы можете создать новый заказ.",
            'en' => "#{$order->id} — no master found. You can create a new order.",
        ], ['order_id' => $order->id]);
    }
}
