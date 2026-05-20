<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Per-locale name/slug/description for SEO-friendly URLs and localized
     * category content. Keyed by locale code (az, ru, en, tr, ar). When a
     * locale key is missing, callers fall back to the original Azeri value.
     */
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->jsonb('name_translations')->default('{}');
            $table->jsonb('slug_translations')->default('{}');
            $table->jsonb('description_translations')->default('{}');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn(['name_translations', 'slug_translations', 'description_translations']);
        });
    }
};
