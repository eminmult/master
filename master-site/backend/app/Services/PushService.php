<?php

namespace App\Services;

use App\Models\DeviceToken;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Mobile push notifications via Firebase Cloud Messaging HTTP v1.
 *
 * Driver chosen by FCM_SERVICE_ACCOUNT env:
 *   - empty / "log"   → write to laravel.log (dev / no creds yet)
 *   - <path-to-json>  → real FCM via service-account OAuth2
 *
 * Usage:
 *   PushService::sendToUser($userId, 'Title', 'Body', ['order_id' => 5]);
 *
 * The mobile client uses the data payload to deep-link (e.g. order_id → open
 * /order/{id} screen) and shows the title/body as system notification.
 */
class PushService
{
    /**
     * Send to all device tokens belonging to a user. Silently no-ops if the
     * user has no registered devices.
     */
    public static function sendToUser(int $userId, string $title, string $body, array $data = []): void
    {
        $tokens = DeviceToken::where('user_id', $userId)->pluck('token', 'id')->all();
        if (empty($tokens)) return;

        foreach ($tokens as $deviceId => $token) {
            self::send($token, $title, $body, $data, $deviceId);
        }
    }

    public static function send(string $token, string $title, string $body, array $data = [], ?int $deviceId = null): void
    {
        $serviceAccountPath = env('FCM_SERVICE_ACCOUNT');

        if (!$serviceAccountPath || !is_file($serviceAccountPath)) {
            Log::info('push.send.log', [
                'token' => substr($token, 0, 12) . '…',
                'title' => $title,
                'body' => $body,
                'data' => $data,
            ]);
            return;
        }

        try {
            self::sendFcm($serviceAccountPath, $token, $title, $body, $data, $deviceId);
        } catch (\Throwable $e) {
            Log::warning('push.send.failed', [
                'token' => substr($token, 0, 12) . '…',
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Real FCM HTTP v1 send. Stringifies all data values per FCM contract.
     */
    private static function sendFcm(string $saPath, string $token, string $title, string $body, array $data, ?int $deviceId): void
    {
        $sa = json_decode(file_get_contents($saPath), true);
        if (!$sa || empty($sa['project_id']) || empty($sa['client_email']) || empty($sa['private_key'])) {
            throw new \RuntimeException('Invalid FCM service account JSON');
        }

        $accessToken = self::getAccessToken($sa);

        // FCM requires data values to be strings.
        $stringData = [];
        foreach ($data as $k => $v) $stringData[(string) $k] = (string) $v;

        $payload = [
            'message' => [
                'token' => $token,
                'notification' => ['title' => $title, 'body' => $body],
                'data' => $stringData,
                'android' => [
                    'priority' => 'high',
                    'notification' => ['sound' => 'default', 'channel_id' => 'default'],
                ],
                'apns' => [
                    'payload' => [
                        'aps' => ['sound' => 'default', 'badge' => 1, 'mutable-content' => 1],
                    ],
                ],
            ],
        ];

        $url = "https://fcm.googleapis.com/v1/projects/{$sa['project_id']}/messages:send";
        $resp = Http::withToken($accessToken)
            ->timeout(10)
            ->post($url, $payload);

        // Token invalid (uninstalled / regenerated) → drop it so we don't keep retrying.
        if (in_array($resp->status(), [400, 404]) && $deviceId) {
            $err = $resp->json('error.details.0.errorCode') ?? '';
            if (in_array($err, ['UNREGISTERED', 'INVALID_ARGUMENT'])) {
                DeviceToken::where('id', $deviceId)->delete();
                Log::info('push.token.dropped', ['device_id' => $deviceId, 'reason' => $err]);
                return;
            }
        }

        $resp->throw();
    }

    /**
     * Mint an OAuth2 access token from the service account private key.
     * Cached for 50 minutes (FCM tokens last 60 min).
     */
    private static function getAccessToken(array $sa): string
    {
        $cacheKey = 'fcm:token:' . md5($sa['client_email']);

        return Cache::remember($cacheKey, 3000, function () use ($sa) {
            $now = time();
            $header = self::b64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = self::b64url(json_encode([
                'iss' => $sa['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ]));

            $signingInput = "{$header}.{$claims}";
            $signature = '';
            if (!openssl_sign($signingInput, $signature, $sa['private_key'], OPENSSL_ALGO_SHA256)) {
                throw new \RuntimeException('Failed to sign JWT for FCM');
            }

            $jwt = "{$signingInput}." . self::b64url($signature);

            $resp = Http::asForm()->timeout(10)->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ])->throw()->json();

            return $resp['access_token'];
        });
    }

    private static function b64url(string $s): string
    {
        return rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
    }
}
