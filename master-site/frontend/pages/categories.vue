<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-page-header">
        <h1 class="hm-page-title">{{ $t('categories.page_title') }}</h1>
        <p class="hm-page-sub">{{ $t('categories.page_subtitle') }}</p>
      </div>

      <div class="hm-services-grid">
        <NuxtLink
          v-for="(cat, i) in categories"
          :key="cat.id"
          :to="localePath('/category/' + (cat.slug || cat.id))"
          class="hm-svc-card"
        >
          <span v-if="i < 2" class="hm-svc-popular">★ {{ $t('popular.popular_tag') }}</span>
          <div class="hm-svc-icon"><CatIcon :icon="cat.icon_url" fallback="category" /></div>
          <h3>{{ cat.name }}</h3>
          <p>{{ cat.description || '' }}</p>
          <div v-if="cat.subcategories?.length" class="hm-sub-tags">
            <span v-for="sub in cat.subcategories.slice(0, 3)" :key="sub.id" class="hm-tag">{{ sub.name }}</span>
          </div>
          <span class="hm-svc-book">{{ $t('popular.book_now') }} <span>→</span></span>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
useSeoHead({
  title: $t('seo.categories_title'),
  description: $t('seo.categories_desc'),
  canonicalPath: '/categories',
})
const localePath = useLocalePath()
const { apiFetch } = useApi()

const { data: categories } = await useAsyncData('categories-page', async () => {
  try {
    const res = await apiFetch<{ categories: any[] }>('/categories?include_subcategories=1&only_with_masters=1')
    return res.categories || []
  } catch {
    return []
  }
}, { default: () => [] })
</script>
