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

const { t: $t } = useI18n()
const localePath = useLocalePath()
const route = useRoute()
const { trail } = useBreadcrumbs()

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

function autoTrail(): { label: string; to?: string }[] {
  const path = route.path.replace(/^\/(az|en|ru|tr|ar)(?=\/|$)/, '') || '/'
  if (path === '/' || path === '') return []
  const segments = path.split('/').filter(Boolean)
  const out: { label: string; to?: string }[] = []
  let acc = ''
  for (let i = 0; i < segments.length; i++) {
    acc += '/' + segments[i]
    const key = segments[i]
    const labelKey = FALLBACK_LABELS[key]
    const label = labelKey ? tr(labelKey) || key : key
    out.push({ label, to: i < segments.length - 1 ? localePath(acc) : undefined })
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
