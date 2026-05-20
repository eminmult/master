<?php

return [
    'stateful' => explode(',', env(
        'SANCTUM_STATEFUL_DOMAINS',
        'itez.app,localhost,localhost:3000,localhost:8093'
    )),

    'guard' => ['web'],

    'expiration' => 60 * 24 * 30, // 30 days in minutes

    'token_prefix' => env('SANCTUM_TOKEN_PREFIX', ''),

    'middleware' => [
        'authenticate_session' => Laravel\Sanctum\Http\Middleware\AuthenticateSession::class,
        'encrypt_cookies' => Illuminate\Cookie\Middleware\EncryptCookies::class,
        'validate_csrf_token' => Illuminate\Foundation\Http\Middleware\ValidateCsrfToken::class,
    ],
];
