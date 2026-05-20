/**
 * Server-Sent Events client for master.gasimov.az realtime relay.
 *
 * Why SSE and not WebSocket: Cloudflare Flexible SSL silently downgrades WSS
 * → HTTP on the proxied apex (mixed-content blocks the connection). SSE is
 * plain HTTPS streaming and survives the CF tier untouched.
 *
 * The composable is a singleton across the app — multiple `useSse()` callers
 * subscribe to the same underlying EventSource and share the parsed event bus.
 */

interface RealtimeEvent {
  type: string
  scope?: string
  scope_id?: number
  message?: any
  [k: string]: any
}

let es: EventSource | null = null
let lastToken: string | null = null
let reconnectTimer: ReturnType<typeof setTimeout> | null = null
let reconnectDelay = 1000
const listeners = new Set<(e: RealtimeEvent) => void>()

function connect(token: string) {
  if (typeof window === 'undefined') return
  if (es && lastToken === token) return
  disconnect()
  lastToken = token
  // Always hits the main domain — SSE works fine through CF Flexible. No
  // need for the realtime.gasimov.az subdomain workaround used for WebSocket.
  const url = `/sse/stream?token=${encodeURIComponent(token)}`
  try {
    es = new EventSource(url, { withCredentials: false })
  } catch (_) {
    scheduleReconnect()
    return
  }
  es.onopen = () => { reconnectDelay = 1000 }
  es.onmessage = (ev) => {
    if (!ev.data) return
    try {
      const j = JSON.parse(ev.data) as RealtimeEvent
      listeners.forEach((fn) => { try { fn(j) } catch (_) {} })
    } catch (_) {}
  }
  es.onerror = () => {
    if (es?.readyState === EventSource.CLOSED) scheduleReconnect()
  }
}

function scheduleReconnect() {
  if (reconnectTimer) return
  const delay = reconnectDelay
  reconnectDelay = Math.min(reconnectDelay * 2, 30000)
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null
    if (lastToken) connect(lastToken)
  }, delay)
}

function disconnect() {
  if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null }
  if (es) { try { es.close() } catch (_) {} es = null }
}

export function useSse() {
  if (typeof window !== 'undefined') {
    const auth = useAuthStore()
    const { authToken } = useApi()
    const tok = authToken.value
    if (auth.user && tok && tok !== lastToken) {
      connect(tok)
    }
    if (!auth.user && es) {
      disconnect()
    }
  }
  return {
    onEvent(fn: (e: RealtimeEvent) => void): () => void {
      listeners.add(fn)
      return () => listeners.delete(fn)
    },
  }
}
