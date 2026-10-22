import { useEffect, useRef, useState, type CSSProperties } from 'react'
import centre from '../assets/images/centre-1.jpg'
import wheelchair from '../assets/images/eq-wheelchair.jpg'
import { categories, categoryPath } from '../data/categories'
import { faqs } from '../data/faqs'
import { site } from '../data/site'
import { Link } from './Link'
import { ArrowIcon, PhoneIcon, WhatsAppIcon } from './Icons'
import { Logo } from './Logo'
import { motionOn } from '../motion'

const steps = [
  {
    title: 'Choose a service',
    text: 'Pick what you need — a 30-minute visit, a few hours of help, or a full 12 or 24-hour shift.',
  },
  {
    title: 'We send a verified professional',
    text: 'A qualified, police-verified nurse, caregiver or therapist comes to your door.',
  },
  {
    title: 'Care, with support behind it',
    text: 'Vitals are recorded at every visit, and a senior medical supervisor is always on call.',
  },
]

export function HowItWorks() {
  const [active, setActive] = useState(0)
  const [paused, setPaused] = useState(false)
  const [inView, setInView] = useState(false)
  const ref = useRef<HTMLOListElement>(null)

  // Walk through the steps on their own while the section is on screen,
  // unless the visitor is pointing at or focused on one.
  useEffect(() => {
    const el = ref.current
    if (!el || !motionOn()) return
    const io = new IntersectionObserver(([e]) => setInView(e.isIntersecting), { threshold: 0.4 })
    io.observe(el)
    return () => io.disconnect()
  }, [])

  useEffect(() => {
    if (!inView || paused) return
    const t = window.setInterval(() => setActive((a) => (a + 1) % steps.length), 3600)
    return () => window.clearInterval(t)
  }, [inView, paused])

  return (
    <section className="section" id="how-it-works" aria-labelledby="how-title">
      <div className="container">
        <div className="section-head reveal">
          <p className="eyebrow">How it works</p>
          <h2 id="how-title">Care at home in three simple steps</h2>
        </div>
        <ol
          ref={ref}
          className="steps reveal"
          style={{ '--progress': (active + 1) / steps.length } as CSSProperties}
          onPointerLeave={() => setPaused(false)}
          onBlur={() => setPaused(false)}
        >
          {steps.map((s, i) => (
            <li
              key={s.title}
              className={`spotlight ${i === active ? 'is-active' : ''} ${i < active ? 'is-done' : ''}`}
              style={{ '--d': i } as CSSProperties}
              tabIndex={0}
              onPointerEnter={() => {
                setPaused(true)
                setActive(i)
              }}
              onFocus={() => {
                setPaused(true)
                setActive(i)
              }}
            >
              <span className="step-num">{String(i + 1).padStart(2, '0')}</span>
              <h3>{s.title}</h3>
              <p>{s.text}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}

export function MoreCare() {
  const cards = [
    {
      img: centre,
      alt: 'A bright, clean room at a care centre',
      title: 'Verified care centres',
      text: 'Field-audited elder care homes, rehabilitation and recovery centres with clear bed availability.',
    },
    {
      img: wheelchair,
      alt: 'A wheelchair available on rent',
      title: 'Medical equipment on rent',
      text: 'Wheelchairs, hospital beds and oxygen concentrators delivered home, with a refundable deposit.',
    },
  ]
  return (
    <section className="section section-tint" aria-labelledby="more-title">
      <div className="container">
        <div className="section-head reveal">
          <p className="eyebrow">Also on ALLCURO</p>
          <h2 id="more-title">Need a stay or equipment?</h2>
        </div>
        <div className="more-grid">
          {cards.map((c, i) => (
            <article className="more-card spotlight reveal" key={c.title} style={{ '--d': i } as CSSProperties}>
              <div className="more-img">
                <img src={c.img} alt={c.alt} loading="lazy" />
              </div>
              <div>
                <h3>{c.title}</h3>
                <p>{c.text}</p>
                <a className="text-link" href={site.phoneHref}>
                  Ask our team <ArrowIcon size={16} />
                </a>
              </div>
            </article>
          ))}
        </div>
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
          <a className="btn btn-ghost-light btn-lg" href={site.whatsappHref} target="_blank" rel="noreferrer">
            <WhatsAppIcon /> WhatsApp us
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
                <Link to={categoryPath(c.slug)}>{c.label}</Link>
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
      </div>
      <div className="container footer-bottom">
        <span>© {new Date().getFullYear()} ALLCURO. All rights reserved.</span>
        <span>For medical emergencies, call 112.</span>
      </div>
    </footer>
  )
}
