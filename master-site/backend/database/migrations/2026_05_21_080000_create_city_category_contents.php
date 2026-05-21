<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * AI-generated content per (city, category, locale). Shape mirrors
     * category_contents.body so the renderer can reuse the same blocks
     * (intro, faqs, etc.) with city-specific copy. city is stored as the
     * canonical slug so multiple city-name variants ("Bakı", "Baku") share
     * one row.
     */
    public function up(): void
    {
        Schema::create('city_category_contents', function (Blueprint $table) {
            $table->id();
            $table->string('city_slug', 64);
            $table->foreignId('category_id')->constrained('categories')->cascadeOnDelete();
            $table->string('locale', 8);
            $table->jsonb('body')->default('{}');
            $table->timestamps();
            $table->unique(['city_slug', 'category_id', 'locale']);
            $table->index(['city_slug', 'category_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('city_category_contents');
    }
};
