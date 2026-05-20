<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * AI-generated long-form content per category × locale. Body is a JSONB
     * blob with keyed sections (intro, what_included[], pricing, faqs[]...)
     * so the renderer doesn't need a schema migration for new block types.
     */
    public function up(): void
    {
        Schema::create('category_contents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained('categories')->cascadeOnDelete();
            $table->string('locale', 8);
            $table->jsonb('body')->default('{}');
            $table->timestamps();
            $table->unique(['category_id', 'locale']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('category_contents');
    }
};
