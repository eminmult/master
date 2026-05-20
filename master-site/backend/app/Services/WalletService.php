<?php

namespace App\Services;

use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Read/write façade over the wallet_transactions ledger.
 *
 * The ledger is the source of truth: `users.balance_cents` is a cache, always
 * updated inside the same DB transaction that writes the ledger entries, with
 * the user row locked. Reading balance from the cache is fine for display;
 * for any debit (charge against balance, withdrawal hold) the caller MUST
 * read inside a transaction with `lockForUpdate` to avoid races.
 */
class WalletService
{
    /**
     * Post a multi-leg transaction. Callers pass an array of entries; the
     * method validates that debits and credits balance, persists them, and
     * updates each affected user's balance_cents cache atomically.
     *
     * @param  array<int, array{
     *     account_type: string,
     *     account_user_id?: int|null,
     *     direction: 'debit'|'credit',
     *     amount_cents: int,
     *     order_id?: int|null,
     *     kind: string,
     *     metadata?: array,
     * }>  $entries
     * @param  string  $currency
     * @param  string|null  $idempotencyKey  if non-null and key exists, returns existing rows
     * @param  int|null  $createdByUserId
     * @return string transaction_uuid
     */
    public function post(array $entries, string $currency = 'AZN', ?string $idempotencyKey = null, ?int $createdByUserId = null): string
    {
        if (empty($entries)) {
            throw new \InvalidArgumentException('Empty wallet transaction');
        }

        // Validate balance: sum of credits == sum of debits.
        $sum = 0;
        foreach ($entries as $e) {
            $amt = (int) $e['amount_cents'];
            if ($amt <= 0) {
                throw new \InvalidArgumentException('amount_cents must be > 0');
            }
            $sum += ($e['direction'] === WalletTransaction::DIR_CREDIT ? 1 : -1) * $amt;
        }
        if ($sum !== 0) {
            throw new \InvalidArgumentException('Ledger entries do not balance: net=' . $sum);
        }

        // Idempotency: if a row with this key already exists return that group.
        if ($idempotencyKey) {
            $existing = WalletTransaction::where('idempotency_key', $idempotencyKey)->first();
            if ($existing) {
                return $existing->transaction_uuid;
            }
        }

        $uuid = (string) Str::uuid();

        DB::transaction(function () use ($entries, $currency, $idempotencyKey, $createdByUserId, $uuid) {
            // Lock all affected user rows up-front, sorted by id to avoid deadlock.
            $userIds = collect($entries)
                ->pluck('account_user_id')
                ->filter()
                ->unique()
                ->sort()
                ->values()
                ->all();
            if (!empty($userIds)) {
                User::whereIn('id', $userIds)->lockForUpdate()->get();
            }

            $first = true;
            foreach ($entries as $e) {
                WalletTransaction::create([
                    'transaction_uuid'   => $uuid,
                    'account_type'       => $e['account_type'],
                    'account_user_id'    => $e['account_user_id'] ?? null,
                    'direction'          => $e['direction'],
                    'amount_cents'       => (int) $e['amount_cents'],
                    'currency'           => $currency,
                    'order_id'           => $e['order_id'] ?? null,
                    'kind'               => $e['kind'],
                    // Only one of the legs carries the idempotency key — it's
                    // unique at the row level so we anchor it on the first leg.
                    'idempotency_key'    => $first ? $idempotencyKey : null,
                    'metadata'           => $e['metadata'] ?? null,
                    'created_by_user_id' => $createdByUserId,
                ]);
                $first = false;

                // Mirror to users.balance_cents (only for user-owned accounts).
                if (($e['account_type'] ?? null) === WalletTransaction::ACCOUNT_USER && !empty($e['account_user_id'])) {
                    $delta = (int) $e['amount_cents'] * ($e['direction'] === WalletTransaction::DIR_CREDIT ? 1 : -1);
                    User::where('id', $e['account_user_id'])->update([
                        'balance_cents' => DB::raw('balance_cents + (' . $delta . ')'),
                    ]);
                }
            }
        });

        return $uuid;
    }

    /**
     * Cached balance read. Cheap; safe for display.
     */
    public function balanceCents(int $userId): int
    {
        return (int) (User::where('id', $userId)->value('balance_cents') ?? 0);
    }

    /**
     * Authoritative balance — recomputed from the ledger. Use only for
     * reconciliation or admin tools — cost is O(rows).
     */
    public function balanceFromLedger(int $userId): int
    {
        $row = WalletTransaction::query()
            ->where('account_type', WalletTransaction::ACCOUNT_USER)
            ->where('account_user_id', $userId)
            ->selectRaw("COALESCE(SUM(CASE WHEN direction='credit' THEN amount_cents ELSE -amount_cents END), 0) as bal")
            ->first();
        return (int) ($row->bal ?? 0);
    }

    public function history(int $userId, int $limit = 50): \Illuminate\Support\Collection
    {
        return WalletTransaction::query()
            ->where('account_type', WalletTransaction::ACCOUNT_USER)
            ->where('account_user_id', $userId)
            ->with('order')
            ->orderByDesc('id')
            ->limit($limit)
            ->get();
    }
}
