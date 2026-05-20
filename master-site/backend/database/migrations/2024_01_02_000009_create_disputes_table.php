<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('reporter_id')->constrained('users');
            $table->string('reason');
            $table->text('description')->nullable();
            $table->enum('status', ['open', 'reviewing', 'resolved', 'closed'])->default('open');
            $table->text('admin_note')->nullable();
            $table->foreignId('resolved_by')->nullable()->constrained('users');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('disputes');
    }
};
