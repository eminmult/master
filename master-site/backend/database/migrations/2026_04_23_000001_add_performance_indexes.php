<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->index('created_at', 'orders_created_at_index');
            $table->index(['status', 'created_at'], 'orders_status_created_idx');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->index('created_at', 'users_created_at_index');
        });

        Schema::table('reviews', function (Blueprint $table) {
            $table->index('reviewer_id', 'reviews_reviewer_id_index');
            $table->index(['reviewee_id', 'created_at'], 'reviews_reviewee_created_idx');
        });

        Schema::table('notifications', function (Blueprint $table) {
            $table->index('created_at', 'notifications_created_at_index');
        });

        Schema::table('chat_messages', function (Blueprint $table) {
            $table->index('sender_id', 'chat_messages_sender_id_index');
            $table->index('read_at', 'chat_messages_read_at_index');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex('orders_created_at_index');
            $table->dropIndex('orders_status_created_idx');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex('users_created_at_index');
        });

        Schema::table('reviews', function (Blueprint $table) {
            $table->dropIndex('reviews_reviewer_id_index');
            $table->dropIndex('reviews_reviewee_created_idx');
        });

        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex('notifications_created_at_index');
        });

        Schema::table('chat_messages', function (Blueprint $table) {
            $table->dropIndex('chat_messages_sender_id_index');
            $table->dropIndex('chat_messages_read_at_index');
        });
    }
};
