<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\EmailVerification;
use App\Mail\PasswordReset;
use App\Models\MasterProfile;
use App\Models\User;
use App\Services\SmsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function registerClient(Request $request): JsonResponse
    {
        $data = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'nullable|string|max:100',
            'phone' => ['required', 'string', 'max:20', 'unique:users,phone', 'regex:/^\+?[0-9]{10,15}$/'],
            'email' => 'nullable|email|unique:users,email',
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ]);

        $user = User::create([
            ...$data,
            'role' => 'client',
            'password' => Hash::make($data['password']),
        ]);

        if ($user->email) $this->sendVerifyEmail($user);
        SmsService::sendOtp($user->phone);

        $token = $user->createToken('auth')->plainTextToken;

        return response()->json([
            'user' => $this->userResponse($user),
            'token' => $token,
        ], 201);
    }

    public function registerMaster(Request $request): JsonResponse
    {
        $data = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'phone' => ['required', 'string', 'max:20', 'unique:users,phone', 'regex:/^\+?[0-9]{10,15}$/'],
            'email' => 'required|email|unique:users,email',
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
            'city' => 'required|string|max:100',
            'district' => 'nullable|string|max:100',
            'description' => 'required|string|max:1000',
            'experience_years' => 'required|integer|min:0|max:50',
            'category_ids' => 'required|array|min:1',
            'category_ids.*' => 'exists:categories,id',
        ]);

        $user = User::create([
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'phone' => $data['phone'],
            'email' => $data['email'],
            'role' => 'master',
            'password' => Hash::make($data['password']),
        ]);

        $profile = MasterProfile::create([
            'user_id' => $user->id,
            'description' => $data['description'],
            'experience_years' => $data['experience_years'],
            'city' => $data['city'],
            'district' => $data['district'] ?? null,
        ]);

        foreach ($data['category_ids'] as $categoryId) {
            $profile->masterCategories()->create(['category_id' => $categoryId]);
        }

        $this->sendVerifyEmail($user);
        SmsService::sendOtp($user->phone);

        $token = $user->createToken('auth')->plainTextToken;

        return response()->json([
            'user' => $this->userResponse($user->load('masterProfile')),
            'token' => $token,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'login' => 'required|string',
            'password' => 'required|string',
        ]);

        $login = $request->login;
        $user = User::where('email', $login)
            ->orWhere('phone', $login)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['Yanlış giriş məlumatları.'],
            ]);
        }

        if (!$user->is_active) {
            throw ValidationException::withMessages([
                'login' => ['Hesabınız deaktiv edilib.'],
            ]);
        }

        $token = $user->createToken('auth')->plainTextToken;

        $user->load($user->isMaster() ? ['masterProfile'] : []);

        return response()->json([
            'user' => $this->userResponse($user),
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Çıxış edildi.']);
    }

    /**
     * Rotate the current access token. Mobile clients call this periodically
     * (e.g. every 7 days, well before the 30-day expiry) so the user never
     * gets logged out involuntarily. Old token is revoked atomically.
     *
     * Reason for rotation rather than long-lived tokens: a stolen token has
     * a tighter window of usefulness, and we can revoke a leaked device fleet
     * by deleting all tokens from a given created_at timestamp.
     */
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        $oldToken = $user->currentAccessToken();
        $oldName = $oldToken->name ?? 'auth';
        $oldToken->delete();

        $newToken = $user->createToken($oldName)->plainTextToken;

        return response()->json([
            'token' => $newToken,
            'expires_at' => now()->addMinutes(config('sanctum.expiration', 60 * 24 * 30))->toIso8601String(),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->load($user->isMaster() ? ['masterProfile.masterCategories.category'] : ['addresses']);

        return response()->json(['user' => $this->userResponse($user)]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate([
            'login' => 'required|string|max:100', // email or phone
        ]);

        $login = $request->login;
        $user = User::where('email', $login)->orWhere('phone', $login)->first();

        // Always respond 200 — do not leak whether an account exists.
        if (!$user) {
            return response()->json(['message' => 'If an account exists, a reset link has been sent.']);
        }

        // Generate token, keep only the hash on the server — the plain token goes out in the email.
        $plain = Str::random(64);
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email ?: $user->phone],
            [
                'email' => $user->email ?: $user->phone,
                'token' => Hash::make($plain),
                'created_at' => now(),
            ]
        );

        if ($user->email) {
            try {
                $resetUrl = rtrim(env('FRONTEND_URL', 'https://itez.app'), '/')
                    . '/reset-password?token=' . urlencode($plain)
                    . '&login=' . urlencode($user->email);
                Mail::to($user->email)->queue(new PasswordReset($user->first_name, $resetUrl));
            } catch (\Throwable $e) {
                Log::warning('password_reset_mail_failed', ['user_id' => $user->id, 'error' => $e->getMessage()]);
            }
        } else {
            // Phone-only account — send the token via SMS
            SmsService::send($user->phone, "Master.az şifrə bərpa kodu: {$plain}");
        }

        return response()->json(['message' => 'If an account exists, a reset link has been sent.']);
    }

    /**
     * Verify email — token came from EmailVerification Mailable. 24h TTL.
     */
    public function verifyEmail(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => 'required|string',
            'user_id' => 'required|integer',
        ]);

        $stored = Cache::get("email_verify:{$data['user_id']}");
        if (!$stored || !hash_equals($stored, hash('sha256', $data['token']))) {
            throw ValidationException::withMessages(['token' => ['Invalid or expired verification token.']]);
        }

        $user = User::findOrFail($data['user_id']);
        $user->update(['email_verified_at' => now()]);
        Cache::forget("email_verify:{$user->id}");

        return response()->json(['message' => 'Email verified.', 'user' => $this->userResponse($user)]);
    }

    public function resendEmailVerification(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->email) return response()->json(['message' => 'No email on account'], 422);
        if ($user->email_verified_at) return response()->json(['message' => 'Already verified']);

        $cooldown = "email_verify:cooldown:{$user->id}";
        if (Cache::has($cooldown)) return response()->json(['message' => 'Please wait before resending'], 429);
        Cache::put($cooldown, 1, 60);

        $this->sendVerifyEmail($user);
        return response()->json(['message' => 'Verification email sent.']);
    }

    public function requestPhoneOtp(Request $request): JsonResponse
    {
        $user = $request->user();
        $result = SmsService::sendOtp($user->phone);
        if (!$result['ok']) return response()->json($result, 429);
        return response()->json(['ok' => true, 'expires_in' => $result['expires_in']]);
    }

    public function verifyPhoneOtp(Request $request): JsonResponse
    {
        $data = $request->validate(['code' => 'required|string|size:6']);
        $user = $request->user();
        if (!SmsService::verifyOtp($user->phone, $data['code'])) {
            throw ValidationException::withMessages(['code' => ['Invalid or expired code.']]);
        }
        $user->update(['phone_verified_at' => now()]);
        return response()->json(['message' => 'Phone verified.', 'user' => $this->userResponse($user)]);
    }

    private function sendVerifyEmail(User $user): void
    {
        if (!$user->email) return;
        $plain = Str::random(64);
        Cache::put("email_verify:{$user->id}", hash('sha256', $plain), 86400);
        try {
            $verifyUrl = rtrim(env('FRONTEND_URL', 'https://itez.app'), '/')
                . '/verify-email?token=' . urlencode($plain)
                . '&user_id=' . $user->id;
            Mail::to($user->email)->queue(new EmailVerification($user->first_name, $verifyUrl));
        } catch (\Throwable $e) {
            Log::warning('email_verify_mail_failed', ['user_id' => $user->id, 'error' => $e->getMessage()]);
        }
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'login' => 'required|string|max:100',
            'token' => 'required|string',
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ]);

        $user = User::where('email', $data['login'])->orWhere('phone', $data['login'])->first();
        if (!$user) {
            throw ValidationException::withMessages(['token' => ['Invalid or expired reset token.']]);
        }

        $key = $user->email ?: $user->phone;
        $row = DB::table('password_reset_tokens')->where('email', $key)->first();
        if (!$row || !Hash::check($data['token'], $row->token)) {
            throw ValidationException::withMessages(['token' => ['Invalid or expired reset token.']]);
        }

        // 1-hour validity window
        if (strtotime($row->created_at) < time() - 3600) {
            DB::table('password_reset_tokens')->where('email', $key)->delete();
            throw ValidationException::withMessages(['token' => ['Reset token has expired.']]);
        }

        $user->update(['password' => Hash::make($data['password'])]);
        DB::table('password_reset_tokens')->where('email', $key)->delete();

        // Revoke existing sessions so stolen tokens can't outlive the password.
        $user->tokens()->delete();

        return response()->json(['message' => 'Password has been reset.']);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => 'required|string',
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ]);

        $user = $request->user();
        if (!Hash::check($data['current_password'], $user->password)) {
            throw ValidationException::withMessages(['current_password' => [trans('auth.current_password_incorrect')]]);
        }

        $user->update(['password' => Hash::make($data['password'])]);

        // Revoke other sessions; keep the current token
        $currentTokenId = $user->currentAccessToken()->id;
        $user->tokens()->where('id', '!=', $currentTokenId)->delete();

        return response()->json(['message' => trans('auth.password_updated')]);
    }

    private function userResponse(User $user): array
    {
        $data = [
            'id' => $user->id,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'full_name' => $user->full_name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'avatar_url' => $user->avatar_url,
            'locale' => $user->locale,
            'rating_avg' => $user->rating_avg,
            'rating_count' => $user->rating_count,
            'is_active' => $user->is_active,
            'is_verified' => (bool) $user->is_verified,
            'verified_at' => $user->verified_at?->toIso8601String(),
            'email_verified_at' => $user->email_verified_at,
            'phone_verified_at' => $user->phone_verified_at,
            'created_at' => $user->created_at,
        ];

        if ($user->isMaster()) {
            $data['subscription'] = [
                'active' => (bool) $user->subscription_active,
                'expires_at' => $user->subscription_expires_at?->toIso8601String(),
                'required' => (bool) config('master.subscription_required', false),
                'free_launch_until' => config('master.free_launch_until'),
                'can_operate' => $user->canOperateAsMaster(),
            ];

            if ($user->relationLoaded('masterProfile') && $user->masterProfile) {
                $data['master_profile'] = $user->masterProfile;
            }
        }

        if ($user->relationLoaded('addresses')) {
            $data['addresses'] = $user->addresses;
        }

        return $data;
    }
}
