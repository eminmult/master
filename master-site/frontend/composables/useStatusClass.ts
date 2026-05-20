export function useStatusClass() {
  function statusClass(s: string): string {
    if (!s) return 'badge-warning'
    if (s.startsWith('canceled')) return 'badge-danger'
    if (['completed', 'closed'].includes(s)) return 'badge-success'
    if (['discussion', 'pending_master', 'pending_client', 'awaiting_completion', 'awaiting_review'].includes(s)) return 'badge-warning'
    if (['confirmed', 'accepted', 'on_the_way', 'arrived', 'in_progress'].includes(s)) return 'badge-primary'
    return 'badge-warning'
  }
  return { statusClass }
}
