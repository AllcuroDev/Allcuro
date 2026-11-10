import { useState } from 'react'

/** Busy flag around an async action (accept / decline / submit…). */
export function useBusy() {
  const [busy, setBusy] = useState<string | null>(null)
  const run = async (key: string, fn: () => Promise<void>) => {
    if (busy) return
    setBusy(key)
    try {
      await fn()
    } finally {
      setBusy(null)
    }
  }
  return [busy, run] as const
}
