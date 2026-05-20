<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="master" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <div>
              <h1>{{ $t('master.hello', { name: auth.user?.first_name }) }}</h1>
              <p class="hm-page-sub">{{ $t('master.panel') }}</p>
            </div>
            <div class="status-toggle" :class="isOnline ? 'online' : 'offline'">
              <span class="status-dot"></span>
              {{ isOnline ? $t('master.online') : $t('master.offline') }}
            </div>
          </div>

          <SubscriptionBanner />

          <div class="hm-dash-stats">
            <div class="hm-dash-stat">
              <div class="hm-dash-stat-v accent">{{ auth.user?.rating_avg || '0.00' }}</div>
              <div class="hm-dash-stat-l">{{ $t('master.rating') }}</div>
            </div>
            <div class="hm-dash-stat">
              <div class="hm-dash-stat-v">{{ auth.user?.master_profile?.completed_orders_count || 0 }}</div>
              <div class="hm-dash-stat-l">{{ $t('master.orders_count') }}</div>
            </div>
            <div class="hm-dash-stat">
              <div class="hm-dash-stat-v">{{ auth.user?.rating_count || 0 }}</div>
              <div class="hm-dash-stat-l">{{ $t('master.reviews_count') }}</div>
            </div>
          </div>

          <div v-if="pendingOrders.length" class="pending-section">
            <h2><span>⚡</span> {{ $t('master.pending_requests') }} ({{ pendingOrders.length }})</h2>
            <div class="pending-list">
              <NuxtLink
                v-for="order in pendingOrders"
                :key="order.id"
                :to="localePath('/order/' + order.id)"
                class="pending-card"
              >
                <div class="pc-left">
                  <span class="badge badge-warning">{{ $t('status.pending_master') }}</span>
                  <strong>{{ order.category?.name }}</strong>
                  <p>{{ order.description }}</p>
                </div>
                <div class="pc-right">→</div>
              </NuxtLink>
            </div>
          </div>

          <div class="hm-services-grid" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
            <NuxtLink :to="localePath('/master/orders')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">list_alt</span></div>
              <h3>{{ $t('master.available_orders') }}</h3>
              <p>{{ $t('master.available_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/master/my-orders')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">inventory_2</span></div>
              <h3>{{ $t('master.my_orders') }}</h3>
              <p>{{ $t('master.orders_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/master/earnings')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">analytics</span></div>
              <h3>{{ $t('master.earnings_title') }}</h3>
              <p>{{ $t('master.daily_chart') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/master/profile')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">person</span></div>
              <h3>{{ $t('master.profile') }}</h3>
              <p>{{ $t('master.profile_desc') }}</p>
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })
const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const auth = useAuthStore()
const isOnline = computed(() => auth.user?.master_profile?.status === 'online')

const pendingOrders = ref<any[]>([])

onMounted(async () => {
  try {
    const res = await apiFetch<{ orders: any[] }>('/orders/my')
    pendingOrders.value = res.orders.filter((o: any) => o.status === 'pending_master')
  } catch {}
})
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0; color: var(--hm-text); letter-spacing: -0.4px; }
.status-toggle {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 14px;
  border-radius: 999px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  font-size: 13px;
  font-weight: 600;
  color: var(--hm-text);
}
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.status-toggle.online .status-dot { background: #22c55e; box-shadow: 0 0 6px #22c55e; }
.status-toggle.offline .status-dot { background: var(--hm-text-3); }

.pending-section {
  background: var(--hm-bg-1);
  border: 1px solid rgba(255, 255, 0, 0.3);
  border-radius: 18px;
  padding: 20px;
}
.pending-section h2 {
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 1px;
  text-transform: uppercase;
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 14px;
  color: var(--hm-accent);
}
.pending-list { display: flex; flex-direction: column; gap: 8px; }
.pending-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  background: rgba(255, 255, 0, 0.06);
  border: 1px solid rgba(255, 255, 0, 0.2);
  border-radius: 14px;
  transition: all 0.15s;
  text-decoration: none;
  color: var(--hm-text);
}
.pending-card:hover { border-color: var(--hm-accent); transform: translateY(-1px); }
.pc-left { display: flex; flex-direction: column; gap: 4px; min-width: 0; flex: 1; }
.pc-left strong { font-size: 14px; color: var(--hm-text); }
.pc-left p {
  font-size: 13px;
  color: var(--hm-text-3);
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.pc-right {
  font-size: 20px;
  color: var(--hm-accent);
  flex-shrink: 0;
  font-weight: 700;
}
</style>
