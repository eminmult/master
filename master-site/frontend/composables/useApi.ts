export const useApi = () => {
  const config = useRuntimeConfig()
  const i18n = (() => { try { return useI18n() } catch { return null } })()

  // On server use internal URL, on client use public URL
  const baseURL = import.meta.server
    ? (process.env.API_INTERNAL_URL || 'http://master-api:8000/api')
    : (config.public.apiBase as string)

  const authToken = useCookie('auth_token', { maxAge: 60 * 60 * 24 * 30 })

  const apiFetch = async <T>(url: string, opts: any = {}): Promise<T> => {
    const locale = i18n?.locale?.value || 'az'
    const headers: Record<string, string> = {
      Accept: 'application/json',
      'Accept-Language': locale,
      ...(opts.headers || {}),
    }

    if (authToken.value) {
      headers.Authorization = `Bearer ${authToken.value}`
    }

    return await $fetch<T>(url, {
      baseURL,
      ...opts,
      headers,
    })
  }

  return { apiFetch, authToken }
}
