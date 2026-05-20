<?php

return [
    /*
     * Subscription gate. When false, every master is treated as active
     * regardless of subscription_expires_at. Flip on after launch to enforce.
     */
    'subscription_required' => env('MASTER_SUBSCRIPTION_REQUIRED', false),

    /*
     * Pricing (AZN). Surfaced to frontend for the subscribe page; not yet
     * wired to a payment provider — at launch everything is free.
     */
    'registration_fee' => (float) env('MASTER_REGISTRATION_FEE', 0),
    'monthly_fee' => (float) env('MASTER_MONTHLY_FEE', 0),
    'yearly_fee' => (float) env('MASTER_YEARLY_FEE', 0),

    /*
     * The free-launch end-date is shown to masters as a banner so they know
     * the deal will end. Shown verbatim — no auto-enforcement here.
     */
    'free_launch_until' => env('MASTER_FREE_LAUNCH_UNTIL', '2026-12-31'),

    /*
     * Callout fee — the platform-mediated payment a client makes to confirm
     * an order after the master has proposed an arrival time. Split:
     *   master  +master_share_cents (credited to wallet balance)
     *   platform +platform_share_cents (accumulated platform_revenue)
     *
     * INVARIANT: master_share_cents + platform_share_cents == amount_cents.
     * Verify with CalloutFeeService::ensureConfigConsistent() on boot.
     *
     * On master-initiated cancellation after payment: client gets a full refund
     * AND master is debited `master_cancel_penalty_cents`.
     */
    'callout_fee' => [
        'amount_cents'              => (int) env('CALLOUT_FEE_AMOUNT_CENTS', 2500),
        'master_share_cents'        => (int) env('CALLOUT_FEE_MASTER_CENTS', 1900),
        'platform_share_cents'      => (int) env('CALLOUT_FEE_PLATFORM_CENTS', 600),
        'master_cancel_penalty_cents' => (int) env('CALLOUT_FEE_MASTER_PENALTY_CENTS', 600),
        'currency'                  => env('CALLOUT_FEE_CURRENCY', 'AZN'),
        // 15 minutes — if the client doesn't complete payment in this window
        // the order rolls back from pending_payment to pending_client.
        'payment_timeout_minutes'   => (int) env('CALLOUT_FEE_TIMEOUT_MIN', 15),
    ],
];

