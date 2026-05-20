<template>
  <div v-if="banner" class="sub-banner" :class="`sub-banner-${banner.tone}`">
    <div class="sub-banner-icon"><span class="icon">{{ banner.icon }}</span></div>
    <div class="sub-banner-text">
      <strong>{{ banner.title }}</strong>
      <p>{{ banner.body }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
const auth = useAuthStore()
const { t } = useI18n()

const banner = computed(() => {
  const sub = auth.user?.subscription
  if (!sub) return null

  // Inactive — gate already triggered server-side; tell master what to do.
  if (sub.required && !sub.can_operate) {
    return {
      tone: 'danger',
      icon: 'lock',
      title: t('subscription.inactive_title'),
      body: t('subscription.inactive_body'),
    }
  }

  // Free-launch period — show grace info so masters know it ends.
  if (!sub.required && sub.free_launch_until) {
    return {
      tone: 'info',
      icon: 'celebration',
      title: t('subscription.free_title'),
      body: t('subscription.free_body', { until: sub.free_launch_until }),
    }
  }

  // Paid + expiring soon (<=7d).
  if (sub.expires_at) {
    const ms = new Date(sub.expires_at).getTime() - Date.now()
    const days = Math.ceil(ms / 86400000)
    if (days >= 0 && days <= 7) {
      return {
        tone: 'warning',
        icon: 'schedule',
        title: t('subscription.expiring_title'),
        body: t('subscription.expiring_body', { days }),
      }
    }
  }

  return null
})
</script>

<style scoped>
.sub-banner {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  padding: 14px 16px;
  border-radius: 12px;
  margin-bottom: 16px;
  border: 1px solid;
}
.sub-banner-icon { font-size: 20px; line-height: 1; padding-top: 2px; }
.sub-banner-text strong { display: block; margin-bottom: 2px; }
.sub-banner-text p { margin: 0; font-size: 13px; opacity: 0.85; }

.sub-banner-info { background: rgba(60, 130, 220, 0.08); border-color: rgba(60, 130, 220, 0.25); color: #3c82dc; }
.sub-banner-warning { background: rgba(220, 160, 40, 0.10); border-color: rgba(220, 160, 40, 0.30); color: #b87a18; }
.sub-banner-danger { background: rgba(220, 60, 60, 0.10); border-color: rgba(220, 60, 60, 0.30); color: #c73838; }
</style>
