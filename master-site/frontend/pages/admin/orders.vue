<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
      <div class="page-header">
        <h1>{{ $t('admin.orders') }}</h1>
        <p class="text-muted">{{ $t('admin.orders_manage') }}</p>
      </div>

      <div class="filters card mb-2">
        <div class="filter-row">
          <select v-model="filters.status">
            <option value="">{{ $t('admin.all_statuses') }}</option>
            <option v-for="s in statuses" :key="s.value" :value="s.value">{{ $t('status.' + s.value) }}</option>
          </select>
          <input v-model="filters.search" type="text" :placeholder="$t('admin.search_orders')" />
          <button class="btn btn-primary btn-sm" @click="fetchOrders">{{ $t('admin.search_btn') }}</button>
        </div>
      </div>

      <div v-if="!loading && orders.length === 0" class="text-center mt-4 text-muted">{{ $t('admin.no_orders') }}</div>
      <div v-else-if="orders.length" class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ $t('admin.th_id') }}</th>
              <th>{{ $t('admin.th_date') }}</th>
              <th>{{ $t('admin.th_client') }}</th>
              <th>{{ $t('admin.th_master') }}</th>
              <th>{{ $t('admin.th_category') }}</th>
              <th>{{ $t('admin.th_status') }}</th>
              <th>{{ $t('admin.th_address') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="order in orders" :key="order.id">
              <td>#{{ order.id }}</td>
              <td>{{ formatDate(order.created_at) }}</td>
              <td>{{ order.client?.first_name }} {{ order.client?.last_name }}</td>
              <td>{{ order.master ? `${order.master.first_name} ${order.master.last_name}` : '—' }}</td>
              <td>{{ order.category?.name }}</td>
              <td><span class="badge" :class="statusClass(order.status)">{{ statusLabel(order.status) }}</span></td>
              <td class="truncate">{{ order.full_address }}</td>
            </tr>
          </tbody>
        </table>
      </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: ['auth', 'admin'] })
const { t: $t } = useI18n()

const { apiFetch } = useApi()
const { statusClass } = useStatusClass()
const { formatDateTime: formatDate } = useFormatDate()
const filters = reactive({ status: '', search: '' })

const statuses = [
  { value: 'new' },
  { value: 'searching_master' },
  { value: 'accepted' },
  { value: 'on_the_way' },
  { value: 'arrived' },
  { value: 'in_progress' },
  { value: 'completed' },
  { value: 'awaiting_review' },
  { value: 'canceled_by_client' },
  { value: 'canceled_by_master' },
  { value: 'closed' },
]

function statusLabel(s: string) {
  return $t('status.' + s)
}

function buildParams() {
  const params = new URLSearchParams()
  if (filters.status) params.set('status', filters.status)
  if (filters.search) params.set('search', filters.search)
  return params.toString()
}

const { data: orders } = await useAsyncData('admin-orders', async () => {
  try {
    const res = await apiFetch<{ orders: any[] }>(`/admin/orders?${buildParams()}`)
    return res.orders || []
  } catch { return [] }
}, { default: () => [] })
const loading = ref(false)

async function fetchOrders() {
  loading.value = true
  try {
    const res = await apiFetch<{ orders: any[] }>(`/admin/orders?${buildParams()}`)
    orders.value = res.orders || []
  } catch {}
  loading.value = false
}
</script>

<style scoped>
.page-header { margin-bottom: 20px; }
.page-header h1 { font-size: 26px; font-weight: 700; margin: 0; color: var(--hm-text); letter-spacing: -0.4px; }
.filter-row { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 18px; }
.filter-row select, .filter-row input { max-width: 240px; }
.table-wrap {
  overflow-x: auto;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
}
.data-table { width: 100%; border-collapse: collapse; font-size: 14px; color: var(--hm-text); }
.data-table th {
  text-align: left; padding: 12px 16px;
  border-bottom: 1px solid var(--hm-border-2);
  font-weight: 700; color: var(--hm-text-3);
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.7px;
  background: var(--hm-bg-2);
}
.data-table td { padding: 14px 16px; border-bottom: 1px solid var(--hm-border-2); color: var(--hm-text-2); }
.data-table tr:last-child td { border-bottom: 0; }
.data-table tr:hover td { background: var(--hm-bg-2); }
.truncate { max-width: 220px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
</style>
