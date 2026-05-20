<template>
  <div class="hm-page hm-order-public-page">
    <div class="hm-page-inner" style="max-width: 980px">
      <nav class="hm-breadcrumb">
        <NuxtLink :to="localePath('/')">{{ $t('nav.home') }}</NuxtLink>
        <span class="hm-breadcrumb-sep">›</span>
        <NuxtLink :to="localePath('/orders')">{{ $t('public_orders.page_title') }}</NuxtLink>
        <span v-if="order" class="hm-breadcrumb-sep">›</span>
        <span v-if="order" class="hm-breadcrumb-current">#{{ order.id }}</span>
      </nav>

      <div v-if="pending" class="hm-loading">{{ $t('common.loading') }}</div>
      <div v-else-if="!order" class="hm-empty-state">
        <span class="icon">search_off</span>
        <h3>{{ $t('public_orders.not_found_title') }}</h3>
        <p>{{ $t('public_orders.not_found_desc') }}</p>
        <NuxtLink :to="localePath('/orders')" class="hm-btn hm-btn-primary">{{ $t('public_orders.back_to_list') }}</NuxtLink>
      </div>

      <div v-else class="hm-op-layout">
        <main class="hm-op-main">
          <section class="hm-op-card">
            <div class="hm-op-head">
              <div class="hm-op-cat">
                <CatIcon v-if="order.category?.icon_url" :icon="order.category.icon_url" />
                <div>
                  <h1>{{ order.category?.name }}</h1>
                  <div v-if="order.subcategory" class="hm-op-sub">{{ order.subcategory.name }}</div>
                </div>
              </div>
            </div>

            <p class="hm-op-desc">{{ order.description }}</p>

            <div v-if="order.comment" class="hm-op-note">
              <span class="icon icon-sm">info</span>
              {{ order.comment }}
            </div>

            <div v-if="order.photos?.length" class="hm-op-photos">
              <button
                v-for="(p, i) in order.photos"
                :key="p.id"
                type="button"
                class="hm-op-photo"
                @click="openLightbox(i)"
              >
                <img :src="resolvePhoto(p.url)" :alt="'photo ' + (i + 1)" loading="lazy" />
              </button>
            </div>
          </section>

          <section class="hm-op-card">
            <h2 class="hm-op-section-title">{{ $t('public_orders.details_title') }}</h2>
            <dl class="hm-op-details">
              <div v-if="order.district">
                <dt><span class="icon icon-sm">location_on</span> {{ $t('public_orders.area') }}</dt>
                <dd>{{ order.district }}</dd>
              </div>
              <div>
                <dt><span class="icon icon-sm">schedule</span> {{ $t('public_orders.when') }}</dt>
                <dd v-if="order.desired_time === 'scheduled' && order.scheduled_at">{{ formatDateTime(order.scheduled_at) }}</dd>
                <dd v-else>{{ $t('public_orders.asap_full') }}</dd>
              </div>
              <div v-if="order.estimated_budget">
                <dt><span class="icon icon-sm">payments</span> {{ $t('public_orders.budget') }}</dt>
                <dd>~{{ order.estimated_budget }} AZN</dd>
              </div>
              <div>
                <dt><span class="icon icon-sm">event</span> {{ $t('public_orders.posted') }}</dt>
                <dd>{{ formatDateTime(order.created_at) }}</dd>
              </div>
            </dl>
          </section>
        </main>

        <aside class="hm-op-side">
          <div class="hm-op-card hm-op-side-card">
            <div class="hm-op-client">
              <span class="hm-op-avatar" :style="order.client?.avatar_url ? { backgroundImage: `url(${order.client.avatar_url})` } : {}">
                <span v-if="!order.client?.avatar_url">{{ (order.client?.first_name || '?').charAt(0) }}</span>
              </span>
              <div>
                <div class="hm-op-client-name">{{ order.client?.first_name }}</div>
                <div v-if="order.client?.rating_count" class="hm-op-client-rating">
                  ★ {{ order.client.rating_avg || '—' }} · {{ order.client.rating_count }} {{ $t('masters.reviews') }}
                </div>
                <div v-else class="hm-op-client-rating">{{ $t('public_orders.new_client') }}</div>
              </div>
            </div>

            <div v-if="auth.isLoggedIn && auth.isMaster && !hasApplied" class="hm-op-apply-form">
              <label class="hm-op-apply-label">{{ $t('public_orders.application_message_label') }}</label>
              <textarea
                v-model="applicationMessage"
                class="hm-op-apply-textarea"
                rows="3"
                maxlength="1000"
                :placeholder="$t('public_orders.application_message_placeholder')"
              ></textarea>
              <label class="hm-op-apply-label">{{ $t('public_orders.application_price_label') }}</label>
              <input
                v-model.number="applicationPrice"
                type="number"
                min="0"
                step="1"
                class="hm-op-apply-input"
                :placeholder="$t('public_orders.application_price_placeholder')"
              />
            </div>

            <button
              v-if="!hasApplied"
              type="button"
              class="hm-btn hm-btn-primary"
              style="width:100%;margin-top:14px"
              @click="handleApply"
              :disabled="applying"
            >
              <span class="icon icon-sm">send</span>
              {{ applying ? $t('public_orders.sending') : applyButtonLabel }}
            </button>

            <div v-else class="hm-op-applied-state">
              <div class="hm-op-applied-head">
                <span class="icon">check_circle</span>
                <span>{{ $t('public_orders.application_sent_short') }}</span>
              </div>
              <button
                type="button"
                class="hm-btn hm-btn-ghost hm-btn-sm hm-op-withdraw-btn"
                @click="withdrawApplication"
                :disabled="withdrawing || myApplicationStatus === 'accepted'"
              >
                <span class="icon icon-sm">close</span>
                {{ withdrawing ? $t('common.loading') : $t('apps.withdraw') }}
              </button>
            </div>

            <p class="hm-op-apply-hint">{{ applyHint }}</p>

            <NuxtLink :to="localePath('/orders')" class="hm-btn hm-btn-ghost hm-btn-sm" style="width:100%;margin-top:8px">
              ← {{ $t('public_orders.back_to_list') }}
            </NuxtLink>
          </div>
        </aside>
      </div>
    </div>

    <!-- Lightbox -->
    <div v-if="lightboxIdx >= 0" class="hm-op-lightbox" @click.self="lightboxIdx = -1">
      <button class="hm-op-lb-close" @click="lightboxIdx = -1"><span class="icon">close</span></button>
      <button v-if="order && order.photos && order.photos.length > 1" class="hm-op-lb-nav hm-op-lb-prev" @click="lightboxIdx = (lightboxIdx - 1 + order.photos.length) % order.photos.length"><span class="icon">chevron_left</span></button>
      <img v-if="order && order.photos" :src="resolvePhoto(order.photos[lightboxIdx]?.url)" />
      <button v-if="order && order.photos && order.photos.length > 1" class="hm-op-lb-nav hm-op-lb-next" @click="lightboxIdx = (lightboxIdx + 1) % order.photos.length"><span class="icon">chevron_right</span></button>
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

const orderId = route.params.id

const { data: order, pending } = await useAsyncData(`public-order-${orderId}`, async () => {
  try {
    const res = await apiFetch<{ order: any }>(`/orders/public/${orderId}`)
    return res.order
  } catch { return null }
})

const applying = ref(false)
const withdrawing = ref(false)
const lightboxIdx = ref(-1)
const applicationMessage = ref('')
const applicationPrice = ref<number | null>(null)
const hasApplied = ref(false)
const myApplicationId = ref<number | null>(null)
const myApplicationStatus = ref<string>('')
const checkingApplication = ref(false)

async function checkExistingApplication() {
  if (!auth.isLoggedIn || !auth.isMaster) {
    hasApplied.value = false
    myApplicationId.value = null
    return
  }
  checkingApplication.value = true
  try {
    const res = await apiFetch<{ applications: { id: number; order_id: number; status: string }[] }>('/master/applied-order-ids')
    const mine = (res.applications || []).find(a => Number(a.order_id) === Number(orderId))
    if (mine) {
      hasApplied.value = true
      myApplicationId.value = mine.id
      myApplicationStatus.value = mine.status
    } else {
      hasApplied.value = false
      myApplicationId.value = null
      myApplicationStatus.value = ''
    }
  } catch {
    hasApplied.value = false
    myApplicationId.value = null
  }
  finally { checkingApplication.value = false }
}

async function withdrawApplication() {
  if (!myApplicationId.value) return
  if (!confirm($t('apps.withdraw_confirm'))) return
  withdrawing.value = true
  try {
    await apiFetch(`/order-applications/${myApplicationId.value}/withdraw`, { method: 'POST' })
    toast.success($t('apps.withdrawn_toast'))
    hasApplied.value = false
    myApplicationId.value = null
    myApplicationStatus.value = ''
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  } finally {
    withdrawing.value = false
  }
}

const applyButtonLabel = computed(() => {
  if (!auth.isLoggedIn) return $t('public_orders.register_to_apply')
  if (auth.isClient) return $t('public_orders.only_masters_short')
  if (hasApplied.value) return $t('public_orders.application_sent_short')
  return $t('public_orders.send_application')
})

const applyHint = computed(() => {
  if (!auth.isLoggedIn) return $t('public_orders.apply_hint_guest')
  if (auth.isClient) return $t('public_orders.apply_hint_client')
  if (hasApplied.value) return $t('public_orders.apply_hint_applied')
  return $t('public_orders.apply_hint_master_v2')
})

function resolvePhoto(url: string): string {
  if (!url) return ''
  if (url.startsWith('http://') || url.startsWith('https://')) return url
  const base = (config.public as any).apiBase?.replace(/\/api\/?$/, '') || ''
  return url.startsWith('/') ? base + url : url
}

function openLightbox(i: number) { lightboxIdx.value = i }

async function handleApply() {
  if (!auth.isLoggedIn) {
    router.push({ path: localePath('/register/master'), query: { redirect: route.fullPath } })
    return
  }
  if (auth.isClient) {
    toast.error($t('public_orders.only_masters'))
    return
  }
  if (hasApplied.value) return
  applying.value = true
  try {
    await apiFetch(`/orders/${orderId}/apply`, {
      method: 'POST',
      body: {
        message: applicationMessage.value || undefined,
        proposed_price: applicationPrice.value || undefined,
      },
    })
    toast.success($t('public_orders.application_sent'))
    hasApplied.value = true
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  } finally {
    applying.value = false
  }
}

useHead({ title: () => order.value ? `${order.value.category?.name} — ${$t('public_orders.page_title')}` : $t('public_orders.page_title') })

onMounted(() => {
  checkExistingApplication()
  const onKey = (e: KeyboardEvent) => {
    if (lightboxIdx.value < 0 || !order.value?.photos) return
    if (e.key === 'Escape') lightboxIdx.value = -1
    else if (e.key === 'ArrowLeft') lightboxIdx.value = (lightboxIdx.value - 1 + order.value.photos.length) % order.value.photos.length
    else if (e.key === 'ArrowRight') lightboxIdx.value = (lightboxIdx.value + 1) % order.value.photos.length
  }
  window.addEventListener('keydown', onKey)
  onUnmounted(() => window.removeEventListener('keydown', onKey))
})
</script>

<style scoped>
.hm-order-public-page { padding-top: 24px; padding-bottom: 48px; }

.hm-breadcrumb {
  display: flex;
  gap: 8px;
  align-items: center;
  font-size: 13px;
  color: var(--hm-text-3);
  margin-bottom: 18px;
  flex-wrap: wrap;
}
.hm-breadcrumb a { color: var(--hm-text-3); text-decoration: none; }
.hm-breadcrumb a:hover { color: var(--hm-accent); }
.hm-breadcrumb-current { color: var(--hm-text); font-weight: 600; }
.hm-breadcrumb-sep { color: var(--hm-text-3); }

.hm-op-layout {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 20px;
  align-items: start;
}
@media (max-width: 860px) {
  .hm-op-layout { grid-template-columns: 1fr; }
}

.hm-op-main { display: flex; flex-direction: column; gap: 16px; }

.hm-op-card {
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  border-radius: 14px;
  padding: 22px;
}

.hm-op-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 14px;
  margin-bottom: 14px;
}
.hm-op-cat { display: flex; gap: 12px; align-items: flex-start; }
.hm-op-cat .icon {
  font-size: 32px;
  color: var(--hm-accent);
  background: rgba(var(--hm-accent-rgb, 0, 168, 143), 0.1);
  padding: 8px;
  border-radius: 10px;
}
.hm-op-cat h1 { font-size: 22px; font-weight: 700; color: var(--hm-text); margin: 0 0 2px; letter-spacing: -0.3px; }
.hm-op-sub { font-size: 13px; color: var(--hm-text-3); }

.hm-op-badges { display: flex; gap: 6px; flex-wrap: wrap; }
.hm-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 999px;
}
.hm-badge-urgent { background: rgba(255,77,77,0.12); color: #e04040; }
.hm-badge .icon { font-size: 14px; }

.hm-op-desc {
  font-size: 15px;
  line-height: 1.65;
  color: var(--hm-text);
  white-space: pre-wrap;
  margin: 0;
}

.hm-op-note {
  display: flex;
  gap: 8px;
  align-items: flex-start;
  background: var(--hm-bg-2);
  border-radius: 8px;
  padding: 10px 12px;
  margin-top: 12px;
  font-size: 13px;
  color: var(--hm-text-2);
}
.hm-op-note .icon { color: var(--hm-text-3); flex-shrink: 0; }

.hm-op-photos {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 8px;
  margin-top: 14px;
}
.hm-op-photo {
  border: none;
  padding: 0;
  cursor: zoom-in;
  aspect-ratio: 1;
  border-radius: 10px;
  overflow: hidden;
  background: var(--hm-bg-2);
}
.hm-op-photo img { width: 100%; height: 100%; object-fit: cover; display: block; }

.hm-op-section-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--hm-text);
  margin: 0 0 12px;
  letter-spacing: -0.2px;
}

.hm-op-details { margin: 0; display: flex; flex-direction: column; gap: 10px; }
.hm-op-details > div {
  display: grid;
  grid-template-columns: 180px 1fr;
  gap: 10px;
  font-size: 13.5px;
}
.hm-op-details dt {
  color: var(--hm-text-3);
  display: flex;
  align-items: center;
  gap: 6px;
}
.hm-op-details dt .icon { font-size: 16px; }
.hm-op-details dd { margin: 0; color: var(--hm-text); font-weight: 500; }
@media (max-width: 560px) {
  .hm-op-details > div { grid-template-columns: 1fr; }
}

.hm-op-side-card { position: sticky; top: 80px; }
.hm-op-client {
  display: flex;
  gap: 12px;
  align-items: center;
}
.hm-op-avatar {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: var(--hm-bg-2) center/cover no-repeat;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  font-weight: 600;
  color: var(--hm-text-2);
  flex-shrink: 0;
}
.hm-op-client-name {
  font-size: 16px;
  font-weight: 700;
  color: var(--hm-text);
  margin-bottom: 2px;
}
.hm-op-client-rating {
  font-size: 12.5px;
  color: var(--hm-text-3);
}
.hm-op-apply-hint {
  font-size: 12.5px;
  color: var(--hm-text-3);
  text-align: center;
  margin: 10px 0 0;
  line-height: 1.5;
}

.hm-op-apply-form {
  margin-top: 14px;
  padding-top: 14px;
  border-top: 1px dashed var(--hm-border);
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.hm-op-apply-label {
  font-size: 11.5px;
  color: var(--hm-text-3);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.4px;
  margin-top: 8px;
}
.hm-op-apply-textarea,
.hm-op-apply-input {
  width: 100%;
  padding: 10px 12px;
  font-size: 13.5px;
  font-family: inherit;
  background: var(--hm-bg-2);
  color: var(--hm-text);
  border: 1px solid var(--hm-border);
  border-radius: 10px;
  resize: vertical;
  transition: border-color .15s;
}
.hm-op-apply-textarea:focus,
.hm-op-apply-input:focus {
  outline: none;
  border-color: var(--hm-accent);
}

.hm-op-applied-state {
  margin-top: 14px;
  padding: 14px;
  background: rgba(34, 197, 94, 0.08);
  border: 1px solid rgba(34, 197, 94, 0.3);
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.hm-op-applied-head {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 700;
  color: #22c55e;
}
.hm-op-applied-head .icon { font-size: 20px; }
.hm-op-withdraw-btn {
  width: 100%;
  color: #ef4444 !important;
  border-color: rgba(239, 68, 68, 0.3) !important;
  background: transparent !important;
}
.hm-op-withdraw-btn:hover:not(:disabled) {
  background: rgba(239, 68, 68, 0.08) !important;
  border-color: rgba(239, 68, 68, 0.5) !important;
}
.hm-op-withdraw-btn:disabled {
  opacity: .5;
  cursor: not-allowed;
}

.hm-op-lightbox {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.88);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
}
.hm-op-lightbox img {
  max-width: 90vw;
  max-height: 90vh;
  object-fit: contain;
}
.hm-op-lb-close, .hm-op-lb-nav {
  position: absolute;
  background: rgba(255,255,255,0.1);
  border: none;
  color: #fff;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.hm-op-lb-close:hover, .hm-op-lb-nav:hover { background: rgba(255,255,255,0.2); }
.hm-op-lb-close { top: 20px; right: 20px; }
.hm-op-lb-prev { left: 20px; top: 50%; transform: translateY(-50%); }
.hm-op-lb-next { right: 20px; top: 50%; transform: translateY(-50%); }
</style>
