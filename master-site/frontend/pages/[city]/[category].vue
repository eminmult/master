<template>
  <div class="hm-page hm-masters-page">
    <div class="hm-page-inner">
      <section class="hm-main-col" style="width:100%;">
        <div class="hm-main-head">
          <div>
            <h1 class="hm-page-title">{{ heading }}</h1>
            <p class="hm-page-sub">{{ $t('masters.found_n', { n: masters.length }) }}</p>
            <p v-if="category?.description" class="hm-page-desc">{{ category.description }}</p>
          </div>
        </div>

        <!-- Same content shape as /category, rendered when city-specific or
             generic category content is available. -->
        <article v-if="content" class="hm-cat-content">
          <section v-if="content.intro" class="hm-cat-block">
            <p v-for="(p, i) in (content.intro.split(/\n+/))" :key="i">{{ p }}</p>
          </section>
          <section v-if="content.pricing" class="hm-cat-block">
            <h2>{{ $t('catpage.pricing') }}</h2>
            <p>{{ content.pricing }}</p>
          </section>
          <section v-if="content.faqs?.length" class="hm-cat-block hm-cat-faq">
            <h2>{{ $t('catpage.faq') }}</h2>
            <details v-for="(qa, i) in content.faqs" :key="i">
              <summary>{{ qa.q }}</summary>
              <p>{{ qa.a }}</p>
            </details>
          </section>
        </article>

        <div v-if="loading && !masters.length" class="hm-loading">{{ $t('common.loading') }}</div>
        <div v-else-if="masters.length === 0" class="hm-empty">{{ $t('masters.no_results') }}</div>

        <div v-else class="hm-masters-grid">
          <NuxtLink
            v-for="m in masters"
            :key="m.id"
            :to="localePath('/master/' + (m.slug || m.id))"
            class="hm-spec-card"
          >
            <div class="hm-spec-photo" :style="m.avatar_url ? { backgroundImage: `url(${m.avatar_url})` } : {}">
              <div v-if="m.is_online" class="hm-spec-avail">{{ $t('masters.online') }}</div>
              <div v-if="m.rating_avg" class="hm-spec-rating">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="var(--hm-accent)"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
                {{ m.rating_avg }}
              </div>
            </div>
            <h3>{{ m.first_name }} {{ m.last_name }}</h3>
            <p class="hm-spec-sub">{{ m.description }}</p>
            <div class="hm-spec-foot">
              <div>
                <div class="hm-spec-rev">{{ m.rating_count || 0 }} {{ $t('masters.reviews') }}</div>
                <div class="hm-spec-city">{{ m.city }}{{ m.district ? ', ' + m.district : '' }}</div>
              </div>
            </div>
          </NuxtLink>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'hm',
  // Block random 2-segment URLs by validating against the known city/category
  // sets. Invalid combos fall through to a 404 instead of rendering an empty
  // listing that would otherwise be indexed.
  async validate(route) {
    const city = String(route.params.city || '')
    const category = String(route.params.category || '')
    if (!city || !category) return false
    // Avoid clashing with reserved top-level paths.
    const reserved = ['admin', 'api', 'master', 'masters', 'category', 'categories', 'order', 'orders', 'client', 'register', 'login', 'about', 'faq', 'privacy', 'terms', 'how-it-works', 'verify-email', 'verify-phone', 'forgot-password', 'reset-password', 'payment-methods']
    if (reserved.includes(city)) return false
    try {
      const config = useRuntimeConfig()
      const base = import.meta.server
        ? (process.env.API_INTERNAL_URL || 'http://master-api:8000/api')
        : (config.public.apiBase as string)
      const [cities, cats] = await Promise.all([
        $fetch<{ cities: { slug: string }[] }>(`${base}/cities`),
        $fetch<{ categories: { slug: string }[] }>(`${base}/categories`),
      ])
      const cityOk = (cities.cities || []).some((c) => c.slug === city)
      const catOk = (cats.categories || []).some((c) => c.slug === category)
      return cityOk && catOk
    } catch { return false }
  },
})

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const route = useRoute()

const citySlug = computed(() => String(route.params.city || ''))
const categorySlug = computed(() => String(route.params.category || ''))

const { data: payload, pending: loading } = await useAsyncData(
  () => `citycat-${citySlug.value}-${categorySlug.value}`,
  async () => {
    try {
      const [catRes, cityRes, mastersRes, ccRes] = await Promise.all([
        apiFetch<{ category: any }>(`/categories/${categorySlug.value}`),
        apiFetch<{ cities: { name: string; slug: string }[] }>('/cities'),
        apiFetch<{ masters: any[] }>(
          `/masters?category_slug=${encodeURIComponent(categorySlug.value)}&city_slug=${encodeURIComponent(citySlug.value)}`,
        ),
        apiFetch<{ content: any }>(
          `/cities/${encodeURIComponent(citySlug.value)}/categories/${encodeURIComponent(categorySlug.value)}/content`,
        ).catch(() => ({ content: null })),
      ])
      const cityName = (cityRes.cities || []).find((c) => c.slug === citySlug.value)?.name || citySlug.value
      return {
        category: catRes.category,
        cityName,
        masters: mastersRes.masters || [],
        content: ccRes.content || null,
      }
    } catch { return null }
  },
  { default: () => null, watch: [citySlug, categorySlug] },
)

const category = computed(() => payload.value?.category || null)
const masters = computed(() => payload.value?.masters || [])
const content = computed(() => payload.value?.content || null)
const heading = computed(() => {
  const cn = category.value?.name || categorySlug.value
  const city = payload.value?.cityName || citySlug.value
  return `${cn} — ${city}`
})

useSeoHead(() => {
  const c = category.value
  const cityName = payload.value?.cityName || citySlug.value
  // Single canonical /{city}/{category} URL for every locale.
  // (useSeoHead defaults all locale alternates to the same canonical path.)
  const hreflangPaths: Record<string, string> = {}
  // Canonical-slug redirect if a stale locale-specific slug was linked.
  if (c && c.slug && c.slug !== categorySlug.value) {
    void navigateTo(localePath(`/${citySlug.value}/${c.slug}`), { redirectCode: 301 })
  }
  return {
    title: c ? $t('seo.citycat_title', { category: c.name, city: cityName }) : '',
    description: c ? $t('seo.citycat_desc', { category: c.name, city: cityName }) : '',
    canonicalPath: `/${citySlug.value}/${categorySlug.value}`,
    hreflangPaths,
  }
})

// JSON-LD: Service narrowed to a City via areaServed + LocalBusiness scope.
// This is the primary local-SEO surface (city + category) so the schema needs
// to make the geo intent unambiguous for Google.
useHead(() => {
  const c = category.value
  const cityName = payload.value?.cityName || citySlug.value
  if (!c) return {}
  const SITE = 'https://itez.app'
  const list = masters.value.slice(0, 20).map((m, i) => ({
    '@type': 'ListItem',
    position: i + 1,
    item: {
      '@type': 'Person',
      name: `${m.first_name} ${m.last_name}`,
      url: `${SITE}/master/${m.slug}`,
      image: m.avatar_url || undefined,
    },
  }))
  const serviceSchema = {
    '@context': 'https://schema.org',
    '@type': 'Service',
    name: `${c.name} — ${cityName}`,
    description: c.description || undefined,
    serviceType: c.name,
    areaServed: {
      '@type': 'City',
      name: cityName,
      address: { '@type': 'PostalAddress', addressLocality: cityName, addressCountry: 'AZ' },
    },
    provider: { '@type': 'Organization', name: 'itez.app', url: SITE },
    url: `${SITE}/${citySlug.value}/${c.slug}`,
  }
  const itemListSchema = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    itemListElement: list,
    numberOfItems: masters.value.length,
  }
  return {
    script: [
      { type: 'application/ld+json', innerHTML: JSON.stringify(serviceSchema), key: 'jsonld-citycat-service' },
      { type: 'application/ld+json', innerHTML: JSON.stringify(itemListSchema), key: 'jsonld-citycat-itemlist' },
    ],
  }
})

const breadcrumbs = useBreadcrumbs()
watchEffect(() => {
  const p = payload.value
  if (!p) { breadcrumbs.set(null); return }
  breadcrumbs.set([
    { label: $t('nav.categories'), to: localePath('/categories') },
    { label: p.category?.name || categorySlug.value, to: localePath('/category/' + categorySlug.value) },
    { label: p.cityName || citySlug.value },
  ])
})
onBeforeUnmount(() => breadcrumbs.set(null))
</script>

<style scoped>
.hm-page-desc { margin-top: 8px; color: var(--hm-text-2); max-width: 800px; }
.hm-cat-content {
  max-width: 820px;
  margin: 40px auto;
  display: grid;
  gap: 32px;
  line-height: 1.65;
  color: var(--hm-text);
}
.hm-cat-block h2 { font-size: 22px; font-weight: 700; margin: 0 0 14px; letter-spacing: -0.01em; }
.hm-cat-block p { margin: 0 0 12px; }
.hm-cat-faq details {
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  padding: 14px 18px;
  margin-bottom: 10px;
  background: var(--hm-bg-card);
}
.hm-cat-faq summary { cursor: pointer; font-weight: 600; list-style: none; }
.hm-cat-faq summary::-webkit-details-marker { display: none; }
.hm-cat-faq summary::after { content: '+'; float: inline-end; color: var(--hm-text-3); }
.hm-cat-faq details[open] summary::after { content: '−'; }
.hm-cat-faq details p { margin-top: 10px; color: var(--hm-text-2); }
</style>
