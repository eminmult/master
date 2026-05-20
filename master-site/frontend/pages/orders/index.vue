<template>
  <div class="hm-page hm-orders-page">
    <div class="hm-page-inner">
      <div class="hm-orders-layout">
        <aside class="hm-side">
          <div class="hm-side-head">
            <h2 class="pub">{{ $t('public_orders.filters') }}</h2>
            <a class="hm-side-clear" @click="clearFilters">{{ $t('masters.clear_all') }}</a>
          </div>

          <div class="hm-side-group">
            <div class="hm-side-label">{{ $t('public_orders.category') }}</div>
            <div class="hm-filter-list">
              <button
                v-for="c in categories"
                :key="c.id"
                type="button"
                class="hm-filter-btn"
                :class="{ active: filters.category_id == c.id }"
                @click="selectCategory(c.id)"
              >
                <span>{{ c.name }}</span>
              </button>
            </div>
          </div>

          <div class="hm-side-group">
            <div class="hm-side-label">{{ $t('public_orders.sort') }}</div>
            <select v-model="filters.sort" @change="refresh" class="hm-form-select">
              <option value="recent">{{ $t('public_orders.sort_recent') }}</option>
              <option v-if="filters.lat != null && filters.lng != null" value="distance">{{ $t('public_orders.sort_distance') }}</option>
            </select>
          </div>

          <div class="hm-side-group">
            <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm" style="width:100%" @click="useMyLocation" :disabled="locating">
              <span class="icon icon-sm">my_location</span>
              {{ filters.lat != null ? $t('public_orders.location_set') : (locating ? $t('public_orders.locating') : $t('public_orders.use_my_location')) }}
            </button>
          </div>
        </aside>

        <section class="hm-main-col">
          <div class="hm-main-head">
            <div>
              <h1 class="hm-page-title">{{ $t('public_orders.page_title') }}</h1>
              <p class="hm-page-sub">{{ $t('public_orders.page_sub', { n: pagination.total }) }}</p>
            </div>
          </div>

          <div v-if="loading && !orders.length" class="hm-loading">{{ $t('common.loading') }}</div>
          <div v-else-if="orders.length === 0" class="hm-empty-state">
            <span class="icon">inbox</span>
            <h3>{{ $t('public_orders.empty_title') }}</h3>
            <p>{{ $t('public_orders.empty_desc') }}</p>
          </div>

          <div v-else class="hm-orders-grid">
            <article v-for="o in orders" :key="o.id" class="hm-order-card">
              <div class="hm-order-card-head">
                <span class="hm-order-cat">
                  <CatIcon v-if="o.category?.icon_url" :icon="o.category.icon_url" />
                  {{ o.category?.name }}
                </span>
                <div class="hm-order-card-badges">
                  <span v-if="o.distance_km != null" class="hm-badge hm-badge-muted">
                    <span class="icon icon-sm">near_me</span> {{ o.distance_km }} {{ $t('masters.km') }}
                  </span>
                </div>
              </div>

              <p class="hm-order-desc">{{ o.description }}</p>

              <div v-if="o.first_photo" class="hm-order-photo-wrap">
                <div class="hm-order-photo" :style="{ backgroundImage: `url(${resolvePhoto(o.first_photo)})` }"></div>
                <span v-if="o.photos_count > 1" class="hm-order-photo-count">+{{ o.photos_count - 1 }}</span>
              </div>

              <dl class="hm-order-meta">
                <div v-if="o.district">
                  <dt><span class="icon icon-sm">location_on</span></dt>
                  <dd>{{ o.district }}</dd>
                </div>
                <div v-if="o.desired_time === 'scheduled' && o.scheduled_at">
                  <dt><span class="icon icon-sm">schedule</span></dt>
                  <dd>{{ formatDateTime(o.scheduled_at) }}</dd>
                </div>
                <div v-else>
                  <dt><span class="icon icon-sm">bolt</span></dt>
                  <dd>{{ $t('public_orders.asap') }}</dd>
                </div>
                <div v-if="o.estimated_budget">
                  <dt><span class="icon icon-sm">payments</span></dt>
                  <dd>~{{ o.estimated_budget }} AZN</dd>
                </div>
              </dl>

              <footer class="hm-order-card-foot">
                <div class="hm-order-client">
                  <span class="hm-order-avatar" :style="o.client?.avatar_url ? { backgroundImage: `url(${o.client.avatar_url})` } : {}">
                    <span v-if="!o.client?.avatar_url">{{ (o.client?.first_name || '?').charAt(0) }}</span>
                  </span>
                  <div>
                    <div class="hm-order-client-name">{{ o.client?.first_name }}</div>
                    <div class="hm-order-client-time">{{ timeAgo(o.created_at) }}</div>
                  </div>
                </div>
                <div class="hm-order-actions">
                  <NuxtLink :to="localePath('/orders/' + o.id)" class="hm-btn hm-btn-ghost hm-btn-sm">{{ $t('public_orders.details') }}</NuxtLink>
                  <template v-if="appliedIds.has(o.id)">
                    <span class="hm-order-applied-pill">
                      <span class="icon icon-sm">check</span>
                      {{ $t('public_orders.application_sent_short') }}
                    </span>
                    <button
                      v-if="applicationByOrderId[o.id]?.status !== 'accepted'"
                      type="button"
                      class="hm-btn hm-btn-ghost hm-btn-sm hm-order-withdraw-btn"
                      @click.stop.prevent="withdrawApplicationFor(o.id)"
                      :disabled="withdrawingId === o.id"
                      :title="$t('apps.withdraw')"
                    >
                      <span class="icon icon-sm">{{ withdrawingId === o.id ? 'hourglass_top' : 'close' }}</span>
                    </button>
                  </template>
                  <button
                    v-else
                    type="button"
                    class="hm-btn hm-btn-primary hm-btn-sm"
                    @click="handleApply(o.id)"
                    :disabled="applyingId === o.id"
                  >
                    {{ applyingId === o.id ? $t('public_orders.sending') : $t('public_orders.apply') }}
                  </button>
                </div>
              </footer>
            </article>
          </div>

          <div v-if="pagination.has_more" class="hm-orders-more">
            <button type="button" class="hm-btn hm-btn-ghost" @click="loadMore" :disabled="loading">
              {{ loading ? $t('common.loading') : $t('public_orders.load_more') }}
            </button>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const route = useRoute()
const router = useRouter()
const { apiFetch } = useApi()
const auth = useAuthStore()
const toast = useToast()
const { formatDateTime } = useFormatDate()
const config = useRuntimeConfig()

const filters = reactive({
  category_id: (route.query.category_id || '') as string | number,
  sort: (route.query.sort as string) || 'recent',
  lat: null as number | null,
  lng: null as number | null,
})

const pagination = reactive({ page: 1, per_page: 20, total: 0, has_more: false })
const orders = ref<any[]>([])
const loading = ref(false)
const locating = ref(false)
const applyingId = ref<number | null>(null)
const appliedIds = ref<Set<number>>(new Set())
const applicationByOrderId = ref<Record<number, { id: number; status: string }>>({})
const withdrawingId = ref<number | null>(null)

async function loadAppliedIds() {
  if (!auth.isLoggedIn || !auth.isMaster) {
    appliedIds.value = new Set()
    applicationByOrderId.value = {}
    return
  }
  try {
    const res = await apiFetch<{ applications: { id: number; order_id: number; status: string }[] }>('/master/applied-order-ids')
    const apps = res.applications || []
    appliedIds.value = new Set(apps.map(a => Number(a.order_id)))
    applicationByOrderId.value = Object.fromEntries(apps.map(a => [Number(a.order_id), { id: a.id, status: a.status }]))
  } catch {}
}

async function withdrawApplicationFor(orderId: number) {
  const app = applicationByOrderId.value[orderId]
  if (!app) return
  if (!confirm($t('apps.withdraw_confirm'))) return
  withdrawingId.value = orderId
  try {
    await apiFetch(`/order-applications/${app.id}/withdraw`, { method: 'POST' })
    toast.success($t('apps.withdrawn_toast'))
    const newSet = new Set(appliedIds.value)
    newSet.delete(orderId)
    appliedIds.value = newSet
    const copy = { ...applicationByOrderId.value }
    delete copy[orderId]
    applicationByOrderId.value = copy
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  } finally {
    withdrawingId.value = null
  }
}

function buildParams(page = 1) {
  const params = new URLSearchParams()
  params.set('page', String(page))
  params.set('per_page', String(pagination.per_page))
  if (filters.category_id) params.set('category_id', String(filters.category_id))

  if (filters.sort === 'distance' && filters.lat != null && filters.lng != null) {
    params.set('sort', 'distance')
    params.set('lat', String(filters.lat))
    params.set('lng', String(filters.lng))
  } else if (filters.lat != null && filters.lng != null) {
    params.set('lat', String(filters.lat))
    params.set('lng', String(filters.lng))
  }
  return params
}

const { data: categories } = await useAsyncData('orders-categories', async () => {
  const res = await apiFetch<{ categories: any[] }>('/categories?only_with_masters=1')
  return res.categories || []
}, { default: () => [] })

async function load(page = 1) {
  loading.value = true
  try {
    const res = await apiFetch<{ orders: any[]; pagination: any }>(`/orders/public?${buildParams(page)}`)
    if (page === 1) orders.value = res.orders
    else orders.value = [...orders.value, ...(res.orders || [])]
    Object.assign(pagination, res.pagination)
  } catch { /* keep previous */ }
  finally { loading.value = false }
}

await load(1)
if (process.client) loadAppliedIds()

function refresh() {
  pagination.page = 1
  load(1)
}

function loadMore() {
  load(pagination.page + 1)
}

function selectCategory(id: string | number) {
  filters.category_id = filters.category_id == id ? '' : id
  refresh()
}

function clearFilters() {
  filters.category_id = ''

  filters.sort = 'recent'
  refresh()
}

function useMyLocation() {
  if (!navigator.geolocation) {
    toast.error($t('public_orders.geo_unsupported'))
    return
  }
  locating.value = true
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      filters.lat = pos.coords.latitude
      filters.lng = pos.coords.longitude
      filters.sort = 'distance'
      locating.value = false
      refresh()
    },
    () => { locating.value = false; toast.error($t('public_orders.geo_failed')) },
    { timeout: 10000 },
  )
}

function resolvePhoto(url: string): string {
  if (!url) return ''
  if (url.startsWith('http://') || url.startsWith('https://')) return url
  const base = (config.public as any).apiBase?.replace(/\/api\/?$/, '') || ''
  return url.startsWith('/') ? base + url : url
}

function timeAgo(iso: string): string {
  if (!iso) return ''
  const diff = (Date.now() - new Date(iso).getTime()) / 1000
  if (diff < 60) return $t('public_orders.just_now')
  if (diff < 3600) return $t('public_orders.minutes_ago', { n: Math.floor(diff / 60) })
  if (diff < 86400) return $t('public_orders.hours_ago', { n: Math.floor(diff / 3600) })
  return $t('public_orders.days_ago', { n: Math.floor(diff / 86400) })
}

async function handleApply(id: number) {
  if (!auth.isLoggedIn) {
    router.push({ path: localePath('/register/master'), query: { redirect: route.fullPath } })
    return
  }
  if (auth.isClient) {
    toast.error($t('public_orders.only_masters'))
    return
  }
  if (!auth.isMaster) return
  if (appliedIds.value.has(id)) {
    router.push(localePath('/orders/' + id))
    return
  }
  applyingId.value = id
  try {
    await apiFetch(`/orders/${id}/apply`, { method: 'POST' })
    toast.success($t('public_orders.application_sent'))
    appliedIds.value = new Set([...appliedIds.value, id])
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  } finally {
    applyingId.value = null
  }
}

useHead({ title: () => $t('public_orders.page_title') + ' — Master.az' })
</script>

<style scoped>
.hm-orders-page { padding-top: 24px; padding-bottom: 48px; }
.hm-orders-layout {
  display: grid;
  grid-template-columns: 260px 1fr;
  gap: 24px;
  align-items: start;
}
@media (max-width: 960px) {
  .hm-orders-layout { grid-template-columns: 1fr; }
}

.hm-orders-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 16px;
}

.hm-order-card {
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  border-radius: 14px;
  padding: 18px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: transform .15s, box-shadow .15s, border-color .15s;
}
.hm-order-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.08);
  border-color: var(--hm-accent);
}

.hm-order-card-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 10px;
}
.hm-order-cat {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  font-size: 14px;
  color: var(--hm-text);
}
.hm-order-cat .icon { color: var(--hm-accent); font-size: 20px; }

.hm-order-card-badges { display: flex; gap: 6px; flex-wrap: wrap; }
.hm-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 999px;
  white-space: nowrap;
}
.hm-badge .icon { font-size: 14px; }
.hm-badge-urgent {
  background: rgba(255,77,77,0.12);
  color: #e04040;
}
.hm-badge-muted {
  background: var(--hm-bg-2);
  color: var(--hm-text-2);
}

.hm-order-desc {
  font-size: 13.5px;
  line-height: 1.5;
  color: var(--hm-text-2);
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.hm-order-photo-wrap { position: relative; }
.hm-order-photo {
  width: 100%;
  height: 140px;
  border-radius: 10px;
  background: var(--hm-bg-2) center/cover no-repeat;
}
.hm-order-photo-count {
  position: absolute;
  right: 8px;
  bottom: 8px;
  background: rgba(0,0,0,0.7);
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 999px;
}

.hm-order-meta {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 6px 12px;
  margin: 0;
  padding: 10px 0;
  border-top: 1px dashed var(--hm-border);
  border-bottom: 1px dashed var(--hm-border);
}
.hm-order-meta > div {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  color: var(--hm-text-2);
}
.hm-order-meta dt { display: flex; color: var(--hm-text-3); }
.hm-order-meta dt .icon { font-size: 16px; }
.hm-order-meta dd { margin: 0; font-weight: 500; color: var(--hm-text); }

.hm-order-card-foot {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}
.hm-order-client {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}
.hm-order-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: var(--hm-bg-2) center/cover no-repeat;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 14px;
  color: var(--hm-text-2);
  flex-shrink: 0;
}
.hm-order-client-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--hm-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.hm-order-client-time {
  font-size: 11.5px;
  color: var(--hm-text-3);
}
.hm-order-actions { display: flex; gap: 6px; flex-shrink: 0; }
.hm-order-applied-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 5px 10px;
  border-radius: 8px;
  font-size: 11.5px;
  font-weight: 700;
  color: #22c55e;
  background: rgba(34, 197, 94, 0.1);
  border: 1px solid rgba(34, 197, 94, 0.3);
  white-space: nowrap;
}
.hm-order-applied-pill .icon { font-size: 14px; color: #22c55e; }
.hm-order-withdraw-btn {
  width: 32px; height: 32px;
  padding: 0 !important;
  color: #ef4444 !important;
  border-color: rgba(239, 68, 68, 0.3) !important;
  background: transparent !important;
}
.hm-order-withdraw-btn:hover:not(:disabled) {
  background: rgba(239, 68, 68, 0.08) !important;
  border-color: rgba(239, 68, 68, 0.5) !important;
}
.hm-order-withdraw-btn .icon { font-size: 16px; }

.hm-orders-more {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}
</style>
