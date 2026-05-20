<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="master" />
        <div class="hm-dash-main">
      <h1><span class="icon">analytics</span> {{ $t('master.earnings_title') }}</h1>

      <template v-if="!loading">
        <!-- Stats cards -->
        <div class="earn-grid mt-3">
          <div class="earn-card card">
            <span class="earn-label">{{ $t('master.this_week') }}</span>
            <strong class="earn-num">{{ stats.this_week_orders }}</strong>
            <span class="earn-sub">{{ $t('masters.completed') }}</span>
            <div v-if="stats.this_week_revenue" class="earn-revenue">{{ stats.this_week_revenue }} AZN</div>
          </div>
          <div class="earn-card card">
            <span class="earn-label">{{ $t('master.this_month') }}</span>
            <strong class="earn-num">{{ stats.this_month_orders }}</strong>
            <span class="earn-sub">{{ $t('masters.completed') }}</span>
            <div v-if="stats.this_month_revenue" class="earn-revenue">{{ stats.this_month_revenue }} AZN</div>
          </div>
          <div class="earn-card card">
            <span class="earn-label">{{ $t('master.last_month') }}</span>
            <strong class="earn-num">{{ stats.last_month_orders }}</strong>
            <span class="earn-sub">{{ $t('masters.completed') }}</span>
            <div v-if="stats.last_month_revenue" class="earn-revenue">{{ stats.last_month_revenue }} AZN</div>
          </div>
          <div class="earn-card card">
            <span class="earn-label">{{ $t('master.total') }}</span>
            <strong class="earn-num">{{ stats.total_orders }}</strong>
            <span class="earn-sub">★ {{ stats.rating }}</span>
          </div>
        </div>

        <!-- Chart -->
        <div class="card mt-3">
          <h2>{{ $t('master.daily_chart') }}</h2>
          <div class="chart-area mt-2">
            <div class="chart-bars">
              <div v-for="d in stats.daily" :key="d.date" class="chart-bar-wrap">
                <div class="chart-bar" :style="{ height: barHeight(d.count) + 'px' }">
                  <span class="chart-tooltip">{{ d.count }}</span>
                </div>
                <span class="chart-date">{{ d.date.slice(5) }}</span>
              </div>
            </div>
            <p v-if="!stats.daily?.length" class="text-muted text-center">{{ $t('orders.no_orders') }}</p>
          </div>
        </div>
      </template>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })
const { t: $t } = useI18n()
const { apiFetch } = useApi()
const stats = ref<any>({})
const loading = ref(true)

const maxCount = computed(() => Math.max(...(stats.value.daily || []).map((d: any) => d.count), 1))
function barHeight(count: number) { return Math.max(4, (count / maxCount.value) * 120) }

onMounted(async () => {
  try { const res = await apiFetch<{ stats: any }>('/master/earnings'); stats.value = res.stats } catch {}
  loading.value = false
})
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; display: flex; align-items: center; gap: 10px; margin: 0 0 16px; color: var(--hm-text); letter-spacing: -0.4px; }
h1 .icon { color: var(--hm-accent); }
h2 { font-size: 13px; font-weight: 700; text-transform: uppercase; letter-spacing: 1.2px; color: var(--hm-text-3); margin: 0 0 14px; }
.earn-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 14px; }
.earn-card {
  text-align: center;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
  padding: 20px 16px;
}
.earn-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.7px; color: var(--hm-text-3); }
.earn-num { display: block; font-size: 30px; font-weight: 700; color: var(--hm-accent); margin: 6px 0; letter-spacing: -0.5px; }
:global(html.theme-light) .earn-num { color: #b07f00; }
.earn-sub { font-size: 12px; color: var(--hm-text-3); }
.earn-revenue { font-size: 14px; font-weight: 700; color: #22c55e; margin-top: 6px; }

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
  width: 100%; max-width: 26px;
  background: var(--hm-accent);
  border-radius: 4px 4px 0 0;
  position: relative;
  transition: height 0.3s;
}
:global(html.theme-light) .chart-bar { background: #facc15; }
.chart-bar:hover { opacity: 0.85; }
.chart-tooltip {
  display: none; position: absolute; top: -18px; left: 50%; transform: translateX(-50%);
  font-size: 11px; font-weight: 700; color: var(--hm-accent);
}
:global(html.theme-light) .chart-tooltip { color: #b07f00; }
.chart-bar:hover .chart-tooltip { display: block; }
.chart-date { font-size: 10px; color: var(--hm-text-3); margin-top: 4px; white-space: nowrap; }

@media (min-width: 768px) { .earn-grid { grid-template-columns: repeat(4, 1fr); } }
</style>
