// Real-User Monitoring for Core Web Vitals (LCP, INP, CLS, TTFB, FCP).
// Beacons each metric to /api/v1/cwv on document hide so we don't compete
// with the page for bandwidth. web-vitals is loaded dynamically only on the
// client so we don't pay for it in SSR.

export default defineNuxtPlugin(async () => {
  if (typeof window === 'undefined') return
  // Defer until idle so the metrics library doesn't push out LCP itself.
  const sched = (cb: () => void) =>
    'requestIdleCallback' in window
      ? (window as any).requestIdleCallback(cb, { timeout: 2000 })
      : setTimeout(cb, 1500)

  sched(async () => {
    try {
      const wv: any = await import('web-vitals')
      const beacon = (metric: any) => {
        const payload = {
          name: metric.name,
          value: Math.round(metric.value * 1000) / 1000,
          id: metric.id,
          rating: metric.rating,
          path: window.location.pathname,
        }
        const body = JSON.stringify(payload)
        // sendBeacon survives unload; falls back to keepalive fetch.
        if (navigator.sendBeacon) {
          navigator.sendBeacon('/api/v1/cwv', new Blob([body], { type: 'application/json' }))
        } else {
          fetch('/api/v1/cwv', { method: 'POST', body, headers: { 'Content-Type': 'application/json' }, keepalive: true })
        }
      }
      wv.onLCP?.(beacon)
      wv.onINP?.(beacon)
      wv.onCLS?.(beacon)
      wv.onFCP?.(beacon)
      wv.onTTFB?.(beacon)
    } catch { /* web-vitals not installed yet — silent */ }
  })
})
