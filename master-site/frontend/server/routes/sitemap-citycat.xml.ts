import { LOCALES, apiJson, renderUrl, urlsetXml, type Locale } from '~~/server/utils/seo'

interface ApiCategory { id: number; slug: string }
interface ApiCity { slug: string; masters_count: number }

export default defineEventHandler(async (event) => {
  setHeader(event, 'content-type', 'application/xml; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=3600, s-maxage=3600')

  // City slugs don't change per locale (already ASCII). Categories do.
  const cities = (await apiJson<{ cities: ApiCity[] }>('/v1/cities')).cities || []

  const catSlugsByLocale = {} as Record<Locale, Map<number, string>>
  await Promise.all(
    LOCALES.map(async (l) => {
      try {
        const r = await apiJson<{ categories: ApiCategory[] }>('/v1/categories?only_with_masters=1', l)
        const m = new Map<number, string>()
        for (const c of r.categories || []) m.set(c.id, c.slug)
        catSlugsByLocale[l] = m
      } catch { catSlugsByLocale[l] = new Map() }
    }),
  )
  // Use AZ as the "canonical" iteration set — every category that exists in AZ
  // should appear in every locale (with localized slug or AZ fallback).
  const baseCategories = catSlugsByLocale.az

  const urls: string[] = []
  for (const city of cities) {
    if (city.masters_count === 0) continue
    for (const [catId, _azSlug] of baseCategories) {
      void _azSlug
      urls.push(
        renderUrl(
          (l) => `/${city.slug}/${catSlugsByLocale[l].get(catId) || baseCategories.get(catId)}`,
          { changefreq: 'weekly', priority: 0.6 },
        ),
      )
    }
  }
  return urlsetXml(urls)
})
