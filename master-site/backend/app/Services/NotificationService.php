<?php

namespace App\Services;

use App\Mail\NotificationMail;
use App\Models\Notification;
use App\Models\Order;
use App\Models\User;
use App\Services\PushService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class NotificationService
{
    // ===== ORDER LIFECYCLE =====

    public static function orderCreated(Order $order): void
    {
        self::create($order->client_id, 'order_created', [
            'az' => 'Sifarişiniz yaradıldı',
            'ru' => 'Заказ создан',
            'en' => 'Order created',
        ], [
            'az' => "#{$order->id} — usta axtarılır",
            'ru' => "#{$order->id} — ищем мастера",
            'en' => "#{$order->id} — searching for master",
        ], ['order_id' => $order->id]);
    }

    public static function orderAccepted(Order $order): void
    {
        $masterName = $order->master?->first_name ?? 'Usta';

        // To client
        self::create($order->client_id, 'order_accepted', [
            'az' => 'Usta tapıldı!',
            'ru' => 'Мастер найден!',
            'en' => 'Master found!',
        ], [
            'az' => "{$masterName} sifarişinizi qəbul etdi",
            'ru' => "{$masterName} принял ваш заказ",
            'en' => "{$masterName} accepted your order",
        ], ['order_id' => $order->id, 'master_id' => $order->master_id]);

        // To master
        self::create($order->master_id, 'order_assigned', [
            'az' => 'Yeni sifariş qəbul edildi',
            'ru' => 'Новый заказ принят',
            'en' => 'New order accepted',
        ], [
            'az' => "#{$order->id} — {$order->category?->name}",
            'ru' => "#{$order->id} — {$order->category?->name}",
            'en' => "#{$order->id} — {$order->category?->name}",
        ], ['order_id' => $order->id]);
    }

    public static function masterOnTheWay(Order $order): void
    {
        self::create($order->client_id, 'master_on_the_way', [
            'az' => 'Usta yola çıxdı',
            'ru' => 'Мастер выехал',
            'en' => 'Master is on the way',
        ], [
            'az' => "#{$order->id} — usta sizə tərəf gəlir",
            'ru' => "#{$order->id} — мастер едет к вам",
            'en' => "#{$order->id} — master is heading to you",
        ], ['order_id' => $order->id]);
    }

    public static function masterArrived(Order $order): void
    {
        self::create($order->client_id, 'master_arrived', [
            'az' => 'Usta gəldi',
            'ru' => 'Мастер прибыл',
            'en' => 'Master arrived',
        ], [
            'az' => "#{$order->id} — usta ünvana çatdı",
            'ru' => "#{$order->id} — мастер на месте",
            'en' => "#{$order->id} — master is at the location",
        ], ['order_id' => $order->id]);
    }

    public static function workStarted(Order $order): void
    {
        self::create($order->client_id, 'work_started', [
            'az' => 'İş başladı',
            'ru' => 'Работа начата',
            'en' => 'Work started',
        ], [
            'az' => "#{$order->id} — usta işə başladı",
            'ru' => "#{$order->id} — мастер начал работу",
            'en' => "#{$order->id} — master started working",
        ], ['order_id' => $order->id]);
    }

    public static function orderCompleted(Order $order): void
    {
        // To client
        self::create($order->client_id, 'order_completed', [
            'az' => 'Sifariş tamamlandı',
            'ru' => 'Заказ завершен',
            'en' => 'Order completed',
        ], [
            'az' => "#{$order->id} — rəy yazmağı unutmayın!",
            'ru' => "#{$order->id} — не забудьте оставить отзыв!",
            'en' => "#{$order->id} — don't forget to leave a review!",
        ], ['order_id' => $order->id]);

        // To master
        self::create($order->master_id, 'order_completed', [
            'az' => 'Sifariş tamamlandı',
            'ru' => 'Заказ завершен',
            'en' => 'Order completed',
        ], [
            'az' => "#{$order->id} — rəy yazmağı unutmayın!",
            'ru' => "#{$order->id} — не забудьте оставить отзыв!",
            'en' => "#{$order->id} — don't forget to leave a review!",
        ], ['order_id' => $order->id]);
    }

    public static function orderCanceled(Order $order, string $canceledBy): void
    {
        $targetId = $canceledBy === 'client' ? $order->master_id : $order->client_id;
        if (!$targetId) return;

        $who = $canceledBy === 'client'
            ? ['az' => 'Müştəri', 'ru' => 'Клиент', 'en' => 'Client']
            : ['az' => 'Usta', 'ru' => 'Мастер', 'en' => 'Master'];

        self::create($targetId, 'order_canceled', [
            'az' => 'Sifariş ləğv edildi',
            'ru' => 'Заказ отменен',
            'en' => 'Order canceled',
        ], [
            'az' => "#{$order->id} — {$who['az']} tərəfindən ləğv edildi",
            'ru' => "#{$order->id} — отменен {$who['ru']}ом",
            'en' => "#{$order->id} — canceled by {$who['en']}",
        ], ['order_id' => $order->id]);
    }

    // ===== CHAT =====

    public static function newMessage(int $orderId, int $senderId, int $receiverId, string $senderName): void
    {
        self::create($receiverId, 'new_message', [
            'az' => 'Yeni mesaj',
            'ru' => 'Новое сообщение',
            'en' => 'New message',
        ], [
            'az' => "{$senderName} sizə mesaj göndərdi",
            'ru' => "{$senderName} отправил вам сообщение",
            'en' => "{$senderName} sent you a message",
        ], ['order_id' => $orderId, 'sender_id' => $senderId]);
    }

    // ===== REVIEW =====

    public static function newReview(int $revieweeId, string $reviewerName, int $rating, int $orderId): void
    {
        self::create($revieweeId, 'new_review', [
            'az' => 'Yeni rəy',
            'ru' => 'Новый отзыв',
            'en' => 'New review',
        ], [
            'az' => "{$reviewerName} sizə {$rating}★ verdi",
            'ru' => "{$reviewerName} поставил вам {$rating}★",
            'en' => "{$reviewerName} gave you {$rating}★",
        ], ['order_id' => $orderId, 'reviewee_id' => $revieweeId]);
    }

    // ===== NEW ORDER FOR MASTERS =====

    public static function newOrderAvailable(int $masterId, Order $order): void
    {
        self::newOrderAvailableBulk([$masterId], $order);
    }

    /**
     * Bulk variant — single INSERT instead of N inserts.
     * Also redacts the full_address (could be precise enough to identify the client's door)
     * and shows only a district hint for search-pool notifications.
     */
    public static function newOrderAvailableBulk(iterable $masterIds, Order $order): void
    {
        $ids = collect($masterIds)->filter()->unique()->values();
        if ($ids->isEmpty()) return;

        $district = $order->full_address ? trim(explode(',', $order->full_address)[0] ?? '') : '';
        $category = $order->category?->name ?? '';
        $body = $district ? "{$category} — {$district}" : $category;

        $titles = json_encode([
            'az' => 'Yeni sifariş!',
            'ru' => 'Новый заказ!',
            'en' => 'New order!',
        ], JSON_UNESCAPED_UNICODE);

        $bodies = json_encode([
            'az' => $body,
            'ru' => $body,
            'en' => $body,
        ], JSON_UNESCAPED_UNICODE);

        $data = json_encode(['order_id' => $order->id]);
        $now = now();

        $rows = $ids->map(fn($mid) => [
            'user_id' => (int) $mid,
            'type' => 'new_order_available',
            'title' => $titles,
            'body' => $bodies,
            'data' => $data,
            'is_read' => false,
            'created_at' => $now,
            'updated_at' => $now,
        ])->all();

        Notification::insert($rows);
    }

    // ===== CORE =====

    public static function send(
        ?int $userId,
        string $type,
        array $titles,
        array $bodies,
        array $data = []
    ): void {
        self::create($userId, $type, $titles, $bodies, $data);
    }

    private static function create(
        ?int $userId,
        string $type,
        array $titles,
        array $bodies,
        array $data = []
    ): void {
        if (!$userId) return;

        Notification::create([
            'user_id' => $userId,
            'type' => $type,
            'title' => json_encode($titles, JSON_UNESCAPED_UNICODE),
            'body' => json_encode($bodies, JSON_UNESCAPED_UNICODE),
            'data' => $data,
        ]);

        // High-signal events also go to email so offline users don't miss them.
        // Skip "new_message" — would spam during chat.
        if (in_array($type, self::EMAIL_EVENT_TYPES, true)) {
            self::queueEmail($userId, $type, $titles, $bodies, $data);
        }

        // Push to mobile devices for ALL types (chat included — that's the
        // main reason you install a mobile app).
        self::queuePush($userId, $type, $titles, $bodies, $data);
    }

    private static function queuePush(int $userId, string $type, array $titles, array $bodies, array $data): void
    {
        try {
            $user = User::select(['id', 'first_name'])->find($userId);
            if (!$user) return;

            // Pick locale: user's preferred locale would require an extra column.
            // For now use ru as default (highest user share), fall back to az/en.
            $title = $titles['ru'] ?? $titles['az'] ?? $titles['en'] ?? 'Master.az';
            $body = $bodies['ru'] ?? $bodies['az'] ?? $bodies['en'] ?? '';

            PushService::sendToUser($userId, $title, $body, [
                'type' => $type,
                ...$data,
            ]);
        } catch (\Throwable $e) {
            Log::warning('notification_push_failed', ['user_id' => $userId, 'type' => $type, 'error' => $e->getMessage()]);
        }
    }

    private const EMAIL_EVENT_TYPES = [
        'order_accepted',
        'order_assigned',
        'order_canceled',
        'order_completed',
        'proposal_received',
        'proposal_accepted',
        'application_accepted',
        'master_arrived',
        'new_review',
    ];

    private static function queueEmail(int $userId, string $type, array $titles, array $bodies, array $data): void
    {
        try {
            $user = User::select(['id', 'first_name', 'email', 'email_verified_at'])->find($userId);
            if (!$user || !$user->email || !$user->email_verified_at) return;

            $title = $titles['ru'] ?? $titles['az'] ?? $titles['en'] ?? 'Master.az';
            $body = $bodies['ru'] ?? $bodies['az'] ?? $bodies['en'] ?? '';

            $orderId = $data['order_id'] ?? null;
            $base = rtrim(env('FRONTEND_URL', 'https://itez.app'), '/');
            $url = $orderId ? "{$base}/order/{$orderId}" : "{$base}/notifications";

            Mail::to($user->email)->queue(
                new NotificationMail($title, $body, $user->first_name ?? '', $url, 'Открыть')
            );
        } catch (\Throwable $e) {
            Log::warning('notification_mail_failed', ['user_id' => $userId, 'type' => $type, 'error' => $e->getMessage()]);
        }
    }
}
