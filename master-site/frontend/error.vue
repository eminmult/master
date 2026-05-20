<template>
  <div class="error-page">
    <div class="error-content">
      <span class="error-code">{{ error?.statusCode || 404 }}</span>
      <h1>{{ error?.statusCode === 404 ? 'Page not found' : 'Error' }}</h1>
      <p class="text-muted">{{ error?.message || 'Something went wrong' }}</p>
      <NuxtLink to="/" class="btn btn-primary mt-3">
        <span class="icon icon-sm">home</span> Home
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{ error: any }>()
</script>

<style scoped>
.error-page {
  min-height: 100vh; display: flex; align-items: center; justify-content: center;
  font-family: 'Inter', sans-serif; text-align: center; padding: 2rem;
}
.error-code { font-size: 6rem; font-weight: 900; color: var(--gray-200, #e5e7eb); line-height: 1; }
.error-content h1 { font-size: 1.5rem; font-weight: 700; margin-top: 0.5rem; }
.error-content p { margin-top: 0.5rem; }
</style>
