import { useEffect } from 'react'

// Subtle page motion. `main.tsx` adds `.motion` to <html> unless the visitor
// prefers reduced motion; every animation in index.css is scoped to it, so
// without it the page is fully visible and still.

export const motionOn = () => document.documentElement.classList.contains('motion')

/**
 * Fades `.reveal` elements in as they scroll into view. Re-scans when `key`
 * (the path) changes, and also picks up elements rendered later — e.g. FAQs
 * and partner cards that arrive from Supabase after the page has mounted,
 * which would otherwise stay invisible.
 */
export function useReveal(key: string) {
  useEffect(() => {
    if (!motionOn()) return
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (!e.isIntersecting) continue
          e.target.classList.add('is-in')
          io.unobserve(e.target)
        }
      },
      { rootMargin: '0px 0px -8% 0px', threshold: 0.12 },
    )
    const scan = () => document.querySelectorAll('.reveal:not(.is-in)').forEach((el) => io.observe(el))
    scan()
    let queued = 0
    const mo = new MutationObserver(() => {
      if (queued) return
      queued = requestAnimationFrame(() => {
        queued = 0
        scan()
      })
    })
    mo.observe(document.body, { childList: true, subtree: true })
    return () => {
      mo.disconnect()
      cancelAnimationFrame(queued)
      io.disconnect()
    }
  }, [key])
}

/** Feeds the pointer position to `.spotlight` cards so a soft glow follows the cursor. */
export function useSpotlight() {
  useEffect(() => {
    const onMove = (e: PointerEvent) => {
      if (e.pointerType !== 'mouse') return
      const el = (e.target as Element).closest?.<HTMLElement>('.spotlight')
      if (!el) return
      const r = el.getBoundingClientRect()
      el.style.setProperty('--mx', `${e.clientX - r.left}px`)
      el.style.setProperty('--my', `${e.clientY - r.top}px`)
    }
    document.addEventListener('pointermove', onMove, { passive: true })
    return () => document.removeEventListener('pointermove', onMove)
  }, [])
}
