<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class SetLocaleFromRequest
{
    private const SUPPORTED = ['az', 'ru', 'en', 'tr', 'ar'];
    private const DEFAULT = 'az';

    public function handle(Request $request, Closure $next)
    {
        $locale = self::DEFAULT;

        // 1. ?locale=ru wins (explicit override)
        if ($q = $request->query('locale')) {
            $q = strtolower((string) $q);
            if (in_array($q, self::SUPPORTED, true)) $locale = $q;
        } else {
            // 2. Accept-Language header
            $header = (string) $request->header('Accept-Language', '');
            foreach (explode(',', $header) as $chunk) {
                $code = strtolower(trim(explode(';', $chunk, 2)[0]));
                $code = substr($code, 0, 2);
                if (in_array($code, self::SUPPORTED, true)) { $locale = $code; break; }
            }
        }

        app()->setLocale($locale);
        return $next($request);
    }
}
