<template>
  <Transition name="cc-fade">
    <div v-if="visible" class="cc-banner" role="dialog" aria-live="polite">
      <div class="cc-text">
        <strong>{{ $t('cookie.title') }}</strong>
        <p>{{ $t('cookie.body') }}
          <NuxtLink :to="localePath('/privacy')" class="cc-link">{{ $t('cookie.policy') }}</NuxtLink>
        </p>
      </div>
      <div class="cc-actions">
        <button type="button" class="cc-btn cc-btn-ghost" @click="reject">{{ $t('cookie.reject') }}</button>
        <button type="button" class="cc-btn cc-btn-primary" @click="accept">{{ $t('cookie.accept') }}</button>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
const localePath = useLocalePath()
const visible = ref(false)
const STORAGE_KEY = 'cookie_consent_v1'

onMounted(() => {
  // Respect Do Not Track — auto-set "rejected" without showing UI.
  const dnt = navigator.doNotTrack === '1' || (window as any).doNotTrack === '1'
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored) return
  if (dnt) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ choice: 'reject', at: new Date().toISOString(), via: 'dnt' }))
    return
  }
  visible.value = true
})

function accept() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ choice: 'accept', at: new Date().toISOString() }))
  visible.value = false
}
function reject() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ choice: 'reject', at: new Date().toISOString() }))
  visible.value = false
}
</script>

<style scoped>
.cc-banner {
  position: fixed;
  bottom: 16px;
  left: 16px;
  right: 16px;
  max-width: 720px;
  margin: 0 auto;
  background: var(--hm-bg-card, #1a1a1d);
  color: var(--hm-text, #e8e8e8);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.35);
  padding: 18px 22px;
  display: flex;
  gap: 16px;
  align-items: center;
  z-index: 9999;
}
@media (max-width: 640px) {
  .cc-banner { flex-direction: column; align-items: stretch; }
}
.cc-text strong { display: block; margin-bottom: 4px; }
.cc-text p { margin: 0; font-size: 13px; opacity: 0.8; line-height: 1.5; }
.cc-link { color: var(--hm-accent, #fbbf24); }
.cc-actions { display: flex; gap: 8px; flex-shrink: 0; }
.cc-btn {
  padding: 10px 18px;
  border-radius: 10px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: transparent;
  color: inherit;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
}
.cc-btn-primary { background: var(--hm-accent, #fbbf24); color: #111; border-color: transparent; }
.cc-btn-ghost { opacity: 0.7; }
.cc-btn:hover { opacity: 1; }
.cc-fade-enter-active, .cc-fade-leave-active { transition: opacity .2s, transform .2s; }
.cc-fade-enter-from, .cc-fade-leave-to { opacity: 0; transform: translateY(8px); }
</style>
