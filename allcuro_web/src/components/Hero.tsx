import { useEffect, useRef, useState, type CSSProperties } from 'react'
import nurse from '../assets/images/nurse-1.jpg'
import { ALL_SLUG, categories, categoryHref } from '../data/categories'
import { site } from '../data/site'
import { Link } from './Link'
import { artUrl } from './art'
import { motionOn } from '../motion'
import { CheckIcon, ClockIcon, HeadsetIcon, PhoneIcon, RupeeIcon, ShieldIcon, BoltIcon } from './Icons'

const tiles = [
  ...categories.map((c) => ({ slug: c.slug, href: c.href, label: c.label, art: c.art })),
  { slug: ALL_SLUG, label: 'All Services', art: 'see_all' },
]

export function Hero() {
  return (
    <section className="hero" id="top">
      <div className="container hero-grid">
        <div className="hero-copy">
          <h1>
            Healthcare <span className="hl">at your doorstep</span>
          </h1>

          <nav className="tile-box" aria-labelledby="tiles-title">
            <h2 id="tiles-title" className="tile-box-title">
              What are you looking for?
            </h2>
            <ul className="tiles">
              {tiles.map((t) => (
                <li key={t.slug}>
                  <Link to={categoryHref(t)} className="tile">
                    <span className="tile-art">
                      <img src={artUrl(t.art)} alt="" width={60} height={60} />
                    </span>
                    <span className="tile-label">{t.label}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </nav>

          <div className="hero-quick">
            <Link to="/book-nurse" className="btn btn-primary btn-lg">
              <BoltIcon /> Book a nurse in 45 mins
            </Link>
            <Link to="/nurses" className="btn btn-outline btn-lg">
              Browse verified nurses
            </Link>
          </div>

          <p className="hero-note">
            Not sure what you need?{' '}
            <a href={site.phoneHref}>
              <PhoneIcon size={16} /> Call {site.phoneDisplay}
            </a>
          </p>
        </div>

        <HeroVisual />
      </div>
    </section>
  )
}

// Care types that circle the photo in the hero.
const orbit = ['nursing', 'elder_care', 'mother_baby', 'physio', 'doctor', 'caregiver']

// The "on the way" card steps through a few kinds of visit.
const visits = [
  { who: 'Nurse', task: 'Injection at home' },
  { who: 'Physiotherapist', task: 'Knee rehab session' },
  { who: 'Caregiver', task: 'Day care for an elder' },
  { who: 'Doctor', task: 'Home consultation' },
]

/**
 * Right-hand side of the hero: a nurse photo in an arch, care icons orbiting
 * it, and small floating cards that hint at what a visit looks like. The whole
 * scene leans gently toward the mouse.
 */
function HeroVisual() {
  const ref = useRef<HTMLDivElement>(null)
  const [visit, setVisit] = useState(0)

  useEffect(() => {
    if (!motionOn()) return
    const t = window.setInterval(() => setVisit((v) => (v + 1) % visits.length), 3800)
    return () => window.clearInterval(t)
  }, [])

  useEffect(() => {
    const el = ref.current
    if (!el || !motionOn()) return
    const onMove = (e: PointerEvent) => {
      if (e.pointerType !== 'mouse') return
      const r = el.getBoundingClientRect()
      el.style.setProperty('--px', ((e.clientX - r.left) / r.width - 0.5).toFixed(3))
      el.style.setProperty('--py', ((e.clientY - r.top) / r.height - 0.5).toFixed(3))
    }
    const onLeave = () => {
      el.style.setProperty('--px', '0')
      el.style.setProperty('--py', '0')
    }
    el.addEventListener('pointermove', onMove)
    el.addEventListener('pointerleave', onLeave)
    return () => {
      el.removeEventListener('pointermove', onMove)
      el.removeEventListener('pointerleave', onLeave)
    }
  }, [])

  const v = visits[visit]

  return (
    <div className="hv" ref={ref} aria-hidden="true">
      <div className="hv-blob" />
      <div className="hv-orbit">
        {orbit.map((art, i) => (
          <span key={art} className="hv-planet" style={{ '--a': `${(360 / orbit.length) * i}deg` } as CSSProperties}>
            <span className="hv-planet-face">
              <img src={artUrl(art)} alt="" width={40} height={40} />
            </span>
          </span>
        ))}
      </div>

      <div className="hv-photo">
        <img src={nurse} alt="" />
      </div>

      <div className="hv-card hv-eta" style={{ '--d': 0 } as CSSProperties}>
        <span className="hv-card-icon hv-pulse">
          <ClockIcon size={18} />
        </span>
        <div key={visit} className="hv-swap">
          <strong>{v.who} on the way</strong>
          <span>{v.task}</span>
          <span className="hv-progress" />
        </div>
      </div>

      <div className="hv-card hv-vitals" style={{ '--d': 1 } as CSSProperties}>
        <div className="hv-vitals-head">
          <strong>Vitals recorded</strong>
          <span className="hv-check">
            <CheckIcon size={12} />
          </span>
        </div>
        <svg className="hv-ecg" viewBox="0 0 160 36" preserveAspectRatio="none">
          <path d="M0 20h34l6-10 7 20 8-28 7 26 5-8h32l5-6 6 12 5-6h45" pathLength={100} />
        </svg>
        <span className="hv-vitals-row">
          <span>
            BP <b>120/80</b>
          </span>
          <span>
            SpO₂ <b>98%</b>
          </span>
        </span>
      </div>

      <div className="hv-card hv-verified" style={{ '--d': 2 } as CSSProperties}>
        <span className="hv-card-icon">
          <ShieldIcon size={18} />
        </span>
        <div>
          <strong>100% verified</strong>
          <span>Police &amp; Nursing Council checked</span>
        </div>
      </div>
    </div>
  )
}

const trustItems = [
  { title: '100% Verified', text: 'Police & State Nursing Council checked', icon: <ShieldIcon /> },
  { title: 'Flexible Slots', text: '30-min visits, hourly care or full shifts', icon: <ClockIcon size={22} /> },
  { title: 'Transparent Pricing', text: 'Standard rates, no hidden markups', icon: <RupeeIcon /> },
  { title: '24/7 Care Desk', text: 'Doctor & nursing supervisor on call', icon: <HeadsetIcon /> },
]

export function TrustBand() {
  return (
    <section className="trust" id="why-allcuro" aria-label="Why ALLCURO">
      <div className="trust-glow" aria-hidden="true" />
      <div className="container trust-grid">
        {trustItems.map((i, n) => (
          <div className="trust-item reveal" key={i.title} style={{ '--d': n } as CSSProperties}>
            <span className="trust-icon">{i.icon}</span>
            <div>
              <h3>{i.title}</h3>
              <p>{i.text}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
