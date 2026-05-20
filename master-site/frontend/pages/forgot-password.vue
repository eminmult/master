<template>
  <div class="hm-auth-page">
    <div class="hm-auth-glow-1"></div>
    <div class="hm-auth-glow-2"></div>

    <div class="hm-auth-card">
      <h1 class="hm-auth-title">{{ $t('auth.forgot_title') }}</h1>
      <p class="hm-auth-sub">{{ $t('auth.forgot_subtitle') }}</p>

      <div v-if="sent" class="hm-auth-info">{{ $t('auth.forgot_sent') }}</div>
      <div v-if="error" class="hm-auth-error">{{ error }}</div>

      <form v-if="!sent" @submit.prevent="submit">
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.phone_or_email') }}</label>
          <input v-model="login" type="text" class="hm-form-input" placeholder="+994..." required autocomplete="username" />
        </div>
        <button type="submit" class="hm-auth-primary" :disabled="loading">
          {{ loading ? $t('common.loading') : $t('auth.forgot_submit') }}
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
const { apiFetch } = useApi()

const login = ref('')
const loading = ref(false)
const error = ref('')
const sent = ref(false)

async function submit() {
  loading.value = true
  error.value = ''
  try {
    await apiFetch('/auth/forgot-password', { method: 'POST', body: { login: login.value } })
    sent.value = true
  } catch (e: any) {
    error.value = e?.data?.message || $t('auth.error_occurred')
  } finally {
    loading.value = false
  }
}
</script>
