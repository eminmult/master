<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="master" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <h1>{{ $t('master.my_applications') }}</h1>
            <NuxtLink :to="localePath('/orders')" class="hm-btn hm-btn-primary hm-btn-sm">
              <span class="icon icon-sm">add</span> {{ $t('master.find_orders') }}
            </NuxtLink>
          </div>

          <div class="hm-tabs" style="margin-bottom:0">
            <button type="button" class="hm-tab" :class="{ active: tab === 'active' }" @click="tab = 'active'">
              {{ $t('apps.tab_active') }}
              <span v-if="counts.active" class="hm-tab-badge">{{ counts.active }}</span>
            </button>
            <button type="button" class="hm-tab" :class="{ active: tab === 'accepted' }" @click="tab = 'accepted'">
              {{ $t('apps.tab_accepted') }}
              <span v-if="counts.accepted" class="hm-tab-badge">{{ counts.accepted }}</span>
            </button>
            <button type="button" class="hm-tab" :class="{ active: tab === 'rejected' }" @click="tab = 'rejected'">
              {{ $t('apps.tab_rejected') }}
            </button>
            <button type="button" class="hm-tab" :class="{ active: tab === 'all' }" @click="tab = 'all'">
              {{ $t('apps.tab_all') }}
            </button>
          </div>

          <div v-if="loading && !applications.length" class="hm-loading">{{ $t('common.loading') }}</div>
          <div v-else-if="!filtered.length" class="hm-empty-state">
            <span class="icon">inbox</span>
            <h3>{{ $t('apps.empty_title') }}</h3>
            <p>{{ $t('apps.empty_desc') }}</p>
            <NuxtLink :to="localePath('/orders')" class="hm-btn hm-btn-primary hm-btn-sm" style="margin-top:14px">
              {{ $t('apps.find_orders') }}
            </NuxtLink>
          </div>

          <div v-else class="apps-list">
            <div
              v-for="app in filtered"
              :key="app.id"
              class="hm-dash-card app-row"
              :class="{
                'app-row-accepted': app.status === 'accepted',
                'app-row-rejected': ['rejected', 'withdrawn'].includes(app.status),
                'app-row-discussing': ['discussing', 'proposed'].includes(app.status),
              }"
            >
              <div class="app-row-head">
                <span class="app-cat">
                  <CatIcon v-if="app.order?.category?.icon_url" :icon="app.order.category.icon_url" />
                  {{ app.order?.category?.name }}
                </span>
                <span class="app-status" :class="'app-status-' + app.status">{{ $t('orders.app_status_' + app.status) }}</span>
              </div>

              <p class="app-desc">{{ app.order?.description }}</p>

              <div class="app-meta">
                <span v-if="app.proposed_price" class="app-price-tag">{{ app.proposed_price }} AZN</span>
                <span v-if="app.proposed_date" class="app-price-tag">{{ formatDate(app.proposed_date) }}</span>
                <span class="app-time">{{ timeAgo(app.created_at) }}</span>
              </div>

              <div v-if="app.message" class="app-message">"{{ app.message }}"</div>

              <div class="app-actions">
                <button
                  v-if="['discussing', 'proposed', 'pending'].includes(app.status)"
                  class="hm-btn hm-btn-primary hm-btn-sm"
                  @click="openChat(app)"
                >
                  <span class="icon icon-sm">chat</span> {{ $t('apps.open_chat_with_client') }}
                </button>
                <NuxtLink
                  v-if="app.status === 'accepted'"
                  :to="localePath('/order/' + app.order_id)"
                  class="hm-btn hm-btn-primary hm-btn-sm"
                >
                  <span class="icon icon-sm">chat</span> {{ $t('apps.open_order') }}
                </NuxtLink>
                <NuxtLink
                  :to="localePath('/orders/' + app.order_id)"
                  class="hm-btn hm-btn-ghost hm-btn-sm"
                >
                  {{ $t('apps.view_order') }}
                </NuxtLink>
                <button
                  v-if="['pending', 'discussing', 'proposed'].includes(app.status)"
                  class="hm-btn hm-btn-ghost hm-btn-sm"
                  style="color:#ef4444;border-color:rgba(239,68,68,.3)"
                  :disabled="withdrawingId === app.id"
                  @click="withdraw(app.id)"
                >
                  {{ withdrawingId === app.id ? $t('common.loading') : $t('apps.withdraw') }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Chat drawer -->
    <Teleport to="body">
      <div v-if="chatApp" class="chat-drawer-overlay" @click.self="closeChat">
        <div class="chat-drawer">
          <header class="chat-drawer-head">
            <div class="chat-drawer-title">
              <span
                class="chat-drawer-avatar"
                :style="chatApp.order?.client?.avatar_url ? { backgroundImage: 'url(' + chatApp.order.client.avatar_url + ')', color: 'transparent' } : {}"
              >{{ (chatApp.order?.client?.first_name || '?').charAt(0) }}</span>
              <div>
                <strong>{{ chatApp.order?.client?.first_name }}</strong>
                <div class="chat-drawer-sub">#{{ chatApp.order_id }} · {{ chatApp.order?.category?.name }}</div>
              </div>
            </div>
            <button class="chat-drawer-close" @click="closeChat"><span class="icon">close</span></button>
          </header>

          <!-- Order details card — what the master needs before/while chatting. -->
          <div class="chat-drawer-order">
            <div v-if="chatApp.order?.description" class="cdo-desc">{{ chatApp.order.description }}</div>
            <div v-if="chatApp.order?.photos?.length" class="cdo-photos">
              <a v-for="ph in chatApp.order.photos" :key="ph.id" :href="ph.url" target="_blank" class="cdo-photo">
                <img :src="photoThumb(ph.url)" :alt="$t('order_form.photos')" />
              </a>
            </div>
            <div class="cdo-meta">
              <span v-if="chatApp.order?.district" class="cdo-chip">
                <span class="icon icon-sm">location_on</span> {{ chatApp.order.district }}
              </span>
              <span v-if="chatApp.proposed_date" class="cdo-chip">
                <span class="icon icon-sm">event</span> {{ formatDate(chatApp.proposed_date) }}
              </span>
            </div>
          </div>

          <div class="chat-drawer-status">
            <span :class="'app-status app-status-' + chatApp.status">
              {{ $t('orders.app_status_' + chatApp.status) }}
            </span>
            <button
              v-if="['pending', 'discussing', 'proposed'].includes(chatApp.status)"
              class="hm-btn hm-btn-ghost hm-btn-sm chat-drawer-withdraw"
              :disabled="withdrawingId === chatApp.id"
              @click="withdrawFromChat"
            >
              <span class="icon icon-sm">close</span>
              {{ withdrawingId === chatApp.id ? $t('common.loading') : $t('apps.withdraw') }}
            </button>
          </div>

          <div ref="chatScrollEl" class="chat-drawer-messages">
            <div v-if="!chatMessages.length" class="chat-drawer-hint">
              {{ $t('apps.chat_hint_master') }}
            </div>
            <div
              v-for="m in chatMessages"
              :key="m.id"
              class="chat-drawer-msg"
              :class="{ mine: m.sender_id === auth.user?.id }"
            >
              <ChatProposalBubble v-if="isProposalMessage(m.text)" :payload="parseProposal(m.text)" />
              <div v-else class="chat-drawer-bubble">{{ m.text }}</div>
              <div class="chat-drawer-time">{{ formatTime(m.created_at) }}</div>
            </div>
          </div>

          <div v-if="canChat(chatApp)" class="chat-drawer-foot">
            <div v-if="showProposeForm" class="chat-propose-form">
              <p class="chat-propose-hint">{{ $t('apps.propose_time_only_hint') }}</p>
              <div class="chat-propose-row">
                <label>{{ $t('apps.propose_date') }}</label>
                <input v-model="proposeDate" type="date" :min="todayStr" />
              </div>
              <div class="chat-propose-row">
                <label>{{ $t('apps.propose_time') }}</label>
                <input v-model="proposeTime" type="time" />
              </div>
              <div class="chat-propose-actions">
                <button class="hm-btn hm-btn-ghost hm-btn-sm" @click="showProposeForm = false">{{ $t('common.cancel') }}</button>
                <button class="hm-btn hm-btn-primary hm-btn-sm" :disabled="!proposeDate || !proposeTime || sendingPropose" @click="sendProposal">
                  <span class="icon icon-sm">send</span>
                  {{ sendingPropose ? $t('common.loading') : $t('apps.send_proposal') }}
                </button>
              </div>
            </div>
            <div v-else class="chat-drawer-input">
              <input
                v-model="chatDraft"
                type="text"
                :placeholder="$t('apps.chat_placeholder')"
                maxlength="2000"
                @keydown.enter.prevent="sendMsg"
              />
              <button class="hm-btn hm-btn-ghost hm-btn-sm" :title="$t('apps.send_proposal')" @click="openProposeForm">
                <span class="icon icon-sm">description</span>
              </button>
              <button class="hm-btn hm-btn-primary hm-btn-sm" :disabled="!chatDraft.trim() || sendingChat" @click="sendMsg">
                <span class="icon icon-sm">send</span>
              </button>
            </div>
          </div>
          <div v-else class="chat-drawer-locked">{{ $t('orders.apps_chat_locked') }}</div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const toast = useToast()
const auth = useAuthStore()
const { formatDateTime: formatDate, formatTime } = useFormatDate()

const tab = ref<'active' | 'accepted' | 'rejected' | 'all'>('active')
const withdrawingId = ref<number | null>(null)

const { data: applications, pending: loading, refresh } = await useAsyncData('master-applications', async () => {
  try {
    const res = await apiFetch<{ applications: any[] }>('/master/applications')
    return res.applications || []
  } catch { return [] }
}, { default: () => [] })

const counts = computed(() => ({
  active: applications.value.filter((a: any) => ['pending', 'discussing', 'proposed'].includes(a.status)).length,
  accepted: applications.value.filter((a: any) => a.status === 'accepted').length,
  rejected: applications.value.filter((a: any) => ['rejected', 'withdrawn', 'expired'].includes(a.status)).length,
}))

const filtered = computed(() => {
  if (tab.value === 'all') return applications.value
  if (tab.value === 'active') return applications.value.filter((a: any) => ['pending', 'discussing', 'proposed'].includes(a.status))
  if (tab.value === 'rejected') return applications.value.filter((a: any) => ['rejected', 'withdrawn', 'expired'].includes(a.status))
  return applications.value.filter((a: any) => a.status === tab.value)
})

function timeAgo(iso: string): string {
  if (!iso) return ''
  const diff = (Date.now() - new Date(iso).getTime()) / 1000
  if (diff < 60) return $t('public_orders.just_now')
  if (diff < 3600) return $t('public_orders.minutes_ago', { n: Math.floor(diff / 60) })
  if (diff < 86400) return $t('public_orders.hours_ago', { n: Math.floor(diff / 3600) })
  return $t('public_orders.days_ago', { n: Math.floor(diff / 86400) })
}

async function withdraw(id: number) {
  if (!confirm($t('apps.withdraw_confirm'))) return
  withdrawingId.value = id
  try {
    await apiFetch(`/order-applications/${id}/withdraw`, { method: 'POST' })
    await refresh()
    toast.success($t('apps.withdrawn_toast'))
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  withdrawingId.value = null
}

// ---- Chat drawer state ----
const chatApp = ref<any | null>(null)
const chatMessages = ref<any[]>([])
const chatDraft = ref('')
const sendingChat = ref(false)
const chatScrollEl = ref<HTMLElement | null>(null)
let chatPoll: ReturnType<typeof setInterval> | null = null

const showProposeForm = ref(false)
const proposeDate = ref('')
const proposeTime = ref('')
const sendingPropose = ref(false)

function photoThumb(url: string): string {
  return url.replace(/_large\.webp$/, '_thumb.webp').replace(/_medium\.webp$/, '_thumb.webp')
}

async function withdrawFromChat() {
  if (!chatApp.value) return
  if (!confirm($t('apps.withdraw_confirm'))) return
  await withdraw(chatApp.value.id)
  closeChat()
}
const todayStr = computed(() => new Date().toISOString().split('T')[0])

// Master can chat once the client has started the discussion. While the
// application is still PENDING the master must wait — the client's first
// message (or "Accept") moves status to DISCUSSING and unlocks the composer.
function canChat(app: any) { return app && ['discussing', 'proposed'].includes(app.status) }
function isProposalMessage(text: string): boolean {
  if (!text) return false
  try { return JSON.parse(text)._type === 'proposal' } catch { return false }
}
function parseProposal(text: string): any {
  try { return JSON.parse(text) } catch { return {} }
}

async function openChat(app: any) {
  chatApp.value = app
  chatMessages.value = []
  chatDraft.value = ''
  showProposeForm.value = false
  await loadMessages()
  // SSE = primary realtime. 10s polling as a safety net.
  chatPoll = setInterval(loadMessages, 10000)
  const sse = useSse()
  sse.onEvent((e: any) => {
    if (e?.type !== 'chat.message') return
    if (!chatApp.value) return
    if (e.scope === 'application' && e.scope_id === chatApp.value.id) {
      loadMessages()
    }
  })
}

// Realtime: when the user-channel emits a chat.message for this application,
// re-fetch the thread immediately so the master's chat reads in real time.
const calls = useCallsStore()
watch(() => calls.chatBus, (e: any) => {
  if (!e || !chatApp.value) return
  if (e.scope === 'application' && e.scope_id === chatApp.value.id) {
    loadMessages()
  }
})

function closeChat() {
  chatApp.value = null
  if (chatPoll) { clearInterval(chatPoll); chatPoll = null }
}

async function loadMessages() {
  if (!chatApp.value) return
  try {
    const lastId = chatMessages.value.reduce((m: number, x: any) => Math.max(m, x.id || 0), 0)
    const url = lastId > 0
      ? `/order-applications/${chatApp.value.id}/messages?since=${lastId}`
      : `/order-applications/${chatApp.value.id}/messages`
    const res = await apiFetch<{ messages: any[] }>(url)
    // Also refresh app status (could have transitioned to proposed/accepted/rejected)
    const myApp = (applications.value || []).find((a: any) => a.id === chatApp.value.id)
    if (myApp) chatApp.value = myApp
    if (lastId > 0) {
      if (!res.messages?.length) return
      const seen = new Set(chatMessages.value.map((m: any) => m.id))
      const fresh = res.messages.filter((m: any) => !seen.has(m.id))
      if (fresh.length) {
        chatMessages.value = [...chatMessages.value, ...fresh]
        await nextTick()
        if (chatScrollEl.value) chatScrollEl.value.scrollTop = chatScrollEl.value.scrollHeight
      }
    } else {
      chatMessages.value = res.messages || []
      await nextTick()
      if (chatScrollEl.value) chatScrollEl.value.scrollTop = chatScrollEl.value.scrollHeight
    }
  } catch {}
}

async function sendMsg() {
  if (!chatApp.value || !chatDraft.value.trim()) return
  sendingChat.value = true
  try {
    const res = await apiFetch<{ message: any }>(`/order-applications/${chatApp.value.id}/messages`, {
      method: 'POST',
      body: { text: chatDraft.value.trim() },
    })
    chatMessages.value = [...chatMessages.value, res.message]
    chatDraft.value = ''
    await nextTick()
    if (chatScrollEl.value) chatScrollEl.value.scrollTop = chatScrollEl.value.scrollHeight
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  sendingChat.value = false
}

function openProposeForm() {
  showProposeForm.value = true
  // Preseed from current proposal if one exists
  if (chatApp.value?.proposed_date) {
    const d = new Date(chatApp.value.proposed_date)
    proposeDate.value = d.toISOString().split('T')[0]
    const h = String(d.getHours()).padStart(2, '0')
    const m = String(d.getMinutes()).padStart(2, '0')
    proposeTime.value = `${h}:${m}`
  }
}

async function sendProposal() {
  if (!chatApp.value || !proposeDate.value || !proposeTime.value) return
  sendingPropose.value = true
  try {
    const iso = `${proposeDate.value}T${proposeTime.value}:00`
    await apiFetch(`/order-applications/${chatApp.value.id}/propose`, {
      method: 'POST',
      body: { proposed_date: iso },
    })
    toast.success($t('apps.proposal_sent'))
    showProposeForm.value = false
    proposeDate.value = ''
    proposeTime.value = ''
    proposePrice.value = null
    await refresh()
    await loadMessages()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  sendingPropose.value = false
}

onUnmounted(() => { if (chatPoll) clearInterval(chatPoll) })

useHead({ title: () => $t('master.my_applications') + ' — Master.az' })
</script>

<style scoped>
.apps-list { display: flex; flex-direction: column; gap: 12px; }
.app-row { padding: 16px 18px; transition: border-color .15s; }
.app-row:hover { border-color: var(--hm-accent); }
.app-row-accepted { border-color: rgba(34,197,94,.35) !important; background: rgba(34,197,94,0.04); }
.app-row-rejected { opacity: .6; }
.app-row-discussing { border-color: rgba(59,130,246,.35) !important; }

.app-row-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; gap: 10px; flex-wrap: wrap; }
.app-cat { display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 14px; color: var(--hm-text); }
.app-cat .icon { color: var(--hm-accent); font-size: 20px; }

.app-status {
  font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 999px;
  text-transform: uppercase; letter-spacing: 0.3px;
}
.app-status-pending { background: rgba(251,191,36,0.12); color: #eab308; }
.app-status-discussing { background: rgba(59,130,246,0.12); color: #3b82f6; }
.app-status-proposed { background: rgba(168,85,247,0.14); color: #a855f7; }
.app-status-accepted { background: rgba(34,197,94,0.12); color: #22c55e; }
.app-status-rejected { background: rgba(239,68,68,0.12); color: #ef4444; }
.app-status-withdrawn { background: var(--hm-bg-3); color: var(--hm-text-3); }

.app-desc {
  font-size: 13.5px; color: var(--hm-text-2); margin: 0 0 10px; line-height: 1.5;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}

.app-meta { display: flex; align-items: center; gap: 8px; font-size: 12px; color: var(--hm-text-3); flex-wrap: wrap; margin-bottom: 8px; }
.app-price-tag {
  background: var(--hm-bg-2); border: 1px solid var(--hm-border); padding: 2px 8px;
  border-radius: 999px; font-weight: 600; color: var(--hm-text); font-size: 11.5px;
}
.app-time { color: var(--hm-text-3); }

.app-message {
  font-size: 13px; color: var(--hm-text-2); padding: 8px 10px;
  background: var(--hm-bg-2); border-radius: 8px; border-left: 3px solid var(--hm-accent);
  margin-bottom: 10px; font-style: italic;
}

.app-actions { display: flex; gap: 8px; flex-wrap: wrap; }

.hm-tab-badge {
  display: inline-block; min-width: 18px; height: 18px; padding: 0 5px;
  background: var(--hm-accent); color: #000; border-radius: 999px;
  font-size: 10.5px; font-weight: 700; line-height: 18px; text-align: center; margin-left: 4px;
}

/* Chat drawer */
.chat-drawer-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.6);
  backdrop-filter: blur(6px);
  display: flex;
  align-items: stretch;
  justify-content: flex-end;
  z-index: 1000;
}
.chat-drawer {
  width: 420px; max-width: 100%;
  background: var(--hm-bg-1);
  border-left: 1px solid var(--hm-border-2);
  display: flex;
  flex-direction: column;
  animation: drawer-in .25s cubic-bezier(.34,1.56,.64,1);
}
@keyframes drawer-in { from { transform: translateX(100%); } to { transform: translateX(0); } }

.chat-drawer-head {
  padding: 16px;
  border-bottom: 1px solid var(--hm-border-2);
  display: flex; align-items: center; justify-content: space-between; gap: 10px;
}
.chat-drawer-title { display: flex; align-items: center; gap: 10px; }
.chat-drawer-avatar {
  width: 40px; height: 40px; border-radius: 50%;
  background: var(--hm-accent); color: #000;
  display: flex; align-items: center; justify-content: center;
  font-weight: 700; background-size: cover; background-position: center;
}
.chat-drawer-title strong { color: var(--hm-text); display: block; font-size: 15px; }
.chat-drawer-sub { font-size: 12px; color: var(--hm-text-3); }
.chat-drawer-close {
  background: transparent; border: 0; color: var(--hm-text-3);
  width: 34px; height: 34px; border-radius: 8px; cursor: pointer;
}
.chat-drawer-close:hover { background: var(--hm-bg-3); color: var(--hm-text); }

.chat-drawer-status {
  padding: 10px 16px; display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
  border-bottom: 1px solid var(--hm-border-2);
  font-size: 12px;
}
.chat-drawer-withdraw { margin-left: auto; color: #ef4444; border-color: rgba(239,68,68,.3); }
.chat-drawer-withdraw:hover:not(:disabled) { background: rgba(239,68,68,.1); }

/* Order details card surfaced above the chat — what the master needs to read
   before deciding on an arrival-time proposal. */
.chat-drawer-order {
  padding: 12px 16px;
  border-bottom: 1px solid var(--hm-border-2);
  display: flex; flex-direction: column; gap: 10px;
  background: var(--hm-bg-2);
}
.cdo-desc { font-size: 13.5px; line-height: 1.45; color: var(--hm-text); white-space: pre-wrap; }
.cdo-photos { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 2px; }
.cdo-photo {
  flex-shrink: 0; width: 84px; height: 84px;
  border-radius: 10px; overflow: hidden;
  border: 1px solid var(--hm-border-2);
}
.cdo-photo img { width: 100%; height: 100%; object-fit: cover; display: block; }
.cdo-meta { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
.cdo-chip {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 3px 9px; border-radius: 99px;
  background: var(--hm-bg-3); border: 1px solid var(--hm-border-2);
  font-size: 11px; color: var(--hm-text-2);
}
.chat-propose-hint { font-size: 12px; color: var(--hm-text-3); margin: 0 0 8px; line-height: 1.4; }

.chat-drawer-messages {
  flex: 1; overflow-y: auto;
  padding: 16px;
  display: flex; flex-direction: column; gap: 10px;
  background: var(--hm-bg-2);
}
.chat-drawer-hint { font-style: italic; color: var(--hm-text-3); text-align: center; padding: 24px 12px; font-size: 13px; }
.chat-drawer-msg { display: flex; flex-direction: column; align-items: flex-start; max-width: 80%; }
.chat-drawer-msg.mine { align-self: flex-end; align-items: flex-end; }
.chat-drawer-bubble {
  padding: 9px 13px; border-radius: 12px;
  background: var(--hm-bg-3); color: var(--hm-text);
  font-size: 13.5px; word-break: break-word;
}
.chat-drawer-msg.mine .chat-drawer-bubble { background: var(--hm-accent); color: #000; }
:global(html.theme-light) .chat-drawer-msg.mine .chat-drawer-bubble { background: #b07f00; color: #fff; }
.chat-drawer-time { font-size: 10.5px; color: var(--hm-text-3); margin-top: 2px; }

.chat-drawer-foot { padding: 12px 16px 16px; border-top: 1px solid var(--hm-border-2); }
.chat-drawer-input { display: flex; align-items: center; gap: 6px; }
.chat-drawer-input input {
  flex: 1; padding: 10px 12px; font-size: 13.5px;
  background: var(--hm-bg-2); border: 1px solid var(--hm-border-2);
  border-radius: 10px; color: var(--hm-text);
}
.chat-drawer-input input:focus { outline: none; border-color: var(--hm-accent); }
.chat-drawer-input .btn,
.chat-drawer-input .hm-btn { height: 40px; min-width: 44px; flex-shrink: 0; }

.chat-drawer-locked { padding: 16px; font-size: 13px; color: var(--hm-text-3); text-align: center; font-style: italic; }

.chat-propose-form { display: flex; flex-direction: column; gap: 8px; }
.chat-propose-row { display: flex; align-items: center; gap: 10px; }
.chat-propose-row label { font-size: 12.5px; color: var(--hm-text-3); width: 90px; font-weight: 600; }
.chat-propose-row input {
  flex: 1; padding: 9px 12px; font-size: 13.5px;
  background: var(--hm-bg-2); border: 1px solid var(--hm-border-2);
  border-radius: 10px; color: var(--hm-text);
}
.chat-propose-row input:focus { outline: none; border-color: var(--hm-accent); }
.chat-propose-actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 4px; }
</style>
