<template>
  <NuxtLayout>
    <NuxtPage :transition="{ name: 'page', mode: 'out-in' }" />
  </NuxtLayout>
</template>

<script setup lang="ts">
useHead({ htmlAttrs: { class: 'theme-light' } })
</script>

<style>
.page-enter-active { animation: fadeIn 0.2s ease; }
.page-leave-active { animation: fadeIn 0.15s ease reverse; }
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
