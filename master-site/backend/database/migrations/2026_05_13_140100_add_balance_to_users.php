<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Cached balance for fast reads. Authoritative source of truth is still
     * the wallet_transactions ledger; this column is always updated inside the
     * same DB transaction that writes the ledger entry, with a row-level lock.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->bigInteger('balance_cents')->default(0)->after('is_verified');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('balance_cents');
        });
    }
};
