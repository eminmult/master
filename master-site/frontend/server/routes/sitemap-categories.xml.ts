import { LOCALES, apiJson, renderUrl, urlsetXml, type Locale } from '~~/server/utils/seo'

interface ApiCategory {
  id: number
  slug: string
  slug_az?: string
  name: string
  masters_count?: number | null
}

// Per-locale categories with localized slugs. We fetch once per locale so we
// can build hreflang-correct URLs in renderUrl().
async function fetchAll(): Promise<Record<Locale, ApiCategory[]>> {
  const map = {} as Record<Locale, ApiCategory[]>
  await Promise.all(
    LOCALES.map(async (l) => {
      try {
        const r = await apiJson<{ categories: ApiCategory[] }>('/v1/categories?only_with_masters=1', l)
        map[l] = r.categories || []
      } catch {
        map[l] = []
      }
    }),
  )
  return map
}

export default defineEventHandler(async (event) => {
  setHeader(event, 'content-type', 'application/xml; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=3600, s-maxage=3600')

  const byLocale = await fetchAll()
  // Build a Map<id, locale → slug> so every <url> entry can emit the
  // right slug in each language.
  const idToSlugs = new Map<number, Record<Locale, string>>()
  for (const l of LOCALES) {
    for (const c of byLocale[l]) {
      const m = idToSlugs.get(c.id) || ({} as Record<Locale, string>)
      m[l] = c.slug
      idToSlugs.set(c.id, m)
    }
  }

  const urls: string[] = []
  for (const [id, slugs] of idToSlugs) {
    void id
    urls.push(
      renderUrl((l) => `/category/${slugs[l] || slugs.az}`, {
        changefreq: 'weekly',
        priority: 0.8,
      }),
    )
  }
  return urlsetXml(urls)
})
