<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div v-if="!loading && !profile" class="hm-loading">404</div>
      <template v-else-if="profile">
        <div class="hm-person-grid">
          <!-- LEFT -->
          <div>
            <!-- Head -->
            <section class="hm-person-head">
              <div class="hm-person-photo">
                <div class="hm-person-photo-inner" :style="profile.avatar_url ? { backgroundImage: `url(${profile.avatar_url})` } : {}">
                  <span v-if="!profile.avatar_url">{{ initials }}</span>
                </div>
                <div v-if="profile.is_verified || profile.master_profile?.is_verified" class="hm-person-verified">{{ $t('masters.verified') }}</div>
              </div>

              <div class="hm-person-main">
                <div class="hm-person-title-row">
                  <h1 class="hm-person-name">{{ profile.full_name }}</h1>
                  <div class="hm-person-rating-inline">
                    <span class="star">★</span>
                    <span class="val">{{ Number(profile.rating_avg || 0).toFixed(2) }}</span>
                    <span class="cnt">({{ profile.rating_count || 0 }} {{ $t('masters.reviews_short') }})</span>
                  </div>
                </div>
                <div class="hm-person-sub">{{ roleSubtitle }}</div>
                <div class="hm-person-chips">
                  <span v-if="profile.master_profile?.is_online" class="hm-chip">● {{ $t('masters.online') }}</span>
                  <span v-if="profile.master_profile?.experience_years" class="hm-chip">{{ profile.master_profile.experience_years }}+ {{ $t('masters.years') }}</span>
                  <span v-if="profile.master_profile?.languages" class="hm-chip">🌐 {{ profile.master_profile.languages }}</span>
                </div>
              </div>
            </section>

            <!-- Stats -->
            <section class="hm-person-stats">
              <div class="hm-person-stat">
                <div class="hm-person-stat-v accent">{{ profile.rating_count || 0 }}</div>
                <div class="hm-person-stat-l">{{ $t('masters.reviews_short') }}</div>
              </div>
              <div class="hm-person-stat">
                <div class="hm-person-stat-v">{{ Number(profile.rating_avg || 0).toFixed(1) }}</div>
                <div class="hm-person-stat-l">{{ $t('masters.rating') }}</div>
              </div>
              <div class="hm-person-stat">
                <div class="hm-person-stat-v">{{ completedCount }}</div>
                <div class="hm-person-stat-l">{{ $t('masters.completed') }}</div>
              </div>
              <div class="hm-person-stat">
                <div class="hm-person-stat-v">{{ profile.master_profile?.experience_years || '—' }}{{ profile.master_profile?.experience_years ? $t('masters.yr') : '' }}</div>
                <div class="hm-person-stat-l">{{ $t('masters.experience') }}</div>
              </div>
            </section>

            <!-- About -->
            <section v-if="profile.master_profile?.description" class="hm-person-section">
              <h2 class="hm-person-section-title">{{ $t('person.about') }}</h2>
              <p>{{ profile.master_profile.description }}</p>
            </section>

            <!-- Location (master) -->
            <section v-if="profile.master_profile?.city" class="hm-person-section">
              <h2 class="hm-person-section-title">{{ $t('person.location') }}</h2>
              <p>📍 {{ profile.master_profile.city }}<span v-if="profile.master_profile.district">, {{ profile.master_profile.district }}</span><span v-if="profile.master_profile.work_radius_km"> · {{ $t('masters.radius') }}: {{ profile.master_profile.work_radius_km }} {{ $t('masters.km') }}</span></p>
            </section>

            <!-- Specialties -->
            <section v-if="profile.master_profile?.categories?.length" class="hm-person-section">
              <h2 class="hm-person-section-title">{{ $t('person.specialties') }}</h2>
              <div class="hm-specialty-grid">
                <NuxtLink
                  v-for="cat in profile.master_profile.categories"
                  :key="cat.id"
                  :to="localePath('/category/' + cat.slug)"
                  class="hm-specialty"
                >
                  <span class="hm-specialty-ico">⚡</span>
                  {{ cat.name }}
                </NuxtLink>
              </div>
            </section>

            <!-- Tabs -->
            <section v-if="profile.role === 'master'" class="hm-person-section">
              <div class="hm-tabs">
                <button
                  v-if="hasPortfolio"
                  class="hm-tab"
                  :class="{ active: tab === 'portfolio' }"
                  @click="tab = 'portfolio'"
                >{{ $t('person.tab_portfolio') }}</button>
                <button
                  class="hm-tab"
                  :class="{ active: tab === 'reviews' }"
                  @click="tab = 'reviews'"
                >{{ $t('person.tab_reviews') }} ({{ profile.rating_count || 0 }})</button>
                <button
                  v-if="hasSkills"
                  class="hm-tab"
                  :class="{ active: tab === 'credentials' }"
                  @click="tab = 'credentials'"
                >{{ $t('person.tab_skills') }}</button>
              </div>

              <!-- Portfolio -->
              <div v-if="tab === 'portfolio' && hasPortfolio" class="hm-portfolio-grid">
                <button
                  v-for="(item, i) in profile.master_profile.portfolio"
                  :key="item.id || i"
                  class="hm-portfolio-item"
                  :style="portfolioBg(item)"
                  @click="lightbox = portfolioSrc(item)"
                >
                  <span class="hm-portfolio-label">{{ item.title || `${$t('person.project')} ${i + 1}` }}</span>
                </button>
              </div>

              <!-- Reviews -->
              <div v-if="tab === 'reviews'" class="hm-reviews-list">
                <div v-for="r in profile.reviews" :key="r.id" class="hm-review">
                  <div class="hm-review-head">
                    <div class="hm-review-avatar">{{ (r.reviewer_name || '?').charAt(0).toUpperCase() }}</div>
                    <div class="hm-review-meta">
                      <div class="hm-review-topline">
                        <div class="hm-review-name">
                          {{ r.reviewer_name }}
                          <span class="hm-review-ver">✓ {{ $t('person.verified') }}</span>
                        </div>
                        <div class="hm-review-stars">{{ '★'.repeat(r.rating) }}{{ '☆'.repeat(5 - r.rating) }}</div>
                      </div>
                      <div class="hm-review-date">{{ formatDate(r.created_at) }}</div>
                    </div>
                  </div>
                  <p v-if="r.text" class="hm-review-text">{{ r.text }}</p>
                  <div v-if="r.photos?.length" class="hm-review-photos">
                    <a v-for="photo in r.photos" :key="photo.thumb" :href="photo.large" target="_blank" class="hm-review-photo">
                      <img :src="photo.thumb" :alt="$t('review.photo')" loading="lazy" />
                    </a>
                  </div>
                </div>
                <p v-if="!profile.reviews?.length" style="color: var(--hm-text-3); text-align: center; padding: 40px 0;">{{ $t('masters.no_reviews') }}</p>
              </div>

              <!-- Credentials / skills -->
              <div v-if="tab === 'credentials' && hasSkills" class="hm-cred-list">
                <div
                  v-for="(items, groupName) in profile.master_profile.skills"
                  :key="groupName"
                  class="hm-cred"
                >
                  <div class="hm-cred-ico">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M12 2L4 5v6c0 5 3.5 9 8 11 4.5-2 8-6 8-11V5l-8-3z" />
                      <path d="M9 12l2 2 4-4" />
                    </svg>
                  </div>
                  <div>
                    <div class="hm-cred-title">{{ groupName }}</div>
                    <div class="hm-cred-desc">{{ items.map((s) => s.name).join(' · ') }}</div>
                  </div>
                </div>
              </div>
            </section>

            <!-- For clients: reviews block if any -->
            <section v-else-if="profile.reviews?.length" class="hm-person-section">
              <h2 class="hm-person-section-title">{{ $t('masters.reviews_title') }} ({{ profile.rating_count }})</h2>
              <div class="hm-reviews-list">
                <div v-for="r in profile.reviews" :key="r.id" class="hm-review">
                  <div class="hm-review-head">
                    <div class="hm-review-avatar">{{ (r.reviewer_name || '?').charAt(0).toUpperCase() }}</div>
                    <div class="hm-review-meta">
                      <div class="hm-review-topline">
                        <div class="hm-review-name">{{ r.reviewer_name }}</div>
                        <div class="hm-review-stars">{{ '★'.repeat(r.rating) }}{{ '☆'.repeat(5 - r.rating) }}</div>
                      </div>
                      <div class="hm-review-date">{{ formatDate(r.created_at) }}</div>
                    </div>
                  </div>
                  <p v-if="r.text" class="hm-review-text">{{ r.text }}</p>
                </div>
              </div>
            </section>
          </div>

          <!-- RIGHT — sticky booking card -->
          <aside v-if="profile.role === 'master'">
            <div class="hm-book-card">
              <div class="hm-book-price">
                <div class="hm-book-price-v">{{ priceLabel }}</div>
                <div v-if="profile.master_profile?.experience_years" class="hm-book-price-u">/ {{ $t('person.per_hour') }}</div>
              </div>
              <div class="hm-book-price-note">{{ $t('person.price_note') }}</div>

              <div v-if="profile.master_profile?.is_accepting" class="hm-book-status">
                <span class="dot"></span>
                {{ $t('person.available_today') }}
              </div>
              <div v-else class="hm-book-status offline">
                <span class="dot"></span>
                {{ $t('masters.not_accepting_now') }}
              </div>

              <NuxtLink
                v-if="profile.master_profile?.is_accepting"
                :to="bookUrl"
                class="hm-cta hm-btn-lg hm-book-btn"
              >
                {{ $t('masters.call_this_master') }}
              </NuxtLink>
              <button
                v-else
                class="hm-cta hm-btn-lg hm-book-btn"
                disabled
                style="opacity: 0.5; cursor: not-allowed;"
              >{{ $t('masters.not_accepting_now') }}</button>

              <div class="hm-book-perks">
                <div class="hm-book-perk"><span class="hm-book-perk-ico">💳</span>{{ $t('person.perk_pay_after') }}</div>
                <div class="hm-book-perk"><span class="hm-book-perk-ico">🔒</span>{{ $t('person.perk_guarantee') }}</div>
                <div class="hm-book-perk"><span class="hm-book-perk-ico">⚡</span>{{ $t('person.perk_fast_response') }}</div>
              </div>
            </div>
          </aside>
        </div>
      </template>
    </div>

    <!-- Lightbox -->
    <div v-if="lightbox" class="hm-lightbox" @click="lightbox = null">
      <img :src="lightbox" alt="" />
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const route = useRoute()
const { formatDate } = useFormatDate()

const slug = computed(() => String(route.params.slug || ''))

const { data: profile, pending: loading } = await useAsyncData(
  () => `profile-${slug.value}`,
  async () => {
    try {
      const res = await apiFetch<{ profile: any }>(`/users/${slug.value}/profile`)
      return res.profile
    } catch { return null }
  },
  { default: () => null, watch: [slug] },
)

// Canonical-slug redirect: if backend's slug differs from URL slug (e.g. user
// followed an old or mistyped link), 301 to the canonical one.
if (profile.value?.slug && profile.value.slug !== slug.value) {
  await navigateTo(localePath('/master/' + profile.value.slug), { redirectCode: 301 })
}

// Build breadcrumb trail: Masters > {name}. The "Home" root is prepended by
// HmBreadcrumbs itself.
const breadcrumbs = useBreadcrumbs()
watchEffect(() => {
  const p = profile.value
  if (!p) { breadcrumbs.set(null); return }
  const trail = [{ label: $t('nav.masters'), to: localePath('/masters') }]
  const primaryCat = p.master_profile?.categories?.[0]
  if (primaryCat?.slug) {
    trail.push({ label: primaryCat.name, to: localePath('/category/' + primaryCat.slug) })
  }
  trail.push({ label: p.full_name })
  breadcrumbs.set(trail)
})
onBeforeUnmount(() => breadcrumbs.set(null))

// JSON-LD: ProfilePage > Person with AggregateRating + Review[]. Schema.org's
// Person type covers individual professionals; Service-only schemas like
// LocalBusiness require an address, which we deliberately don't expose for
// privacy. AggregateRating + Review combo unlocks star ratings in SERPs.
useHead(() => {
  const p = profile.value
  if (!p) return {}
  const SITE = 'https://itez.app'
  const primaryCat = p.master_profile?.categories?.[0]
  const reviews = (p.reviews || []).slice(0, 10).map((r: any) => ({
    '@type': 'Review',
    author: { '@type': 'Person', name: r.reviewer_name || 'Anonymous' },
    datePublished: r.created_at,
    reviewBody: r.text || undefined,
    reviewRating: {
      '@type': 'Rating',
      ratingValue: r.rating,
      bestRating: 5,
      worstRating: 1,
    },
  }))
  const personUrl = `${SITE}/master/${p.slug}`
  const profileSchema: Record<string, any> = {
    '@context': 'https://schema.org',
    '@type': 'ProfilePage',
    url: personUrl,
    dateModified: p.updated_at || undefined,
    mainEntity: {
      '@type': 'Person',
      '@id': personUrl + '#person',
      name: p.full_name,
      url: personUrl,
      image: p.avatar_url || undefined,
      jobTitle: primaryCat?.name || undefined,
      knowsAbout: (p.master_profile?.categories || []).map((c: any) => c.name),
      address: p.master_profile?.city
        ? {
            '@type': 'PostalAddress',
            addressLocality: p.master_profile.city,
            addressCountry: 'AZ',
          }
        : undefined,
      aggregateRating:
        p.rating_count > 0
          ? {
              '@type': 'AggregateRating',
              ratingValue: Number(p.rating_avg || 0),
              ratingCount: p.rating_count,
              bestRating: 5,
              worstRating: 1,
            }
          : undefined,
      review: reviews.length ? reviews : undefined,
      makesOffer: (p.master_profile?.categories || [])
        .filter((c: any) => c.base_price)
        .map((c: any) => ({
          '@type': 'Offer',
          itemOffered: { '@type': 'Service', name: c.name },
          price: c.base_price,
          priceCurrency: 'AZN',
        })),
    },
  }
  // Strip undefined values from mainEntity (Google validator dislikes them).
  for (const k of Object.keys(profileSchema.mainEntity)) {
    if (profileSchema.mainEntity[k] === undefined) delete profileSchema.mainEntity[k]
  }
  return {
    script: [
      {
        type: 'application/ld+json',
        innerHTML: JSON.stringify(profileSchema),
        key: 'jsonld-profile',
      },
    ],
  }
})

// SEO head — per-locale title/description with star count + reviews, og:image
// uses avatar when present (will be replaced by dedicated /og endpoint later).
useSeoHead(() => {
  const p = profile.value
  if (!p) return { title: $t('seo.masters_title', { n: 0 }), canonicalPath: '/master/' + slug.value }
  const primaryCat = p.master_profile?.categories?.[0]
  const hreflangPaths: Record<string, string> = {}
  if (p.slug_translations) {
    for (const l of ['az', 'ru', 'en', 'tr', 'ar']) {
      hreflangPaths[l] = '/master/' + (p.slug_translations[l] || p.slug)
    }
  }
  const desc = p.master_profile?.description
    ? p.master_profile.description.slice(0, 155)
    : $t('seo.master_desc', {
        name: p.full_name,
        category: primaryCat?.name || '',
        experience: p.master_profile?.experience_years || 0,
        orders: p.master_profile?.completed_orders || 0,
        description: '',
      })
  return {
    title: $t('seo.master_title', {
      name: p.full_name,
      category: primaryCat?.name || $t('admin.role_master'),
      rating: Number(p.rating_avg || 0).toFixed(1),
      reviews: p.rating_count || 0,
    }),
    description: desc,
    canonicalPath: '/master/' + p.slug,
    hreflangPaths,
    image: p.avatar_url,
    ogType: 'profile',
  }
})

const tab = ref<'portfolio' | 'reviews' | 'credentials'>('reviews')
const lightbox = ref<string | null>(null)

const initials = computed(() => {
  const p = profile.value
  if (!p) return ''
  return `${(p.first_name || '').charAt(0)}${(p.last_name || '').charAt(0)}`.toUpperCase()
})

const hasPortfolio = computed(() => (profile.value?.master_profile?.portfolio?.length || 0) > 0)
const hasSkills = computed(() => {
  const s = profile.value?.master_profile?.skills
  return s && Object.keys(s).length > 0
})

const completedCount = computed(() => {
  const p = profile.value
  if (!p) return 0
  return p.master_profile?.completed_orders || p.orders_count || 0
})

const roleSubtitle = computed(() => {
  const p = profile.value
  if (!p) return ''
  if (p.role === 'master') {
    const cats = p.master_profile?.categories || []
    if (cats.length) return cats.map((c: any) => c.name).join(' · ')
    return $t('admin.role_master')
  }
  return $t('admin.role_client')
})

const priceLabel = computed(() => {
  const p = profile.value
  if (!p?.master_profile) return '—'
  const prices = (p.master_profile.categories || []).map((c: any) => c.base_price).filter(Boolean)
  if (prices.length) return `${$t('common.from')} ${Math.min(...prices)} ₼`
  return `${Number(p.rating_avg || 5).toFixed(1)} ★`
})

const bookUrl = computed(() => {
  const p = profile.value
  if (!p) return localePath('/masters')
  return localePath('/client/new-order?master_id=' + p.id + '&master_name=' + encodeURIComponent(p.full_name))
})

function portfolioSrc(item: any): string {
  return item?.large_url || item?.medium_url || item?.thumb_url || item?.image_url || ''
}

function portfolioBg(item: any) {
  const src = item?.medium_url || item?.thumb_url || item?.image_url
  if (!src) return { background: 'var(--hm-bg-3)' }
  return { backgroundImage: `url(${src})` }
}

onMounted(() => {
  const q = route.query.tab as string | undefined
  if (q === 'reviews' || q === 'portfolio' || q === 'credentials') {
    tab.value = q
    return
  }
  if (!hasPortfolio.value && !hasSkills.value) tab.value = 'reviews'
  else if (hasPortfolio.value) tab.value = 'portfolio'
})
</script>
