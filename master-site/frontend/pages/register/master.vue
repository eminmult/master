<template>
  <div class="hm-auth-page">
    <div class="hm-auth-glow-1"></div>
    <div class="hm-auth-glow-2"></div>

    <div class="hm-auth-card" style="width:560px">
      <div v-if="registered" style="text-align:center">
        <span class="icon" style="font-size:48px;color:var(--hm-accent)">check_circle</span>
        <h1 class="hm-auth-title" style="margin-top:12px">{{ $t('auth.master_registered_title') }}</h1>
        <p class="hm-auth-sub">{{ $t('auth.master_registered_desc') }}</p>
        <NuxtLink :to="registeredTarget" class="hm-auth-primary" style="display:flex;text-decoration:none">
          {{ $t('auth.go_to_dashboard') }}
        </NuxtLink>
      </div>

      <template v-else>
        <h1 class="hm-auth-title">{{ $t('auth.register_master_title') }}</h1>
        <p class="hm-auth-sub">{{ $t('auth.register_master_subtitle') }}</p>

        <div v-if="error" class="hm-auth-error">{{ error }}</div>

        <form @submit.prevent="handleRegister">
          <div class="hm-form-row">
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('auth.first_name') }} *</label>
              <input v-model="form.first_name" type="text" class="hm-form-input" required />
            </div>
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('auth.last_name') }} *</label>
              <input v-model="form.last_name" type="text" class="hm-form-input" required />
            </div>
          </div>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('auth.phone') }} *</label>
            <input v-model="form.phone" type="tel" class="hm-form-input" placeholder="+994..." required />
          </div>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('auth.email') }} *</label>
            <input v-model="form.email" type="email" class="hm-form-input" required />
          </div>
          <div class="hm-form-row">
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('auth.password') }} *</label>
              <input v-model="form.password" type="password" class="hm-form-input" required minlength="8" pattern="(?=.*[A-Za-zA-zŞşÇçĞğİıÖöÜüƏəА-Яа-я])(?=.*\d).{8,}" title="At least 8 characters with letters and digits" autocomplete="new-password" />
            </div>
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('auth.password_confirm') }} *</label>
              <input v-model="form.password_confirmation" type="password" class="hm-form-input" required autocomplete="new-password" />
            </div>
          </div>
          <div class="hm-form-row">
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('auth.city') }} *</label>
              <input v-model="form.city" type="text" class="hm-form-input" placeholder="Bakı" required />
            </div>
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('auth.district') }}</label>
              <input v-model="form.district" type="text" class="hm-form-input" />
            </div>
          </div>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('auth.experience') }} *</label>
            <input v-model.number="form.experience_years" type="number" class="hm-form-input" min="0" max="50" required />
          </div>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('auth.about_you') }} *</label>
            <textarea v-model="form.description" class="hm-form-textarea" rows="4" :placeholder="$t('auth.about_placeholder')" required></textarea>
          </div>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('auth.select_categories') }} * ({{ $t('auth.select_min_one') }})</label>
            <div v-if="categories.length" class="hm-cat-chips">
              <label v-for="cat in categories" :key="cat.id" class="hm-cat-chip" :class="{ active: form.category_ids.includes(cat.id) }">
                <input type="checkbox" :value="cat.id" v-model="form.category_ids" hidden />
                <CatIcon :icon="cat.icon_url" fallback="build" /> {{ cat.name }}
              </label>
            </div>
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
          <div class="hm-role-switch-head">{{ $t('auth.role_switch_client_q') }}</div>
          <NuxtLink :to="{ path: localePath('/register'), query: route.query.redirect ? { redirect: route.query.redirect } : {} }" class="hm-role-switch-card">
            <span class="hm-role-icon"><span class="icon">person</span></span>
            <span class="hm-role-switch-body">
              <span class="hm-role-title">{{ $t('auth.role_client_title') }}</span>
              <span class="hm-role-desc">{{ $t('auth.role_client_desc') }}</span>
            </span>
            <span class="icon hm-role-switch-arrow">chevron_right</span>
          </NuxtLink>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'guest' })
const { t: $t } = useI18n()
const localePath = useLocalePath()
const auth = useAuthStore()
const route = useRoute()
const { apiFetch } = useApi()

const form = reactive({
  first_name: '', last_name: '', phone: '', email: '',
  password: '', password_confirmation: '',
  city: '', district: '', experience_years: 1, description: '',
  category_ids: [] as number[],
})
const loading = ref(false)
const registered = ref(false)
const error = ref('')
const categories = ref<any[]>([])

const registeredTarget = computed(() => {
  const raw = route.query.redirect
  if (typeof raw === 'string' && raw.startsWith('/') && !raw.startsWith('//')) return raw
  return localePath('/master')
})

onMounted(async () => {
  try {
    const res = await apiFetch<{ categories: any[] }>('/categories')
    categories.value = res.categories
  } catch {}
})

async function handleRegister() {
  if (form.category_ids.length === 0) { error.value = $t('auth.select_at_least_one'); return }
  loading.value = true; error.value = ''
  try { await auth.registerMaster(form); registered.value = true }
  catch (e: any) { error.value = e?.data?.errors ? Object.values(e.data.errors).flat().join('. ') : (e?.data?.message || $t('auth.error_occurred')) }
  finally { loading.value = false }
}
</script>
