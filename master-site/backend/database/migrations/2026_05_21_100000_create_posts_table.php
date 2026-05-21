<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Long-form blog posts — backbone of off-page SEO via natural backlinks.
     * Per-locale rows keyed by (slug, locale) so the same conceptual post
     * exists in multiple languages with the same canonical slug. Body is
     * Markdown rendered on the client (no XSS surface for now since posts
     * are admin-only).
     */
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->string('slug', 191);
            $table->string('locale', 8);
            $table->string('title');
            $table->string('excerpt', 320)->nullable();
            $table->longText('body_md');
            $table->string('hero_url', 512)->nullable();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->unique(['slug', 'locale']);
            $table->index(['locale', 'published_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
