<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'broadcasting/auth'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => array_filter([
        env('FRONTEND_URL', 'https://itez.app'),
        'http://localhost:3000',
        'http://localhost:8093',
        'http://localhost:8095',  // Flutter web preview
    ]),
    // Allow any host on port 8095 so the preview works whether you open it by
    // localhost, server IP, or hostname.
    'allowed_origins_patterns' => ['#^https?://[^/]+:8095$#'],
    'allowed_headers' => [
        'Accept',
        'Accept-Language',
        'Authorization',
        'Content-Type',
        'X-Requested-With',
        'X-CSRF-TOKEN',
        'X-XSRF-TOKEN',
    ],
    'exposed_headers' => [],
    'max_age' => 3600,
    'supports_credentials' => true,
];
