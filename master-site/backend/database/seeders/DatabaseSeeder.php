<?php

namespace Database\Seeders;

use App\Models\Address;
use App\Models\Category;
use App\Models\MasterCategory;
use App\Models\MasterProfile;
use App\Models\Subcategory;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Admin
        User::create([
            'first_name' => 'Admin',
            'last_name' => 'Master',
            'email' => 'admin@itez.app',
            'phone' => '+994501234567',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
        ]);

        // Categories
        $categories = [
            [
                'name' => 'Santexnik', 'slug' => 'santexnik', 'icon_url' => '🔧',
                'description' => 'Su boruları, kanalizasiya, kran təmiri',
                'subs' => [
                    ['name' => 'Kran təmiri', 'slug' => 'kran-temiri'],
                    ['name' => 'Boru təmiri', 'slug' => 'boru-temiri'],
                    ['name' => 'Kanalizasiya', 'slug' => 'kanalizasiya'],
                    ['name' => 'Su sayğacı', 'slug' => 'su-saygaci'],
                    ['name' => 'Unitaz quraşdırma', 'slug' => 'unitaz-qurasdirma'],
                ],
            ],
            [
                'name' => 'Elektrik', 'slug' => 'elektrik', 'icon_url' => '⚡',
                'description' => 'Elektrik xətləri, rozetka, lampa quraşdırma',
                'subs' => [
                    ['name' => 'Rozetka/açar', 'slug' => 'rozetka-acar'],
                    ['name' => 'Lampa quraşdırma', 'slug' => 'lampa-qurasdirma'],
                    ['name' => 'Elektrik xətti', 'slug' => 'elektrik-xetti'],
                    ['name' => 'Avtomat/UZO', 'slug' => 'avtomat-uzo'],
                ],
            ],
            [
                'name' => 'Qaynaqçı', 'slug' => 'qaynaqci', 'icon_url' => '🔥',
                'description' => 'Metal qaynaq işləri',
                'subs' => [
                    ['name' => 'Boru qaynağı', 'slug' => 'boru-qaynagi'],
                    ['name' => 'Metal konstruksiya', 'slug' => 'metal-konstruksiya'],
                ],
            ],
            [
                'name' => 'Usta saatı', 'slug' => 'usta-saati', 'icon_url' => '🛠️',
                'description' => 'Kiçik təmir və quraşdırma işləri',
                'subs' => [
                    ['name' => 'Qapı təmiri', 'slug' => 'qapi-temiri'],
                    ['name' => 'Pəncərə təmiri', 'slug' => 'pencere-temiri'],
                    ['name' => 'Rəf quraşdırma', 'slug' => 'ref-qurasdirma'],
                ],
            ],
            [
                'name' => 'Mebel yığımı', 'slug' => 'mebel-yigimi', 'icon_url' => '🪑',
                'description' => 'Mebel sökülməsi və yığılması',
                'subs' => [
                    ['name' => 'Mətbəx mebeli', 'slug' => 'metbex-mebeli'],
                    ['name' => 'Şkaf yığımı', 'slug' => 'skaf-yigimi'],
                    ['name' => 'Çarpayı yığımı', 'slug' => 'carpay-yigimi'],
                ],
            ],
            [
                'name' => 'Rəngləmə', 'slug' => 'rengleme', 'icon_url' => '🖌️',
                'description' => 'Divar boyama, dekorativ işlər',
                'subs' => [
                    ['name' => 'Divar boyama', 'slug' => 'divar-boyama'],
                    ['name' => 'Tavan boyama', 'slug' => 'tavan-boyama'],
                    ['name' => 'Dekorativ suvaq', 'slug' => 'dekorativ-suvaq'],
                ],
            ],
            [
                'name' => 'Kondisioner', 'slug' => 'kondisioner', 'icon_url' => '❄️',
                'description' => 'Kondisioner quraşdırma və təmiri',
                'subs' => [
                    ['name' => 'Quraşdırma', 'slug' => 'kondisioner-qurasdirma'],
                    ['name' => 'Təmizləmə', 'slug' => 'kondisioner-temizleme'],
                    ['name' => 'Təmir', 'slug' => 'kondisioner-temir'],
                ],
            ],
            [
                'name' => 'Çilingər', 'slug' => 'cilinger', 'icon_url' => '🔑',
                'description' => 'Qıfıl dəyişmə, qapı açma',
                'subs' => [
                    ['name' => 'Qıfıl dəyişmə', 'slug' => 'qifil-deyisme'],
                    ['name' => 'Qapı açma', 'slug' => 'qapi-acma'],
                ],
            ],
        ];

        foreach ($categories as $i => $catData) {
            $subs = $catData['subs'];
            unset($catData['subs']);
            $catData['sort_order'] = $i;

            $category = Category::create($catData);

            foreach ($subs as $j => $subData) {
                $subData['category_id'] = $category->id;
                $subData['sort_order'] = $j;
                Subcategory::create($subData);
            }
        }

        // Demo client
        $client = User::create([
            'first_name' => 'Əli',
            'last_name' => 'Həsənov',
            'email' => 'client@itez.app',
            'phone' => '+994551112233',
            'password' => Hash::make('client123'),
            'role' => 'client',
        ]);

        Address::create([
            'user_id' => $client->id,
            'label' => 'Ev',
            'full_address' => 'Bakı, Nəsimi r., Nizami küç. 42',
            'lat' => 40.3790,
            'lng' => 49.8492,
            'floor' => '5',
            'is_default' => true,
        ]);

        // Demo master
        $masterUser = User::create([
            'first_name' => 'Rəşad',
            'last_name' => 'Məmmədov',
            'email' => 'master@itez.app',
            'phone' => '+994554445566',
            'password' => Hash::make('master123'),
            'role' => 'master',
            'rating_avg' => 4.80,
            'rating_count' => 12,
        ]);

        $profile = MasterProfile::create([
            'user_id' => $masterUser->id,
            'description' => '10 illik təcrübəli santexnik ustası. Keyfiyyətli və operativ xidmət.',
            'experience_years' => 10,
            'status' => 'online',
            'is_accepting_orders' => true,
            'is_verified' => true,
            'city' => 'Bakı',
            'district' => 'Nəsimi',
            'transport_type' => 'car',
            'urgent_available' => true,
            'work_radius_km' => 30,
            'languages' => 'az,ru',
            'current_lat' => 40.4093,
            'current_lng' => 49.8671,
            'location_updated_at' => now(),
            'verified_at' => now(),
            'completed_orders_count' => 12,
        ]);

        $santexnik = Category::where('slug', 'santexnik')->first();
        $elektrik = Category::where('slug', 'elektrik')->first();
        MasterCategory::create(['master_profile_id' => $profile->id, 'category_id' => $santexnik->id]);
        MasterCategory::create(['master_profile_id' => $profile->id, 'category_id' => $elektrik->id]);
    }
}
