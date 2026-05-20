<?php

namespace Tests\Unit;

use App\Services\ChatTextSanitizer;
use PHPUnit\Framework\TestCase;

class ChatTextSanitizerTest extends TestCase
{
    public function test_passes_clean_text_through(): void
    {
        $r = ChatTextSanitizer::sanitize('Salam, sabah saat 10-da gəlim?');
        $this->assertFalse($r['flagged']);
        $this->assertSame('Salam, sabah saat 10-da gəlim?', $r['clean']);
    }

    public function test_masks_local_phone_number(): void
    {
        $r = ChatTextSanitizer::sanitize('Zəng et: +994 50 123 45 67');
        $this->assertTrue($r['flagged']);
        $this->assertContains('phone', $r['reasons']);
        $this->assertStringNotContainsString('994', $r['clean']);
        $this->assertStringContainsString('[•••]', $r['clean']);
    }

    public function test_masks_email(): void
    {
        $r = ChatTextSanitizer::sanitize('Yazın: usta@gmail.com');
        $this->assertTrue($r['flagged']);
        $this->assertContains('email', $r['reasons']);
        $this->assertStringNotContainsString('usta@gmail.com', $r['clean']);
    }

    public function test_masks_telegram_handle(): void
    {
        $r = ChatTextSanitizer::sanitize('Telegram: @master_az_2024');
        $this->assertTrue($r['flagged']);
        $this->assertContains('handle', $r['reasons']);
    }

    public function test_masks_whatsapp_link(): void
    {
        $r = ChatTextSanitizer::sanitize('https://wa.me/994501234567 yazın');
        $this->assertTrue($r['flagged']);
    }

    public function test_short_digits_are_not_phone(): void
    {
        $r = ChatTextSanitizer::sanitize('Saat 10-da, qiymət 50 manat');
        $this->assertFalse($r['flagged']);
    }

    public function test_handles_null_text(): void
    {
        $r = ChatTextSanitizer::sanitize(null);
        $this->assertFalse($r['flagged']);
        $this->assertNull($r['clean']);
    }

    public function test_apply_mask_false_returns_original(): void
    {
        $r = ChatTextSanitizer::sanitize('Telefon: 0501234567', false);
        $this->assertTrue($r['flagged']);
        $this->assertSame('Telefon: 0501234567', $r['clean']);
    }
}
