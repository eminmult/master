<template>
  <div class="hm-page hm-static">
    <div class="hm-page-inner">
      <div class="hm-page-header" style="text-align:center">
        <h1 class="hm-page-title">{{ $t('steps.title') }}</h1>
        <p class="hm-page-sub" style="margin:16px auto 0;max-width:640px">{{ $t('steps.subtitle') }}</p>
      </div>

      <div class="hm-how-grid">
        <div v-for="(step, i) in steps" :key="i" class="hm-how-item">
          <div class="hm-how-num">{{ i + 1 }}</div>
          <h3>{{ step.title }}</h3>
          <p>{{ step.desc }}</p>
        </div>
      </div>

      <div style="text-align:center;margin-top:48px">
        <NuxtLink :to="localePath('/register')" class="hm-btn hm-btn-primary hm-btn-lg">
          {{ $t('cta.start_now') }} →
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })
const { t: $t } = useI18n()
useSeoHead({ title: $t('seo.how_title'), canonicalPath: '/how-it-works' })
const localePath = useLocalePath()
const steps = computed(() => [
  { title: $t('how.step1_title'), desc: $t('how.step1_long') },
  { title: $t('how.step2_title'), desc: $t('how.step2_long') },
  { title: $t('how.step3_title'), desc: $t('how.step3_long') },
  { title: $t('how.step4_title'), desc: $t('how.step4_long') },
])
</script>
