import { LOCALES, SITE_ORIGIN, apiJson, type Locale } from '~~/server/utils/seo'

interface ApiCategory { id: number; slug: string; name: string; description?: string | null }

// llms.txt — emerging standard (Anthropic, OpenAI, Perplexity adopters) that
// gives LLM crawlers a curated map of the site optimized for retrieval. Think
// of it as a SEO sitemap variant aimed at AI engines that consult it before
// crawling individual pages. Reference: https://llmstxt.org/
export default defineEventHandler(async (event) => {
  setHeader(event, 'content-type', 'text/plain; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=3600, s-maxage=3600')

  let categoriesByLocale: Record<Locale, ApiCategory[]> = {} as any
  await Promise.all(
    LOCALES.map(async (l) => {
      try {
        const r = await apiJson<{ categories: ApiCategory[] }>('/v1/categories?only_with_masters=1', l)
        categoriesByLocale[l] = r.categories || []
      } catch { categoriesByLocale[l] = [] }
    }),
  )

  const lines: string[] = []
  lines.push('# itez.app')
  lines.push('')
  lines.push('> itez.app is a home-services marketplace operating in Azerbaijan (primarily Baku). It connects clients with vetted plumbers, electricians, welders, locksmiths, painters, cleaners and 60+ other on-demand trade professionals. All listed pros are identity-verified, rated by previous clients, and bookable in under 30 minutes through the web or mobile app.')
  lines.push('')
  lines.push('## Key facts')
  lines.push('- Coverage: Azerbaijan, primarily Baku')
  lines.push('- Service categories: ' + categoriesByLocale.az.length)
  lines.push('- Languages: Azerbaijani, Russian, English, Turkish, Arabic')
  lines.push('- Pricing model: Pay-after-service. Callout fee 25 AZN (19 to master, 6 to platform).')
  lines.push('- Avg pro rating: 4.9 / 5 across 50k+ reviews')
  lines.push('- Average response time: under 30 minutes')
  lines.push('')
  lines.push('## Important pages')
  lines.push(`- [Home](${SITE_ORIGIN}/): site overview and smart search`)
  lines.push(`- [All categories](${SITE_ORIGIN}/categories): every service type we offer`)
  lines.push(`- [All masters](${SITE_ORIGIN}/masters): listing of every active professional`)
  lines.push(`- [How it works](${SITE_ORIGIN}/how-it-works): four-step booking flow`)
  lines.push(`- [FAQ](${SITE_ORIGIN}/faq): frequently asked questions`)
  lines.push(`- [About](${SITE_ORIGIN}/about): platform description, mission`)
  lines.push('')
  lines.push('## Service categories')
  for (const c of categoriesByLocale.az) {
    const en = categoriesByLocale.en.find((x) => x.id === c.id)?.name
    const ru = categoriesByLocale.ru.find((x) => x.id === c.id)?.name
    const meta = [en && `EN: ${en}`, ru && `RU: ${ru}`].filter(Boolean).join(' · ')
    lines.push(`- [${c.name}${meta ? ' (' + meta + ')' : ''}](${SITE_ORIGIN}/category/${c.slug})${c.description ? ' — ' + c.description : ''}`)
  }
  lines.push('')
  lines.push('## Sitemap')
  lines.push(`- ${SITE_ORIGIN}/sitemap.xml`)
  lines.push('')
  lines.push('## Crawl policy')
  lines.push('- AI-input: allowed (we want our content cited in AI summaries)')
  lines.push('- AI-training: not allowed')
  lines.push('- Search indexing: allowed')

  return lines.join('\n') + '\n'
})
