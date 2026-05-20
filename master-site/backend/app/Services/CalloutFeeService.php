<?php

namespace App\Services;

use App\Models\ChatMessage;
use App\Models\Order;
use App\Models\PaymentCard;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\Payments\PaymentGateway;
use Illuminate\Support\Facades\DB;

/**
 * The core money-movement orchestrator for the platform-mediated callout fee.
 *
 * Lifecycle:
 *   1. Master proposes arrival time → order goes to pending_client.
 *   2. Client taps "Confirm & Pay" → order goes to pending_payment, this
 *      service is invoked with the client's card.
 *   3. Charge the card via the configured PaymentGateway.
 *   4. On success, post a 3-leg wallet transaction:
 *         debit  external_card        25.00
 *         credit user_balance(master) 19.00
 *         credit platform_revenue      6.00
 *      (amounts come from config('master.callout_fee').)
 *   5. Transition order to confirmed.
 *   6. On master-initiated cancellation later: refund() reverses (4) and
 *      also debits the master 6.00 as a penalty (platform credit).
 */
class CalloutFeeService
{
    public function __construct(
        private readonly PaymentGateway $gateway,
        private readonly WalletService $wallet,
    ) {}

    /**
     * Returns [amount, masterShare, platformShare] in cents.
     */
    public function pricing(): array
    {
        $c = config('master.callout_fee');
        $amount   = (int) $c['amount_cents'];
        $master   = (int) $c['master_share_cents'];
        $platform = (int) $c['platform_share_cents'];
        if ($master + $platform !== $amount) {
            throw new \RuntimeException("callout_fee config is inconsistent: $master + $platform != $amount");
        }
        return [$amount, $master, $platform, (string) $c['currency']];
    }

    /**
     * Charge the client and post ledger entries. Throws on any failure.
     *
     * @return array{order: Order, charge_id: string, transaction_uuid: string}
     */
    public function chargeAndConfirm(Order $order, User $client, ?PaymentCard $card): array
    {
        [$amount, $masterShare, $platformShare, $currency] = $this->pricing();

        if ($order->client_id !== $client->id) {
            abort(403, 'Only the order client may pay the callout fee');
        }
        if (!in_array($order->status, [Order::STATUS_PENDING_CLIENT, Order::STATUS_PENDING_PAYMENT], true)) {
            abort(422, 'Order is not awaiting payment');
        }
        if (!$order->master_id) {
            abort(422, 'Order has no master assigned yet');
        }
        if (!$order->agreed_date) {
            abort(422, 'Master has not proposed an arrival time yet');
        }

        // Idempotency: same order can only be charged once regardless of retries.
        $idempotency = 'callout_fee:order_' . $order->id;
        $existing = WalletTransaction::where('idempotency_key', $idempotency)->first();
        if ($existing) {
            return [
                'order' => $order->fresh(),
                'charge_id' => (string) ($existing->metadata['charge_id'] ?? 'duplicate'),
                'transaction_uuid' => $existing->transaction_uuid,
            ];
        }

        // Move order to pending_payment first so concurrent retries serialise.
        $order = DB::transaction(function () use ($order) {
            $locked = Order::where('id', $order->id)->lockForUpdate()->first();
            if (!in_array($locked->status, [Order::STATUS_PENDING_CLIENT, Order::STATUS_PENDING_PAYMENT], true)) {
                abort(409, 'Order status changed');
            }
            if ($locked->status === Order::STATUS_PENDING_CLIENT) {
                $locked->update(['status' => Order::STATUS_PENDING_PAYMENT]);
                $locked->logStatus(Order::STATUS_PENDING_PAYMENT, $locked->client_id);
            }
            return $locked;
        });

        // Charge — this is the only step that may legitimately fail; if it
        // does the order stays in pending_payment and the client can retry.
        $result = $this->gateway->charge($amount, $currency, $client, $card, [
            'order_id' => $order->id,
            'purpose'  => 'callout_fee',
        ]);
        if (!$result->success) {
            abort(402, $result->error ?? 'Card was declined');
        }

        $masterId = (int) $order->master_id;

        $uuid = $this->wallet->post(
            entries: [
                ['account_type' => WalletTransaction::ACCOUNT_CARD,     'account_user_id' => null,       'direction' => WalletTransaction::DIR_DEBIT,  'amount_cents' => $amount,        'order_id' => $order->id, 'kind' => WalletTransaction::KIND_CALLOUT_FEE, 'metadata' => ['charge_id' => $result->chargeId, 'paid_by_user_id' => $client->id, 'card_last4' => $card?->last4]],
                ['account_type' => WalletTransaction::ACCOUNT_USER,     'account_user_id' => $masterId,  'direction' => WalletTransaction::DIR_CREDIT, 'amount_cents' => $masterShare,  'order_id' => $order->id, 'kind' => WalletTransaction::KIND_CALLOUT_FEE, 'metadata' => ['charge_id' => $result->chargeId]],
                ['account_type' => WalletTransaction::ACCOUNT_PLATFORM, 'account_user_id' => null,       'direction' => WalletTransaction::DIR_CREDIT, 'amount_cents' => $platformShare,'order_id' => $order->id, 'kind' => WalletTransaction::KIND_CALLOUT_FEE, 'metadata' => ['charge_id' => $result->chargeId]],
            ],
            currency: $currency,
            idempotencyKey: $idempotency,
            createdByUserId: $client->id,
        );

        // Transition order: pending_payment → confirmed.
        $order = DB::transaction(function () use ($order, $client) {
            $locked = Order::where('id', $order->id)->lockForUpdate()->first();
            if ($locked->status === Order::STATUS_PENDING_PAYMENT) {
                $locked->update([
                    'status'       => Order::STATUS_CONFIRMED,
                    'confirmed_at' => now(),
                ]);
                $locked->logStatus(Order::STATUS_CONFIRMED, $client->id);
            }
            return $locked;
        });

        // System chat message — both parties see "Callout fee paid · 25 AZN".
        ChatMessage::create([
            'order_id'  => $order->id,
            'sender_id' => $client->id,
            'text'      => json_encode([
                '_type'        => 'callout_paid',
                'amount'       => $amount / 100,
                'currency'     => $currency,
            ], JSON_UNESCAPED_UNICODE),
        ]);

        NotificationService::send($masterId, 'callout_paid', [
            'az' => 'Müştəri çağırış ödənişini etdi',
            'ru' => 'Клиент оплатил вызов',
            'en' => 'Client paid the callout fee',
            'tr' => 'Müşteri çağrı ödemesini yaptı',
            'ar' => 'دفع العميل رسوم الاستدعاء',
        ], [
            'az' => "#{$order->id} — sifariş təsdiqləndi.",
            'ru' => "#{$order->id} — заказ подтверждён.",
            'en' => "#{$order->id} — order confirmed.",
            'tr' => "#{$order->id} — sipariş onaylandı.",
            'ar' => "#{$order->id} — تم تأكيد الطلب.",
        ], ['order_id' => $order->id]);

        return [
            'order' => $order->fresh(),
            'charge_id' => $result->chargeId,
            'transaction_uuid' => $uuid,
        ];
    }

    /**
     * Master cancelled (or system attributed cancellation to master) AFTER
     * the client paid the callout fee. Refund the client in full, debit the
     * master both their share and the configured penalty, credit the platform
     * the penalty (the +6 share was already on platform).
     *
     * NOTE: this is idempotent at the wallet layer via the idempotency key.
     */
    public function refundOnMasterCancel(Order $order, ?int $cancelledByUserId = null): ?string
    {
        $original = WalletTransaction::where('order_id', $order->id)
            ->where('kind', WalletTransaction::KIND_CALLOUT_FEE)
            ->where('account_type', WalletTransaction::ACCOUNT_CARD)
            ->first();
        if (!$original) {
            return null; // no charge to refund (paid_callout never happened)
        }

        $idempotency = 'callout_refund:order_' . $order->id;
        if (WalletTransaction::where('idempotency_key', $idempotency)->exists()) {
            return null;
        }

        [$amount, $masterShare, $platformShare, $currency] = $this->pricing();
        $penalty = (int) config('master.callout_fee.master_cancel_penalty_cents');
        $masterId = (int) $order->master_id;
        $chargeId = (string) ($original->metadata['charge_id'] ?? '');

        // 1. PSP refund back to the client's card.
        $refund = $this->gateway->refund($chargeId, $amount, ['order_id' => $order->id]);
        if (!$refund->success) {
            throw new \RuntimeException('PSP refund failed: ' . ($refund->error ?? 'unknown'));
        }

        // 2. Ledger reversal:
        //      debit  user_balance(master)   -19   (give back master's share)
        //      debit  platform_revenue       -6    (give back platform share)
        //      credit external_card          +25   (returned to card)
        //    Plus the penalty leg:
        //      debit  user_balance(master)   -6    (penalty taken from master)
        //      credit platform_revenue       +6    (kept by platform)
        $uuid = $this->wallet->post(
            entries: [
                ['account_type' => WalletTransaction::ACCOUNT_USER,     'account_user_id' => $masterId, 'direction' => WalletTransaction::DIR_DEBIT,  'amount_cents' => $masterShare,   'order_id' => $order->id, 'kind' => WalletTransaction::KIND_CALLOUT_REFUND],
                ['account_type' => WalletTransaction::ACCOUNT_PLATFORM, 'account_user_id' => null,      'direction' => WalletTransaction::DIR_DEBIT,  'amount_cents' => $platformShare,'order_id' => $order->id, 'kind' => WalletTransaction::KIND_CALLOUT_REFUND],
                ['account_type' => WalletTransaction::ACCOUNT_CARD,     'account_user_id' => null,      'direction' => WalletTransaction::DIR_CREDIT, 'amount_cents' => $amount,        'order_id' => $order->id, 'kind' => WalletTransaction::KIND_CALLOUT_REFUND, 'metadata' => ['refund_id' => $refund->refundId]],
                // Separate penalty transfer:
                ['account_type' => WalletTransaction::ACCOUNT_USER,     'account_user_id' => $masterId, 'direction' => WalletTransaction::DIR_DEBIT,  'amount_cents' => $penalty,       'order_id' => $order->id, 'kind' => WalletTransaction::KIND_MASTER_PENALTY],
                ['account_type' => WalletTransaction::ACCOUNT_PLATFORM, 'account_user_id' => null,      'direction' => WalletTransaction::DIR_CREDIT, 'amount_cents' => $penalty,       'order_id' => $order->id, 'kind' => WalletTransaction::KIND_MASTER_PENALTY],
            ],
            currency: $currency,
            idempotencyKey: $idempotency,
            createdByUserId: $cancelledByUserId,
        );

        return $uuid;
    }
}
