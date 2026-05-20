<template>
  <footer class="hm-footer">
    <div class="hm-footer-inner">
      <div class="hm-footer-brand">
        <div class="hm-logo">
          <div class="hm-logo-mark">
            <svg width="19" height="22" viewBox="0 0 19 22" aria-hidden="true">
              <path d="M 8.175 16.625 L 12.875 10.9 L 9.125 10.9 L 9.75 5.95 L 5.55 12 L 8.85 12 L 8.175 16.625 M 4.5 21.9 L 5.5 14.9 L 0 14.9 L 10.325 0 L 13.4 0 L 12.4 8 L 19.075 8 L 7.55 21.9 L 4.5 21.9" />
            </svg>
          </div>
          <span>Master</span>
        </div>
        <p>{{ $t('footer.slogan') }}</p>
      </div>
      <div>
        <h4>{{ $t('footer.services') }}</h4>
        <a v-for="cat in categories.slice(0, 4)" :key="cat.id" @click="goCat(cat.id)">{{ cat.name }}</a>
      </div>
      <div>
        <h4>{{ $t('footer.company') }}</h4>
        <NuxtLink :to="localePath('/about')">{{ $t('footer.about') }}</NuxtLink>
        <NuxtLink :to="localePath('/faq')">{{ $t('footer.faq') }}</NuxtLink>
      </div>
      <div>
        <h4>{{ $t('footer.support') }}</h4>
        <NuxtLink :to="localePath('/privacy')">{{ $t('footer.privacy') }}</NuxtLink>
        <NuxtLink :to="localePath('/terms')">{{ $t('footer.terms') }}</NuxtLink>
      </div>
    </div>
    <div class="hm-footer-bottom">© {{ new Date().getFullYear() }} MASTER PREMIUM SERVICES</div>
  </footer>
</template>

<script setup lang="ts">
const { t: $t } = useI18n()
const localePath = useLocalePath()
const router = useRouter()
const { apiFetch } = useApi()

const categories = ref<any[]>([])

function goCat(id: number) {
  router.push(localePath('/masters?category_id=' + id))
}

onMounted(async () => {
  try {
    const res = await apiFetch<{ categories: any[] }>('/categories?only_with_masters=1')
    categories.value = (res.categories || []).slice(0, 4)
  } catch {}
})
</script>
