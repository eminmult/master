<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="client" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <h1>{{ $t('client.my_orders') }}</h1>
            <NuxtLink :to="localePath('/client/new-order')" class="hm-cta hm-btn-sm">+ {{ $t('orders.new_order') }}</NuxtLink>
          </div>

          <div class="hm-tabs" style="margin-bottom: 0;">
            <button type="button" class="hm-tab" :class="{ active: tab === 'active' }" @click="tab = 'active'">{{ $t('orders.active') }}</button>
            <button type="button" class="hm-tab" :class="{ active: tab === 'history' }" @click="tab = 'history'">{{ $t('orders.history') }}</button>
          </div>

          <div v-if="!loading && filtered.length === 0" class="hm-empty-state">
            <span class="icon">inventory_2</span>
            <h3>{{ $t('orders.no_orders') }}</h3>
            <NuxtLink :to="localePath('/client/new-order')" class="hm-cta hm-btn-sm" style="margin-top: 14px; display: inline-block;">+ {{ $t('orders.new_order') }}</NuxtLink>
          </div>

          <div v-else-if="filtered.length" class="orders-list">
            <NuxtLink
              v-for="order in filtered"
              :key="order.id"
              :to="localePath('/order/' + order.id)"
              class="hm-dash-card order-card"
            >
              <div class="order-head">
                <span class="oid">#{{ order.id }}</span>
                <span class="badge" :class="statusClass(order.status)">{{ $t('status.' + order.status) }}</span>
              </div>
              <h3>{{ order.category?.name }}</h3>
              <p class="order-desc">{{ order.description }}</p>
              <div class="order-meta">
                <span>📍 {{ order.full_address }}</span>
                <span>{{ formatDate(order.created_at) }}</span>
              </div>
              <div v-if="order.master" class="order-master">
                <div
                  class="order-master-avatar"
                  :style="order.master.avatar_url ? { backgroundImage: `url(${order.master.avatar_url})` } : {}"
                >
                  <span v-if="!order.master.avatar_url">{{ order.master.first_name[0] }}</span>
                </div>
                <div>
                  <strong>{{ order.master.first_name }} {{ order.master.last_name }}</strong>
                  <span class="rate">★ {{ order.master.rating_avg }}</span>
                </div>
              </div>
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
const { statusClass } = useStatusClass()
const { formatDateTime: formatDate } = useFormatDate()

const tab = ref('active')
const activeStatuses = ['new', 'searching_master', 'pending_master', 'discussion', 'pending_client', 'confirmed', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'awaiting_completion', 'awaiting_review']

const { data: orders, pending: loading } = await useAsyncData('client-orders', async () => {
  try {
    const res = await apiFetch<{ orders: any[] }>('/orders/my')
    return res.orders || []
  } catch { return [] }
}, { default: () => [] })

const filtered = computed(() => tab.value === 'active'
  ? orders.value.filter((o: any) => activeStatuses.includes(o.status))
  : orders.value.filter((o: any) => !activeStatuses.includes(o.status))
)
</script>

<style scoped>
.orders-list { display: flex; flex-direction: column; gap: 14px; }
.order-card {
  display: block;
  text-decoration: none;
  color: inherit;
  transition: all 0.15s;
  cursor: pointer;
}
.order-card:hover {
  border-color: var(--hm-accent);
  transform: translateY(-2px);
}
.order-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.oid { font-weight: 700; color: var(--hm-text-3); font-size: 12px; letter-spacing: 0.3px; }
.order-card h3 { font-size: 16px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); }
.order-desc {
  font-size: 13px;
  margin: 0 0 10px;
  color: var(--hm-text-3);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.order-meta {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: var(--hm-text-3);
  margin-bottom: 10px;
  gap: 12px;
  flex-wrap: wrap;
}
.order-master {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  padding-top: 10px;
  border-top: 1px solid var(--hm-border-2);
}
.order-master strong { color: var(--hm-text); }
.rate { color: var(--hm-accent); font-weight: 600; margin-left: 6px; }
.order-master-avatar {
  width: 32px; height: 32px; border-radius: 50%;
  background: var(--hm-accent); color: #000;
  display: flex; align-items: center; justify-content: center;
  font-weight: 700; font-size: 13px;
  background-size: cover; background-position: center;
  flex-shrink: 0;
}
</style>
