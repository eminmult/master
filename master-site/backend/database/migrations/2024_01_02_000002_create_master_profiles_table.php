<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('master_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->text('description')->nullable();
            $table->unsignedSmallInteger('experience_years')->default(0);
            $table->enum('status', ['online', 'offline', 'busy'])->default('offline');
            $table->boolean('is_accepting_orders')->default(false);
            $table->boolean('is_verified')->default(false);
            $table->string('city')->nullable();
            $table->string('district')->nullable();
            $table->string('transport_type')->nullable();
            $table->boolean('urgent_available')->default(false);
            $table->unsignedSmallInteger('work_radius_km')->default(20);
            $table->string('languages')->nullable(); // comma-separated
            $table->decimal('current_lat', 10, 7)->nullable();
            $table->decimal('current_lng', 10, 7)->nullable();
            $table->timestamp('location_updated_at')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->unsignedInteger('completed_orders_count')->default(0);
            $table->unsignedInteger('canceled_orders_count')->default(0);
            $table->timestamps();
        });

        Schema::create('master_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('master_profile_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subcategory_id')->nullable()->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['master_profile_id', 'category_id', 'subcategory_id'], 'master_cat_subcat_unique');
        });

        Schema::create('master_work_hours', function (Blueprint $table) {
            $table->id();
            $table->foreignId('master_profile_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('day_of_week'); // 0=Mon, 6=Sun
            $table->time('start_time');
            $table->time('end_time');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('master_work_hours');
        Schema::dropIfExists('master_categories');
        Schema::dropIfExists('master_profiles');
    }
};
