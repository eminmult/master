<template>
  <div class="map-picker">
    <div class="map-search">
      <span class="icon icon-sm">search</span>
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="$t('address.search_map')"
        @keydown.enter.prevent="searchAddress"
      />
      <button v-if="searchQuery" type="button" class="search-go" @click="searchAddress">
        <span class="icon icon-sm">arrow_forward</span>
      </button>
    </div>
    <div ref="mapEl" class="map-el"></div>
    <div v-if="selectedAddress" class="map-selected">
      <span class="icon icon-sm">location_on</span>
      <span>{{ selectedAddress }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  lat?: number | null
  lng?: number | null
}>()

const emit = defineEmits<{
  (e: 'update', data: { lat: number; lng: number; address: string }): void
}>()

const { t: $t } = useI18n()

const mapEl = ref<HTMLElement | null>(null)
const selectedAddress = ref('')
const searchQuery = ref('')

let map: any = null
let marker: any = null
let L: any = null

async function initMap() {
  if (!mapEl.value) return

  const mod = await import('leaflet')
  L = mod.default || mod

  if (!L || !L.map) return

  if (L.Icon?.Default?.prototype) {
    delete (L.Icon.Default.prototype as any)._getIconUrl
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
      iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
    })
  }

  const center: [number, number] = [props.lat || 40.4093, props.lng || 49.8671]
  map = L.map(mapEl.value).setView(center, 14)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap',
    maxZoom: 18,
  }).addTo(map)

  if (props.lat && props.lng) {
    placeMarker(props.lat, props.lng)
    reverseGeocode(props.lat, props.lng)
  }

  map.on('click', (e: any) => {
    placeMarker(e.latlng.lat, e.latlng.lng)
    reverseGeocode(e.latlng.lat, e.latlng.lng)
  })
}

function placeMarker(lat: number, lng: number) {
  if (!L || !map) return
  if (marker) {
    marker.setLatLng([lat, lng])
  } else {
    marker = L.marker([lat, lng], { draggable: true }).addTo(map)
    marker.on('dragend', () => {
      const pos = marker.getLatLng()
      reverseGeocode(pos.lat, pos.lng)
    })
  }
  map.setView([lat, lng], Math.max(map.getZoom(), 15))
}

async function reverseGeocode(lat: number, lng: number) {
  try {
    const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&accept-language=az`)
    const data = await res.json()
    const addr = data.display_name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`
    selectedAddress.value = addr
    emit('update', { lat, lng, address: addr })
  } catch {
    const addr = `${lat.toFixed(5)}, ${lng.toFixed(5)}`
    selectedAddress.value = addr
    emit('update', { lat, lng, address: addr })
  }
}

async function searchAddress() {
  if (!searchQuery.value.trim()) return
  try {
    const q = encodeURIComponent(searchQuery.value.trim())
    const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${q}&limit=1&countrycodes=az`)
    const results = await res.json()
    if (results.length) {
      const r = results[0]
      const lat = parseFloat(r.lat)
      const lng = parseFloat(r.lon)
      placeMarker(lat, lng)
      selectedAddress.value = r.display_name
      emit('update', { lat, lng, address: r.display_name })
    }
  } catch {}
}

onMounted(() => {
  if (!document.querySelector('link[href*="leaflet"]')) {
    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
    document.head.appendChild(link)
  }
  setTimeout(initMap, 300)
})

onUnmounted(() => {
  if (map) { map.remove(); map = null }
})
</script>

<style scoped>
.map-picker { border: 1px solid var(--gray-200); border-radius: var(--radius-sm); overflow: hidden; }
.map-search {
  display: flex; align-items: center; gap: 0.5rem;
  padding: 0.5rem 0.75rem; border-bottom: 1px solid var(--gray-100); background: var(--gray-50);
}
.map-search .icon { color: var(--gray-400); }
.map-search input { flex: 1; border: none; outline: none; background: transparent; font-size: 0.875rem; padding: 0.25rem 0; }
.search-go { color: var(--primary); padding: 0.25rem; }
.map-el { height: 250px; width: 100%; }
.map-selected {
  display: flex; align-items: flex-start; gap: 0.375rem;
  padding: 0.625rem 0.75rem; background: #f0fdf4; border-top: 1px solid #bbf7d0;
  font-size: 0.813rem; color: #166534; line-height: 1.4;
}
</style>
