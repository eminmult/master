<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Review;
use App\Models\ReviewPhoto;
use App\Services\ImageService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReviewController extends Controller
{
    public function store(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if ($user->id !== $order->client_id && $user->id !== $order->master_id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        if (!in_array($order->status, ['completed', 'closed', 'awaiting_review'])) {
            return response()->json(['message' => 'Order not completed yet.'], 422);
        }

        // Check if already reviewed
        $existing = Review::where('order_id', $order->id)->where('reviewer_id', $user->id)->first();
        if ($existing) {
            return response()->json(['message' => 'Already reviewed.'], 422);
        }

        $data = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'text' => 'nullable|string|max:1000',
            'photos' => 'nullable|array|max:5',
            'photos.*' => 'string', // base64
        ]);

        $revieweeId = $user->id === $order->client_id ? $order->master_id : $order->client_id;

        $review = DB::transaction(function () use ($order, $user, $data, $revieweeId) {
            $review = Review::create([
                'order_id' => $order->id,
                'reviewer_id' => $user->id,
                'reviewee_id' => $revieweeId,
                'rating' => $data['rating'],
                'text' => $data['text'] ?? null,
            ]);

            if (!empty($data['photos'])) {
                foreach ($data['photos'] as $i => $base64) {
                    $urls = ImageService::processBase64($base64, 'reviews/' . $review->id);
                    if ($urls) {
                        ReviewPhoto::create([
                            'review_id' => $review->id,
                            'thumb_url' => $urls['thumb'],
                            'medium_url' => $urls['medium'],
                            'large_url' => $urls['large'],
                            'sort_order' => $i,
                        ]);
                    }
                }
            }

            // Update review flags
            if ($user->id === $order->client_id) {
                $order->update(['client_reviewed' => true]);
            } else {
                $order->update(['master_reviewed' => true]);
            }

            // If both reviewed — close order
            $order->refresh();
            if ($order->client_reviewed && $order->master_reviewed) {
                $order->update(['status' => Order::STATUS_CLOSED, 'closed_at' => now()]);
                $order->logStatus(Order::STATUS_CLOSED, $user->id);
            }

            // Recalculate reviewee rating within the same transaction so a failure rolls
            // back everything including the new review.
            $reviewee = \App\Models\User::find($revieweeId);
            if ($reviewee) {
                $reviewee->recalculateRating();
            }

            return $review;
        });

        // Notification is dispatched *after* the transaction commits so a later error
        // cannot cause a notification about a review that was rolled back.
        NotificationService::newReview($revieweeId, $user->first_name, $data['rating'], $order->id);

        return response()->json(['review' => $review], 201);
    }

    // Get pending reviews for user
    public function pending(Request $request): JsonResponse
    {
        $user = $request->user();

        $orders = Order::whereIn('status', ['completed', 'awaiting_review', 'closed'])
            ->where(function ($q) use ($user) {
                $q->where(function ($q2) use ($user) {
                    $q2->where('client_id', $user->id)->where('client_reviewed', false);
                })->orWhere(function ($q2) use ($user) {
                    $q2->where('master_id', $user->id)->where('master_reviewed', false);
                });
            })
            ->with(['client', 'master', 'category'])
            ->orderByDesc('completed_at')
            ->limit(10)
            ->get();

        return response()->json(['orders' => $orders]);
    }
}
