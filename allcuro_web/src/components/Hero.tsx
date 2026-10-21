import centre from '../assets/images/centre-1.jpg'
import nurse from '../assets/images/nurse-1.jpg'
import nurse2 from '../assets/images/nurse-2.jpg'
import { ALL_SLUG, categories, categoryPath } from '../data/categories'
import { site } from '../data/site'
import { Link } from './Link'
import { artUrl } from './art'
import { ClockIcon, HeadsetIcon, PhoneIcon, RupeeIcon, ShieldIcon } from './Icons'

const tiles = [
  ...categories.map((c) => ({ slug: c.slug, label: c.label, art: c.art })),
  { slug: ALL_SLUG, label: 'All Services', art: 'see_all' },
]

export function Hero({ onSelectCategory }: { onSelectCategory?: (slug: string) => void }) {
  const handleTileClick = (e: React.MouseEvent, slug: string) => {
    if (onSelectCategory) {
      e.preventDefault()
      onSelectCategory(slug)
      const el = document.getElementById('services-explorer')
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' })
      }
    }
  }

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
                  <Link
                    to={categoryPath(t.slug)}
                    className="tile"
                    onClick={(e) => handleTileClick(e, t.slug)}
                  >
                    <span className="tile-art">
                      <img src={artUrl(t.art)} alt="" width={60} height={60} />
                    </span>
                    <span className="tile-label">{t.label}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </nav>

          <p className="hero-note">
            Not sure what you need?{' '}
            <a href={site.phoneHref}>
              <PhoneIcon size={16} /> Call {site.phoneDisplay}
            </a>
          </p>
        </div>

        <div className="collage" aria-hidden="true">
          <img src={nurse} alt="" className="collage-a" />
          <img src={nurse2} alt="" className="collage-b" />
          <img src={centre} alt="" className="collage-c" />
          <div className="float-card">
            <span className="float-icon">
              <ShieldIcon />
            </span>
            <div>
              <strong>100% verified</strong>
              <span>Police &amp; Nursing Council checked</span>
            </div>
          </div>
        </div>
      </div>
    </section>
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
      <div className="container trust-grid">
        {trustItems.map((i) => (
          <div className="trust-item" key={i.title}>
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
