import type { AnchorHTMLAttributes, MouseEvent } from 'react'
import { navigate } from '../router'

type LinkProps = AnchorHTMLAttributes<HTMLAnchorElement> & { to: string }

/** In-app link. Same-page `#hash` links fall through to the browser's own jump. */
export function Link({ to, onClick, ...rest }: LinkProps) {
  const handleClick = (e: MouseEvent<HTMLAnchorElement>) => {
    onClick?.(e)
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return
    const url = new URL(to, window.location.href)
    if (url.pathname + url.search === window.location.pathname + window.location.search) {
      if (url.hash) return
      e.preventDefault()
      window.scrollTo({ top: 0, behavior: 'smooth' })
      return
    }
    e.preventDefault()
    navigate(url.pathname + url.search + url.hash)
  }
  return <a href={to} onClick={handleClick} {...rest} />
}
