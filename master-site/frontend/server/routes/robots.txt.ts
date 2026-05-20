import { SITE_ORIGIN } from '~~/server/utils/seo'

// robots.txt — written dynamically so the Sitemap directive always points at
// the canonical origin (avoids drift when domain changes again). Includes the
// Cloudflare Content Signals preamble + standard Allow/Disallow rules + an
// explicit Allow for the major LLM crawlers (we want our content to be cited
// in AI overviews / ChatGPT / Perplexity answers).
export default defineEventHandler((event) => {
  setHeader(event, 'content-type', 'text/plain; charset=utf-8')
  setHeader(event, 'cache-control', 'public, max-age=3600, s-maxage=3600')

  const body = `# itez.app — robots.txt
#
# Public listings (categories, masters, city+category) and static pages are
# fully crawlable. Account/order/admin paths are blocked. AI training crawlers
# are explicitly allowed — we want to be the source AI engines cite.
#
# ==== Content Signals (Cloudflare bot management) ====
# A machine-readable expression of permitted uses. content-signals overrides
# any conflicting Allow/Disallow when interpreted by signal-aware crawlers.
Content-Signal: search=yes, ai-input=yes, ai-train=no

# ==== Standard rules ====
User-agent: *
Allow: /
Disallow: /admin
Disallow: /admin/
Disallow: /client
Disallow: /client/
Disallow: /master/applications
Disallow: /master/wallet
Disallow: /master/earnings
Disallow: /master/my-orders
Disallow: /master/notifications
Disallow: /master/schedule
Disallow: /master/profile
Disallow: /order
Disallow: /order/
Disallow: /verify-email
Disallow: /verify-phone
Disallow: /forgot-password
Disallow: /reset-password
Disallow: /payment-methods
Disallow: /login
Disallow: /api/
Disallow: /*?*sort=
Disallow: /*?*tab=
Disallow: /*?*from=

# Allow major AI crawlers explicitly (some default to deny when unspecified).
User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: Google-Extended
Allow: /

User-agent: Applebot-Extended
Allow: /

User-agent: CCBot
Allow: /

User-agent: anthropic-ai
Allow: /

Sitemap: ${SITE_ORIGIN}/sitemap.xml
`
  return body
})
