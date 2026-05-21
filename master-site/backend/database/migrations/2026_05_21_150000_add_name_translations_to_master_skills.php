<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * The actual skills table is `master_skills`, not `skills`. Adding the
     * translation columns here as a separate migration so the prior one
     * (which guessed "skills") becomes a no-op.
     */
    public function up(): void
    {
        Schema::table('master_skills', function (Blueprint $table) {
            $table->jsonb('name_translations')->nullable();
            $table->string('content_locale', 5)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('master_skills', function (Blueprint $table) {
            $table->dropColumn(['name_translations', 'content_locale']);
        });
    }
};
