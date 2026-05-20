<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('client_id')->constrained('users');
            $table->foreignId('master_id')->nullable()->constrained('users');
            $table->foreignId('category_id')->constrained();
            $table->foreignId('subcategory_id')->nullable()->constrained();
            $table->foreignId('address_id')->nullable()->constrained();
            $table->text('description');
            $table->string('full_address');
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->string('entrance')->nullable();
            $table->string('floor')->nullable();
            $table->string('intercom')->nullable();
            $table->string('contact_phone', 20);
            $table->enum('desired_time', ['asap', 'scheduled'])->default('asap');
            $table->timestamp('scheduled_at')->nullable();
            $table->enum('urgency', ['normal', 'urgent'])->default('normal');
            $table->decimal('estimated_budget', 10, 2)->nullable();
            $table->text('comment')->nullable();

            $table->enum('status', [
                'draft',
                'new',
                'searching_master',
                'accepted',
                'on_the_way',
                'arrived',
                'in_progress',
                'completed',
                'awaiting_review',
                'canceled_by_client',
                'canceled_by_master',
                'canceled_by_system',
                'disputed',
                'closed',
            ])->default('new');

            $table->string('cancel_reason')->nullable();
            $table->decimal('cancel_lat', 10, 7)->nullable();
            $table->decimal('cancel_lng', 10, 7)->nullable();

            $table->boolean('client_reviewed')->default(false);
            $table->boolean('master_reviewed')->default(false);

            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('on_the_way_at')->nullable();
            $table->timestamp('arrived_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('canceled_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();

            $table->index('status');
            $table->index('client_id');
            $table->index('master_id');
            $table->index('category_id');
        });

        Schema::create('order_status_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('status');
            $table->foreignId('changed_by')->nullable()->constrained('users');
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index('order_id');
        });

        Schema::create('order_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('url');
            $table->enum('type', ['problem', 'result'])->default('problem');
            $table->foreignId('uploaded_by')->constrained('users');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_photos');
        Schema::dropIfExists('order_status_history');
        Schema::dropIfExists('orders');
    }
};
