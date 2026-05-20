<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            // Free-text clarification the client wants the master to see
            // when arriving — "code on gate is 1234", "second door on left",
            // "ring twice", etc. Optional, capped at 500 chars to match
            // existing free-text fields on this table.
            $table->text('note')->nullable()->after('intercom');
        });
    }

    public function down(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            $table->dropColumn('note');
        });
    }
};
