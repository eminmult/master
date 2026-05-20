<template>
  <div class="hm-page hm-static">
    <div class="hm-page-inner hm-static-content">
      <h1 class="hm-page-title">{{ $t('terms.title') }}</h1>
      <p style="color:var(--hm-text-3)">{{ $t('terms.updated') }}: {{ formatDate(new Date()) }}</p>
      <h2>{{ $t('terms.s1_title') }}</h2><p>{{ $t('terms.s1_text') }}</p>
      <h2>{{ $t('terms.s2_title') }}</h2><p>{{ $t('terms.s2_text') }}</p>
      <h2>{{ $t('terms.s3_title') }}</h2><p>{{ $t('terms.s3_text') }}</p>
      <h2>{{ $t('terms.s4_title') }}</h2><p>{{ $t('terms.s4_text') }}</p>
      <h2>{{ $t('terms.s5_title') }}</h2><p>{{ $t('terms.s5_text') }}</p>
      <h2>{{ $t('terms.s6_title') }}</h2><p>{{ $t('terms.s6_text') }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })
const { t: $t } = useI18n()
useSeoHead({ title: $t('seo.terms_title'), canonicalPath: '/terms' })
const { formatDate } = useFormatDate()
</script>
