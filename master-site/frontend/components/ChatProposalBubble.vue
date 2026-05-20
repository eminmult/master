<template>
  <div class="cpb" :class="'cpb-' + payload._type">
    <div v-if="payload._type === 'proposal'" class="cpb-body">
      <span class="icon icon-sm">description</span>
      <span>{{ $t('orders.chat_proposal_label') }}:</span>
      <strong v-if="payload.date">{{ payload.date }}</strong>
      <strong v-if="payload.price">{{ payload.price }} AZN</strong>
    </div>
    <div v-else-if="payload._type === 'confirmed'" class="cpb-body">
      <span class="icon icon-sm">check_circle</span>
      <span>{{ $t('orders.chat_confirmed_label') }}</span>
    </div>
    <div v-else-if="payload._type === 'rejected'" class="cpb-body">
      <span class="icon icon-sm">block</span>
      <span>{{ $t('orders.chat_rejected_label') }}</span>
    </div>
    <div v-else-if="payload._type === 'callout_paid'" class="cpb-body">
      <span class="icon icon-sm">payments</span>
      <span>{{ $t('orders.chat_callout_paid_label') }}</span>
      <strong v-if="payload.amount">{{ payload.amount }} {{ payload.currency || 'AZN' }}</strong>
    </div>
  </div>
</template>

<script setup lang="ts">
const { t: $t } = useI18n()
defineProps<{ payload: any }>()
</script>

<style scoped>
.cpb {
  display: inline-block;
  margin: 4px 0;
  padding: 8px 12px;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 500;
  line-height: 1.4;
  border: 1px solid var(--hm-border);
  background: var(--hm-bg-2);
}
.cpb-body {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.cpb-body .icon { color: var(--hm-accent); }
.cpb-body strong { font-weight: 700; color: var(--hm-text); }
.cpb-proposal { border-color: var(--hm-accent); background: rgba(255,255,0,0.06); }
:global(html.theme-light) .cpb-proposal { background: rgba(176,127,0,0.08); }
.cpb-confirmed { border-color: rgba(34,197,94,.4); background: rgba(34,197,94,0.08); color: #22c55e; }
.cpb-confirmed .icon { color: #22c55e; }
.cpb-rejected { border-color: rgba(239,68,68,.3); background: rgba(239,68,68,0.06); color: #ef4444; }
.cpb-rejected .icon { color: #ef4444; }
</style>
