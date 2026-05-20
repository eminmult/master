<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use App\Models\Order;
use App\Models\OrderApplication;
use App\Models\Review;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * GDPR-style endpoints. Export returns the full personal-data dump as JSON;
 * delete soft-anonymizes (we keep order rows so other users' history stays
 * intact, but strip PII so the account is unreachable).
 */
class PrivacyController extends Controller
{
    public function export(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'exported_at' => now()->toIso8601String(),
            'user' => $user->only([
                'id', 'first_name', 'last_name', 'email', 'phone', 'role',
                'avatar_url', 'rating_avg', 'rating_count', 'is_active',
                'email_verified_at', 'phone_verified_at', 'created_at',
            ]),
            'master_profile' => $user->isMaster() ? $user->masterProfile : null,
            'addresses' => $user->isClient() ? $user->addresses : [],
            'orders_as_client' => Order::where('client_id', $user->id)->get()->toArray(),
            'orders_as_master' => Order::where('master_id', $user->id)->get()->toArray(),
            'applications' => OrderApplication::where('master_id', $user->id)->get()->toArray(),
            'chat_messages' => ChatMessage::where('sender_id', $user->id)->get(['id', 'order_id', 'application_id', 'text', 'created_at'])->toArray(),
            'reviews_given' => Review::where('reviewer_id', $user->id)->get()->toArray(),
            'reviews_received' => Review::where('reviewee_id', $user->id)->get()->toArray(),
        ]);
    }

    public function delete(Request $request): JsonResponse
    {
        $request->validate([
            'confirm' => 'required|in:DELETE',
        ]);

        $user = $request->user();

        // Block delete if there's an in-flight order — would orphan a counterparty.
        $hasInflight = Order::where(function ($q) use ($user) {
                $q->where('client_id', $user->id)->orWhere('master_id', $user->id);
            })
            ->whereIn('status', [
                Order::STATUS_PENDING_MASTER,
                Order::STATUS_DISCUSSION,
                Order::STATUS_CONFIRMED,
                Order::STATUS_ACCEPTED,
                Order::STATUS_ON_THE_WAY,
                Order::STATUS_ARRIVED,
                Order::STATUS_IN_PROGRESS,
                Order::STATUS_AWAITING_COMPLETION,
                Order::STATUS_DISPUTED,
            ])
            ->exists();

        if ($hasInflight) {
            return response()->json([
                'message' => 'Cannot delete account with active orders. Cancel or complete them first.',
                'code' => 'has_inflight_orders',
            ], 422);
        }

        DB::transaction(function () use ($user) {
            // Anonymize: keep the row so referential integrity holds, but strip PII.
            $user->tokens()->delete();
            $stamp = $user->id;
            $user->update([
                'first_name' => 'Deleted',
                'last_name' => "User #{$stamp}",
                'email' => "deleted-{$stamp}@deleted.local",
                'phone' => "+0000000{$stamp}",
                'password' => bcrypt(\Illuminate\Support\Str::random(32)),
                'avatar_url' => null,
                'is_active' => false,
                'subscription_active' => false,
                'email_verified_at' => null,
                'phone_verified_at' => null,
            ]);

            if ($user->masterProfile) {
                $user->masterProfile->update([
                    'description' => '',
                    'description_translations' => null,
                    'city' => '',
                    'district' => null,
                ]);
            }
        });

        return response()->json(['message' => 'Account deleted.']);
    }
}
