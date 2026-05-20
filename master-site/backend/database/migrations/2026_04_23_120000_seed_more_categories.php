<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $categories = [
            // Renovation & finishes
            ['name' => 'Gips karton', 'slug' => 'gips-karton', 'icon' => 'grid_3x3'],
            ['name' => 'Sökmə işləri', 'slug' => 'sokme', 'icon' => 'construction'],
            ['name' => 'Gərmə tavan', 'slug' => 'germe-tavan', 'icon' => 'view_day'],
            ['name' => 'Pəncərə şüşələmə', 'slug' => 'sushelemе', 'icon' => 'window'],
            ['name' => 'Balkon şüşələmə', 'slug' => 'balkon', 'icon' => 'balcony'],
            ['name' => 'İnteryer dizayn', 'slug' => 'dizayn', 'icon' => 'design_services'],
            ['name' => 'İşıqlandırma', 'slug' => 'isiqlandirma', 'icon' => 'lightbulb'],
            ['name' => 'Smart ev', 'slug' => 'smart-ev', 'icon' => 'smart_home'],
            ['name' => 'Hamam bərpası', 'slug' => 'hamam', 'icon' => 'bathtub'],
            ['name' => 'İzolyasiya', 'slug' => 'izolyasiya', 'icon' => 'thermostat'],

            // Appliances repair (beyond existing)
            ['name' => 'Su qızdırıcı', 'slug' => 'su-qizdirici', 'icon' => 'water_drop'],
            ['name' => 'Mikrodalğalı peç', 'slug' => 'mikrodalga', 'icon' => 'microwave'],
            ['name' => 'Peç / Soba', 'slug' => 'pec', 'icon' => 'whatshot'],
            ['name' => 'Tozsoran təmiri', 'slug' => 'tozsoran', 'icon' => 'vacuum'],
            ['name' => 'Tikiş maşını', 'slug' => 'tikis-masini', 'icon' => 'content_cut'],

            // IT / electronics
            ['name' => 'Telefon təmiri', 'slug' => 'telefon', 'icon' => 'smartphone'],
            ['name' => 'Printer təmiri', 'slug' => 'printer', 'icon' => 'print'],
            ['name' => 'Planşet təmiri', 'slug' => 'planset', 'icon' => 'tablet_mac'],

            // Mounting / handyman
            ['name' => 'Rəf / şəkil quraşdırma', 'slug' => 'ref-quraşdırma', 'icon' => 'shelves'],
            ['name' => 'Jalüz / Pərdə', 'slug' => 'jaluz', 'icon' => 'blinds'],
            ['name' => 'Güzgü quraşdırma', 'slug' => 'guzgu', 'icon' => 'crop_landscape'],

            // Water / specialty
            ['name' => 'Kanalizasiya təmizləmə', 'slug' => 'kanalizasiya', 'icon' => 'water'],
            ['name' => 'Sızıntı axtarışı', 'slug' => 'sizinti', 'icon' => 'water_damage'],

            // Outdoor / landscape
            ['name' => 'Qazon biçmə', 'slug' => 'qazon', 'icon' => 'yard'],
            ['name' => 'Landşaft dizayn', 'slug' => 'landsaft', 'icon' => 'landscape'],
            ['name' => 'Hasar quraşdırma', 'slug' => 'hasar', 'icon' => 'fence'],
            ['name' => 'Asfalt / yol örtüyü', 'slug' => 'asfalt', 'icon' => 'route'],
            ['name' => 'Qar təmizləmə', 'slug' => 'qar', 'icon' => 'ac_unit'],
            ['name' => 'Ağac budama', 'slug' => 'agac-budama', 'icon' => 'park'],

            // Auto / transport
            ['name' => 'Avtomobil ustası', 'slug' => 'avto-usta', 'icon' => 'directions_car'],
            ['name' => 'Təkər dəyişdirmə', 'slug' => 'teker', 'icon' => 'tire_repair'],
            ['name' => 'Avtoyuma', 'slug' => 'avtoyuma', 'icon' => 'local_car_wash'],
            ['name' => 'Kuryer', 'slug' => 'kuryer', 'icon' => 'local_mall'],

            // Personal services (home-based)
            ['name' => 'Uşaq baxıcısı', 'slug' => 'usaq-baxicisi', 'icon' => 'child_care'],
            ['name' => 'Ev heyvan baxımı', 'slug' => 'petsitting', 'icon' => 'pets'],
            ['name' => 'Fotoqraf', 'slug' => 'fotoqraf', 'icon' => 'photo_camera'],
            ['name' => 'Repetitor', 'slug' => 'repetitor', 'icon' => 'school'],
            ['name' => 'Stilist / bərbər', 'slug' => 'berber', 'icon' => 'content_cut'],
            ['name' => 'Manikür / pedikür', 'slug' => 'manikur', 'icon' => 'spa'],

            // Special
            ['name' => 'Xalça yuma', 'slug' => 'xalca-yuma', 'icon' => 'roller_shades'],
            ['name' => 'Mebel bərpası', 'slug' => 'mebel-berpasi', 'icon' => 'chair_alt'],
            ['name' => 'Royal köklənməsi', 'slug' => 'piano', 'icon' => 'piano'],
            ['name' => 'Tədbir hazırlanması', 'slug' => 'tedbir', 'icon' => 'celebration'],
        ];

        $now = now();
        $startOrder = (int) DB::table('categories')->max('sort_order') + 1;

        foreach ($categories as $i => $cat) {
            // Skip if slug already exists
            if (DB::table('categories')->where('slug', $cat['slug'])->exists()) continue;

            DB::table('categories')->insert([
                'name' => $cat['name'],
                'slug' => $cat['slug'],
                'icon_url' => $cat['icon'],
                'description' => null,
                'sort_order' => $startOrder + $i,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        $slugs = [
            'gips-karton', 'sokme', 'germe-tavan', 'sushelemе', 'balkon', 'dizayn', 'isiqlandirma',
            'smart-ev', 'hamam', 'izolyasiya', 'su-qizdirici', 'mikrodalga', 'pec', 'tozsoran',
            'tikis-masini', 'telefon', 'printer', 'planset', 'ref-quraşdırma', 'jaluz', 'guzgu',
            'kanalizasiya', 'sizinti', 'qazon', 'landsaft', 'hasar', 'asfalt', 'qar', 'agac-budama',
            'avto-usta', 'teker', 'avtoyuma', 'kuryer', 'usaq-baxicisi', 'petsitting', 'fotoqraf',
            'repetitor', 'berber', 'manikur', 'xalca-yuma', 'mebel-berpasi', 'piano', 'tedbir',
        ];
        DB::table('categories')->whereIn('slug', $slugs)->delete();
    }
};
