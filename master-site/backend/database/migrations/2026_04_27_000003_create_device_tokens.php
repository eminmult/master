<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('platform', ['ios', 'android', 'web']);
            $table->string('token', 512); // FCM/APNs tokens can be long
            $table->string('app_version', 20)->nullable();
            $table->string('device_model', 100)->nullable();
            $table->string('locale', 5)->nullable();
            $table->timestamp('last_active_at')->nullable();
            $table->timestamps();

            // One token can only belong to one user; if a user reinstalls, FCM
            // returns a new token, so we don't expect collisions here normally.
            $table->unique('token');
            $table->index(['user_id', 'platform']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
    }
};
