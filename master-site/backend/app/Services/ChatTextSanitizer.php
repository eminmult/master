<?php

namespace App\Services;

/**
 * Strip / mask off-platform contact attempts in chat:
 *   - phone numbers (8+ consecutive digits, with optional separators)
 *   - email addresses
 *   - common alt-platform handles (Telegram @username, WhatsApp, etc.)
 *
 * Returns ['clean' => string, 'flagged' => bool, 'reasons' => array].
 *
 * Pre-acceptance only: once the order is `confirmed`, both parties already
 * have each other's phone via Order.contact_phone, so masking is moot.
 */
class ChatTextSanitizer
{
    public static function sanitize(?string $text, bool $applyMask = true): array
    {
        if ($text === null || $text === '') {
            return ['clean' => $text, 'flagged' => false, 'reasons' => []];
        }

        $reasons = [];
        $clean = $text;

        // Phone — 8+ consecutive digits possibly broken by spaces/dashes/dots
        if (preg_match('/(?:\+?\d[\s\-\.\(\)]?){8,}/u', $text)) {
            $reasons[] = 'phone';
            if ($applyMask) {
                $clean = preg_replace('/(?:\+?\d[\s\-\.\(\)]?){8,}/u', '[•••]', $clean);
            }
        }

        // Email
        if (preg_match('/[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/', $text)) {
            $reasons[] = 'email';
            if ($applyMask) {
                $clean = preg_replace('/[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/', '[•••]', $clean);
            }
        }

        // Telegram / WhatsApp handles
        if (preg_match('/(?:t\.me\/|telegram|whatsapp|wa\.me|@[a-z0-9_]{4,32})/iu', $text)) {
            $reasons[] = 'handle';
            if ($applyMask) {
                $clean = preg_replace('/(?:t\.me\/[a-z0-9_]+|wa\.me\/[0-9]+|@[a-z0-9_]{4,32})/iu', '[•••]', $clean);
            }
        }

        return [
            'clean' => $clean,
            'flagged' => !empty($reasons),
            'reasons' => $reasons,
        ];
    }
}
