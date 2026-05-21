import { SITE_ORIGIN, sitemapIndexXml } from '~~/server/utils/seo'

// Sitemap index — points to per-section sitemap files. Crawlers (Google,
// Bing, Yandex) fetch the index first, then each section in parallel.
export default defineEventHandler((event) => {
  setHeader(event, 'content-type', 'application/xml; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=900, s-maxage=900')
  const now = new Date().toISOString()
  return sitemapIndexXml([
    { loc: `${SITE_ORIGIN}/sitemap-pages.xml`, lastmod: now },
    { loc: `${SITE_ORIGIN}/sitemap-categories.xml`, lastmod: now },
    { loc: `${SITE_ORIGIN}/sitemap-masters.xml`, lastmod: now },
    { loc: `${SITE_ORIGIN}/sitemap-citycat.xml`, lastmod: now },
    { loc: `${SITE_ORIGIN}/sitemap-blog.xml`, lastmod: now },
  ])
})
