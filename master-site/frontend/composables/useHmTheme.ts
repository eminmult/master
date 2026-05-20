// Global theme state (dark/light) for the hm design language.
// Shared across all pages so navigation doesn't flash.
export function useHmTheme() {
  const value = useState<'dark' | 'light'>('hm-theme', () => 'light')

  function apply(t: 'dark' | 'light') {
    if (!import.meta.client) return
    document.documentElement.classList.toggle('theme-light', t === 'light')
    localStorage.setItem('hm_theme', t)
  }

  function toggle() {
    value.value = value.value === 'dark' ? 'light' : 'dark'
    apply(value.value)
  }

  function init() {
    if (!import.meta.client) return
    const saved = localStorage.getItem('hm_theme') as 'dark' | 'light' | null
    if (saved) value.value = saved
    apply(value.value)
  }

  return { value, toggle, init }
}
