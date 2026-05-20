// Keeps <html lang dir> in sync with the active i18n locale. SSR sees the
// correct values on first paint (good for Google's lang detection + RTL
// CSS for AR), client side updates them when the user switches languages.

const LOCALE_DIR: Record<string, 'ltr' | 'rtl'> = {
  az: 'ltr',
  ru: 'ltr',
  en: 'ltr',
  tr: 'ltr',
  ar: 'rtl',
}

export default defineNuxtPlugin({
  // Run after the @nuxtjs/i18n plugin (which sets up the composable) so the
  // calls below find a valid setup context.
  dependsOn: ['i18n:plugin'],
  setup() {
    const nuxtApp = useNuxtApp()
    const i18n = nuxtApp.$i18n as any
    useHead(() => ({
      htmlAttrs: {
        lang: i18n.locale.value,
        dir: LOCALE_DIR[i18n.locale.value] || 'ltr',
      },
    }))
  },
})
