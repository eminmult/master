import { addCollection } from '@iconify/vue'
import phosphor from '@iconify-json/ph/icons.json'

/**
 * Pre-register Phosphor icons so they render in SSR HTML
 * and avoid the flicker from async CDN loading.
 */
export default defineNuxtPlugin(() => {
  addCollection(phosphor as any)
})
