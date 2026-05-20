<template>
  <div class="hm-dash-grid">
    <HmDashSidebar role="master" />
    <main class="hm-dash-main">
      <h1 class="page-title">{{ $t('wallet.title') }}</h1>

      <!-- Balance card -->
      <section class="wallet-card">
        <div class="wallet-balance-label">{{ $t('wallet.balance') }}</div>
        <div class="wallet-balance">
          {{ amountAzn }} <span class="wallet-currency">AZN</span>
        </div>
        <button class="btn btn-primary" :disabled="amountCents <= 0" @click="showWithdraw = true">
          <span class="icon icon-sm">north_east</span>
          {{ $t('wallet.withdraw_cta') }}
        </button>
      </section>

      <!-- Withdrawals list -->
      <section v-if="withdrawals.length" class="wallet-section">
        <h2>{{ $t('wallet.withdrawals') }}</h2>
        <div class="wd-list">
          <div v-for="w in withdrawals" :key="w.id" class="wd-row" :class="'wd-status-' + w.status">
            <div class="wd-row-amount">−{{ (w.amount_cents / 100).toFixed(2) }} {{ w.currency }}</div>
            <div class="wd-row-meta">
              <span class="wd-status-pill">{{ $t('wallet.status_' + w.status) }}</span>
              <span class="wd-row-iban">{{ maskIban(w.iban) }}</span>
              <span class="wd-row-date">{{ formatDate(w.created_at) }}</span>
            </div>
            <button v-if="w.status === 'pending'" class="btn btn-sm btn-outline wd-cancel" @click="cancelWithdrawal(w.id)">
              {{ $t('common.cancel') }}
            </button>
          </div>
        </div>
      </section>

      <!-- Transactions -->
      <section class="wallet-section">
        <h2>{{ $t('wallet.transactions') }}</h2>
        <div v-if="loadingTx" class="wt-loading"><div class="spinner" /></div>
        <div v-else-if="!transactions.length" class="wt-empty">
          {{ $t('wallet.empty') }}
        </div>
        <div v-else class="wt-list">
          <div v-for="tx in transactions" :key="tx.id" class="wt-row">
            <div class="wt-row-left">
              <div class="wt-row-kind">{{ kindLabel(tx.kind) }}</div>
              <div class="wt-row-meta">
                <span v-if="tx.order_id" class="wt-row-order">
                  <NuxtLink :to="localePath('/order/' + tx.order_id)">#{{ tx.order_id }}</NuxtLink>
                </span>
                <span class="wt-row-date">{{ formatDate(tx.created_at) }}</span>
              </div>
            </div>
            <div class="wt-row-amount" :class="{ pos: tx.amount_cents > 0, neg: tx.amount_cents < 0 }">
              {{ tx.amount_cents > 0 ? '+' : '' }}{{ (tx.amount_cents / 100).toFixed(2) }} {{ tx.currency }}
            </div>
          </div>
        </div>
      </section>
    </main>

    <!-- Withdraw request modal -->
    <Teleport to="body">
      <div v-if="showWithdraw" class="popup-overlay" @click.self="showWithdraw = false">
        <div class="popup-card popup-card-wd">
          <div class="popup-header">
            <h3><span class="icon">north_east</span> {{ $t('wallet.withdraw_title') }}</h3>
            <button @click="showWithdraw = false"><span class="icon">close</span></button>
          </div>
          <div class="popup-body">
            <div class="form-group">
              <label>{{ $t('wallet.amount_label') }} (AZN)</label>
              <input v-model.number="wdAmount" type="number" min="1" :max="amountCents / 100" />
            </div>
            <div class="form-group">
              <label>IBAN</label>
              <input v-model="wdIban" type="text" placeholder="AZxx xxxx xxxx xxxx xxxx xxxx" />
            </div>
            <div class="form-group">
              <label>{{ $t('wallet.holder_label') }}</label>
              <input v-model="wdHolder" type="text" />
            </div>
            <div class="form-group">
              <label>{{ $t('wallet.note_label') }}</label>
              <input v-model="wdNote" type="text" />
            </div>
            <p v-if="wdError" class="wd-error">{{ wdError }}</p>
          </div>
          <div class="popup-footer">
            <button class="btn btn-primary btn-block" :disabled="wdSaving || !canRequest" @click="submitWithdraw">
              {{ wdSaving ? $t('common.loading') : $t('wallet.withdraw_submit') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t } = useI18n()
const { apiFetch } = useApi()
const localePath = useLocalePath()
const toast = useToast()

const amountCents = ref(0)
const showWithdraw = ref(false)
const withdrawals = ref<any[]>([])
const transactions = ref<any[]>([])
const loadingTx = ref(true)

const wdAmount = ref<number | null>(null)
const wdIban = ref('')
const wdHolder = ref('')
const wdNote = ref('')
const wdSaving = ref(false)
const wdError = ref('')

const amountAzn = computed(() => (amountCents.value / 100).toFixed(2))
const canRequest = computed(() =>
  !!wdAmount.value && wdAmount.value * 100 <= amountCents.value && wdIban.value.trim().length > 5 && wdHolder.value.trim().length > 1,
)

async function loadAll() {
  try {
    const [bal, tx, wd] = await Promise.all([
      apiFetch<{ balance_cents: number }>('/wallet/balance'),
      apiFetch<{ transactions: any[] }>('/wallet/transactions'),
      apiFetch<{ withdrawals: any[] }>('/withdrawals'),
    ])
    amountCents.value = bal.balance_cents
    transactions.value = tx.transactions
    withdrawals.value = wd.withdrawals
  } catch {}
  loadingTx.value = false
}

async function submitWithdraw() {
  wdSaving.value = true
  wdError.value = ''
  try {
    await apiFetch('/withdrawals', {
      method: 'POST',
      body: {
        amount_cents: Math.round((wdAmount.value || 0) * 100),
        iban: wdIban.value.replace(/\s+/g, ''),
        account_holder: wdHolder.value,
        note: wdNote.value || undefined,
      },
    })
    toast.success($t('wallet.withdraw_submitted_toast'))
    showWithdraw.value = false
    wdAmount.value = null
    wdIban.value = wdHolder.value = wdNote.value = ''
    await loadAll()
  } catch (e: any) {
    wdError.value = e?.data?.message || $t('auth.error_occurred')
  }
  wdSaving.value = false
}

async function cancelWithdrawal(id: number) {
  try {
    await apiFetch(`/withdrawals/${id}/cancel`, { method: 'POST' })
    await loadAll()
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  }
}

function kindLabel(k: string): string {
  const map: Record<string, string> = {
    callout_fee: $t('wallet.kind_callout_fee'),
    callout_refund: $t('wallet.kind_callout_refund'),
    master_penalty: $t('wallet.kind_master_penalty'),
    withdrawal_hold: $t('wallet.kind_withdrawal_hold'),
    withdrawal_paid: $t('wallet.kind_withdrawal_paid'),
    withdrawal_restore: $t('wallet.kind_withdrawal_restore'),
    manual_adjust: $t('wallet.kind_manual_adjust'),
  }
  return map[k] || k
}
function maskIban(iban: string | null): string {
  if (!iban) return ''
  return iban.length > 8 ? iban.slice(0, 4) + ' •••• ' + iban.slice(-4) : iban
}
function formatDate(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleDateString() + ' ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

onMounted(loadAll)
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; margin: 0 0 22px; letter-spacing: -0.5px; }
.wallet-card {
  background: linear-gradient(135deg, rgba(255,255,0,0.12), rgba(255,255,0,0.04));
  border: 1px solid rgba(255,255,0,0.3);
  border-radius: 18px;
  padding: 26px;
  display: flex; flex-direction: column; gap: 14px; align-items: flex-start;
  margin-bottom: 26px;
}
.wallet-balance-label { font-size: 12px; text-transform: uppercase; letter-spacing: 0.8px; color: var(--hm-text-3); }
.wallet-balance { font-size: 44px; font-weight: 800; line-height: 1; letter-spacing: -1.5px; }
.wallet-currency { font-size: 22px; opacity: 0.7; margin-left: 4px; }
.wallet-section { margin-bottom: 30px; }
.wallet-section h2 { font-size: 16px; font-weight: 700; margin: 0 0 12px; }
.wt-list, .wd-list { display: flex; flex-direction: column; gap: 8px; }
.wt-row, .wd-row {
  display: flex; align-items: center; gap: 12px;
  padding: 12px 14px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 12px;
}
.wt-row-left { flex: 1; }
.wt-row-kind { font-weight: 600; font-size: 14px; }
.wt-row-meta { display: flex; gap: 10px; font-size: 12px; color: var(--hm-text-3); margin-top: 2px; }
.wt-row-amount { font-family: 'JetBrains Mono', monospace; font-weight: 700; font-size: 14px; }
.wt-row-amount.pos { color: #22c55e; }
.wt-row-amount.neg { color: #f87171; }
.wt-empty, .wt-loading { padding: 24px; text-align: center; color: var(--hm-text-3); font-size: 13px; }
.spinner { width: 28px; height: 28px; border: 3px solid #333; border-top-color: var(--hm-accent); border-radius: 50%; animation: sp 0.8s linear infinite; margin: 0 auto; }
@keyframes sp { to { transform: rotate(360deg); } }
.wd-row { gap: 14px; }
.wd-row-amount { font-family: 'JetBrains Mono', monospace; font-weight: 700; font-size: 14px; color: #f87171; }
.wd-row-meta { display: flex; gap: 10px; flex: 1; font-size: 12px; color: var(--hm-text-3); align-items: center; }
.wd-status-pill {
  padding: 3px 9px; border-radius: 999px; font-size: 11px; font-weight: 700;
  background: var(--hm-bg-3); border: 1px solid var(--hm-border-2);
}
.wd-status-pending .wd-status-pill { background: rgba(245,158,11,0.15); border-color: rgba(245,158,11,0.4); color: #f59e0b; }
.wd-status-approved .wd-status-pill { background: rgba(34,197,94,0.15); border-color: rgba(34,197,94,0.4); color: #22c55e; }
.wd-status-paid .wd-status-pill { background: rgba(34,197,94,0.15); border-color: rgba(34,197,94,0.4); color: #22c55e; }
.wd-status-rejected .wd-status-pill, .wd-status-cancelled .wd-status-pill { background: rgba(248,113,113,0.15); border-color: rgba(248,113,113,0.4); color: #f87171; }
.wd-row-iban { font-family: 'JetBrains Mono', monospace; }
.wd-cancel { padding: 4px 10px; }
.popup-card-wd { width: 380px; max-width: calc(100vw - 32px); background: var(--hm-bg-2); border: 1px solid var(--hm-border-2); border-radius: 18px; }
.popup-overlay { background: rgba(0,0,0,0.7); }
.popup-header { display: flex; align-items: center; justify-content: space-between; padding: 14px 16px; border-bottom: 1px solid var(--hm-border-2); }
.popup-header h3 { display: flex; align-items: center; gap: 8px; font-size: 16px; font-weight: 700; }
.popup-body { padding: 18px 16px; }
.popup-footer { padding: 14px 16px; border-top: 1px solid var(--hm-border-2); }
.form-group { margin-bottom: 12px; }
.form-group label { display: block; font-size: 12px; text-transform: uppercase; color: var(--hm-text-3); margin-bottom: 4px; letter-spacing: 0.5px; }
.form-group input { width: 100%; padding: 10px 12px; background: var(--hm-bg-3); border: 1px solid var(--hm-border-2); border-radius: 10px; color: var(--hm-text); font-size: 14px; }
.form-group input:focus { outline: none; border-color: var(--hm-accent); }
.btn-block { width: 100%; padding: 12px; font-weight: 700; }
.wd-error { color: #f87171; font-size: 13px; }
</style>
