<template>
  <div class="hm-auth-page">
    <div class="hm-auth-glow-1"></div>
    <div class="hm-auth-glow-2"></div>

    <div class="hm-auth-card" style="width:480px">
      <h1 class="hm-auth-title">{{ $t('auth.register_client_title') }}</h1>
      <p class="hm-auth-sub">{{ $t('auth.register_client_subtitle') }}</p>

      <div v-if="error" class="hm-auth-error">{{ error }}</div>

      <form @submit.prevent="handleRegister">
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.first_name') }} *</label>
          <input v-model="form.first_name" type="text" class="hm-form-input" required />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.last_name') }}</label>
          <input v-model="form.last_name" type="text" class="hm-form-input" />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.phone') }} *</label>
          <input v-model="form.phone" type="tel" class="hm-form-input" placeholder="+994..." required />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.email') }}</label>
          <input v-model="form.email" type="email" class="hm-form-input" />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.password') }} *</label>
          <input v-model="form.password" type="password" class="hm-form-input" required minlength="8" pattern="(?=.*[A-Za-zA-zŞşÇçĞğİıÖöÜüƏəА-Яа-я])(?=.*\d).{8,}" title="At least 8 characters with letters and digits" autocomplete="new-password" />
        </div>
        <div class="hm-form-group">
          <label class="hm-auth-label">{{ $t('auth.password_confirm') }} *</label>
          <input v-model="form.password_confirmation" type="password" class="hm-form-input" required autocomplete="new-password" />
        </div>
        <button type="submit" class="hm-auth-primary" :disabled="loading">
          {{ loading ? $t('auth.registering') : $t('nav.register') }}
        </button>
      </form>

      <div class="hm-auth-alt">
        {{ $t('auth.have_account') }}
        <NuxtLink :to="{ path: localePath('/login'), query: route.query.redirect ? { redirect: route.query.redirect } : {} }">{{ $t('nav.login') }}</NuxtLink>
      </div>

      <div class="hm-role-switch">
        <div class="hm-role-switch-head">{{ $t('auth.role_switch_master_q') }}</div>
        <NuxtLink :to="{ path: localePath('/register/master'), query: route.query.redirect ? { redirect: route.query.redirect } : {} }" class="hm-role-switch-card">
          <span class="hm-role-icon hm-role-icon-accent"><span class="icon">handyman</span></span>
          <span class="hm-role-switch-body">
            <span class="hm-role-title">{{ $t('auth.role_master_title') }}</span>
            <span class="hm-role-desc">{{ $t('auth.role_master_desc') }}</span>
          </span>
          <span class="icon hm-role-switch-arrow">chevron_right</span>
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

const form = reactive({ first_name: '', last_name: '', phone: '', email: '', password: '', password_confirmation: '' })
const loading = ref(false)
const error = ref('')

function safeRedirect(): string | null {
  const raw = route.query.redirect
  if (typeof raw !== 'string') return null
  if (!raw.startsWith('/') || raw.startsWith('//')) return null
  return raw
}

async function handleRegister() {
  loading.value = true; error.value = ''
  try {
    await auth.registerClient(form)
    const target = safeRedirect()
    router.push(target || localePath('/client'))
  } catch (e: any) {
    error.value = e?.data?.errors ? Object.values(e.data.errors).flat().join('. ') : (e?.data?.message || $t('auth.error_occurred'))
  } finally { loading.value = false }
}
</script>
