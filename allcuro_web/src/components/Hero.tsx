import type { CSSProperties } from 'react'
import { ALL_SLUG, categories, categoryHref } from '../data/categories'
import { site } from '../data/site'
import { Link } from './Link'
import { Artwork } from './CareIcon'
import { MedicinesBanner } from './HomeSections'
import { SearchBar } from './SearchBar'
import { useCategoryImages } from '../state/catalog'
import { ClockIcon, HeadsetIcon, RupeeIcon, ShieldIcon } from './Icons'

// Every care type, then medicine delivery, then the full list. One row on wide
// screens, wrapping onto more rows as the screen narrows (index.css `.tiles`).
const heroTiles = (): { id: string; slug: string; href?: string; label: string; icon: string }[] => [
  ...categories.map((c) => ({ id: c.id, slug: c.slug, href: c.href, label: c.label, icon: c.icon })),
  { id: 'medicines', slug: 'medicines', href: '/medicines', label: 'Order Medicines', icon: 'med_kit' },
  { id: ALL_SLUG, slug: ALL_SLUG, label: 'All Services', icon: 'see_all' },
]

export function Hero() {
  const images = useCategoryImages()
  const tiles = heroTiles()
  return (
    <section className="hero" id="top">
      <div className="container">
        <div className="hero-copy">
          <h1>
            {site.heroHeadline} {site.heroHighlight && <span className="hl">{site.heroHighlight}</span>}
          </h1>

          {/* Same order as the app: search, then Order medicines, then the care tiles. */}
          <SearchBar className="hero-search" />
          <MedicinesBanner />

          <nav className="tile-box" aria-labelledby="tiles-title">
            <h2 id="tiles-title" className="tile-box-title">
              {site.tilesTitle}
            </h2>
            <ul className="tiles">
              {tiles.map((t) => (
                <li key={t.slug}>
                  <Link to={categoryHref(t)} className="tile">
                    <span className="tile-art">
                      <Artwork image={images[t.id]} icon={t.icon} size={60} />
                    </span>
                    <span className="tile-label">{t.label}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
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
