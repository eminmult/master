<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="master" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <div>
              <h1>{{ $t('master.planner_title') }}</h1>
              <p class="hm-page-sub">{{ $t('master.planner_desc') }}</p>
            </div>
            <div class="hm-plan-summary">
              <div><strong>{{ activeOrdersCount }}</strong><span>{{ $t('master.plan_active') }}</span></div>
              <div><strong>{{ upcomingOrders.length }}</strong><span>{{ $t('master.plan_upcoming') }}</span></div>
            </div>
          </div>

          <!-- Calendar card -->
          <section class="hm-plan-card">
            <div class="hm-plan-head">
              <button type="button" class="hm-plan-nav" @click="shiftMonth(-1)" aria-label="Previous"><span class="icon">chevron_left</span></button>
              <div class="hm-plan-month">{{ monthLabel }}</div>
              <button type="button" class="hm-plan-nav" @click="shiftMonth(1)" aria-label="Next"><span class="icon">chevron_right</span></button>
              <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm hm-plan-today" @click="goToday">{{ $t('master.plan_today') }}</button>
            </div>

            <div class="hm-plan-grid">
              <div v-for="d in weekdayShort" :key="d" class="hm-plan-dow">{{ d }}</div>
              <div
                v-for="cell in calendarCells"
                :key="cell.key"
                class="hm-plan-cell"
                :class="{
                  'hm-plan-cell-other': !cell.inMonth,
                  'hm-plan-cell-today': cell.isToday,
                  'hm-plan-cell-selected': cell.key === selectedKey,
                  'hm-plan-cell-offday': !cell.isWorkDay,
                }"
                @click="selectDay(cell.key)"
              >
                <div class="hm-plan-num">{{ cell.day }}</div>
                <div v-if="cell.events.length" class="hm-plan-events">
                  <span
                    v-for="ev in cell.events.slice(0, 3)"
                    :key="ev.id"
                    class="hm-plan-event"
                    :class="'hm-plan-ev-' + statusKind(ev.status)"
                    :title="ev.category?.name + ' · ' + (ev.full_address || '')"
                  >
                    <span class="hm-plan-ev-dot"></span>
                    <span class="hm-plan-ev-text">{{ ev.time }} {{ ev.category?.name }}</span>
                  </span>
                  <span v-if="cell.events.length > 3" class="hm-plan-more">+{{ cell.events.length - 3 }}</span>
                </div>
              </div>
            </div>

            <div class="hm-plan-legend">
              <span><span class="hm-plan-ev-dot hm-plan-ev-upcoming"></span>{{ $t('master.plan_status_upcoming') }}</span>
              <span><span class="hm-plan-ev-dot hm-plan-ev-active"></span>{{ $t('master.plan_status_active') }}</span>
              <span><span class="hm-plan-ev-dot hm-plan-ev-done"></span>{{ $t('master.plan_status_done') }}</span>
              <span><span class="hm-plan-ev-dot hm-plan-ev-cancel"></span>{{ $t('master.plan_status_cancel') }}</span>
            </div>
          </section>

          <!-- Agenda for selected day -->
          <section class="hm-plan-card">
            <h2 class="hm-plan-section-title">
              <span class="icon">today</span>
              {{ selectedKey === todayKey ? $t('master.plan_today') : selectedDayLabel }}
            </h2>

            <div v-if="!selectedDayEvents.length" class="hm-plan-empty">
              <span class="icon">event_available</span>
              <p>{{ $t('master.plan_day_empty') }}</p>
            </div>

            <div v-else class="hm-plan-list">
              <NuxtLink
                v-for="o in selectedDayEvents"
                :key="o.id"
                :to="localePath('/order/' + o.id)"
                class="hm-plan-item"
                :class="'hm-plan-item-' + statusKind(o.status)"
              >
                <div class="hm-plan-item-time">
                  <span class="hm-plan-item-hour">{{ o.time }}</span>
                  <span class="hm-plan-item-tag">{{ $t('status.' + o.status) }}</span>
                </div>
                <div class="hm-plan-item-body">
                  <div class="hm-plan-item-title">
                    <CatIcon v-if="o.category?.icon_url" :icon="o.category.icon_url" />
                    {{ o.category?.name || '—' }}
                  </div>
                  <div class="hm-plan-item-desc">{{ o.description }}</div>
                  <div class="hm-plan-item-meta">
                    <span v-if="o.full_address"><span class="icon icon-sm">location_on</span>{{ o.full_address }}</span>
                    <span v-if="o.client"><span class="icon icon-sm">person</span>{{ o.client.first_name }} {{ o.client.last_name || '' }}</span>
                    <span v-if="o.estimated_budget"><span class="icon icon-sm">payments</span>{{ o.estimated_budget }} AZN</span>
                  </div>
                </div>
                <span class="icon hm-plan-item-arrow">chevron_right</span>
              </NuxtLink>
            </div>
          </section>

          <!-- Upcoming agenda -->
          <section v-if="upcomingOrders.length" class="hm-plan-card">
            <h2 class="hm-plan-section-title">
              <span class="icon">upcoming</span>
              {{ $t('master.plan_upcoming_title') }}
            </h2>
            <div class="hm-plan-list">
              <NuxtLink
                v-for="o in upcomingOrders.slice(0, 5)"
                :key="'up-' + o.id"
                :to="localePath('/order/' + o.id)"
                class="hm-plan-item"
                :class="'hm-plan-item-' + statusKind(o.status)"
              >
                <div class="hm-plan-item-time">
                  <span class="hm-plan-item-hour">{{ formatShortDate(o.date) }}</span>
                  <span class="hm-plan-item-sub">{{ o.time }}</span>
                </div>
                <div class="hm-plan-item-body">
                  <div class="hm-plan-item-title">{{ o.category?.name || '—' }}</div>
                  <div class="hm-plan-item-desc">{{ o.description }}</div>
                </div>
                <span class="icon hm-plan-item-arrow">chevron_right</span>
              </NuxtLink>
            </div>
          </section>

          <!-- Work hours editor -->
          <section class="hm-plan-card">
            <button type="button" class="hm-plan-section-title hm-plan-toggle" @click="workHoursOpen = !workHoursOpen">
              <span class="icon">schedule</span>
              {{ $t('master.schedule_title') }}
              <span class="icon hm-plan-toggle-arrow" :class="{ open: workHoursOpen }">expand_more</span>
            </button>

            <div v-if="workHoursOpen" class="hm-plan-work">
              <p class="hm-plan-work-hint">{{ $t('master.schedule_desc') }}</p>

              <div v-if="saved" class="hm-plan-saved">
                <span class="icon icon-sm">check_circle</span> {{ $t('profile.saved') }}
              </div>

              <div class="hm-plan-days">
                <div v-for="day in 7" :key="day - 1" class="hm-plan-day-row">
                  <label class="hm-plan-day-label">
                    <input type="checkbox" :checked="isDayActive(day - 1)" @change="toggleDay(day - 1)" />
                    <span class="hm-check-box"></span>
                    <strong>{{ $t('days.' + (day - 1)) }}</strong>
                  </label>
                  <div v-if="isDayActive(day - 1)" class="hm-plan-day-times">
                    <select v-model="hours[day - 1].start" class="hm-form-select hm-plan-time">
                      <option v-for="h in timeOptions" :key="h" :value="h">{{ h }}</option>
                    </select>
                    <span class="hm-plan-dash">—</span>
                    <select v-model="hours[day - 1].end" class="hm-form-select hm-plan-time">
                      <option v-for="h in timeOptions" :key="h" :value="h">{{ h }}</option>
                    </select>
                  </div>
                  <span v-else class="hm-plan-day-off">{{ $t('master.day_off') }}</span>
                </div>
              </div>

              <button class="hm-btn hm-btn-primary" @click="saveHours" :disabled="saving" style="margin-top: 12px">
                {{ saving ? $t('common.loading') : $t('profile.save') }}
              </button>
            </div>
          </section>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t, tm, rt, locale } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()

// Localised month & weekday names come from i18n (browser Intl has poor AZ support)
const monthNames = computed(() => (tm('cal.months') as any[]).map(m => rt(m)))
const monthShortNames = computed(() => (tm('cal.months_short') as any[]).map(m => rt(m)))
const weekdayShortNames = computed(() => (tm('cal.weekdays_short') as any[]).map(m => rt(m)))
const weekdayLongNames = computed(() => (tm('cal.weekdays_long') as any[]).map(m => rt(m)))

// BCP 47 tag for time formatting (HH:mm is supported in all locales)
const LOCALE_MAP: Record<string, string> = {
  az: 'az-AZ', ru: 'ru-RU', en: 'en-US', tr: 'tr-TR', ar: 'ar',
}
const dateLocale = computed(() => LOCALE_MAP[locale.value] || locale.value)

// ── Orders ──────────────────────────────────────────────────────────────────
interface RawOrder {
  id: number
  status: string
  description: string
  full_address: string
  estimated_budget: string | number | null
  scheduled_at: string | null
  desired_time: string
  accepted_at: string | null
  created_at: string
  category: { id: number; name: string; icon_url?: string } | null
  client: { first_name: string; last_name?: string } | null
}

const { data: rawOrders } = await useAsyncData('master-planner-orders', async () => {
  try {
    const res = await apiFetch<{ orders: RawOrder[] }>('/orders/my')
    return res.orders || []
  } catch { return [] as RawOrder[] }
}, { default: () => [] as RawOrder[] })

// Pick an "event date" for each order: scheduled_at → accepted_at → created_at
function orderDate(o: RawOrder): Date {
  const raw = (o.desired_time === 'scheduled' && o.scheduled_at)
    ? o.scheduled_at
    : (o.accepted_at || o.created_at)
  return new Date(raw)
}

const enrichedOrders = computed(() =>
  (rawOrders.value || [])
    .filter(o => !['draft', 'searching_master'].includes(o.status))
    .map(o => {
      const d = orderDate(o)
      return {
        ...o,
        date: d,
        key: dateKey(d),
        time: d.toLocaleTimeString(dateLocale.value, { hour: '2-digit', minute: '2-digit' }),
      }
    }),
)

// ── Calendar ────────────────────────────────────────────────────────────────
const now = new Date()
const cursor = reactive({ year: now.getFullYear(), month: now.getMonth() })
const selectedKey = ref(dateKey(now))
const todayKey = dateKey(now)

function dateKey(d: Date): string {
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0')
}

const weekdayShort = weekdayShortNames

const monthLabel = computed(() => `${monthNames.value[cursor.month] || ''} ${cursor.year}`)

interface CalendarCell {
  key: string
  day: number
  inMonth: boolean
  isToday: boolean
  isWorkDay: boolean
  events: any[]
}

const calendarCells = computed<CalendarCell[]>(() => {
  const first = new Date(cursor.year, cursor.month, 1)
  const startOffset = (first.getDay() + 6) % 7 // Mon=0
  const gridStart = new Date(cursor.year, cursor.month, 1 - startOffset)
  const cells: CalendarCell[] = []
  const eventsByKey = new Map<string, any[]>()
  for (const o of enrichedOrders.value) {
    if (!eventsByKey.has(o.key)) eventsByKey.set(o.key, [])
    eventsByKey.get(o.key)!.push(o)
  }
  for (const list of eventsByKey.values()) list.sort((a, b) => a.date.getTime() - b.date.getTime())

  for (let i = 0; i < 42; i++) {
    const d = new Date(gridStart); d.setDate(gridStart.getDate() + i)
    const k = dateKey(d)
    const weekdayIdx = (d.getDay() + 6) % 7 // Mon=0..Sun=6
    cells.push({
      key: k,
      day: d.getDate(),
      inMonth: d.getMonth() === cursor.month,
      isToday: k === todayKey,
      isWorkDay: !!hours[weekdayIdx]?.active,
      events: eventsByKey.get(k) || [],
    })
  }
  return cells
})

function shiftMonth(delta: number) {
  let m = cursor.month + delta
  let y = cursor.year
  while (m < 0) { m += 12; y-- }
  while (m > 11) { m -= 12; y++ }
  cursor.month = m; cursor.year = y
}

function goToday() {
  cursor.year = now.getFullYear()
  cursor.month = now.getMonth()
  selectedKey.value = todayKey
}

function selectDay(key: string) { selectedKey.value = key }

const selectedDayEvents = computed(() => enrichedOrders.value.filter(o => o.key === selectedKey.value))

const selectedDayLabel = computed(() => {
  const [y, m, d] = selectedKey.value.split('-').map(Number)
  const date = new Date(y, m - 1, d)
  const weekdayIdx = (date.getDay() + 6) % 7 // Mon=0..Sun=6
  const weekday = weekdayLongNames.value[weekdayIdx] || ''
  const month = monthNames.value[m - 1] || ''
  return `${weekday}, ${d} ${month}`
})

const activeOrdersCount = computed(() =>
  enrichedOrders.value.filter(o => ['accepted', 'confirmed', 'on_the_way', 'arrived', 'in_progress', 'awaiting_completion', 'pending_client', 'discussion'].includes(o.status)).length,
)

const upcomingOrders = computed(() => {
  const nowTs = Date.now()
  return enrichedOrders.value
    .filter(o => o.date.getTime() >= nowTs && ['accepted', 'confirmed', 'pending_client', 'discussion'].includes(o.status))
    .sort((a, b) => a.date.getTime() - b.date.getTime())
})

function statusKind(status: string): string {
  if (['accepted', 'confirmed', 'pending_client', 'discussion', 'on_the_way'].includes(status)) return 'upcoming'
  if (['arrived', 'in_progress', 'awaiting_completion'].includes(status)) return 'active'
  if (['completed', 'awaiting_review', 'closed'].includes(status)) return 'done'
  return 'cancel'
}

function formatShortDate(d: Date): string {
  const month = monthShortNames.value[d.getMonth()] || ''
  return `${d.getDate()} ${month}`
}

// ── Work hours editor ───────────────────────────────────────────────────────
const workHoursOpen = ref(false)
const saved = ref(false)
const saving = ref(false)

const timeOptions = Array.from({ length: 30 }, (_, i) => {
  const h = Math.floor(i / 2) + 7
  const m = i % 2 === 0 ? '00' : '30'
  return `${h.toString().padStart(2, '0')}:${m}`
})

const hours = reactive<Record<number, { active: boolean; start: string; end: string }>>({})
for (let i = 0; i < 7; i++) hours[i] = { active: false, start: '09:00', end: '18:00' }

function isDayActive(day: number) { return hours[day]?.active }
function toggleDay(day: number) { hours[day].active = !hours[day].active }

async function saveHours() {
  saving.value = true; saved.value = false
  const data = Object.entries(hours).filter(([, v]) => v.active).map(([k, v]) => ({ day: Number(k), start: v.start, end: v.end }))
  try { await apiFetch('/master/work-hours', { method: 'POST', body: { hours: data } }); saved.value = true } catch {}
  saving.value = false
}

onMounted(async () => {
  try {
    const res = await apiFetch<{ hours: any[] }>('/master/work-hours')
    for (const h of res.hours) {
      hours[h.day_of_week] = { active: true, start: h.start_time?.slice(0, 5) || '09:00', end: h.end_time?.slice(0, 5) || '18:00' }
    }
  } catch {}
})
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0 0 4px; color: var(--hm-text); letter-spacing: -0.4px; }

.hm-dash-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 16px;
  margin-bottom: 18px;
  flex-wrap: wrap;
}

.hm-plan-summary {
  display: flex;
  gap: 10px;
}
.hm-plan-summary > div {
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  padding: 10px 16px;
  text-align: center;
  min-width: 90px;
}
.hm-plan-summary strong {
  display: block;
  font-size: 22px;
  font-weight: 700;
  color: var(--hm-text);
  line-height: 1.1;
}
.hm-plan-summary span {
  font-size: 11.5px;
  color: var(--hm-text-3);
}

.hm-plan-card {
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  border-radius: 14px;
  padding: 20px;
  margin-bottom: 16px;
}

.hm-plan-head {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 14px;
}
.hm-plan-nav {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  border: 1px solid var(--hm-border);
  background: var(--hm-bg-2);
  color: var(--hm-text);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all .15s;
}
.hm-plan-nav:hover { border-color: var(--hm-accent); color: var(--hm-accent); }
.hm-plan-month {
  font-size: 16px;
  font-weight: 700;
  color: var(--hm-text);
  text-transform: capitalize;
}
.hm-plan-today { margin-left: auto; }

.hm-plan-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
}
.hm-plan-dow {
  text-align: center;
  font-size: 11px;
  font-weight: 600;
  color: var(--hm-text-3);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 6px 0;
}
.hm-plan-cell {
  min-height: 92px;
  padding: 6px;
  background: var(--hm-bg-2);
  border: 1px solid transparent;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  gap: 3px;
  transition: all .12s;
}
.hm-plan-cell:hover { border-color: var(--hm-accent); }
.hm-plan-cell-other { opacity: 0.35; }
.hm-plan-cell-offday { background: transparent; }
.hm-plan-cell-today .hm-plan-num {
  background: var(--hm-accent);
  color: #111;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
}
.hm-plan-cell-selected {
  border-color: var(--hm-accent);
  background: var(--hm-bg-card);
  box-shadow: 0 0 0 1px var(--hm-accent);
}
.hm-plan-num {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--hm-text);
}
.hm-plan-events {
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow: hidden;
}
.hm-plan-event {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 10.5px;
  color: var(--hm-text-2);
  background: rgba(255,255,255,0.05);
  border-radius: 4px;
  padding: 1px 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
html.theme-light .hm-plan-event { background: rgba(0,0,0,0.04); }
.hm-plan-ev-text { overflow: hidden; text-overflow: ellipsis; }
.hm-plan-more {
  font-size: 10px;
  color: var(--hm-text-3);
  font-weight: 600;
  padding: 0 4px;
}

.hm-plan-ev-dot {
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--hm-text-3);
  flex-shrink: 0;
}
.hm-plan-ev-upcoming .hm-plan-ev-dot, .hm-plan-ev-dot.hm-plan-ev-upcoming { background: #3b82f6; }
.hm-plan-ev-active .hm-plan-ev-dot, .hm-plan-ev-dot.hm-plan-ev-active { background: #facc15; }
.hm-plan-ev-done .hm-plan-ev-dot, .hm-plan-ev-dot.hm-plan-ev-done { background: #22c55e; }
.hm-plan-ev-cancel .hm-plan-ev-dot, .hm-plan-ev-dot.hm-plan-ev-cancel { background: #ef4444; }

.hm-plan-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px dashed var(--hm-border);
  font-size: 11.5px;
  color: var(--hm-text-3);
}
.hm-plan-legend span { display: inline-flex; align-items: center; gap: 6px; }

/* Sections */
.hm-plan-section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 700;
  color: var(--hm-text);
  margin: 0 0 14px;
  letter-spacing: -0.2px;
}
.hm-plan-section-title .icon { color: var(--hm-accent); font-size: 22px; }

/* Agenda list */
.hm-plan-empty {
  text-align: center;
  padding: 30px 20px;
  color: var(--hm-text-3);
}
.hm-plan-empty .icon { font-size: 40px; margin-bottom: 6px; display: block; }
.hm-plan-empty p { font-size: 13px; margin: 0; }

.hm-plan-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.hm-plan-item {
  display: flex;
  gap: 14px;
  align-items: center;
  padding: 12px 14px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border);
  border-left: 3px solid var(--hm-text-3);
  border-radius: 12px;
  text-decoration: none;
  transition: all .15s;
}
.hm-plan-item:hover { border-color: var(--hm-accent); transform: translateX(2px); }
.hm-plan-item-upcoming { border-left-color: #3b82f6; }
.hm-plan-item-active { border-left-color: #facc15; }
.hm-plan-item-done { border-left-color: #22c55e; }
.hm-plan-item-cancel { border-left-color: #ef4444; opacity: 0.7; }

.hm-plan-item-time {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 70px;
  text-align: center;
  padding: 4px 6px;
  background: var(--hm-bg-card);
  border-radius: 8px;
  flex-shrink: 0;
}
.hm-plan-item-hour {
  font-size: 14px;
  font-weight: 700;
  color: var(--hm-text);
}
.hm-plan-item-tag, .hm-plan-item-sub {
  font-size: 10px;
  color: var(--hm-text-3);
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.hm-plan-item-body { flex: 1; min-width: 0; }
.hm-plan-item-title {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 14px;
  font-weight: 700;
  color: var(--hm-text);
  margin-bottom: 3px;
}
.hm-plan-item-title .icon { color: var(--hm-accent); }
.hm-plan-item-desc {
  font-size: 12.5px;
  color: var(--hm-text-2);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
  margin-bottom: 4px;
}
.hm-plan-item-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  font-size: 11.5px;
  color: var(--hm-text-3);
}
.hm-plan-item-meta > span { display: inline-flex; align-items: center; gap: 3px; }
.hm-plan-item-meta .icon { font-size: 14px; }

.hm-plan-item-arrow {
  color: var(--hm-text-3);
  font-size: 22px;
  flex-shrink: 0;
}

/* Work hours editor */
.hm-plan-toggle {
  cursor: pointer;
  user-select: none;
  width: 100%;
  text-align: left;
  border: none;
  background: transparent;
  padding: 0;
}
.hm-plan-toggle-arrow {
  margin-left: auto;
  font-size: 22px;
  color: var(--hm-text-3);
  transition: transform .2s;
}
.hm-plan-toggle-arrow.open { transform: rotate(180deg); }

.hm-plan-work-hint {
  font-size: 13px;
  color: var(--hm-text-3);
  margin: 0 0 14px;
}
.hm-plan-saved {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: rgba(34,197,94,0.1);
  color: #22c55e;
  border: 1px solid rgba(34,197,94,0.3);
  padding: 8px 12px;
  border-radius: 10px;
  font-size: 13px;
  margin-bottom: 14px;
}
.hm-plan-days { display: flex; flex-direction: column; gap: 8px; max-width: 560px; }
.hm-plan-day-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border);
  border-radius: 12px;
}
.hm-plan-day-label {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 140px;
  cursor: pointer;
}
.hm-plan-day-label input { display: none; }
.hm-plan-day-label strong { font-size: 13.5px; color: var(--hm-text); }
.hm-plan-day-times {
  display: flex;
  align-items: center;
  gap: 8px;
}
.hm-plan-time {
  width: 90px;
  padding: 6px 10px;
  font-size: 13px;
}
.hm-plan-dash { color: var(--hm-text-3); }
.hm-plan-day-off {
  font-size: 12px;
  color: var(--hm-text-3);
  font-style: italic;
}

@media (max-width: 640px) {
  .hm-plan-cell { min-height: 64px; padding: 4px; }
  .hm-plan-event { font-size: 9px; }
  .hm-plan-ev-text { display: none; }
  .hm-plan-item { flex-wrap: wrap; }
  .hm-plan-item-time { min-width: 56px; }
}
</style>
