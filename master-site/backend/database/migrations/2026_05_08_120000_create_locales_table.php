<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('locales', function (Blueprint $table) {
            $table->id();
            $table->string('code', 8)->unique();
            $table->string('name', 64);
            $table->string('dir', 3)->default('ltr');
            $table->boolean('is_active')->default(true);
            $table->boolean('is_default')->default(false);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();

            $table->index(['is_active', 'sort_order']);
        });

        DB::table('locales')->insert([
            ['code' => 'az', 'name' => 'Azərbaycan', 'dir' => 'ltr', 'is_active' => true, 'is_default' => true,  'sort_order' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'ru', 'name' => 'Русский',     'dir' => 'ltr', 'is_active' => true, 'is_default' => false, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'en', 'name' => 'English',     'dir' => 'ltr', 'is_active' => true, 'is_default' => false, 'sort_order' => 2, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'tr', 'name' => 'Türkçe',      'dir' => 'ltr', 'is_active' => true, 'is_default' => false, 'sort_order' => 3, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'ar', 'name' => 'العربية',     'dir' => 'rtl', 'is_active' => true, 'is_default' => false, 'sort_order' => 4, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('locales');
    }
};
