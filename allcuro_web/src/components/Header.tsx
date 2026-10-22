import { useEffect, useState } from 'react'
import { ALL_SLUG, categoryPath } from '../data/categories'
import { site } from '../data/site'
import { Link } from './Link'
import { CloseIcon, MenuIcon, PhoneIcon } from './Icons'

export function Header() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  // A soft shadow once the page moves, so the header separates from the content.
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const close = () => setOpen(false)

  return (
    <header className={`header ${scrolled ? 'is-scrolled' : ''}`}>
      <div className="container header-inner">
        <Link to="/" className="header-brand">
          <span className="brand-wordmark">ALLCURO</span>
        </Link>

        <nav className={`header-nav ${open ? 'is-open' : ''}`} aria-label="Main">
          <Link to={categoryPath(ALL_SLUG)} onClick={close}>
            Services
          </Link>
          <Link to="/#how-it-works" onClick={close}>
            How It Works
          </Link>
          <Link to="/#faq" onClick={close}>
            FAQ
          </Link>
        </nav>

        <div className="header-actions">
          <a className="btn btn-primary header-cta" href={site.phoneHref}>
            <PhoneIcon size={16} />
            <span>{site.phoneDisplay}</span>
          </a>
          <button
            type="button"
            className="menu-btn"
            onClick={() => setOpen((o) => !o)}
            aria-expanded={open}
            aria-label={open ? 'Close menu' : 'Open menu'}
          >
            {open ? <CloseIcon /> : <MenuIcon />}
          </button>
        </div>
      </div>
    </header>
  )
}
