import { useSyncExternalStore } from 'react'

// Minimal history-API router. Pages match on the path themselves (see App.tsx),
// so a routing library would be more weight than help.

const subscribe = (onChange: () => void) => {
  window.addEventListener('popstate', onChange)
  return () => window.removeEventListener('popstate', onChange)
}

export const usePath = () => useSyncExternalStore(subscribe, () => window.location.pathname)

/** The current `?query`, re-read on every navigation. */
export const useSearch = () => useSyncExternalStore(subscribe, () => window.location.search)

export const useQuery = (key: string) => new URLSearchParams(useSearch()).get(key)

export function navigate(to: string, { replace = false } = {}) {
  if (replace) window.history.replaceState(window.history.state, '', to)
  else window.history.pushState(null, '', to)
  window.dispatchEvent(new PopStateEvent('popstate'))
}

/** Go back like the app's `context.pop()`, or to `fallback` when the visitor landed here directly. */
export function goBack(fallback: string) {
  if (window.history.state?.inApp) window.history.back()
  else navigate(fallback)
}

// Mark entries we pushed ourselves, so goBack knows there is an in-app page behind them.
const push = window.history.pushState.bind(window.history)
window.history.pushState = (_state, unused, url) => push({ inApp: true }, unused, url)
