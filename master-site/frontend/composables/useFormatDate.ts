export function useFormatDate() {
  const { locale } = useI18n()

  function formatDate(d: string | Date | null | undefined, opts: Intl.DateTimeFormatOptions = { day: '2-digit', month: '2-digit', year: 'numeric' }): string {
    if (!d) return ''
    const date = typeof d === 'string' ? new Date(d) : d
    if (isNaN(date.getTime())) return ''
    return date.toLocaleDateString(locale.value, opts)
  }

  function formatDateTime(d: string | Date | null | undefined): string {
    return formatDate(d, { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
  }

  function formatShortDateTime(d: string | Date | null | undefined): string {
    return formatDate(d, { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })
  }

  function formatTime(d: string | Date | null | undefined): string {
    if (!d) return ''
    const date = typeof d === 'string' ? new Date(d) : d
    if (isNaN(date.getTime())) return ''
    return date.toLocaleTimeString(locale.value, { hour: '2-digit', minute: '2-digit' })
  }

  return { formatDate, formatDateTime, formatShortDateTime, formatTime }
}
