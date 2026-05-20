export default defineNuxtRouteMiddleware(async (to) => {
  const auth = useAuthStore()
  const localePath = useLocalePath()

  if (!auth.isLoggedIn) {
    await auth.fetchUser()
  }

  if (!auth.isLoggedIn) {
    const redirect = to.fullPath && to.fullPath !== '/' ? to.fullPath : undefined
    return navigateTo({ path: localePath('/login'), query: redirect ? { redirect } : {} })
  }
})
