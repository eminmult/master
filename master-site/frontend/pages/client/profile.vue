<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="client" />
        <div class="hm-dash-main">
          <h1 class="hm-prof-title">{{ $t('profile.title') }}</h1>
          <p class="hm-prof-sub">{{ $t('profile.subtitle') }}</p>

          <!-- Header card -->
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
              <h2>{{ auth.user?.first_name }} {{ auth.user?.last_name || '' }}</h2>
              <div class="hm-prof-meta">
                <span><span class="icon icon-sm">phone</span>{{ auth.user?.phone }}</span>
                <span v-if="auth.user?.email"><span class="icon icon-sm">mail</span>{{ auth.user.email }}</span>
                <NuxtLink v-if="auth.user?.id" :to="localePath('/master/' + auth.user.id)" class="hm-prof-public">
                  <span class="icon icon-sm">open_in_new</span> {{ $t('profile.view_public') }}
                </NuxtLink>
              </div>
            </div>
          </section>

          <div v-if="saved" class="hm-prof-saved">
            <span class="icon icon-sm">check_circle</span> {{ $t('profile.saved') }}
          </div>

          <!-- Personal info -->
          <form @submit.prevent="handleSave">
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
                  <label class="hm-auth-label">{{ $t('auth.last_name') }}</label>
                  <input v-model="form.last_name" type="text" class="hm-form-input" />
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

              <div>
                <button type="submit" class="hm-btn hm-btn-primary" :disabled="profileLoading">
                  <span v-if="profileLoading" class="icon icon-sm">autorenew</span>
                  <span v-else class="icon icon-sm">save</span>
                  {{ profileLoading ? $t('profile.saving') : $t('profile.save') }}
                </button>
              </div>
            </section>
          </form>

          <!-- Addresses -->
          <section class="hm-prof-card">
            <div class="hm-prof-card-head">
              <h3 class="hm-prof-card-title">
                <span class="icon">home</span>{{ $t('profile.my_addresses') }}
              </h3>
              <button type="button" class="hm-btn hm-btn-primary hm-btn-sm" @click="openAddressForm()">
                <span class="icon icon-sm">add</span> {{ $t('address.add') }}
              </button>
            </div>

            <div v-if="showAddrForm" class="hm-addr-form">
              <div class="hm-form-group">
                <label class="hm-auth-label">{{ $t('address.label') }}</label>
                <input v-model="addrForm.label" type="text" class="hm-form-input" placeholder="Ev, İş..." />
              </div>
              <div class="hm-form-group">
                <label class="hm-auth-label">{{ $t('address.address') }} *</label>
                <ClientOnly>
                  <AddressMapPicker :lat="addrForm.lat || null" :lng="addrForm.lng || null" @update="onMapSelect" />
                </ClientOnly>
                <input v-model="addrForm.full_address" type="text" class="hm-form-input" required :placeholder="$t('address.address_manual')" style="margin-top:8px" />
              </div>
              <div class="hm-form-row-3">
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('address.entrance') }}</label>
                  <input v-model="addrForm.entrance" type="text" class="hm-form-input" />
                </div>
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('address.floor') }}</label>
                  <input v-model="addrForm.floor" type="text" class="hm-form-input" />
                </div>
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('address.intercom') }}</label>
                  <input v-model="addrForm.intercom" type="text" class="hm-form-input" />
                </div>
              </div>
              <div class="hm-form-group">
                <label class="hm-auth-label">{{ $t('address.note_for_master') }}</label>
                <textarea
                  v-model="addrForm.note"
                  class="hm-form-input"
                  rows="3"
                  maxlength="500"
                  :placeholder="$t('address.note_hint')"
                ></textarea>
              </div>
              <label class="hm-check">
                <input type="checkbox" v-model="addrForm.is_default" />
                <span class="hm-check-box"></span>
                {{ $t('address.set_default') }}
              </label>

              <div class="hm-addr-form-actions">
                <button type="button" class="hm-btn hm-btn-primary hm-btn-sm" @click="saveAddress" :disabled="addrSaving">
                  <span class="icon icon-sm">save</span>
                  {{ addrSaving ? $t('profile.saving') : $t('profile.save') }}
                </button>
                <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm" @click="showAddrForm = false">
                  <span class="icon icon-sm">close</span> {{ $t('common.cancel') }}
                </button>
              </div>
            </div>

            <div v-if="addresses.length" class="hm-addr-list">
              <div v-for="addr in addresses" :key="addr.id" class="hm-addr-card">
                <div class="hm-addr-card-body">
                  <div class="hm-addr-label">
                    <span class="icon icon-sm">location_on</span>
                    <strong>{{ addr.label || $t('common.address_label') }}</strong>
                    <span v-if="addr.is_default" class="hm-addr-badge">{{ $t('address.set_default') }}</span>
                  </div>
                  <p class="hm-addr-text">{{ addr.full_address }}</p>
                  <div v-if="addr.entrance || addr.floor || addr.intercom" class="hm-addr-extra">
                    <span v-if="addr.entrance">{{ $t('address.entrance') }}: {{ addr.entrance }}</span>
                    <span v-if="addr.floor">{{ $t('address.floor') }}: {{ addr.floor }}</span>
                    <span v-if="addr.intercom">{{ $t('address.intercom') }}: {{ addr.intercom }}</span>
                  </div>
                  <p v-if="addr.note" class="hm-addr-note">
                    <span class="icon icon-sm">sticky_note_2</span> {{ addr.note }}
                  </p>
                </div>
                <div class="hm-addr-actions">
                  <button type="button" class="hm-addr-btn" @click="editAddress(addr)" :title="$t('common.edit')"><span class="icon icon-sm">edit</span></button>
                  <button type="button" class="hm-addr-btn hm-addr-btn-danger" @click="deleteAddress(addr.id)" :title="$t('common.delete')"><span class="icon icon-sm">delete</span></button>
                </div>
              </div>
            </div>
            <div v-else-if="!showAddrForm" class="hm-addr-empty">
              <span class="icon">location_off</span>
              <p>{{ $t('profile.no_addresses') }}</p>
            </div>
          </section>

          <!-- Payment methods shortcut -->
          <NuxtLink :to="localePath('/payment-methods')" class="hm-prof-card hm-prof-link">
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

const profileLoading = ref(false)
const saved = ref(false)
const uploadingAvatar = ref(false)
const form = reactive({
  first_name: auth.user?.first_name || '',
  last_name: auth.user?.last_name || '',
  email: auth.user?.email || '',
})

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
    } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
    finally { uploadingAvatar.value = false }
  }
  reader.readAsDataURL(file)
}

async function handleSave() {
  profileLoading.value = true; saved.value = false
  try {
    await apiFetch('/client/profile', { method: 'PUT', body: form })
    await auth.fetchUser()
    saved.value = true
    setTimeout(() => { saved.value = false }, 3000)
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  finally { profileLoading.value = false }
}

// Addresses
const addresses = ref<any[]>([])
const showAddrForm = ref(false)
const addrSaving = ref(false)
const editingAddrId = ref<number | null>(null)
const addrForm = reactive({
  label: '', full_address: '', entrance: '', floor: '', intercom: '',
  note: '',
  is_default: false, lat: null as number | null, lng: null as number | null,
})

function onMapSelect(data: { lat: number; lng: number; address: string }) {
  addrForm.lat = data.lat; addrForm.lng = data.lng; addrForm.full_address = data.address
}

function resetAddrForm() {
  addrForm.label = ''; addrForm.full_address = ''; addrForm.entrance = ''
  addrForm.floor = ''; addrForm.intercom = ''; addrForm.note = ''
  addrForm.is_default = false
  addrForm.lat = null; addrForm.lng = null
  editingAddrId.value = null
}

function openAddressForm() { resetAddrForm(); showAddrForm.value = true }

function editAddress(addr: any) {
  editingAddrId.value = addr.id
  addrForm.label = addr.label || ''
  addrForm.full_address = addr.full_address
  addrForm.entrance = addr.entrance || ''
  addrForm.floor = addr.floor || ''
  addrForm.intercom = addr.intercom || ''
  addrForm.note = addr.note || ''
  addrForm.is_default = addr.is_default
  addrForm.lat = addr.lat ? parseFloat(addr.lat) : null
  addrForm.lng = addr.lng ? parseFloat(addr.lng) : null
  showAddrForm.value = true
}

async function saveAddress() {
  if (!addrForm.full_address.trim()) return
  addrSaving.value = true
  try {
    if (editingAddrId.value) {
      await apiFetch(`/addresses/${editingAddrId.value}`, { method: 'PUT', body: { ...addrForm } })
    } else {
      await apiFetch('/addresses', { method: 'POST', body: { ...addrForm } })
    }
    await loadAddresses()
    showAddrForm.value = false
    resetAddrForm()
    toast.success($t('profile.saved'))
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  finally { addrSaving.value = false }
}

async function deleteAddress(id: number) {
  if (!confirm($t('address.confirm_delete'))) return
  try {
    await apiFetch(`/addresses/${id}`, { method: 'DELETE' })
    await loadAddresses()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}

async function loadAddresses() {
  try { const res = await apiFetch<{ addresses: any[] }>('/addresses'); addresses.value = res.addresses }
  catch {}
}

onMounted(loadAddresses)
</script>

<style scoped>
.hm-prof-title { font-size: 26px; font-weight: 700; margin: 0 0 4px; color: var(--hm-text); letter-spacing: -0.4px; }
.hm-prof-sub { font-size: 14px; color: var(--hm-text-3); margin: 0 0 20px; }

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
.hm-prof-avatar-col { display: flex; flex-direction: column; align-items: center; gap: 10px; }
.hm-prof-avatar {
  width: 100px; height: 100px; border-radius: 50%;
  background: var(--hm-bg-2) center/cover no-repeat;
  border: 3px solid var(--hm-border);
  display: flex; align-items: center; justify-content: center;
  color: var(--hm-text-3);
}
.hm-prof-avatar .icon { font-size: 44px; }
.hm-prof-avatar-btn { cursor: pointer; }
.hm-prof-avatar-btn input { display: none; }

.hm-prof-identity h2 {
  font-size: 22px; font-weight: 700; color: var(--hm-text);
  margin: 0 0 6px; letter-spacing: -0.3px;
}
.hm-prof-meta {
  display: flex; flex-wrap: wrap; gap: 14px;
  font-size: 13px; color: var(--hm-text-3);
}
.hm-prof-meta > span, .hm-prof-meta > a {
  display: inline-flex; align-items: center; gap: 5px;
}
.hm-prof-meta .icon { font-size: 16px; }
.hm-prof-public { color: var(--hm-accent); text-decoration: none; }
.hm-prof-public:hover { text-decoration: underline; }

@media (max-width: 640px) {
  .hm-prof-header { grid-template-columns: 1fr; text-align: center; }
  .hm-prof-meta { justify-content: center; }
}

.hm-prof-saved {
  display: inline-flex; align-items: center; gap: 6px;
  background: rgba(34,197,94,0.1); color: #22c55e;
  border: 1px solid rgba(34,197,94,0.3);
  padding: 10px 14px; border-radius: 12px;
  font-size: 13px; margin-bottom: 14px;
}

.hm-prof-card {
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  border-radius: 14px;
  padding: 20px;
  display: flex; flex-direction: column; gap: 14px;
  margin-bottom: 16px;
}
.hm-prof-card-head {
  display: flex; justify-content: space-between; align-items: center;
  gap: 10px; flex-wrap: wrap;
}
.hm-prof-card-title {
  display: flex; align-items: center; gap: 8px;
  font-size: 15px; font-weight: 700;
  color: var(--hm-text); margin: 0 0 2px;
  letter-spacing: -0.2px;
}
.hm-prof-card-title .icon { color: var(--hm-accent); font-size: 20px; }

.hm-form-hint { font-size: 11.5px; color: var(--hm-text-3); margin-top: 2px; }

.hm-form-row-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}
@media (max-width: 560px) { .hm-form-row-3 { grid-template-columns: 1fr; } }

/* Address form */
.hm-addr-form {
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  padding: 18px;
  display: flex; flex-direction: column; gap: 12px;
}
.hm-addr-form-actions { display: flex; gap: 10px; }

/* Address list */
.hm-addr-list { display: flex; flex-direction: column; gap: 10px; }
.hm-addr-card {
  display: flex; justify-content: space-between; align-items: flex-start;
  gap: 12px;
  padding: 14px 16px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  transition: border-color .15s;
}
.hm-addr-card:hover { border-color: var(--hm-accent); }
.hm-addr-card-body { flex: 1; min-width: 0; }
.hm-addr-label {
  display: flex; align-items: center; gap: 6px;
  font-size: 14px; margin-bottom: 4px;
  flex-wrap: wrap;
}
.hm-addr-label .icon { color: var(--hm-accent); }
.hm-addr-label strong { color: var(--hm-text); }
.hm-addr-badge {
  display: inline-block;
  background: rgba(250,204,21,0.14);
  color: var(--hm-accent);
  font-size: 10px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 999px;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}
html.theme-light .hm-addr-badge { color: #b07f00; }
.hm-addr-text {
  font-size: 13.5px;
  color: var(--hm-text-2);
  margin: 0 0 4px;
}
.hm-addr-extra {
  display: flex; flex-wrap: wrap; gap: 12px;
  font-size: 11.5px;
  color: var(--hm-text-3);
}
.hm-addr-note {
  display: flex; align-items: flex-start; gap: 6px;
  margin: 8px 0 0;
  padding: 8px 10px;
  background: var(--hm-accent-soft, rgba(255, 255, 0, 0.08));
  border: 1px solid var(--hm-accent-border, rgba(255, 255, 0, 0.2));
  border-radius: 8px;
  font-size: 12px;
  line-height: 1.4;
  color: var(--hm-text-2);
}
.hm-addr-note .icon { color: var(--hm-accent); margin-top: 1px; }

.hm-addr-actions { display: flex; gap: 4px; flex-shrink: 0; }
.hm-addr-btn {
  width: 32px; height: 32px;
  border-radius: 8px;
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  color: var(--hm-text-3);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: all .15s;
}
.hm-addr-btn:hover { border-color: var(--hm-accent); color: var(--hm-accent); }
.hm-addr-btn-danger:hover { border-color: #ef4444; color: #ef4444; }

.hm-addr-empty {
  text-align: center;
  padding: 30px 20px;
  color: var(--hm-text-3);
}
.hm-addr-empty .icon { font-size: 40px; display: block; margin-bottom: 6px; }
.hm-addr-empty p { font-size: 13px; margin: 0; }

.hm-prof-link {
  display: block; text-decoration: none; color: inherit;
  transition: border-color .15s, background .15s;
}
.hm-prof-link:hover { border-color: var(--hm-accent); background: rgba(255,255,0,.03); }
.hm-prof-link-arrow { margin-left: auto; color: var(--hm-text-3); }
.hm-prof-link-sub {
  margin: 6px 0 0 32px; font-size: 12.5px; color: var(--hm-text-3); line-height: 1.4;
}
</style>
