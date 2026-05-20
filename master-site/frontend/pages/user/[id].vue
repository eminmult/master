<script setup lang="ts">
// Legacy /user/{id} URL — fetch the canonical slug and 301 to /master/{slug}.
const route = useRoute()
const localePath = useLocalePath()
const { apiFetch } = useApi()
const id = String(route.params.id || '')
let slug = id
try {
  const res = await apiFetch<{ profile: { slug?: string } }>(`/users/${id}/profile`)
  if (res?.profile?.slug) slug = res.profile.slug
} catch { /* keep id as fallback so /master/{id} still resolves */ }
await navigateTo(localePath('/master/' + slug), { redirectCode: 301 })
</script>
