<?php

namespace Database\Seeders;

use App\Models\MasterProfile;
use App\Models\MasterWorkHour;
use App\Models\PortfolioItem;
use App\Models\Review;
use App\Models\User;
use App\Models\VerificationDocument;
use Illuminate\Database\Seeder;

class MasterEnrichSeeder extends Seeder
{
    public function run(): void
    {
        $masters = User::where('role', 'master')->with('masterProfile')->get();
        $clients = User::where('role', 'client')->get();

        if ($clients->isEmpty() || $masters->isEmpty()) {
            echo "No clients or masters found\n";
            return;
        }

        // Portfolio descriptions per category style
        $portfolioDescriptions = [
            'Mətbəxdə kran dəyişdirilməsi — köhnə kran sökülüb yeni GROHE kran quraşdırılıb.',
            'Hamamda tam boru sistemi yenilənməsi — polipropilen borular.',
            'Qonaq otağında 5 rozetka və 3 açar quraşdırılması.',
            'Mətbəxdə LED lampa sistemi quraşdırılması.',
            'Balkon metalının qaynaq ilə bərpası.',
            'Giriş qapısı üçün metal çərçivə hazırlanması.',
            'IKEA PAX şkafının yığılması — 3 metrlik.',
            'Uşaq otağında çarpayı və yazı masası yığılması.',
            'Qonaq otağında dekorativ suvaq — venetsian üsulu.',
            'Mətbəx divarlarının boyama işi — 20 kvm.',
            'Split kondisionerin quraşdırılması — 3-cü mərtəbə.',
            'Kondisionerin təmizlənməsi və freon doldurulması.',
            'Giriş qapısının qıfılının dəyişdirilməsi — KALE marka.',
            'Seyf qıfılının açılması və dəyişdirilməsi.',
            'Hamamda kafel döşənməsi — 12 kvm italyan kafel.',
            'Mətbəxdə fartuk kafeli — mozaika üsulu.',
            'Laminat döşənməsi — 45 kvm qonaq otağı + yataq otağı.',
            'Kombi təmiri — Baxi marka, istilik mübadiləcisi dəyişdirildi.',
            'Radiator sistemi quraşdırılması — 6 radiator.',
            'Evdə 8 kamera sistemi quraşdırılması — Hikvision.',
            'Ofisdə internet şəbəkəsi çəkilməsi — 12 nöqtə.',
            'Paltaryuyan maşının təmiri — su nasosu dəyişdirildi.',
            'Soyuducunun təmiri — kompressor dəyişdirildi.',
            'Plastik pəncərənin dəyişdirilməsi — 3 pəncərə.',
            'Hamam və tualetin tam təmiri — kafel, santexnika, elektrik.',
            'Evin tam elektrik xəttinin yenilənməsi — 3 otaqlı mənzil.',
            'Həyətdə qazon döşənməsi — 100 kvm.',
            'Mətbəx mebeli yığımı — sifarişlə hazırlanmış mebel.',
            'Ofisdə asma tavan quraşdırılması — Armstrong.',
            'Evin fasadının boyama işi — 3 mərtəbəli villa.',
        ];

        // Review texts from clients
        $reviewTexts = [
            5 => [
                'Əla usta! Çox peşəkar və vaxtında gəldi. Mütləq tövsiyə edirəm.',
                'Mükəmməl iş! Hər şey dəqiq və keyfiyyətli oldu.',
                'Çox minnətdaram, gözlədiyimdən yaxşı oldu!',
                'Super usta, işini bilir. Təmiz və səliqəli iş.',
                'Ən yaxşı usta ilə işləmişəm. 5 ulduz az belə.',
                'İnanılmaz keyfiyyət! Qonşulara da tövsiyə etdim.',
                'Hər şey əladır, qiymət də münasib idi.',
                'Peşəkar, nəzakətli, vaxtında. Nə istəsən.',
            ],
            4 => [
                'Yaxşı iş gördü, amma bir az gecikdi.',
                'Ümumiyyətlə razıyam, keyfiyyətli işdir.',
                'Normal usta, işini bilir. Bir-iki kiçik qüsur olsa da düzəltdi.',
                'Qiymət bir az yüksək idi, amma iş keyfiyyətli.',
                'Yaxşıdır, tövsiyə edirəm. Sadəcə materialları özüm aldım.',
                'İş gözəl alındı, amma vaxt bir az çox çəkdi.',
            ],
            3 => [
                'Orta səviyyədə, daha yaxşı ola bilərdi.',
                'İş gördü amma bəzi yerləri bəyənmədim.',
            ],
        ];

        // Review tags
        $tagSets = [
            ['quality', 'punctual', 'polite'],
            ['quality', 'professional'],
            ['punctual', 'clean_work'],
            ['polite', 'fair_price'],
            ['quality', 'punctual', 'professional', 'clean_work'],
            ['professional', 'polite'],
            ['quality', 'fair_price'],
            ['punctual', 'polite', 'quality'],
        ];

        // Client review texts (master about client)
        $masterReviewTexts = [
            5 => [
                'Əla müştəri, problem dəqiq təsvir edilmişdi. Rahat iş mühiti.',
                'Çox nəzakətli müştəri, ödəniş problemsiz oldu.',
                'Yaxşı müştəri, vaxtında gözləyirdi.',
                'Mükəmməl əməkdaşlıq, minnətdaram.',
            ],
            4 => [
                'Normal müştəri, əlaqədə idi.',
                'Yaxşı müştəri, amma ünvanı tapmaqda çətinlik oldu.',
                'Ödəniş problemsiz, normal iş mühiti.',
            ],
        ];

        $addedReviews = 0;
        $addedPortfolio = 0;
        $addedWorkHours = 0;
        $addedDocs = 0;

        foreach ($masters as $master) {
            $profile = $master->masterProfile;
            if (!$profile) continue;

            // === PORTFOLIO (3-6 items per master) ===
            $portfolioCount = rand(3, 6);
            $usedDescs = [];
            for ($p = 0; $p < $portfolioCount; $p++) {
                $desc = $portfolioDescriptions[array_rand($portfolioDescriptions)];
                if (in_array($desc, $usedDescs)) continue;
                $usedDescs[] = $desc;

                PortfolioItem::create([
                    'master_profile_id' => $profile->id,
                    'image_url' => '/placeholder-work-' . rand(1, 10) . '.jpg',
                    'description' => $desc,
                ]);
                $addedPortfolio++;
            }

            // === WORK HOURS (Mon-Sat) ===
            $startHour = rand(8, 10);
            $endHour = rand(18, 21);
            for ($day = 0; $day <= 5; $day++) { // Mon-Sat
                MasterWorkHour::firstOrCreate([
                    'master_profile_id' => $profile->id,
                    'day_of_week' => $day,
                ], [
                    'start_time' => sprintf('%02d:00', $startHour),
                    'end_time' => sprintf('%02d:00', $endHour),
                ]);
                $addedWorkHours++;
            }

            // === VERIFICATION DOCS (2-3 per master) ===
            $docTypes = ['photo', 'certificate', 'id_document'];
            shuffle($docTypes);
            $docsCount = rand(2, 3);
            for ($d = 0; $d < $docsCount; $d++) {
                VerificationDocument::firstOrCreate([
                    'master_profile_id' => $profile->id,
                    'type' => $docTypes[$d],
                ], [
                    'url' => '/placeholder-doc-' . $docTypes[$d] . '.jpg',
                    'status' => 'approved',
                    'reviewed_at' => now()->subDays(rand(10, 90)),
                ]);
                $addedDocs++;
            }

            // === REVIEWS (5-15 per master from random clients) ===
            $existingReviewCount = Review::where('reviewee_id', $master->id)->count();
            $targetReviews = rand(5, 15);
            $newReviews = max(0, $targetReviews - $existingReviewCount);

            $shuffledClients = $clients->shuffle();

            for ($r = 0; $r < $newReviews && $r < $shuffledClients->count(); $r++) {
                $client = $shuffledClients[$r];

                // Check if this client already reviewed this master (without order)
                $exists = Review::where('reviewer_id', $client->id)
                    ->where('reviewee_id', $master->id)
                    ->exists();
                if ($exists) continue;

                // Find an order between them, or create a closed one
                $order = \App\Models\Order::where('client_id', $client->id)
                    ->where('master_id', $master->id)
                    ->whereIn('status', ['completed', 'closed'])
                    ->whereDoesntHave('reviews', fn($q) => $q->where('reviewer_id', $client->id))
                    ->first();

                if (!$order) {
                    // Create a synthetic closed order
                    $cat = $profile->masterCategories()->first();
                    $address = $client->addresses()->first();
                    $daysAgo = rand(7, 120);

                    $order = \App\Models\Order::create([
                        'client_id' => $client->id,
                        'master_id' => $master->id,
                        'category_id' => $cat ? $cat->category_id : 1,
                        'description' => 'Təmir işi',
                        'full_address' => $address ? $address->full_address : 'Bakı',
                        'lat' => $address->lat ?? 40.4093,
                        'lng' => $address->lng ?? 49.8671,
                        'contact_phone' => $client->phone,
                        'desired_time' => 'asap',
                        'urgency' => 'normal',
                        'status' => 'closed',
                        'client_reviewed' => true,
                        'master_reviewed' => true,
                        'accepted_at' => now()->subDays($daysAgo)->addMinutes(5),
                        'on_the_way_at' => now()->subDays($daysAgo)->addMinutes(10),
                        'arrived_at' => now()->subDays($daysAgo)->addMinutes(25),
                        'started_at' => now()->subDays($daysAgo)->addMinutes(30),
                        'completed_at' => now()->subDays($daysAgo)->addHours(2),
                        'closed_at' => now()->subDays($daysAgo)->addHours(3),
                        'created_at' => now()->subDays($daysAgo),
                        'updated_at' => now()->subDays($daysAgo)->addHours(3),
                    ]);
                }

                // Client → Master review
                $rating = $this->weightedRating();
                $texts = $reviewTexts[$rating] ?? $reviewTexts[4];
                Review::create([
                    'order_id' => $order->id,
                    'reviewer_id' => $client->id,
                    'reviewee_id' => $master->id,
                    'rating' => $rating,
                    'text' => $texts[array_rand($texts)],
                    'tags' => $tagSets[array_rand($tagSets)],
                    'created_at' => $order->completed_at ?? now()->subDays(rand(1, 60)),
                ]);

                // Master → Client review
                $mRating = rand(4, 5);
                $mTexts = $masterReviewTexts[$mRating] ?? $masterReviewTexts[4];
                Review::firstOrCreate([
                    'order_id' => $order->id,
                    'reviewer_id' => $master->id,
                ], [
                    'reviewee_id' => $client->id,
                    'rating' => $mRating,
                    'text' => $mTexts[array_rand($mTexts)],
                    'tags' => ['responsive', 'polite'],
                    'created_at' => $order->completed_at ?? now()->subDays(rand(1, 60)),
                ]);

                $addedReviews++;
            }

            // Recalculate rating
            $master->recalculateRating();

            // Update completed orders count
            $completedCount = \App\Models\Order::where('master_id', $master->id)
                ->whereIn('status', ['completed', 'closed'])
                ->count();
            $profile->update(['completed_orders_count' => $completedCount]);
        }

        // Recalculate client ratings too
        foreach ($clients as $client) {
            $client->recalculateRating();
        }

        echo "Portfolio items: +{$addedPortfolio}\n";
        echo "Work hours: +{$addedWorkHours}\n";
        echo "Verification docs: +{$addedDocs}\n";
        echo "Reviews: +{$addedReviews}\n";
        echo "Ratings recalculated for all users\n";
    }

    private function weightedRating(): int
    {
        $roll = rand(1, 100);
        if ($roll <= 55) return 5;   // 55%
        if ($roll <= 85) return 4;   // 30%
        return 3;                     // 15%
    }
}
