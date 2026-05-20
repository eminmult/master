export default defineNuxtPlugin(async () => {
  const auth = useAuthStore()

  // On first load (SSR or client), try to fetch user from token
  if (!auth.isLoggedIn) {
    await auth.fetchUser()
  }
})
