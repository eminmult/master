interface ToastItem {
  id: number
  text: string
  type: 'success' | 'error' | 'info'
  ttl: number
}

const toasts = ref<ToastItem[]>([])
let nextId = 1

function show(text: string, type: ToastItem['type'] = 'info', ttl = 4000) {
  const id = nextId++
  toasts.value.push({ id, text, type, ttl })
  if (ttl > 0) {
    setTimeout(() => dismiss(id), ttl)
  }
  return id
}

function dismiss(id: number) {
  toasts.value = toasts.value.filter(t => t.id !== id)
}

export function useToast() {
  return {
    toasts,
    show,
    success: (text: string, ttl?: number) => show(text, 'success', ttl),
    error: (text: string, ttl?: number) => show(text, 'error', ttl),
    info: (text: string, ttl?: number) => show(text, 'info', ttl),
    dismiss,
  }
}
