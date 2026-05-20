<?php

use Illuminate\Support\Facades\Broadcast;

/*
 * Per-user private channel for in-app calls and other realtime notifications.
 * Subscription is authorized via Sanctum: `/broadcasting/auth` checks that
 * the requesting user matches the channel id.
 */
Broadcast::channel('user.{userId}', function ($user, int $userId) {
    return (int) $user->id === $userId;
});
