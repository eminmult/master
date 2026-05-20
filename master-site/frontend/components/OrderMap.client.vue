<template>
  <div class="map-container">
    <div class="map-header">
      <span class="icon">map</span>
      <span>{{ $t('map.title') }}</span>
      <span v-if="eta" class="map-eta">
        <span class="icon icon-sm">schedule</span> ~{{ eta }} {{ $t('map.min') }}
      </span>
    </div>
    <div ref="mapEl" class="map-el"></div>
    <div v-if="locationError" class="map-error">
      <span class="icon icon-sm">location_off</span> {{ $t('map.location_unavailable') }}
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  orderId: number
  orderLat: number
  orderLng: number
  masterLat?: number | null
  masterLng?: number | null
  isMaster: boolean
  isTracking: boolean // on_the_way, arrived
}>()

const { t: $t } = useI18n()
const { apiFetch } = useApi()

const mapEl = ref<HTMLElement | null>(null)
const locationError = ref(false)
const eta = ref<number | null>(null)

let map: any = null
let masterMarker: any = null
let clientMarker: any = null
let routeLine: any = null
let geoWatchId: number | null = null
let L: any = null
let pollTimer: ReturnType<typeof setInterval> | null = null
let initTimer: ReturnType<typeof setTimeout> | null = null

async function initMap() {
  if (!mapEl.value) return

  try {
  // Dynamic import leaflet (client only)
  const mod = await import('leaflet')
  L = mod.default || mod
  if (!L || !L.map) { console.error('Leaflet not loaded'); return }

  // Fix leaflet default icons
  if (L.Icon?.Default?.prototype) {
    delete (L.Icon.Default.prototype as any)._getIconUrl
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
      iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
    })
  }

  const center = [props.orderLat || 40.4093, props.orderLng || 49.8671]
  map = L.map(mapEl.value).setView(center, 14)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap',
    maxZoom: 18,
  }).addTo(map)

  // Client/order location marker (red)
  const clientIcon = L.divIcon({
    className: 'custom-marker client-pin',
    html: '<div class="pin-inner pin-client"><span class="material-symbols-outlined">home</span></div>',
    iconSize: [40, 40],
    iconAnchor: [20, 40],
  })
  clientMarker = L.marker(center, { icon: clientIcon }).addTo(map)
    .bindPopup($t('map.client_location'))

  // Master marker (blue, will be updated)
  if (props.masterLat && props.masterLng) {
    addMasterMarker(props.masterLat, props.masterLng)
  }

  // If master — start sharing location
  if (props.isMaster && props.isTracking) {
    startGeoTracking()
  }

  // If client — poll master location
  if (!props.isMaster && props.isTracking) {
    pollMasterLocation()
    pollTimer = setInterval(pollMasterLocation, 3000)
  }

  } catch (e) {
    console.error('Map init error:', e)
  }
}

function addMasterMarker(lat: number, lng: number) {
  if (!L || !map) return

  const masterIcon = L.divIcon({
    className: 'custom-marker master-pin',
    html: '<div class="pin-inner pin-master"><span class="material-symbols-outlined">directions_car</span></div>',
    iconSize: [40, 40],
    iconAnchor: [20, 40],
  })

  if (masterMarker) {
    masterMarker.setLatLng([lat, lng])
  } else {
    masterMarker = L.marker([lat, lng], { icon: masterIcon }).addTo(map)
      .bindPopup($t('map.master_location'))
  }

  // Fit bounds to show both markers
  if (clientMarker) {
    const bounds = L.latLngBounds([clientMarker.getLatLng(), masterMarker.getLatLng()])
    map.fitBounds(bounds, { padding: [50, 50], maxZoom: 15 })
  }

  // Calculate ETA (rough estimate: 40 km/h average)
  if (clientMarker) {
    const dist = map.distance(masterMarker.getLatLng(), clientMarker.getLatLng()) // meters
    eta.value = Math.max(1, Math.round(dist / 1000 / 40 * 60)) // minutes
  }

  // Draw route line
  if (routeLine) map.removeLayer(routeLine)
  if (clientMarker) {
    routeLine = L.polyline([masterMarker.getLatLng(), clientMarker.getLatLng()], {
      color: '#2563eb',
      weight: 3,
      dashArray: '8, 8',
      opacity: 0.7,
    }).addTo(map)
  }
}

function startGeoTracking() {
  if (!navigator.geolocation) {
    locationError.value = true
    return
  }

  geoWatchId = navigator.geolocation.watchPosition(
    (pos) => {
      locationError.value = false
      const lat = pos.coords.latitude
      const lng = pos.coords.longitude

      addMasterMarker(lat, lng)

      // Send to server
      apiFetch('/master/location', {
        method: 'POST',
        body: { lat, lng },
      }).catch(() => {})
    },
    () => { locationError.value = true },
    { enableHighAccuracy: true, maximumAge: 5000, timeout: 10000 }
  )
}

async function pollMasterLocation() {
  try {
    const res = await apiFetch<{ order: any }>(`/orders/${props.orderId}`)
    const master = res.order?.master
    const profile = master?.master_profile
    if (profile?.current_lat && profile?.current_lng) {
      addMasterMarker(parseFloat(profile.current_lat), parseFloat(profile.current_lng))
    }
  } catch {}
}

onMounted(() => {
  // Load leaflet CSS
  if (!document.querySelector('link[href*="leaflet"]')) {
    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
    document.head.appendChild(link)
  }
  // Wait for CSS to load then init
  initTimer = setTimeout(initMap, 500)
})

onUnmounted(() => {
  if (initTimer) { clearTimeout(initTimer); initTimer = null }
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
  if (geoWatchId !== null) { navigator.geolocation.clearWatch(geoWatchId); geoWatchId = null }
  if (map) { map.remove(); map = null }
})
</script>

<style>
/* Global styles for map markers */
.custom-marker { background: none !important; border: none !important; }
.pin-inner {
  width: 36px; height: 36px; border-radius: 50% 50% 50% 0;
  display: flex; align-items: center; justify-content: center;
  transform: rotate(-45deg); box-shadow: 0 2px 6px rgba(0,0,0,0.3);
}
.pin-inner span { transform: rotate(45deg); font-size: 18px; color: #fff; }
.pin-client { background: #dc2626; }
.pin-master { background: #2563eb; }
</style>

<style scoped>
.map-container {
  border: 1px solid var(--gray-200);
  border-radius: var(--radius);
  overflow: hidden;
  background: #fff;
}
.map-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--gray-100);
  font-weight: 600;
  font-size: 0.875rem;
  background: var(--gray-50);
}
.map-eta {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.813rem;
  color: var(--primary);
  font-weight: 700;
}
.map-el {
  height: 350px;
  width: 100%;
}
.map-error {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.625rem;
  background: #fef3c7;
  color: #92400e;
  font-size: 0.75rem;
}
</style>
