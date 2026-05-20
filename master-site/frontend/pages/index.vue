<template>
  <div class="hm-landing-content">
    <!-- === HERO === -->
    <section class="hm-hero">
      <div class="hm-glow hm-glow-1"></div>
      <div class="hm-glow hm-glow-2"></div>

      <div class="hm-blob hm-blob-1" aria-hidden="true"></div>
      <div class="hm-blob hm-blob-2" aria-hidden="true"></div>
      <div class="hm-blob hm-blob-3" aria-hidden="true"></div>

      <h1 class="hm-hero-title">
        {{ $t('hero.home_line1') }}<br />
        {{ $t('hero.home_line2_before') }}
        <span class="hm-accent-text">{{ $t('hero.home_highlight') }}</span>
        {{ $t('hero.home_line2_after') }}
      </h1>

      <p class="hm-hero-sub">{{ $t('hero.home_subtitle') }}</p>

      <form class="hm-smart-search" @submit.prevent="doSmartSearch">
        <div class="hm-smart-textarea-wrap">
          <textarea
            v-model="problemText"
            class="hm-smart-textarea"
            rows="3"
            :placeholder="$t('hero.smart_placeholder')"
            :disabled="smartLoading"
          />
          <div class="hm-smart-tools">
            <label class="hm-smart-photo-btn" :class="{ active: !!photoPreview }">
              <input
                type="file"
                accept="image/*"
                hidden
                @change="onPhotoPicked"
                :disabled="smartLoading"
              />
              <span class="icon icon-sm">{{ photoPreview ? 'photo' : 'photo_camera' }}</span>
              <span>{{ photoPreview ? $t('hero.photo_attached') : $t('hero.attach_photo') }}</span>
            </label>
            <button
              v-if="photoPreview"
              type="button"
              class="hm-smart-photo-clear"
              @click="clearPhoto"
              :disabled="smartLoading"
              :title="$t('hero.remove_photo')"
            >
              <span class="icon icon-sm">close</span>
            </button>
            <div class="hm-smart-loc" v-if="userCoords">
              <span class="icon icon-sm">near_me</span>
              <span>{{ $t('hero.geo_ready') }}</span>
            </div>
            <button
              type="button"
              v-else
              class="hm-smart-geo-btn"
              @click="requestGeo"
              :disabled="smartLoading || geoLoading"
            >
              <span class="icon icon-sm">my_location</span>
              {{ geoLoading ? $t('hero.detecting_geo') : $t('hero.use_my_location') }}
            </button>
          </div>
          <img v-if="photoPreview" :src="photoPreview" class="hm-smart-photo-preview" />
          <p v-if="smartError" class="hm-smart-error">{{ smartError }}</p>
        </div>
        <button
          type="submit"
          class="hm-btn hm-btn-primary hm-smart-submit"
          :disabled="smartLoading || (!problemText.trim() && !photoPreview)"
        >
          <span v-if="smartLoading" class="hm-smart-spinner"></span>
          <span v-else class="icon icon-sm">auto_awesome</span>
          {{ smartLoading ? $t('hero.smart_analyzing') : $t('hero.smart_find') }}
        </button>
      </form>

      <div class="hm-trust-row">
        <div class="hm-trust-item">
          <strong>★ 4.9/5</strong>
          <span>{{ $t('hero.trust_reviews') }}</span>
        </div>
        <div class="hm-trust-item">
          <strong>🛡</strong>
          <span>{{ $t('hero.trust_licensed') }}</span>
        </div>
        <div class="hm-trust-item">
          <strong>⚡</strong>
          <span>{{ $t('hero.trust_response') }}</span>
        </div>
      </div>
    </section>

    <!-- === POPULAR SERVICES === -->
    <section class="hm-section hm-popular">
      <div class="hm-section-inner">
        <div class="hm-section-head">
          <div>
            <h2 class="hm-section-title">{{ $t('popular.title') }}</h2>
            <p class="hm-section-sub">{{ $t('popular.subtitle') }}</p>
          </div>
          <NuxtLink :to="localePath('/categories')" class="hm-see-all">
            {{ $t('popular.see_all') }} <span>→</span>
          </NuxtLink>
        </div>

        <div class="hm-services-grid">
          <NuxtLink
            v-for="(s, i) in popularServices"
            :key="i"
            :to="s.slug ? localePath('/category/' + s.slug) : localePath('/categories')"
            class="hm-svc-card"
          >
            <span v-if="s.popular" class="hm-svc-popular">★ {{ $t('popular.popular_tag') }}</span>
            <div class="hm-svc-icon"><CatIcon :icon="s.icon" fallback="category" /></div>
            <h3>{{ s.title }}</h3>
            <p>{{ s.desc }}</p>
            <span class="hm-svc-book">{{ $t('popular.book_now') }} <span>→</span></span>
          </NuxtLink>
        </div>
      </div>
    </section>

    <!-- === 4-STEP BOOKING === -->
    <section class="hm-section hm-steps-section">
      <div class="hm-section-inner">
        <div class="hm-steps-card">
          <div class="hm-steps-head">
            <h2>{{ $t('steps.title') }}</h2>
            <p>{{ $t('steps.subtitle') }}</p>
          </div>

          <div class="hm-steps-grid">
            <div class="hm-steps-dash"></div>
            <div v-for="(s, i) in steps" :key="i" class="hm-step">
              <div class="hm-step-num">{{ i + 1 }}</div>
              <h3>{{ s.title }}</h3>
              <p>{{ s.desc }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- === WHY TRUST === -->
    <section class="hm-section hm-trust">
      <div class="hm-section-inner hm-trust-grid">
        <div class="hm-trust-left">
          <h2 class="hm-section-title">
            {{ $t('trust.title_before') }}<br />
            <span class="hm-accent-text">{{ $t('trust.title_brand') }}</span>
          </h2>

          <div class="hm-trust-list">
            <div v-for="(t, i) in trustItems" :key="i" class="hm-trust-point">
              <div class="hm-trust-icon">{{ t.icon }}</div>
              <div>
                <h4>{{ t.title }}</h4>
                <p>{{ t.desc }}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="hm-trust-collage">
          <div class="hm-trust-col">
            <div class="hm-trust-photo" :style="{ backgroundImage: 'url(/landing-assets/pro-1.png)' }"></div>
            <div class="hm-trust-stat hm-stat-accent">
              <div class="hm-stat-num">99%</div>
              <div class="hm-stat-label">{{ $t('trust.stat_satisfaction') }}</div>
            </div>
          </div>
          <div class="hm-trust-col hm-trust-col-shift">
            <div class="hm-trust-stat hm-stat-dark">
              <div class="hm-stat-num">4.9/5</div>
              <div class="hm-stat-label">{{ $t('trust.stat_appstore') }}</div>
            </div>
            <div class="hm-trust-photo" :style="{ backgroundImage: 'url(/landing-assets/pro-2.png)' }"></div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const router = useRouter()

useSeoHead({
  title: $t('seo.home_title'),
  description: $t('seo.home_desc'),
  canonicalPath: '/',
})

const { data: categories } = await useAsyncData('home-categories', async () => {
  try {
    const res = await apiFetch<{ categories: any[] }>('/categories?only_with_masters=1')
    return res.categories || []
  } catch { return [] }
}, { default: () => [] })

// === Smart search state ===
const problemText = ref('')
const photoBase64 = ref<string | null>(null)
const photoPreview = ref<string | null>(null)
const photoMime = ref<string | null>(null)
const userCoords = ref<{ lat: number; lng: number } | null>(null)
const geoLoading = ref(false)
const smartLoading = ref(false)
const smartError = ref('')

function onPhotoPicked(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  if (file.size > 5 * 1024 * 1024) {
    smartError.value = $t('hero.photo_too_large')
    return
  }
  const reader = new FileReader()
  reader.onload = () => {
    const result = String(reader.result || '')
    photoPreview.value = result
    // result is a data:URL — strip prefix for base64
    const m = result.match(/^data:([^;]+);base64,(.*)$/)
    if (m) {
      photoMime.value = m[1]
      photoBase64.value = m[2]
    }
  }
  reader.readAsDataURL(file)
}

function clearPhoto() {
  photoBase64.value = null
  photoPreview.value = null
  photoMime.value = null
}

function requestGeo() {
  if (!import.meta.client) return
  if (!navigator.geolocation) {
    smartError.value = $t('hero.geo_unsupported')
    return
  }
  geoLoading.value = true
  smartError.value = ''
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      userCoords.value = { lat: pos.coords.latitude, lng: pos.coords.longitude }
      geoLoading.value = false
    },
    () => {
      geoLoading.value = false
      smartError.value = $t('hero.geo_denied')
    },
    { enableHighAccuracy: false, timeout: 8000, maximumAge: 60000 }
  )
}

async function doSmartSearch() {
  if (!problemText.value.trim() && !photoBase64.value) return
  smartLoading.value = true
  smartError.value = ''
  try {
    const res = await apiFetch<{ category_id: number | null; category_slug: string | null; category_name: string | null; title: string | null; description: string | null }>(
      '/smart-search',
      {
        method: 'POST',
        body: {
          description: problemText.value.trim(),
          image: photoBase64.value,
          image_mime: photoMime.value,
        },
      }
    )
    const query: Record<string, string> = {}
    if (userCoords.value) {
      query.lat = String(userCoords.value.lat)
      query.lng = String(userCoords.value.lng)
      query.sort = 'distance'
    }
    const targetPath = res.category_slug
      ? localePath('/category/' + res.category_slug)
      : localePath('/masters')
    if (!res.category_slug && res.category_id) query.category_id = String(res.category_id)
    router.push({ path: targetPath, query })
  } catch (e: any) {
    smartError.value = e?.data?.message || $t('hero.smart_error')
  } finally {
    smartLoading.value = false
  }
}

const defaultServices = computed(() => [
  { icon: 'ph:lightning', title: $t('popular.electrician'), desc: $t('popular.electrician_desc'), popular: true },
  { icon: 'ph:wrench', title: $t('popular.plumber'), desc: $t('popular.plumber_desc') },
  { icon: 'ph:toolbox', title: $t('popular.handyman'), desc: $t('popular.handyman_desc') },
  { icon: 'ph:snowflake', title: $t('popular.hvac'), desc: $t('popular.hvac_desc') },
  { icon: 'ph:broom', title: $t('popular.cleaning'), desc: $t('popular.cleaning_desc') },
  { icon: 'ph:plant', title: $t('popular.landscaping'), desc: $t('popular.landscaping_desc') },
  { icon: 'ph:paint-roller', title: $t('popular.painting'), desc: $t('popular.painting_desc') },
  { icon: 'ph:house-simple', title: $t('popular.roofing'), desc: $t('popular.roofing_desc') },
])

const popularServices = computed(() => {
  const cats = categories.value.slice(0, 8)
  if (!cats.length) return defaultServices.value
  return defaultServices.value.map((d, i) => cats[i]
    ? { id: cats[i].id, slug: cats[i].slug, icon: cats[i].icon_url || d.icon, title: cats[i].name, desc: cats[i].description || d.desc, popular: i === 0 }
    : d
  )
})

const steps = computed(() => [
  { title: $t('steps.s1_title'), desc: $t('steps.s1_desc') },
  { title: $t('steps.s2_title'), desc: $t('steps.s2_desc') },
  { title: $t('steps.s3_title'), desc: $t('steps.s3_desc') },
  { title: $t('steps.s4_title'), desc: $t('steps.s4_desc') },
])

const trustItems = computed(() => [
  { icon: '🏆', title: $t('trust.t1_title'), desc: $t('trust.t1_desc') },
  { icon: '💰', title: $t('trust.t2_title'), desc: $t('trust.t2_desc') },
  { icon: '⏰', title: $t('trust.t3_title'), desc: $t('trust.t3_desc') },
  { icon: '🛡', title: $t('trust.t4_title'), desc: $t('trust.t4_desc') },
])

</script>
