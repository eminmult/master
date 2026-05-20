<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Replace Material Symbols names with Phosphor (via Iconify).
 * Format: "ph:<name>" — rendered by frontend <CatIcon> component.
 * Down(): restore Material Symbols defaults.
 */
return new class extends Migration
{
    public function up(): void
    {
        // slug => Phosphor icon (regular outline style — ph:<name>)
        $map = [
            'santexnik'       => 'ph:wrench',
            'elektrik'        => 'ph:lightning',
            'qaynaqci'        => 'ph:flame',
            'usta-saati'      => 'ph:toolbox',
            'mebel-yigimi'    => 'ph:armchair',
            'rengleme'        => 'ph:paint-roller',
            'kondisioner'     => 'ph:snowflake',
            'cilinger'        => 'ph:lock-key',
            'temizlik'        => 'ph:broom',
            'suvaq'           => 'ph:paint-brush-broad',
            'kafel'           => 'ph:grid-four',
            'laminat'         => 'ph:stack',
            'divar-kagizi'    => 'ph:wall',
            'perde'           => 'ph:list-dashes',
            'kombi'           => 'ph:fire',
            'texnika-temir'   => 'ph:washing-machine',
            'soyuducu'        => 'ph:fridge',  // may fallback — ok
            'tv-antenna'      => 'ph:television-simple',
            'kamera'          => 'ph:security-camera',
            'internet'        => 'ph:wifi-high',
            'komputer'        => 'ph:desktop',
            'bagcivan'        => 'ph:plant',
            'zeresizlesdirme' => 'ph:bug-beetle',
            'dasinma'         => 'ph:truck',
            'pencere-qapi'    => 'ph:door',
            'dam'             => 'ph:house-simple',
            'hovuz'           => 'ph:swimming-pool',
            'lift'            => 'ph:elevator',
            // second batch (added in earlier migration)
            'gips-karton'     => 'ph:square-half-bottom',
            'sokme'           => 'ph:hammer',
            'germe-tavan'     => 'ph:squares-four',
            'sushelemе'       => 'ph:frame-corners', // window-like frame
            'balkon'          => 'ph:buildings',
            'dizayn'          => 'ph:palette',
            'isiqlandirma'    => 'ph:lightbulb',
            'smart-ev'        => 'ph:house-line',
            'hamam'           => 'ph:bathtub',
            'izolyasiya'      => 'ph:thermometer',
            'su-qizdirici'    => 'ph:drop-half-bottom',
            'mikrodalga'      => 'ph:microwave',
            'pec'             => 'ph:flame',
            'tozsoran'        => 'ph:fan',
            'tikis-masini'    => 'ph:needle',
            'telefon'         => 'ph:device-mobile',
            'printer'         => 'ph:printer',
            'planset'         => 'ph:device-tablet',
            'ref-quraşdırma'  => 'ph:frame-corners',
            'jaluz'           => 'ph:list-bullets',
            'guzgu'           => 'ph:rectangle',
            'kanalizasiya'    => 'ph:drop',
            'sizinti'         => 'ph:magnifying-glass',
            'qazon'           => 'ph:leaf',
            'landsaft'        => 'ph:mountains',
            'hasar'           => 'ph:bricks',
            'asfalt'          => 'ph:road-horizon',
            'qar'             => 'ph:snowflake',
            'agac-budama'     => 'ph:tree',
            'avto-usta'       => 'ph:car',
            'teker'           => 'ph:steering-wheel',
            'avtoyuma'        => 'ph:sparkle',
            'kuryer'          => 'ph:package',
            'usaq-baxicisi'   => 'ph:baby',
            'petsitting'      => 'ph:dog',
            'fotoqraf'        => 'ph:camera',
            'repetitor'       => 'ph:books',
            'berber'          => 'ph:scissors',
            'manikur'         => 'ph:paint-brush',
            'xalca-yuma'      => 'ph:wind',
            'mebel-berpasi'   => 'ph:couch',
            'piano'           => 'ph:piano-keys',
            'tedbir'          => 'ph:confetti',
        ];

        foreach ($map as $slug => $icon) {
            DB::table('categories')->where('slug', $slug)->update(['icon_url' => $icon]);
        }
    }

    public function down(): void
    {
        $revert = [
            'santexnik'       => 'plumbing',
            'elektrik'        => 'electric_bolt',
            'qaynaqci'        => 'hardware',
            'usta-saati'      => 'handyman',
            'mebel-yigimi'    => 'chair',
            'rengleme'        => 'format_paint',
            'kondisioner'     => 'ac_unit',
            'cilinger'        => 'lock',
            'temizlik'        => 'cleaning_services',
            'suvaq'           => 'wall_art',
            'kafel'           => 'grid_view',
            'laminat'         => 'layers',
            'divar-kagizi'    => 'wallpaper',
            'perde'           => 'curtains',
            'kombi'           => 'local_fire_department',
            'texnika-temir'   => 'local_laundry_service',
            'soyuducu'        => 'kitchen',
            'tv-antenna'      => 'tv',
            'kamera'          => 'videocam',
            'internet'        => 'wifi',
            'komputer'        => 'computer',
            'bagcivan'        => 'grass',
            'zeresizlesdirme' => 'pest_control',
            'dasinma'         => 'local_shipping',
            'pencere-qapi'    => 'door_front',
            'dam'             => 'roofing',
            'hovuz'           => 'pool',
            'lift'            => 'elevator',
        ];
        foreach ($revert as $slug => $icon) {
            DB::table('categories')->where('slug', $slug)->update(['icon_url' => $icon]);
        }
    }
};
