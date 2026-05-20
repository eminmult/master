<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Models\WithdrawalRequest;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Master-initiated withdrawal flow.
 *
 * MVP (stub mode): create a WithdrawalRequest row, hold the amount on the
 * master's balance (debit + KIND_WITHDRAWAL_HOLD), and surface it to admin
 * for manual settlement via bank-client. Admin endpoints flip status to
 * `paid` (no balance change — the hold already captured the debit) or
 * `rejected` (re-credit master with KIND_WITHDRAWAL_RESTORE).
 *
 * When a real PSP is wired in, the gateway->payout() call will replace the
 * "admin approves manually" path; the WithdrawalRequest row stays as the
 * audit trail.
 */
class WithdrawalController extends Controller
{
    public function __construct(private readonly WalletService $wallet) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $rows = WithdrawalRequest::where('user_id', $user->id)
            ->orderByDesc('id')
            ->limit(50)
            ->get();
        return response()->json(['withdrawals' => $rows]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'amount_cents'   => 'required|integer|min:100',
            'iban'           => 'required|string|max:64',
            'account_holder' => 'required|string|max:128',
            'note'           => 'nullable|string|max:500',
        ]);
        $user = $request->user();
        if ($user->role !== 'master') {
            abort(403, 'Only masters can withdraw');
        }

        $req = DB::transaction(function () use ($user, $data) {
            $locked = User::where('id', $user->id)->lockForUpdate()->first();
            $available = (int) ($locked->balance_cents ?? 0);
            if ($available < (int) $data['amount_cents']) {
                abort(422, 'Insufficient balance');
            }

            $req = WithdrawalRequest::create([
                'user_id'        => $locked->id,
                'amount_cents'   => (int) $data['amount_cents'],
                'currency'       => (string) config('master.callout_fee.currency'),
                'status'         => WithdrawalRequest::STATUS_PENDING,
                'iban'           => $data['iban'],
                'account_holder' => $data['account_holder'],
                'note'           => $data['note'] ?? null,
            ]);

            // Place a HOLD: debit the master's balance now. Restored on reject.
            $this->wallet->post(
                entries: [
                    ['account_type' => WalletTransaction::ACCOUNT_USER,     'account_user_id' => $locked->id, 'direction' => WalletTransaction::DIR_DEBIT,  'amount_cents' => (int) $data['amount_cents'], 'kind' => WalletTransaction::KIND_WITHDRAWAL_HOLD, 'metadata' => ['withdrawal_request_id' => $req->id]],
                    ['account_type' => WalletTransaction::ACCOUNT_PLATFORM, 'account_user_id' => null,        'direction' => WalletTransaction::DIR_CREDIT, 'amount_cents' => (int) $data['amount_cents'], 'kind' => WalletTransaction::KIND_WITHDRAWAL_HOLD, 'metadata' => ['withdrawal_request_id' => $req->id]],
                ],
                idempotencyKey: 'wd_hold:' . $req->id,
                createdByUserId: $locked->id,
            );

            return $req;
        });

        return response()->json(['withdrawal' => $req], 201);
    }

    public function cancel(Request $request, WithdrawalRequest $withdrawal): JsonResponse
    {
        $user = $request->user();
        if ($withdrawal->user_id !== $user->id) abort(403);
        if ($withdrawal->status !== WithdrawalRequest::STATUS_PENDING) {
            abort(422, 'Cannot cancel — already processed');
        }
        $this->restoreFunds($withdrawal, $user->id, 'cancelled by master');
        $withdrawal->update([
            'status'       => WithdrawalRequest::STATUS_CANCELLED,
            'processed_at' => now(),
        ]);
        return response()->json(['withdrawal' => $withdrawal->fresh()]);
    }

    // ------- admin endpoints -------

    public function adminIndex(Request $request): JsonResponse
    {
        $rows = WithdrawalRequest::with('user')
            ->orderByDesc('id')
            ->limit(200)
            ->get();
        return response()->json(['withdrawals' => $rows]);
    }

    public function adminApprove(Request $request, WithdrawalRequest $withdrawal): JsonResponse
    {
        if ($withdrawal->status !== WithdrawalRequest::STATUS_PENDING) abort(422);
        $withdrawal->update([
            'status'                => WithdrawalRequest::STATUS_APPROVED,
            'processed_by_admin_id' => $request->user()->id,
            'admin_note'            => $request->input('admin_note'),
        ]);
        return response()->json(['withdrawal' => $withdrawal->fresh()]);
    }

    public function adminMarkPaid(Request $request, WithdrawalRequest $withdrawal): JsonResponse
    {
        if (!in_array($withdrawal->status, [WithdrawalRequest::STATUS_PENDING, WithdrawalRequest::STATUS_APPROVED], true)) {
            abort(422);
        }
        // No master-balance change — the hold already captured the debit. We
        // record the platform → external_card movement here so reports can
        // close the loop (hold ↔ paid pair share the withdrawal_request_id).
        $withdrawal->update([
            'status'                => WithdrawalRequest::STATUS_PAID,
            'processed_by_admin_id' => $request->user()->id,
            'processed_at'          => now(),
            'admin_note'            => $request->input('admin_note', $withdrawal->admin_note),
        ]);

        $this->wallet->post(
            entries: [
                ['account_type' => WalletTransaction::ACCOUNT_PLATFORM, 'account_user_id' => null, 'direction' => WalletTransaction::DIR_DEBIT,  'amount_cents' => $withdrawal->amount_cents, 'kind' => WalletTransaction::KIND_WITHDRAWAL_PAID, 'metadata' => ['withdrawal_request_id' => $withdrawal->id]],
                ['account_type' => WalletTransaction::ACCOUNT_CARD,     'account_user_id' => null, 'direction' => WalletTransaction::DIR_CREDIT, 'amount_cents' => $withdrawal->amount_cents, 'kind' => WalletTransaction::KIND_WITHDRAWAL_PAID, 'metadata' => ['withdrawal_request_id' => $withdrawal->id]],
            ],
            currency: $withdrawal->currency,
            idempotencyKey: 'wd_paid:' . $withdrawal->id,
            createdByUserId: $request->user()->id,
        );

        return response()->json(['withdrawal' => $withdrawal->fresh()]);
    }

    public function adminReject(Request $request, WithdrawalRequest $withdrawal): JsonResponse
    {
        if (!in_array($withdrawal->status, [WithdrawalRequest::STATUS_PENDING, WithdrawalRequest::STATUS_APPROVED], true)) {
            abort(422);
        }
        $this->restoreFunds($withdrawal, $request->user()->id, 'rejected by admin');
        $withdrawal->update([
            'status'                => WithdrawalRequest::STATUS_REJECTED,
            'processed_by_admin_id' => $request->user()->id,
            'processed_at'          => now(),
            'admin_note'            => $request->input('admin_note'),
        ]);
        return response()->json(['withdrawal' => $withdrawal->fresh()]);
    }

    private function restoreFunds(WithdrawalRequest $w, int $byUserId, string $reason): void
    {
        $this->wallet->post(
            entries: [
                ['account_type' => WalletTransaction::ACCOUNT_PLATFORM, 'account_user_id' => null,         'direction' => WalletTransaction::DIR_DEBIT,  'amount_cents' => $w->amount_cents, 'kind' => WalletTransaction::KIND_WITHDRAWAL_RESTORE, 'metadata' => ['withdrawal_request_id' => $w->id, 'reason' => $reason]],
                ['account_type' => WalletTransaction::ACCOUNT_USER,     'account_user_id' => $w->user_id,  'direction' => WalletTransaction::DIR_CREDIT, 'amount_cents' => $w->amount_cents, 'kind' => WalletTransaction::KIND_WITHDRAWAL_RESTORE, 'metadata' => ['withdrawal_request_id' => $w->id, 'reason' => $reason]],
            ],
            idempotencyKey: 'wd_restore:' . $w->id,
            createdByUserId: $byUserId,
        );
    }
}
