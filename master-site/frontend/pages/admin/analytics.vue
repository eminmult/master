<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
      <h1>{{ $t('admin.analytics') }}</h1>
      <p class="text-muted mb-4">{{ $t('admin.analytics_desc') }}</p>

      <template v-if="!loading">
        <div class="stats-grid">
          <div class="stat-card card">
            <span class="stat-icon"><span class="icon">group</span></span>
            <strong>{{ stats.total_clients }}</strong>
            <span class="text-muted">{{ $t('admin.stat_clients') }}</span>
          </div>
          <div class="stat-card card">
            <span class="stat-icon"><span class="icon">build</span></span>
            <strong>{{ stats.total_masters }}</strong>
            <span class="text-muted">{{ $t('admin.stat_masters') }}</span>
          </div>
          <div class="stat-card card">
            <span class="stat-icon"><span class="icon">inventory_2</span></span>
            <strong>{{ stats.total_orders }}</strong>
            <span class="text-muted">{{ $t('admin.stat_orders') }}</span>
          </div>
          <div class="stat-card card">
            <span class="stat-icon"><span class="icon">check_circle</span></span>
            <strong>{{ stats.completed_orders }}</strong>
            <span class="text-muted">{{ $t('admin.stat_completed') }}</span>
          </div>
          <div class="stat-card card">
            <span class="stat-icon"><span class="icon">cancel</span></span>
            <strong>{{ stats.canceled_orders }}</strong>
            <span class="text-muted">{{ $t('admin.stat_canceled') }}</span>
          </div>
          <div class="stat-card card">
            <span class="stat-icon"><span class="icon">star</span></span>
            <strong>{{ stats.avg_master_rating }}</strong>
            <span class="text-muted">{{ $t('admin.stat_avg_rating') }}</span>
          </div>
        </div>

        <!-- Daily orders chart -->
        <div class="card mt-4">
          <h2>{{ $t('admin.daily_chart') }}</h2>
          <div class="chart-area mt-2">
            <div class="chart-bars">
              <div v-for="d in daily" :key="d.date" class="chart-bar-wrap">
                <div class="chart-bar" :style="{ height: barHeight(d.count) + 'px' }">
                  <span class="chart-tooltip">{{ d.count }}</span>
                </div>
                <span class="chart-date">{{ String(d.date).slice(5) }}</span>
              </div>
            </div>
            <p v-if="!daily.length" class="text-muted text-center">{{ $t('admin.no_daily_data') }}</p>
          </div>
        </div>
      </template>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: ['auth', 'admin'] })
const { t: $t } = useI18n()
const { apiFetch } = useApi()
const stats = ref<any>({})
const daily = ref<any[]>([])
const loading = ref(true)

const maxCount = computed(() => Math.max(...daily.value.map((d: any) => Number(d.count)), 1))
function barHeight(count: number) { return Math.max(4, (Number(count) / maxCount.value) * 120) }

onMounted(async () => {
  try {
    const res = await apiFetch<{ stats: any }>('/admin/analytics')
    stats.value = res.stats
  } catch {
    stats.value = { total_clients: 0, total_masters: 0, total_orders: 0, completed_orders: 0, canceled_orders: 0, avg_master_rating: '0.00' }
  }
  try {
    const res2 = await apiFetch<{ daily: any[] }>('/admin/analytics/daily')
    daily.value = res2.daily || []
  } catch {
    daily.value = []
  }
  loading.value = false
})
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); letter-spacing: -0.4px; }
h2 { font-size: 13px; font-weight: 700; text-transform: uppercase; letter-spacing: 1.2px; color: var(--hm-text-3); margin: 0 0 14px; }
.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 14px; }
.stat-card {
  display: flex; flex-direction: column; align-items: center; gap: 6px;
  text-align: center;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
  padding: 20px;
}
.stat-icon { font-size: 28px; color: var(--hm-accent); }
:global(html.theme-light) .stat-icon { color: #b07f00; }
.stat-card strong { font-size: 28px; font-weight: 700; color: var(--hm-accent); letter-spacing: -0.5px; }
:global(html.theme-light) .stat-card strong { color: #b07f00; }
.stat-card span { font-size: 12px; color: var(--hm-text-3); }

.card {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
  padding: 20px;
}
.chart-area { overflow-x: auto; }
.chart-bars { display: flex; align-items: flex-end; gap: 4px; min-height: 140px; padding-bottom: 24px; }
.chart-bar-wrap { display: flex; flex-direction: column; align-items: center; flex: 1; min-width: 22px; position: relative; }
.chart-bar {
  width: 100%; max-width: 26px; background: var(--hm-accent);
  border-radius: 4px 4px 0 0; position: relative; transition: height 0.3s;
}
:global(html.theme-light) .chart-bar { background: #facc15; }
.chart-bar:hover { opacity: 0.85; }
.chart-tooltip {
  display: none; position: absolute; top: -18px; left: 50%; transform: translateX(-50%);
  font-size: 11px; font-weight: 700; color: var(--hm-accent); white-space: nowrap;
}
:global(html.theme-light) .chart-tooltip { color: #b07f00; }
.chart-bar:hover .chart-tooltip { display: block; }
.chart-date { font-size: 10px; color: var(--hm-text-3); margin-top: 4px; white-space: nowrap; }
</style>
