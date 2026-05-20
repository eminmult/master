<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Immutable double-entry ledger for the in-app wallet.
     * Every value movement is captured as 2+ rows sharing a `transaction_uuid`,
     * with debits and credits summing to zero across the transaction.
     *
     * Account types:
     *   - user_balance     — `account_user_id` is the user that holds the balance
     *   - platform_revenue — accumulated app fee (account_user_id NULL)
     *   - external_card    — money that entered/left the system via a card (account_user_id NULL)
     *
     * `kind` describes the business meaning (callout_fee, callout_refund, master_penalty,
     * withdrawal_request, withdrawal_paid, manual_adjust, ...). Reports group by this.
     */
    public function up(): void
    {
        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->uuid('transaction_uuid');
            $table->string('account_type', 32);
            $table->foreignId('account_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->char('direction', 6); // 'debit' | 'credit'
            $table->bigInteger('amount_cents'); // always positive
            $table->string('currency', 8)->default('AZN');
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->string('kind', 48);
            $table->string('idempotency_key', 64)->nullable()->unique();
            $table->json('metadata')->nullable();
            $table->foreignId('created_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['account_user_id', 'created_at']);
            $table->index('transaction_uuid');
            $table->index('order_id');
            $table->index('kind');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
    }
};
