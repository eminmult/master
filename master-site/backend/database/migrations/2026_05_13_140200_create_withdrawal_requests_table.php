<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Master-initiated withdrawal request. On create, master's balance is
     * decremented (debit). On admin approval and manual payout completion,
     * status flips to `paid`. On rejection, balance is restored.
     */
    public function up(): void
    {
        Schema::create('withdrawal_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->bigInteger('amount_cents');
            $table->string('currency', 8)->default('AZN');
            // pending | approved | paid | rejected | cancelled
            $table->string('status', 16)->default('pending');
            $table->string('iban', 64)->nullable();
            $table->string('account_holder', 128)->nullable();
            $table->text('note')->nullable();
            $table->text('admin_note')->nullable();
            $table->foreignId('processed_by_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('withdrawal_requests');
    }
};
