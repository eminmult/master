<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Wire the payment gateway. Swap StubPaymentGateway for a real PSP
        // implementation (PashaPaymentGateway, KapitalPaymentGateway, …) once
        // the merchant contract is signed and credentials live in .env.
        $this->app->bind(
            \App\Services\Payments\PaymentGateway::class,
            fn () => new \App\Services\Payments\StubPaymentGateway(),
        );
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
