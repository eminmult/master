<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Verification was previously a master-only flag (master_profiles.is_verified).
 * Clients can also be verified — passport ID, payment record, hand-curated
 * trust score — so we promote the flag to the users table. Master-side
 * verification stays where it is for backwards compatibility but front-ends
 * should now read users.is_verified directly.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_verified')->default(false)->after('phone_verified_at');
            $table->timestamp('verified_at')->nullable()->after('is_verified');
        });

        // Backfill: any master who is currently is_verified=true mirrors to users.
        // PostgreSQL uses UPDATE … FROM …, not MySQL's UPDATE … JOIN.
        \DB::statement("
            UPDATE users u
            SET is_verified = mp.is_verified,
                verified_at = mp.verified_at
            FROM master_profiles mp
            WHERE mp.user_id = u.id AND mp.is_verified = TRUE
        ");
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['is_verified', 'verified_at']);
        });
    }
};
