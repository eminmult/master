<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="master" />
        <div class="hm-dash-main">
      <h1>{{ $t('master.my_orders') }}</h1>
      <div class="tabs mt-2 mb-2">
        <button :class="{ active: tab === 'active' }" @click="tab = 'active'">{{ $t('orders.active') }}</button>
        <button :class="{ active: tab === 'history' }" @click="tab = 'history'">{{ $t('orders.history') }}</button>
      </div>
      <div v-if="filtered.length === 0" class="empty-state mt-4"><p class="text-muted">{{ $t('orders.no_orders') }}</p></div>
      <div v-else class="orders-list">
        <NuxtLink v-for="order in filtered" :key="order.id" :to="localePath('/order/' + order.id)" class="order-card card">
          <div class="order-header">
            <span class="order-id">#{{ order.id }}</span>
            <span class="badge" :class="statusClass(order.status)">{{ $t('status.' + order.status) }}</span>
          </div>
          <h3>{{ order.category?.name }}</h3>
          <p class="text-muted order-desc">{{ order.description }}</p>
          <div class="order-meta text-muted"><span><span class="icon icon-sm">location_on</span> {{ order.full_address }}</span><span>{{ formatDate(order.created_at) }}</span></div>
          <div class="order-client mt-1"><strong>{{ $t('orders.client') }}:</strong> {{ order.client?.first_name }} · {{ order.contact_phone }}</div>
          <div v-if="isActive(order)" class="order-actions mt-2">
            <button v-if="order.status === 'accepted'" class="btn btn-primary btn-sm" @click="updateStatus(order.id, 'on_the_way')">{{ $t('orders.departed') }}</button>
            <button v-if="order.status === 'on_the_way'" class="btn btn-primary btn-sm" @click="updateStatus(order.id, 'arrived')">{{ $t('orders.arrived') }}</button>
            <button v-if="order.status === 'arrived'" class="btn btn-primary btn-sm" @click="updateStatus(order.id, 'in_progress')">{{ $t('orders.started') }}</button>
            <button v-if="order.status === 'in_progress'" class="btn btn-success btn-sm" @click="updateStatus(order.id, 'completed')">{{ $t('orders.finished') }}</button>
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
const toast = useToast()
const { statusClass } = useStatusClass()
const { formatShortDateTime: formatDate } = useFormatDate()

const tab = ref('active')
const activeStatuses = ['pending_master', 'discussion', 'pending_client', 'confirmed', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'awaiting_completion', 'awaiting_review']

const { data: orders, refresh: fetchOrders } = await useAsyncData('master-my-orders', async () => {
  try {
    const res = await apiFetch<{ orders: any[] }>('/orders/my')
    return res.orders || []
  } catch { return [] }
}, { default: () => [] })

const filtered = computed(() => tab.value === 'active'
  ? orders.value.filter((o: any) => activeStatuses.includes(o.status))
  : orders.value.filter((o: any) => !activeStatuses.includes(o.status)))

function isActive(o: any) { return activeStatuses.includes(o.status) }

async function updateStatus(id: number, status: string) {
  try { await apiFetch(`/orders/${id}/status`, { method: 'POST', body: { status } }); await fetchOrders() }
  catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); letter-spacing: -0.4px; }
.tabs { display: flex; gap: 6px; padding: 4px; background: var(--hm-bg-2); border-radius: 999px; width: fit-content; border: 1px solid var(--hm-border-2); }
.tabs button {
  padding: 8px 18px; border-radius: 999px; font-weight: 500; font-size: 13px;
  background: transparent; color: var(--hm-text-2); border: 0; cursor: pointer;
  transition: all 0.15s; font-family: inherit;
}
.tabs button.active { background: var(--hm-accent); color: #000; font-weight: 700; }
:global(html.theme-light) .tabs button.active { background: #facc15; color: #111; }
.empty-state { text-align: center; padding: 50px 0; color: var(--hm-text-3); }
.orders-list { display: flex; flex-direction: column; gap: 14px; max-width: 760px; }
.order-card {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 18px;
  padding: 18px;
  display: block;
  text-decoration: none;
  color: inherit;
  transition: all 0.15s;
}
.order-card:hover { border-color: var(--hm-accent); transform: translateY(-2px); }
.order-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; gap: 10px; flex-wrap: wrap; }
.order-id { font-weight: 700; color: var(--hm-text-3); font-size: 12px; }
.order-card h3 { font-size: 16px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); }
.order-desc { font-size: 13px; color: var(--hm-text-3); margin: 0 0 10px; }
.order-meta { display: flex; justify-content: space-between; font-size: 12px; color: var(--hm-text-3); margin-bottom: 10px; gap: 10px; flex-wrap: wrap; }
.order-client { font-size: 13px; padding-top: 10px; border-top: 1px solid var(--hm-border-2); color: var(--hm-text-2); }
.order-client strong { color: var(--hm-text); }
.order-actions { display: flex; gap: 8px; margin-top: 12px; flex-wrap: wrap; }
.order-actions .btn {
  padding: 9px 16px; border-radius: 10px;
  background: var(--hm-accent); color: #000;
  border: 0; font-size: 13px; font-weight: 600; cursor: pointer;
}
:global(html.theme-light) .order-actions .btn { background: #facc15; color: #111; }
.order-actions .btn-success { background: #22c55e; color: #fff; }
</style>
