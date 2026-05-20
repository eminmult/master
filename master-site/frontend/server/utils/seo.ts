// Shared SEO helpers for sitemap, robots and llms.txt.
// Locale codes here must mirror nuxt.config.ts i18n.locales.

export const LOCALES = ['az', 'ru', 'en', 'tr', 'ar'] as const
export const DEFAULT_LOCALE = 'az'
export type Locale = (typeof LOCALES)[number]

export const SITE_ORIGIN = 'https://itez.app'

// Build a localized public URL. AZ omits the prefix (matches
// strategy:'prefix_except_default' in nuxt i18n).
export function localizedUrl(path: string, locale: Locale): string {
  const cleaned = path.startsWith('/') ? path : '/' + path
  const prefix = locale === DEFAULT_LOCALE ? '' : '/' + locale
  return SITE_ORIGIN + prefix + cleaned
}

// Server-side API base — talks to Laravel directly inside docker network.
export function internalApiBase(): string {
  return process.env.API_INTERNAL_URL || 'http://master-api:8000/api'
}

// Fetch JSON from backend with locale header so localized fields come back
// for the right language. Used by sitemap generators.
export async function apiJson<T>(path: string, locale: Locale = DEFAULT_LOCALE): Promise<T> {
  return await $fetch<T>(internalApiBase() + path, {
    headers: { 'Accept-Language': locale, Accept: 'application/json' },
  })
}

// XML helpers — escape user content to avoid breaking the document.
export function xmlEscape(s: string): string {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

export interface SitemapEntry {
  path: string
  lastmod?: string // ISO 8601
  changefreq?: 'always' | 'hourly' | 'daily' | 'weekly' | 'monthly' | 'yearly' | 'never'
  priority?: number // 0.0..1.0
}

// Render a <url> with xhtml:link hreflang alternates for every locale. Pass a
// builder that produces the path for a given locale (so localized slugs are
// honored).
export function renderUrl(builder: (l: Locale) => string, extra: Omit<SitemapEntry, 'path'> = {}): string {
  const alts = LOCALES.map((l) => {
    const href = SITE_ORIGIN + (l === DEFAULT_LOCALE ? '' : '/' + l) + builder(l)
    return `    <xhtml:link rel="alternate" hreflang="${l}" href="${xmlEscape(href)}"/>`
  })
  // x-default → AZ canonical.
  alts.push(
    `    <xhtml:link rel="alternate" hreflang="x-default" href="${xmlEscape(SITE_ORIGIN + builder(DEFAULT_LOCALE))}"/>`,
  )
  const loc = SITE_ORIGIN + builder(DEFAULT_LOCALE)
  const lastmod = extra.lastmod ? `\n    <lastmod>${xmlEscape(extra.lastmod)}</lastmod>` : ''
  const changefreq = extra.changefreq ? `\n    <changefreq>${extra.changefreq}</changefreq>` : ''
  const priority = extra.priority != null ? `\n    <priority>${extra.priority.toFixed(1)}</priority>` : ''
  return `  <url>
    <loc>${xmlEscape(loc)}</loc>${lastmod}${changefreq}${priority}
${alts.join('\n')}
  </url>`
}

export function urlsetXml(urls: string[]): string {
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
${urls.join('\n')}
</urlset>
`
}

export function sitemapIndexXml(sitemaps: { loc: string; lastmod?: string }[]): string {
  const items = sitemaps
    .map(
      (s) =>
        `  <sitemap>\n    <loc>${xmlEscape(s.loc)}</loc>${s.lastmod ? `\n    <lastmod>${xmlEscape(s.lastmod)}</lastmod>` : ''}\n  </sitemap>`,
    )
    .join('\n')
  return `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${items}
</sitemapindex>
`
}
