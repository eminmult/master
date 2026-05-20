<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="client" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <div>
              <h1>{{ $t('client.hello', { name: auth.user?.first_name }) }}</h1>
              <p class="hm-page-sub">{{ $t('client.what_to_do') }}</p>
            </div>
          </div>

          <div class="hm-dash-stats">
            <div class="hm-dash-stat">
              <div class="hm-dash-stat-v accent">{{ stats.active }}</div>
              <div class="hm-dash-stat-l">{{ $t('client.active_orders') }}</div>
            </div>
            <div class="hm-dash-stat">
              <div class="hm-dash-stat-v">{{ stats.completed }}</div>
              <div class="hm-dash-stat-l">{{ $t('masters.completed') }}</div>
            </div>
            <div class="hm-dash-stat">
              <div class="hm-dash-stat-v">{{ stats.total }}</div>
              <div class="hm-dash-stat-l">{{ $t('client.total_orders') }}</div>
            </div>
          </div>

          <div class="hm-services-grid" style="grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));">
            <NuxtLink :to="localePath('/client/new-order')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">add_circle</span></div>
              <h3>{{ $t('client.create_order') }}</h3>
              <p>{{ $t('client.new_order_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/client/orders')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">inventory_2</span></div>
              <h3>{{ $t('client.my_orders') }}</h3>
              <p>{{ $t('client.orders_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/masters')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">engineering</span></div>
              <h3>{{ $t('nav.masters') }}</h3>
              <p>{{ $t('masters.page_subtitle') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/client/profile')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">person</span></div>
              <h3>{{ $t('client.profile') }}</h3>
              <p>{{ $t('client.profile_desc') }}</p>
            </NuxtLink>
          </div>
        </div>
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

const stats = ref({ active: 0, completed: 0, total: 0 })

onMounted(async () => {
  try {
    const res = await apiFetch<{ orders: any[] }>('/orders?limit=100')
    const list = res.orders || []
    const active = list.filter((o: any) => !['completed', 'closed', 'canceled_by_client', 'canceled_by_master'].includes(o.status)).length
    const completed = list.filter((o: any) => ['completed', 'closed'].includes(o.status)).length
    stats.value = { active, completed, total: list.length }
  } catch {}
})
</script>
