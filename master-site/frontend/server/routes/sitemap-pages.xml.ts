import { renderUrl, urlsetXml } from '~~/server/utils/seo'

// Static pages exposed to crawlers. Auth/admin/order routes are excluded
// (also covered by Disallow in robots.txt as defense in depth).
const STATIC_PATHS: { path: string; priority?: number; changefreq?: any }[] = [
  { path: '/', priority: 1.0, changefreq: 'daily' },
  { path: '/masters', priority: 0.9, changefreq: 'daily' },
  { path: '/categories', priority: 0.9, changefreq: 'weekly' },
  { path: '/orders', priority: 0.7, changefreq: 'daily' }, // public order board
  { path: '/how-it-works', priority: 0.5, changefreq: 'monthly' },
  { path: '/about', priority: 0.4, changefreq: 'monthly' },
  { path: '/faq', priority: 0.6, changefreq: 'monthly' },
  { path: '/privacy', priority: 0.2, changefreq: 'yearly' },
  { path: '/terms', priority: 0.2, changefreq: 'yearly' },
  { path: '/login', priority: 0.3, changefreq: 'yearly' },
  { path: '/register', priority: 0.4, changefreq: 'yearly' },
  { path: '/register/master', priority: 0.5, changefreq: 'yearly' },
]

export default defineEventHandler((event) => {
  setHeader(event, 'content-type', 'application/xml; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=900, s-maxage=900')
  const urls = STATIC_PATHS.map((p) =>
    renderUrl(() => p.path, { priority: p.priority, changefreq: p.changefreq }),
  )
  return urlsetXml(urls)
})
