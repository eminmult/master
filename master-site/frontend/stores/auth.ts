import { defineStore } from 'pinia'

interface MasterSubscription {
  active: boolean
  expires_at: string | null
  required: boolean
  free_launch_until: string | null
  can_operate: boolean
}

interface User {
  id: number
  first_name: string
  last_name: string | null
  full_name: string
  email: string | null
  phone: string
  role: 'client' | 'master' | 'admin'
  avatar_url: string | null
  locale: string | null
  rating_avg: string
  rating_count: number
  is_active: boolean
  is_verified?: boolean
  verified_at?: string | null
  email_verified_at: string | null
  phone_verified_at: string | null
  subscription?: MasterSubscription
  master_profile?: any
  addresses?: any[]
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const isLoggedIn = computed(() => !!user.value)
  const isClient = computed(() => user.value?.role === 'client')
  const isMaster = computed(() => user.value?.role === 'master')
  const isAdmin = computed(() => user.value?.role === 'admin')

  const { apiFetch, authToken } = useApi()

  /**
   * Apply server-stored locale to the active i18n state. Called whenever a
   * fresh user payload arrives (login / register / /auth/me) so the language
   * follows the account across devices, matching the mobile app.
   */
  async function applyUserLocale(u: User | null) {
    const code = u?.locale
    if (!code) return
    const supported = ['az', 'ru', 'en', 'tr', 'ar']
    if (!supported.includes(code)) return
    try {
      const { $i18n } = useNuxtApp() as any
      if ($i18n && $i18n.locale.value !== code) {
        await $i18n.setLocale(code)
      }
      const cookie = useCookie('i18n_lang', { maxAge: 60 * 60 * 24 * 365 })
      cookie.value = code
    } catch { /* SSR or i18n not ready — noop */ }
  }

  async function login(login: string, password: string) {
    const res = await apiFetch<{ user: User; token: string }>('/auth/login', {
      method: 'POST',
      body: { login, password },
    })
    authToken.value = res.token
    user.value = res.user
    await applyUserLocale(res.user)
    return res.user
  }

  async function registerClient(data: any) {
    const res = await apiFetch<{ user: User; token: string }>('/auth/register/client', {
      method: 'POST',
      body: data,
    })
    authToken.value = res.token
    user.value = res.user
    await applyUserLocale(res.user)
    return res.user
  }

  async function registerMaster(data: any) {
    const res = await apiFetch<{ user: User; token: string }>('/auth/register/master', {
      method: 'POST',
      body: data,
    })
    authToken.value = res.token
    user.value = res.user
    await applyUserLocale(res.user)
    return res.user
  }

  async function fetchUser() {
    if (!authToken.value) return null
    try {
      const res = await apiFetch<{ user: User }>('/auth/me')
      user.value = res.user
      await applyUserLocale(res.user)
      return res.user
    } catch {
      authToken.value = null
      user.value = null
      return null
    }
  }

  async function logout() {
    try {
      const notifications = useNotificationsStore()
      notifications.stopPolling()
    } catch {}
    try {
      await apiFetch('/auth/logout', { method: 'POST' })
    } catch {}
    authToken.value = null
    user.value = null
  }

  return {
    user, isLoggedIn, isClient, isMaster, isAdmin,
    login, registerClient, registerMaster, fetchUser, logout,
  }
})
