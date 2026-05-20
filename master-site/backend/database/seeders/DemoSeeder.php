<?php

namespace Database\Seeders;

use App\Models\Address;
use App\Models\Category;
use App\Models\ChatMessage;
use App\Models\MasterCategory;
use App\Models\MasterProfile;
use App\Models\Order;
use App\Models\Review;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $password = Hash::make('demo123');
        $categories = Category::all();

        // ===== 10 CLIENTS =====
        $clients = [];
        $clientData = [
            ['first_name' => 'Əli', 'last_name' => 'Həsənov', 'phone' => '+994501110001', 'email' => 'ali@demo.az', 'address' => 'Bakı, Nəsimi r., Nizami küç. 42', 'lat' => 40.3790, 'lng' => 49.8492],
            ['first_name' => 'Leyla', 'last_name' => 'Əliyeva', 'phone' => '+994501110002', 'email' => 'leyla@demo.az', 'address' => 'Bakı, Yasamal r., İnşaatçılar pr. 15', 'lat' => 40.3880, 'lng' => 49.8350],
            ['first_name' => 'Tural', 'last_name' => 'Məmmədov', 'phone' => '+994501110003', 'email' => 'tural@demo.az', 'address' => 'Bakı, Xətai r., Babək pr. 78', 'lat' => 40.3950, 'lng' => 49.8820],
            ['first_name' => 'Günel', 'last_name' => 'Qasımova', 'phone' => '+994501110004', 'email' => 'gunel@demo.az', 'address' => 'Bakı, Binəqədi r., 8-ci mkr.', 'lat' => 40.4520, 'lng' => 49.8280],
            ['first_name' => 'Orxan', 'last_name' => 'Bayramov', 'phone' => '+994501110005', 'email' => 'orxan@demo.az', 'address' => 'Bakı, Səbail r., Bulvar küç. 3', 'lat' => 40.3660, 'lng' => 49.8370],
            ['first_name' => 'Nigar', 'last_name' => 'İsmayılova', 'phone' => '+994501110006', 'email' => 'nigar@demo.az', 'address' => 'Bakı, Nərimanov r., Atatürk pr. 20', 'lat' => 40.4130, 'lng' => 49.8670],
            ['first_name' => 'Rəşad', 'last_name' => 'Hüseynov', 'phone' => '+994501110007', 'email' => 'resad@demo.az', 'address' => 'Bakı, Suraxanı r., Hövsan qəs.', 'lat' => 40.4280, 'lng' => 50.0100],
            ['first_name' => 'Aynur', 'last_name' => 'Şıxəliyeva', 'phone' => '+994501110008', 'email' => 'aynur@demo.az', 'address' => 'Sumqayıt, 10-cu mkr., bl. 15', 'lat' => 40.5890, 'lng' => 49.6320],
            ['first_name' => 'Elvin', 'last_name' => 'Nəsirov', 'phone' => '+994501110009', 'email' => 'elvin@demo.az', 'address' => 'Bakı, Nizami r., 2-ci Alatava küç.', 'lat' => 40.3810, 'lng' => 49.8530],
            ['first_name' => 'Səbinə', 'last_name' => 'Rəhimova', 'phone' => '+994501110010', 'email' => 'sebine@demo.az', 'address' => 'Bakı, Xəzər r., Mərdəkan qəs.', 'lat' => 40.4960, 'lng' => 50.1480],
        ];

        foreach ($clientData as $cd) {
            $user = User::create([
                'first_name' => $cd['first_name'],
                'last_name' => $cd['last_name'],
                'phone' => $cd['phone'],
                'email' => $cd['email'],
                'password' => $password,
                'role' => 'client',
            ]);
            Address::create([
                'user_id' => $user->id,
                'label' => 'Ev',
                'full_address' => $cd['address'],
                'lat' => $cd['lat'],
                'lng' => $cd['lng'],
                'is_default' => true,
            ]);
            $clients[] = $user;
        }

        // ===== 10 MASTERS =====
        $masters = [];
        $masterData = [
            ['first_name' => 'Kamran', 'last_name' => 'Əsgərov', 'phone' => '+994552220001', 'email' => 'kamran@demo.az', 'desc' => '12 illik təcrübəli santexnik. Hər növ boru və kanalizasiya işləri.', 'exp' => 12, 'city' => 'Bakı', 'district' => 'Nəsimi', 'cats' => ['santexnik'], 'lat' => 40.4093, 'lng' => 49.8671, 'rating' => 4.9, 'orders' => 87],
            ['first_name' => 'Vüqar', 'last_name' => 'Muradov', 'phone' => '+994552220002', 'email' => 'vuqar@demo.az', 'desc' => 'Peşəkar elektrik ustası. Lisenziyalı, təhlükəsiz iş.', 'exp' => 8, 'city' => 'Bakı', 'district' => 'Yasamal', 'cats' => ['elektrik'], 'lat' => 40.3920, 'lng' => 49.8410, 'rating' => 4.7, 'orders' => 65],
            ['first_name' => 'Nihad', 'last_name' => 'Babayev', 'phone' => '+994552220003', 'email' => 'nihad@demo.az', 'desc' => 'Metal qaynaq və konstruksiya işləri. Arqon, yarıavtomat qaynağı.', 'exp' => 15, 'city' => 'Bakı', 'district' => 'Xətai', 'cats' => ['qaynaqci'], 'lat' => 40.3970, 'lng' => 49.8790, 'rating' => 4.8, 'orders' => 43],
            ['first_name' => 'Sənan', 'last_name' => 'Kərimov', 'phone' => '+994552220004', 'email' => 'senan@demo.az', 'desc' => 'Hər növ mebel yığımı və sökülməsi. IKEA, bellona və s.', 'exp' => 5, 'city' => 'Bakı', 'district' => 'Binəqədi', 'cats' => ['mebel-yigimi', 'usta-saati'], 'lat' => 40.4480, 'lng' => 49.8320, 'rating' => 4.6, 'orders' => 120],
            ['first_name' => 'Elşən', 'last_name' => 'Əhmədov', 'phone' => '+994552220005', 'email' => 'elshan@demo.az', 'desc' => 'Boyama, dekorativ suvaq, oboy yapışdırma. 10 il təcrübə.', 'exp' => 10, 'city' => 'Bakı', 'district' => 'Nərimanov', 'cats' => ['rengleme', 'suvaq', 'divar-kagizi'], 'lat' => 40.4140, 'lng' => 49.8690, 'rating' => 4.5, 'orders' => 95],
            ['first_name' => 'Fərid', 'last_name' => 'Rzayev', 'phone' => '+994552220006', 'email' => 'ferid@demo.az', 'desc' => 'Kondisioner quraşdırma, təmizləmə, freon doldurma.', 'exp' => 7, 'city' => 'Bakı', 'district' => 'Səbail', 'cats' => ['kondisioner'], 'lat' => 40.3670, 'lng' => 49.8350, 'rating' => 4.8, 'orders' => 156],
            ['first_name' => 'Rauf', 'last_name' => 'Quliyev', 'phone' => '+994552220007', 'email' => 'rauf@demo.az', 'desc' => 'Qıfıl açma, dəyişmə, domofon quraşdırma. 24/7 xidmət.', 'exp' => 9, 'city' => 'Bakı', 'district' => 'Nizami', 'cats' => ['cilinger'], 'lat' => 40.3830, 'lng' => 49.8560, 'rating' => 4.9, 'orders' => 210],
            ['first_name' => 'Cavid', 'last_name' => 'Nəcəfov', 'phone' => '+994552220008', 'email' => 'cavid@demo.az', 'desc' => 'Kafel, plitka, laminat döşəmə işləri. Dəqiq və keyfiyyətli.', 'exp' => 11, 'city' => 'Bakı', 'district' => 'Suraxanı', 'cats' => ['kafel', 'laminat'], 'lat' => 40.4300, 'lng' => 50.0050, 'rating' => 4.7, 'orders' => 78],
            ['first_name' => 'Tamerlan', 'last_name' => 'Sadıqov', 'phone' => '+994552220009', 'email' => 'tamerlan@demo.az', 'desc' => 'Kombi, radiator, su qızdırıcı quraşdırma və təmiri.', 'exp' => 6, 'city' => 'Bakı', 'district' => 'Xəzər', 'cats' => ['kombi'], 'lat' => 40.5000, 'lng' => 50.1400, 'rating' => 4.4, 'orders' => 34],
            ['first_name' => 'Zaur', 'last_name' => 'Həsənli', 'phone' => '+994552220010', 'email' => 'zaur@demo.az', 'desc' => 'Kamera, siqnalizasiya, internet şəbəkə quraşdırma.', 'exp' => 4, 'city' => 'Bakı', 'district' => 'Nəsimi', 'cats' => ['kamera', 'internet'], 'lat' => 40.4050, 'lng' => 49.8600, 'rating' => 4.6, 'orders' => 52],
        ];

        foreach ($masterData as $md) {
            $user = User::create([
                'first_name' => $md['first_name'],
                'last_name' => $md['last_name'],
                'phone' => $md['phone'],
                'email' => $md['email'],
                'password' => $password,
                'role' => 'master',
                'rating_avg' => $md['rating'],
                'rating_count' => $md['orders'],
            ]);

            $profile = MasterProfile::create([
                'user_id' => $user->id,
                'description' => $md['desc'],
                'experience_years' => $md['exp'],
                'status' => 'online',
                'is_accepting_orders' => true,
                'is_verified' => true,
                'city' => $md['city'],
                'district' => $md['district'],
                'transport_type' => 'car',
                'urgent_available' => true,
                'work_radius_km' => 25,
                'languages' => 'az,ru',
                'current_lat' => $md['lat'],
                'current_lng' => $md['lng'],
                'location_updated_at' => now(),
                'verified_at' => now()->subMonths(rand(1, 12)),
                'completed_orders_count' => $md['orders'],
            ]);

            foreach ($md['cats'] as $catSlug) {
                $cat = $categories->firstWhere('slug', $catSlug);
                if ($cat) {
                    MasterCategory::create([
                        'master_profile_id' => $profile->id,
                        'category_id' => $cat->id,
                    ]);
                }
            }

            $masters[] = $user;
        }

        // ===== ORDERS =====
        $statuses = [
            // 5 completed orders
            ['status' => 'closed', 'with_review' => true],
            ['status' => 'closed', 'with_review' => true],
            ['status' => 'closed', 'with_review' => true],
            ['status' => 'completed', 'with_review' => true],
            ['status' => 'completed', 'with_review' => true],
            // 3 active orders in various stages
            ['status' => 'searching_master', 'with_review' => false],
            ['status' => 'accepted', 'with_review' => false],
            ['status' => 'on_the_way', 'with_review' => false],
            ['status' => 'in_progress', 'with_review' => false],
            // 1 canceled
            ['status' => 'canceled_by_client', 'with_review' => false],
        ];

        $descriptions = [
            'Mətbəxdə kran axır, dəyişmək lazımdır.',
            'Qonaq otağında 3 rozetka quraşdırmaq lazımdır.',
            'Balkon qapısının qaynağı tökülüb, bərpa etmək lazımdır.',
            'IKEA şkafı yığmaq lazımdır, hissələr hazırdır.',
            'Mətbəxdə divarları boyamaq lazımdır, 15 kv.m.',
            'Yataq otağında kondisioner quraşdırmaq, split sistem.',
            'Giriş qapısının qıfılı xarab olub, dəyişmək lazımdır.',
            'Hamamda kafel döşəmək, 8 kv.m.',
            'Kombi işləmir, yanmır. Baxi marka.',
            'Evdə 4 kamera quraşdırmaq lazımdır.',
        ];

        $addresses = [
            'Bakı, Nəsimi r., Təbriz küç. 14',
            'Bakı, Yasamal r., Şərifzadə küç. 88',
            'Bakı, Xətai r., M.Hadi küç. 30',
            'Bakı, Binəqədi r., 7-ci mkr., bl. 22',
            'Bakı, Nərimanov r., Əliyar Əliyev küç. 5',
            'Bakı, Səbail r., R.Behbudov küç. 10',
            'Bakı, Nizami r., Hüseyn Cavid pr. 44',
            'Bakı, Suraxanı r., Yeni Günəşli, bl. 9',
            'Bakı, Xəzər r., Şüvəlan qəs.',
            'Bakı, Nəsimi r., 28 May küç. 16',
        ];

        for ($i = 0; $i < 10; $i++) {
            $client = $clients[$i];
            $master = $masters[$i % count($masters)];
            $cat = $categories->random();
            $s = $statuses[$i];
            $daysAgo = $s['status'] === 'closed' ? rand(5, 30) : ($s['status'] === 'completed' ? rand(1, 4) : 0);
            $createdAt = now()->subDays($daysAgo)->subHours(rand(0, 12));

            $orderData = [
                'client_id' => $client->id,
                'category_id' => $cat->id,
                'description' => $descriptions[$i],
                'full_address' => $addresses[$i],
                'lat' => $client->addresses->first()->lat ?? 40.4093,
                'lng' => $client->addresses->first()->lng ?? 49.8671,
                'contact_phone' => $client->phone,
                'desired_time' => 'asap',
                'urgency' => $i % 3 === 0 ? 'urgent' : 'normal',
                'status' => $s['status'],
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ];

            // Assign master for non-searching statuses
            if ($s['status'] !== 'searching_master') {
                $orderData['master_id'] = $master->id;
                $orderData['accepted_at'] = $createdAt->copy()->addMinutes(rand(2, 10));
            }

            if (in_array($s['status'], ['on_the_way', 'arrived', 'in_progress', 'completed', 'closed'])) {
                $orderData['on_the_way_at'] = $createdAt->copy()->addMinutes(rand(11, 15));
            }
            if (in_array($s['status'], ['arrived', 'in_progress', 'completed', 'closed'])) {
                $orderData['arrived_at'] = $createdAt->copy()->addMinutes(rand(20, 35));
            }
            if (in_array($s['status'], ['in_progress', 'completed', 'closed'])) {
                $orderData['started_at'] = $createdAt->copy()->addMinutes(rand(36, 45));
            }
            if (in_array($s['status'], ['completed', 'closed'])) {
                $orderData['completed_at'] = $createdAt->copy()->addHours(rand(1, 3));
            }
            if ($s['status'] === 'closed') {
                $orderData['closed_at'] = $createdAt->copy()->addHours(rand(4, 24));
                $orderData['client_reviewed'] = true;
                $orderData['master_reviewed'] = true;
            }
            if ($s['status'] === 'canceled_by_client') {
                $orderData['canceled_at'] = $createdAt->copy()->addMinutes(rand(5, 20));
                $orderData['cancel_reason'] = 'Ehtiyac aradan qalxdı';
            }

            $order = Order::create($orderData);

            // Status history
            $order->logStatus('new', $client->id);
            $order->logStatus('searching_master', $client->id);

            if ($s['status'] !== 'searching_master') {
                $order->logStatus('accepted', $master->id);
            }
            if (in_array($s['status'], ['on_the_way', 'arrived', 'in_progress', 'completed', 'closed'])) {
                $order->logStatus('on_the_way', $master->id);
            }
            if (in_array($s['status'], ['arrived', 'in_progress', 'completed', 'closed'])) {
                $order->logStatus('arrived', $master->id);
            }
            if (in_array($s['status'], ['in_progress', 'completed', 'closed'])) {
                $order->logStatus('in_progress', $master->id);
            }
            if (in_array($s['status'], ['completed', 'closed'])) {
                $order->logStatus('completed', $master->id);
            }
            if ($s['status'] === 'closed') {
                $order->logStatus('closed', $client->id);
            }
            if ($s['status'] === 'canceled_by_client') {
                $order->logStatus('canceled_by_client', $client->id);
            }

            // Reviews for completed/closed
            if ($s['with_review']) {
                $clientRating = rand(4, 5);
                $masterRating = rand(4, 5);

                $clientReviewTexts = [
                    'Əla usta, çox minnətdaram!',
                    'Keyfiyyətli iş gördü, vaxtında gəldi.',
                    'Çox peşəkar, tövsiyə edirəm.',
                    'Yaxşı iş gördü, amma bir az gecikdi.',
                    'Mükəmməl nəticə, təşəkkür edirəm.',
                ];
                $masterReviewTexts = [
                    'Yaxşı müştəri, problem dəqiq təsvir edilmişdi.',
                    'Əlaqədə idi, rahat iş mühiti.',
                    'Vaxtında gözləyirdi, ödəniş problemsiz.',
                    'Normal müştəri.',
                    'Çox nəzakətli, minnətdaram.',
                ];

                Review::create([
                    'order_id' => $order->id,
                    'reviewer_id' => $client->id,
                    'reviewee_id' => $master->id,
                    'rating' => $clientRating,
                    'text' => $clientReviewTexts[array_rand($clientReviewTexts)],
                    'tags' => ['quality', 'punctual'],
                ]);

                Review::create([
                    'order_id' => $order->id,
                    'reviewer_id' => $master->id,
                    'reviewee_id' => $client->id,
                    'rating' => $masterRating,
                    'text' => $masterReviewTexts[array_rand($masterReviewTexts)],
                    'tags' => ['responsive', 'polite'],
                ]);

                // Chat messages for some orders
                if ($i < 5) {
                    ChatMessage::create(['order_id' => $order->id, 'sender_id' => $client->id, 'text' => 'Salam, nə vaxt gələ bilərsiniz?', 'created_at' => $createdAt->copy()->addMinutes(3)]);
                    ChatMessage::create(['order_id' => $order->id, 'sender_id' => $master->id, 'text' => 'Salam, 15-20 dəqiqəyə orada olacam.', 'created_at' => $createdAt->copy()->addMinutes(5)]);
                    ChatMessage::create(['order_id' => $order->id, 'sender_id' => $client->id, 'text' => 'Yaxşı, gözləyirəm.', 'created_at' => $createdAt->copy()->addMinutes(6)]);
                }
            }
        }

        echo "Created: 10 clients, 10 masters, 10 orders with reviews & chat\n";
    }
}
