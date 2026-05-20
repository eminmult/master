<template>
  <div class="app-layout" :dir="currentLocale === 'ar' ? 'rtl' : 'ltr'">
    <header class="app-header">
      <div class="container header-inner">
        <NuxtLink :to="localePath('/')" class="logo">
          <span class="logo-icon">M</span>
          <span class="logo-text">Master</span>
        </NuxtLink>
        <nav class="nav-desktop">
          <NuxtLink :to="localePath('/categories')">{{ $t('nav.services') }}</NuxtLink>
          <NuxtLink :to="localePath('/masters')">{{ $t('masters.page_title') }}</NuxtLink>
          <NuxtLink :to="localePath('/how-it-works')">{{ $t('nav.how_it_works') }}</NuxtLink>
        </nav>
        <div class="header-actions">
          <div class="lang-switcher">
            <NuxtLink
              v-for="loc in availableLocales"
              :key="loc.code"
              :to="getLocalePath(loc.code)"
              class="lang-btn"
              :class="{ active: loc.code === currentLocale }"
            >{{ loc.label }}</NuxtLink>
          </div>
          <template v-if="auth.isLoggedIn">
            <!-- Master accepting toggle -->
            <label v-if="auth.isMaster" class="accept-switch" :class="{ active: masterAccepting }">
              <input type="checkbox" :checked="masterAccepting" @change="toggleAccepting" />
              <span class="switch-track"><span class="switch-thumb"></span></span>
              <span class="switch-label">{{ masterAccepting ? $t('master.accepting') : $t('master.not_accepting') }}</span>
            </label>
            <NotificationBell />
            <NuxtLink :to="localePath(dashboardLink)" class="btn btn-outline btn-sm">{{ auth.user?.first_name }}</NuxtLink>
            <button class="btn btn-sm" style="color:var(--gray-500)" @click="handleLogout">{{ $t('nav.logout') }}</button>
          </template>
          <template v-else>
            <NuxtLink :to="localePath('/login')" class="btn btn-outline btn-sm">{{ $t('nav.login') }}</NuxtLink>
            <NuxtLink :to="localePath('/register')" class="btn btn-primary btn-sm">{{ $t('nav.register') }}</NuxtLink>
          </template>
        </div>
        <button class="mobile-menu-btn" @click="mobileMenu = !mobileMenu">
          <span></span><span></span><span></span>
        </button>
      </div>
      <div v-if="mobileMenu" class="mobile-menu">
        <NuxtLink :to="localePath('/categories')" @click="mobileMenu = false">{{ $t('nav.services') }}</NuxtLink>
        <NuxtLink :to="localePath('/masters')" @click="mobileMenu = false">{{ $t('masters.page_title') }}</NuxtLink>
        <NuxtLink :to="localePath('/how-it-works')" @click="mobileMenu = false">{{ $t('nav.how_it_works') }}</NuxtLink>
        <hr />
        <div class="mobile-lang">
          <NuxtLink v-for="loc in availableLocales" :key="loc.code"
            :to="getLocalePath(loc.code)"
            :class="{ 'lang-active': loc.code === currentLocale }"
            @click="mobileMenu = false">{{ loc.label }}</NuxtLink>
        </div>
        <hr />
        <template v-if="auth.isLoggedIn">
          <NuxtLink :to="localePath(dashboardLink)" @click="mobileMenu = false">{{ auth.user?.first_name }} - {{ $t('nav.panel') }}</NuxtLink>
          <a href="#" @click.prevent="handleLogout(); mobileMenu = false">{{ $t('nav.logout') }}</a>
        </template>
        <template v-else>
          <NuxtLink :to="localePath('/login')" @click="mobileMenu = false">{{ $t('nav.login') }}</NuxtLink>
          <NuxtLink :to="localePath('/register')" @click="mobileMenu = false">{{ $t('nav.register') }}</NuxtLink>
        </template>
      </div>
    </header>
    <main class="app-main">
      <slot />
    </main>
    <footer class="app-footer">
      <div class="container footer-inner">
        <div class="footer-brand">
          <span class="logo-icon">M</span>
          <span>Master</span>
          <p class="text-muted">{{ $t('footer.slogan') }}</p>
        </div>
        <div class="footer-links">
          <NuxtLink :to="localePath('/about')">{{ $t('footer.about') }}</NuxtLink>
          <NuxtLink :to="localePath('/faq')">{{ $t('footer.faq') }}</NuxtLink>
          <NuxtLink :to="localePath('/privacy')">{{ $t('footer.privacy') }}</NuxtLink>
          <NuxtLink :to="localePath('/terms')">{{ $t('footer.terms') }}</NuxtLink>
        </div>
        <p class="footer-copy text-muted">&copy; {{ new Date().getFullYear() }} Master. {{ $t('footer.rights') }}</p>
      </div>
    </footer>

    <!-- Mobile bottom navigation -->
    <MobileNav />

    <!-- Global toasts -->
    <ToastStack />

    <!-- Cookie consent (auto-respects DNT, stored in localStorage) -->
    <CookieConsent />

    <!-- In-app voice call overlay (mounted globally so it works on any page) -->
    <ClientOnly>
      <CallModal />
    </ClientOnly>
  </div>
</template>

<script setup lang="ts">
const { locale } = useI18n()
const localePath = useLocalePath()
const switchLocalePath = useSwitchLocalePath()
const route = useRoute()
const mobileMenu = ref(false)
const auth = useAuthStore()
const router = useRouter()
const { apiFetch } = useApi()

const masterAccepting = computed(() => auth.user?.master_profile?.is_accepting_orders)

onMounted(async () => {
  if (auth.user?.id) {
    const calls = useCallsStore()
    await calls.connect()
    useSse() // start SSE realtime stream
  }
})

watch(() => auth.user?.id, async (id) => {
  if (!id) return
  const calls = useCallsStore()
  await calls.connect()
  useSse()
})

async function toggleAccepting() {
  const newStatus = masterAccepting.value ? 'offline' : 'online'
  try {
    await apiFetch('/master/status', { method: 'PUT', body: { status: newStatus } })
    await auth.fetchUser()
  } catch {}
}

const availableLocales = [
  { code: 'az', label: 'AZ' },
  { code: 'ru', label: 'RU' },
  { code: 'en', label: 'EN' },
  { code: 'tr', label: 'TR' },
  { code: 'ar', label: 'AR' },
]

const currentLocale = computed(() => {
  const prefix = route.path.split('/')[1]
  return availableLocales.find(l => l.code === prefix)?.code || 'az'
})

function getLocalePath(code: string): string {
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

async function handleLogout() {
  await auth.logout()
  router.push(localePath('/'))
}
</script>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(255,255,255,0.95);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--gray-100);
}
.header-inner {
  display: flex;
  align-items: center;
  height: 64px;
  gap: 2rem;
}
.logo {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 700;
  font-size: 1.25rem;
}
.logo-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  background: var(--primary);
  color: #fff;
  border-radius: 10px;
  font-weight: 800;
  font-size: 1.125rem;
}
.nav-desktop { display: none; gap: 1.5rem; }
.nav-desktop a { font-weight: 500; font-size: 0.938rem; color: var(--gray-600); transition: color 0.2s; }
.nav-desktop a:hover { color: var(--primary); }
.header-actions { display: none; gap: 0.75rem; margin-left: auto; align-items: center; }
/* Accept orders switch */
.accept-switch {
  display: flex; align-items: center; gap: 0.5rem; cursor: pointer; user-select: none;
}
.accept-switch input { display: none; }
.switch-track {
  width: 36px; height: 20px; border-radius: 100px; background: var(--gray-300);
  position: relative; transition: background 0.25s;
}
.accept-switch.active .switch-track { background: #16a34a; }
.switch-thumb {
  position: absolute; top: 2px; left: 2px; width: 16px; height: 16px;
  border-radius: 50%; background: #fff; transition: transform 0.25s; box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}
.accept-switch.active .switch-thumb { transform: translateX(16px); }
.switch-label { font-size: 0.7rem; font-weight: 600; color: var(--gray-500); max-width: 80px; line-height: 1.2; }
.accept-switch.active .switch-label { color: #16a34a; }
.lang-switcher { display: flex; gap: 2px; background: var(--gray-100); border-radius: 6px; padding: 2px; }
.lang-btn { padding: 0.25rem 0.45rem; font-size: 0.7rem; font-weight: 600; color: var(--gray-500); border-radius: 4px; transition: all 0.15s; line-height: 1; }
.lang-btn:hover { color: var(--gray-800); }
.lang-btn.active { background: #fff; color: var(--primary); box-shadow: 0 1px 2px rgba(0,0,0,0.08); }
.mobile-menu-btn { display: flex; flex-direction: column; gap: 5px; margin-left: auto; padding: 8px; }
.mobile-menu-btn span { display: block; width: 22px; height: 2px; background: var(--gray-700); border-radius: 2px; }
.mobile-menu { display: flex; flex-direction: column; padding: 1rem; border-top: 1px solid var(--gray-100); }
.mobile-menu a { padding: 0.75rem 0; font-weight: 500; color: var(--gray-700); }
.mobile-menu hr { border: none; border-top: 1px solid var(--gray-100); margin: 0.5rem 0; }
.mobile-lang { display: flex; gap: 0.75rem; padding: 0.5rem 0; }
.mobile-lang a { font-size: 0.875rem; font-weight: 600; color: var(--gray-400); padding: 0.25rem 0.5rem; border-radius: 6px; }
.mobile-lang a.lang-active { color: var(--primary); background: var(--primary-light); }
.app-main { min-height: calc(100vh - 64px - 200px); }
.app-footer { background: var(--gray-50); border-top: 1px solid var(--gray-100); padding: 3rem 0 2rem; margin-top: 4rem; padding-bottom: 5rem; }
@media (min-width: 768px) { .app-footer { padding-bottom: 2rem; } }
.footer-inner { text-align: center; }
.footer-brand { display: flex; flex-direction: column; align-items: center; gap: 0.25rem; font-weight: 700; font-size: 1.125rem; margin-bottom: 1.5rem; }
.footer-brand p { font-size: 0.875rem; font-weight: 400; }
.footer-links { display: flex; flex-wrap: wrap; justify-content: center; gap: 1.5rem; margin-bottom: 1.5rem; }
.footer-links a { font-size: 0.875rem; color: var(--gray-500); }
.footer-links a:hover { color: var(--primary); }
.footer-copy { font-size: 0.813rem; }

@media (min-width: 768px) {
  .nav-desktop { display: flex; }
  .header-actions { display: flex; }
  .mobile-menu-btn { display: none; }
  .mobile-menu { display: none; }
}
</style>
