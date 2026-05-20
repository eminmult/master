<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use App\Models\Order;
use App\Models\OrderApplication;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderApplicationController extends Controller
{
    /**
     * Master applies to an open announcement.
     * Creates an application. Does NOT close the announcement — multiple masters can apply.
     */
    public function apply(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMaster()) {
            return response()->json(['message' => 'Yalnız ustalar müraciət edə bilər.'], 403);
        }

        if ($order->status !== Order::STATUS_SEARCHING) {
            return response()->json(['message' => 'Bu elan üçün müraciət qəbul edilmir.'], 422);
        }

        $data = $request->validate([
            'message' => 'nullable|string|max:1000',
            'proposed_price' => 'nullable|numeric|min:0|max:999999',
        ]);

        // Per-user daily cap — prevents spamming applications platform-wide
        $today = OrderApplication::where('master_id', $user->id)
            ->whereDate('created_at', today())->count();
        if ($today >= 50) {
            return response()->json(['message' => 'Günlük müraciət limiti aşıldı (50).'], 429);
        }

        // Dedupe: re-activate a withdrawn application, block pending/discussing duplicates.
        $existing = OrderApplication::where('order_id', $order->id)
            ->where('master_id', $user->id)
            ->first();

        if ($existing) {
            if ($existing->status === OrderApplication::STATUS_WITHDRAWN) {
                $existing->update([
                    'status' => OrderApplication::STATUS_PENDING,
                    'message' => $data['message'] ?? null,
                    'proposed_price' => $data['proposed_price'] ?? null,
                    'proposed_date' => null,
                    'responded_at' => null,
                ]);
                self::notifyClientNewApplication($order);
                return response()->json(['application' => $existing->fresh()]);
            }
            return response()->json(['message' => 'Siz artıq müraciət etmisiniz.', 'application' => $existing], 409);
        }

        $application = OrderApplication::create([
            'order_id' => $order->id,
            'master_id' => $user->id,
            'status' => OrderApplication::STATUS_PENDING,
            'message' => $data['message'] ?? null,
            'proposed_price' => $data['proposed_price'] ?? null,
        ]);

        self::notifyClientNewApplication($order);

        return response()->json(['application' => $application], 201);
    }

    /**
     * Master withdraws their own application.
     * Announcement stays open. Status transitions: pending|discussing|proposed → withdrawn.
     */
    public function withdraw(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();

        if ($application->master_id !== $user->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        if (!in_array($application->status, [
            OrderApplication::STATUS_PENDING,
            OrderApplication::STATUS_DISCUSSING,
            OrderApplication::STATUS_PROPOSED,
        ], true)) {
            return response()->json(['message' => 'Bu müraciəti geri götürə bilməzsiniz.'], 422);
        }

        $application->update([
            'status' => OrderApplication::STATUS_WITHDRAWN,
            'responded_at' => now(),
        ]);

        // Notify client a master pulled back
        NotificationService::send(
            $application->order->client_id,
            'application_withdrawn',
            [
                'az' => 'Usta müraciətini geri götürdü',
                'ru' => 'Мастер отозвал свою заявку',
                'en' => 'A master withdrew their application',
                'tr' => 'Usta başvurusunu geri çekti',
                'ar' => 'سحب أحد المحترفين طلبه',
            ],
            [
                'az' => "#{$application->order_id} — başqa ustalar da seçə bilərsiniz.",
                'ru' => "#{$application->order_id} — вы можете выбрать другого мастера.",
                'en' => "#{$application->order_id} — you can still pick another master.",
                'tr' => "#{$application->order_id} — başka bir usta seçebilirsiniz.",
                'ar' => "#{$application->order_id} — يمكنك اختيار محترف آخر.",
            ],
            ['order_id' => $application->order_id],
        );

        return response()->json(['application' => $application]);
    }

    /**
     * Master sees their own applications. Paginated 20 per page.
     */
    public function mine(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMaster()) {
            return response()->json(['applications' => [], 'pagination' => ['total' => 0, 'has_more' => false]]);
        }

        $status = $request->query('status');
        $page = max(1, (int) $request->query('page', 1));
        $perPage = min(50, max(1, (int) $request->query('per_page', 20)));

        $q = OrderApplication::with([
            'order:id,category_id,description,full_address,urgency,estimated_budget,status,created_at,scheduled_at,desired_time',
            'order.category:id,name,icon_url',
            'order.client:id,first_name,avatar_url',
            // Photos — surfaced in the chat drawer so the master sees what the
            // job looks like without having to navigate back to the listing.
            'order.photos:id,order_id,url',
        ])->where('master_id', $user->id);

        if ($status) $q->where('status', $status);

        $total = (clone $q)->count();
        $applications = $q->orderByDesc('created_at')->forPage($page, $perPage)->get();

        // Inject the address-derived district (first comma-separated chunk) so
        // the frontend can show location context without leaking the full
        // street address before the master is hired.
        $applications->each(function ($app) {
            if ($app->order) {
                $district = trim(explode(',', (string) $app->order->full_address)[0] ?? '');
                $app->order->setAttribute('district', $district);
            }
        });

        return response()->json([
            'applications' => $applications,
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'has_more' => ($page * $perPage) < $total,
            ],
        ]);
    }

    /**
     * Client lists applications for their own order.
     */
    public function index(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if ($order->client_id !== $user->id && !$user->isAdmin()) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $applications = OrderApplication::with([
            'master:id,first_name,last_name,avatar_url,rating_avg,rating_count,is_verified',
            'master.masterProfile:id,user_id,description,status,experience_years,completed_orders_count,is_verified',
            // Categories drive the inbox card's "specialty" line — clients
            // pick a master partly on what they're known for.
            'master.masterProfile.masterCategories.category:id,name,slug,icon_url',
        ])->where('order_id', $order->id)
          ->orderByDesc('created_at')
          ->get();

        // Inject computed full_name + flattened categories so the mobile
        // card doesn't have to rebuild the strings client-side.
        $payload = $applications->map(function ($a) {
            $arr = $a->toArray();
            if ($a->master) {
                $arr['master']['full_name'] = trim("{$a->master->first_name} {$a->master->last_name}");
                $cats = $a->master->masterProfile?->masterCategories
                    ?->map(fn($mc) => $mc->category ? ['id' => $mc->category->id, 'name' => $mc->category->name, 'slug' => $mc->category->slug] : null)
                    ?->filter()
                    ?->unique('id')
                    ?->values()
                    ?->all() ?? [];
                $arr['master']['categories'] = $cats;
            }
            return $arr;
        });

        return response()->json(['applications' => $payload]);
    }

    /**
     * Client starts a discussion with this specific master (opens chat).
     * Announcement stays open. Other applications remain untouched —
     * client can discuss with several masters in parallel.
     */
    public function startDiscussion(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();

        if ($application->order->client_id !== $user->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        if (!in_array($application->status, [
            OrderApplication::STATUS_PENDING,
            OrderApplication::STATUS_DISCUSSING,
        ], true)) {
            return response()->json(['message' => 'Bu müraciətlə müzakirə başlatmaq olmaz.'], 422);
        }

        if ($application->status === OrderApplication::STATUS_PENDING) {
            $application->update([
                'status' => OrderApplication::STATUS_DISCUSSING,
            ]);

            NotificationService::send(
                $application->master_id,
                'application_discussion_started',
                [
                    'az' => 'Müştəri sizinlə əlaqə saxladı',
                    'ru' => 'Клиент начал с вами обсуждение',
                    'en' => 'Client started a discussion with you',
                    'tr' => 'Müşteri sizinle görüşmeye başladı',
                    'ar' => 'بدأ العميل المناقشة معك',
                ],
                [
                    'az' => "#{$application->order_id} — detalları razılaşdırın və təklif göndərin.",
                    'ru' => "#{$application->order_id} — обсудите детали и отправьте предложение.",
                    'en' => "#{$application->order_id} — discuss details and send a proposal.",
                    'tr' => "#{$application->order_id} — detayları konuşun ve teklif gönderin.",
                    'ar' => "#{$application->order_id} — ناقش التفاصيل وأرسل عرضًا.",
                ],
                ['order_id' => $application->order_id, 'application_id' => $application->id],
            );
        }

        return response()->json(['application' => $application->fresh()]);
    }

    /**
     * Master sends a formal proposal (date + price) on an application.
     * Application moves to 'proposed', a structured chat message is emitted,
     * and the client is notified. Announcement still open.
     */
    public function propose(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();

        if ($application->master_id !== $user->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        if (!in_array($application->status, [
            OrderApplication::STATUS_DISCUSSING,
            OrderApplication::STATUS_PROPOSED,
            OrderApplication::STATUS_PENDING,
        ], true)) {
            return response()->json(['message' => 'Təklif göndərmək mümkün deyil.'], 422);
        }

        // Master proposes ONLY an arrival time. Price of the work itself stays
        // a free-text negotiation in the chat — the only platform-mediated
        // money is the fixed callout fee the client pays to confirm.
        $data = $request->validate([
            'proposed_date' => 'required|date|after:now',
        ]);

        $application->update([
            'status' => OrderApplication::STATUS_PROPOSED,
            'proposed_date' => $data['proposed_date'],
            'proposed_price' => null,
        ]);

        ChatMessage::create([
            'order_id' => $application->order_id,
            'application_id' => $application->id,
            'sender_id' => $user->id,
            'text' => json_encode([
                '_type' => 'proposal',
                'date' => date('d.m.Y H:i', strtotime($data['proposed_date'])),
            ], JSON_UNESCAPED_UNICODE),
        ]);

        $dateStr = date('d.m.Y H:i', strtotime($data['proposed_date']));
        NotificationService::send(
            $application->order->client_id,
            'application_proposal',
            [
                'az' => 'Usta gəliş vaxtı təklif etdi',
                'ru' => 'Мастер предложил время прибытия',
                'en' => 'Master proposed an arrival time',
                'tr' => 'Usta varış zamanı önerdi',
                'ar' => 'اقترح المحترف وقت الوصول',
            ],
            [
                'az' => "#{$application->order_id} — {$dateStr}. Çağırış ödənişi ilə təsdiqləyin.",
                'ru' => "#{$application->order_id} — {$dateStr}. Подтвердите, оплатив вызов.",
                'en' => "#{$application->order_id} — {$dateStr}. Confirm by paying the callout fee.",
                'tr' => "#{$application->order_id} — {$dateStr}. Çağrı ödemesi ile onaylayın.",
                'ar' => "#{$application->order_id} — {$dateStr}. أكد بدفع رسوم الاستدعاء.",
            ],
            ['order_id' => $application->order_id, 'application_id' => $application->id],
        );

        return response()->json(['application' => $application->fresh()]);
    }

    /**
     * Client accepts a master's proposal — THE FINAL STEP.
     * Locks in: order.master_id = that master, order.status = confirmed,
     * other applications auto-rejected, announcement closes.
     */
    public function acceptProposal(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();
        $order = $application->order;

        if ($order->client_id !== $user->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        // Accept ONLY works once the master has formally proposed price + date
        // — this is the moment the announcement clinches the deal. Until
        // then the announcement stays open in the public pool and other
        // masters can keep applying / discussing. Order.master_id is set
        // here, status flips to CONFIRMED, and the rest of the universal
        // order lifecycle takes over.
        if ($application->status !== OrderApplication::STATUS_PROPOSED) {
            return response()->json([
                'message' => 'Bu müraciətdə hələ qiymət və vaxt təklifi yoxdur. Ustadan təklif gözləyin.',
            ], 422);
        }

        if ($order->status !== Order::STATUS_SEARCHING) {
            return response()->json(['message' => 'Bu elan artıq aktiv deyil.'], 422);
        }

        $rejectedMasterIds = [];

        try {
            DB::transaction(function () use ($application, $order, $user, &$rejectedMasterIds) {
            $freshOrder = Order::where('id', $order->id)->lockForUpdate()->first();
            if (!$freshOrder || $freshOrder->status !== Order::STATUS_SEARCHING) {
                throw new \RuntimeException('Order no longer available');
            }

            // Lock the chosen master in and copy their proposed arrival time
            // onto the order. Status goes to PENDING_PAYMENT — the client must
            // pay the callout fee to push it to CONFIRMED. Announcement closes
            // here either way (the other applications are rejected below); if
            // the client never pays we'll roll back via the timeout job.
            $freshOrder->update([
                'master_id'   => $application->master_id,
                'status'      => Order::STATUS_PENDING_PAYMENT,
                'accepted_at' => now(),
                'agreed_date' => $application->proposed_date,
                'agreed_price'=> null,
            ]);
            $freshOrder->logStatus(Order::STATUS_PENDING_PAYMENT, $user->id);

            $application->update([
                'status' => OrderApplication::STATUS_ACCEPTED,
                'responded_at' => now(),
            ]);

            // Reject all other non-terminal applications
            $others = OrderApplication::where('order_id', $order->id)
                ->where('id', '!=', $application->id)
                ->whereIn('status', [
                    OrderApplication::STATUS_PENDING,
                    OrderApplication::STATUS_DISCUSSING,
                    OrderApplication::STATUS_PROPOSED,
                ])->get();

            foreach ($others as $other) {
                $other->update([
                    'status' => OrderApplication::STATUS_REJECTED,
                    'responded_at' => now(),
                ]);
                $rejectedMasterIds[] = $other->master_id;
            }

            // Emit a "confirmed" chat message in the chosen application's thread
            ChatMessage::create([
                'order_id' => $order->id,
                'application_id' => $application->id,
                'sender_id' => $user->id,
                'text' => json_encode(['_type' => 'confirmed'], JSON_UNESCAPED_UNICODE),
            ]);
            });
        } catch (\RuntimeException $e) {
            return response()->json(['message' => 'Bu elan artıq başqa ustaya təyin edilib.'], 422);
        }

        NotificationService::send(
            $application->master_id,
            'proposal_accepted',
            [
                'az' => 'Müştəri sizi seçdi!',
                'ru' => 'Клиент выбрал вас!',
                'en' => 'Client picked you!',
                'tr' => 'Müşteri sizi seçti!',
                'ar' => 'اختاركَ العميل!',
            ],
            [
                'az' => "#{$order->id} — sifariş çatında qiymət və vaxtı razılaşdırın.",
                'ru' => "#{$order->id} — согласуйте цену и время в чате заказа.",
                'en' => "#{$order->id} — agree on price and time in the order chat.",
                'tr' => "#{$order->id} — sipariş sohbetinde fiyat ve zamanı belirleyin.",
                'ar' => "#{$order->id} — اتفقا على السعر والوقت في محادثة الطلب.",
            ],
            ['order_id' => $order->id],
        );

        foreach ($rejectedMasterIds as $mid) {
            NotificationService::send(
                $mid,
                'application_rejected',
                [
                    'az' => 'Başqa usta seçildi',
                    'ru' => 'Клиент выбрал другого мастера',
                    'en' => 'Client chose another master',
                    'tr' => 'Müşteri başka usta seçti',
                    'ar' => 'اختار العميل محترفاً آخر',
                ],
                [
                    'az' => "#{$order->id} üçün müraciətiniz qəbul edilmədi.",
                    'ru' => "Ваша заявка на заказ #{$order->id} отклонена.",
                    'en' => "Your application for order #{$order->id} was not selected.",
                    'tr' => "#{$order->id} için başvurunuz seçilmedi.",
                    'ar' => "لم يتم اختيار طلبك للطلبية #{$order->id}.",
                ],
                ['order_id' => $order->id],
            );
        }

        return response()->json([
            'order' => $order->fresh()->load(['master', 'category']),
            'application' => $application->fresh(),
        ]);
    }

    /**
     * Client rejects a master's proposal — application goes back to discussing,
     * chat stays open so master can send another proposal.
     */
    public function rejectProposal(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();

        if ($application->order->client_id !== $user->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        if ($application->status !== OrderApplication::STATUS_PROPOSED) {
            return response()->json(['message' => 'Təklif yoxdur.'], 422);
        }

        $application->update([
            'status' => OrderApplication::STATUS_DISCUSSING,
            'proposed_date' => null,
            'proposed_price' => null,
        ]);

        ChatMessage::create([
            'order_id' => $application->order_id,
            'application_id' => $application->id,
            'sender_id' => $user->id,
            'text' => json_encode(['_type' => 'rejected'], JSON_UNESCAPED_UNICODE),
        ]);

        NotificationService::send(
            $application->master_id,
            'proposal_rejected',
            [
                'az' => 'Təklif rədd edildi',
                'ru' => 'Ваше предложение отклонено',
                'en' => 'Your proposal was rejected',
                'tr' => 'Teklifiniz reddedildi',
                'ar' => 'تم رفض عرضك',
            ],
            [
                'az' => "#{$application->order_id} — müştəri yeni şərtlər istəyir.",
                'ru' => "#{$application->order_id} — клиент хочет обсудить условия заново.",
                'en' => "#{$application->order_id} — client wants to discuss terms again.",
                'tr' => "#{$application->order_id} — müşteri şartları yeniden konuşmak istiyor.",
                'ar' => "#{$application->order_id} — يريد العميل إعادة نقاش الشروط.",
            ],
            ['order_id' => $application->order_id, 'application_id' => $application->id],
        );

        return response()->json(['application' => $application->fresh()]);
    }

    /**
     * Client rejects an entire application (before proposal stage).
     */
    public function reject(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();

        if ($application->order->client_id !== $user->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        if (!in_array($application->status, [
            OrderApplication::STATUS_PENDING,
            OrderApplication::STATUS_DISCUSSING,
            OrderApplication::STATUS_PROPOSED,
        ], true)) {
            return response()->json(['message' => 'Bu müraciətə cavab verilib.'], 422);
        }

        $application->update([
            'status' => OrderApplication::STATUS_REJECTED,
            'responded_at' => now(),
        ]);

        NotificationService::send(
            $application->master_id,
            'application_rejected',
            [
                'az' => 'Müraciətiniz rədd edildi',
                'ru' => 'Заявка отклонена',
                'en' => 'Application rejected',
                'tr' => 'Başvuru reddedildi',
                'ar' => 'تم رفض الطلب',
            ],
            [
                'az' => "#{$application->order_id} üçün müraciətiniz qəbul edilmədi.",
                'ru' => "Ваша заявка на заказ #{$application->order_id} отклонена клиентом.",
                'en' => "Your application for order #{$application->order_id} was rejected.",
                'tr' => "#{$application->order_id} için başvurunuz reddedildi.",
                'ar' => "تم رفض طلبك للطلبية #{$application->order_id}.",
            ],
            ['order_id' => $application->order_id],
        );

        return response()->json(['application' => $application->fresh()]);
    }

    /**
     * Messages in an application-scoped chat. Both client and master of this
     * application can read/send. Works while status ∈ CHAT_STATUSES.
     * Paginated (50 newest by default); pass ?before=<id> for older pages.
     */
    /**
     * Return a single application with parent order + counterparty so the
     * mobile chat page can display order context (category, address,
     * description, photos) without a second request. Both sides may read.
     */
    public function show(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();
        $allowed = $user->id === $application->master_id
            || $user->id === $application->order->client_id
            || $user->isAdmin();
        if (!$allowed) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $application->load([
            // full_name is a model accessor, not a column — exclude it from
            // the select list, the JSON serializer appends it for free.
            'master:id,first_name,last_name,avatar_url,rating_avg,rating_count,is_verified',
            'order.client:id,first_name,last_name,avatar_url,rating_avg,rating_count,is_verified',
            'order.category',
            'order.photos:id,order_id,url',
        ]);

        // Surface the district so the chat header can show location context
        // even while the precise address is masked for unhired masters.
        if ($application->order) {
            $district = trim(explode(',', (string) $application->order->full_address)[0] ?? '');
            $application->order->setAttribute('district', $district);
        }

        // Mask precise location for masters until acceptance — same rule as
        // OrderController::show. Once the client picks them, the order
        // becomes addressable via /orders/:id and full data is exposed.
        $order = $application->order;
        if ($user->id !== $order->client_id) {
            $order->lat = null;
            $order->lng = null;
            $order->entrance = null;
            $order->floor = null;
            $order->intercom = null;
            $order->contact_phone = null;
        }

        return response()->json(['application' => $application]);
    }

    public function messages(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();
        $allowed = $user->id === $application->master_id
            || $user->id === $application->order->client_id
            || $user->isAdmin();
        if (!$allowed) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $limit = min(100, max(1, (int) $request->query('limit', 50)));
        $before = (int) $request->query('before', 0);
        // `since` is the id of the last message the client already has —
        // when present and there's nothing newer the controller returns an
        // empty list early, keeping the 1s polling cycle cheap on idle chats.
        $since = (int) $request->query('since', 0);

        if ($since > 0) {
            $hasNew = ChatMessage::where('application_id', $application->id)
                ->where('id', '>', $since)
                ->exists();
            if (!$hasNew) {
                // Even on empty polls we still need to flip read_at so the
                // sender's "delivered" indicator stays accurate.
                ChatMessage::where('application_id', $application->id)
                    ->where('sender_id', '!=', $user->id)
                    ->whereNull('read_at')
                    ->update(['read_at' => now()]);
                return response()->json(['messages' => [], 'has_more' => false]);
            }
        }

        $q = ChatMessage::with('sender:id,first_name,last_name,avatar_url')
            ->where('application_id', $application->id);

        if ($before) $q->where('id', '<', $before);
        if ($since)  $q->where('id', '>', $since);

        $messages = $q->orderByDesc('id')->limit($limit)->get()->sortBy('id')->values();

        ChatMessage::where('application_id', $application->id)
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'messages' => $messages,
            'has_more' => $messages->count() === $limit,
        ]);
    }

    public function sendMessage(Request $request, OrderApplication $application): JsonResponse
    {
        $user = $request->user();
        $allowed = $user->id === $application->master_id
            || $user->id === $application->order->client_id;
        if (!$allowed) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        if (!$application->canChat()) {
            return response()->json(['message' => 'Bu mərhələdə yazışmaq mümkün deyil.'], 422);
        }

        // Pending = master applied, client hasn't engaged yet. Master must
        // wait for the client's first message (or the client hitting "Accept"
        // / "Discuss") before they can chime in. The client's first message
        // implicitly opens the discussion below.
        if ($application->status === OrderApplication::STATUS_PENDING
            && $user->id !== $application->order->client_id) {
            return response()->json([
                'message' => 'Müştəri müzakirəni başlatana qədər gözləyin.',
            ], 422);
        }

        $data = $request->validate([
            'text' => 'required|string|max:2000',
        ]);

        // Client sending = implicit start of discussion
        if ($user->id === $application->order->client_id && $application->status === OrderApplication::STATUS_PENDING) {
            $application->update(['status' => OrderApplication::STATUS_DISCUSSING]);
        }

        $msg = ChatMessage::create([
            'order_id' => $application->order_id,
            'application_id' => $application->id,
            'sender_id' => $user->id,
            'text' => $data['text'],
        ]);

        // Notify the other side
        $recipientId = $user->id === $application->master_id
            ? $application->order->client_id
            : $application->master_id;

        // Realtime push — Reverb (WebSocket) plus Redis pub/sub fan-out for
        // the SSE relay. SSE works through CF Flexible where WSS doesn't.
        event(new \App\Events\ChatMessageBroadcast(
            toUserId: $recipientId,
            scope: 'application',
            scopeId: $application->id,
            message: $msg,
        ));
        \Illuminate\Support\Facades\Redis::publish("realtime:user:{$recipientId}", json_encode([
            'type'     => 'chat.message',
            'scope'    => 'application',
            'scope_id' => $application->id,
            'message'  => $msg->load('sender:id,first_name,last_name,avatar_url')->toArray(),
        ], JSON_UNESCAPED_UNICODE));
        NotificationService::send(
            $recipientId,
            'new_message',
            [
                'az' => 'Yeni mesaj', 'ru' => 'Новое сообщение',
                'en' => 'New message', 'tr' => 'Yeni mesaj', 'ar' => 'رسالة جديدة',
            ],
            [
                'az' => "#{$application->order_id} — söhbətə baxın",
                'ru' => "#{$application->order_id} — откройте чат",
                'en' => "#{$application->order_id} — open the chat",
                'tr' => "#{$application->order_id} — sohbeti açın",
                'ar' => "#{$application->order_id} — افتح الدردشة",
            ],
            ['order_id' => $application->order_id, 'application_id' => $application->id],
        );

        return response()->json(['message' => $msg->load('sender:id,first_name,last_name,avatar_url')]);
    }

    private static function notifyClientNewApplication(Order $order): void
    {
        $count = OrderApplication::where('order_id', $order->id)
            ->where('status', OrderApplication::STATUS_PENDING)
            ->count();

        NotificationService::send(
            $order->client_id,
            'application_received',
            [
                'az' => 'Yeni müraciət!',
                'ru' => 'Новая заявка от мастера!',
                'en' => 'New application from a master!',
                'tr' => 'Yeni bir usta başvurdu!',
                'ar' => 'طلب جديد من محترف!',
            ],
            [
                'az' => "#{$order->id} — {$count} müraciət. İcraçı seçin.",
                'ru' => "#{$order->id} — {$count} заявок. Выберите исполнителя.",
                'en' => "#{$order->id} — {$count} applications. Pick a master.",
                'tr' => "#{$order->id} — {$count} başvuru. Usta seçin.",
                'ar' => "#{$order->id} — {$count} طلبات. اختر محترفًا.",
            ],
            ['order_id' => $order->id],
        );
    }
}
