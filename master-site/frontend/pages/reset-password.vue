<template>
  <div class="hm-auth-page">
    <div class="hm-auth-glow-1"></div>
    <div class="hm-auth-glow-2"></div>

    <div class="hm-auth-card">
      <h1 class="hm-auth-title">{{ $t('auth.reset_title') }}</h1>
      <p class="hm-auth-sub">{{ $t('auth.reset_subtitle') }}</p>

      <div v-if="done" class="hm-auth-info">{{ $t('auth.reset_success') }}</div>
      <div v-if="error" class="hm-auth-error">{{ error }}</div>

      <form v-if="!done" @submit.prevent="submit">
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.phone_or_email') }}</label>
          <input v-model="form.login" type="text" class="hm-form-input" placeholder="+994..." required autocomplete="username" />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.reset_token') }}</label>
          <input v-model="form.token" type="text" class="hm-form-input" required />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.new_password') }}</label>
          <input v-model="form.password" type="password" class="hm-form-input" required autocomplete="new-password" />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.new_password_confirm') }}</label>
          <input v-model="form.password_confirmation" type="password" class="hm-form-input" required autocomplete="new-password" />
        </div>
        <button type="submit" class="hm-auth-primary" :disabled="loading">
          {{ loading ? $t('common.loading') : $t('auth.reset_submit') }}
        </button>
      </form>

      <div class="hm-auth-alt">
        <NuxtLink :to="localePath('/login')">{{ $t('auth.back_to_login') }}</NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'guest' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const route = useRoute()
const { apiFetch } = useApi()

const form = reactive({
  login: (route.query.login as string) || '',
  token: (route.query.token as string) || '',
  password: '',
  password_confirmation: '',
})
const loading = ref(false)
const error = ref('')
const done = ref(false)

async function submit() {
  error.value = ''
  if (form.password !== form.password_confirmation) {
    error.value = $t('auth.passwords_do_not_match')
    return
  }
  loading.value = true
  try {
    await apiFetch('/auth/reset-password', { method: 'POST', body: form })
    done.value = true
  } catch (e: any) {
    error.value = e?.data?.message || $t('auth.error_occurred')
  } finally {
    loading.value = false
  }
}
</script>
