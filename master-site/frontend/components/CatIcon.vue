<template>
  <svg
    v-if="iconData"
    class="cat-icon-svg"
    :viewBox="`0 0 ${iconData.width} ${iconData.height}`"
    width="1em"
    height="1em"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
    role="img"
    v-html="iconData.body"
  />
  <span v-else-if="isEmoji" class="cat-icon-emoji" aria-hidden="true">{{ icon }}</span>
  <span v-else class="icon cat-icon-material" aria-hidden="true">{{ icon || fallback }}</span>
</template>

<script setup lang="ts">
import { getIcon } from '@iconify/vue'

const props = defineProps<{
  icon?: string | null
  fallback?: string
}>()

const fallback = computed(() => props.fallback || 'category')

// Iconify identifiers contain a `:` (e.g. "ph:wrench")
// We resolve the icon synchronously via getIcon() — requires the collection to be
// pre-registered via the /plugins/iconify.ts plugin (runs on both SSR and client).
const iconData = computed(() => {
  const key = props.icon
  if (!key || !key.includes(':')) return null
  const data = getIcon(key)
  if (!data) return null
  return {
    body: data.body,
    width: data.width ?? 24,
    height: data.height ?? 24,
  }
})

// Short strings are probably emoji fallbacks stored on old categories
const isEmoji = computed(() => {
  if (!props.icon || props.icon.includes(':')) return false
  return props.icon.length <= 2 && /\p{Emoji}/u.test(props.icon)
})
</script>

<style scoped>
.cat-icon-svg {
  display: inline-block;
  vertical-align: -0.125em;
  fill: currentColor;
  color: inherit;
}
.cat-icon-emoji { font-size: 1em; }
.cat-icon-material { font-size: 1em; }
</style>
