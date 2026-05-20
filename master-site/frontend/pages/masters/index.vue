<template>
  <div class="hm-page hm-masters-page">
    <div class="hm-page-inner">
      <div class="hm-masters-layout">
        <!-- Sidebar with filters -->
        <aside class="hm-side">
          <div class="hm-side-head">
            <h2 class="pub">{{ $t('masters.filters_title') }}</h2>
            <a class="hm-side-clear" @click="clearFilters">{{ $t('masters.clear_all') }}</a>
          </div>

          <div class="hm-side-group">
            <div class="hm-side-label">{{ $t('masters.service_type') }}</div>
            <div class="hm-filter-list">
              <button
                v-for="c in categories"
                :key="c.id"
                type="button"
                class="hm-filter-btn"
                :class="{ active: filters.category_id == c.id }"
                @click="selectCategory(c.id)"
              >
                <span>{{ c.name }}</span>
                <span v-if="c.masters_count" class="hm-filter-count">{{ c.masters_count }}</span>
              </button>
            </div>
          </div>

          <div class="hm-side-group">
            <div class="hm-side-label">{{ $t('masters.sort_by') }}</div>
            <select v-model="filters.sort" @change="fetchMasters" class="hm-form-select">
              <option v-if="filters.lat != null && filters.lng != null" value="distance">{{ $t('masters.sort_distance') }}</option>
              <option value="rating">{{ $t('masters.sort_rating') }}</option>
              <option value="orders">{{ $t('masters.sort_orders') }}</option>
              <option value="experience">{{ $t('masters.sort_experience') }}</option>
              <option value="newest">{{ $t('masters.sort_newest') }}</option>
            </select>
          </div>

          <div class="hm-side-group">
            <div class="hm-side-label">{{ $t('masters.availability') }}</div>
            <label class="hm-check">
              <input type="checkbox" v-model="filters.online" @change="fetchMasters" />
              <span class="hm-check-box"></span>
              {{ $t('masters.online_only') }}
            </label>
          </div>

          <div class="hm-side-group">
            <div class="hm-side-label">{{ $t('masters.search_label') }}</div>
            <input
              v-model="filters.search"
              type="text"
              class="hm-form-input"
              :placeholder="$t('masters.search_placeholder')"
              @input="debouncedFetch"
            />
          </div>
        </aside>

        <!-- Main grid -->
        <section class="hm-main-col">
          <div class="hm-main-head">
            <div>
              <h1 class="hm-page-title">
                {{ filters.category_id ? (categories.find(c => c.id == filters.category_id)?.name || '') : $t('masters.all_specialists') }}
              </h1>
              <p class="hm-page-sub">{{ $t('masters.found_n', { n: masters.length }) }}</p>
            </div>
          </div>

          <div v-if="loading && !masters.length" class="hm-loading">{{ $t('common.loading') }}</div>
          <div v-else-if="masters.length === 0" class="hm-empty">{{ $t('masters.no_results') }}</div>

          <div v-else class="hm-masters-grid">
            <NuxtLink
              v-for="m in masters"
              :key="m.id"
              :to="localePath('/master/' + (m.slug || m.id))"
              class="hm-spec-card"
            >
              <div class="hm-spec-photo" :style="m.avatar_url ? { backgroundImage: `url(${m.avatar_url})` } : {}">
                <div v-if="m.is_online" class="hm-spec-avail">{{ $t('masters.online') }}</div>
                <div v-if="m.distance_km != null" class="hm-spec-dist"><span class="icon icon-sm">near_me</span>{{ m.distance_km }} {{ $t('masters.km') }}</div>
                <div v-if="m.rating_avg" class="hm-spec-rating">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="var(--hm-accent)"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
                  {{ m.rating_avg }}
                </div>
              </div>
              <h3>{{ m.first_name }} {{ m.last_name }}</h3>
              <p class="hm-spec-sub">{{ m.description }}</p>
              <div class="hm-spec-tags" v-if="m.categories?.length">
                <span v-for="c in m.categories.slice(0, 2)" :key="c.id" class="hm-tag">{{ c.name }}</span>
              </div>
              <div class="hm-spec-foot">
                <div>
                  <div class="hm-spec-rev">{{ m.rating_count || 0 }} {{ $t('masters.reviews') }}</div>
                  <div class="hm-spec-city">{{ m.city }}{{ m.district ? ', ' + m.district : '' }}</div>
                </div>
                <span class="hm-btn hm-btn-primary hm-btn-xs">{{ $t('masters.view') }}</span>
              </div>
            </NuxtLink>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
useSeoHead(() => ({
  title: $t('seo.masters_title', { n: masters.value?.length || 0 }),
  description: $t('seo.masters_desc'),
  canonicalPath: '/masters',
}))
const localePath = useLocalePath()
const { apiFetch } = useApi()
const route = useRoute()

const filters = reactive({
  search: (route.query.search || route.query.q || '') as string,
  category_id: (route.query.category_id || '') as string | number,
  sort: (route.query.sort as string) || 'rating',
  online: false,
  lat: route.query.lat ? parseFloat(route.query.lat as string) : null as number | null,
  lng: route.query.lng ? parseFloat(route.query.lng as string) : null as number | null,
})

function buildParams() {
  const params = new URLSearchParams()
  if (filters.search) params.set('search', filters.search)
  if (filters.category_id) params.set('category_id', String(filters.category_id))
  if (filters.sort) params.set('sort', filters.sort)
  if (filters.online) params.set('online', '1')
  if (filters.lat != null && filters.lng != null) {
    params.set('lat', String(filters.lat))
    params.set('lng', String(filters.lng))
  }
  return params
}

const { data: categories } = await useAsyncData('masters-categories', async () => {
  const res = await apiFetch<{ categories: any[] }>('/categories?only_with_masters=1')
  return res.categories || []
}, { default: () => [] })

const { data: masters } = await useAsyncData(
  `masters-list:${String(filters.category_id || '')}:${filters.sort}:${filters.online ? 1 : 0}:${filters.search}`,
  async () => {
    const res = await apiFetch<{ masters: any[] }>(`/masters?${buildParams()}`)
    return res.masters || []
  },
  { default: () => [] },
)
const loading = ref(false)

async function refreshMasters() {
  loading.value = true
  try {
    const res = await apiFetch<{ masters: any[] }>(`/masters?${buildParams()}`)
    masters.value = res.masters || []
  } catch {
    // Keep previous list on error — better than empty state
  } finally {
    loading.value = false
  }
}

function selectCategory(id: string | number) {
  filters.category_id = filters.category_id == id ? '' : id
  refreshMasters()
}

function clearFilters() {
  filters.search = ''
  filters.category_id = ''
  filters.sort = 'rating'
  filters.online = false
  refreshMasters()
}

const fetchMasters = refreshMasters

let debounceTimer: ReturnType<typeof setTimeout> | null = null
function debouncedFetch() {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(refreshMasters, 400)
}

onUnmounted(() => {
  if (debounceTimer) { clearTimeout(debounceTimer); debounceTimer = null }
})
</script>
