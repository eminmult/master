<?php

namespace App\Models;

use App\Models\Concerns\HasAutoTranslation;
use App\Services\ChatTextSanitizer;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatMessage extends Model
{
    use HasAutoTranslation;

    protected array $translatable = ['text'];

    protected $fillable = [
        'order_id', 'application_id', 'sender_id', 'text', 'read_at',
        'text_translations', 'content_locale',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $msg) {
            // Skip structured/system messages (proposal bubbles).
            $text = (string) $msg->text;
            if ($text === '' || str_starts_with(trim($text), '{')) return;

            $result = ChatTextSanitizer::sanitize($text);
            if ($result['flagged']) {
                $msg->text = $result['clean'];
            }
        });
    }

    protected $hidden = ['text_translations'];

    protected function casts(): array
    {
        return [
            'read_at' => 'datetime',
            'text_translations' => 'array',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function application(): BelongsTo
    {
        return $this->belongsTo(OrderApplication::class, 'application_id');
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
