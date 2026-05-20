<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('chat_messages', function (Blueprint $table) {
            // Null = main order chat (post-agreement). Non-null = per-application pre-agreement chat.
            $table->foreignId('application_id')->nullable()->after('order_id')
                ->constrained('order_applications')->nullOnDelete();
            $table->index(['order_id', 'application_id']);
        });

        Schema::table('order_applications', function (Blueprint $table) {
            // Master's proposed start time (when they want to come). Accepted → order.agreed_date.
            $table->timestamp('proposed_date')->nullable()->after('proposed_price');
        });
    }

    public function down(): void
    {
        Schema::table('chat_messages', function (Blueprint $table) {
            $table->dropForeign(['application_id']);
            $table->dropIndex(['order_id', 'application_id']);
            $table->dropColumn('application_id');
        });
        Schema::table('order_applications', function (Blueprint $table) {
            $table->dropColumn('proposed_date');
        });
    }
};
