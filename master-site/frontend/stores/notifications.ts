import { defineStore } from 'pinia'

export const useNotificationsStore = defineStore('notifications', () => {
  const { apiFetch } = useApi()
  const { locale } = useI18n()

  const notifications = ref<any[]>([])
  const unread = ref(0)
  const total = ref(0)
  const loading = ref(false)
  let pollTimer: ReturnType<typeof setInterval> | null = null

  function getLocalized(obj: any): string {
    if (!obj) return ''
    if (typeof obj === 'string') {
      try { obj = JSON.parse(obj) } catch { return obj }
    }
    return obj[locale.value] || obj['az'] || obj['en'] || Object.values(obj)[0] || ''
  }

  async function fetchUnreadCount() {
    try {
      const res = await apiFetch<{ unread: number }>('/notifications/unread-count')
      // Play sound if new unread appeared
      if (res.unread > unread.value && unread.value >= 0) {
        try {
          const { playNotification } = useSound()
          playNotification()
        } catch {}
      }
      unread.value = res.unread
    } catch {}
  }

  async function fetchNotifications(reset = false) {
    loading.value = true
    const offset = reset ? 0 : notifications.value.length
    try {
      const res = await apiFetch<{ notifications: any[]; total: number; unread: number; has_more: boolean }>(
        `/notifications?limit=20&offset=${offset}`
      )
      const mapped = res.notifications.map((n: any) => ({
        ...n,
        title: getLocalized(n.titles),
        body: getLocalized(n.bodies),
      }))
      if (reset) {
        notifications.value = mapped
      } else {
        notifications.value.push(...mapped)
      }
      total.value = res.total
      unread.value = res.unread
    } catch {}
    loading.value = false
  }

  async function markRead(id: number) {
    try {
      await apiFetch(`/notifications/${id}/read`, { method: 'POST' })
      const n = notifications.value.find(x => x.id === id)
      if (n) n.is_read = true
      unread.value = Math.max(0, unread.value - 1)
    } catch {}
  }

  async function markAllRead() {
    try {
      await apiFetch('/notifications/read-all', { method: 'POST' })
      notifications.value.forEach(n => n.is_read = true)
      unread.value = 0
    } catch {}
  }

  let visibilityHandler: (() => void) | null = null

  function startPolling() {
    stopPolling()
    if (import.meta.client && typeof document !== 'undefined' && document.hidden) {
      // Defer until visible; still register handler
    } else {
      fetchUnreadCount()
      pollTimer = setInterval(fetchUnreadCount, 5000)
    }
    if (import.meta.client && typeof document !== 'undefined' && !visibilityHandler) {
      visibilityHandler = () => {
        if (document.hidden) {
          if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
        } else if (!pollTimer) {
          fetchUnreadCount()
          pollTimer = setInterval(fetchUnreadCount, 5000)
        }
      }
      document.addEventListener('visibilitychange', visibilityHandler)
    }
  }

  function stopPolling() {
    if (pollTimer) {
      clearInterval(pollTimer)
      pollTimer = null
    }
    if (import.meta.client && visibilityHandler && typeof document !== 'undefined') {
      document.removeEventListener('visibilitychange', visibilityHandler)
      visibilityHandler = null
    }
  }

  return {
    notifications, unread, total, loading,
    fetchNotifications, fetchUnreadCount, markRead, markAllRead,
    startPolling, stopPolling,
  }
})
