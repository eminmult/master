export default defineNuxtRouteMiddleware(async () => {
  const auth = useAuthStore()
  const localePath = useLocalePath()

  if (!auth.isLoggedIn) {
    await auth.fetchUser()
  }

  if (!auth.isLoggedIn) {
    return navigateTo(localePath('/login'))
  }

  if (!auth.isAdmin) {
    return navigateTo(localePath('/'))
  }
})
