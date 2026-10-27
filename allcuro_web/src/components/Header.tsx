import { useEffect, useState } from 'react'
import { ALL_SLUG, categoryPath } from '../data/categories'
import { site } from '../data/site'
import { initials } from '../lib/format'
import { usePath } from '../router'
import { useAuth } from '../state/auth'
import { Link } from './Link'
import { CloseIcon, MenuIcon, PhoneIcon, UserIcon } from './Icons'

// Main sections, matching the app's bottom tabs (Home, Care Centres, 45 Mins, Equipments, Bookings).
const NAV = [
  { to: categoryPath(ALL_SLUG), label: 'Services', match: '/service' },
  { to: '/nurses', label: 'Nurses', match: '/nurses' },
  { to: '/centres', label: 'Care Centres', match: '/centres' },
  { to: '/equipment', label: 'Equipment', match: '/equipment' },
  { to: '/bookings', label: 'My Bookings', match: '/bookings' },
]

export function Header() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)
  const path = usePath()
  const { isLoggedIn, profile } = useAuth()

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
          {NAV.map((n) => (
            <Link
              key={n.to}
              to={n.to}
              onClick={close}
              aria-current={path.startsWith(n.match) ? 'page' : undefined}
            >
              {n.label}
            </Link>
          ))}
          <a className="header-nav-phone" href={site.phoneHref}>
            <PhoneIcon size={16} /> {site.phoneDisplay}
          </a>
        </nav>

        <div className="header-actions">
          <a className="btn btn-outline header-cta" href={site.phoneHref} aria-label={`Call ${site.phoneDisplay}`}>
            <PhoneIcon size={16} />
            <span>{site.phoneDisplay}</span>
          </a>
          {isLoggedIn && profile?.name ? (
            <Link to="/profile" className="account-btn" aria-label={`My profile (${profile.name})`} onClick={close}>
              {initials(profile.name)}
            </Link>
          ) : (
            <Link
              to={isLoggedIn ? '/profile' : '/login'}
              className="btn btn-primary header-signin"
              onClick={close}
            >
              <UserIcon size={16} />
              <span>{isLoggedIn ? 'Finish setup' : 'Sign in'}</span>
            </Link>
          )}
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
