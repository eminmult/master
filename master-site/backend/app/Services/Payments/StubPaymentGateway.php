<?php

namespace App\Services\Payments;

use App\Models\PaymentCard;
use App\Models\User;
use Illuminate\Support\Str;

/**
 * Stub gateway — always succeeds. Used in dev and at launch (pre-PSP).
 *
 * No PAN/CVV ever touches the system; saved PaymentCards already only store
 * brand + last4 + expiry. Replace with a real provider in
 * `config/services.php` -> `payment.gateway` when the PSP contract is signed.
 */
class StubPaymentGateway implements PaymentGateway
{
    public function charge(int $amountCents, string $currency, User $user, ?PaymentCard $card, array $context = []): ChargeResult
    {
        return new ChargeResult(
            success: true,
            chargeId: 'stub_ch_' . Str::ulid(),
            rawResponse: [
                'amount_cents' => $amountCents,
                'currency'     => $currency,
                'user_id'      => $user->id,
                'card_last4'   => $card?->last4,
            ],
        );
    }

    public function refund(string $chargeId, int $amountCents, array $context = []): RefundResult
    {
        return new RefundResult(
            success: true,
            refundId: 'stub_re_' . Str::ulid(),
        );
    }

    public function payout(User $master, int $amountCents, string $iban, string $holder): PayoutResult
    {
        // Stub doesn't actually move money — the WithdrawalRequest flow is
        // what surfaces a payout for the admin to settle by hand.
        return new PayoutResult(
            success: true,
            payoutId: 'stub_po_' . Str::ulid(),
        );
    }
}
