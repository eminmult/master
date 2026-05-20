<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('master_locations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('master_id')->constrained('users');
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->timestamp('recorded_at')->useCurrent();

            $table->index(['order_id', 'recorded_at']);
            $table->index('master_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('master_locations');
    }
};
