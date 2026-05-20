// Centralised breadcrumb trail. Pages can override via setBreadcrumbs() during
// SSR/setup; otherwise the layout falls back to building a trail from the
// current path using a small static label map. Trail is shared via useState so
// SSR markup hydrates without flicker.

export interface BreadcrumbItem {
  label: string
  to?: string
}

export function useBreadcrumbs() {
  const trail = useState<BreadcrumbItem[] | null>('hm-breadcrumbs', () => null)

  function set(items: BreadcrumbItem[] | null) {
    trail.value = items && items.length ? items : null
  }

  return { trail, set }
}
