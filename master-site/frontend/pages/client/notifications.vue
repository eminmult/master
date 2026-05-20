<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="client" />
        <div class="hm-dash-main">
      <div class="notif-page-header">
        <h1>{{ $t('notifications.title') }}</h1>
        <button v-if="store.unread > 0" class="btn btn-outline btn-sm" @click="store.markAllRead()">
          <span class="icon icon-sm">done_all</span> {{ $t('notifications.mark_all_read') }}
        </button>
      </div>

      <div v-if="!store.loading && !store.notifications.length" class="empty-state">
        <span class="icon" style="font-size:48px;color:var(--hm-text-3)">notifications_off</span>
        <p class="text-muted mt-2">{{ $t('notifications.empty') }}</p>
      </div>
      <div v-else-if="store.notifications.length" class="notif-full-list">
        <template v-for="(group, label) in groupedNotifications" :key="label">
          <div class="date-divider">{{ label }}</div>
          <div
            v-for="n in group"
            :key="n.id"
          class="notif-full-item"
          :class="{ unread: !n.is_read }"
          @click="handleClick(n)"
        >
          <span class="notif-full-icon icon" :class="iconClass(n.type)">{{ iconName(n.type) }}</span>
          <div class="notif-full-content">
            <strong>{{ n.title }}</strong>
            <p>{{ n.body }}</p>
          </div>
          <div class="notif-full-meta">
            <span class="notif-full-time">{{ formatDate(n.created_at) }}</span>
            <span v-if="!n.is_read" class="notif-full-dot"></span>
          </div>
        </div>
        </template>
        <div v-if="store.notifications.length < store.total" class="text-center mt-3">
          <button class="btn btn-outline btn-sm" @click="store.fetchNotifications()" :disabled="store.loading">
            {{ $t('masters.load_more') }}
          </button>
        </div>
      </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })
const { t: $t } = useI18n()
const localePath = useLocalePath()
const store = useNotificationsStore()
const router = useRouter()

const groupedNotifications = computed(() => {
  const groups: Record<string, any[]> = {}
  for (const n of store.notifications) {
    const label = dateGroup(n.created_at)
    if (!groups[label]) groups[label] = []
    groups[label].push(n)
  }
  return groups
})

const { formatDate: fmtGroup, formatDateTime: formatDate } = useFormatDate()

function dateGroup(dateStr: string): string {
  const d = new Date(dateStr)
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const yesterday = new Date(today.getTime() - 86400000)
  const dateOnly = new Date(d.getFullYear(), d.getMonth(), d.getDate())

  if (dateOnly.getTime() === today.getTime()) return $t('notifications.today')
  if (dateOnly.getTime() === yesterday.getTime()) return $t('notifications.yesterday')
  return fmtGroup(d)
}

const auth = useAuthStore()
function handleClick(n: any) {
  if (!n.is_read) store.markRead(n.id)
  if (n.type === 'new_review') {
    const uid = n.data?.reviewee_id || auth.user?.id
    if (uid) { router.push(localePath('/master/' + uid + '?tab=reviews')); return }
  }
  if (n.data?.order_id) router.push(localePath('/order/' + n.data.order_id))
}

const { iconName, iconClass } = useNotificationIcon()
onMounted(() => store.fetchNotifications(true))
</script>

<style scoped>
.notif-page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 12px; }
h1 { font-size: 26px; font-weight: 700; margin: 0; color: var(--hm-text); letter-spacing: -0.4px; }
.empty-state { text-align: center; padding: 60px 0; color: var(--hm-text-3); }
.empty-state .icon { color: var(--hm-text-3) !important; opacity: 0.5; }
.notif-full-list {
  display: flex;
  flex-direction: column;
  max-width: 760px;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 18px;
  overflow: hidden;
}
.date-divider {
  font-size: 11px;
  font-weight: 700;
  color: var(--hm-text-3);
  text-transform: uppercase;
  letter-spacing: 1px;
  padding: 14px 18px 8px;
  background: var(--hm-bg-2);
}
.notif-full-item {
  display: flex; align-items: flex-start; gap: 14px;
  padding: 16px 18px;
  border-bottom: 1px solid var(--hm-border-2);
  cursor: pointer;
  transition: background 0.15s;
  color: var(--hm-text);
}
.notif-full-item:last-child { border-bottom: 0; }
.notif-full-item:hover { background: var(--hm-bg-2); }
.notif-full-item.unread { background: rgba(255, 255, 0, 0.05); }
.notif-full-item.unread:hover { background: rgba(255, 255, 0, 0.08); }
.notif-full-icon {
  flex-shrink: 0; width: 42px; height: 42px; border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  font-size: 20px;
  background: var(--hm-bg-3);
  color: var(--hm-text-3);
}
.notif-full-icon.icon-success { background: rgba(34, 197, 94, 0.12); color: #22c55e; }
.notif-full-icon.icon-danger { background: rgba(239, 68, 68, 0.12); color: #ef4444; }
.notif-full-icon.icon-primary { background: rgba(255, 255, 0, 0.12); color: var(--hm-accent); }
.notif-full-icon.icon-info { background: rgba(59, 130, 246, 0.12); color: #60a5fa; }
.notif-full-content { flex: 1; min-width: 0; }
.notif-full-content strong { display: block; font-size: 14px; font-weight: 700; color: var(--hm-text); }
.notif-full-content p { font-size: 13px; color: var(--hm-text-3); margin: 3px 0 0; line-height: 1.45; }
.notif-full-meta { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; flex-shrink: 0; }
.notif-full-time { font-size: 11px; color: var(--hm-text-3); white-space: nowrap; }
.notif-full-dot { width: 8px; height: 8px; background: var(--hm-accent); border-radius: 50%; box-shadow: 0 0 8px var(--hm-accent); }
</style>
