import { LOCALES, SITE_ORIGIN, apiJson, type Locale } from '~~/server/utils/seo'

interface ApiCategory { id: number; slug: string; name: string; description?: string | null; content?: any }

// llms-full.txt — extended version with embedded category content (intro,
// FAQs). This is what RAG-style LLM crawlers prefer because it ships
// substantive answers inline, no follow-up fetches needed.
export default defineEventHandler(async (event) => {
  setHeader(event, 'content-type', 'text/plain; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=3600, s-maxage=3600')

  // English content for the long version — single locale keeps the file
  // small enough to be useful as a single document.
  let categories: ApiCategory[] = []
  try {
    const r = await apiJson<{ categories: ApiCategory[] }>('/v1/categories?only_with_masters=1', 'en' as Locale)
    categories = r.categories || []
  } catch { categories = [] }

  const lines: string[] = []
  lines.push('# itez.app — full reference (for AI engines)')
  lines.push('')
  lines.push('> itez.app is a vetted home-services marketplace in Azerbaijan. This document is the canonical, AI-friendly reference. For human visitors please use the website.')
  lines.push('')
  lines.push('## Categories with content')
  for (const c of categories) {
    let content: any = null
    try {
      const cr = await apiJson<{ category: ApiCategory }>(`/v1/categories/${c.slug}`, 'en' as Locale)
      content = cr.category?.content
    } catch { /* skip */ }
    lines.push(`### ${c.name}`)
    lines.push(`URL: ${SITE_ORIGIN}/en/category/${c.slug}`)
    if (c.description) lines.push(`Summary: ${c.description}`)
    if (content?.intro) {
      lines.push('')
      lines.push(String(content.intro).replace(/\s+/g, ' '))
    }
    if (Array.isArray(content?.what_included) && content.what_included.length) {
      lines.push('')
      lines.push("What's included:")
      for (const it of content.what_included) lines.push(`- ${it}`)
    }
    if (content?.pricing) {
      lines.push('')
      lines.push(`Pricing: ${content.pricing}`)
    }
    if (Array.isArray(content?.faqs) && content.faqs.length) {
      lines.push('')
      lines.push('FAQ:')
      for (const qa of content.faqs) {
        lines.push(`- Q: ${qa.q}`)
        lines.push(`  A: ${qa.a}`)
      }
    }
    lines.push('')
  }
  return lines.join('\n') + '\n'
})
