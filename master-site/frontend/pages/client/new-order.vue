<template>
  <div class="hm-page ord-new">
    <div class="hm-page-inner">
      <nav class="hm-breadcrumb">
        <NuxtLink :to="localePath('/')">{{ $t('nav.home') }}</NuxtLink>
        <span class="hm-breadcrumb-sep">›</span>
        <NuxtLink :to="localePath('/masters')">{{ $t('nav.masters') }}</NuxtLink>
        <span class="hm-breadcrumb-sep">›</span>
        <span class="hm-breadcrumb-current">{{ $t('order_form.title') }}</span>
      </nav>

      <!-- === SUCCESS === -->
      <div v-if="success" class="ord-success">
        <div class="ord-success-icon"><span class="icon">check_circle</span></div>
        <h1>{{ $t('order_form.success') }}</h1>
        <p>{{ $t('order_form.success_sub') }}</p>
        <NuxtLink :to="localePath('/client/orders')" class="ord-success-cta">
          {{ $t('order_form.go_to_orders') }}
          <span class="icon icon-sm">arrow_forward</span>
        </NuxtLink>
      </div>

      <!-- === FORM === -->
      <form v-else @submit.prevent="handleSubmit" class="ord-grid">
        <div class="ord-main">
          <!-- Header -->
          <header class="ord-header">
            <h1>{{ $t('order_form.title') }}</h1>
            <p>{{ $t('order_form.subtitle') }}</p>
          </header>

          <!-- Master pill -->
          <div v-if="selectedMasterName" class="ord-master-chip">
            <div class="ord-master-chip-avatar">{{ selectedMasterName.charAt(0).toUpperCase() }}</div>
            <div class="ord-master-chip-body">
              <strong>{{ selectedMasterName }}</strong>
              <span>{{ $t('masters.call_this_master') }}</span>
            </div>
            <button type="button" class="ord-master-chip-x" @click="clearMaster" :title="$t('order_form.clear_master')">
              <span class="icon icon-sm">close</span>
            </button>
          </div>

          <!-- Error banner -->
          <div v-if="error" class="ord-error">
            <span class="icon">error_outline</span>
            <span>{{ error }}</span>
          </div>

          <!-- ==== STEP 1 / CATEGORY ==== -->
          <section class="ord-card" v-if="!preferredMasterId || masterCategories.length > 1">
            <header class="ord-card-head">
              <div class="ord-card-num">01</div>
              <div>
                <h2>{{ $t('order_form.category') }}</h2>
                <p>{{ $t('order_form.category_hint') }}</p>
              </div>
            </header>
            <div class="ord-cat-grid">
              <button
                v-for="c in availableCats"
                :key="c.id"
                type="button"
                class="ord-cat"
                :class="{ active: form.category_id == c.id }"
                @click="form.category_id = c.id; onCategoryChange()"
              >
                <span class="ord-cat-emoji"><CatIcon :icon="c.icon_url" fallback="build" /></span>
                <span class="ord-cat-name">{{ c.name }}</span>
                <span class="ord-cat-desc">{{ c.description || '' }}</span>
                <span v-if="form.category_id == c.id" class="ord-cat-check">
                  <span class="icon icon-sm">check</span>
                </span>
              </button>
            </div>

            <div v-if="subcategories.length" class="ord-subcat-row">
              <label class="ord-label">{{ $t('order_form.subcategory') }}</label>
              <select v-model="form.subcategory_id" class="ord-select">
                <option value="">{{ $t('order_form.select') }}</option>
                <option v-for="s in subcategories" :key="s.id" :value="s.id">{{ s.name }}</option>
              </select>
            </div>

            <div class="ord-suggest-row">
              <span class="ord-suggest-text">{{ $t('cat_sugg.missing_hint') }}</span>
              <SuggestCategoryBtn />
            </div>
          </section>

          <!-- Category locked (single master cat) -->
          <section class="ord-card ord-card-compact" v-else-if="form.category_id">
            <div class="ord-locked">
              <span class="icon">verified</span>
              <div>
                <div class="ord-locked-ttl">{{ $t('order_form.category') }}</div>
                <div class="ord-locked-val">{{ categories.find((c) => c.id == form.category_id)?.name }}</div>
              </div>
            </div>
          </section>

          <!-- ==== STEP 2 / WHEN ==== -->
          <section class="ord-card">
            <header class="ord-card-head">
              <div class="ord-card-num">02</div>
              <div>
                <h2>{{ $t('order_form.date_time') }}</h2>
                <p>{{ $t('order_form.date_time_hint') }}</p>
              </div>
            </header>

            <div class="ord-when-tabs">
              <button
                type="button"
                class="ord-when-tab"
                :class="{ active: form.desired_time === 'asap' }"
                @click="form.desired_time = 'asap'"
              >
                <span class="icon">bolt</span>
                <div>
                  <strong>{{ $t('order_form.asap') }}</strong>
                  <span>{{ $t('order_form.asap_hint') }}</span>
                </div>
              </button>
              <button
                type="button"
                class="ord-when-tab"
                :class="{ active: form.desired_time === 'scheduled' }"
                @click="form.desired_time = 'scheduled'"
              >
                <span class="icon">event</span>
                <div>
                  <strong>{{ $t('order_form.scheduled') }}</strong>
                  <span>{{ $t('order_form.scheduled_hint') }}</span>
                </div>
              </button>
            </div>

            <div v-if="form.desired_time === 'scheduled'" class="ord-cal">
              <div class="ord-cal-head">
                <div class="ord-cal-month">{{ monthLabel }}</div>
                <div class="ord-cal-nav">
                  <button type="button" @click="shiftMonth(-1)" :disabled="calOffset === 0"><span class="icon">chevron_left</span></button>
                  <button type="button" @click="shiftMonth(1)"><span class="icon">chevron_right</span></button>
                </div>
              </div>
              <div class="ord-cal-grid">
                <button
                  v-for="day in calendarDays"
                  :key="day.key"
                  type="button"
                  class="ord-cal-day"
                  :class="{ active: day.iso === selectedDate, disabled: day.disabled }"
                  :disabled="day.disabled"
                  @click="pickDate(day.iso)"
                >
                  <span class="ord-cal-day-dow">{{ day.dow }}</span>
                  <span class="ord-cal-day-d">{{ day.d }}</span>
                </button>
              </div>
              <div class="ord-time-section">
                <div class="ord-label">{{ $t('order_form.time') }}</div>
                <div class="ord-time-chips">
                  <button
                    v-for="t in timeSlots"
                    :key="t"
                    type="button"
                    class="ord-time-chip"
                    :class="{ active: selectedTime === t }"
                    @click="pickTime(t)"
                  >{{ t }}</button>
                </div>
              </div>
            </div>
          </section>

          <!-- ==== STEP 3 / WHERE ==== -->
          <section class="ord-card">
            <header class="ord-card-head">
              <div class="ord-card-num">03</div>
              <div>
                <h2>{{ $t('order_form.address') }}</h2>
                <p>{{ $t('order_form.address_hint') }}</p>
              </div>
            </header>

            <div v-if="addresses.length" class="ord-addr-list">
              <label
                v-for="addr in addresses"
                :key="addr.id"
                class="ord-addr"
                :class="{ selected: selectedAddrId === addr.id }"
              >
                <input
                  type="radio"
                  name="ord-addr"
                  :value="addr.id"
                  :checked="selectedAddrId === addr.id"
                  @change="selectAddress(addr)"
                  hidden
                />
                <span class="ord-addr-dot"></span>
                <div class="ord-addr-body">
                  <strong>
                    <span class="icon icon-sm">{{ addr.is_default ? 'home' : 'location_on' }}</span>
                    {{ addr.label || $t('common.address_label') }}
                  </strong>
                  <span>{{ addr.full_address }}</span>
                </div>
                <span v-if="addr.is_default" class="ord-addr-badge">{{ $t('address.default') }}</span>
              </label>
              <label
                class="ord-addr ord-addr-new"
                :class="{ selected: selectedAddrId === null && manualAddr }"
              >
                <input
                  type="radio"
                  name="ord-addr"
                  value="new"
                  :checked="selectedAddrId === null && manualAddr"
                  @change="selectedAddrId = null; manualAddr = true"
                  hidden
                />
                <span class="ord-addr-dot"></span>
                <div class="ord-addr-body">
                  <strong>
                    <span class="icon icon-sm">add_location</span>
                    {{ $t('address.or_new') }}
                  </strong>
                </div>
              </label>
            </div>

            <div v-if="!addresses.length || (selectedAddrId === null && manualAddr)" class="ord-addr-form">
              <AddressMapPicker :lat="newAddrLat" :lng="newAddrLng" @update="onNewAddrMap" />
              <div class="ord-field">
                <label class="ord-label">{{ $t('order_form.address_placeholder') }}</label>
                <input
                  v-model="form.full_address"
                  type="text"
                  class="ord-input"
                  :placeholder="$t('order_form.address_placeholder')"
                  :required="!selectedAddrId"
                />
              </div>
              <div class="ord-field-row">
                <div class="ord-field">
                  <label class="ord-label">{{ $t('order_form.entrance') }}</label>
                  <input v-model="form.entrance" type="text" class="ord-input" placeholder="—" />
                </div>
                <div class="ord-field">
                  <label class="ord-label">{{ $t('order_form.floor') }}</label>
                  <input v-model="form.floor" type="text" class="ord-input" placeholder="—" />
                </div>
                <div class="ord-field">
                  <label class="ord-label">{{ $t('order_form.intercom') }}</label>
                  <input v-model="form.intercom" type="text" class="ord-input" placeholder="—" />
                </div>
              </div>
              <div class="ord-field">
                <label class="ord-label">{{ $t('address.label') }}</label>
                <input v-model="newAddrLabel" type="text" class="ord-input" :placeholder="$t('address.label_hint')" />
              </div>
              <label class="ord-check">
                <input type="checkbox" v-model="saveNewAddr" />
                <span class="ord-check-box"><span class="icon icon-sm">check</span></span>
                <span>{{ $t('address.save_to_profile') }}</span>
              </label>
            </div>
          </section>

          <!-- ==== STEP 4 / DETAILS ==== -->
          <section class="ord-card">
            <header class="ord-card-head">
              <div class="ord-card-num">04</div>
              <div>
                <h2>{{ $t('order_form.description') }}</h2>
                <p>{{ $t('order_form.description_hint') }}</p>
              </div>
            </header>

            <div class="ord-field">
              <label class="ord-label">{{ $t('order_form.description') }} *</label>
              <textarea
                v-model="form.description"
                rows="4"
                class="ord-input ord-textarea"
                :placeholder="$t('order_form.description_placeholder')"
                required
              ></textarea>
            </div>

            <div class="ord-field-row">
              <div class="ord-field">
                <label class="ord-label">{{ $t('order_form.contact_phone') }} *</label>
                <input v-model="form.contact_phone" type="tel" class="ord-input" placeholder="+994 XX XXX XX XX" required />
              </div>
            </div>

            <div class="ord-field">
              <label class="ord-label">{{ $t('order_form.comment') }}</label>
              <textarea
                v-model="form.comment"
                rows="2"
                class="ord-input ord-textarea"
                :placeholder="$t('order_form.comment_placeholder')"
              ></textarea>
            </div>

            <div class="ord-field">
              <label class="ord-label">
                <span class="icon icon-sm">photo_camera</span>
                {{ $t('order_form.photos') }}
                <span class="ord-label-hint">({{ orderPhotos.length }}/5)</span>
              </label>
              <div class="ord-photos">
                <div v-for="(photo, i) in orderPhotos" :key="i" class="ord-photo">
                  <img :src="photo" />
                  <button type="button" class="ord-photo-x" @click="orderPhotos.splice(i, 1)">
                    <span class="icon icon-sm">close</span>
                  </button>
                </div>
                <label v-if="orderPhotos.length < 5" class="ord-photo-add">
                  <span class="icon">add_photo_alternate</span>
                  <span>{{ $t('order_form.add_photo') }}</span>
                  <input type="file" accept="image/*" multiple hidden @change="handleOrderPhotos" />
                </label>
              </div>
            </div>
          </section>
        </div>

        <!-- === RIGHT SUMMARY === -->
        <aside class="ord-aside">
          <div class="ord-summary">
            <div class="ord-summary-h">
              <span class="icon">receipt_long</span>
              {{ $t('order_form.summary_title') }}
            </div>

            <dl class="ord-summary-list">
              <div class="ord-summary-row">
                <dt><span class="icon icon-sm">build</span>{{ $t('order_form.category') }}</dt>
                <dd>{{ summaryCategory }}</dd>
              </div>
              <div class="ord-summary-row">
                <dt><span class="icon icon-sm">event</span>{{ $t('order_form.date_time') }}</dt>
                <dd>{{ summaryDate }}</dd>
              </div>
              <div class="ord-summary-row">
                <dt><span class="icon icon-sm">location_on</span>{{ $t('order_form.address') }}</dt>
                <dd class="ord-summary-ellipsis">{{ form.full_address || '—' }}</dd>
              </div>
              <div class="ord-summary-row" v-if="orderPhotos.length">
                <dt><span class="icon icon-sm">photo_camera</span>{{ $t('order_form.photos') }}</dt>
                <dd>{{ orderPhotos.length }}</dd>
              </div>
            </dl>

            <button
              type="submit"
              class="ord-submit"
              :disabled="loading || !canSubmit"
            >
              <span v-if="loading" class="ord-spin"></span>
              <span v-else class="icon icon-sm">rocket_launch</span>
              {{ loading ? $t('order_form.submitting') : $t('order_form.submit') }}
            </button>

            <p class="ord-summary-footnote">
              <span class="icon icon-sm">shield</span>
              {{ $t('order_form.agreement') }}
            </p>
          </div>
        </aside>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const auth = useAuthStore()
const route = useRoute()

const categories = ref<any[]>([])
const subcategories = ref<any[]>([])
const addresses = ref<any[]>([])
const selectedAddrId = ref<number | null>(null)
const manualAddr = ref(false)
const loading = ref(false)
const error = ref('')
const success = ref(false)

const preferredMasterId = ref(route.query.master_id ? Number(route.query.master_id) : null)
const selectedMasterName = ref(route.query.master_name ? decodeURIComponent(route.query.master_name as string) : '')
const masterCategories = ref<any[]>([])

function clearMaster() {
  preferredMasterId.value = null
  selectedMasterName.value = ''
  masterCategories.value = []
  form.category_id = ''
}

const availableCats = computed(() => {
  if (preferredMasterId.value && masterCategories.value.length > 1) return masterCategories.value
  return categories.value
})

function selectAddress(addr: any) {
  selectedAddrId.value = addr.id
  manualAddr.value = false
  form.full_address = addr.full_address
  form.entrance = addr.entrance || ''
  form.floor = addr.floor || ''
  form.intercom = addr.intercom || ''
}

const form = reactive({
  category_id: '' as any,
  subcategory_id: '' as any,
  description: '',
  full_address: '',
  entrance: '',
  floor: '',
  intercom: '',
  contact_phone: auth.user?.phone || '',
  desired_time: 'asap',
  scheduled_at: '',
  urgency: 'normal',
  comment: '',
})
const orderPhotos = ref<string[]>([])
const newAddrLat = ref<number | null>(null)
const newAddrLng = ref<number | null>(null)
const newAddrLabel = ref('')
const saveNewAddr = ref(true)

function onNewAddrMap(data: { lat: number; lng: number; address: string }) {
  newAddrLat.value = data.lat
  newAddrLng.value = data.lng
  form.full_address = data.address
}

function handleOrderPhotos(e: Event) {
  const files = (e.target as HTMLInputElement).files
  if (!files) return
  const remaining = 5 - orderPhotos.value.length
  Array.from(files).slice(0, remaining).forEach((file) => {
    if (file.size > 5 * 1024 * 1024) return
    const reader = new FileReader()
    reader.onload = () => { orderPhotos.value.push(reader.result as string) }
    reader.readAsDataURL(file)
  })
  ;(e.target as HTMLInputElement).value = ''
}

async function onCategoryChange() {
  form.subcategory_id = ''
  if (!form.category_id) { subcategories.value = []; return }
  try {
    const res = await apiFetch<{ category: any }>(`/categories/${form.category_id}`)
    subcategories.value = res.category.subcategories || []
  } catch { subcategories.value = [] }
}

// Calendar
const calOffset = ref(0)
const today = new Date()
today.setHours(0, 0, 0, 0)

const calBaseDate = computed(() => new Date(today.getFullYear(), today.getMonth() + calOffset.value, 1))

const monthLabel = computed(() => {
  const d = calBaseDate.value
  const locale = (useI18n() as any).locale?.value || 'ru'
  return d.toLocaleDateString(locale, { month: 'long', year: 'numeric' })
})

function pad(n: number) { return String(n).padStart(2, '0') }
function isoOf(d: Date) { return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` }

const calendarDays = computed(() => {
  const base = calBaseDate.value
  const daysInMonth = new Date(base.getFullYear(), base.getMonth() + 1, 0).getDate()
  const out: any[] = []
  const isCurrent = calOffset.value === 0
  const start = isCurrent ? today.getDate() : 1
  const locale = (useI18n() as any).locale?.value || 'ru'
  for (let d = start; d <= daysInMonth; d++) {
    const dt = new Date(base.getFullYear(), base.getMonth(), d)
    out.push({
      key: isoOf(dt),
      iso: isoOf(dt),
      d,
      dow: dt.toLocaleDateString(locale, { weekday: 'short' }),
      disabled: false,
    })
    if (out.length >= 14) break
  }
  return out
})

const selectedDate = ref<string>('')
const selectedTime = ref<string>('')
const timeSlots = ['09:00', '11:00', '13:00', '15:00', '17:00', '19:00']

function pickDate(iso: string) {
  selectedDate.value = iso
  if (!selectedTime.value) selectedTime.value = timeSlots[2]
  syncScheduled()
}
function pickTime(t: string) {
  selectedTime.value = t
  if (!selectedDate.value && calendarDays.value.length) selectedDate.value = calendarDays.value[0].iso
  syncScheduled()
}
function syncScheduled() {
  if (selectedDate.value && selectedTime.value) {
    form.scheduled_at = `${selectedDate.value}T${selectedTime.value}`
  }
}
function shiftMonth(delta: number) {
  calOffset.value = Math.max(0, calOffset.value + delta)
}

const summaryCategory = computed(() => {
  if (!form.category_id) return '—'
  return categories.value.find((c) => c.id == form.category_id)?.name || '—'
})
const summaryDate = computed(() => {
  if (form.desired_time === 'asap') return $t('order_form.asap')
  if (selectedDate.value && selectedTime.value) {
    return `${new Date(selectedDate.value).toLocaleDateString()} · ${selectedTime.value}`
  }
  return $t('order_form.scheduled')
})

const canSubmit = computed(() => {
  return !!form.category_id
    && !!form.description
    && !!form.full_address
    && !!form.contact_phone
})

onMounted(async () => {
  try { const res = await apiFetch<{ addresses: any[] }>('/addresses'); addresses.value = res.addresses; const def = res.addresses.find((a: any) => a.is_default); if (def) selectAddress(def) } catch {}
  try { const res = await apiFetch<{ categories: any[] }>('/categories?only_with_masters=1'); categories.value = res.categories } catch {}
  if (preferredMasterId.value) {
    try {
      const res = await apiFetch<{ master: any }>(`/masters/${preferredMasterId.value}`)
      selectedMasterName.value = res.master.full_name
      masterCategories.value = res.master.categories || []
      if (masterCategories.value.length === 1) {
        form.category_id = masterCategories.value[0].id
        onCategoryChange()
      }
    } catch {}
  }
})

async function handleSubmit() {
  loading.value = true; error.value = ''
  try {
    await apiFetch('/orders', {
      method: 'POST',
      body: {
        ...form,
        scheduled_at: form.scheduled_at || undefined,
        subcategory_id: form.subcategory_id || undefined,
        preferred_master_id: preferredMasterId.value || undefined,
        photos: orderPhotos.value.length ? orderPhotos.value : undefined,
      },
    })
    if (saveNewAddr.value && !selectedAddrId.value && form.full_address) {
      try {
        await apiFetch('/addresses', {
          method: 'POST',
          body: {
            label: newAddrLabel.value || undefined,
            full_address: form.full_address,
            lat: newAddrLat.value,
            lng: newAddrLng.value,
            entrance: form.entrance || undefined,
            floor: form.floor || undefined,
            intercom: form.intercom || undefined,
          },
        })
      } catch {}
    }
    success.value = true
  } catch (e: any) {
    error.value = e?.data?.errors ? Object.values(e.data.errors).flat().join('. ') : (e?.data?.message || $t('auth.error_occurred'))
  }
  loading.value = false
}
</script>

<style scoped>
.ord-new { }

/* Grid layout */
.ord-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 400px;
  gap: 28px;
  align-items: start;
}
@media (max-width: 1020px) {
  .ord-grid { grid-template-columns: 1fr; }
}

.ord-main { display: flex; flex-direction: column; gap: 18px; min-width: 0; }

/* Header */
.ord-header h1 {
  font-family: "Public Sans", sans-serif;
  font-size: clamp(1.75rem, 3vw, 2.25rem);
  font-weight: 700; letter-spacing: -0.025em;
  color: var(--hm-text);
  margin: 0 0 6px;
}
.ord-header p { color: var(--hm-text-3); font-size: 15px; margin: 0; line-height: 1.6; }

/* Master pill */
.ord-master-chip {
  display: flex; align-items: center; gap: 14px;
  padding: 14px 16px;
  background: rgba(255, 255, 0, 0.06);
  border: 1px solid var(--hm-accent);
  border-radius: 16px;
}
:global(html.theme-light) .ord-master-chip { background: rgba(177, 127, 0, 0.06); border-color: #b07f00; }
.ord-master-chip-avatar {
  width: 42px; height: 42px; border-radius: 12px;
  background: var(--hm-accent); color: #000;
  display: grid; place-items: center;
  font-weight: 800; font-size: 18px; flex-shrink: 0;
  font-family: "Public Sans", sans-serif;
}
:global(html.theme-light) .ord-master-chip-avatar { background: #facc15; color: #111; }
.ord-master-chip-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.ord-master-chip-body strong { color: var(--hm-text); font-size: 15px; font-weight: 700; }
.ord-master-chip-body span { color: var(--hm-text-3); font-size: 12px; }
.ord-master-chip-x {
  width: 32px; height: 32px; border-radius: 50%;
  background: transparent;
  border: 1px solid var(--hm-border-2);
  color: var(--hm-text-3);
  display: grid; place-items: center; cursor: pointer;
  transition: all 0.15s;
}
.ord-master-chip-x:hover { color: #ef4444; border-color: #ef4444; }

/* Error */
.ord-error {
  display: flex; align-items: center; gap: 10px;
  padding: 14px 18px;
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 14px;
  color: #ef4444;
  font-size: 14px;
  font-weight: 500;
}

/* Step card */
.ord-card {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 24px;
  padding: 28px;
}
:global(html.theme-light) .ord-card { background: #fff; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04); }
.ord-card-compact { padding: 16px 20px; }

.ord-card-head {
  display: flex; align-items: flex-start; gap: 16px;
  margin-bottom: 20px;
}
.ord-card-num {
  width: 40px; height: 40px; flex-shrink: 0;
  border-radius: 12px;
  background: var(--hm-bg-3);
  color: var(--hm-accent);
  display: grid; place-items: center;
  font-weight: 800; font-size: 14px;
  font-family: "Public Sans", sans-serif;
  letter-spacing: 0.5px;
}
:global(html.theme-light) .ord-card-num { background: rgba(177, 127, 0, 0.1); color: #b07f00; }
.ord-card-head h2 {
  font-family: "Public Sans", sans-serif;
  font-size: 19px; font-weight: 700;
  color: var(--hm-text);
  margin: 0 0 4px;
  letter-spacing: -0.015em;
}
.ord-card-head p { color: var(--hm-text-3); font-size: 13px; margin: 0; line-height: 1.5; }

/* Locked category */
.ord-locked {
  display: flex; align-items: center; gap: 14px;
  padding: 14px;
  background: var(--hm-bg-2);
  border-radius: 12px;
}
.ord-locked .icon { color: var(--hm-accent); font-size: 22px; }
:global(html.theme-light) .ord-locked .icon { color: #b07f00; }
.ord-locked-ttl { font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--hm-text-3); font-weight: 600; }
.ord-locked-val { font-size: 15px; font-weight: 700; color: var(--hm-text); margin-top: 2px; }

/* Category grid */
.ord-cat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 10px;
}
.ord-cat {
  display: flex; flex-direction: column; gap: 4px;
  padding: 16px 14px;
  background: var(--hm-bg-2);
  border: 1.5px solid var(--hm-border-2);
  border-radius: 14px;
  cursor: pointer;
  text-align: left;
  font-family: inherit;
  transition: all 0.15s;
  position: relative;
}
.ord-cat:hover { border-color: var(--hm-border); transform: translateY(-1px); }
.ord-cat.active {
  border-color: var(--hm-accent);
  background: rgba(255, 255, 0, 0.06);
}
:global(html.theme-light) .ord-cat.active { border-color: #b07f00; background: rgba(177, 127, 0, 0.06); }
.ord-cat-emoji { font-size: 24px; line-height: 1; margin-bottom: 4px; }
.ord-cat-name { color: var(--hm-text); font-size: 14px; font-weight: 700; }
.ord-cat-desc {
  color: var(--hm-text-3); font-size: 11px; line-height: 1.4;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.ord-cat-check {
  position: absolute; top: 10px; right: 10px;
  width: 22px; height: 22px; border-radius: 50%;
  background: var(--hm-accent); color: #000;
  display: grid; place-items: center;
}
:global(html.theme-light) .ord-cat-check { background: #facc15; color: #111; }
.ord-cat-check .icon { font-size: 14px; }

.ord-subcat-row { margin-top: 14px; }

.ord-suggest-row {
  margin-top: 18px;
  padding-top: 14px;
  border-top: 1px dashed var(--hm-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
.ord-suggest-text { font-size: 12.5px; color: var(--hm-text-3); }

/* When tabs */
.ord-when-tabs {
  display: grid; grid-template-columns: 1fr 1fr; gap: 10px;
  margin-bottom: 20px;
}
@media (max-width: 520px) {
  .ord-when-tabs { grid-template-columns: 1fr; }
}
.ord-when-tab {
  display: flex; align-items: center; gap: 12px;
  padding: 16px 18px;
  background: var(--hm-bg-2);
  border: 1.5px solid var(--hm-border-2);
  border-radius: 14px;
  cursor: pointer;
  text-align: left;
  font-family: inherit;
  transition: all 0.15s;
}
.ord-when-tab:hover { border-color: var(--hm-border); }
.ord-when-tab.active {
  border-color: var(--hm-accent);
  background: rgba(255, 255, 0, 0.06);
}
:global(html.theme-light) .ord-when-tab.active { border-color: #b07f00; background: rgba(177, 127, 0, 0.06); }
.ord-when-tab .icon {
  color: var(--hm-accent); font-size: 24px;
  padding: 8px; border-radius: 10px; background: var(--hm-bg-3);
}
:global(html.theme-light) .ord-when-tab .icon { color: #b07f00; background: rgba(177, 127, 0, 0.1); }
.ord-when-tab > div { display: flex; flex-direction: column; gap: 2px; }
.ord-when-tab strong { color: var(--hm-text); font-size: 15px; font-weight: 700; }
.ord-when-tab span { color: var(--hm-text-3); font-size: 12px; }

/* Calendar */
.ord-cal {
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
  padding: 18px;
}
.ord-cal-head {
  display: flex; align-items: center; justify-content: space-between;
  margin-bottom: 14px;
}
.ord-cal-month { color: var(--hm-text); font-size: 15px; font-weight: 700; text-transform: capitalize; }
.ord-cal-nav { display: flex; gap: 6px; }
.ord-cal-nav button {
  width: 32px; height: 32px; border-radius: 50%;
  background: var(--hm-bg-3); border: 0; cursor: pointer;
  color: var(--hm-text); display: grid; place-items: center;
  transition: background 0.15s;
}
.ord-cal-nav button:hover:not(:disabled) { background: var(--hm-border); }
.ord-cal-nav button:disabled { opacity: 0.3; cursor: not-allowed; }
.ord-cal-nav .icon { font-size: 18px; }

.ord-cal-grid {
  display: grid; grid-template-columns: repeat(7, 1fr); gap: 6px;
  margin-bottom: 18px;
}
.ord-cal-day {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  aspect-ratio: 1;
  background: transparent;
  border: 1px solid var(--hm-border-2);
  border-radius: 10px;
  color: var(--hm-text);
  font-family: inherit;
  cursor: pointer;
  gap: 2px;
  transition: all 0.15s;
}
.ord-cal-day:hover:not(.disabled):not(.active) { background: var(--hm-bg-3); }
.ord-cal-day.active {
  background: var(--hm-accent);
  border-color: transparent;
  color: #000;
}
:global(html.theme-light) .ord-cal-day.active { background: #facc15; color: #111; }
.ord-cal-day.disabled { opacity: 0.3; cursor: not-allowed; }
.ord-cal-day-dow { font-size: 9px; text-transform: uppercase; opacity: 0.6; }
.ord-cal-day-d { font-size: 14px; font-weight: 700; }

.ord-time-section { padding-top: 16px; border-top: 1px solid var(--hm-border-2); }
.ord-time-chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 10px; }
.ord-time-chip {
  padding: 9px 16px;
  background: transparent;
  border: 1px solid var(--hm-border-2);
  border-radius: 999px;
  color: var(--hm-text);
  font-family: inherit; font-size: 13px; font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.ord-time-chip:hover:not(.active) { background: var(--hm-bg-3); }
.ord-time-chip.active {
  background: var(--hm-accent); color: #000; border-color: transparent;
}
:global(html.theme-light) .ord-time-chip.active { background: #facc15; color: #111; }

/* Labels & inputs */
.ord-label {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 12px; font-weight: 600; letter-spacing: 0.3px;
  color: var(--hm-text-2); text-transform: uppercase;
}
.ord-label .icon { color: var(--hm-accent); font-size: 14px; }
:global(html.theme-light) .ord-label .icon { color: #b07f00; }
.ord-label-hint { color: var(--hm-text-3); font-size: 11px; font-weight: 500; text-transform: none; letter-spacing: 0; }
.ord-field { display: flex; flex-direction: column; gap: 8px; margin-top: 16px; }
.ord-field:first-child { margin-top: 0; }
.ord-field-row {
  display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px;
  margin-top: 16px;
}
.ord-field-row > .ord-field { margin-top: 0; }
.ord-field-row.two { grid-template-columns: 1fr 1fr; }
@media (max-width: 600px) {
  .ord-field-row { grid-template-columns: 1fr; }
}

.ord-input, .ord-select, .ord-textarea {
  width: 100%;
  padding: 13px 16px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 12px;
  color: var(--hm-text);
  font-family: inherit;
  font-size: 14px;
  transition: border-color 0.15s;
}
.ord-input:focus, .ord-select:focus, .ord-textarea:focus {
  border-color: var(--hm-accent); outline: 0;
}
:global(html.theme-light) .ord-input:focus,
:global(html.theme-light) .ord-select:focus,
:global(html.theme-light) .ord-textarea:focus { border-color: #b07f00; }
.ord-input::placeholder, .ord-textarea::placeholder { color: var(--hm-text-3); }
.ord-textarea { resize: vertical; min-height: 80px; line-height: 1.5; }
.ord-select {
  appearance: none; -webkit-appearance: none; -moz-appearance: none;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8' fill='%2399a'><path d='M6 8L0 0h12z'/></svg>");
  background-repeat: no-repeat;
  background-position: right 14px center;
  padding-right: 36px;
}

.ord-input-group { position: relative; display: flex; align-items: center; }
.ord-input-group .ord-input { padding-right: 40px; }
.ord-input-suffix {
  position: absolute; right: 14px; color: var(--hm-text-3);
  font-weight: 700; pointer-events: none;
}

/* Address radio list */
.ord-addr-list { display: flex; flex-direction: column; gap: 8px; }
.ord-addr {
  display: flex; align-items: center; gap: 12px;
  padding: 14px 16px;
  background: var(--hm-bg-2);
  border: 1.5px solid var(--hm-border-2);
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.15s;
}
.ord-addr:hover { border-color: var(--hm-border); }
.ord-addr.selected {
  border-color: var(--hm-accent);
  background: rgba(255, 255, 0, 0.06);
}
:global(html.theme-light) .ord-addr.selected { border-color: #b07f00; background: rgba(177, 127, 0, 0.06); }
.ord-addr-dot {
  width: 20px; height: 20px; border-radius: 50%;
  border: 1.5px solid var(--hm-border); flex-shrink: 0;
  position: relative;
  transition: border-color 0.15s;
}
.ord-addr.selected .ord-addr-dot { border-color: var(--hm-accent); }
.ord-addr.selected .ord-addr-dot::after {
  content: ''; position: absolute; inset: 3px;
  background: var(--hm-accent); border-radius: 50%;
}
:global(html.theme-light) .ord-addr.selected .ord-addr-dot,
:global(html.theme-light) .ord-addr.selected .ord-addr-dot::after { border-color: #b07f00; background: #b07f00; }
.ord-addr-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.ord-addr-body strong {
  display: inline-flex; align-items: center; gap: 6px;
  color: var(--hm-text); font-size: 14px; font-weight: 700;
}
.ord-addr-body strong .icon { color: var(--hm-accent); font-size: 15px; }
:global(html.theme-light) .ord-addr-body strong .icon { color: #b07f00; }
.ord-addr-body span {
  color: var(--hm-text-3); font-size: 13px;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.ord-addr-badge {
  padding: 3px 9px; border-radius: 999px;
  background: var(--hm-accent); color: #000;
  font-size: 9px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px;
}
:global(html.theme-light) .ord-addr-badge { background: #facc15; color: #111; }
.ord-addr-new { border-style: dashed; }

/* Address form (for new) */
.ord-addr-form {
  display: flex; flex-direction: column; gap: 14px;
  margin-top: 14px;
  padding: 18px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
}

/* Checkbox */
.ord-check {
  display: inline-flex; align-items: center; gap: 10px;
  cursor: pointer; font-size: 13px; color: var(--hm-text-2);
  user-select: none;
}
.ord-check input { display: none; }
.ord-check-box {
  width: 20px; height: 20px; border-radius: 6px;
  border: 1.5px solid var(--hm-border);
  display: grid; place-items: center;
  transition: all 0.15s;
}
.ord-check-box .icon { font-size: 14px; color: transparent; }
.ord-check input:checked + .ord-check-box {
  background: var(--hm-accent); border-color: var(--hm-accent);
}
:global(html.theme-light) .ord-check input:checked + .ord-check-box {
  background: #b07f00; border-color: #b07f00;
}
.ord-check input:checked + .ord-check-box .icon { color: #000; }
:global(html.theme-light) .ord-check input:checked + .ord-check-box .icon { color: #fff; }

/* Urgency pills */
.ord-urgency { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.ord-urgency-opt {
  display: inline-flex; align-items: center; justify-content: center; gap: 6px;
  padding: 13px;
  background: var(--hm-bg-2);
  border: 1.5px solid var(--hm-border-2);
  border-radius: 12px;
  color: var(--hm-text); font-family: inherit;
  font-size: 13px; font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.ord-urgency-opt.active { border-color: var(--hm-accent); background: rgba(255, 255, 0, 0.06); }
:global(html.theme-light) .ord-urgency-opt.active { border-color: #b07f00; background: rgba(177, 127, 0, 0.06); }
.ord-urgency-urgent.active { border-color: #ef4444; background: rgba(239, 68, 68, 0.08); color: #ef4444; }

/* Photos */
.ord-photos {
  display: flex; flex-wrap: wrap; gap: 10px;
  margin-top: 8px;
}
.ord-photo {
  position: relative;
  width: 96px; height: 96px;
  border-radius: 14px; overflow: hidden;
  border: 1px solid var(--hm-border-2);
}
.ord-photo img { width: 100%; height: 100%; object-fit: cover; }
.ord-photo-x {
  position: absolute; top: 6px; right: 6px;
  width: 24px; height: 24px; border-radius: 50%;
  background: rgba(0, 0, 0, 0.7); color: #fff;
  border: 0; cursor: pointer;
  display: grid; place-items: center;
  transition: background 0.15s;
}
.ord-photo-x:hover { background: #ef4444; }
.ord-photo-add {
  width: 96px; height: 96px;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px;
  border: 1.5px dashed var(--hm-border);
  border-radius: 14px;
  color: var(--hm-text-3); cursor: pointer;
  background: var(--hm-bg-2);
  transition: all 0.15s;
}
.ord-photo-add:hover { border-color: var(--hm-accent); color: var(--hm-accent); }
:global(html.theme-light) .ord-photo-add:hover { border-color: #b07f00; color: #b07f00; }
.ord-photo-add .icon { font-size: 26px; }
.ord-photo-add span:last-child { font-size: 10px; text-align: center; }

/* === Summary aside === */
.ord-aside {
  position: sticky;
  top: 96px;
  align-self: start;
}
@media (max-width: 1020px) {
  .ord-aside { position: static; }
}
.ord-summary {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 24px;
  padding: 28px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
}
:global(html.theme-light) .ord-summary { background: #fff; box-shadow: 0 12px 40px rgba(0, 0, 0, 0.08); }
.ord-summary-h {
  display: flex; align-items: center; gap: 10px;
  font-family: "Public Sans", sans-serif;
  font-size: 16px; font-weight: 700;
  color: var(--hm-text);
  padding-bottom: 18px;
  border-bottom: 1px dashed var(--hm-border-2);
  margin-bottom: 18px;
}
.ord-summary-h .icon { color: var(--hm-accent); font-size: 22px; }
:global(html.theme-light) .ord-summary-h .icon { color: #b07f00; }

.ord-summary-list { display: flex; flex-direction: column; gap: 14px; margin: 0; padding: 0; }
.ord-summary-row {
  display: flex; justify-content: space-between; align-items: flex-start; gap: 12px;
  font-size: 13px;
}
.ord-summary-row dt {
  display: inline-flex; align-items: center; gap: 6px;
  color: var(--hm-text-3); font-weight: 500;
  flex-shrink: 0;
}
.ord-summary-row dt .icon { color: var(--hm-text-2); font-size: 15px; }
.ord-summary-row dd {
  color: var(--hm-text); font-weight: 600;
  margin: 0; text-align: right;
  min-width: 0;
}
.ord-summary-ellipsis {
  overflow: hidden; text-overflow: ellipsis;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
}
.ord-urgent-tag {
  padding: 3px 8px; border-radius: 999px;
  background: rgba(239, 68, 68, 0.12); color: #ef4444;
  font-size: 11px; font-weight: 700; text-transform: uppercase;
}

.ord-summary-budget {
  margin-top: 22px; padding: 18px;
  background: rgba(255, 255, 0, 0.06);
  border: 1px dashed var(--hm-accent);
  border-radius: 14px;
  text-align: center;
}
:global(html.theme-light) .ord-summary-budget { background: rgba(177, 127, 0, 0.06); border-color: #b07f00; }
.ord-summary-budget-lbl {
  color: var(--hm-text-3); font-size: 11px; font-weight: 600;
  text-transform: uppercase; letter-spacing: 0.5px;
}
.ord-summary-budget-v {
  color: var(--hm-text); font-weight: 700;
  font-size: 32px; letter-spacing: -0.02em;
  line-height: 1; margin: 6px 0;
  font-family: "Public Sans", sans-serif;
}
.ord-summary-budget-v span { color: var(--hm-accent); font-size: 20px; }
:global(html.theme-light) .ord-summary-budget-v span { color: #b07f00; }
.ord-summary-budget-note { color: var(--hm-text-3); font-size: 11px; }

/* Submit */
.ord-submit {
  width: 100%; margin-top: 22px;
  display: inline-flex; align-items: center; justify-content: center; gap: 8px;
  padding: 16px 22px;
  background: var(--hm-accent); color: #000;
  border: 0; border-radius: 14px;
  font-family: "Public Sans", sans-serif; font-weight: 800;
  font-size: 15px; letter-spacing: 0.2px;
  cursor: pointer;
  transition: transform 0.15s, box-shadow 0.15s;
  box-shadow: 0 10px 24px -8px rgba(255, 255, 0, 0.4);
}
:global(html.theme-light) .ord-submit { background: #facc15; color: #111; box-shadow: 0 10px 24px -8px rgba(250, 204, 21, 0.5); }
.ord-submit:hover:not(:disabled) { transform: translateY(-1px); }
.ord-submit:disabled { opacity: 0.45; cursor: not-allowed; box-shadow: none; }
.ord-submit .icon { font-size: 18px; }
.ord-spin {
  width: 16px; height: 16px;
  border: 2.5px solid rgba(0, 0, 0, 0.2);
  border-top-color: #000;
  border-radius: 50%;
  animation: ord-rot 0.75s linear infinite;
}
@keyframes ord-rot { to { transform: rotate(360deg); } }

.ord-summary-footnote {
  display: inline-flex; align-items: flex-start; gap: 6px;
  margin: 14px 0 0;
  color: var(--hm-text-3); font-size: 11px; line-height: 1.5;
  text-align: left;
}
.ord-summary-footnote .icon { color: var(--hm-text-3); font-size: 14px; flex-shrink: 0; margin-top: 1px; }

/* Success */
.ord-success {
  max-width: 520px; margin: 60px auto;
  text-align: center;
  padding: 56px 40px;
  background: var(--hm-bg-1);
  border: 1px solid rgba(34, 197, 94, 0.3);
  border-radius: 28px;
}
:global(html.theme-light) .ord-success { background: #fff; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08); }
.ord-success-icon {
  width: 88px; height: 88px; margin: 0 auto 24px;
  border-radius: 50%;
  background: rgba(34, 197, 94, 0.15);
  display: grid; place-items: center;
  animation: ord-pop 0.4s cubic-bezier(0.2, 0.6, 0.3, 1.3);
}
@keyframes ord-pop { from { transform: scale(0); } to { transform: scale(1); } }
.ord-success-icon .icon { font-size: 44px; color: #22c55e; }
.ord-success h1 {
  font-family: "Public Sans", sans-serif;
  font-size: 28px; font-weight: 700;
  color: var(--hm-text); margin: 0 0 10px;
}
.ord-success p { color: var(--hm-text-3); font-size: 15px; margin: 0 0 28px; line-height: 1.6; }
.ord-success-cta {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 14px 28px;
  background: var(--hm-accent); color: #000;
  border-radius: 12px; text-decoration: none;
  font-weight: 700; font-family: "Public Sans", sans-serif;
  transition: transform 0.15s;
}
:global(html.theme-light) .ord-success-cta { background: #facc15; color: #111; }
.ord-success-cta:hover { transform: translateY(-1px); }
</style>
