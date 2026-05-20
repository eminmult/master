<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // During launch flag MASTER_SUBSCRIPTION_REQUIRED=false → defaults
            // mean every existing master is automatically active. When the flag
            // flips on, subscription_expires_at is the gate.
            $table->boolean('subscription_active')->default(true)->after('is_active');
            $table->timestamp('subscription_expires_at')->nullable()->after('subscription_active');
            $table->timestamp('registration_paid_at')->nullable()->after('subscription_expires_at');
        });

        // Backfill: existing masters get a far-future expiry so the launch
        // grace period works without requiring config gymnastics later.
        DB::table('users')->where('role', 'master')->update([
            'subscription_active' => true,
            'subscription_expires_at' => now()->addYear(),
        ]);

        Schema::create('master_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('master_id')->constrained('users')->cascadeOnDelete();
            $table->enum('plan', ['registration', 'monthly', 'yearly', 'lifetime', 'manual'])->default('monthly');
            $table->decimal('amount', 10, 2)->default(0);
            $table->string('currency', 3)->default('AZN');
            $table->enum('status', ['pending', 'paid', 'failed', 'refunded', 'manual'])->default('pending');
            $table->string('payment_provider')->nullable();
            $table->string('payment_id')->nullable();
            $table->timestamp('starts_at')->useCurrent();
            $table->timestamp('expires_at')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['master_id', 'status']);
            $table->index('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('master_subscriptions');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['subscription_active', 'subscription_expires_at', 'registration_paid_at']);
        });
    }
};
