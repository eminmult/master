<template>
  <div class="hm-auth-page">
    <div class="hm-auth-glow-1"></div>
    <div class="hm-auth-glow-2"></div>

    <div class="hm-auth-card">
      <h1 class="hm-auth-title">{{ $t('auth.verify_phone_title') }}</h1>
      <p class="hm-auth-sub">{{ $t('auth.verify_phone_sub', { phone: auth.user?.phone || '' }) }}</p>

      <div v-if="done" class="hm-auth-info" style="background: rgba(34,197,94,.1); border-color: rgba(34,197,94,.3); color: #16a34a;">
        {{ $t('auth.verify_phone_success') }}
      </div>
      <div v-if="error" class="hm-auth-error">{{ error }}</div>

      <form v-if="!done" @submit.prevent="submit">
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.otp_code') }}</label>
          <input
            v-model="code"
            type="text"
            class="hm-form-input"
            inputmode="numeric"
            pattern="[0-9]{6}"
            maxlength="6"
            placeholder="123456"
            required
            autocomplete="one-time-code"
          />
        </div>
        <button type="submit" class="hm-auth-primary" :disabled="loading || code.length !== 6">
          {{ loading ? $t('common.loading') : $t('auth.verify_submit') }}
        </button>
      </form>

      <div v-if="!done" class="hm-auth-alt" style="margin-top: 16px;">
        <button type="button" class="hm-link-btn" :disabled="resending || cooldown > 0" @click="resend">
          {{ cooldown > 0 ? $t('auth.resend_in', { s: cooldown }) : $t('auth.resend_code') }}
        </button>
      </div>

      <div class="hm-auth-alt" style="margin-top: 24px;">
        <NuxtLink v-if="done" :to="localePath('/')" class="hm-auth-primary" style="display:inline-block; text-decoration:none;">
          {{ $t('common.continue') }}
        </NuxtLink>
        <NuxtLink v-else :to="localePath('/')">{{ $t('common.skip') }}</NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const auth = useAuthStore()

const code = ref('')
const loading = ref(false)
const resending = ref(false)
const error = ref('')
const done = ref(false)
const cooldown = ref(0)

let timer: any = null
function startCooldown(s: number) {
  cooldown.value = s
  clearInterval(timer)
  timer = setInterval(() => {
    cooldown.value--
    if (cooldown.value <= 0) clearInterval(timer)
  }, 1000)
}
onUnmounted(() => clearInterval(timer))

async function submit() {
  error.value = ''
  loading.value = true
  try {
    await apiFetch('/auth/phone/verify-otp', { method: 'POST', body: { code: code.value } })
    done.value = true
    auth.fetchUser()
  } catch (e: any) {
    error.value = e?.data?.message || $t('auth.invalid_code')
  } finally {
    loading.value = false
  }
}

async function resend() {
  error.value = ''
  resending.value = true
  try {
    await apiFetch('/auth/phone/request-otp', { method: 'POST' })
    startCooldown(60)
  } catch (e: any) {
    if (e?.data?.retry_after) startCooldown(e.data.retry_after)
    error.value = e?.data?.message || $t('auth.error_occurred')
  } finally {
    resending.value = false
  }
}
</script>

<style scoped>
.hm-link-btn { background: none; border: none; color: var(--hm-accent); cursor: pointer; font-size: 14px; padding: 0; }
.hm-link-btn:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
