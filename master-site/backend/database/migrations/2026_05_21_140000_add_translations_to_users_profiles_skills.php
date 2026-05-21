<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Per-locale translations for the remaining user-generated text fields:
     * user names (transliterated per script), master profile city + district
     * and skill names. Combined with description_translations (already in
     * place) every public surface for a master can now render fully in the
     * visitor's language.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->jsonb('first_name_translations')->nullable();
            $table->jsonb('last_name_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });

        Schema::table('master_profiles', function (Blueprint $table) {
            $table->jsonb('city_translations')->nullable();
            $table->jsonb('district_translations')->nullable();
        });

        if (Schema::hasTable('skills')) {
            Schema::table('skills', function (Blueprint $table) {
                $table->jsonb('name_translations')->nullable();
                $table->string('content_locale', 5)->nullable();
            });
        }

        if (Schema::hasTable('portfolio_items') && !Schema::hasColumn('portfolio_items', 'title_translations')) {
            Schema::table('portfolio_items', function (Blueprint $table) {
                $table->jsonb('title_translations')->nullable();
            });
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['first_name_translations', 'last_name_translations', 'content_locale']);
        });
        Schema::table('master_profiles', function (Blueprint $table) {
            $table->dropColumn(['city_translations', 'district_translations']);
        });
        if (Schema::hasTable('skills')) {
            Schema::table('skills', function (Blueprint $table) {
                $table->dropColumn(['name_translations', 'content_locale']);
            });
        }
        if (Schema::hasTable('portfolio_items') && Schema::hasColumn('portfolio_items', 'title_translations')) {
            Schema::table('portfolio_items', function (Blueprint $table) {
                $table->dropColumn('title_translations');
            });
        }
    }
};
