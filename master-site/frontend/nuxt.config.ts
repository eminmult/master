export default defineNuxtConfig({
  compatibilityDate: '2025-01-01',
  devtools: { enabled: false },

  modules: [
    '@pinia/nuxt',
    '@nuxtjs/i18n',
  ],

  i18n: {
    locales: [
      { code: 'az', name: 'Azərbaycan', file: 'az.json', dir: 'ltr' },
      { code: 'ru', name: 'Русский', file: 'ru.json', dir: 'ltr' },
      { code: 'en', name: 'English', file: 'en.json', dir: 'ltr' },
      { code: 'tr', name: 'Türkçe', file: 'tr.json', dir: 'ltr' },
      { code: 'ar', name: 'العربية', file: 'ar.json', dir: 'rtl' },
    ],
    defaultLocale: 'az',
    lazy: true,
    bundle: {
      fullInstall: false,
    },
    langDir: '../locales',
    strategy: 'prefix_except_default',
    // Always start in `az`. Browser language is intentionally ignored — once
    // the user picks a language, the choice persists via the `i18n_lang` cookie
    // (set on switch in the language selector).
    detectBrowserLanguage: false,
  },

  css: ['~/assets/css/main.css', '~/assets/css/hm.css'],

  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8093/api',
      wsUrl: process.env.NUXT_PUBLIC_WS_URL || 'ws://localhost:8093',
      googleMapsKey: process.env.NUXT_PUBLIC_GOOGLE_MAPS_KEY || '',
      reverbKey: process.env.NUXT_PUBLIC_REVERB_KEY || '',
      // Realtime (WebSocket) host — DNS-only subdomain that bypasses Cloudflare.
      // CF Flexible SSL silently downgrades WSS → HTTP on the proxied
      // itez.app path, which mixed-content blocks in the browser.
      reverbHost: process.env.NUXT_PUBLIC_REVERB_HOST || 'realtime.itez.app',
      reverbPort: process.env.NUXT_PUBLIC_REVERB_PORT || '443',
      reverbScheme: process.env.NUXT_PUBLIC_REVERB_SCHEME || 'https',
    },
  },

  app: {
    head: {
      title: 'Master - Ev ustası çağır',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Ev ustası çağırmaq üçün ən sürətli platforma' },
        { property: 'og:title', content: 'Master - Ev ustası çağır' },
        { property: 'og:description', content: 'Santexnik, elektrik, qaynaqçı və digər peşəkar ustalar bir kliklə yanınızda.' },
        { property: 'og:type', content: 'website' },
        { property: 'og:url', content: 'https://itez.app' },
        { name: 'twitter:card', content: 'summary' },
      ],
      link: [
        { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
        // DNS warm-up; gstatic crossorigin attr is required for font preflight.
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        // Critical fonts inlined as a single request, font-display:swap so the
        // text paints immediately in a system font then upgrades. Reduces FCP
        // by ~300ms vs the previous 3-request setup.
        {
          rel: 'preload',
          as: 'style',
          href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Space+Grotesk:wght@400;500;600;700&family=Public+Sans:wght@400;500;700;800&display=swap',
        },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Space+Grotesk:wght@400;500;600;700&family=Public+Sans:wght@400;500;700;800&display=swap',
          media: 'print',
          // The `onload` trick swaps media→all once the stylesheet is fetched,
          // making the request non-render-blocking. A <noscript> fallback can
          // be added later if needed for SEO crawlers without JS.
          onload: "this.media='all'",
        },
        // Material Symbols stays render-blocking (display:block) because we
        // use the .icon glyphs above the fold; swapping causes a visual jump.
        // Still single-request and ~250KB cached for 1 year by Google.
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=block',
        },
      ],
    },
  },

  ssr: true,

  // Performance — inline critical CSS into the SSR HTML so first paint
  // doesn't wait for entry.css to download. Cuts ~150-300ms off LCP on slow
  // connections. payloadExtraction is intentionally OFF — it lazy-loads the
  // SSR payload via a JSON request on hydration and was failing in production
  // (the JSON file URL collided with our localized routes and returned 500).
  experimental: {
    inlineRouteRules: true,
    viewTransition: true,
  },

  features: {
    inlineStyles: true,
  },

  // Route-level rules — long-lived caches for static, short for HTML.
  routeRules: {
    '/_nuxt/**': { headers: { 'cache-control': 'public, max-age=31536000, immutable' } },
    '/favicon.svg': { headers: { 'cache-control': 'public, max-age=86400' } },
    '/master-mobile.apk': { headers: { 'cache-control': 'public, max-age=300' } },
    '/sitemap*.xml': { headers: { 'cache-control': 'public, max-age=3600, s-maxage=3600' } },
    '/robots.txt': { headers: { 'cache-control': 'public, max-age=3600' } },
    '/llms*.txt': { headers: { 'cache-control': 'public, max-age=3600' } },
  },
})
