<template>
  <div class="hm-sc-wrap">
    <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm" @click="open = true">
      <span class="icon icon-sm">lightbulb</span>
      {{ $t('cat_sugg.suggest_btn') }}
    </button>

    <Transition name="hm-pop">
      <div v-if="open" class="hm-sc-overlay" @click.self="close">
        <div class="hm-sc-modal hm-popover">
          <div class="hm-popover-glow"></div>
          <h2>{{ $t('cat_sugg.suggest_title') }}</h2>
          <p class="hm-sc-sub">{{ $t('cat_sugg.suggest_desc') }}</p>

          <div v-if="submitted" class="hm-sc-done">
            <span class="icon">check_circle</span>
            <div>
              <strong>{{ $t('cat_sugg.submitted_title') }}</strong>
              <p>{{ $t('cat_sugg.submitted_desc') }}</p>
            </div>
          </div>

          <form v-else @submit.prevent="submit">
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('cat_sugg.field_name') }} *</label>
              <input v-model="form.name" type="text" class="hm-form-input" required maxlength="80" :placeholder="$t('cat_sugg.field_name_hint')" />
            </div>
            <div class="hm-form-group">
              <label class="hm-auth-label">{{ $t('cat_sugg.field_desc') }}</label>
              <textarea v-model="form.description" class="hm-form-textarea" rows="3" maxlength="500" :placeholder="$t('cat_sugg.field_desc_hint')"></textarea>
            </div>

            <div v-if="error" class="hm-auth-error">{{ error }}</div>

            <div class="hm-sc-actions">
              <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm" @click="close">{{ $t('common.cancel') }}</button>
              <button type="submit" class="hm-btn hm-btn-primary hm-btn-sm" :disabled="submitting">
                <span class="icon icon-sm">send</span>
                {{ submitting ? $t('common.loading') : $t('cat_sugg.submit') }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
const { t: $t } = useI18n()
const { apiFetch } = useApi()
const auth = useAuthStore()
const toast = useToast()

const open = ref(false)
const submitting = ref(false)
const submitted = ref(false)
const error = ref('')
const form = reactive({ name: '', description: '' })

function close() {
  open.value = false
  // Delay reset so the closing animation finishes first
  setTimeout(() => {
    submitted.value = false
    error.value = ''
    form.name = ''
    form.description = ''
  }, 300)
}

async function submit() {
  if (!auth.isLoggedIn) { error.value = $t('cat_sugg.login_required'); return }
  submitting.value = true
  error.value = ''
  try {
    await apiFetch('/category-suggestions', {
      method: 'POST',
      body: { name: form.name.trim(), description: form.description?.trim() || null },
    })
    submitted.value = true
    toast.success($t('cat_sugg.submitted_toast'))
  } catch (e: any) {
    error.value = e?.data?.message || $t('auth.error_occurred')
  } finally { submitting.value = false }
}
</script>

<style scoped>
.hm-sc-wrap { display: inline-block; }

.hm-sc-overlay {
  position: fixed; inset: 0;
  background: rgba(0, 0, 0, 0.65);
  display: flex; align-items: center; justify-content: center;
  padding: 20px; z-index: 1000;
  -webkit-backdrop-filter: blur(4px); backdrop-filter: blur(4px);
}
.hm-sc-modal {
  position: relative;
  width: min(460px, 100%);
  padding: 24px;
  margin: 0;
}
.hm-sc-modal h2 { font-size: 18px; font-weight: 700; color: var(--hm-text); margin: 0 0 4px; }
.hm-sc-sub { font-size: 13px; color: var(--hm-text-3); margin: 0 0 18px; line-height: 1.5; }
.hm-sc-actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 12px; }

.hm-sc-done {
  display: flex; gap: 14px; align-items: flex-start;
  padding: 16px;
  background: rgba(34,197,94,0.08);
  border: 1px solid rgba(34,197,94,0.3);
  border-radius: 12px;
}
.hm-sc-done .icon { font-size: 36px; color: #22c55e; }
.hm-sc-done strong { display: block; font-size: 14px; font-weight: 700; color: var(--hm-text); margin-bottom: 4px; }
.hm-sc-done p { font-size: 12.5px; color: var(--hm-text-2); margin: 0; line-height: 1.5; }
</style>
