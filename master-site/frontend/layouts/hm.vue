<template>
  <div class="hm-app">
    <HmSiteSchema />
    <HmHeader />
    <HmBreadcrumbs />
    <main class="hm-main">
      <slot />
    </main>
    <HmFooter />
    <ToastStack />
    <ClientOnly>
      <CallModal />
    </ClientOnly>
  </div>
</template>

<script setup lang="ts">
const theme = useHmTheme()
const auth = useAuthStore()

onMounted(async () => {
  theme.init()
  if (auth.user?.id) {
    const calls = useCallsStore()
    await calls.connect()
    useSse()
  }
})

watch(() => auth.user?.id, async (id) => {
  if (!id) return
  const calls = useCallsStore()
  await calls.connect()
  useSse()
})
</script>

<style>
.hm-main { display: block; }
</style>
