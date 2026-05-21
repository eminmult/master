<?php

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\MasterController;
use App\Http\Controllers\Api\MasterListController;
use App\Http\Controllers\Api\OrderController;
use Illuminate\Support\Facades\Route;

/**
 * Routes are registered twice:
 *   - Unprefixed under /api/* — legacy entrypoint used by the current web frontend.
 *   - Versioned under /api/v1/* — canonical entrypoint mobile clients should target.
 *
 * Future breaking changes go to /api/v2/* without disturbing live mobile installs.
 * Do not add endpoints inside the closure that depend on a specific prefix; use
 * route('name') / url() helpers if you need self-references.
 */
$registerApi = function () {

// Public — throttle to block credential stuffing and registration spam
Route::middleware('throttle:20,1')->group(function () {
    Route::post('/auth/register/client', [AuthController::class, 'registerClient']);
    Route::post('/auth/register/master', [AuthController::class, 'registerMaster']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/auth/verify-email', [AuthController::class, 'verifyEmail']);
});

// Health check — used by load balancers / uptime monitors.
// Returns 200 if app, db, redis are reachable; 503 otherwise. No auth.
Route::get('/health', function () {
    $checks = ['app' => 'ok', 'db' => 'ok', 'redis' => 'ok', 'queue' => 'ok'];
    $code = 200;

    try {
        \Illuminate\Support\Facades\DB::connection()->getPdo();
    } catch (\Throwable $e) {
        $checks['db'] = 'fail';
        $code = 503;
    }

    try {
        \Illuminate\Support\Facades\Redis::connection()->ping();
    } catch (\Throwable $e) {
        $checks['redis'] = 'fail';
        $code = 503;
    }

    try {
        $size = \Illuminate\Support\Facades\Redis::connection()->llen('queues:default');
        if ($size > 10000) $checks['queue'] = "backlog:{$size}";
    } catch (\Throwable $e) {
        $checks['queue'] = 'unknown';
    }

    return response()->json([
        'status' => $code === 200 ? 'ok' : 'degraded',
        'checks' => $checks,
        'version' => env('APP_VERSION', 'dev'),
        'time' => now()->toIso8601String(),
    ], $code);
});

// Mobile app config — min supported version, force-update flag, store URLs.
// Mobile clients call this on boot to decide whether to show "please update" wall.
Route::get('/app/config', [\App\Http\Controllers\Api\AppConfigController::class, 'index']);

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/{category}', [CategoryController::class, 'show']);

// Public list of cities derived from active master profiles.
Route::get('/cities', [\App\Http\Controllers\Api\CityController::class, 'index']);

// Blog — public list + single post by slug.
Route::get('/posts', [\App\Http\Controllers\Api\PostController::class, 'index']);
Route::get('/posts/{slug}', [\App\Http\Controllers\Api\PostController::class, 'show']);

// City × Category SEO content (intro, pricing, FAQs). Falls back to the
// generic category content when no city-specific row exists yet.
Route::get('/cities/{city}/categories/{category}/content', function (string $city, $category) {
    $cat = ctype_digit((string) $category)
        ? \App\Models\Category::find((int) $category)
        : \App\Models\Category::where('slug', $category)
            ->orWhereRaw("EXISTS (SELECT 1 FROM jsonb_each_text(slug_translations) WHERE value = ?)", [$category])
            ->first();
    if (!$cat) abort(404);
    $locale = app()->getLocale();
    $row = \App\Models\CityCategoryContent::where('city_slug', $city)
        ->where('category_id', $cat->id)
        ->where('locale', $locale)
        ->value('body');
    if (!$row) {
        // Fallback to generic category content so the page isn't empty.
        $row = \App\Models\CategoryContent::where('category_id', $cat->id)
            ->where('locale', $locale)->value('body');
    }
    return response()->json(['content' => $row]);
});

// Public list of supported locales — both clients fetch on bootstrap.
Route::get('/i18n/locales', [\App\Http\Controllers\Api\LocaleController::class, 'index']);

Route::get('/users/{id}/profile', [\App\Http\Controllers\Api\UserProfileController::class, 'show']);
Route::get('/masters', [MasterListController::class, 'index']);
Route::get('/masters/{id}', [MasterListController::class, 'show']);
Route::get('/masters/{id}/reviews', [MasterListController::class, 'reviews']);

// AI-assisted smart search — text + optional photo → category classification
Route::middleware('throttle:30,1')->post('/smart-search', [\App\Http\Controllers\Api\SmartSearchController::class, 'classify']);

// Core Web Vitals beacon — the frontend posts LCP/INP/CLS/TTFB samples here
// from real users. We log to a dedicated channel so an offline aggregator can
// build percentile dashboards without straining the request hot path.
Route::middleware('throttle:120,1')->post('/cwv', function (\Illuminate\Http\Request $r) {
    $data = $r->validate([
        'name' => 'required|string|in:LCP,INP,CLS,TTFB,FCP',
        'value' => 'required|numeric',
        'id' => 'nullable|string|max:64',
        'path' => 'nullable|string|max:512',
        'rating' => 'nullable|in:good,needs-improvement,poor',
    ]);
    \Illuminate\Support\Facades\Log::channel('cwv')->info('cwv', $data);
    return response()->noContent();
});

// Public homepage stats (masters count, completed orders, avg rating) — cached 5 min
Route::get('/stats/public', function () {
    $stats = \Illuminate\Support\Facades\Cache::remember('stats:public', now()->addMinutes(5), function () {
        $masters = \App\Models\User::where('role', 'master')->where('is_active', true)->count();
        $completed = \App\Models\Order::whereIn('status', ['completed', 'closed'])->count();
        $rating = (float) \App\Models\User::where('role', 'master')
            ->where('rating_count', '>', 0)->avg('rating_avg') ?: 0;
        return [
            'masters' => $masters,
            'completed_orders' => $completed,
            'avg_rating' => round($rating, 1),
        ];
    });
    return response()->json(['stats' => $stats]);
});

// Public announcements feed — visible to everyone (guests, clients, masters)
Route::middleware('throttle:120,1')->group(function () {
    Route::get('/orders/public', [OrderController::class, 'publicIndex']);
    Route::get('/orders/public/{order}', [OrderController::class, 'publicShow']);
});

// Authenticated
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/refresh', [AuthController::class, 'refresh'])->middleware('throttle:30,1');
    Route::post('/auth/resend-verification', [AuthController::class, 'resendEmailVerification'])->middleware('throttle:5,1');
    Route::post('/auth/phone/request-otp', [AuthController::class, 'requestPhoneOtp'])->middleware('throttle:3,1');
    Route::post('/auth/phone/verify-otp', [AuthController::class, 'verifyPhoneOtp'])->middleware('throttle:10,1');

    // Mobile push token registration
    Route::post('/devices/register', [\App\Http\Controllers\Api\DeviceController::class, 'register'])->middleware('throttle:30,1');
    Route::post('/devices/unregister', [\App\Http\Controllers\Api\DeviceController::class, 'unregister'])->middleware('throttle:30,1');

    // GDPR — export own data / delete account
    Route::get('/me/export', [\App\Http\Controllers\Api\PrivacyController::class, 'export'])->middleware('throttle:3,60');
    Route::post('/me/delete', [\App\Http\Controllers\Api\PrivacyController::class, 'delete'])->middleware('throttle:3,60');

    // Persist user's preferred locale — clients call this on every language switch.
    Route::patch('/me/locale', [\App\Http\Controllers\Api\LocaleController::class, 'update']);

    // Change password (auth'd self-service; resetPassword stays for forgot-flow).
    Route::post('/auth/change-password', [AuthController::class, 'changePassword'])->middleware('throttle:10,60');

    // Orders (shared)
    Route::post('/orders', [OrderController::class, 'store'])->middleware('throttle:10,1');
    Route::get('/orders/my', [OrderController::class, 'myOrders']);
    Route::get('/orders/available', [OrderController::class, 'available']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);
    Route::post('/orders/{order}/accept', [OrderController::class, 'accept']);
    Route::post('/orders/{order}/decline', [OrderController::class, 'decline']);

    // Applications to public announcements — multi-master parallel discussions.
    // Announcement stays open until client explicitly accepts a proposal OR cancels the order.
    // master.active gates master mutations behind subscription (no-op during free launch).
    Route::post('/orders/{order}/apply', [\App\Http\Controllers\Api\OrderApplicationController::class, 'apply'])->middleware(['throttle:10,1', 'master.active']);
    Route::get('/orders/{order}/applications', [\App\Http\Controllers\Api\OrderApplicationController::class, 'index']);
    // Client starts chatting with one master (non-exclusive — can start with several)
    Route::post('/order-applications/{application}/start-discussion', [\App\Http\Controllers\Api\OrderApplicationController::class, 'startDiscussion']);
    Route::post('/order-applications/{application}/reject', [\App\Http\Controllers\Api\OrderApplicationController::class, 'reject']);
    Route::post('/order-applications/{application}/withdraw', [\App\Http\Controllers\Api\OrderApplicationController::class, 'withdraw']);
    // Master proposes date + price
    Route::post('/order-applications/{application}/propose', [\App\Http\Controllers\Api\OrderApplicationController::class, 'propose'])->middleware('master.active');
    // Client finalizes — this is what closes the announcement
    Route::post('/order-applications/{application}/accept-proposal', [\App\Http\Controllers\Api\OrderApplicationController::class, 'acceptProposal']);
    Route::post('/order-applications/{application}/reject-proposal', [\App\Http\Controllers\Api\OrderApplicationController::class, 'rejectProposal']);
    // Per-application chat
    Route::get('/order-applications/{application}', [\App\Http\Controllers\Api\OrderApplicationController::class, 'show']);
    Route::get('/order-applications/{application}/messages', [\App\Http\Controllers\Api\OrderApplicationController::class, 'messages']);
    Route::post('/order-applications/{application}/messages', [\App\Http\Controllers\Api\OrderApplicationController::class, 'sendMessage'])->middleware(['throttle:60,1', 'master.active']);
    Route::get('/master/applications', [\App\Http\Controllers\Api\OrderApplicationController::class, 'mine']);
    Route::get('/master/applied-order-ids', function (\Illuminate\Http\Request $request) {
        $user = $request->user();
        if (!$user->isMaster()) return response()->json(['order_ids' => [], 'applications' => []]);
        $apps = \App\Models\OrderApplication::where('master_id', $user->id)
            ->whereIn('status', ['pending', 'accepted'])
            ->get(['id', 'order_id', 'status']);
        return response()->json([
            'order_ids' => $apps->pluck('order_id'),
            'applications' => $apps->map(fn($a) => [
                'id' => $a->id,
                'order_id' => $a->order_id,
                'status' => $a->status,
            ]),
        ]);
    });
    Route::post('/orders/{order}/confirm', [OrderController::class, 'confirm']);
    Route::post('/orders/{order}/reject-proposal', [OrderController::class, 'rejectProposal']);
    Route::post('/orders/{order}/status', [OrderController::class, 'updateStatus']);
    Route::post('/orders/{order}/cancel', [OrderController::class, 'cancel']);

    // Callout fee — client pays platform-mediated fee to confirm an order
    // after the master proposed an arrival time.
    Route::get('/orders/{order}/callout-fee',  [\App\Http\Controllers\Api\CalloutFeeController::class, 'preview']);
    Route::post('/orders/{order}/pay-callout', [\App\Http\Controllers\Api\CalloutFeeController::class, 'pay'])->middleware('throttle:5,1');

    // Master wallet — balance + transaction history.
    Route::get('/wallet/balance',      [\App\Http\Controllers\Api\WalletController::class, 'balance']);
    Route::get('/wallet/transactions', [\App\Http\Controllers\Api\WalletController::class, 'transactions']);

    // Withdrawals — master requests payout (stub: admin settles manually).
    Route::get('/withdrawals',                 [\App\Http\Controllers\Api\WithdrawalController::class, 'index']);
    Route::post('/withdrawals',                [\App\Http\Controllers\Api\WithdrawalController::class, 'store'])->middleware('throttle:5,1');
    Route::post('/withdrawals/{withdrawal}/cancel', [\App\Http\Controllers\Api\WithdrawalController::class, 'cancel']);

    // Chat — moderate throttle to prevent flooding
    Route::get('/orders/{order}/messages', [ChatController::class, 'messages']);
    Route::post('/orders/{order}/messages', [ChatController::class, 'send'])->middleware('throttle:60,1');
    Route::get('/chat/unread', [ChatController::class, 'unreadCount']);

    // Disputes — only allowed during/after work, not while still searching.
    Route::post('/orders/{order}/dispute', function (\Illuminate\Http\Request $request, \App\Models\Order $order) {
        $user = $request->user();
        if ($user->id !== $order->client_id && $user->id !== $order->master_id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $disputableStatuses = [
            \App\Models\Order::STATUS_CONFIRMED,
            \App\Models\Order::STATUS_ON_THE_WAY,
            \App\Models\Order::STATUS_ARRIVED,
            \App\Models\Order::STATUS_IN_PROGRESS,
            \App\Models\Order::STATUS_AWAITING_COMPLETION,
            \App\Models\Order::STATUS_COMPLETED,
        ];
        if (!in_array($order->status, $disputableStatuses, true)) {
            return response()->json(['message' => 'Order is not in a disputable state'], 422);
        }

        if (\App\Models\Dispute::where('order_id', $order->id)->whereNull('resolved_at')->exists()) {
            return response()->json(['message' => 'Dispute already open for this order'], 422);
        }

        $data = $request->validate([
            'reason' => 'required|string|max:100',
            'description' => 'nullable|string|max:2000',
        ]);

        $dispute = \App\Models\Dispute::create([
            'order_id' => $order->id,
            'reporter_id' => $user->id,
            'reason' => $data['reason'],
            'description' => $data['description'] ?? null,
        ]);

        $order->update(['status' => \App\Models\Order::STATUS_DISPUTED]);
        $order->logStatus(\App\Models\Order::STATUS_DISPUTED, $user->id, null, null, "Dispute opened: {$data['reason']}");

        $otherId = $user->id === $order->client_id ? $order->master_id : $order->client_id;
        if ($otherId) {
            \App\Services\NotificationService::send($otherId, 'dispute_opened', [
                'az' => 'Mübahisə açıldı',
                'ru' => 'Открыт спор',
                'en' => 'Dispute opened',
            ], [
                'az' => "#{$order->id} — qarşı tərəf mübahisə açdı",
                'ru' => "#{$order->id} — другая сторона открыла спор",
                'en' => "#{$order->id} — counterparty opened a dispute",
            ], ['order_id' => $order->id, 'dispute_id' => $dispute->id]);
        }

        return response()->json(['dispute' => $dispute, 'order_status' => $order->status], 201);
    })->middleware('throttle:5,1');

    // Reviews
    Route::post('/orders/{order}/review', [\App\Http\Controllers\Api\ReviewController::class, 'store'])->middleware('throttle:10,1');
    Route::get('/reviews/pending', [\App\Http\Controllers\Api\ReviewController::class, 'pending']);

    // Notifications
    Route::get('/notifications', [\App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [\App\Http\Controllers\Api\NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{notification}/read', [\App\Http\Controllers\Api\NotificationController::class, 'markRead']);
    Route::post('/notifications/read-all', [\App\Http\Controllers\Api\NotificationController::class, 'markAllRead']);

    // Avatar upload — validates MIME and generates 3 WebP sizes
    Route::post('/avatar', function (\Illuminate\Http\Request $request) {
        $request->validate(['avatar' => 'required|string']);
        $urls = \App\Services\ImageService::processBase64($request->avatar, 'avatars');
        if (empty($urls)) {
            return response()->json(['message' => 'Invalid or unsupported image.'], 422);
        }
        $url = $urls['medium'] ?? $urls['large'] ?? reset($urls);
        $request->user()->update(['avatar_url' => $url]);
        return response()->json(['avatar_url' => $url]);
    });

    // Saved payment cards — stub mode (no PAN persisted, last4 + brand + expiry only)
    Route::get('/payment-cards', [\App\Http\Controllers\Api\PaymentCardController::class, 'index']);
    Route::post('/payment-cards', [\App\Http\Controllers\Api\PaymentCardController::class, 'store']);
    Route::post('/payment-cards/{card}/default', [\App\Http\Controllers\Api\PaymentCardController::class, 'setDefault']);
    Route::delete('/payment-cards/{card}', [\App\Http\Controllers\Api\PaymentCardController::class, 'destroy']);

    // In-app voice calls (WebRTC over Reverb). Phones are never exposed to either party.
    Route::get('/calls',                         [\App\Http\Controllers\Api\CallController::class, 'index']);
    Route::post('/calls',                        [\App\Http\Controllers\Api\CallController::class, 'initiate'])->middleware('throttle:30,1');
    Route::get('/calls/{call}',                  [\App\Http\Controllers\Api\CallController::class, 'show']);
    Route::post('/calls/{call}/accept',          [\App\Http\Controllers\Api\CallController::class, 'accept']);
    Route::post('/calls/{call}/reject',          [\App\Http\Controllers\Api\CallController::class, 'reject']);
    Route::post('/calls/{call}/end',             [\App\Http\Controllers\Api\CallController::class, 'end']);
    Route::post('/calls/{call}/signal',          [\App\Http\Controllers\Api\CallController::class, 'signal'])->middleware('throttle:300,1');

    // Client
    Route::put('/client/profile', [ClientController::class, 'updateProfile']);
    Route::get('/addresses', [\App\Http\Controllers\Api\AddressController::class, 'index']);
    Route::post('/addresses', [\App\Http\Controllers\Api\AddressController::class, 'store']);
    Route::put('/addresses/{address}', [\App\Http\Controllers\Api\AddressController::class, 'update']);
    Route::delete('/addresses/{address}', [\App\Http\Controllers\Api\AddressController::class, 'destroy']);

    // Master
    Route::put('/master/profile', [MasterController::class, 'updateProfile']);
    Route::put('/master/status', [MasterController::class, 'updateStatus']);
    Route::post('/master/location', [MasterController::class, 'updateLocation']);
    Route::get('/master/work-hours', function (\Illuminate\Http\Request $request) {
        $profile = $request->user()->masterProfile;
        return response()->json(['hours' => $profile ? $profile->workHours : []]);
    });
    Route::post('/master/work-hours', function (\Illuminate\Http\Request $request) {
        $profile = $request->user()->masterProfile;
        if (!$profile) return response()->json(['message' => 'No profile'], 404);
        $data = $request->validate(['hours' => 'required|array']);
        $profile->workHours()->delete();
        foreach ($data['hours'] as $h) {
            $profile->workHours()->create(['day_of_week' => $h['day'], 'start_time' => $h['start'], 'end_time' => $h['end']]);
        }
        return response()->json(['hours' => $profile->workHours()->get()]);
    });
    Route::get('/master/earnings', function (\Illuminate\Http\Request $request) {
        $user = $request->user();
        $orders = \App\Models\Order::where('master_id', $user->id);

        $thisMonth = (clone $orders)->where('completed_at', '>=', now()->startOfMonth())->whereIn('status', ['completed', 'closed']);
        $lastMonth = (clone $orders)->where('completed_at', '>=', now()->subMonth()->startOfMonth())->where('completed_at', '<', now()->startOfMonth())->whereIn('status', ['completed', 'closed']);
        $thisWeek = (clone $orders)->where('completed_at', '>=', now()->startOfWeek())->whereIn('status', ['completed', 'closed']);

        // Daily orders for last 30 days
        $daily = \Illuminate\Support\Facades\DB::select("
            SELECT DATE(completed_at) as date, COUNT(*) as count, COALESCE(SUM(agreed_price), 0) as revenue
            FROM orders
            WHERE master_id = ? AND status IN ('completed', 'closed') AND completed_at >= ?
            GROUP BY DATE(completed_at)
            ORDER BY date
        ", [$user->id, now()->subDays(30)->toDateString()]);

        return response()->json([
            'stats' => [
                'this_month_orders' => $thisMonth->count(),
                'this_month_revenue' => $thisMonth->sum('agreed_price') ?? 0,
                'last_month_orders' => $lastMonth->count(),
                'last_month_revenue' => $lastMonth->sum('agreed_price') ?? 0,
                'this_week_orders' => $thisWeek->count(),
                'this_week_revenue' => $thisWeek->sum('agreed_price') ?? 0,
                'total_orders' => $user->masterProfile?->completed_orders_count ?? 0,
                'rating' => $user->rating_avg,
                'daily' => $daily,
            ],
        ]);
    });

    // Category suggestions (any authenticated user)
    Route::post('/category-suggestions', [\App\Http\Controllers\Api\CategorySuggestionController::class, 'store'])->middleware('throttle:5,1');
    Route::get('/category-suggestions/mine', [\App\Http\Controllers\Api\CategorySuggestionController::class, 'mine']);

    // Admin
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        // Blog post create/update/delete (single endpoint upserts on slug+locale).
        Route::post('/posts', [\App\Http\Controllers\Api\PostController::class, 'upsert']);
        Route::delete('/posts/{slug}/{locale}', [\App\Http\Controllers\Api\PostController::class, 'destroy']);

        // Withdrawals — admin settles master payouts manually until a real PSP is wired.
        Route::get('/withdrawals',                            [\App\Http\Controllers\Api\WithdrawalController::class, 'adminIndex']);
        Route::post('/withdrawals/{withdrawal}/approve',      [\App\Http\Controllers\Api\WithdrawalController::class, 'adminApprove']);
        Route::post('/withdrawals/{withdrawal}/mark-paid',    [\App\Http\Controllers\Api\WithdrawalController::class, 'adminMarkPaid']);
        Route::post('/withdrawals/{withdrawal}/reject',       [\App\Http\Controllers\Api\WithdrawalController::class, 'adminReject']);

        Route::get('/category-suggestions', [\App\Http\Controllers\Api\CategorySuggestionController::class, 'index']);
        Route::post('/category-suggestions/{suggestion}/approve', [\App\Http\Controllers\Api\CategorySuggestionController::class, 'approve']);
        Route::post('/category-suggestions/{suggestion}/reject', [\App\Http\Controllers\Api\CategorySuggestionController::class, 'reject']);
        Route::get('/users', [AdminController::class, 'users']);
        Route::get('/orders', [AdminController::class, 'orders']);
        Route::get('/categories', [AdminController::class, 'categories']);
        Route::post('/categories', function (\Illuminate\Http\Request $request) {
            $data = $request->validate(['name' => 'required|string', 'slug' => 'required|string|unique:categories', 'icon_url' => 'nullable|string', 'description' => 'nullable|string']);
            $cat = \App\Models\Category::create($data);
            \App\Http\Controllers\Api\CategoryController::clearCache();
            return response()->json(['category' => $cat], 201);
        });
        Route::put('/categories/{category}', function (\Illuminate\Http\Request $request, \App\Models\Category $category) {
            $data = $request->validate(['name' => 'required|string', 'slug' => 'required|string', 'icon_url' => 'nullable|string', 'description' => 'nullable|string']);
            $category->update($data);
            \App\Http\Controllers\Api\CategoryController::clearCache();
            return response()->json(['category' => $category]);
        });
        Route::delete('/categories/{category}', function (\Illuminate\Http\Request $request, \App\Models\Category $category) {
            $category->delete();
            \App\Http\Controllers\Api\CategoryController::clearCache();
            return response()->json(['ok' => true]);
        });
        Route::get('/analytics/daily', function () {
            $daily = \Illuminate\Support\Facades\DB::select("SELECT DATE(created_at) as date, COUNT(*) as count FROM orders WHERE created_at >= ? GROUP BY DATE(created_at) ORDER BY date", [now()->subDays(30)->toDateString()]);
            return response()->json(['daily' => $daily]);
        });
        Route::get('/reviews', [AdminController::class, 'reviews']);
        Route::get('/disputes', [AdminController::class, 'disputes']);
        Route::get('/analytics', [AdminController::class, 'analytics']);
        Route::post('/users/{user}/toggle-block', [AdminController::class, 'toggleBlock']);
        Route::post('/users/{user}/verify', [AdminController::class, 'verifyMaster']);
        Route::post('/users/{user}/extend-subscription', [AdminController::class, 'extendSubscription']);
        Route::post('/users/{user}/deactivate-subscription', [AdminController::class, 'deactivateSubscription']);
        Route::post('/orders/{order}/set-status', [AdminController::class, 'updateOrderStatus']);
        Route::post('/disputes/{dispute}/resolve', [AdminController::class, 'resolveDispute']);
        Route::delete('/reviews/{review}', [AdminController::class, 'deleteReview']);
    });
});

}; // end of $registerApi closure

// Mount under canonical /api/v1/* (mobile clients target this).
Route::prefix('v1')->group($registerApi);

// Mount under unprefixed /api/* for backward compatibility with the existing
// web frontend. Once web migrates to v1, this block can be deleted.
$registerApi();
