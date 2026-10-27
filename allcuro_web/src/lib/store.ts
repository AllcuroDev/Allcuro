import { useSyncExternalStore } from 'react'

// A tiny state container kept in localStorage, standing in for the app's
// SharedPreferences + Riverpod providers. When a real backend lands, only the
// files in src/state need to change — pages read through their hooks.

export interface Store<T> {
  get: () => T
  set: (next: T | ((prev: T) => T)) => void
  use: () => T
}

export function persistedStore<T>(key: string, initial: T): Store<T> {
  const listeners = new Set<() => void>()
  const storageKey = `allcuro.${key}`

  const read = (): T => {
    try {
      const raw = localStorage.getItem(storageKey)
      return raw ? (JSON.parse(raw) as T) : initial
    } catch {
      return initial
    }
  }

  let value = read()

  const get = () => value
  const set: Store<T>['set'] = (next) => {
    value = typeof next === 'function' ? (next as (prev: T) => T)(value) : next
    try {
      localStorage.setItem(storageKey, JSON.stringify(value))
    } catch {
      // Private mode or storage full: keep working in memory for this visit.
    }
    listeners.forEach((l) => l())
  }

  const subscribe = (onChange: () => void) => {
    listeners.add(onChange)
    // Keep several open tabs in step (e.g. signing out in one signs out all).
    const onStorage = (e: StorageEvent) => {
      if (e.key !== storageKey) return
      value = read()
      onChange()
    }
    window.addEventListener('storage', onStorage)
    return () => {
      listeners.delete(onChange)
      window.removeEventListener('storage', onStorage)
    }
  }

  return { get, set, use: () => useSyncExternalStore(subscribe, get) }
}

/** Same shape as persistedStore, for state that should not outlive the tab (open dialogs, toasts). */
export function memoryStore<T>(initial: T): Store<T> {
  const listeners = new Set<() => void>()
  let value = initial
  const get = () => value
  const set: Store<T>['set'] = (next) => {
    value = typeof next === 'function' ? (next as (prev: T) => T)(value) : next
    listeners.forEach((l) => l())
  }
  const subscribe = (onChange: () => void) => {
    listeners.add(onChange)
    return () => listeners.delete(onChange)
  }
  return { get, set, use: () => useSyncExternalStore(subscribe, get) }
}

/** Resolves after `ms`, standing in for network latency like the app's `Future.delayed`. */
export const delay = (ms: number) => new Promise<void>((r) => setTimeout(r, ms))
