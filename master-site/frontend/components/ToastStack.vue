<template>
  <Teleport to="body">
    <div class="toast-stack" aria-live="polite">
      <TransitionGroup name="toast">
        <div
          v-for="t in toasts"
          :key="t.id"
          class="toast"
          :class="'toast-' + t.type"
          role="status"
        >
          <span class="icon icon-sm">{{ iconFor(t.type) }}</span>
          <span class="toast-text">{{ t.text }}</span>
          <button class="toast-close" @click="dismiss(t.id)" type="button" aria-label="close">
            <span class="icon icon-sm">close</span>
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const { toasts, dismiss } = useToast()

function iconFor(type: string) {
  if (type === 'success') return 'check_circle'
  if (type === 'error') return 'error'
  return 'info'
}
</script>

<style scoped>
.toast-stack {
  position: fixed;
  top: 1rem;
  right: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  z-index: 2000;
  max-width: calc(100vw - 2rem);
}
[dir="rtl"] .toast-stack { right: auto; left: 1rem; }

.toast {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.75rem 1rem;
  border-radius: var(--radius-sm);
  background: #fff;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  border: 1px solid var(--gray-200);
  min-width: 280px;
  max-width: 420px;
  font-size: 0.875rem;
  color: var(--gray-800);
}
.toast-success { border-color: #bbf7d0; background: #f0fdf4; color: #166534; }
.toast-error   { border-color: #fecaca; background: #fef2f2; color: #991b1b; }
.toast-info    { border-color: #bfdbfe; background: #eff6ff; color: #1e40af; }

.toast-text { flex: 1; line-height: 1.4; }

.toast-close {
  border: 0;
  background: transparent;
  color: inherit;
  opacity: 0.6;
  cursor: pointer;
  padding: 0;
  display: flex;
}
.toast-close:hover { opacity: 1; }

.toast-enter-active, .toast-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.toast-enter-from { opacity: 0; transform: translateX(40px); }
.toast-leave-to   { opacity: 0; transform: translateX(40px); }
[dir="rtl"] .toast-enter-from,
[dir="rtl"] .toast-leave-to { transform: translateX(-40px); }
</style>
