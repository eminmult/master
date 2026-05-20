// Page-level SEO orchestration. Sets title, meta description, canonical URL,
// hreflang alternates for all locales + x-default, and Open Graph / Twitter
// Card tags in one call. Pages that have locale-divergent slugs (e.g. the
// master/category pages where slug encodes a translated word) can pass
// `hreflangPaths` to override the default "same path everywhere" rule.

const LOCALES = ['az', 'ru', 'en', 'tr', 'ar'] as const
const DEFAULT_LOCALE = 'az'
const SITE_ORIGIN = 'https://itez.app'
type Locale = (typeof LOCALES)[number]

function localizedHref(path: string, locale: Locale): string {
  const cleaned = path.startsWith('/') ? path : '/' + path
  return SITE_ORIGIN + (locale === DEFAULT_LOCALE ? '' : '/' + locale) + cleaned
}

export interface SeoHeadInput {
  title: string
  description?: string
  /** Path WITHOUT locale prefix. Defaults to current route's stripped path. */
  canonicalPath?: string
  /** Override per-locale path when slug changes between languages. */
  hreflangPaths?: Partial<Record<Locale, string>>
  /** Absolute or root-relative image URL. */
  image?: string
  /** noindex when true — for thin pages, search results, etc. */
  noindex?: boolean
  /** Schema.org type for og:type. Defaults to "website". */
  ogType?: 'website' | 'article' | 'profile'
}

export function useSeoHead(input: SeoHeadInput | (() => SeoHeadInput)) {
  const route = useRoute()
  const i18n = useI18n()

  const resolve = (): SeoHeadInput => (typeof input === 'function' ? input() : input)

  const data = computed(() => {
    const inp = resolve()
    const localeNow = (i18n.locale.value || DEFAULT_LOCALE) as Locale
    // Strip the locale prefix from current path so we can rebuild per locale.
    const rawPath = route.path || '/'
    const stripped = rawPath.replace(/^\/(az|ru|en|tr|ar)(?=\/|$)/, '') || '/'
    const canonical = inp.canonicalPath || stripped

    const hreflangs = LOCALES.map((l) => ({
      l,
      href: localizedHref(inp.hreflangPaths?.[l] || canonical, l),
    }))

    return { inp, localeNow, canonical, hreflangs }
  })

  useHead(() => {
    const { inp, localeNow, canonical, hreflangs } = data.value
    const canonicalHref = localizedHref(canonical, localeNow)
    const imageAbs = inp.image
      ? inp.image.startsWith('http')
        ? inp.image
        : SITE_ORIGIN + (inp.image.startsWith('/') ? inp.image : '/' + inp.image)
      : `${SITE_ORIGIN}/og-default.png`

    const meta: { name?: string; property?: string; content: string }[] = []
    if (inp.description) {
      meta.push({ name: 'description', content: inp.description })
      meta.push({ property: 'og:description', content: inp.description })
      meta.push({ name: 'twitter:description', content: inp.description })
    }
    meta.push({ property: 'og:title', content: inp.title })
    meta.push({ name: 'twitter:title', content: inp.title })
    meta.push({ property: 'og:type', content: inp.ogType || 'website' })
    meta.push({ property: 'og:url', content: canonicalHref })
    meta.push({ property: 'og:locale', content: localeNow })
    meta.push({ property: 'og:image', content: imageAbs })
    meta.push({ name: 'twitter:card', content: 'summary_large_image' })
    meta.push({ name: 'twitter:image', content: imageAbs })
    if (inp.noindex) meta.push({ name: 'robots', content: 'noindex, follow' })

    const link: { rel: string; href: string; hreflang?: string }[] = [
      { rel: 'canonical', href: canonicalHref },
    ]
    for (const h of hreflangs) {
      link.push({ rel: 'alternate', hreflang: h.l, href: h.href })
    }
    // x-default → AZ canonical (per Google guidance for sites without an
    // automatic country/language fallback page).
    link.push({
      rel: 'alternate',
      hreflang: 'x-default',
      href: localizedHref(inp.hreflangPaths?.az || canonical, 'az'),
    })

    return {
      title: inp.title,
      meta,
      link,
    }
  })
}
