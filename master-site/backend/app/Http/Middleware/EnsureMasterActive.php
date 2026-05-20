<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gate master-only mutating endpoints (apply, propose, send message)
 * behind the subscription state. Read endpoints stay open so masters
 * can still see their dashboard / past orders even after expiry.
 *
 * During launch (config('master.subscription_required') === false) every
 * master passes — middleware short-circuits.
 */
class EnsureMasterActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (!$user || !$user->isMaster()) {
            return $next($request);
        }

        if ($user->canOperateAsMaster()) {
            return $next($request);
        }

        return response()->json([
            'message' => 'Subscription expired',
            'code' => 'subscription_required',
            'subscription_expires_at' => $user->subscription_expires_at?->toIso8601String(),
        ], 402);
    }
}
