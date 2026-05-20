<template>
  <div class="hm-page hm-static">
    <div class="hm-page-inner hm-static-content">
      <h1 class="hm-page-title">{{ $t('faq.title') }}</h1>
      <div class="hm-faq-list">
        <div v-for="(item, i) in faqItems" :key="i" class="hm-faq-item" @click="toggle(i)">
          <div class="hm-faq-q">
            <span>{{ item.q }}</span>
            <span class="hm-faq-arrow" :class="{ open: openIndex === i }">▼</span>
          </div>
          <div v-if="openIndex === i" class="hm-faq-a">{{ item.a }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })
const { t: $t } = useI18n()
useSeoHead({ title: $t('seo.faq_title'), canonicalPath: '/faq' })
const openIndex = ref<number | null>(null)
function toggle(i: number) { openIndex.value = openIndex.value === i ? null : i }
const faqItems = computed(() => [
  { q: $t('faq.q1'), a: $t('faq.a1') },
  { q: $t('faq.q2'), a: $t('faq.a2') },
  { q: $t('faq.q3'), a: $t('faq.a3') },
  { q: $t('faq.q4'), a: $t('faq.a4') },
  { q: $t('faq.q5'), a: $t('faq.a5') },
  { q: $t('faq.q6'), a: $t('faq.a6') },
])
</script>
