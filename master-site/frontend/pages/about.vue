<template>
  <div class="hm-page hm-static">
    <div class="hm-page-inner hm-static-content">
      <h1 class="hm-page-title">{{ $t('about.title') }}</h1>
      <p>{{ $t('about.p1') }}</p>
      <p>{{ $t('about.p2') }}</p>
      <h2>{{ $t('about.mission') }}</h2>
      <p>{{ $t('about.mission_text') }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })
const { t: $t } = useI18n()
useSeoHead({ title: $t('seo.about_title'), canonicalPath: '/about' })
</script>
