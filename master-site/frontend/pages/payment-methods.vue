<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar :role="auth.isMaster ? 'master' : 'client'" />
        <div class="hm-dash-main">
          <h1 class="hm-prof-title">{{ $t('profile.payment_methods') }}</h1>
          <p class="hm-prof-sub">{{ $t('payment.subtitle') }}</p>

          <section class="hm-cards-section">
            <div v-if="loading" class="hm-cards-loading">
              <span class="icon spin">progress_activity</span>
            </div>
            <div v-else-if="!cards.length" class="hm-cards-empty">
              <span class="icon">credit_card_off</span>
              <p>{{ $t('payment.no_cards') }}</p>
            </div>
            <div v-else class="hm-cards-list">
              <div v-for="c in cards" :key="c.id" class="hm-card-row" :class="{ active: c.is_default }">
                <div class="hm-card-brand" :class="'brand-' + c.brand">{{ brandLabel(c.brand) }}</div>
                <div class="hm-card-main">
                  <div class="hm-card-num">
                    •••• {{ c.last4 }}
                    <span v-if="c.is_default" class="hm-card-default">{{ $t('profile.default') }}</span>
                  </div>
                  <div class="hm-card-meta">
                    <span v-if="c.holder_name">{{ c.holder_name.toUpperCase() }}</span>
                    <span>{{ String(c.exp_month).padStart(2,'0') }}/{{ String(c.exp_year).slice(-2) }}</span>
                  </div>
                </div>
                <div class="hm-card-actions">
                  <button v-if="!c.is_default" class="hm-btn hm-btn-ghost hm-btn-sm" @click="setDefault(c.id)">
                    <span class="icon icon-sm">star</span>{{ $t('payment.set_default') }}
                  </button>
                  <button class="hm-btn hm-btn-ghost hm-btn-sm hm-btn-danger" @click="del(c.id)">
                    <span class="icon icon-sm">delete</span>
                  </button>
                </div>
              </div>
            </div>

            <button class="hm-btn hm-btn-primary hm-cards-add" @click="showAdd = true">
              <span class="icon icon-sm">add_card</span> {{ $t('payment.add_card') }}
            </button>
          </section>

          <!-- Add card modal -->
          <div v-if="showAdd" class="hm-modal-backdrop" @click.self="showAdd = false">
            <div class="hm-modal hm-card-modal">
              <div class="hm-modal-head">
                <h3>{{ $t('payment.add_card') }}</h3>
                <button class="hm-btn hm-btn-ghost hm-btn-sm" @click="showAdd = false">
                  <span class="icon">close</span>
                </button>
              </div>

              <!-- Live preview -->
              <div class="hm-card-preview" :class="'brand-' + form.brand">
                <div class="hm-card-preview-top">
                  <span class="icon">contactless</span>
                  <span class="hm-card-preview-brand">{{ brandLabel(form.brand) || '•' }}</span>
                </div>
                <div class="hm-card-preview-num">{{ previewNumber }}</div>
                <div class="hm-card-preview-bottom">
                  <div>
                    <div class="hm-card-preview-label">{{ $t('payment.card_holder') }}</div>
                    <div class="hm-card-preview-val">{{ (form.holder || '—').toUpperCase() }}</div>
                  </div>
                  <div>
                    <div class="hm-card-preview-label">{{ $t('payment.card_exp') }}</div>
                    <div class="hm-card-preview-val">{{ form.exp || '••/••' }}</div>
                  </div>
                </div>
              </div>

              <form @submit.prevent="submit" class="hm-card-form">
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('payment.card_number') }}</label>
                  <input
                    v-model="numberInput"
                    type="text"
                    inputmode="numeric"
                    autocomplete="cc-number"
                    placeholder="1234 5678 9012 3456"
                    class="hm-form-input"
                    @input="onNumberInput"
                  />
                </div>
                <div class="hm-form-group">
                  <label class="hm-auth-label">{{ $t('payment.card_holder') }}</label>
                  <input
                    v-model="form.holder"
                    type="text"
                    autocomplete="cc-name"
                    placeholder="CARDHOLDER NAME"
                    class="hm-form-input"
                    style="text-transform: uppercase"
                  />
                </div>
                <div class="hm-form-row">
                  <div class="hm-form-group">
                    <label class="hm-auth-label">{{ $t('payment.card_exp') }}</label>
                    <input
                      v-model="expInput"
                      type="text"
                      inputmode="numeric"
                      autocomplete="cc-exp"
                      placeholder="MM/YY"
                      class="hm-form-input"
                      maxlength="5"
                      @input="onExpInput"
                    />
                  </div>
                  <div class="hm-form-group">
                    <label class="hm-auth-label">CVV</label>
                    <input
                      v-model="form.cvv"
                      type="password"
                      inputmode="numeric"
                      autocomplete="cc-csc"
                      placeholder="123"
                      class="hm-form-input"
                      maxlength="4"
                    />
                  </div>
                </div>
                <label class="hm-card-default-toggle">
                  <input type="checkbox" v-model="form.is_default" />
                  <span>{{ $t('payment.set_as_default') }}</span>
                </label>
                <div v-if="error" class="hm-card-error">
                  <span class="icon icon-sm">error</span>{{ error }}
                </div>
                <button type="submit" :disabled="saving" class="hm-btn hm-btn-primary hm-btn-block">
                  <span class="icon icon-sm">check</span>
                  {{ saving ? $t('common.loading') : $t('payment.save_card') }}
                </button>
                <p class="hm-card-security">
                  <span class="icon icon-sm">lock</span>{{ $t('payment.security_note') }}
                </p>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useApi } from '@/composables/useApi'
import { useI18n } from 'vue-i18n'
import { useToast } from '@/composables/useToast'

definePageMeta({ layout: 'hm', middleware: 'auth' })

const auth = useAuthStore()
const { apiFetch } = useApi()
const { t: $t } = useI18n()
const toast = useToast()

interface Card {
  id: number
  brand: string
  last4: string
  exp_month: number
  exp_year: number
  holder_name: string | null
  is_default: boolean
}

const cards = ref<Card[]>([])
const loading = ref(false)
const saving = ref(false)
const showAdd = ref(false)
const error = ref<string | null>(null)
const form = ref({ holder: '', cvv: '', is_default: false, brand: 'unknown' })
const numberInput = ref('')
const expInput = ref('')

async function load() {
  loading.value = true
  try {
    const res: any = await apiFetch('/payment-cards')
    cards.value = res.cards || []
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  } finally {
    loading.value = false
  }
}

function brandLabel(b: string) {
  switch (b) {
    case 'visa': return 'VISA'
    case 'mastercard': return 'MC'
    case 'amex': return 'AMEX'
    default: return '•'
  }
}

function detectBrand(digits: string): string {
  if (!digits) return 'unknown'
  if (digits.startsWith('4')) return 'visa'
  const f2 = parseInt(digits.slice(0, 2) || '0', 10)
  if (f2 >= 51 && f2 <= 55) return 'mastercard'
  const f4 = parseInt(digits.slice(0, 4) || '0', 10)
  if (f4 >= 2221 && f4 <= 2720) return 'mastercard'
  if (digits.startsWith('34') || digits.startsWith('37')) return 'amex'
  return 'unknown'
}

function luhn(digits: string): boolean {
  if (digits.length < 12) return false
  let sum = 0, alt = false
  for (let i = digits.length - 1; i >= 0; i--) {
    let n = parseInt(digits[i], 10)
    if (alt) { n *= 2; if (n > 9) n -= 9 }
    sum += n
    alt = !alt
  }
  return sum % 10 === 0
}

function onNumberInput(e: Event) {
  const raw = (e.target as HTMLInputElement).value.replace(/\D/g, '').slice(0, 19)
  const formatted = raw.replace(/(.{4})/g, '$1 ').trim()
  numberInput.value = formatted
  form.value.brand = detectBrand(raw)
}

function onExpInput(e: Event) {
  const raw = (e.target as HTMLInputElement).value.replace(/\D/g, '').slice(0, 4)
  expInput.value = raw.length > 2 ? `${raw.slice(0, 2)}/${raw.slice(2)}` : raw
}

const previewNumber = computed(() => {
  const digits = numberInput.value.replace(/\D/g, '')
  let out = ''
  for (let i = 0; i < 16; i++) {
    if (i > 0 && i % 4 === 0) out += ' '
    out += i < digits.length ? digits[i] : '•'
  }
  return out
})

async function submit() {
  error.value = null
  const digits = numberInput.value.replace(/\D/g, '')
  if (!luhn(digits)) { error.value = $t('payment.invalid_card'); return }
  if (!/^\d{2}\/\d{2}$/.test(expInput.value)) { error.value = $t('payment.invalid_exp'); return }
  const [mm, yy] = expInput.value.split('/').map((x) => parseInt(x, 10))
  if (mm < 1 || mm > 12) { error.value = $t('payment.invalid_exp'); return }
  if ((form.value.cvv || '').length < 3) { error.value = $t('payment.invalid_cvv'); return }
  saving.value = true
  try {
    await apiFetch('/payment-cards', {
      method: 'POST',
      body: {
        number: digits,
        exp_month: mm,
        exp_year: 2000 + yy,
        cvv: form.value.cvv,
        holder_name: form.value.holder,
        is_default: form.value.is_default,
      },
    })
    toast.success($t('payment.card_added'))
    showAdd.value = false
    form.value = { holder: '', cvv: '', is_default: false, brand: 'unknown' }
    numberInput.value = ''
    expInput.value = ''
    await load()
  } catch (e: any) {
    error.value = e?.data?.message || $t('auth.error_occurred')
  } finally {
    saving.value = false
  }
}

async function setDefault(id: number) {
  try {
    await apiFetch(`/payment-cards/${id}/default`, { method: 'POST' })
    await load()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}

async function del(id: number) {
  if (!confirm($t('payment.delete_confirm'))) return
  try {
    await apiFetch(`/payment-cards/${id}`, { method: 'DELETE' })
    await load()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}

onMounted(load)
</script>

<style scoped>
.hm-cards-section { margin-top: 24px; }
.hm-cards-loading { display: flex; justify-content: center; padding: 40px; }
.spin { animation: spin 0.9s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.hm-cards-empty {
  text-align: center; padding: 40px;
  border: 1px dashed rgba(255,255,255,.1);
  border-radius: 16px;
}
.hm-cards-empty .icon { font-size: 28px; color: rgba(255,255,255,.4); }
.hm-cards-empty p { margin: 8px 0 0; color: rgba(255,255,255,.6); font-size: 13px; }

.hm-cards-list { display: flex; flex-direction: column; gap: 10px; }
.hm-card-row {
  display: flex; align-items: center; gap: 14px;
  padding: 14px 14px; border-radius: 16px;
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.08);
}
.hm-card-row.active { border-color: rgba(255,255,0,.4); background: rgba(255,255,0,.05); }

.hm-card-brand {
  width: 56px; height: 36px; border-radius: 8px;
  display: flex; align-items: center; justify-content: center;
  background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.1);
  font-weight: 900; font-size: 11px; letter-spacing: .8px;
  color: rgba(255,255,255,.7);
}
.hm-card-brand.brand-visa { color: #FFD200; }
.hm-card-brand.brand-mastercard { color: #EB001B; font-size: 13px; }
.hm-card-brand.brand-amex { color: #2E77BB; }

.hm-card-main { flex: 1; min-width: 0; }
.hm-card-num {
  font-size: 16px; font-weight: 900; color: #fff; letter-spacing: 1.2px;
  display: flex; align-items: center; gap: 8px;
}
.hm-card-default {
  font-size: 9.5px; font-weight: 900; letter-spacing: .8px;
  color: #ff0; background: rgba(255,255,0,.1);
  border: 1px solid rgba(255,255,0,.3); border-radius: 999px;
  padding: 2px 8px;
}
.hm-card-meta {
  display: flex; gap: 10px; margin-top: 4px;
  font-size: 11.5px; font-weight: 800; letter-spacing: .6px;
  color: rgba(255,255,255,.55);
}

.hm-card-actions { display: flex; gap: 6px; }
.hm-btn-danger { color: #EF4444 !important; }

.hm-cards-add { margin-top: 14px; width: 100%; }

.hm-modal-backdrop {
  position: fixed; inset: 0; z-index: 1000;
  background: rgba(0,0,0,.7); display: flex;
  align-items: center; justify-content: center; padding: 16px;
}
.hm-modal {
  width: 100%; max-width: 480px;
  background: #1A1A1A; border-radius: 22px;
  border: 1px solid rgba(255,255,255,.1);
  padding: 22px; max-height: 90vh; overflow-y: auto;
}
.hm-modal-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.hm-modal-head h3 { margin: 0; font-size: 18px; font-weight: 800; }

.hm-card-preview {
  aspect-ratio: 1.586;
  background: linear-gradient(135deg, #1F1F1F, #0A0A0A);
  border: 1px solid rgba(255,255,255,.1); border-radius: 18px;
  padding: 18px; display: flex; flex-direction: column;
  margin-bottom: 18px;
  box-shadow: 0 8px 20px rgba(0,0,0,.4);
}
.hm-card-preview-top { display: flex; justify-content: space-between; align-items: center; }
.hm-card-preview-top .icon { color: rgba(255,255,255,.5); }
.hm-card-preview-brand {
  font-size: 12px; font-weight: 900; letter-spacing: .8px;
  padding: 4px 8px; border-radius: 6px;
}
.brand-visa .hm-card-preview-brand { color: #FFD200; background: rgba(255,210,0,.18); }
.brand-mastercard .hm-card-preview-brand { color: #EB001B; background: rgba(235,0,27,.18); }
.brand-amex .hm-card-preview-brand { color: #2E77BB; background: rgba(46,119,187,.18); }

.hm-card-preview-num {
  margin-top: auto; font-size: 17px; font-weight: 800; color: #fff; letter-spacing: 1.6px;
}
.hm-card-preview-bottom { display: flex; justify-content: space-between; margin-top: 12px; gap: 16px; }
.hm-card-preview-label {
  font-size: 8px; letter-spacing: 1.2px; color: rgba(255,255,255,.4);
  font-weight: 800; text-transform: uppercase;
}
.hm-card-preview-val { font-size: 11.5px; color: rgba(255,255,255,.85); font-weight: 800; letter-spacing: .6px; }

.hm-card-form .hm-form-group { margin-bottom: 12px; }
.hm-card-default-toggle {
  display: inline-flex; align-items: center; gap: 8px;
  font-size: 13.5px; color: rgba(255,255,255,.85);
  cursor: pointer; padding: 6px 0; line-height: 1;
}
.hm-card-default-toggle input[type="checkbox"] {
  appearance: none;
  -webkit-appearance: none;
  width: 16px; height: 16px; min-width: 16px;
  margin: 0; padding: 0;
  border: 1px solid rgba(255,255,255,.3);
  border-radius: 4px;
  background: transparent;
  cursor: pointer;
  position: relative;
  flex-shrink: 0;
}
.hm-card-default-toggle input[type="checkbox"]:checked {
  background: #ff0; border-color: #ff0;
}
.hm-card-default-toggle input[type="checkbox"]:checked::after {
  content: ""; position: absolute;
  left: 4px; top: 0;
  width: 5px; height: 10px;
  border: solid #000; border-width: 0 2px 2px 0;
  transform: rotate(45deg);
}
.hm-card-error {
  display: flex; align-items: center; gap: 8px;
  background: rgba(239,68,68,.15); border: 1px solid rgba(239,68,68,.3);
  border-radius: 12px; padding: 10px 12px; margin: 8px 0;
  color: #EF4444; font-size: 12.5px;
}
.hm-btn-block { width: 100%; margin-top: 14px; }
.hm-card-security {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px; color: rgba(255,255,255,.45);
  margin: 12px 0 0; line-height: 1.4;
}
</style>
