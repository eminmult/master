<template>
  <article v-if="post" class="hm-page blog-post">
    <div class="hm-page-inner">
      <header class="blog-post-head">
        <time>{{ formatDate(post.published_at) }}</time>
        <h1>{{ post.title }}</h1>
        <p v-if="post.excerpt" class="lead">{{ post.excerpt }}</p>
        <div v-if="post.author" class="byline">
          <span>{{ post.author.first_name }} {{ post.author.last_name }}</span>
        </div>
      </header>
      <div v-if="post.hero_url" class="blog-post-hero">
        <img :src="post.hero_url" :alt="post.title" loading="lazy" />
      </div>
      <div class="blog-post-body" v-html="bodyHtml" />
    </div>
  </article>
  <div v-else class="hm-loading">404</div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const { formatDate } = useFormatDate()
const route = useRoute()

const slug = computed(() => String(route.params.slug || ''))

const { data: post } = await useAsyncData(
  () => `blog-${slug.value}`,
  async () => {
    try {
      const r = await apiFetch<{ post: any }>(`/posts/${slug.value}`)
      return r.post
    } catch { return null }
  },
  { default: () => null, watch: [slug] },
)

// Canonical-slug redirect: each locale has its own slug; if the URL was
// reached with a different locale's slug (e.g. user pasted /en/blog/<RU-slug>)
// hop to the localized one. 301 keeps search engines happy.
if (post.value?.slug && post.value.slug !== slug.value) {
  await navigateTo(localePath('/blog/' + post.value.slug), { redirectCode: 301 })
}

// Minimal Markdown → HTML. Blog posts are admin-only so we don't sanitise
// (admins can already deploy code). For untrusted authors swap in DOMPurify.
const bodyHtml = computed(() => {
  const md = post.value?.body_md || ''
  return md
    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" rel="noopener">$1</a>')
    .replace(/\n\n+/g, '</p><p>')
    .replace(/^/, '<p>')
    .replace(/$/, '</p>')
})

useSeoHead(() => {
  const p = post.value
  // Each locale has its own slug — feed the per-locale path map into the
  // header language switcher and hreflang alternates.
  const hreflangPaths: Record<string, string> = {}
  if (p?.slug_translations) {
    for (const [l, s] of Object.entries(p.slug_translations as Record<string, string>)) {
      hreflangPaths[l] = `/blog/${s}`
    }
  }
  return {
    title: p?.title || $t('blog.title'),
    description: p?.excerpt || undefined,
    canonicalPath: `/blog/${p?.slug || slug.value}`,
    hreflangPaths,
    image: p?.hero_url,
    ogType: 'article',
  }
})

// Article JSON-LD for rich result eligibility.
useHead(() => {
  const p = post.value
  if (!p) return {}
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: p.title,
    description: p.excerpt,
    image: p.hero_url,
    datePublished: p.published_at,
    dateModified: p.updated_at || p.published_at,
    author: p.author
      ? { '@type': 'Person', name: `${p.author.first_name} ${p.author.last_name}` }
      : undefined,
    publisher: {
      '@type': 'Organization',
      name: 'itez.app',
      logo: { '@type': 'ImageObject', url: 'https://itez.app/favicon.svg' },
    },
    mainEntityOfPage: `https://itez.app/blog/${p.slug}`,
  }
  return {
    script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(schema), key: 'jsonld-article' }],
  }
})

const breadcrumbs = useBreadcrumbs()
watchEffect(() => {
  const p = post.value
  if (!p) { breadcrumbs.set(null); return }
  breadcrumbs.set([
    { label: $t('blog.title'), to: localePath('/blog') },
    { label: p.title },
  ])
})
onBeforeUnmount(() => breadcrumbs.set(null))
</script>

<style scoped>
.blog-post { max-width: 760px; margin: 0 auto; padding: 32px 20px; }
.blog-post-head time { font-size: 13px; color: var(--hm-text-3); }
.blog-post-head h1 { font-size: 36px; font-weight: 700; letter-spacing: -0.5px; margin: 6px 0 12px; line-height: 1.2; }
.blog-post-head .lead { font-size: 18px; color: var(--hm-text-2); line-height: 1.5; margin: 0 0 16px; }
.blog-post-head .byline { font-size: 14px; color: var(--hm-text-3); margin-bottom: 16px; }
.blog-post-hero { margin: 24px 0; }
.blog-post-hero img { width: 100%; border-radius: 16px; display: block; }
.blog-post-body { font-size: 17px; line-height: 1.7; }
.blog-post-body :deep(h2) { font-size: 26px; margin: 32px 0 12px; font-weight: 700; }
.blog-post-body :deep(h3) { font-size: 20px; margin: 24px 0 10px; font-weight: 600; }
.blog-post-body :deep(p) { margin: 0 0 16px; }
.blog-post-body :deep(a) { color: var(--hm-accent); }
html.theme-light .blog-post-body :deep(a) { color: #b07f00; }
</style>
