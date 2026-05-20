<template>
  <div v-if="history.length" class="timeline-card card">
    <h3><span class="icon icon-sm">timeline</span> {{ $t('orders.timeline') }}</h3>
    <div class="timeline">
      <div v-for="(item, i) in history" :key="i" class="tl-item">
        <div class="tl-dot" :class="i === history.length - 1 ? 'active' : ''"></div>
        <div class="tl-content">
          <strong>{{ $t('status.' + item.status) }}</strong>
          <span class="tl-time">{{ formatTime(item.created_at) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{ history: any[] }>()
const { t: $t } = useI18n()

const { formatShortDateTime: formatTime } = useFormatDate()
</script>

<style scoped>
.timeline-card h3 { display: flex; align-items: center; gap: 0.5rem; font-size: 0.938rem; font-weight: 600; margin-bottom: 1rem; }
.timeline { display: flex; flex-direction: column; gap: 0; padding-left: 0.5rem; }
.tl-item { display: flex; align-items: flex-start; gap: 0.75rem; position: relative; padding-bottom: 0.75rem; }
.tl-item:not(:last-child)::before {
  content: ''; position: absolute; left: 5px; top: 14px; bottom: 0; width: 2px; background: var(--gray-200);
}
.tl-dot { width: 12px; height: 12px; border-radius: 50%; background: var(--gray-300); flex-shrink: 0; margin-top: 3px; }
.tl-dot.active { background: var(--primary); }
.tl-content { display: flex; flex-direction: column; }
.tl-content strong { font-size: 0.813rem; }
.tl-time { font-size: 0.688rem; color: var(--gray-400); }
</style>
