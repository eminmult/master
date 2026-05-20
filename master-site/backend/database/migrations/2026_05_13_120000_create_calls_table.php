<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('calls', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('caller_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('callee_id')->constrained('users')->cascadeOnDelete();
            // ringing | accepted | rejected | missed | ended | cancelled
            $table->string('status', 16)->default('ringing');
            $table->timestamp('started_at')->useCurrent();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->unsignedInteger('duration_sec')->nullable();
            $table->string('end_reason', 32)->nullable();
            $table->timestamps();

            $table->index(['order_id', 'status']);
            $table->index(['caller_id', 'created_at']);
            $table->index(['callee_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('calls');
    }
};
