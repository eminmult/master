<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\MasterCategory;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'subcategory_id' => 'nullable|exists:subcategories,id',
            'description' => 'required|string|max:2000',
            'full_address' => 'required|string|max:500',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'entrance' => 'nullable|string|max:20',
            'floor' => 'nullable|string|max:10',
            'intercom' => 'nullable|string|max:20',
            'contact_phone' => 'required|string|max:20',
            'desired_time' => 'required|in:asap,scheduled',
            'scheduled_at' => 'nullable|date|after:now',
            'urgency' => 'required|in:normal,urgent',
            'estimated_budget' => 'nullable|numeric|min:0|max:999999',
            'comment' => 'nullable|string|max:1000',
            'preferred_master_id' => 'nullable|exists:users,id',
            'photos' => 'nullable|array|max:5',
            'photos.*' => 'string',
        ]);

        $preferredMasterId = $data['preferred_master_id'] ?? null;
        $photos = $data['photos'] ?? [];
        unset($data['preferred_master_id'], $data['photos']);

        // If preferred master — send request, waiting for master to accept
        if ($preferredMasterId) {
            $order = Order::create([
                ...$data,
                'client_id' => $request->user()->id,
                'master_id' => $preferredMasterId,
                'status' => Order::STATUS_PENDING_MASTER,
            ]);
            $order->logStatus(Order::STATUS_NEW, $request->user()->id);
            $order->logStatus(Order::STATUS_PENDING_MASTER, $request->user()->id);
            $order->load('category');
            NotificationService::orderCreated($order);
            NotificationService::newOrderAvailable($preferredMasterId, $order);
        } else {
            $order = Order::create([
                ...$data,
                'client_id' => $request->user()->id,
                'status' => Order::STATUS_SEARCHING,
            ]);
            $order->logStatus(Order::STATUS_NEW, $request->user()->id);
            $order->logStatus(Order::STATUS_SEARCHING, $request->user()->id);
            $order->load('category');
            NotificationService::orderCreated($order);

            // Notify matching masters
            $masterIds = MasterCategory::where('category_id', $order->category_id)
                ->whereHas('masterProfile', fn($q) => $q->where('status', 'online')->where('is_accepting_orders', true))
                ->with('masterProfile')
                ->get()
                ->pluck('masterProfile.user_id')
                ->unique();

            NotificationService::newOrderAvailableBulk($masterIds, $order);
        }

        // Process photos
        if (!empty($photos)) {
            foreach ($photos as $photoBase64) {
                $urls = \App\Services\ImageService::processBase64($photoBase64, 'orders/' . $order->id);
                if ($urls) {
                    $order->photos()->create([
                        'url' => $urls['large'],
                        'type' => 'problem',
                        'uploaded_by' => $request->user()->id,
                    ]);
                }
            }
        }

        return response()->json(['order' => $order->load(['category', 'subcategory'])], 201);
    }

    public function myOrders(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->isMaster()) {
            $orders = Order::with(['client', 'category'])
                ->where('master_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(50)
                ->get();
        } else {
            $orders = Order::with(['master', 'category'])
                ->where('client_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(50)
                ->get();
        }

        return response()->json(['orders' => $orders]);
    }

    public function available(Request $request): JsonResponse
    {
        $user = $request->user();
        $profile = $user->masterProfile;

        if (!$profile) {
            return response()->json(['orders' => []]);
        }

        $categoryIds = MasterCategory::where('master_profile_id', $profile->id)
            ->pluck('category_id');

        // Working hours lookup: day_of_week → [ [start, end], ... ]
        // day_of_week convention here: 0=Mon..6=Sun (matches migration)
        $hoursByDay = $profile->workHours()->get()->groupBy('day_of_week')->map(
            fn($rows) => $rows->map(fn($r) => [(string) $r->start_time, (string) $r->end_time])->all()
        )->all();
        $hasHours = !empty($hoursByDay);

        $matchesHours = function (?string $desiredTime, ?string $scheduledAt) use ($hoursByDay, $hasHours): bool {
            if (!$hasHours) return true;
            $ts = $desiredTime === 'scheduled' && $scheduledAt
                ? strtotime($scheduledAt)
                : time();
            // Convert PHP N (1=Mon..7=Sun) to our convention (0=Mon..6=Sun)
            $day = (int) date('N', $ts) - 1;
            $time = date('H:i:s', $ts);
            if (empty($hoursByDay[$day])) return false;
            foreach ($hoursByDay[$day] as [$start, $end]) {
                if ($time >= $start && $time <= $end) return true;
            }
            return false;
        };

        // Filter by distance if both the master and the order have coordinates.
        // If the master has not shared location yet, fall back to no distance filter
        // so they still see orders (prevents a "nothing to do" experience after signup).
        $masterLat = $profile->current_lat ? (float) $profile->current_lat : null;
        $masterLng = $profile->current_lng ? (float) $profile->current_lng : null;
        $radiusKm = (float) ($profile->work_radius_km ?? 20);
        $radiusKm = max(1, min($radiusKm, 200));

        $orders = Order::with(['category'])
            ->where('status', Order::STATUS_SEARCHING)
            ->whereIn('category_id', $categoryIds)
            ->orderByDesc('urgency')
            ->orderByDesc('created_at')
            ->limit(80) // over-fetch then distance-filter down
            ->get();

        if ($masterLat !== null && $masterLng !== null) {
            $orders = $orders->filter(function ($o) use ($masterLat, $masterLng, $radiusKm) {
                if ($o->lat === null || $o->lng === null) return true; // keep orders without coords
                $km = $this->haversineKm($masterLat, $masterLng, (float) $o->lat, (float) $o->lng);
                return $km <= $radiusKm;
            })->values();
        }

        // Working hours filter
        $orders = $orders->filter(fn($o) => $matchesHours($o->desired_time, $o->scheduled_at ? (string) $o->scheduled_at : null))->values();

        $orders = $orders->take(20)->map(function ($order) use ($masterLat, $masterLng) {
            $distanceKm = null;
            if ($masterLat !== null && $masterLng !== null && $order->lat !== null && $order->lng !== null) {
                $distanceKm = round($this->haversineKm($masterLat, $masterLng, (float) $order->lat, (float) $order->lng), 1);
            }
            return [
                'id' => $order->id,
                'category' => $order->category,
                'description' => $order->description,
                'district' => $order->entrance ? null : explode(',', $order->full_address)[0] ?? '',
                'urgency' => $order->urgency,
                'estimated_budget' => $order->estimated_budget,
                'desired_time' => $order->desired_time,
                'distance_km' => $distanceKm,
                'created_at' => $order->created_at,
            ];
        });

        return response()->json(['orders' => $orders->values()]);
    }

    private function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthR = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return 2 * $earthR * asin(min(1, sqrt($a)));
    }

    /**
     * Public feed of open announcements (status=searching_master).
     * Visible to everyone (guests, clients, masters) — no auth required.
     * Hides sensitive data (phone, exact address).
     */
    public function publicIndex(Request $request): JsonResponse
    {
        $categoryId = $request->query('category_id');
        $lat = $request->query('lat');
        $lng = $request->query('lng');
        $sort = $request->query('sort', 'recent'); // recent | distance
        $page = max(1, (int) $request->query('page', 1));
        $perPage = min(50, max(1, (int) $request->query('per_page', 20)));

        $q = Order::with(['category', 'client:id,first_name,avatar_url', 'photos:id,order_id,url'])
            ->where('status', Order::STATUS_SEARCHING)
            ->where('created_at', '>=', now()->subDays(30));

        if ($categoryId) $q->where('category_id', (int) $categoryId);

        if ($sort === 'distance' && $lat !== null && $lng !== null) {
            // PostgreSQL-native distance sort using haversine SQL
            $q->selectRaw("orders.*, (
                6371 * acos(
                    cos(radians(?)) * cos(radians(lat)) *
                    cos(radians(lng) - radians(?)) +
                    sin(radians(?)) * sin(radians(lat))
                )
            ) AS distance_km", [(float) $lat, (float) $lng, (float) $lat])
              ->whereNotNull('lat')->whereNotNull('lng')
              ->orderBy('distance_km', 'asc');
        } else {
            $q->orderByDesc('created_at');
        }

        $total = (clone $q)->count();
        $orders = $q->forPage($page, $perPage)->get();

        $viewerLat = $lat !== null ? (float) $lat : null;
        $viewerLng = $lng !== null ? (float) $lng : null;

        $items = $orders->map(function ($o) use ($viewerLat, $viewerLng) {
            $distance = null;
            if ($viewerLat !== null && $viewerLng !== null && $o->lat !== null && $o->lng !== null) {
                $distance = round($this->haversineKm($viewerLat, $viewerLng, (float) $o->lat, (float) $o->lng), 1);
            }
            $district = explode(',', (string) $o->full_address)[0] ?? '';
            return [
                'id' => $o->id,
                'category' => $o->category ? [
                    'id' => $o->category->id,
                    'name' => $o->category->name,
                    'icon_url' => $o->category->icon_url,
                ] : null,
                'description' => $o->description,
                'district' => trim($district),
                'urgency' => $o->urgency,
                'estimated_budget' => $o->estimated_budget,
                'desired_time' => $o->desired_time,
                'scheduled_at' => $o->scheduled_at,
                'distance_km' => $distance,
                'photos_count' => $o->photos->count(),
                'first_photo' => $o->photos->first()?->url,
                'client' => $o->client ? [
                    'first_name' => $o->client->first_name,
                    'avatar_url' => $o->client->avatar_url,
                ] : null,
                'created_at' => $o->created_at,
            ];
        });

        return response()->json([
            'orders' => $items,
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'has_more' => ($page * $perPage) < $total,
            ],
        ]);
    }

    /**
     * Public detail view of an announcement.
     * Returns 404 if not in status=searching_master (owner should use /orders/{id}).
     */
    public function publicShow(\Illuminate\Http\Request $request, Order $order): JsonResponse
    {
        if ($order->status !== Order::STATUS_SEARCHING) {
            return response()->json(['message' => 'Elan mövcud deyil.'], 404);
        }

        $order->load(['category', 'subcategory', 'client:id,first_name,avatar_url,rating_avg,rating_count', 'photos']);

        $district = explode(',', (string) $order->full_address)[0] ?? '';

        // For an authenticated master, surface the id of their own existing
        // application on this order (if any) — the mobile/web detail page
        // uses it to switch the bottom CTA from "Apply" → "Open chat".
        //
        // This route is OUTSIDE the auth:sanctum middleware group (it's
        // publicly viewable), so $request->user() falls back to the default
        // session guard which is always null for token-auth API clients.
        // Resolving the sanctum guard explicitly does the bearer-token
        // lookup even without middleware.
        $myApplicationId = null;
        $u = $request->user('sanctum') ?? \Illuminate\Support\Facades\Auth::guard('sanctum')->user();
        if ($u && $u->isMaster()) {
            $myApplicationId = \App\Models\OrderApplication::where('order_id', $order->id)
                ->where('master_id', $u->id)
                ->whereIn('status', ['pending', 'discussing', 'proposed'])
                ->value('id');
        }

        return response()->json([
            'order' => [
                'id' => $order->id,
                'category' => $order->category,
                'subcategory' => $order->subcategory,
                'description' => $order->description,
                'district' => trim($district),
                'urgency' => $order->urgency,
                'estimated_budget' => $order->estimated_budget,
                'desired_time' => $order->desired_time,
                'scheduled_at' => $order->scheduled_at,
                'comment' => $order->comment,
                'photos' => $order->photos->map(fn($p) => ['id' => $p->id, 'url' => $p->url]),
                'client' => $order->client ? [
                    'id' => $order->client->id,
                    'first_name' => $order->client->first_name,
                    'avatar_url' => $order->client->avatar_url,
                    'rating_avg' => $order->client->rating_avg,
                    'rating_count' => $order->client->rating_count,
                ] : null,
                'created_at' => $order->created_at,
                'my_application_id' => $myApplicationId,
            ],
        ]);
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        $isOwner = ($user->id === $order->client_id)
            || ($order->master_id !== null && $user->id === $order->master_id);

        if (!$isOwner && !$user->isAdmin()) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $order->load(['client', 'master.masterProfile', 'category', 'subcategory', 'photos', 'statusHistory']);

        // Client sees list of applications for their own searching_master order
        if ($user->id === $order->client_id && $order->status === Order::STATUS_SEARCHING) {
            $order->setRelation('applications', \App\Models\OrderApplication::with([
                'master:id,first_name,last_name,avatar_url,rating_avg,rating_count',
                'master.masterProfile:id,user_id,description,status,experience_years,completed_orders_count',
            ])->where('order_id', $order->id)
              ->orderByDesc('created_at')
              ->get());
        }

        $phoneVisibleStatuses = [
            Order::STATUS_CONFIRMED,
            Order::STATUS_ACCEPTED,
            Order::STATUS_ON_THE_WAY,
            Order::STATUS_ARRIVED,
            Order::STATUS_IN_PROGRESS,
            Order::STATUS_COMPLETED,
            Order::STATUS_AWAITING_REVIEW,
            Order::STATUS_CLOSED,
        ];

        if (!$user->isAdmin() && !in_array($order->status, $phoneVisibleStatuses, true)) {
            $order->contact_phone = null;
            if ($order->client) $order->client->phone = null;
            if ($order->master) $order->master->phone = null;
        }

        // Precise location is hidden from the master until they explicitly accept the job.
        // This prevents leaking the client's door-level address when the master just
        // browses the order (pending_master direct request, or searching_master pool).
        $addressHiddenStatuses = [Order::STATUS_PENDING_MASTER, Order::STATUS_SEARCHING, Order::STATUS_NEW];
        $isOwnerClient = $user->id === $order->client_id;
        if (!$user->isAdmin() && !$isOwnerClient && in_array($order->status, $addressHiddenStatuses, true)) {
            $order->lat = null;
            $order->lng = null;
            $order->entrance = null;
            $order->floor = null;
            $order->intercom = null;
            $order->address_id = null;
        }

        return response()->json(['order' => $order]);
    }

    public function accept(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMaster()) {
            return response()->json(['message' => 'Yalnız ustalar qəbul edə bilər.'], 403);
        }

        // Serialize concurrent accepts via DB row lock
        $result = DB::transaction(function () use ($order, $user) {
            $fresh = Order::where('id', $order->id)->lockForUpdate()->first();
            if (!$fresh) {
                return ['error' => ['message' => 'Sifariş tapılmadı.'], 'code' => 404];
            }

            // Public pool orders: master must use /apply (creates an application,
            // client then chooses one). Direct accept is no longer allowed here —
            // this prevents a master from hijacking a public order without the
            // client's approval.
            if ($fresh->status === Order::STATUS_SEARCHING) {
                return ['error' => ['message' => 'Açıq elanlar üçün müraciət göndərin — müştəri icraçını seçəcək.'], 'code' => 422];
            }

            // From pending_master → discussion (direct request model — client
            // already picked this specific master, master now confirms)
            if ($fresh->status === Order::STATUS_PENDING_MASTER && $fresh->master_id === $user->id) {
                $fresh->update([
                    'status' => Order::STATUS_DISCUSSION,
                    'accepted_at' => now(),
                ]);
                $fresh->logStatus(Order::STATUS_DISCUSSION, $user->id);
                return ['order' => $fresh];
            }

            return ['error' => ['message' => 'Bu sifariş artıq qəbul edilib və ya qəbul edilə bilməz.'], 'code' => 409];
        });

        if (isset($result['error'])) {
            return response()->json($result['error'], $result['code']);
        }

        $order = $result['order']->load('category', 'master');
        NotificationService::orderAccepted($order);
        return response()->json(['order' => $order->load(['client', 'category'])]);
    }

    // Master declines direct request
    public function decline(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if ($order->status !== Order::STATUS_PENDING_MASTER || $order->master_id !== $user->id) {
            return response()->json(['message' => 'Bu əməliyyat mümkün deyil.'], 422);
        }

        $order->update([
            'status' => Order::STATUS_CANCELED_MASTER,
            'master_id' => null,
            'canceled_at' => now(),
            'cancel_reason' => 'Usta sorğunu rədd etdi',
        ]);
        $order->logStatus(Order::STATUS_CANCELED_MASTER, $user->id);
        NotificationService::orderCanceled($order, 'master');

        // No callout-fee refund path here — the order never reached confirmed,
        // so no payment exists. refundOnMasterCancel() is a no-op for unpaid
        // orders but we don't bother invoking it.
        return response()->json(['order' => $order]);
    }

    /**
     * Master proposes ONLY an arrival time → status flips to pending_client.
     * Price of the work itself is negotiated freely in the chat and is no
     * longer part of the structured proposal — the only platform-mediated
     * money is the fixed callout fee that the client pays to confirm.
     */
    public function confirm(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        // Master proposes arrival time
        if ($order->status === Order::STATUS_DISCUSSION && $order->master_id === $user->id) {
            $data = $request->validate([
                'agreed_date' => 'required|date|after:now',
            ]);

            $agreedDate = $data['agreed_date'];

            $order->update([
                'status'      => Order::STATUS_PENDING_CLIENT,
                'agreed_date' => $agreedDate,
                'agreed_price'=> null, // no longer used in the proposal
            ]);
            $order->logStatus(Order::STATUS_PENDING_CLIENT, $user->id);

            \App\Models\ChatMessage::create([
                'order_id'  => $order->id,
                'sender_id' => $user->id,
                'text'      => json_encode([
                    '_type' => 'proposal',
                    'date'  => date('d.m.Y H:i', strtotime($agreedDate)),
                ], JSON_UNESCAPED_UNICODE),
            ]);

            $dateStr = date('d.m.Y H:i', strtotime($agreedDate));
            NotificationService::send($order->client_id, 'order_proposal', [
                'az' => 'Usta gəliş vaxtı təklif etdi',
                'ru' => 'Мастер предложил время прибытия',
                'en' => 'Master proposed an arrival time',
                'tr' => 'Usta varış zamanı önerdi',
                'ar' => 'اقترح المحترف وقت الوصول',
            ], [
                'az' => "#{$order->id} — {$dateStr}. Çağırış ödənişi ilə təsdiqləyin.",
                'ru' => "#{$order->id} — {$dateStr}. Подтвердите, оплатив вызов.",
                'en' => "#{$order->id} — {$dateStr}. Confirm by paying the callout fee.",
                'tr' => "#{$order->id} — {$dateStr}. Çağrı ödemesi ile onaylayın.",
                'ar' => "#{$order->id} — {$dateStr}. أكد بدفع رسوم الاستدعاء.",
            ], ['order_id' => $order->id]);

            return response()->json(['order' => $order->fresh()->load(['client', 'category'])]);
        }

        // Client "confirms" — but we no longer flip to CONFIRMED here. The
        // client must pay the callout fee via POST /orders/{id}/pay-callout,
        // which is the only path to STATUS_CONFIRMED. Return a 409 hint so
        // misuse from older clients is loud.
        if ($order->status === Order::STATUS_PENDING_CLIENT && $order->client_id === $user->id) {
            return response()->json([
                'message' => 'Confirmation now requires callout fee payment. Use POST /orders/{order}/pay-callout.',
                'next'    => 'pay-callout',
            ], 409);
        }

        return response()->json(['message' => 'Bu əməliyyat mümkün deyil.'], 422);
    }

    // Client rejects proposal → back to discussion
    public function rejectProposal(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();
        if ($order->status === Order::STATUS_PENDING_CLIENT && $order->client_id === $user->id) {
            $order->update([
                'status' => Order::STATUS_DISCUSSION,
                'agreed_date' => null,
                'agreed_price' => null,
            ]);
            $order->logStatus(Order::STATUS_DISCUSSION, $user->id, null, null, 'Client rejected proposal');

            \App\Models\ChatMessage::create([
                'order_id' => $order->id,
                'sender_id' => $user->id,
                'text' => json_encode(['_type' => 'rejected'], JSON_UNESCAPED_UNICODE),
            ]);

            NotificationService::send($order->master_id, 'proposal_rejected', [
                'az' => 'Təklif rədd edildi',
                'ru' => 'Предложение отклонено',
                'en' => 'Proposal rejected',
            ], [
                'az' => "#{$order->id} — müştəri yenidən müzakirə istəyir",
                'ru' => "#{$order->id} — клиент хочет обсудить заново",
                'en' => "#{$order->id} — client wants to discuss again",
            ], ['order_id' => $order->id]);

            return response()->json(['order' => $order->fresh()->load(['client', 'category'])]);
        }

        return response()->json(['message' => 'Bu əməliyyat mümkün deyil.'], 422);
    }

    public function updateStatus(Request $request, Order $order): JsonResponse
    {
        $request->validate([
            'status' => 'required|string|in:' . implode(',', Order::ALL_STATUSES),
        ]);

        $user = $request->user();
        $newStatus = $request->status;

        // Allowed transitions per role — only statuses the master / client may drive via this endpoint.
        // Cancellations go through cancel(), proposals through confirm()/rejectProposal(),
        // and searching_master/pending_master/discussion/pending_client transitions are
        // handled by accept/confirm flows. This endpoint is the "work-in-progress" lane.
        $masterTransitions = [
            Order::STATUS_CONFIRMED => [Order::STATUS_ON_THE_WAY],
            Order::STATUS_ACCEPTED => [Order::STATUS_ON_THE_WAY],
            Order::STATUS_ON_THE_WAY => [Order::STATUS_ARRIVED],
            Order::STATUS_ARRIVED => [Order::STATUS_IN_PROGRESS],
            Order::STATUS_IN_PROGRESS => [Order::STATUS_AWAITING_COMPLETION],
        ];
        $clientTransitions = [
            Order::STATUS_AWAITING_COMPLETION => [Order::STATUS_COMPLETED],
        ];

        $isMaster = $user->id === $order->master_id;
        $isClient = $user->id === $order->client_id;

        // Master: in_progress → awaiting_completion (triggered by sending status=completed for backward-compat)
        if ($isMaster
            && $order->status === Order::STATUS_IN_PROGRESS
            && $newStatus === Order::STATUS_COMPLETED
        ) {
            $newStatus = Order::STATUS_AWAITING_COMPLETION;
        }

        // Pick the allowed transitions based on who is acting
        $allowed = [];
        if ($isMaster) $allowed = $masterTransitions;
        elseif ($isClient) $allowed = $clientTransitions;
        elseif ($user->isAdmin()) $allowed = $masterTransitions + $clientTransitions;
        else {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        if (!isset($allowed[$order->status]) || !in_array($newStatus, $allowed[$order->status], true)) {
            return response()->json(['message' => 'Bu status keçidi mümkün deyil.'], 422);
        }

        $timestamps = [
            Order::STATUS_ON_THE_WAY => 'on_the_way_at',
            Order::STATUS_ARRIVED => 'arrived_at',
            Order::STATUS_IN_PROGRESS => 'started_at',
            Order::STATUS_AWAITING_COMPLETION => 'completed_at',
            Order::STATUS_COMPLETED => 'completed_at',
        ];

        $updateData = ['status' => $newStatus];
        if (isset($timestamps[$newStatus])) {
            $updateData[$timestamps[$newStatus]] = now();
        }

        $order->update($updateData);
        $order->logStatus($newStatus, $user->id);

        // Notifications
        match ($newStatus) {
            Order::STATUS_ON_THE_WAY => NotificationService::masterOnTheWay($order),
            Order::STATUS_ARRIVED => NotificationService::masterArrived($order),
            Order::STATUS_IN_PROGRESS => NotificationService::workStarted($order),
            Order::STATUS_AWAITING_COMPLETION => NotificationService::send(
                $order->client_id,
                'awaiting_completion',
                ['az' => 'Usta isi bitirdi!', 'ru' => 'Мастер завершил работу!', 'en' => 'Master finished work!'],
                [
                    'az' => "#{$order->id} — isi tesdiqleyin",
                    'ru' => "#{$order->id} — подтвердите выполнение",
                    'en' => "#{$order->id} — please confirm completion",
                ],
                ['order_id' => $order->id],
            ),
            Order::STATUS_COMPLETED => NotificationService::orderCompleted($order),
            default => null,
        };

        return response()->json(['order' => $order->fresh()->load(['client', 'category'])]);
    }

    public function cancel(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();
        $request->validate(['reason' => 'nullable|string|max:500']);

        // Terminal statuses are non-cancellable — preserves history, payouts, reviews.
        $terminal = [
            Order::STATUS_COMPLETED, Order::STATUS_CLOSED,
            Order::STATUS_CANCELED_CLIENT, Order::STATUS_CANCELED_MASTER,
            Order::STATUS_CANCELED_SYSTEM,
        ];
        if (in_array($order->status, $terminal, true)) {
            return response()->json(['message' => 'Bu sifariş artıq bağlanıb.'], 422);
        }

        // Announcements in searching_master can only be canceled by the client
        // (or admin). Masters with a pending application cannot kill the ad.
        if ($order->status === Order::STATUS_SEARCHING
            && $user->id !== $order->client_id
            && !$user->isAdmin()
        ) {
            return response()->json(['message' => 'Yalnız müştəri elanı ləğv edə bilər.'], 403);
        }

        if ($user->id === $order->client_id) {
            $status = Order::STATUS_CANCELED_CLIENT;
        } elseif ($user->id === $order->master_id) {
            $status = Order::STATUS_CANCELED_MASTER;
        } elseif ($user->isAdmin()) {
            $status = Order::STATUS_CANCELED_SYSTEM;
        } else {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $order->update([
            'status' => $status,
            'cancel_reason' => $request->reason,
            'canceled_at' => now(),
        ]);

        $order->logStatus($status, $user->id, null, null, $request->reason);

        $canceledBy = $user->id === $order->client_id ? 'client' : 'master';
        NotificationService::orderCanceled($order, $canceledBy);

        // Money refund policy on cancellation:
        //   client-cancel (canceled_by_client) → callout fee NOT refunded
        //   master-cancel (canceled_by_master, including system-attributed) →
        //     client gets full refund + master penalty (configurable)
        if ($status === Order::STATUS_CANCELED_MASTER) {
            try {
                app(\App\Services\CalloutFeeService::class)
                    ->refundOnMasterCancel($order, $user->id);
            } catch (\Throwable $e) {
                report($e); // ledger refund failure should never block status flip
            }
        }

        return response()->json(['order' => $order]);
    }
}
