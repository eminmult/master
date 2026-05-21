import { LOCALES, apiJson, renderUrl, urlsetXml, type Locale } from '~~/server/utils/seo'

interface ApiPost { id: number; slug: string; published_at?: string }

export default defineEventHandler(async (event) => {
  setHeader(event, 'content-type', 'application/xml; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=900, s-maxage=900')

  // Posts share canonical slug across locales (the post exists in multiple
  // languages with the same slug). We iterate AZ as the canonical source.
  const byLocale = {} as Record<Locale, ApiPost[]>
  await Promise.all(
    LOCALES.map(async (l) => {
      try {
        const r = await apiJson<{ posts: ApiPost[] }>('/v1/posts', l)
        byLocale[l] = r.posts || []
      } catch { byLocale[l] = [] }
    }),
  )

  const seen = new Set<string>()
  const urls: string[] = []
  for (const p of byLocale.az) {
    if (seen.has(p.slug)) continue
    seen.add(p.slug)
    urls.push(
      renderUrl(() => `/blog/${p.slug}`, {
        lastmod: p.published_at,
        changefreq: 'monthly',
        priority: 0.6,
      }),
    )
  }
  return urlsetXml(urls)
})
