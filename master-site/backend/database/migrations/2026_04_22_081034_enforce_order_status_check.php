<?php

use App\Models\Order;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Drop any existing status check constraint
        $constraints = DB::select("
            SELECT con.conname
            FROM pg_constraint con
            JOIN pg_class rel ON rel.oid = con.conrelid
            WHERE rel.relname = 'orders' AND con.contype = 'c' AND con.conname LIKE '%status%'
        ");
        foreach ($constraints as $c) {
            DB::statement("ALTER TABLE orders DROP CONSTRAINT \"{$c->conname}\"");
        }

        $list = "'" . implode("','", Order::ALL_STATUSES) . "'";
        DB::statement("ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (status IN ({$list}))");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check");
    }
};
