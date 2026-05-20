<template>
  <div class="notif-bell" ref="bellRef">
    <button class="bell-btn" @click="toggle">
      <span class="icon">notifications</span>
      <span v-if="store.unread > 0" class="bell-badge">{{ store.unread > 99 ? '99+' : store.unread }}</span>
    </button>

    <Transition name="hm-pop">
      <div v-if="open" class="notif-dropdown hm-popover">
        <div class="hm-popover-glow"></div>
        <div class="hm-popover-head">
          <span class="hm-popover-title">{{ $t('notifications.title') }}</span>
          <button v-if="store.unread > 0" class="hm-popover-action" @click="store.markAllRead()">
            {{ $t('notifications.mark_all_read') }}
          </button>
          <span v-else-if="store.notifications.length" class="hm-popover-meta">{{ store.notifications.length }}</span>
        </div>
        <div class="notif-list" @scroll="onScroll">
          <div v-if="store.loading && !store.notifications.length" class="notif-empty">
            {{ $t('common.loading') }}
          </div>
          <div v-else-if="!store.notifications.length" class="notif-empty">
            <span class="icon notif-empty-icon">notifications_off</span>
            <p>{{ $t('notifications.empty') }}</p>
          </div>
          <template v-else>
            <div
              v-for="(n, i) in store.notifications"
              :key="n.id"
              class="notif-item hm-pop-item"
              :class="{ unread: !n.is_read }"
              :style="{ '--i': Math.min(i, 8) }"
              @click="handleClick(n)"
            >
              <span class="notif-icon icon" :class="iconClass(n.type)">{{ iconName(n.type) }}</span>
              <div class="notif-content">
                <strong>{{ n.title }}</strong>
                <p>{{ n.body }}</p>
                <span class="notif-time">{{ timeAgo(n.created_at) }}</span>
              </div>
              <span v-if="!n.is_read" class="notif-dot"></span>
            </div>
          </template>
        </div>
        <NuxtLink :to="localePath(notifPagePath)" class="hm-popover-foot" @click="open = false">
          {{ $t('notifications.view_all') }}
        </NuxtLink>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
const { t: $t } = useI18n()
const localePath = useLocalePath()
const store = useNotificationsStore()
const auth = useAuthStore()
const router = useRouter()

const open = ref(false)
const bellRef = ref<HTMLElement | null>(null)

const notifPagePath = computed(() => {
  if (auth.isClient) return '/client/notifications'
  if (auth.isMaster) return '/master/notifications'
  return '/admin'
})

function toggle() {
  open.value = !open.value
  if (open.value && !store.notifications.length) {
    store.fetchNotifications(true)
  }
}

function handleClick(n: any) {
  if (!n.is_read) store.markRead(n.id)
  if (n.type === 'new_review') {
    const uid = n.data?.reviewee_id || auth.user?.id
    if (uid) {
      router.push(localePath('/master/' + uid + '?tab=reviews'))
      open.value = false
      return
    }
  }
  if (n.data?.order_id) {
    router.push(localePath('/order/' + n.data.order_id))
    open.value = false
  }
}

function onScroll(e: Event) {
  const el = e.target as HTMLElement
  if (el.scrollTop + el.clientHeight >= el.scrollHeight - 50) {
    if (!store.loading && store.notifications.length < store.total) {
      store.fetchNotifications()
    }
  }
}

const { iconName, iconClass } = useNotificationIcon()

function timeAgo(date: string): string {
  const diff = Date.now() - new Date(date).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return $t('time_ago.now')
  if (mins < 60) return `${mins}${$t('time_ago.min')}`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}${$t('time_ago.hour')}`
  const days = Math.floor(hours / 24)
  return `${days}${$t('time_ago.day')}`
}

function handleClickOutside(e: MouseEvent) {
  if (bellRef.value && !bellRef.value.contains(e.target as Node)) {
    open.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  store.startPolling()
})
onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.notif-bell { position: relative; }
.bell-btn {
  position: relative;
  display: flex;
  align-items: center;
  padding: 6px;
  border-radius: 10px;
  transition: all 200ms cubic-bezier(.4,0,.2,1);
  color: var(--hm-text-2);
  background: transparent;
  border: none;
  cursor: pointer;
}
.bell-btn:hover {
  background: rgba(255, 255, 255, 0.06);
  color: var(--hm-text);
  transform: translateY(-1px);
}
:global(html.theme-light) .bell-btn:hover { background: rgba(0, 0, 0, 0.05); }
.bell-badge {
  position: absolute;
  top: 0; right: 0;
  min-width: 18px;
  height: 18px;
  background: #ef4444;
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  border-radius: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 5px;
  line-height: 1;
  box-shadow: 0 0 0 2px var(--hm-bg-1), 0 0 8px rgba(239,68,68,0.5);
  animation: bell-pulse 2s ease-in-out infinite;
}
@keyframes bell-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.08); }
}

.notif-dropdown { width: 380px; max-width: 95vw; }

.notif-list {
  max-height: 420px;
  overflow-y: auto;
  padding: 6px;
  scrollbar-width: thin;
  scrollbar-color: rgba(255,255,255,0.1) transparent;
}
.notif-list::-webkit-scrollbar { width: 6px; }
.notif-list::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 3px; }

.notif-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 40px 20px;
  color: var(--hm-text-3);
  font-size: 13px;
}
.notif-empty-icon {
  font-size: 36px;
  color: var(--hm-text-3);
  opacity: 0.5;
}

.notif-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px;
  cursor: pointer;
  border-radius: 12px;
  transition: background 160ms, transform 200ms cubic-bezier(.4,0,.2,1);
  margin-bottom: 2px;
}
.notif-item:hover {
  background: rgba(255, 255, 255, 0.05);
  transform: translateX(3px);
}
:global(html.theme-light) .notif-item:hover { background: rgba(0, 0, 0, 0.04); }
.notif-item.unread {
  background: linear-gradient(135deg, rgba(var(--hm-accent-rgb, 250, 204, 21), 0.08), rgba(var(--hm-accent-rgb, 250, 204, 21), 0.02));
  border-left: 2px solid var(--hm-accent);
  padding-left: 10px;
}
.notif-item.unread:hover {
  background: linear-gradient(135deg, rgba(var(--hm-accent-rgb, 250, 204, 21), 0.12), rgba(var(--hm-accent-rgb, 250, 204, 21), 0.04));
}

.notif-icon {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  background: rgba(255, 255, 255, 0.06);
  color: var(--hm-text-2);
}
:global(html.theme-light) .notif-icon { background: rgba(0, 0, 0, 0.04); }
.notif-icon.icon-success { background: rgba(34, 197, 94, 0.15); color: #22c55e; }
.notif-icon.icon-danger { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.notif-icon.icon-primary { background: rgba(59, 130, 246, 0.15); color: #60a5fa; }
.notif-icon.icon-info { background: rgba(2, 132, 199, 0.15); color: #38bdf8; }

.notif-content { flex: 1; min-width: 0; }
.notif-content strong {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: var(--hm-text);
  margin-bottom: 2px;
}
.notif-content p {
  font-size: 12px;
  color: var(--hm-text-2);
  margin: 0 0 3px;
  line-height: 1.4;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.notif-time { font-size: 11px; color: var(--hm-text-3); }

.notif-dot {
  width: 8px;
  height: 8px;
  background: var(--hm-accent);
  border-radius: 50%;
  flex-shrink: 0;
  margin-top: 6px;
  box-shadow: 0 0 8px var(--hm-accent);
  animation: bell-pulse 2s ease-in-out infinite;
}
</style>
