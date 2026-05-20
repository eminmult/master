<template>
  <Teleport to="body">
    <div v-if="modelValue" class="popup-overlay" @click.self="emit('update:modelValue', false)">
      <div class="popup-card popup-card-pay">
        <div class="popup-header">
          <h3><span class="icon">payments</span> {{ $t('callout.modal_title') }}</h3>
          <button @click="emit('update:modelValue', false)"><span class="icon">close</span></button>
        </div>

        <div class="popup-body">
          <div class="pay-summary">
            <div class="pay-amount">{{ amountAzn }} <span class="pay-currency">AZN</span></div>
            <p class="pay-sub">{{ $t('callout.modal_subtitle') }}</p>
          </div>

          <div v-if="loadingCards" class="pay-loading">
            <div class="spinner" />
          </div>
          <div v-else-if="!cards.length" class="pay-no-cards">
            <span class="icon">credit_card_off</span>
            <p>{{ $t('callout.no_cards') }}</p>
            <NuxtLink :to="localePath('/payment-methods')" class="btn btn-primary btn-block">
              {{ $t('callout.add_card_cta') }}
            </NuxtLink>
          </div>
          <div v-else class="pay-cards">
            <label v-for="c in cards" :key="c.id" class="pay-card" :class="{ active: selectedCardId === c.id }">
              <input type="radio" :value="c.id" v-model="selectedCardId" />
              <span class="pay-card-brand">{{ brandLabel(c.brand) }}</span>
              <span class="pay-card-num">•••• {{ c.last4 }}</span>
              <span class="pay-card-exp">{{ c.exp_month.toString().padStart(2,'0') }}/{{ c.exp_year.toString().slice(-2) }}</span>
            </label>
          </div>

          <p v-if="error" class="pay-error">{{ error }}</p>
        </div>

        <div class="popup-footer">
          <button class="btn btn-block btn-primary" :disabled="!canPay || paying" @click="pay">
            <template v-if="paying">{{ $t('common.loading') }}</template>
            <template v-else>{{ $t('callout.pay_btn', { amount: amountAzn }) }}</template>
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; orderId: number }>()
const emit = defineEmits<{ (e: 'update:modelValue', v: boolean): void; (e: 'paid', order: any): void }>()

const { t: $t } = useI18n()
const { apiFetch } = useApi()
const localePath = useLocalePath()
const toast = useToast()

interface Card { id: number; brand: string; last4: string; exp_month: number; exp_year: number; is_default: boolean }
const cards = ref<Card[]>([])
const loadingCards = ref(true)
const selectedCardId = ref<number | null>(null)
const amountCents = ref(2500)
const currency = ref('AZN')
const paying = ref(false)
const error = ref('')

const amountAzn = computed(() => (amountCents.value / 100).toFixed(0))
const canPay = computed(() => !!selectedCardId.value && !paying.value)

async function loadFee() {
  try {
    const r = await apiFetch<{ amount_cents: number; currency: string }>(`/orders/${props.orderId}/callout-fee`)
    amountCents.value = r.amount_cents
    currency.value = r.currency
  } catch {}
}
async function loadCards() {
  loadingCards.value = true
  try {
    const r = await apiFetch<{ cards: Card[] }>('/payment-cards')
    cards.value = r.cards || []
    selectedCardId.value = cards.value.find(c => c.is_default)?.id || cards.value[0]?.id || null
  } catch {}
  loadingCards.value = false
}

watch(() => props.modelValue, async (open) => {
  if (!open) return
  error.value = ''
  paying.value = false
  await Promise.all([loadFee(), loadCards()])
})

async function pay() {
  if (!selectedCardId.value) return
  paying.value = true
  error.value = ''
  try {
    const r = await apiFetch<{ order: any }>(`/orders/${props.orderId}/pay-callout`, {
      method: 'POST',
      body: { payment_card_id: selectedCardId.value },
    })
    emit('paid', r.order)
    emit('update:modelValue', false)
    toast.success($t('callout.success_toast'))
  } catch (e: any) {
    error.value = e?.data?.message || $t('auth.error_occurred')
  } finally {
    paying.value = false
  }
}

function brandLabel(b: string): string {
  if (b === 'visa') return 'Visa'
  if (b === 'mastercard') return 'Mastercard'
  if (b === 'amex') return 'Amex'
  return b
}
</script>

<style scoped>
.popup-card-pay {
  width: 380px; max-width: calc(100vw - 32px);
  background: var(--hm-bg-2, #111);
  border: 1px solid var(--hm-border-2, #222);
  border-radius: 18px;
  display: flex; flex-direction: column;
}
.popup-overlay { background: rgba(0,0,0,0.7); }
.popup-header { display: flex; align-items: center; justify-content: space-between; padding: 14px 16px; border-bottom: 1px solid var(--hm-border-2, #222); }
.popup-header h3 { display: flex; align-items: center; gap: 8px; font-size: 16px; font-weight: 700; }
.popup-body { padding: 18px 16px; }
.popup-footer { padding: 14px 16px; border-top: 1px solid var(--hm-border-2, #222); }
.pay-summary { text-align: center; margin-bottom: 18px; }
.pay-amount { font-size: 40px; font-weight: 800; letter-spacing: -1px; }
.pay-currency { font-size: 18px; opacity: 0.7; margin-left: 4px; }
.pay-sub { font-size: 13px; color: var(--hm-text-3, #aaa); margin-top: 4px; }
.pay-loading { display: flex; justify-content: center; padding: 24px 0; }
.spinner { width: 28px; height: 28px; border: 3px solid #333; border-top-color: var(--hm-accent, #ff0); border-radius: 50%; animation: sp 0.8s linear infinite; }
@keyframes sp { to { transform: rotate(360deg); } }
.pay-no-cards { text-align: center; padding: 12px 0 4px; }
.pay-no-cards .icon { font-size: 36px; color: var(--hm-text-3, #888); display: block; margin-bottom: 8px; }
.pay-no-cards p { font-size: 13px; color: var(--hm-text-3, #aaa); margin-bottom: 14px; }
.pay-cards { display: flex; flex-direction: column; gap: 8px; }
.pay-card {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 14px;
  background: var(--hm-bg-3, #181818);
  border: 1px solid var(--hm-border-2, #222);
  border-radius: 12px;
  cursor: pointer; transition: all 0.15s;
}
.pay-card.active { border-color: var(--hm-accent, #ff0); background: rgba(255,255,0,0.06); }
.pay-card input { accent-color: var(--hm-accent, #ff0); flex-shrink: 0; }
.pay-card-brand { font-weight: 700; font-size: 14px; }
.pay-card-num { font-family: 'JetBrains Mono', monospace; font-size: 13px; color: var(--hm-text-2); }
.pay-card-exp { margin-left: auto; font-size: 12px; color: var(--hm-text-3); }
.pay-error { color: #f87171; font-size: 13px; margin-top: 12px; text-align: center; }
.btn-block { width: 100%; padding: 12px; font-weight: 700; }
</style>
