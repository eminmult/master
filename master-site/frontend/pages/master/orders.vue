<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="master" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <div>
              <h1>{{ $t('master.available_orders') }}</h1>
              <p class="hm-page-sub">{{ $t('master.available_desc') }}</p>
            </div>
          </div>

          <div v-if="!loading && orders.length === 0" class="hm-empty-state">
            <span class="icon">inbox</span>
            <h3>{{ $t('orders.no_available') }}</h3>
            <p>{{ $t('orders.will_appear') }}</p>
          </div>

          <div v-else-if="orders.length" class="orders-list">
            <div v-for="order in orders" :key="order.id" class="hm-dash-card order-card">
              <div class="order-head">
                <span class="badge badge-warning">{{ $t('status.new') }}</span>
                <span class="stamp">{{ formatDate(order.created_at) }}</span>
              </div>
              <h3>{{ order.category?.name }}</h3>
              <p class="order-desc">{{ order.description }}</p>
              <div class="order-meta">
                <span v-if="order.district">📍 {{ order.district }}</span>
              </div>
              <div v-if="order.estimated_budget" class="budget">💰 ~{{ order.estimated_budget }} AZN</div>
              <button class="btn-primary btn-block" style="margin-top: 14px;" @click="acceptOrder(order.id)">{{ $t('orders.accept') }}</button>
            </div>
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
const router = useRouter()
const toast = useToast()
const { formatShortDateTime: formatDate } = useFormatDate()

const { data: orders, pending: loading } = await useAsyncData('master-available-orders', async () => {
  try {
    const res = await apiFetch<{ orders: any[] }>('/orders/available')
    return res.orders || []
  } catch { return [] }
}, { default: () => [] })

async function acceptOrder(id: number) {
  try { await apiFetch(`/orders/${id}/accept`, { method: 'POST' }); router.push(localePath('/master/my-orders')) }
  catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); letter-spacing: -0.4px; }
.orders-list { display: flex; flex-direction: column; gap: 14px; max-width: 760px; }
.order-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
  gap: 10px;
  flex-wrap: wrap;
}
.stamp { font-size: 12px; color: var(--hm-text-3); }
.order-card h3 { font-size: 16px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); }
.order-desc {
  font-size: 13px;
  color: var(--hm-text-3);
  margin: 0 0 10px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.order-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--hm-text-2);
  flex-wrap: wrap;
}
.budget { font-size: 13px; color: var(--hm-text-2); margin-top: 8px; }
</style>
