<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('chat_messages', function (Blueprint $table) {
            // Image messages — clients/masters drop a photo from their
            // gallery or shoot it on camera. Both URLs are saved when the
            // image processor returns multiple sizes; renderers prefer
            // photo_thumb_url for inline previews and the full one for the
            // lightbox tap.
            $table->string('photo_url', 500)->nullable()->after('text');
            $table->string('photo_thumb_url', 500)->nullable()->after('photo_url');
        });
    }

    public function down(): void
    {
        Schema::table('chat_messages', function (Blueprint $table) {
            $table->dropColumn(['photo_url', 'photo_thumb_url']);
        });
    }
};
