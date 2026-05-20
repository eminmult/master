<?php

namespace App\Models;

use App\Models\Concerns\HasAutoTranslation;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    use HasAutoTranslation;

    protected array $translatable = ['description', 'comment'];

    protected $fillable = [
        'client_id', 'master_id', 'category_id', 'subcategory_id',
        'address_id', 'description', 'full_address', 'lat', 'lng',
        'entrance', 'floor', 'intercom', 'contact_phone',
        'desired_time', 'scheduled_at', 'urgency', 'estimated_budget',
        'comment', 'status', 'cancel_reason', 'cancel_lat', 'cancel_lng',
        'client_reviewed', 'master_reviewed',
        'accepted_at', 'on_the_way_at', 'arrived_at',
        'started_at', 'completed_at', 'canceled_at', 'closed_at',
        'confirmed_at', 'agreed_date', 'agreed_price',
        'description_translations', 'comment_translations', 'content_locale',
    ];

    protected $hidden = [
        'description_translations', 'comment_translations',
    ];

    protected function casts(): array
    {
        return [
            'lat' => 'decimal:7',
            'lng' => 'decimal:7',
            'estimated_budget' => 'decimal:2',
            'client_reviewed' => 'boolean',
            'master_reviewed' => 'boolean',
            'scheduled_at' => 'datetime',
            'accepted_at' => 'datetime',
            'on_the_way_at' => 'datetime',
            'arrived_at' => 'datetime',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
            'canceled_at' => 'datetime',
            'confirmed_at' => 'datetime',
            'agreed_date' => 'datetime',
            'agreed_price' => 'decimal:2',
            'closed_at' => 'datetime',
            'description_translations' => 'array',
            'comment_translations' => 'array',
        ];
    }

    // Status constants
    const STATUS_DRAFT = 'draft';
    const STATUS_NEW = 'new';
    const STATUS_SEARCHING = 'searching_master';
    const STATUS_PENDING_MASTER = 'pending_master';
    const STATUS_DISCUSSION = 'discussion';
    const STATUS_PENDING_CLIENT = 'pending_client';
    /**
     * Master sent an arrival-time proposal, client accepted it, callout fee
     * payment is awaiting completion. Order is invisible from the public pool
     * (master is locked), but not yet committed. On payment success → confirmed.
     * On payment timeout (15 min) → back to pending_client so the client can retry.
     */
    const STATUS_PENDING_PAYMENT = 'pending_payment';
    const STATUS_CONFIRMED = 'confirmed';
    const STATUS_ACCEPTED = 'accepted';
    const STATUS_ON_THE_WAY = 'on_the_way';
    const STATUS_ARRIVED = 'arrived';
    const STATUS_IN_PROGRESS = 'in_progress';
    const STATUS_AWAITING_COMPLETION = 'awaiting_completion';
    const STATUS_COMPLETED = 'completed';
    const STATUS_AWAITING_REVIEW = 'awaiting_review';
    const STATUS_CANCELED_CLIENT = 'canceled_by_client';
    const STATUS_CANCELED_MASTER = 'canceled_by_master';
    const STATUS_CANCELED_SYSTEM = 'canceled_by_system';
    const STATUS_DISPUTED = 'disputed';
    const STATUS_CLOSED = 'closed';

    const ACTIVE_STATUSES = [
        self::STATUS_NEW,
        self::STATUS_SEARCHING,
        self::STATUS_PENDING_MASTER,
        self::STATUS_DISCUSSION,
        self::STATUS_PENDING_CLIENT,
        self::STATUS_PENDING_PAYMENT,
        self::STATUS_CONFIRMED,
        self::STATUS_ACCEPTED,
        self::STATUS_ON_THE_WAY,
        self::STATUS_ARRIVED,
        self::STATUS_IN_PROGRESS,
        self::STATUS_AWAITING_COMPLETION,
    ];

    const ALL_STATUSES = [
        self::STATUS_DRAFT,
        self::STATUS_NEW,
        self::STATUS_SEARCHING,
        self::STATUS_PENDING_MASTER,
        self::STATUS_DISCUSSION,
        self::STATUS_PENDING_CLIENT,
        self::STATUS_PENDING_PAYMENT,
        self::STATUS_CONFIRMED,
        self::STATUS_ACCEPTED,
        self::STATUS_ON_THE_WAY,
        self::STATUS_ARRIVED,
        self::STATUS_IN_PROGRESS,
        self::STATUS_AWAITING_COMPLETION,
        self::STATUS_COMPLETED,
        self::STATUS_AWAITING_REVIEW,
        self::STATUS_CANCELED_CLIENT,
        self::STATUS_CANCELED_MASTER,
        self::STATUS_CANCELED_SYSTEM,
        self::STATUS_DISPUTED,
        self::STATUS_CLOSED,
    ];

    const CHAT_STATUSES = [
        self::STATUS_DISCUSSION,
        self::STATUS_PENDING_CLIENT,
        self::STATUS_CONFIRMED,
        self::STATUS_ACCEPTED,
        self::STATUS_ON_THE_WAY,
        self::STATUS_ARRIVED,
        self::STATUS_IN_PROGRESS,
    ];

    const TRACKABLE_STATUSES = [
        self::STATUS_ACCEPTED,
        self::STATUS_ON_THE_WAY,
        self::STATUS_ARRIVED,
    ];

    // Relations
    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function master(): BelongsTo
    {
        return $this->belongsTo(User::class, 'master_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function subcategory(): BelongsTo
    {
        return $this->belongsTo(Subcategory::class);
    }

    public function address(): BelongsTo
    {
        return $this->belongsTo(Address::class);
    }

    public function statusHistory(): HasMany
    {
        return $this->hasMany(OrderStatusHistory::class)->orderBy('created_at');
    }

    public function photos(): HasMany
    {
        return $this->hasMany(OrderPhoto::class);
    }

    public function locations(): HasMany
    {
        return $this->hasMany(MasterLocation::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function chatMessages(): HasMany
    {
        return $this->hasMany(ChatMessage::class)->orderBy('created_at');
    }

    public function disputes(): HasMany
    {
        return $this->hasMany(Dispute::class);
    }

    public function applications(): HasMany
    {
        return $this->hasMany(OrderApplication::class);
    }

    // Helpers
    public function isActive(): bool
    {
        return in_array($this->status, self::ACTIVE_STATUSES);
    }

    public function isTrackable(): bool
    {
        return in_array($this->status, self::TRACKABLE_STATUSES);
    }

    public function isCanceled(): bool
    {
        return in_array($this->status, [
            self::STATUS_CANCELED_CLIENT,
            self::STATUS_CANCELED_MASTER,
            self::STATUS_CANCELED_SYSTEM,
        ]);
    }

    public function logStatus(string $status, ?int $changedBy = null, ?float $lat = null, ?float $lng = null, ?string $note = null): void
    {
        $this->statusHistory()->create([
            'status' => $status,
            'changed_by' => $changedBy,
            'lat' => $lat,
            'lng' => $lng,
            'note' => $note,
        ]);
    }
}
