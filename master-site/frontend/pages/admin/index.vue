<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <div>
              <h1>{{ $t('admin.title') }}</h1>
              <p class="hm-page-sub">{{ $t('admin.subtitle') }}</p>
            </div>
          </div>

          <div class="hm-services-grid" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
            <NuxtLink :to="localePath('/admin/users')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">group</span></div>
              <h3>{{ $t('admin.users') }}</h3>
              <p>{{ $t('admin.users_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/admin/orders')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">inventory_2</span></div>
              <h3>{{ $t('admin.orders') }}</h3>
              <p>{{ $t('admin.orders_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/admin/categories')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">folder</span></div>
              <h3>{{ $t('admin.categories') }}</h3>
              <p>{{ $t('admin.categories_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/admin/reviews')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">star</span></div>
              <h3>{{ $t('admin.reviews') }}</h3>
              <p>{{ $t('admin.reviews_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/admin/disputes')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">warning</span></div>
              <h3>{{ $t('admin.disputes') }}</h3>
              <p>{{ $t('admin.disputes_desc') }}</p>
            </NuxtLink>
            <NuxtLink :to="localePath('/admin/analytics')" class="hm-action-card">
              <div class="hm-action-card-ico"><span class="icon">analytics</span></div>
              <h3>{{ $t('admin.analytics') }}</h3>
              <p>{{ $t('admin.analytics_desc') }}</p>
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: ['auth', 'admin'] })
const { t: $t } = useI18n()
const localePath = useLocalePath()
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); letter-spacing: -0.4px; }
</style>
