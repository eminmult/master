<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\PaymentCard;
use App\Services\CalloutFeeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CalloutFeeController extends Controller
{
    public function __construct(private readonly CalloutFeeService $service) {}

    /**
     * GET /api/orders/{order}/callout-fee — preview the amount the client
     * will be charged + the configured payment timeout. Used to populate the
     * "Confirm & Pay" sheet without re-hitting config.
     */
    public function preview(Request $request, Order $order): JsonResponse
    {
        if ($order->client_id !== $request->user()->id) {
            abort(403);
        }
        [$amount, $masterShare, $platformShare, $currency] = $this->service->pricing();
        return response()->json([
            'amount_cents'         => $amount,
            // Master-only fields — frontend filters by role; backend includes
            // for masters as well so the wallet card has the split breakdown.
            'master_share_cents'   => $masterShare,
            'platform_share_cents' => $platformShare,
            'currency'             => $currency,
            'timeout_minutes'      => (int) config('master.callout_fee.payment_timeout_minutes'),
        ]);
    }

    /**
     * POST /api/orders/{order}/pay-callout — charge the configured callout
     * fee against a saved card (payment_card_id) and confirm the order.
     */
    public function pay(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate([
            'payment_card_id' => 'nullable|integer|exists:payment_cards,id',
        ]);
        $user = $request->user();

        $card = null;
        if (!empty($data['payment_card_id'])) {
            $card = PaymentCard::where('id', $data['payment_card_id'])
                ->where('user_id', $user->id)
                ->first();
            if (!$card) abort(404, 'Card not found');
        } else {
            $card = PaymentCard::where('user_id', $user->id)
                ->where('is_default', true)
                ->first();
            if (!$card) {
                abort(422, 'No saved card. Add a card before paying.');
            }
        }

        $result = $this->service->chargeAndConfirm($order, $user, $card);

        return response()->json([
            'order' => $result['order']->fresh()->load(['client', 'master', 'category']),
            'charge_id' => $result['charge_id'],
        ]);
    }
}
