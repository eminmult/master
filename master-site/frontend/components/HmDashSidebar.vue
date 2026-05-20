<template>
  <aside class="hm-dash-side">
    <div class="hm-dash-side-greet">
      <div class="hm-dash-side-name">{{ auth.user?.first_name }} {{ auth.user?.last_name }}</div>
      <div class="hm-dash-side-role">{{ roleLabel }}</div>
    </div>

    <NuxtLink
      v-for="item in items"
      :key="item.to"
      :to="localePath(item.to)"
      class="hm-dash-nav-item"
      :class="{ active: isActive(item) }"
    >
      <span class="icon">{{ item.icon }}</span>
      <span>{{ item.label }}</span>
      <span v-if="item.badge" class="hm-dash-nav-badge">{{ item.badge }}</span>
    </NuxtLink>

    <button type="button" class="hm-dash-nav-item danger" @click="logout">
      <span class="icon">logout</span>
      <span>{{ $t('nav.logout') }}</span>
    </button>
  </aside>
</template>

<script setup lang="ts">
const { t: $t } = useI18n()
const localePath = useLocalePath()
const auth = useAuthStore()
const route = useRoute()
const notifications = useNotificationsStore()

const props = defineProps<{ role: 'client' | 'master' | 'admin' }>()

const roleLabel = computed(() => {
  if (props.role === 'client') return $t('admin.role_client')
  if (props.role === 'master') return $t('admin.role_master')
  return $t('nav.admin')
})

const items = computed(() => {
  const unread = notifications.unreadCount || 0
  if (props.role === 'client') {
    return [
      { to: '/client', icon: 'dashboard', label: $t('client.dashboard') },
      { to: '/client/new-order', icon: 'add_circle', label: $t('client.create_order') },
      { to: '/client/orders', icon: 'inventory_2', label: $t('client.my_orders') },
      { to: '/client/profile', icon: 'person', label: $t('client.profile') },
      { to: '/payment-methods', icon: 'credit_card', label: $t('profile.payment_methods') },
      { to: '/client/notifications', icon: 'notifications', label: $t('nav.notifications'), badge: unread },
    ]
  }
  if (props.role === 'master') {
    return [
      { to: '/master', icon: 'dashboard', label: $t('master.dashboard') },
      { to: '/master/orders', icon: 'list_alt', label: $t('master.available_orders') },
      { to: '/master/applications', icon: 'mail', label: $t('master.my_applications') },
      { to: '/master/my-orders', icon: 'inventory_2', label: $t('master.my_orders') },
      { to: '/master/schedule', icon: 'event', label: $t('master.schedule') },
      { to: '/master/wallet', icon: 'account_balance_wallet', label: $t('wallet.title') },
      { to: '/master/profile', icon: 'person', label: $t('master.profile') },
      { to: '/payment-methods', icon: 'credit_card', label: $t('profile.payment_methods') },
      { to: '/master/notifications', icon: 'notifications', label: $t('nav.notifications'), badge: unread },
    ]
  }
  return [
    { to: '/admin', icon: 'dashboard', label: $t('admin.dashboard') },
    { to: '/admin/users', icon: 'people', label: $t('admin.users') },
    { to: '/admin/orders', icon: 'inventory_2', label: $t('admin.orders') },
    { to: '/admin/categories', icon: 'category', label: $t('admin.categories') },
    { to: '/admin/category-suggestions', icon: 'lightbulb', label: $t('admin.cat_suggestions') },
    { to: '/admin/reviews', icon: 'star', label: $t('admin.reviews') },
    { to: '/admin/disputes', icon: 'flag', label: $t('admin.disputes') },
    { to: '/admin/analytics', icon: 'analytics', label: $t('admin.analytics') },
  ]
})

function isActive(item: { to: string }) {
  const base = item.to.replace(/^\//, '')
  const current = route.path.replace(/^\/(ru|az|en|tr|ar)\//, '').replace(/^\//, '').replace(/\/$/, '')
  if (base === 'client' || base === 'master' || base === 'admin') {
    return current === base
  }
  return current === base
}

async function logout() {
  await auth.logout()
  navigateTo(localePath('/'))
}
</script>
