<template>
  <nav v-if="auth.isLoggedIn" class="mobile-bottom-nav">
    <NuxtLink :to="localePath('/')" class="nav-item" :class="{ active: isRoute('/') }">
      <span class="icon">home</span>
      <span>{{ $t('nav.home') }}</span>
    </NuxtLink>

    <template v-if="auth.isClient">
      <NuxtLink :to="localePath('/client/orders')" class="nav-item" :class="{ active: isRoute('/client/orders') || isRoute('/order') }">
        <span class="icon">inventory_2</span>
        <span>{{ $t('client.my_orders') }}</span>
      </NuxtLink>
      <NuxtLink :to="localePath('/masters')" class="nav-item" :class="{ active: isRoute('/masters') }">
        <span class="icon">search</span>
        <span>{{ $t('masters.page_title') }}</span>
      </NuxtLink>
    </template>

    <template v-if="auth.isMaster">
      <NuxtLink :to="localePath('/master/my-orders')" class="nav-item" :class="{ active: isRoute('/master/my-orders') || isRoute('/order') }">
        <span class="icon">inventory_2</span>
        <span>{{ $t('master.my_orders') }}</span>
      </NuxtLink>
      <NuxtLink :to="localePath('/master/orders')" class="nav-item" :class="{ active: isRoute('/master/orders') }">
        <span class="icon">assignment</span>
        <span>{{ $t('master.available_orders') }}</span>
      </NuxtLink>
    </template>

    <NuxtLink :to="localePath(auth.isClient ? '/client/notifications' : '/master/notifications')" class="nav-item" :class="{ active: isRoute('/notifications') }">
      <span class="icon nav-notif-icon">
        notifications
        <span v-if="notifStore.unread > 0" class="nav-badge">{{ notifStore.unread > 9 ? '9+' : notifStore.unread }}</span>
      </span>
      <span>{{ $t('notifications.title') }}</span>
    </NuxtLink>

    <NuxtLink :to="localePath(auth.isClient ? '/client/profile' : '/master/profile')" class="nav-item" :class="{ active: isRoute('/profile') }">
      <span class="icon">person</span>
      <span>{{ $t('client.profile') }}</span>
    </NuxtLink>
  </nav>
</template>

<script setup lang="ts">
const { t: $t } = useI18n()
const localePath = useLocalePath()
const route = useRoute()
const auth = useAuthStore()
const notifStore = useNotificationsStore()

function isRoute(path: string) {
  return route.path.includes(path)
}
</script>

<style scoped>
.mobile-bottom-nav {
  display: flex;
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: #fff;
  border-top: 1px solid var(--gray-200);
  padding: 0.375rem 0 env(safe-area-inset-bottom, 0.375rem);
  box-shadow: 0 -2px 10px rgba(0,0,0,0.05);
}

.nav-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.125rem;
  padding: 0.375rem 0;
  font-size: 0.625rem;
  font-weight: 500;
  color: var(--gray-400);
  transition: color 0.2s;
  text-align: center;
  line-height: 1.2;
}
.nav-item .icon { font-size: 22px; }
.nav-item.active { color: var(--primary); }

.nav-notif-icon { position: relative; }
.nav-badge {
  position: absolute;
  top: -4px;
  right: -8px;
  min-width: 16px;
  height: 16px;
  background: #dc2626;
  color: #fff;
  font-size: 0.563rem;
  font-weight: 700;
  border-radius: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 3px;
  font-family: var(--font-body, sans-serif);
}

@media (min-width: 768px) {
  .mobile-bottom-nav { display: none; }
}
</style>
