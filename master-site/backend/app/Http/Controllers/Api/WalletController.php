<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function __construct(private readonly WalletService $wallet) {}

    public function balance(Request $request): JsonResponse
    {
        $user = $request->user();
        return response()->json([
            'balance_cents' => $this->wallet->balanceCents($user->id),
            'currency'      => (string) config('master.callout_fee.currency'),
        ]);
    }

    public function transactions(Request $request): JsonResponse
    {
        $user  = $request->user();
        $limit = (int) $request->query('limit', 50);
        $rows  = $this->wallet->history($user->id, min(100, $limit));

        return response()->json([
            'transactions' => $rows->map(function ($tx) {
                $signed = (int) $tx->amount_cents * ($tx->direction === 'credit' ? 1 : -1);
                return [
                    'id'           => $tx->id,
                    'kind'         => $tx->kind,
                    'amount_cents' => $signed,
                    'currency'     => $tx->currency,
                    'order_id'     => $tx->order_id,
                    'created_at'   => optional($tx->created_at)->toIso8601String(),
                    'metadata'     => $tx->metadata,
                ];
            })->values(),
        ]);
    }
}
