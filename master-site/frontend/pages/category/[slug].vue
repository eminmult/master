<template>
  <div class="hm-page hm-masters-page">
    <div class="hm-page-inner">
      <section class="hm-main-col" style="width:100%;">
        <div class="hm-main-head">
          <div>
            <h1 class="hm-page-title">{{ category?.name || slug }}</h1>
            <p class="hm-page-sub">{{ $t('masters.found_n', { n: masters.length }) }}</p>
            <p v-if="category?.description" class="hm-page-desc">{{ category.description }}</p>
          </div>
        </div>

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

        <!-- AI-generated long-form SEO content. Renders nothing until P3.4
             populates category_contents. -->
        <article v-if="content" class="hm-cat-content">
          <section v-if="content.intro" class="hm-cat-block">
            <p v-for="(p, i) in content.intro.split(/\n+/)" :key="i">{{ p }}</p>
          </section>
          <section v-if="content.what_included?.length" class="hm-cat-block">
            <h2>{{ $t('catpage.what_included') }}</h2>
            <ul><li v-for="(it, i) in content.what_included" :key="i">{{ it }}</li></ul>
          </section>
          <section v-if="content.pricing" class="hm-cat-block">
            <h2>{{ $t('catpage.pricing') }}</h2>
            <p>{{ content.pricing }}</p>
          </section>
          <section v-if="content.when_needed?.length" class="hm-cat-block">
            <h2>{{ $t('catpage.when_needed') }}</h2>
            <ul><li v-for="(it, i) in content.when_needed" :key="i">{{ it }}</li></ul>
          </section>
          <section v-if="content.how_to_choose?.length" class="hm-cat-block">
            <h2>{{ $t('catpage.how_to_choose') }}</h2>
            <ol><li v-for="(it, i) in content.how_to_choose" :key="i">{{ it }}</li></ol>
          </section>
          <section v-if="content.faqs?.length" class="hm-cat-block hm-cat-faq">
            <h2>{{ $t('catpage.faq') }}</h2>
            <details v-for="(qa, i) in content.faqs" :key="i">
              <summary>{{ qa.q }}</summary>
              <p>{{ qa.a }}</p>
            </details>
          </section>
        </article>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const route = useRoute()

const slug = computed(() => String(route.params.slug || ''))

const { data: payload, pending: loading } = await useAsyncData(
  () => `category-${slug.value}`,
  async () => {
    try {
      const [catRes, mastersRes] = await Promise.all([
        apiFetch<{ category: any }>(`/categories/${slug.value}`),
        apiFetch<{ masters: any[] }>(`/masters?category_slug=${encodeURIComponent(slug.value)}`),
      ])
      return { category: catRes.category, masters: mastersRes.masters || [] }
    } catch { return null }
  },
  { default: () => null, watch: [slug] },
)

const category = computed(() => payload.value?.category || null)
const masters = computed(() => payload.value?.masters || [])
const content = computed(() => category.value?.content || null)

useSeoHead(() => {
  const c = category.value
  const count = masters.value.length
  const rating = masters.value.length
    ? (masters.value.reduce((s, m) => s + Number(m.rating_avg || 0), 0) / masters.value.length).toFixed(1)
    : '4.8'
  // Build per-locale hreflang paths from category.slug_translations so each
  // language gets its own localized slug in the alternate URLs.
  const hreflangPaths: Record<string, string> = {}
  if (c?.slug_translations) {
    for (const l of ['az', 'ru', 'en', 'tr', 'ar']) {
      const slugForLocale = c.slug_translations[l] || c.slug_az || c.slug
      hreflangPaths[l] = `/category/${slugForLocale}`
    }
  }
  return {
    title: c ? $t('seo.category_title', { name: c.name, n: count, rating }) : $t('seo.categories_title'),
    description: c
      ? (c.description ? c.description + ' · ' + $t('seo.category_desc', { name: c.name, n: count, rating }) : $t('seo.category_desc', { name: c.name, n: count, rating }))
      : $t('seo.categories_desc'),
    canonicalPath: `/category/${slug.value}`,
    hreflangPaths,
  }
})

// JSON-LD: Service + ItemList of providers. FAQPage will be appended once
// Phase 3 AI-generated FAQs land in category_contents.
useHead(() => {
  const c = category.value
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
      aggregateRating:
        m.rating_count > 0
          ? {
              '@type': 'AggregateRating',
              ratingValue: Number(m.rating_avg || 0),
              ratingCount: m.rating_count,
              bestRating: 5,
              worstRating: 1,
            }
          : undefined,
    },
  }))
  const serviceSchema = {
    '@context': 'https://schema.org',
    '@type': 'Service',
    name: c.name,
    description: c.description || undefined,
    serviceType: c.name,
    areaServed: { '@type': 'Country', name: 'Azerbaijan' },
    provider: { '@type': 'Organization', name: 'itez.app', url: SITE },
    url: `${SITE}/category/${c.slug}`,
  }
  const itemListSchema = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    itemListElement: list,
    numberOfItems: masters.value.length,
  }
  // FAQPage schema only when AI-generated faqs are present.
  const faqs = content.value?.faqs as { q: string; a: string }[] | undefined
  const faqSchema = faqs?.length
    ? {
        '@context': 'https://schema.org',
        '@type': 'FAQPage',
        mainEntity: faqs.map((qa) => ({
          '@type': 'Question',
          name: qa.q,
          acceptedAnswer: { '@type': 'Answer', text: qa.a },
        })),
      }
    : null
  const scripts: any[] = [
    { type: 'application/ld+json', innerHTML: JSON.stringify(serviceSchema), key: 'jsonld-service' },
    { type: 'application/ld+json', innerHTML: JSON.stringify(itemListSchema), key: 'jsonld-itemlist' },
  ]
  if (faqSchema) {
    scripts.push({ type: 'application/ld+json', innerHTML: JSON.stringify(faqSchema), key: 'jsonld-faq' })
  }
  return { script: scripts }
})

const breadcrumbs = useBreadcrumbs()
watchEffect(() => {
  if (!category.value) { breadcrumbs.set(null); return }
  breadcrumbs.set([
    { label: $t('nav.categories'), to: localePath('/categories') },
    { label: category.value.name },
  ])
})
onBeforeUnmount(() => breadcrumbs.set(null))
</script>

<style scoped>
.hm-page-desc { margin-top: 8px; color: var(--hm-text-2); max-width: 800px; }
.hm-cat-content {
  max-width: 820px;
  margin: 60px auto 40px;
  display: grid;
  gap: 40px;
  line-height: 1.65;
  color: var(--hm-text);
}
.hm-cat-block h2 {
  font-size: 22px;
  font-weight: 700;
  margin: 0 0 14px;
  letter-spacing: -0.01em;
}
.hm-cat-block p { margin: 0 0 12px; }
.hm-cat-block ul, .hm-cat-block ol { margin: 0; padding-left: 22px; }
.hm-cat-block ul li, .hm-cat-block ol li { margin-bottom: 8px; }
.hm-cat-faq details {
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  padding: 14px 18px;
  margin-bottom: 10px;
  background: var(--hm-bg-card);
}
.hm-cat-faq summary {
  cursor: pointer;
  font-weight: 600;
  list-style: none;
}
.hm-cat-faq summary::-webkit-details-marker { display: none; }
.hm-cat-faq summary::after { content: '+'; float: inline-end; color: var(--hm-text-3); }
.hm-cat-faq details[open] summary::after { content: '−'; }
.hm-cat-faq details p { margin-top: 10px; color: var(--hm-text-2); }
</style>
