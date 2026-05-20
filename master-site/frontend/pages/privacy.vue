<template>
  <div class="hm-page hm-static">
    <div class="hm-page-inner hm-static-content">
      <h1 class="hm-page-title">{{ $t('privacy.title') }}</h1>
      <p style="color:var(--hm-text-3)">{{ $t('privacy.updated') }}: {{ formatDate(new Date()) }}</p>
      <h2>{{ $t('privacy.s1_title') }}</h2><p>{{ $t('privacy.s1_text') }}</p>
      <h2>{{ $t('privacy.s2_title') }}</h2><p>{{ $t('privacy.s2_text') }}</p>
      <h2>{{ $t('privacy.s3_title') }}</h2><p>{{ $t('privacy.s3_text') }}</p>
      <h2>{{ $t('privacy.s4_title') }}</h2><p>{{ $t('privacy.s4_text') }}</p>
      <h2>{{ $t('privacy.s5_title') }}</h2><p>{{ $t('privacy.s5_text') }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })
const { t: $t } = useI18n()
useSeoHead({ title: $t('seo.privacy_title'), canonicalPath: '/privacy' })
const { formatDate } = useFormatDate()
</script>
