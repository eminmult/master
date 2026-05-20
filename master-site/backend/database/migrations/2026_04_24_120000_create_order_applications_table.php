<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_applications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignId('master_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 20)->default('pending'); // pending|accepted|rejected|withdrawn|expired
            $table->text('message')->nullable();
            $table->decimal('proposed_price', 10, 2)->nullable();
            $table->timestamp('responded_at')->nullable();
            $table->timestamps();

            $table->unique(['order_id', 'master_id']);
            $table->index(['master_id', 'status']);
            $table->index(['order_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_applications');
    }
};
