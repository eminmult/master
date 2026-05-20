<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="master" />
        <div class="hm-dash-main">
          <h1 class="hm-prof-title">{{ $t('profile.master_title') }}</h1>
          <p class="hm-prof-sub">{{ $t('profile.master_subtitle') }}</p>

          <!-- Header card: avatar + identity + stats -->
          <section class="hm-prof-header">
            <div class="hm-prof-avatar-col">
              <div class="hm-prof-avatar" :style="auth.user?.avatar_url ? { backgroundImage: 'url(' + auth.user.avatar_url + ')' } : {}">
                <span v-if="!auth.user?.avatar_url" class="icon">person</span>
              </div>
              <label class="hm-btn hm-btn-ghost hm-btn-sm hm-prof-avatar-btn">
                <span class="icon icon-sm">photo_camera</span>
                <span>{{ uploadingAvatar ? $t('common.loading') : $t('profile.change_photo') }}</span>
                <input type="file" accept="image/*" hidden @change="uploadAvatar" :disabled="uploadingAvatar" />
              </label>
            </div>

            <div class="hm-prof-identity">
              <h2>{{ auth.user?.first_name }} {{ auth.user?.last_name }}</h2>
              <div class="hm-prof-meta">
                <span v-if="auth.user?.master_profile?.city"><span class="icon icon-sm">location_on</span>{{ auth.user.master_profile.city }}</span>
                <span v-if="mp?.experience_years"><span class="icon icon-sm">workspace_premium</span>{{ mp.experience_years }} {{ $t('master.experience_years') }}</span>
                <NuxtLink v-if="auth.user?.id" :to="localePath('/master/' + auth.user.id)" class="hm-prof-public">
                  <span class="icon icon-sm">open_in_new</span> {{ $t('profile.view_public') }}
                </NuxtLink>
              </div>

              <div class="hm-prof-stats">
                <div class="hm-prof-stat">
                  <span class="hm-prof-stat-val">{{ auth.user?.rating_avg || '—' }}</span>
                  <span class="hm-prof-stat-label">
                    <span class="icon icon-sm">star</span>{{ $t('master.rating') }}
                  </span>
                </div>
                <div class="hm-prof-stat">
                  <span class="hm-prof-stat-val">{{ auth.user?.rating_count || 0 }}</span>
                  <span class="hm-prof-stat-label">{{ $t('master.reviews_count') }}</span>
                </div>
                <div class="hm-prof-stat">
                  <span class="hm-prof-stat-val">{{ mp?.completed_orders_count || 0 }}</span>
                  <span class="hm-prof-stat-label">{{ $t('master.orders_count') }}</span>
                </div>
              </div>
            </div>
          </section>

          <!-- Wallet balance card -->
          <section class="hm-prof-wallet">
            <div class="hm-prof-wallet-head">
              <span class="icon">account_balance_wallet</span>
              <span class="hm-prof-wallet-label">{{ $t('wallet.balance') }}</span>
            </div>
            <div class="hm-prof-wallet-amount">
              {{ walletAmount }} <span class="hm-prof-wallet-currency">{{ walletCurrency }}</span>
            </div>
            <div class="hm-prof-wallet-actions">
              <NuxtLink :to="localePath('/master/wallet')" class="hm-btn hm-btn-ghost hm-btn-sm">
                <span class="icon icon-sm">list_alt</span> {{ $t('wallet.transactions') }}
              </NuxtLink>
              <NuxtLink :to="localePath('/master/wallet')" class="hm-btn hm-btn-primary hm-btn-sm" :class="{ disabled: walletCents <= 0 }">
                <span class="icon icon-sm">north_east</span> {{ $t('wallet.withdraw_cta') }}
              </NuxtLink>
            </div>
          </section>

          <div v-if="saved" class="hm-prof-saved">
            <span class="icon icon-sm">check_circle</span> {{ $t('profile.saved') }}
          </div>

          <form @submit.prevent="handleSave" class="hm-prof-grid">
            <!-- Personal info -->
            <section class="hm-prof-card">
              <h3 class="hm-prof-card-title">
                <span class="icon">person</span>{{ $t('profile.section_personal') }}
              </h3>

              <div class="hm-form-row">
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('auth.first_name') }} *</label>
                  <input v-model="form.first_name" type="text" class="hm-form-input" required />
                </div>
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('auth.last_name') }} *</label>
                  <input v-model="form.last_name" type="text" class="hm-form-input" required />
                </div>
              </div>

              <div class="hm-form-group">
                <label class="hm-auth-label">{{ $t('auth.phone') }}</label>
                <input :value="auth.user?.phone" type="text" class="hm-form-input" disabled />
                <span class="hm-form-hint">{{ $t('profile.phone_locked') }}</span>
              </div>

              <div class="hm-form-group">
                <label class="hm-auth-label">{{ $t('auth.email') }}</label>
                <input v-model="form.email" type="email" class="hm-form-input" />
              </div>
            </section>

            <!-- Location -->
            <section class="hm-prof-card">
              <h3 class="hm-prof-card-title">
                <span class="icon">location_on</span>{{ $t('profile.section_location') }}
              </h3>
              <div class="hm-form-row">
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('auth.city') }}</label>
                  <input v-model="form.city" type="text" class="hm-form-input" placeholder="Bakı" />
                </div>
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('auth.district') }}</label>
                  <input v-model="form.district" type="text" class="hm-form-input" />
                </div>
              </div>
            </section>

            <!-- About & expertise -->
            <section class="hm-prof-card hm-prof-card-wide">
              <h3 class="hm-prof-card-title">
                <span class="icon">handyman</span>{{ $t('profile.section_expertise') }}
              </h3>

              <div class="hm-form-row">
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('auth.experience') }}</label>
                  <input v-model.number="form.experience_years" type="number" min="0" max="60" class="hm-form-input" />
                </div>
              </div>

              <div class="hm-form-group">
                <label class="hm-auth-label">{{ $t('auth.about_you') }}</label>
                <textarea v-model="form.description" class="hm-form-textarea" rows="4" :placeholder="$t('auth.about_placeholder')"></textarea>
              </div>

              <div class="hm-form-group">
                <div class="hm-cat-label-row">
                  <label class="hm-auth-label">{{ $t('auth.select_categories') }}</label>
                  <SuggestCategoryBtn />
                </div>
                <div v-if="categories.length" class="hm-cat-chips">
                  <label v-for="cat in categories" :key="cat.id" class="hm-cat-chip" :class="{ active: form.category_ids.includes(cat.id) }">
                    <input type="checkbox" :value="cat.id" v-model="form.category_ids" hidden />
                    <CatIcon :icon="cat.icon_url" fallback="build" /> {{ cat.name }}
                  </label>
                </div>
                <span v-else class="hm-form-hint">{{ $t('common.loading') }}</span>
              </div>
            </section>

            <div class="hm-prof-save">
              <button type="submit" class="hm-btn hm-btn-primary" :disabled="saving">
                <span v-if="saving" class="icon icon-sm">autorenew</span>
                <span v-else class="icon icon-sm">save</span>
                {{ saving ? $t('profile.saving') : $t('profile.save') }}
              </button>
            </div>
          </form>

          <NuxtLink :to="localePath('/payment-methods')" class="hm-prof-card hm-prof-card-wide hm-prof-link">
            <div class="hm-prof-card-head">
              <h3 class="hm-prof-card-title">
                <span class="icon">credit_card</span>{{ $t('profile.payment_methods') }}
              </h3>
              <span class="icon hm-prof-link-arrow">chevron_right</span>
            </div>
            <p class="hm-prof-link-sub">{{ $t('payment.subtitle') }}</p>
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const auth = useAuthStore()
const { apiFetch } = useApi()
const toast = useToast()

const saving = ref(false)
const saved = ref(false)
const uploadingAvatar = ref(false)
const mp = computed(() => auth.user?.master_profile)

// Wallet balance — pulled once on mount; live updates aren't critical here
// since this page isn't where the money actually moves. The /master/wallet
// page has the canonical transaction history.
const walletCents = ref(0)
const walletCurrency = ref('AZN')
const walletAmount = computed(() => (walletCents.value / 100).toFixed(2))
onMounted(async () => {
  try {
    const r = await apiFetch<{ balance_cents: number; currency: string }>('/wallet/balance')
    walletCents.value = r.balance_cents || 0
    walletCurrency.value = r.currency || 'AZN'
  } catch (_) {}
})

const currentCatIds = mp.value?.master_categories?.map((mc: any) => mc.category_id || mc.category?.id) || []

const form = reactive({
  first_name: auth.user?.first_name || '',
  last_name: auth.user?.last_name || '',
  email: auth.user?.email || '',
  description: mp.value?.description || '',
  city: mp.value?.city || '',
  district: mp.value?.district || '',
  experience_years: mp.value?.experience_years || 0,
  category_ids: currentCatIds as number[],
})

const { data: categoriesData } = await useAsyncData('profile-categories', async () => {
  try {
    const res = await apiFetch<{ categories: any[] }>('/categories')
    return res.categories || []
  } catch { return [] }
}, { default: () => [] })
const categories = categoriesData

async function uploadAvatar(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  if (file.size > 5 * 1024 * 1024) { toast.error($t('profile.avatar_too_big')); return }
  uploadingAvatar.value = true
  const reader = new FileReader()
  reader.onload = async () => {
    try {
      await apiFetch('/avatar', { method: 'POST', body: { avatar: reader.result } })
      await auth.fetchUser()
      toast.success($t('profile.avatar_updated'))
    } catch (e: any) {
      toast.error(e?.data?.message || $t('auth.error_occurred'))
    } finally { uploadingAvatar.value = false }
  }
  reader.readAsDataURL(file)
}

async function handleSave() {
  saving.value = true; saved.value = false
  try {
    await apiFetch('/master/profile', { method: 'PUT', body: form })
    await auth.fetchUser()
    saved.value = true
    setTimeout(() => { saved.value = false }, 3000)
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  } finally { saving.value = false }
}
</script>

<style scoped>
.hm-prof-title { font-size: 26px; font-weight: 700; margin: 0 0 4px; color: var(--hm-text); letter-spacing: -0.4px; }
.hm-prof-sub { font-size: 14px; color: var(--hm-text-3); margin: 0 0 20px; }

/* Header card */
.hm-prof-header {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 22px;
  align-items: center;
  padding: 22px;
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  border-radius: 16px;
  margin-bottom: 16px;
}
.hm-prof-avatar-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}
.hm-prof-avatar {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background: var(--hm-bg-2) center/cover no-repeat;
  border: 3px solid var(--hm-border);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--hm-text-3);
}
.hm-prof-avatar .icon { font-size: 44px; }
.hm-prof-avatar-btn { cursor: pointer; }
.hm-prof-avatar-btn input { display: none; }

.hm-prof-identity h2 {
  font-size: 22px;
  font-weight: 700;
  color: var(--hm-text);
  margin: 0 0 6px;
  letter-spacing: -0.3px;
}
.hm-prof-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  font-size: 13px;
  color: var(--hm-text-3);
  margin-bottom: 14px;
}
.hm-prof-meta > span, .hm-prof-meta > a {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
.hm-prof-meta .icon { font-size: 16px; }
.hm-prof-public {
  color: var(--hm-accent);
  text-decoration: none;
}
.hm-prof-public:hover { text-decoration: underline; }

.hm-prof-stats {
  display: flex;
  gap: 10px;
}
.hm-prof-stat {
  flex: 1;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  padding: 12px 14px;
  text-align: center;
}
.hm-prof-stat-val {
  display: block;
  font-size: 22px;
  font-weight: 700;
  color: var(--hm-text);
  line-height: 1.1;
}
.hm-prof-stat-label {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  justify-content: center;
  font-size: 11px;
  color: var(--hm-text-3);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-top: 4px;
}
.hm-prof-stat-label .icon { font-size: 14px; color: var(--hm-accent); }

@media (max-width: 640px) {
  .hm-prof-header { grid-template-columns: 1fr; text-align: center; }
  .hm-prof-meta { justify-content: center; }
}

.hm-prof-saved {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: rgba(34,197,94,0.1);
  color: #22c55e;
  border: 1px solid rgba(34,197,94,0.3);
  padding: 10px 14px;
  border-radius: 12px;
  font-size: 13px;
  margin-bottom: 14px;
}

/* Section grid */
.hm-prof-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}
.hm-prof-card-wide { grid-column: 1 / -1; }
@media (max-width: 860px) {
  .hm-prof-grid { grid-template-columns: 1fr; }
  .hm-prof-card-wide { grid-column: auto; }
}

.hm-prof-card {
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  border-radius: 14px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.hm-prof-card-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 700;
  color: var(--hm-text);
  margin: 0 0 2px;
  letter-spacing: -0.2px;
}
.hm-prof-card-title .icon { color: var(--hm-accent); font-size: 20px; }

.hm-form-hint {
  font-size: 11.5px;
  color: var(--hm-text-3);
  margin-top: 2px;
}

.hm-prof-save {
  grid-column: 1 / -1;
  display: flex;
  justify-content: flex-end;
  padding-top: 6px;
}
@media (max-width: 860px) {
  .hm-prof-save { justify-content: stretch; }
  .hm-prof-save .hm-btn { width: 100%; }
}

.hm-prof-link {
  display: block; text-decoration: none; color: inherit; cursor: pointer;
  transition: border-color .15s, background .15s;
}
.hm-prof-link:hover { border-color: var(--hm-accent); background: rgba(255,255,0,.03); }
.hm-prof-link-arrow { margin-left: auto; color: var(--hm-text-3); }
.hm-prof-link-sub {
  margin: 6px 0 0 32px; font-size: 12.5px; color: var(--hm-text-3); line-height: 1.4;
}

/* Wallet balance card */
.hm-prof-wallet {
  margin-bottom: 18px;
  padding: 22px;
  background: linear-gradient(135deg, rgba(255,255,0,0.14), rgba(255,255,0,0.04));
  border: 1px solid rgba(255,255,0,0.3);
  border-radius: 18px;
}
.hm-prof-wallet-head {
  display: flex; align-items: center; gap: 8px;
  font-size: 11px; font-weight: 800; letter-spacing: .8px;
  text-transform: uppercase; color: var(--hm-text-3);
}
.hm-prof-wallet-head .icon { color: var(--hm-accent); }
.hm-prof-wallet-amount {
  margin-top: 10px;
  font-size: 36px; font-weight: 800; letter-spacing: -1.2px;
}
.hm-prof-wallet-currency { font-size: 18px; opacity: .7; margin-left: 4px; }
.hm-prof-wallet-actions { display: flex; gap: 8px; margin-top: 14px; }
.hm-prof-wallet-actions .hm-btn { flex: 1; justify-content: center; }
.hm-prof-wallet-actions .disabled { opacity: .55; pointer-events: none; }
</style>
