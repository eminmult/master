<template>
  <header class="hm-topbar">
    <NuxtLink :to="localePath('/')" class="hm-logo">
      <div class="hm-logo-mark">
        <svg width="19" height="22" viewBox="0 0 19 22" aria-hidden="true">
          <path d="M 8.175 16.625 L 12.875 10.9 L 9.125 10.9 L 9.75 5.95 L 5.55 12 L 8.85 12 L 8.175 16.625 M 4.5 21.9 L 5.5 14.9 L 0 14.9 L 10.325 0 L 13.4 0 L 12.4 8 L 19.075 8 L 7.55 21.9 L 4.5 21.9" />
        </svg>
      </div>
      <span>Master</span>
    </NuxtLink>

    <nav class="hm-nav">
      <NuxtLink :to="localePath('/orders')">{{ $t('public_orders.nav_link') }}</NuxtLink>
      <NuxtLink :to="localePath('/categories')">{{ $t('nav.services') }}</NuxtLink>
      <NuxtLink :to="localePath('/masters')">{{ $t('nav.masters') }}</NuxtLink>
      <NuxtLink :to="localePath('/how-it-works')">{{ $t('nav.how_it_works') }}</NuxtLink>
      <NuxtLink :to="localePath('/blog')">{{ $t('blog.title') }}</NuxtLink>
    </nav>

    <div class="hm-actions">
      <div class="hm-lang" ref="langMenuRef">
        <button type="button" class="hm-lang-toggle" :class="{ open: langOpen }" @click="langOpen = !langOpen" :aria-expanded="langOpen">
          <span class="hm-lang-globe" aria-hidden="true">
            <span class="hm-lang-globe-ring"></span>
            <span class="hm-lang-globe-dot"></span>
          </span>
          <span class="hm-lang-cur">{{ currentLocaleLabel }}</span>
          <svg class="hm-lang-caret" width="10" height="6" viewBox="0 0 10 6" fill="none"><path d="M1 1l4 4 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
        </button>
        <Transition name="hm-lang-pop">
          <div v-if="langOpen" class="hm-lang-panel">
            <div class="hm-lang-glow"></div>
            <div class="hm-lang-panel-head">
              <span class="hm-lang-panel-title">{{ $t('lang.choose') }}</span>
              <span class="hm-lang-panel-count">{{ availableLocales.length }}</span>
            </div>
            <div class="hm-lang-list">
              <NuxtLink
                v-for="(loc, i) in availableLocales"
                :key="loc.code"
                :to="getLocalePath(loc.code)"
                class="hm-lang-card"
                :class="['hm-lang-' + loc.code, { active: loc.code === currentLocale }]"
                :style="{ '--i': i }"
                @click="onPickLocale(loc.code)"
              >
                <span class="hm-lang-watermark" aria-hidden="true">{{ loc.label }}</span>
                <span class="hm-lang-card-body">
                  <span class="hm-lang-native">{{ loc.name }}</span>
                  <span class="hm-lang-sample">{{ loc.sample }}</span>
                </span>
                <span class="hm-lang-stripe" aria-hidden="true"></span>
                <span v-if="loc.code === currentLocale" class="hm-lang-active-pill">
                  <span class="hm-lang-active-dot"></span>
                  {{ $t('lang.current') }}
                </span>
              </NuxtLink>
            </div>
          </div>
        </Transition>
      </div>

      <button type="button" class="hm-theme-btn" @click="theme.toggle()" :title="theme.value === 'dark' ? 'Light' : 'Dark'">
        <span class="icon icon-sm">{{ theme.value === 'dark' ? 'light_mode' : 'dark_mode' }}</span>
      </button>

      <ClientOnly>
        <template v-if="auth.isLoggedIn">
          <label v-if="auth.isMaster" class="hm-accept" :class="{ active: masterAccepting }" :title="masterAccepting ? $t('master.accepting_tooltip') : $t('master.not_accepting_tooltip')">
            <span class="hm-accept-dot"></span>
            <span class="hm-accept-text">{{ masterAccepting ? $t('master.online') : $t('master.offline') }}</span>
            <input type="checkbox" :checked="masterAccepting" @change="toggleAccepting" />
            <span class="hm-accept-track"><span class="hm-accept-thumb"></span></span>
          </label>

          <div class="hm-bell-wrap">
            <NotificationBell />
          </div>

          <div class="hm-user" ref="userMenuRef">
            <button type="button" class="hm-user-btn" @click="userOpen = !userOpen">
              <span
                class="hm-user-avatar"
                :style="auth.user?.avatar_url ? { backgroundImage: `url(${auth.user.avatar_url})` } : {}"
              >
                <span v-if="!auth.user?.avatar_url">{{ (auth.user?.first_name || '?').charAt(0) }}</span>
              </span>
              <span class="hm-user-name">{{ auth.user?.first_name }}</span>
              <svg width="10" height="6" viewBox="0 0 10 6" fill="none"><path d="M1 1l4 4 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
            </button>

            <Transition name="hm-pop">
              <div v-if="userOpen" class="hm-user-menu hm-popover">
                <div class="hm-popover-glow"></div>
                <div class="hm-user-head">
                  <strong>{{ auth.user?.first_name }} {{ auth.user?.last_name }}</strong>
                  <span>{{ auth.user?.email || auth.user?.phone }}</span>
                </div>
                <div class="hm-user-body">
                  <NuxtLink :to="localePath(dashboardLink)" class="hm-user-item hm-pop-item" style="--i:0" @click="userOpen = false">
                    <span class="icon icon-sm">dashboard</span> {{ $t('nav.dashboard') }}
                  </NuxtLink>
                  <NuxtLink v-if="auth.isClient" :to="localePath('/client/orders')" class="hm-user-item hm-pop-item" style="--i:1" @click="userOpen = false">
                    <span class="icon icon-sm">receipt_long</span> {{ $t('nav.my_orders') }}
                  </NuxtLink>
                  <NuxtLink v-if="auth.isMaster" :to="localePath('/master/orders')" class="hm-user-item hm-pop-item" style="--i:1" @click="userOpen = false">
                    <span class="icon icon-sm">list_alt</span> {{ $t('master.available_orders') }}
                  </NuxtLink>
                  <NuxtLink v-if="auth.isMaster" :to="localePath('/master/my-orders')" class="hm-user-item hm-pop-item" style="--i:2" @click="userOpen = false">
                    <span class="icon icon-sm">receipt_long</span> {{ $t('nav.my_orders') }}
                  </NuxtLink>
                  <NuxtLink :to="localePath(auth.isMaster ? '/master/profile' : '/client/profile')" class="hm-user-item hm-pop-item" style="--i:3" @click="userOpen = false">
                    <span class="icon icon-sm">person</span> {{ $t('nav.profile') }}
                  </NuxtLink>
                  <NuxtLink v-if="auth.user?.id" :to="localePath('/master/' + auth.user.id)" class="hm-user-item hm-pop-item" style="--i:4" @click="userOpen = false">
                    <span class="icon icon-sm">badge</span> {{ $t('nav.public_profile') }}
                  </NuxtLink>
                  <div class="hm-user-divider"></div>
                  <button type="button" class="hm-user-item hm-user-logout hm-pop-item" style="--i:5" @click="handleLogout">
                    <span class="icon icon-sm">logout</span> {{ $t('nav.logout') }}
                  </button>
                </div>
              </div>
            </Transition>
          </div>
        </template>
        <template v-else>
          <NuxtLink :to="localePath('/login')" class="hm-login-link">{{ $t('nav.login') }}</NuxtLink>
          <NuxtLink :to="localePath('/client/new-order')" class="hm-cta">{{ $t('hero.book_cta') }}</NuxtLink>
        </template>
      </ClientOnly>
    </div>

    <button type="button" class="hm-menu-btn" @click="mobileMenu = !mobileMenu" aria-label="menu">
      <span></span><span></span><span></span>
    </button>

    <div v-if="mobileMenu" class="hm-mobile">
      <NuxtLink :to="localePath('/orders')" @click="mobileMenu = false">{{ $t('public_orders.nav_link') }}</NuxtLink>
      <NuxtLink :to="localePath('/categories')" @click="mobileMenu = false">{{ $t('nav.services') }}</NuxtLink>
      <NuxtLink :to="localePath('/masters')" @click="mobileMenu = false">{{ $t('nav.masters') }}</NuxtLink>
      <NuxtLink :to="localePath('/how-it-works')" @click="mobileMenu = false">{{ $t('nav.how_it_works') }}</NuxtLink>
      <NuxtLink :to="localePath('/blog')" @click="mobileMenu = false">{{ $t('blog.title') }}</NuxtLink>
      <hr />
      <div class="hm-mobile-lang">
        <NuxtLink
          v-for="loc in availableLocales"
          :key="loc.code"
          :to="getLocalePath(loc.code)"
          :class="{ active: loc.code === currentLocale }"
          @click="onPickLocale(loc.code)"
        >{{ loc.label }}</NuxtLink>
      </div>
      <hr />
      <ClientOnly>
        <template v-if="auth.isLoggedIn">
          <NuxtLink :to="localePath(dashboardLink)" @click="mobileMenu = false">
            {{ auth.user?.first_name }} — {{ $t('nav.dashboard') }}
          </NuxtLink>
          <a href="#" @click.prevent="handleLogout">{{ $t('nav.logout') }}</a>
        </template>
        <template v-else>
          <NuxtLink :to="localePath('/login')" @click="mobileMenu = false">{{ $t('nav.login') }}</NuxtLink>
          <NuxtLink :to="localePath('/client/new-order')" @click="mobileMenu = false" class="hm-cta">{{ $t('hero.book_cta') }}</NuxtLink>
        </template>
      </ClientOnly>
    </div>
  </header>
</template>

<script setup lang="ts">
const { t: $t } = useI18n()
const localePath = useLocalePath()
const switchLocalePath = useSwitchLocalePath()
const route = useRoute()
const { apiFetch } = useApi()
const auth = useAuthStore()
const router = useRouter()
const theme = useHmTheme()

const userOpen = ref(false)
const userMenuRef = ref<HTMLElement | null>(null)
const langOpen = ref(false)
const langMenuRef = ref<HTMLElement | null>(null)
const mobileMenu = ref(false)

interface LocaleOption {
  code: string
  label: string
  name: string
  sample: string
}

// Decorative greeting per language. Sourced separately because the API only
// stores code / name / dir / sort.
const localeSamples: Record<string, string> = {
  az: 'Salam', ru: 'Привет', en: 'Hello', tr: 'Merhaba', ar: 'مرحباً',
}

const fallbackLocales: LocaleOption[] = [
  { code: 'az', label: 'AZ', name: 'Azərbaycan', sample: 'Salam' },
  { code: 'ru', label: 'RU', name: 'Русский', sample: 'Привет' },
  { code: 'en', label: 'EN', name: 'English', sample: 'Hello' },
  { code: 'tr', label: 'TR', name: 'Türkçe', sample: 'Merhaba' },
  { code: 'ar', label: 'AR', name: 'العربية', sample: 'مرحباً' },
]

const apiLocales = ref<LocaleOption[] | null>(null)
const availableLocales = computed<LocaleOption[]>(() => apiLocales.value ?? fallbackLocales)

// Refresh the list once on mount — admins can toggle locales server-side
// without a frontend redeploy.
onMounted(async () => {
  try {
    const res = await apiFetch<{ locales: { code: string; name: string; dir: string; sort_order: number }[] }>(
      '/i18n/locales',
    )
    if (res?.locales?.length) {
      apiLocales.value = res.locales.map(l => ({
        code: l.code,
        label: l.code.toUpperCase(),
        name: l.name,
        sample: localeSamples[l.code] ?? l.name,
      }))
    }
  } catch { /* keep fallback */ }
})

const currentLocale = computed(() => {
  const prefix = route.path.split('/')[1]
  return availableLocales.value.find(l => l.code === prefix)?.code || 'az'
})

const currentLocaleLabel = computed(() =>
  availableLocales.value.find(l => l.code === currentLocale.value)?.label || 'AZ'
)

/**
 * Persists the user's locale on the backend so the mobile app and the
 * website stay in sync. Fire-and-forget — the cookie + URL change still
 * apply locally even if the request fails (offline, unauthenticated).
 */
async function onPickLocale(code: string) {
  langOpen.value = false
  mobileMenu.value = false
  try {
    const cookie = useCookie('i18n_lang', { maxAge: 60 * 60 * 24 * 365 })
    cookie.value = code
  } catch { /* SSR / cookie disabled */ }
  if (!auth.isLoggedIn) return
  try {
    await apiFetch('/me/locale', { method: 'PATCH', body: { locale: code } })
  } catch { /* unauth or network — local state still applies */ }
}

// Pages that have per-locale slugs (translated category, master, city+category
// URLs) publish a path-per-locale map via useSeoHead → useState('hm-locale-
// links'). When present, the lang switcher prefers it over switchLocalePath
// so /category/santexnik → /en/category/plumber rather than /en/category/santexnik.
const localeLinks = useState<Record<string, string> | null>('hm-locale-links', () => null)

// Clear stale per-locale links on every navigation so a previous page's
// translated-slug map doesn't bleed into the next route. Each page that has
// localized slugs publishes a fresh map via useSeoHead → useState.
watch(() => route.path, () => { localeLinks.value = null })

function getLocalePath(code: string): string {
  const mapped = localeLinks.value?.[code]
  if (mapped) {
    return code === 'az' ? mapped : '/' + code + mapped
  }
  const p = switchLocalePath(code)
  if (p) return p
  let clean = route.path
  for (const loc of availableLocales) {
    if (clean.startsWith('/' + loc.code + '/') || clean === '/' + loc.code) {
      clean = clean.slice(loc.code.length + 1) || '/'
      break
    }
  }
  return code === 'az' ? clean : '/' + code + clean
}

const dashboardLink = computed(() => {
  if (auth.isMaster) return '/master'
  if (auth.isAdmin) return '/admin'
  return '/client'
})

const masterAccepting = computed(() => auth.user?.master_profile?.is_accepting_orders)

async function toggleAccepting() {
  const newStatus = masterAccepting.value ? 'offline' : 'online'
  try {
    await apiFetch('/master/status', { method: 'PUT', body: { status: newStatus } })
    await auth.fetchUser()
  } catch {}
}

async function handleLogout() {
  userOpen.value = false
  mobileMenu.value = false
  await auth.logout()
  router.push(localePath('/'))
}

function handleClickOutside(e: MouseEvent) {
  if (userMenuRef.value && !userMenuRef.value.contains(e.target as Node)) {
    userOpen.value = false
  }
  if (langMenuRef.value && !langMenuRef.value.contains(e.target as Node)) {
    langOpen.value = false
  }
}

onMounted(() => {
  if (import.meta.client) {
    document.addEventListener('click', handleClickOutside)
    if (!auth.isLoggedIn) auth.fetchUser()
  }
})

onUnmounted(() => {
  if (import.meta.client) document.removeEventListener('click', handleClickOutside)
})
</script>
