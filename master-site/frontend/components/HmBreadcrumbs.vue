<template>
  <nav v-if="items.length > 1" class="hm-breadcrumbs" :aria-label="$t('nav.breadcrumb_label') || 'Breadcrumbs'">
    <ol class="hm-breadcrumbs-list">
      <li v-for="(item, idx) in items" :key="idx" class="hm-breadcrumbs-item">
        <NuxtLink v-if="item.to && idx < items.length - 1" :to="item.to" class="hm-breadcrumbs-link">{{ item.label }}</NuxtLink>
        <span v-else class="hm-breadcrumbs-current">{{ item.label }}</span>
        <span v-if="idx < items.length - 1" class="hm-breadcrumbs-sep" aria-hidden="true">/</span>
      </li>
    </ol>
  </nav>
</template>

<script setup lang="ts">
import type { BreadcrumbItem } from '~/composables/useBreadcrumbs'

const { t: $t, locale } = useI18n()
const localePath = useLocalePath()
const route = useRoute()
const { trail } = useBreadcrumbs()
const { apiFetch } = useApi()

// Static label map for routes without a setBreadcrumbs() call. Keys are the
// route name without locale prefix (e.g., "masters", "category-slug").
const FALLBACK_LABELS: Record<string, string> = {
  masters: 'nav.masters',
  categories: 'nav.categories',
  about: 'nav.about',
  faq: 'nav.faq',
  'how-it-works': 'nav.how_it_works',
  privacy: 'nav.privacy',
  terms: 'nav.terms',
  login: 'nav.login',
  'register': 'nav.register',
  'register-master': 'nav.register_master',
  'forgot-password': 'auth.forgot_title',
  'reset-password': 'auth.reset_title',
  'verify-email': 'auth.verify_email_title',
  'verify-phone': 'auth.verify_phone_title',
  'payment-methods': 'nav.payment_methods',
  orders: 'nav.orders',
  'client': 'nav.dashboard',
  'master': 'nav.dashboard',
}

function tr(key: string): string {
  const v = $t(key)
  return v === key ? '' : v
}

// Look up the entity name in the current locale for known dynamic patterns
// so the SSR-rendered breadcrumb already has the translated label
// (page-level setBreadcrumbs runs AFTER layout render and only kicks in on
// the client). Uses useAsyncData so SSR awaits the resolution and cache keys
// the result. Locale + path are both keyed so a language switch refetches.
const strippedPath = computed(
  () => (route.path.replace(/^\/(az|en|ru|tr|ar)(?=\/|$)/, '') || '/'),
)
const segments = computed(() => strippedPath.value.split('/').filter(Boolean))

const { data: dynamicLabel } = await useAsyncData(
  () => `crumb-${locale.value}-${strippedPath.value}`,
  async () => {
    const segs = segments.value
    try {
      // /master/{slug}
      if (segs[0] === 'master' && segs[1] && segs.length === 2) {
        const r: any = await apiFetch(`/users/${segs[1]}/profile`)
        return { dynamic: r?.profile?.full_name }
      }
      // /category/{slug}
      if (segs[0] === 'category' && segs[1] && segs.length === 2) {
        const r: any = await apiFetch(`/categories/${segs[1]}`)
        return { dynamic: r?.category?.name }
      }
      // /blog/{slug}
      if (segs[0] === 'blog' && segs[1] && segs.length === 2) {
        const r: any = await apiFetch(`/posts/${segs[1]}`)
        return { dynamic: r?.post?.title }
      }
      // /{city}/{category} — city slug + category slug
      if (segs.length === 2 && !FALLBACK_LABELS[segs[0]] && !['master', 'category', 'blog'].includes(segs[0])) {
        const [cats, cities] = await Promise.all([
          apiFetch<{ categories: { slug: string; name: string }[] }>('/categories?only_with_masters=1').catch(() => ({ categories: [] })),
          apiFetch<{ cities: { slug: string; name: string }[] }>('/cities').catch(() => ({ cities: [] })),
        ])
        const cat = (cats as any).categories?.find((c: any) => c.slug === segs[1])
        const city = (cities as any).cities?.find((c: any) => c.slug === segs[0])
        if (cat && city) {
          return { city: city.name, citySlug: city.slug, categorySlug: cat.slug, categoryName: cat.name }
        }
      }
    } catch { /* fall through to slug */ }
    return null
  },
  { default: () => null, watch: [locale, strippedPath] },
)

function autoTrail(): { label: string; to?: string }[] {
  const segs = segments.value
  if (!segs.length) return []
  const dyn: any = dynamicLabel.value || null
  const out: { label: string; to?: string }[] = []
  let acc = ''
  // Specialised shapes — emit nicer crumbs than the generic segment-by-segment
  // builder below.
  if (segs[0] === 'master' && segs[1]) {
    out.push({ label: tr('nav.masters') || 'Masters', to: localePath('/masters') })
    out.push({ label: dyn?.dynamic || segs[1] })
    return out
  }
  if (segs[0] === 'category' && segs[1]) {
    out.push({ label: tr('nav.categories') || 'Categories', to: localePath('/categories') })
    out.push({ label: dyn?.dynamic || segs[1] })
    return out
  }
  if (segs[0] === 'blog' && segs[1]) {
    out.push({ label: tr('blog.title') || 'Blog', to: localePath('/blog') })
    out.push({ label: dyn?.dynamic || segs[1] })
    return out
  }
  if (dyn?.city && dyn?.categoryName) {
    out.push({ label: tr('nav.categories') || 'Categories', to: localePath('/categories') })
    out.push({ label: dyn.categoryName, to: localePath('/category/' + dyn.categorySlug) })
    out.push({ label: dyn.city })
    return out
  }
  // Generic fallback — translate via FALLBACK_LABELS or emit the raw slug.
  for (let i = 0; i < segs.length; i++) {
    acc += '/' + segs[i]
    const labelKey = FALLBACK_LABELS[segs[i]]
    const label = labelKey ? tr(labelKey) || segs[i] : segs[i]
    out.push({ label, to: i < segs.length - 1 ? localePath(acc) : undefined })
  }
  return out
}

const items = computed<BreadcrumbItem[]>(() => {
  const explicit = trail.value
  const root: BreadcrumbItem = { label: tr('nav.home') || 'Home', to: localePath('/') }
  const tail = explicit && explicit.length ? explicit : autoTrail()
  return [root, ...tail]
})

// Hardcoded canonical origin so the JSON-LD item URLs are always https://
// (the request URL behind Cloudflare → origin is http://, which would emit
// the wrong protocol in structured data).
const baseOrigin = 'https://itez.app'

const jsonLd = computed(() => ({
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: items.value.map((it, i) => ({
    '@type': 'ListItem',
    position: i + 1,
    name: it.label,
    item: it.to ? `${baseOrigin}${it.to}` : undefined,
  })),
}))

useHead(() => ({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify(jsonLd.value),
    },
  ],
}))
</script>

<style scoped>
.hm-breadcrumbs {
  max-width: 1200px;
  margin: 0 auto;
  padding: 16px clamp(20px, 5vw, 110px) 0;
}
.hm-breadcrumbs-list {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
  font-size: 13px;
  color: var(--hm-text-3);
}
.hm-breadcrumbs-item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.hm-breadcrumbs-link {
  color: var(--hm-text-2);
  text-decoration: none;
  transition: color 160ms;
}
.hm-breadcrumbs-link:hover { color: var(--hm-accent); }
html.theme-light .hm-breadcrumbs-link:hover { color: #b07f00; }
.hm-breadcrumbs-sep {
  color: var(--hm-text-3);
}
.hm-breadcrumbs-current {
  color: var(--hm-text);
  font-weight: 500;
}
</style>
