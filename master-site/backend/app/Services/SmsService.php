<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * SMS sender + OTP store. Driver chosen by SMS_PROVIDER env:
 *   - "log"    → write to laravel.log only (dev / staging default)
 *   - "twilio" → real send via Twilio REST API
 *
 * OTPs are stored in cache (Redis) with TTL — no DB churn.
 */
class SmsService
{
    private const OTP_TTL_SECONDS = 600;   // 10 min
    private const OTP_RESEND_COOLDOWN = 60; // 1 min between sends per phone

    public static function sendOtp(string $phone): array
    {
        $phone = self::normalize($phone);

        $cooldownKey = "sms:cooldown:{$phone}";
        if (Cache::has($cooldownKey)) {
            return ['ok' => false, 'reason' => 'cooldown', 'retry_after' => self::OTP_RESEND_COOLDOWN];
        }

        $code = (string) random_int(100000, 999999);
        Cache::put("sms:otp:{$phone}", hash('sha256', $code), self::OTP_TTL_SECONDS);
        Cache::put($cooldownKey, 1, self::OTP_RESEND_COOLDOWN);

        $msg = "Master.az kodunuz: {$code}";
        self::send($phone, $msg);

        return ['ok' => true, 'expires_in' => self::OTP_TTL_SECONDS];
    }

    public static function verifyOtp(string $phone, string $code): bool
    {
        $phone = self::normalize($phone);
        $stored = Cache::get("sms:otp:{$phone}");
        if (!$stored) return false;
        $ok = hash_equals($stored, hash('sha256', $code));
        if ($ok) Cache::forget("sms:otp:{$phone}");
        return $ok;
    }

    public static function send(string $phone, string $message): void
    {
        $provider = config('services.sms.provider', env('SMS_PROVIDER', 'log'));

        try {
            switch ($provider) {
                case 'twilio':
                    self::sendTwilio($phone, $message);
                    break;
                case 'log':
                default:
                    Log::info('sms.send', ['phone' => $phone, 'message' => $message]);
            }
        } catch (\Throwable $e) {
            Log::error('sms.failed', ['phone' => $phone, 'error' => $e->getMessage()]);
        }
    }

    private static function sendTwilio(string $phone, string $message): void
    {
        $sid = env('SMS_TWILIO_SID');
        $token = env('SMS_TWILIO_TOKEN');
        $from = env('SMS_TWILIO_FROM');
        if (!$sid || !$token || !$from) {
            throw new \RuntimeException('Twilio credentials missing');
        }
        Http::withBasicAuth($sid, $token)
            ->asForm()
            ->timeout(10)
            ->post("https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json", [
                'From' => $from,
                'To' => $phone,
                'Body' => $message,
            ])
            ->throw();
    }

    private static function normalize(string $phone): string
    {
        $p = preg_replace('/[^0-9+]/', '', $phone);
        if (!str_starts_with($p, '+')) $p = '+' . $p;
        return $p;
    }
}
