<template>
  <div class="chat-container">
    <div class="chat-header">
      <span class="icon">chat</span>
      <div class="chat-header-info">
        <span>{{ $t('chat.title') }}</span>
        <span v-if="partnerName" class="chat-partner">{{ partnerName }}</span>
      </div>
      <span v-if="partnerOnline" class="chat-online-badge">
        <span class="online-dot"></span> {{ $t('masters.online') }}
      </span>
    </div>

    <div class="chat-messages" ref="messagesRef">
      <button v-if="hasMore" class="load-more-btn" @click="loadEarlier">
        {{ $t('chat.load_earlier') }}
      </button>

      <div v-if="!messages.length && !loading" class="chat-empty">
        <span class="icon" style="font-size:32px;color:var(--gray-300)">forum</span>
        <p>{{ $t('chat.no_messages') }}</p>
      </div>

      <template v-for="(msg, idx) in messages" :key="msg.id">
        <!-- Date separator -->
        <div v-if="idx === 0 || dateLabel(msg.created_at) !== dateLabel(messages[idx-1].created_at)" class="msg-date-sep">
          {{ dateLabel(msg.created_at) }}
        </div>
        <!-- System message (proposal/confirmed/rejected) -->
        <div v-if="parseSystem(msg.text)" class="msg-system">
          <div v-if="parseSystem(msg.text)._type === 'proposal'" class="sys-card proposal">
            <div class="sys-icon"><span class="icon">description</span></div>
            <div>
              <strong>{{ $t('chat.proposal_msg') }}</strong>
              <p v-if="parseSystem(msg.text).date"><span class="icon icon-sm">event</span> {{ parseSystem(msg.text).date }}</p>
              <p v-if="parseSystem(msg.text).price"><span class="icon icon-sm">payments</span> {{ parseSystem(msg.text).price }} AZN</p>
            </div>
          </div>
          <div v-else-if="parseSystem(msg.text)._type === 'confirmed'" class="sys-card confirmed">
            <span class="icon">check_circle</span> {{ $t('chat.confirmed_msg') }}
          </div>
          <div v-else-if="parseSystem(msg.text)._type === 'rejected'" class="sys-card rejected">
            <span class="icon">refresh</span> {{ $t('chat.rejected_msg') }}
          </div>
          <div v-else-if="parseSystem(msg.text)._type === 'work_started'" class="sys-card confirmed">
            <span class="icon">construction</span>
            {{ $t('chat.work_started_msg') }} · ~{{ parseSystem(msg.text).duration }} {{ $t('map.min') }}
            <span v-if="parseSystem(msg.text).end_time" class="text-muted"> ({{ parseSystem(msg.text).end_time }})</span>
          </div>
          <div v-else-if="parseSystem(msg.text)._type === 'callout_paid'" class="sys-card confirmed">
            <span class="icon">payments</span>
            {{ $t('chat.callout_paid_msg') }} ·
            {{ parseSystem(msg.text).amount }} {{ parseSystem(msg.text).currency || 'AZN' }}
          </div>
          <span class="msg-time sys-time">{{ formatTime(msg.created_at) }}</span>
        </div>
        <!-- Normal message -->
        <div v-else class="msg" :class="{ mine: msg.is_mine }">
          <div class="msg-bubble">
            <p>{{ msg.text }}</p>
            <span class="msg-time">{{ formatTime(msg.created_at) }}</span>
          </div>
        </div>
      </template>
    </div>

    <form v-if="chatActive" class="chat-input" @submit.prevent="send">
      <input
        v-model="newMessage"
        type="text"
        :placeholder="$t('chat.placeholder')"
        :disabled="sending"
        maxlength="2000"
      />
      <button type="submit" class="send-btn" :disabled="!newMessage.trim() || sending">
        <span class="icon">send</span>
      </button>
    </form>
    <div v-else class="chat-closed">
      <span class="icon icon-sm">lock</span>
      {{ $t('chat.closed') }}
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  orderId: number
  partnerName?: string
  chatActive?: boolean
  partnerOnline?: boolean
}>()

const { t: $t } = useI18n()
const { apiFetch } = useApi()

const messages = ref<any[]>([])
const newMessage = ref('')
const sending = ref(false)
const loading = ref(true)
const hasMore = ref(false)
const messagesRef = ref<HTMLElement | null>(null)

let pollTimer: ReturnType<typeof setInterval> | null = null

const { formatDate: fmtDate, formatTime } = useFormatDate()

function dateLabel(dateStr: string): string {
  const d = new Date(dateStr)
  const today = new Date()
  if (d.toDateString() === today.toDateString()) return $t('notifications.today')
  const yesterday = new Date(today.getTime() - 86400000)
  if (d.toDateString() === yesterday.toDateString()) return $t('notifications.yesterday')
  return fmtDate(d)
}

function parseSystem(text: string): any {
  if (!text || !text.startsWith('{')) return null
  try {
    const obj = JSON.parse(text)
    return obj._type ? obj : null
  } catch { return null }
}

function mergeMessages(incoming: any[]): { added: any[] } {
  const existing = new Map<number, any>()
  for (const m of messages.value) existing.set(m.id, m)
  const added: any[] = []
  for (const m of incoming) {
    if (!existing.has(m.id)) added.push(m)
    existing.set(m.id, m)
  }
  const merged = [...existing.values()].sort((a, b) => a.id - b.id)
  messages.value = merged
  return { added }
}

async function loadMessages(before?: number) {
  try {
    const params = before ? `?limit=30&before=${before}` : '?limit=30'
    const res = await apiFetch<{ messages: any[]; has_more: boolean }>(
      `/orders/${props.orderId}/messages${params}`
    )
    mergeMessages(res.messages)
    hasMore.value = res.has_more
  } catch {}
  loading.value = false
}

async function loadEarlier() {
  if (!messages.value.length) return
  await loadMessages(messages.value[0].id)
}

let polling = false
function stopPolling() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
}
function isTerminalStatus(status?: number): boolean {
  return status === 401 || status === 403 || status === 404
}

async function pollNew() {
  if (polling) return
  polling = true
  try {
    if (!messages.value.length) {
      await loadMessages()
      scrollBottom()
      return
    }
    const res = await apiFetch<{ messages: any[] }>(
      `/orders/${props.orderId}/messages?limit=30`
    )
    const { added } = mergeMessages(res.messages)
    if (added.length) {
      const hasIncoming = added.some((m: any) => !m.is_mine)
      if (hasIncoming) {
        const { playMessage } = useSound()
        playMessage()
      }
      nextTick(scrollBottom)
    }
  } catch (e: any) {
    // Stop polling if the order no longer exists, was closed, or session expired —
    // otherwise we keep pounding the API with requests that can never succeed.
    const status = e?.response?.status || e?.status || e?.statusCode
    if (isTerminalStatus(status)) stopPolling()
  } finally {
    polling = false
  }
}

async function send() {
  const text = newMessage.value.trim()
  if (!text) return
  sending.value = true
  newMessage.value = ''
  try {
    const res = await apiFetch<{ message: any }>(`/orders/${props.orderId}/messages`, {
      method: 'POST',
      body: { text },
    })
    mergeMessages([res.message])
    nextTick(scrollBottom)
  } catch (e: any) {
    newMessage.value = text
    console.error('Send failed:', e?.data?.message || e)
  }
  sending.value = false
}

function scrollBottom() {
  if (messagesRef.value) {
    messagesRef.value.scrollTop = messagesRef.value.scrollHeight
  }
}

onMounted(async () => {
  await loadMessages()
  nextTick(scrollBottom)
  // Poll only for active chats — every 2 seconds
  if (props.chatActive) {
    pollTimer = setInterval(pollNew, 2000)
  }
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})
</script>

<style scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  border: 1px solid var(--hm-border-2);
  border-radius: 20px;
  overflow: hidden;
  height: 560px;
  background: var(--hm-bg-1);
  background-image: radial-gradient(circle at 20% 20%, rgba(255, 255, 0, 0.04), transparent 50%);
}
:global(html.theme-light) .chat-container { background: #fff; background-image: none; }
.chat-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 18px;
  border-bottom: 1px solid var(--hm-border-2);
  font-weight: 700;
  font-size: 14px;
  background: var(--hm-bg-2);
  color: var(--hm-text);
}
.chat-header .icon { color: var(--hm-accent); }
.chat-header-info { display: flex; flex-direction: column; }
.chat-partner { font-weight: 400; color: var(--hm-text-3); font-size: 11px; }
.chat-online-badge {
  margin-left: auto; display: flex; align-items: center; gap: 5px;
  font-size: 11px; font-weight: 600; color: #22c55e;
}
.online-dot { width: 6px; height: 6px; border-radius: 50%; background: #22c55e; box-shadow: 0 0 6px #22c55e; }
.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 18px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.chat-messages::-webkit-scrollbar { width: 6px; }
.chat-messages::-webkit-scrollbar-thumb { background: var(--hm-border-2); border-radius: 3px; }
.chat-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  gap: 8px;
  color: var(--hm-text-3);
  font-size: 14px;
}
.load-more-btn {
  align-self: center;
  font-size: 12px;
  color: var(--hm-text);
  font-weight: 600;
  padding: 6px 14px;
  border-radius: 999px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  margin-bottom: 8px;
  cursor: pointer;
}
.load-more-btn:hover { background: var(--hm-bg-3); }
.msg { display: flex; }
.msg.mine { justify-content: flex-end; }
.msg-bubble {
  max-width: 72%;
  padding: 12px 16px;
  border-radius: 20px 20px 20px 4px;
  font-size: 14px;
  line-height: 1.45;
  background: var(--hm-bg-2);
  color: var(--hm-text);
  border: 1px solid var(--hm-border-2);
}
.msg.mine .msg-bubble {
  background: var(--hm-accent);
  color: #000;
  border-radius: 20px 20px 4px 20px;
  border-color: transparent;
}
:global(html.theme-light) .msg.mine .msg-bubble { background: #facc15; color: #111; }
.msg-time {
  display: block;
  font-size: 10px;
  margin-top: 4px;
  opacity: 0.7;
  text-align: right;
}
.chat-input {
  display: flex;
  gap: 8px;
  align-items: center;
  padding: 10px 12px;
  border-top: 1px solid var(--hm-border-2);
  background: var(--hm-bg-2);
}
.chat-input input {
  flex: 1;
  border: 1px solid var(--hm-border-2);
  border-radius: 999px;
  padding: 10px 18px;
  font-size: 14px;
  background: var(--hm-bg-3);
  color: var(--hm-text);
  outline: 0;
}
.chat-input input:focus { border-color: var(--hm-accent); }
.chat-input input::placeholder { color: var(--hm-text-3); }
.send-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--hm-accent);
  color: #000;
  border: none;
  cursor: pointer;
  transition: transform 0.15s;
}
:global(html.theme-light) .send-btn { background: #facc15; color: #111; }
.send-btn:hover:not(:disabled) { transform: scale(1.05); }
.send-btn:disabled { opacity: 0.5; cursor: not-allowed; }

.msg-date-sep {
  text-align: center; font-size: 10px; font-weight: 600; color: var(--hm-text-3);
  margin: 12px 0 4px; padding: 4px 12px; background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 999px; display: inline-block; align-self: center; letter-spacing: 0.5px; text-transform: uppercase;
}

.msg-system { display: flex; flex-direction: column; align-items: center; margin: 8px 0; }
.sys-card {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 16px; border-radius: 14px;
  font-size: 13px; font-weight: 500; max-width: 85%;
  color: var(--hm-text);
}
.sys-card.proposal {
  background: rgba(255, 255, 0, 0.08);
  border: 1px solid rgba(255, 255, 0, 0.3);
  flex-direction: row; align-items: flex-start;
}
:global(html.theme-light) .sys-card.proposal { background: rgba(177, 127, 0, 0.08); border-color: rgba(177, 127, 0, 0.3); }
.sys-card.proposal strong { display: block; font-size: 13px; margin-bottom: 4px; color: var(--hm-text); }
.sys-card.proposal p { display: flex; align-items: center; gap: 6px; font-size: 12px; margin: 2px 0; color: var(--hm-text-2); }
.sys-icon { color: var(--hm-accent); }
.sys-icon .icon { font-size: 20px; }
.sys-card.confirmed { background: rgba(34, 197, 94, 0.10); border: 1px solid rgba(34, 197, 94, 0.3); }
.sys-card.rejected { background: rgba(239, 68, 68, 0.10); border: 1px solid rgba(239, 68, 68, 0.3); }
.sys-time { font-size: 10px; color: var(--hm-text-3); margin-top: 4px; }

.chat-closed {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px;
  background: var(--hm-bg-2);
  border-top: 1px solid var(--hm-border-2);
  font-size: 13px;
  color: var(--hm-text-3);
}
</style>
