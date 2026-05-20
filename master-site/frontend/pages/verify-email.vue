<template>
  <div class="hm-auth-page">
    <div class="hm-auth-glow-1"></div>
    <div class="hm-auth-glow-2"></div>

    <div class="hm-auth-card">
      <h1 class="hm-auth-title">{{ $t('auth.verify_email_title') }}</h1>

      <div v-if="state === 'pending'" class="hm-auth-info">
        <span class="icon">hourglass_top</span>
        {{ $t('auth.verify_email_checking') }}
      </div>

      <div v-if="state === 'success'" class="hm-auth-info" style="background: rgba(34,197,94,.1); border-color: rgba(34,197,94,.3); color: #16a34a;">
        <span class="icon">check_circle</span>
        {{ $t('auth.verify_email_success') }}
      </div>

      <div v-if="state === 'error'" class="hm-auth-error">
        <span class="icon">error</span>
        {{ error || $t('auth.verify_email_error') }}
      </div>

      <div class="hm-auth-alt" style="margin-top: 24px;">
        <NuxtLink v-if="state === 'success'" :to="localePath('/')" class="hm-auth-primary" style="display:inline-block; text-decoration:none;">
          {{ $t('common.continue') }}
        </NuxtLink>
        <NuxtLink v-else :to="localePath('/login')">{{ $t('auth.back_to_login') }}</NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const route = useRoute()
const { apiFetch } = useApi()
const auth = useAuthStore()

const state = ref<'pending' | 'success' | 'error'>('pending')
const error = ref('')

onMounted(async () => {
  const token = route.query.token as string | undefined
  const userId = route.query.user_id as string | undefined

  if (!token || !userId) {
    state.value = 'error'
    error.value = $t('auth.verify_email_missing_params')
    return
  }

  try {
    await apiFetch('/auth/verify-email', {
      method: 'POST',
      body: { token, user_id: Number(userId) },
    })
    state.value = 'success'
    if (auth.isLoggedIn) auth.fetchUser()
  } catch (e: any) {
    state.value = 'error'
    error.value = e?.data?.message || ''
  }
})
</script>

<style scoped>
.hm-auth-info { display: flex; gap: 10px; align-items: center; padding: 14px 16px; }
.icon { font-size: 22px; }
</style>
