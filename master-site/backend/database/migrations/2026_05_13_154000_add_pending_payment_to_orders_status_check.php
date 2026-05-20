<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Allow the `pending_payment` status added in the callout-fee work.
 *
 * The earlier `STATUS_PENDING_PAYMENT` const was added to the model but the
 * Postgres CHECK constraint still enforced the old enum, so paying the fee
 * blew up with SQLSTATE[23514] inside CalloutFeeService::chargeAndConfirm()
 * the moment the controller tried to flip the order from pending_client.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check');
        DB::statement(<<<'SQL'
            ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (
              (status)::text = ANY (ARRAY[
                'draft'::varchar, 'new'::varchar,
                'searching_master'::varchar, 'pending_master'::varchar,
                'discussion'::varchar, 'pending_client'::varchar, 'pending_payment'::varchar,
                'confirmed'::varchar, 'accepted'::varchar,
                'on_the_way'::varchar, 'arrived'::varchar,
                'in_progress'::varchar, 'awaiting_completion'::varchar,
                'completed'::varchar, 'awaiting_review'::varchar,
                'canceled_by_client'::varchar, 'canceled_by_master'::varchar, 'canceled_by_system'::varchar,
                'disputed'::varchar, 'closed'::varchar
              ]::text[])
            )
            SQL
        );
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check');
        DB::statement(<<<'SQL'
            ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (
              (status)::text = ANY (ARRAY[
                'draft'::varchar, 'new'::varchar,
                'searching_master'::varchar, 'pending_master'::varchar,
                'discussion'::varchar, 'pending_client'::varchar,
                'confirmed'::varchar, 'accepted'::varchar,
                'on_the_way'::varchar, 'arrived'::varchar,
                'in_progress'::varchar, 'awaiting_completion'::varchar,
                'completed'::varchar, 'awaiting_review'::varchar,
                'canceled_by_client'::varchar, 'canceled_by_master'::varchar, 'canceled_by_system'::varchar,
                'disputed'::varchar, 'closed'::varchar
              ]::text[])
            )
            SQL
        );
    }
};
