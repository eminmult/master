<?php

namespace Tests\Unit;

use App\Models\User;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;

class SubscriptionGateTest extends TestCase
{
    public function test_master_passes_when_subscription_not_required(): void
    {
        Config::set('master.subscription_required', false);
        $u = new User(['role' => 'master', 'is_active' => true, 'subscription_active' => false]);
        $this->assertTrue($u->canOperateAsMaster());
    }

    public function test_master_fails_when_required_and_inactive(): void
    {
        Config::set('master.subscription_required', true);
        $u = new User(['role' => 'master', 'is_active' => true, 'subscription_active' => false]);
        $this->assertFalse($u->canOperateAsMaster());
    }

    public function test_master_fails_when_subscription_expired(): void
    {
        Config::set('master.subscription_required', true);
        $u = new User([
            'role' => 'master',
            'is_active' => true,
            'subscription_active' => true,
            'subscription_expires_at' => now()->subDay(),
        ]);
        $u->subscription_expires_at = now()->subDay();
        $this->assertFalse($u->canOperateAsMaster());
    }

    public function test_client_does_not_operate_as_master(): void
    {
        Config::set('master.subscription_required', false);
        $u = new User(['role' => 'client', 'is_active' => true]);
        $this->assertFalse($u->canOperateAsMaster());
    }

    public function test_inactive_user_cannot_operate(): void
    {
        Config::set('master.subscription_required', false);
        $u = new User(['role' => 'master', 'is_active' => false, 'subscription_active' => true]);
        $this->assertFalse($u->canOperateAsMaster());
    }
}
