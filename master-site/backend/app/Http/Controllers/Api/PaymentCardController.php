<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentCard;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Self-service CRUD for saved payment cards. Stub mode: we accept the PAN
 * + CVV on `store` purely to read the brand / last4 / expiry from it — the
 * actual digits are dropped before persistence. When PayRiff (or whoever)
 * is wired in, `store` becomes a thin wrapper that calls
 * Provider::tokenize() and persists the returned token.
 */
class PaymentCardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $cards = PaymentCard::where('user_id', $request->user()->id)
            ->orderByDesc('is_default')
            ->orderByDesc('id')
            ->get();
        return response()->json(['cards' => $cards]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'number'      => 'required|string|min:12|max:23', // accept spaces / dashes
            'exp_month'   => 'required|integer|min:1|max:12',
            'exp_year'    => 'required|integer|min:2000|max:2099',
            'cvv'         => 'required|string|min:3|max:4',
            'holder_name' => 'nullable|string|max:100',
            'is_default'  => 'nullable|boolean',
        ]);

        // Reject expired cards: (exp_year, exp_month) must be >= current month.
        $expEnd = \Carbon\Carbon::create((int) $data['exp_year'], (int) $data['exp_month'], 1)->endOfMonth();
        if ($expEnd->lt(now())) {
            return response()->json([
                'message' => trans('payment.card_expired'),
                'errors' => ['exp_year' => [trans('payment.card_expired')]],
            ], 422);
        }

        $digits = preg_replace('/\D+/', '', $data['number']);
        if (!$this->luhnValid($digits)) {
            return response()->json([
                'message' => 'Kart nömrəsi düzgün deyil.',
            ], 422);
        }

        $card = DB::transaction(function () use ($request, $data, $digits) {
            $isDefault = (bool) ($data['is_default'] ?? false);
            // First card auto-becomes default; subsequent cards demote others
            // when explicitly marked default.
            $hasAny = PaymentCard::where('user_id', $request->user()->id)->exists();
            if (!$hasAny) $isDefault = true;
            if ($isDefault) {
                PaymentCard::where('user_id', $request->user()->id)
                    ->update(['is_default' => false]);
            }

            return PaymentCard::create([
                'user_id'    => $request->user()->id,
                'brand'      => $this->detectBrand($digits),
                'last4'      => substr($digits, -4),
                'exp_month'  => (int) $data['exp_month'],
                'exp_year'   => (int) $data['exp_year'],
                'holder_name'=> $data['holder_name'] ?? null,
                'token'      => null, // populated by provider integration later
                'is_default' => $isDefault,
            ]);
            // PAN + CVV go out of scope here — never persisted.
        });

        return response()->json(['card' => $card], 201);
    }

    public function setDefault(Request $request, PaymentCard $card): JsonResponse
    {
        if ($card->user_id !== $request->user()->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }
        DB::transaction(function () use ($request, $card) {
            PaymentCard::where('user_id', $request->user()->id)
                ->update(['is_default' => false]);
            $card->update(['is_default' => true]);
        });
        return response()->json(['card' => $card->fresh()]);
    }

    public function destroy(Request $request, PaymentCard $card): JsonResponse
    {
        if ($card->user_id !== $request->user()->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }
        $wasDefault = $card->is_default;
        $card->delete();
        // Promote another card to default if we just removed the default one.
        if ($wasDefault) {
            $next = PaymentCard::where('user_id', $request->user()->id)
                ->orderByDesc('id')->first();
            if ($next) $next->update(['is_default' => true]);
        }
        return response()->json(['ok' => true]);
    }

    private function detectBrand(string $digits): string
    {
        if (str_starts_with($digits, '4')) return 'visa';
        $first2 = (int) substr($digits, 0, 2);
        if ($first2 >= 51 && $first2 <= 55) return 'mastercard';
        $first4 = (int) substr($digits, 0, 4);
        if ($first4 >= 2221 && $first4 <= 2720) return 'mastercard';
        if (in_array(substr($digits, 0, 2), ['34', '37'], true)) return 'amex';
        return 'unknown';
    }

    private function luhnValid(string $digits): bool
    {
        if (strlen($digits) < 12) return false;
        $sum = 0;
        $alt = false;
        for ($i = strlen($digits) - 1; $i >= 0; $i--) {
            $n = (int) $digits[$i];
            if ($alt) {
                $n *= 2;
                if ($n > 9) $n -= 9;
            }
            $sum += $n;
            $alt = !$alt;
        }
        return $sum % 10 === 0;
    }
}
