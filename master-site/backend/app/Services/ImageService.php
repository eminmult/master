<?php

namespace App\Services;

use Illuminate\Support\Facades\Storage;

class ImageService
{
    // 3 sizes: thumb (150), medium (600), large (1200)
    const SIZES = [
        'thumb' => 150,
        'medium' => 600,
        'large' => 1200,
    ];

    /**
     * Process base64 image → 3 WebP sizes
     * Returns array of URLs ['thumb' => '...', 'medium' => '...', 'large' => '...']
     */
    // Accepted image MIME types
    const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

    public static function processBase64(string $base64, string $folder = 'uploads'): array
    {
        // Size check: max 5MB base64 ≈ 6.6MB string
        if (strlen($base64) > 7 * 1024 * 1024) return [];

        // Decode base64
        $data = $base64;
        if (str_contains($data, ',')) {
            $data = explode(',', $data)[1];
        }
        $binary = base64_decode($data, true);
        if (!$binary) return [];

        // Hard MIME check via finfo — rejects PDFs, scripts, etc. that can pass a naive GD check
        if (function_exists('finfo_buffer')) {
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $mime = $finfo ? finfo_buffer($finfo, $binary) : null;
            if ($finfo) finfo_close($finfo);
            if (!$mime || !in_array($mime, self::ALLOWED_MIMES, true)) return [];
        }

        // Check actual image dimensions; catches malformed / oversized files
        $info = @getimagesizefromstring($binary);
        if (!$info || $info[0] < 8 || $info[1] < 8) return [];
        if ($info[0] > 8000 || $info[1] > 8000) return [];

        $source = @imagecreatefromstring($binary);
        if (!$source) return [];

        $origW = imagesx($source);
        $origH = imagesy($source);
        $basename = uniqid() . '_' . time();
        $urls = [];

        foreach (self::SIZES as $name => $maxSize) {
            // Calculate new dimensions
            $ratio = min($maxSize / $origW, $maxSize / $origH, 1);
            $newW = (int) round($origW * $ratio);
            $newH = (int) round($origH * $ratio);

            // Resize
            $resized = imagecreatetruecolor($newW, $newH);
            // Preserve transparency
            imagealphablending($resized, false);
            imagesavealpha($resized, true);
            imagecopyresampled($resized, $source, 0, 0, 0, 0, $newW, $newH, $origW, $origH);

            // Save as WebP
            $filename = "{$folder}/{$basename}_{$name}.webp";
            $tmpPath = tempnam(sys_get_temp_dir(), 'img');
            imagewebp($resized, $tmpPath, 85);
            imagedestroy($resized);

            Storage::disk('public')->put($filename, file_get_contents($tmpPath));
            unlink($tmpPath);

            $urls[$name] = '/storage/' . $filename;
        }

        imagedestroy($source);

        return $urls;
    }
}
