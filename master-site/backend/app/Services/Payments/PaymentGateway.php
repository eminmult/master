<?php

namespace App\Services\Payments;

use App\Models\PaymentCard;
use App\Models\User;

/**
 * Abstraction over an external Payment Service Provider.
 *
 * Implementations:
 *   - StubPaymentGateway — always succeeds, no real card movement (current).
 *   - PashaPaymentGateway / KapitalPaymentGateway / StripePaymentGateway — real PSP (future).
 *
 * The point of this interface is that swapping providers is a single line in
 * config/services.php — business logic (wallet, ledger, order flow) is unchanged.
 */
interface PaymentGateway
{
    /**
     * Charge a card (saved or one-off) for a specific amount in cents.
     * Returns a [success, charge_id, error] tuple.
     */
    public function charge(int $amountCents, string $currency, User $user, ?PaymentCard $card, array $context = []): ChargeResult;

    /**
     * Refund a previous charge (full or partial). For stub, this just returns success.
     */
    public function refund(string $chargeId, int $amountCents, array $context = []): RefundResult;

    /**
     * Initiate a payout to a master's bank account.
     * Stub implementation creates a WithdrawalRequest for an admin to manually settle.
     */
    public function payout(User $master, int $amountCents, string $iban, string $holder): PayoutResult;
}

final class ChargeResult
{
    public function __construct(
        public bool $success,
        public ?string $chargeId = null,
        public ?string $error = null,
        public array $rawResponse = [],
    ) {}
}

final class RefundResult
{
    public function __construct(
        public bool $success,
        public ?string $refundId = null,
        public ?string $error = null,
    ) {}
}

final class PayoutResult
{
    public function __construct(
        public bool $success,
        public ?string $payoutId = null,
        public ?string $error = null,
    ) {}
}
