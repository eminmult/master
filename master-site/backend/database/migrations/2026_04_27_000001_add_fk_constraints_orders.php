<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Drop existing FKs (they have no onDelete) and recreate with restrict
        // so that deleting a user with active orders fails loudly instead of
        // leaving orphans pointing at vanished IDs.
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_client_id_foreign');
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_master_id_foreign');

        Schema::table('orders', function ($table) {
            $table->foreign('client_id')->references('id')->on('users')->onDelete('restrict');
            $table->foreign('master_id')->references('id')->on('users')->onDelete('restrict');
        });

        // order_applications.master_id — same protection
        DB::statement('ALTER TABLE order_applications DROP CONSTRAINT IF EXISTS order_applications_master_id_foreign');
        Schema::table('order_applications', function ($table) {
            $table->foreign('master_id')->references('id')->on('users')->onDelete('restrict');
        });

        // reviews — preserve when reviewer/reviewee deleted (we anonymize, not drop)
        DB::statement('ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_reviewer_id_foreign');
        DB::statement('ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_reviewee_id_foreign');
        Schema::table('reviews', function ($table) {
            $table->foreign('reviewer_id')->references('id')->on('users')->onDelete('restrict');
            $table->foreign('reviewee_id')->references('id')->on('users')->onDelete('restrict');
        });
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_client_id_foreign');
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_master_id_foreign');
        Schema::table('orders', function ($table) {
            $table->foreign('client_id')->references('id')->on('users');
            $table->foreign('master_id')->references('id')->on('users');
        });

        DB::statement('ALTER TABLE order_applications DROP CONSTRAINT IF EXISTS order_applications_master_id_foreign');
        Schema::table('order_applications', function ($table) {
            $table->foreign('master_id')->references('id')->on('users');
        });

        DB::statement('ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_reviewer_id_foreign');
        DB::statement('ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_reviewee_id_foreign');
        Schema::table('reviews', function ($table) {
            $table->foreign('reviewer_id')->references('id')->on('users');
            $table->foreign('reviewee_id')->references('id')->on('users');
        });
    }
};
