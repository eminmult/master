<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->jsonb('description_translations')->nullable();
            $table->jsonb('comment_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });

        Schema::table('chat_messages', function (Blueprint $table) {
            $table->jsonb('text_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });

        Schema::table('reviews', function (Blueprint $table) {
            // 'text' already exists — we add translations sibling
            $table->jsonb('text_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });

        Schema::table('master_profiles', function (Blueprint $table) {
            $table->jsonb('description_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });

        Schema::table('portfolio_items', function (Blueprint $table) {
            $table->jsonb('description_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });

        Schema::table('category_suggestions', function (Blueprint $table) {
            $table->jsonb('name_translations')->nullable();
            $table->jsonb('description_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['description_translations', 'comment_translations', 'content_locale']);
        });
        Schema::table('chat_messages', function (Blueprint $table) {
            $table->dropColumn(['text_translations', 'content_locale']);
        });
        Schema::table('reviews', function (Blueprint $table) {
            $table->dropColumn(['text_translations', 'content_locale']);
        });
        Schema::table('master_profiles', function (Blueprint $table) {
            $table->dropColumn(['description_translations', 'content_locale']);
        });
        Schema::table('portfolio_items', function (Blueprint $table) {
            $table->dropColumn(['description_translations', 'content_locale']);
        });
        Schema::table('category_suggestions', function (Blueprint $table) {
            $table->dropColumn(['name_translations', 'description_translations', 'content_locale']);
        });
    }
};
