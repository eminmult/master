<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withBroadcasting(
        __DIR__.'/../routes/channels.php',
        ['prefix' => 'api', 'middleware' => ['auth:sanctum']],
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => \App\Http\Middleware\CheckRole::class,
            'master.active' => \App\Http\Middleware\EnsureMasterActive::class,
        ]);

        // No web login route exists — API-only backend. Tell Authenticate
        // middleware to never redirect so the exception bubbles up to our
        // JSON 401 renderer below regardless of Accept header.
        $middleware->redirectGuestsTo(fn () => null);

        $middleware->statefulApi();

        $middleware->throttleWithRedis();
        $middleware->api(prepend: [
            \Illuminate\Routing\Middleware\ThrottleRequests::class.':60,1',
            \App\Http\Middleware\ForceJsonResponse::class,
            \App\Http\Middleware\SetLocaleFromRequest::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Return JSON 401 on API instead of redirect-to-login HTML
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }
        });

        // Sentry — only active when SENTRY_LARAVEL_DSN is set in env.
        if (env('SENTRY_LARAVEL_DSN') && class_exists(\Sentry\Laravel\Integration::class)) {
            $exceptions->reportable(function (\Throwable $e) {
                \Sentry\Laravel\Integration::captureUnhandledException($e);
            });
        }
    })->create();
