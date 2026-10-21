import { useState } from 'react'
import { site } from '../data/site'
import { Link } from './Link'
import { CloseIcon, MenuIcon, PhoneIcon } from './Icons'

export function Header() {
  const [open, setOpen] = useState(false)

  return (
    <header className="header">
      <div className="container header-inner">
        <Link to="/" className="header-brand">
          <span className="brand-wordmark">ALLCURO</span>
          <span className="brand-badge">
            <span className="pulse-dot" />
            24/7 Verified Care
          </span>
        </Link>

        <nav className={`header-nav ${open ? 'is-open' : ''}`} aria-label="Main">
          <a href="/#services-explorer" onClick={() => setOpen(false)}>
            Services
          </a>
          <a href="/#how-it-works" onClick={() => setOpen(false)}>
            How It Works
          </a>
          <a href="/#why-allcuro" onClick={() => setOpen(false)}>
            Why ALLCURO
          </a>
          <a href="/#faq" onClick={() => setOpen(false)}>
            FAQ
          </a>
        </nav>

        <div className="header-actions">
          <a className="header-phone-pill" href={site.phoneHref} title="24/7 Clinical Support Desk">
            <PhoneIcon size={14} />
            <span>{site.phoneDisplay}</span>
          </a>
          <a className="btn btn-primary header-cta" href="/#services-explorer">
            Book Service
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

