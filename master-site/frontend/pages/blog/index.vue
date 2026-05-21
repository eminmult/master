<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <header class="blog-head">
        <h1>{{ $t('blog.title') }}</h1>
        <p>{{ $t('blog.subtitle') }}</p>
      </header>

      <div v-if="!posts.length" class="hm-empty">{{ $t('blog.empty') }}</div>

      <div v-else class="blog-grid">
        <NuxtLink
          v-for="p in posts"
          :key="p.id"
          :to="localePath(`/blog/${p.slug}`)"
          class="blog-card"
        >
          <div
            v-if="p.hero_url"
            class="blog-card-hero"
            :style="{ backgroundImage: `url(${p.hero_url})` }"
          />
          <div class="blog-card-body">
            <time>{{ formatDate(p.published_at) }}</time>
            <h2>{{ p.title }}</h2>
            <p v-if="p.excerpt">{{ p.excerpt }}</p>
          </div>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const { formatDate } = useFormatDate()

useSeoHead({
  title: $t('blog.seo_title'),
  description: $t('blog.seo_desc'),
  canonicalPath: '/blog',
})

const { data: posts } = await useAsyncData('blog-index', async () => {
  try {
    const r = await apiFetch<{ posts: any[] }>('/posts')
    return r.posts || []
  } catch { return [] }
}, { default: () => [] })

const breadcrumbs = useBreadcrumbs()
breadcrumbs.set([{ label: $t('blog.title') }])
onBeforeUnmount(() => breadcrumbs.set(null))
</script>

<style scoped>
.blog-head { max-width: 800px; margin: 32px auto 24px; padding: 0 20px; text-align: center; }
.blog-head h1 { font-size: 36px; font-weight: 700; letter-spacing: -0.5px; margin: 0 0 8px; }
.blog-head p { color: var(--hm-text-2); margin: 0; }
.blog-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 24px; padding: 24px; max-width: 1200px; margin: 0 auto; }
.blog-card { display: block; border-radius: 16px; overflow: hidden; background: var(--hm-bg-card); border: 1px solid var(--hm-border); transition: transform 160ms, border-color 160ms; text-decoration: none; color: inherit; }
.blog-card:hover { transform: translateY(-2px); border-color: var(--hm-accent); }
.blog-card-hero { height: 200px; background: var(--hm-bg-3) center / cover; }
.blog-card-body { padding: 18px 20px 22px; }
.blog-card-body time { font-size: 12px; color: var(--hm-text-3); }
.blog-card-body h2 { font-size: 18px; font-weight: 700; margin: 6px 0 8px; line-height: 1.3; }
.blog-card-body p { color: var(--hm-text-2); font-size: 14px; line-height: 1.5; margin: 0; }
</style>
