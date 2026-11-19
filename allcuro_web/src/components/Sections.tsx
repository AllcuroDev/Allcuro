import { useState, type CSSProperties } from 'react'
import { categories, categoryHref } from '../data/categories'
import { faqs } from '../data/faqs'
import { site } from '../data/site'
import { Link } from './Link'
import { PhoneIcon } from './Icons'
import { Logo } from './Logo'

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
              <div
                key={f.q}
                className={`faq-item reveal ${isOpen ? 'is-open' : ''}`}
                style={{ '--d': i } as CSSProperties}
              >
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
            )
          })}
        </div>
      </div>
    </section>
  )
}

export function CallBand() {
  return (
    <section className="call-band" aria-labelledby="call-title">
      <span className="call-orb call-orb-a" aria-hidden="true" />
      <span className="call-orb call-orb-b" aria-hidden="true" />
      <div className="container call-inner reveal">
        <div>
          <h2 id="call-title">Need help choosing? Just call us.</h2>
          <p>Our care desk is open 24 hours, every day. We will understand your needs and book the right person.</p>
        </div>
        <div className="call-actions">
          <a className="btn btn-light btn-lg call-phone" href={site.phoneHref}>
            <span className="ring-icon">
              <PhoneIcon />
            </span>
            {site.phoneDisplay}
          </a>
        </div>
      </div>
    </section>
  )
}

export function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-grid">
        <div>
          <Logo light />
          <p className="footer-tag">{site.tagline}</p>
          <p className="footer-small">Verified home nursing, elder care and family health services.</p>
        </div>
        <div>
          <h3>Services</h3>
          <ul>
            {categories.map((c) => (
              <li key={c.slug}>
                <Link to={categoryHref(c)}>{c.label}</Link>
              </li>
            ))}
          </ul>
        </div>
        <div>
          <h3>Contact</h3>
          <ul>
            <li><a href={site.phoneHref}>{site.phoneDisplay}</a></li>
            <li><a href={`mailto:${site.email}`}>{site.email}</a></li>
            <li>{site.cities.join(' · ')}</li>
          </ul>
        </div>
        <div>
          <h3>For partners</h3>
          <ul>
            <li><Link to="/partner/welcome">Join as a nurse or caregiver</Link></li>
            <li><Link to="/partner/welcome">Join as a doctor / physio</Link></li>
            <li><Link to="/partner/welcome">List your care centre</Link></li>
            <li><Link to="/partner/phone-auth">Partner sign in</Link></li>
          </ul>
        </div>
      </div>
      <div className="container footer-bottom">
        <span>© {new Date().getFullYear()} ALLCURO. All rights reserved.</span>
        <span>For medical emergencies, call 112.</span>
      </div>
    </footer>
  )
}
