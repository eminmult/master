<template>
  <div class="hm-auth-page">
    <div class="hm-auth-glow-1"></div>
    <div class="hm-auth-glow-2"></div>

    <div class="hm-auth-card">
      <h1 class="hm-auth-title">{{ $t('auth.login_title') }}</h1>
      <p class="hm-auth-sub">{{ $t('auth.login_subtitle') }}</p>

      <div v-if="error" class="hm-auth-error">{{ error }}</div>

      <form @submit.prevent="handleLogin">
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.phone_or_email') }}</label>
          <input v-model="form.login" type="text" class="hm-form-input" placeholder="+994..." required autocomplete="username" />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.password') }}</label>
          <input v-model="form.password" type="password" class="hm-form-input" required autocomplete="current-password" />
        </div>
        <button type="submit" class="hm-auth-primary" :disabled="loading">
          {{ loading ? $t('auth.logging_in') : $t('auth.login_title') }}
        </button>
      </form>

      <div class="hm-auth-alt" style="text-align:center;margin-top:14px">
        <NuxtLink :to="localePath('/forgot-password')" style="color:var(--hm-text-3);font-size:13px">
          {{ $t('auth.forgot_password') }}
        </NuxtLink>
      </div>

      <div class="hm-or">{{ $t('auth.no_account_short') }}</div>

      <div class="hm-role-pick">
        <NuxtLink :to="{ path: localePath('/register'), query: route.query.redirect ? { redirect: route.query.redirect } : {} }" class="hm-role-card">
          <span class="hm-role-icon"><span class="icon">person</span></span>
          <span class="hm-role-title">{{ $t('auth.role_client_title') }}</span>
          <span class="hm-role-desc">{{ $t('auth.role_client_desc') }}</span>
        </NuxtLink>
        <NuxtLink :to="{ path: localePath('/register/master'), query: route.query.redirect ? { redirect: route.query.redirect } : {} }" class="hm-role-card">
          <span class="hm-role-icon hm-role-icon-accent"><span class="icon">handyman</span></span>
          <span class="hm-role-title">{{ $t('auth.role_master_title') }}</span>
          <span class="hm-role-desc">{{ $t('auth.role_master_desc') }}</span>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'guest' })

const { t: $t } = useI18n()
const localePath = useLocalePath()
const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

const form = reactive({ login: '', password: '' })
const loading = ref(false)
const error = ref('')

function safeRedirect(): string | null {
  const raw = route.query.redirect
  if (typeof raw !== 'string') return null
  // Prevent open-redirect: only accept same-origin relative paths
  if (!raw.startsWith('/') || raw.startsWith('//')) return null
  return raw
}

async function handleLogin() {
  loading.value = true
  error.value = ''
  try {
    const user = await auth.login(form.login, form.password)
    const target = safeRedirect()
    if (target) {
      router.push(target)
      return
    }
    if (user.role === 'master') router.push(localePath('/master'))
    else if (user.role === 'admin') router.push(localePath('/admin'))
    else router.push(localePath('/client'))
  } catch (e: any) {
    error.value = e?.data?.message || $t('auth.error_occurred')
  } finally {
    loading.value = false
  }
}
</script>
