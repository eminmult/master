// When the active i18n locale changes (user picks a new language from the
// header switcher), every `useAsyncData(...)` block in the app continues to
// serve its cached payload — the cache key doesn't include locale. The API
// returns data localised via the Accept-Language header (set in
// composables/useApi.ts), so the cached payload is now in the wrong language
// and the page often appears empty until a manual reload.
//
// Fix: watch the active locale and nuke every Nuxt asyncData cache entry on
// change, then trigger a refresh. clearNuxtData() drops the cache;
// refreshNuxtData() re-runs every active data block.

// dependsOn ensures the i18n plugin runs first so $i18n is on the nuxtApp.
// runWithContext keeps the Nuxt context attached for the refresh helpers
// (they look up the active app via getCurrentInstance under the hood and
// throw "Nuxt instance unavailable" / vue-i18n "26" when called bare from
// an async watcher).
export default defineNuxtPlugin({
  dependsOn: ['i18n:plugin'],
  setup(nuxtApp) {
    const i18n = nuxtApp.$i18n as any
    if (!i18n?.locale) return
    watch(i18n.locale, () => {
      nuxtApp.runWithContext(() => {
        clearNuxtData()
        refreshNuxtData()
        // Reset breadcrumb labels — pages re-publish them on the next setup
        // pass with the freshly-localised labels. Without this, the stale
        // English/Russian crumbs persist alongside the new locale's content.
        const trail = useState<any[] | null>('hm-breadcrumbs')
        trail.value = null
      })
    })
  },
})
