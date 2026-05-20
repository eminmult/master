<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('reviewer_id')->constrained('users');
            $table->foreignId('reviewee_id')->constrained('users');
            $table->unsignedTinyInteger('rating'); // 1-5
            $table->text('text')->nullable();
            $table->json('tags')->nullable(); // ["punctual", "polite", "quality"]
            $table->timestamps();

            $table->unique(['order_id', 'reviewer_id']);
            $table->index('reviewee_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
