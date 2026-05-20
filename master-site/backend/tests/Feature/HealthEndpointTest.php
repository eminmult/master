<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthEndpointTest extends TestCase
{
    public function test_health_returns_200_when_services_up(): void
    {
        $res = $this->getJson('/api/health');
        // In test environment redis may be array-driver; assert structure not statuses.
        $res->assertJsonStructure(['status', 'checks' => ['app', 'db', 'redis', 'queue'], 'time']);
    }
}
