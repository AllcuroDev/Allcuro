import { memoryStore } from './store'

// Short confirmation messages (the app's SnackBars), rendered by <Toaster /> in App.

export interface ToastItem {
  id: number
  text: string
  tone: 'success' | 'info' | 'danger'
}

export const toasts = memoryStore<ToastItem[]>([])

export function toast(text: string, tone: ToastItem['tone'] = 'success') {
  const id = Date.now() + Math.random()
  toasts.set((t) => [...t, { id, text, tone }])
  setTimeout(() => toasts.set((t) => t.filter((x) => x.id !== id)), 3600)
}
