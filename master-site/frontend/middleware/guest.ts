export default defineNuxtRouteMiddleware(async () => {
  const auth = useAuthStore()
  const localePath = useLocalePath()

  if (!auth.isLoggedIn) {
    await auth.fetchUser()
  }

  if (auth.isLoggedIn) {
    if (auth.isMaster) return navigateTo(localePath('/master'))
    if (auth.isAdmin) return navigateTo(localePath('/admin'))
    return navigateTo(localePath('/client'))
  }
})
