import { useState, type CSSProperties } from 'react'
import { categories, categoryHref } from '../data/categories'
import { faqs } from '../data/faqs'
import { site } from '../data/site'
import { Link } from './Link'
import { ArrowUpIcon, MailIcon, PhoneIcon, WhatsAppIcon } from './Icons'

const steps = [
  {
    title: 'Tell us what you need',
    text: 'A short visit, a few hours, or a full-day shift. Booking takes a minute.',
  },
  {
    title: 'We send someone you can trust',
    text: 'A trained, background-checked nurse or caregiver comes to your home.',
  },
  {
    title: 'We stay with you',
    text: 'We keep track of every visit, and a medical supervisor is always a call away.',
  },
]

export function HowItWorks() {
  return (
    <section className="section" id="how-it-works" aria-labelledby="how-title">
      <div className="container">
        <div className="section-head how-head reveal">
          <h2 id="how-title">How it works</h2>
          <p className="section-sub">Care at home in three simple steps</p>
        </div>
        <ol className="how-steps reveal">
          {steps.map((s, i) => (
            <li key={s.title}>
              <span className="how-num" aria-hidden="true">
                {i + 1}
              </span>
              <h3>{s.title}</h3>
              <p>{s.text}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}

export function Faq() {
  const [open, setOpen] = useState<number | null>(0)

  // Filled from public.faqs once content loads; nothing to show until then.
  if (faqs.length === 0) return null

  return (
    <section className="section" id="faq" aria-labelledby="faq-title">
      <div className="container faq-wrap">
        <div className="section-head reveal">
          <p className="eyebrow">Questions</p>
          <h2 id="faq-title">Frequently asked questions</h2>
        </div>
        <div className="faq-list">
          {faqs.map((f, i) => {
            const isOpen = open === i
            return (
              // The reveal sits on a wrapper: React rewrites the item's className on
              // every toggle, which would drop the observer's `is-in` and fade it again.
              <div key={f.q} className="reveal" style={{ '--d': i } as CSSProperties}>
              <div className={`faq-item ${isOpen ? 'is-open' : ''}`}>
                <h3>
                  <button
                    type="button"
                    id={`faq-q-${i}`}
                    aria-expanded={isOpen}
                    aria-controls={`faq-a-${i}`}
                    onClick={() => setOpen(isOpen ? null : i)}
                  >
                    <span>{f.q}</span>
                    <span className="faq-sign" aria-hidden="true" />
                  </button>
                </h3>
                <div className="faq-panel" id={`faq-a-${i}`} role="region" aria-labelledby={`faq-q-${i}`} inert={!isOpen}>
                  <div>
                    <p>{f.a}</p>
                  </div>
                </div>
              </div>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}

// Flat deep-green footer: brand, tagline, WhatsApp + email on the left and link
// columns on the right; then contact icons, copyright and the legal note; a big
// faded wordmark sits in the bottom-right corner.
const exploreLinks = [
  { to: '/nurses', label: 'Verified Nurses' },
  { to: '/book-nurse', label: 'Book a Nurse' },
  { to: '/centres', label: 'Care Centres' },
  { to: '/equipment', label: 'Equipment on Rent' },
  { to: '/medicines', label: 'Order Medicines' },
]
const partnerLinks = [
  { to: '/partner/welcome', label: 'Join as a nurse or caregiver' },
  { to: '/partner/welcome', label: 'Join as a doctor / physio' },
  { to: '/partner/welcome', label: 'List your care centre' },
  { to: '/partner/phone-auth', label: 'Partner sign in' },
]

export function Footer() {
  const toTop = () => window.scrollTo({ top: 0, behavior: 'smooth' })
  const tagline = site.tagline || 'Healthcare, Made Simple.'
  // Services run down two side-by-side lists under one heading.
  const half = Math.ceil(categories.length / 2)
  return (
    <footer className="footer">
      <div className="container footer-inner">
        <div className="footer-hero">
          <div className="footer-hero-copy">
            <Link to="/" className="footer-brand" aria-label={`${site.brand} home`}>
              ALLCURO<span className="footer-brand-dot">.</span>
            </Link>
            <p className="footer-tagline">{tagline}</p>
            <a className="footer-wa" href={site.whatsappHref} target="_blank" rel="noreferrer">
              <WhatsAppIcon size={15} />
              Get help on WhatsApp
            </a>
            <a className="footer-email" href={`mailto:${site.email}`}>
              <MailIcon size={15} />
              {site.email}
            </a>
          </div>

          <nav className="footer-cols" aria-label="Footer">
            <div className="footer-col footer-col-services">
              <h3>All services</h3>
              <div className="footer-split">
                <ul>
                  {categories.slice(0, half).map((c) => (
                    <li key={c.slug}>
                      <Link to={categoryHref(c)}>{c.label}</Link>
                    </li>
                  ))}
                </ul>
                <ul>
                  {categories.slice(half).map((c) => (
                    <li key={c.slug}>
                      <Link to={categoryHref(c)}>{c.label}</Link>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
            <div className="footer-col">
              <h3>Explore</h3>
              <ul>
                {exploreLinks.map((l) => (
                  <li key={l.to}>
                    <Link to={l.to}>{l.label}</Link>
                  </li>
                ))}
              </ul>
            </div>
            <div className="footer-col">
              <h3>For partners</h3>
              <ul>
                {partnerLinks.map((l) => (
                  <li key={l.label}>
                    <Link to={l.to}>{l.label}</Link>
                  </li>
                ))}
              </ul>
            </div>
            <div className="footer-col">
              <h3>All cities</h3>
              <ul>
                {site.cities.map((c) => (
                  <li key={c}>{c}</li>
                ))}
              </ul>
            </div>
          </nav>
        </div>

        <div className="footer-bottom">
          <div className="footer-bottom-row">
            <div className="footer-social">
              <a href={site.phoneHref} aria-label={`Call ${site.phoneDisplay}`}>
                <PhoneIcon size={16} />
              </a>
              <a href={site.whatsappHref} target="_blank" rel="noreferrer" aria-label="WhatsApp">
                <WhatsAppIcon size={16} />
              </a>
              <a href={`mailto:${site.email}`} aria-label={`Email ${site.email}`}>
                <MailIcon size={16} />
              </a>
            </div>
            <div className="footer-bottom-links">
              <Link to="/partner/welcome" className="is-accent">
                Become a partner
              </Link>
              <Link to="/#faq">FAQs</Link>
              <button type="button" className="footer-top-btn" onClick={toTop} aria-label="Back to top">
                <ArrowUpIcon size={16} />
              </button>
            </div>
          </div>
          <div className="footer-bottom-row">
            <p className="footer-copy">
              © {new Date().getFullYear()} ALLCURO. {tagline}
            </p>
            <p className="footer-emergency">
              Medical emergency? Call <a href="tel:112">112</a>
            </p>
          </div>
        </div>

        {/* Last row: legal note on the left, big faded brand mark in the bottom-right corner. */}
        <div className="footer-end">
          <p className="footer-legal">
            Every nurse, caregiver and doctor on ALLCURO is identity-checked and verified before their first visit.
            ALLCURO coordinates care through verified partners and is not a hospital or a substitute for emergency
            medical services. In a life-threatening emergency, call 112 immediately.
          </p>
          <div className="footer-mark" aria-hidden="true">
            <svg className="footer-mark-icon" viewBox="0 0 34 34">
              <rect width="34" height="34" rx="9" />
              <path d="M6 18h5l2.5-6 4 11 3-8 1.5 3H28" />
            </svg>
            <span className="footer-mark-word">allcuro</span>
          </div>
        </div>
      </div>
    </footer>
  )
}
