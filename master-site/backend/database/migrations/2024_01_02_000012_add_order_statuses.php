<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Drop enum constraint — Laravel stores enums as check constraints in PG
        $constraints = DB::select("
            SELECT con.conname
            FROM pg_constraint con
            JOIN pg_class rel ON rel.oid = con.conrelid
            WHERE rel.relname = 'orders' AND con.contype = 'c' AND con.conname LIKE '%status%'
        ");

        foreach ($constraints as $c) {
            DB::statement("ALTER TABLE orders DROP CONSTRAINT \"{$c->conname}\"");
        }

        // Add new columns
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'confirmed_at')) {
                $table->timestamp('confirmed_at')->nullable();
            }
            if (!Schema::hasColumn('orders', 'agreed_date')) {
                $table->timestamp('agreed_date')->nullable();
            }
            if (!Schema::hasColumn('orders', 'agreed_price')) {
                $table->decimal('agreed_price', 10, 2)->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['confirmed_at', 'agreed_date', 'agreed_price']);
        });
    }
};
