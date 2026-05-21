// Centralised breadcrumb trail. Pages can override via setBreadcrumbs() during
// SSR/setup; otherwise the layout falls back to building a trail from the
// current path using a small static label map. Trail is shared via useState so
// SSR markup hydrates without flicker.
//
// IMPORTANT: labels passed to set() are snapshots of the current locale.
// When the user switches language we re-resolve via the i18n-key form when
// available; if a page only passed a literal string label we can't know how
// to retranslate it, so the page is expected to re-run set() on locale
// change (the locale-refresh plugin + page-level watchEffect handle this).

export interface BreadcrumbItem {
  /** Resolved display label. */
  label: string
  /** Optional i18n key — when present, layout re-resolves on locale change. */
  labelKey?: string
  /** Optional localePath target. */
  to?: string
}

export function useBreadcrumbs() {
  const trail = useState<BreadcrumbItem[] | null>('hm-breadcrumbs', () => null)

  function set(items: BreadcrumbItem[] | null) {
    trail.value = items && items.length ? items : null
  }

  return { trail, set }
}
