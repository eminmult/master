<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Saved payment cards. Stub-mode: stores only brand / last4 / exp / holder /
 * an opaque token reference. The card PAN and CVV are never persisted —
 * when we wire in a real provider (PayRiff / Stripe), `token` will be the
 * tokenized reference returned by their tokenization endpoint.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('payment_cards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('brand', 20);           // visa / mastercard / amex / unknown
            $table->string('last4', 4);
            $table->unsignedTinyInteger('exp_month');
            $table->unsignedSmallInteger('exp_year');
            $table->string('holder_name', 100)->nullable();
            $table->string('token', 191)->nullable();   // provider token when wired up
            $table->boolean('is_default')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'is_default']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_cards');
    }
};
