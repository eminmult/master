import { LOCALES, apiJson, renderUrl, urlsetXml, type Locale } from '~~/server/utils/seo'

interface ApiMaster { id: number; slug: string; updated_at?: string }

async function fetchAll(): Promise<Record<Locale, ApiMaster[]>> {
  const map = {} as Record<Locale, ApiMaster[]>
  await Promise.all(
    LOCALES.map(async (l) => {
      try {
        // Listing endpoint already caps to ~50 — for sitemap we want all
        // active masters; the controller default order doesn't matter here.
        const r = await apiJson<{ masters: ApiMaster[] }>('/v1/masters?limit=500', l)
        map[l] = r.masters || []
      } catch {
        map[l] = []
      }
    }),
  )
  return map
}

export default defineEventHandler(async (event) => {
  setHeader(event, 'content-type', 'application/xml; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=900, s-maxage=900')

  const byLocale = await fetchAll()
  const idToSlugs = new Map<number, Record<Locale, string>>()
  for (const l of LOCALES) {
    for (const m of byLocale[l]) {
      const obj = idToSlugs.get(m.id) || ({} as Record<Locale, string>)
      obj[l] = m.slug
      idToSlugs.set(m.id, obj)
    }
  }

  const urls: string[] = []
  for (const [id, slugs] of idToSlugs) {
    void id
    urls.push(
      renderUrl((l) => `/master/${slugs[l] || slugs.az}`, {
        changefreq: 'daily',
        priority: 0.7,
      }),
    )
  }
  return urlsetXml(urls)
})
