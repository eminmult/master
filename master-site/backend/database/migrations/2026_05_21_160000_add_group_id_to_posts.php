<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration {
    /**
     * Blog posts now have per-locale slugs (so /en/blog/apartment-renovation
     * is a Latin English slug instead of the Russian transliteration). Rows
     * that translate the same article share a `group_id` so the language
     * switcher and hreflang can hop between localized URLs.
     *
     * The existing single-slug shape is preserved by back-filling group_id
     * with one UUID per slug; per-locale slug differentiation kicks in only
     * when translate-posts is re-run.
     */
    public function up(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->uuid('group_id')->nullable()->after('id');
            $table->index('group_id');
        });

        // Back-fill: rows that share the same `slug` belong to one group.
        $rows = \DB::table('posts')->select('id', 'slug')->get();
        $groupBySlug = [];
        foreach ($rows as $r) {
            if (!isset($groupBySlug[$r->slug])) {
                $groupBySlug[$r->slug] = (string) Str::uuid();
            }
            \DB::table('posts')->where('id', $r->id)->update(['group_id' => $groupBySlug[$r->slug]]);
        }

        // The (slug, locale) unique stays — same slug can't repeat within a locale.
    }

    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropIndex(['group_id']);
            $table->dropColumn('group_id');
        });
    }
};
