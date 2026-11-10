import { useEffect, useState } from 'react'
import centrePhoto from '../assets/images/centre-1.jpg'
import { categoryById } from '../data/categories'
import { site } from '../data/site'
import { motionOn } from '../motion'
import { useServices } from '../state/catalog'
import { CareIcon } from './CareIcon'
import { ArrowIcon, BoltIcon, HeadsetIcon, PhoneIcon, PillIcon, ShieldIcon, WhatsAppIcon } from './Icons'
import { Link } from './Link'
import { Modal } from './ui'

// Home-screen blocks ported from the customer app's home_screen.dart, in the
// same order: Order Medicines entry, Express 45-min nurse banner, "Our Nurse
// Care" grid, Care Centres banner + "Talk to Our Team".

/** `_MedicinesEntryBanner` from the app: saffron card, pill icon, title + hint, round arrow. */
export function MedicinesBanner() {
  return (
    <Link to="/medicines" className="med-banner">
      <span className="med-banner-icon">
        <PillIcon size={22} />
      </span>
      <span className="med-banner-text">
        <strong>Order medicines</strong>
        <span>Search or upload a prescription</span>
      </span>
      <span className="med-banner-arrow" aria-hidden="true">
        <ArrowIcon size={18} />
      </span>
    </Link>
  )
}

const expressLines = ['12 nurses available near you', 'Avg. arrival today · 32 mins', 'GNM / ANM verified · HPR registered']

/** `_ExpressNurseBanner` — "Need a nurse in 45 mins?" */
export function ExpressBanner() {
  const [line, setLine] = useState(0)
  useEffect(() => {
    if (!motionOn()) return
    const t = window.setInterval(() => setLine((l) => (l + 1) % expressLines.length), 3000)
    return () => window.clearInterval(t)
  }, [])
  return (
    <section className="container home-block" aria-label="Express nurse">
      <Link to="/book-nurse" className="express">
        <span className="express-body">
          <span className="express-tag">
            <BoltIcon size={14} /> EXPRESS CARE
          </span>
          <strong className="express-title">Need a nurse in 45 mins?</strong>
          <span key={line} className="express-line">
            <span className="express-dot" aria-hidden="true" /> {expressLines[line]}
          </span>
        </span>
        <span className="express-cta">
          Book <ArrowIcon size={16} />
        </span>
      </Link>
    </section>
  )
}

// The app's "Our Nurse Care" grid: 7 clinical services + See All.
const nurseCare: { id: string; label: string; icon: string }[] = [
  { id: 'catheter-care', label: 'Catheter Care', icon: 'urine_bag' },
  { id: 'ryle-s-tube-care', label: 'Ryles Tube', icon: 'nasal_tube' },
  { id: 'wound-dressing', label: 'Wound Dressing', icon: 'bandage' },
  { id: 'injection-administration', label: 'Injection', icon: 'injection' },
  { id: 'iv-medication-administration', label: 'IV Care', icon: 'iv_drip' },
  { id: 'tracheostomy-care', label: 'Tracheostomy', icon: 'lungs' },
  { id: 'vital-signs-check', label: 'Vital Monitoring', icon: 'vitals' },
]

export function NurseCareGrid() {
  const services = useServices()
  const tone = categoryById['Nursing Care']
  return (
    <section className="container home-block" aria-labelledby="nurse-care-title">
      <div className="home-head">
        <h2 id="nurse-care-title">Our Nurse Care</h2>
        <Link to="/services/nursing" className="home-more">
          View all <ArrowIcon size={14} />
        </Link>
      </div>
      <ul className="mini-grid">
        {nurseCare.map((n) => {
          const s = services.find((x) => x.id === n.id)
          return (
            <li key={n.id}>
              <Link to={`/service/${n.id}`} className="mini-tile">
                <span className="mini-icon" style={{ background: tone?.wash, color: tone?.ink }}>
                  <CareIcon name={n.icon} size={28} />
                </span>
                <span className="mini-label">{n.label}</span>
                {s && <span className="mini-price">{s.price}</span>}
              </Link>
            </li>
          )
        })}
        <li>
          <Link to="/services/nursing" className="mini-tile is-all">
            <span className="mini-icon">
              <CareIcon name="see_all" size={28} />
            </span>
            <span className="mini-label">See All</span>
          </Link>
        </li>
      </ul>
    </section>
  )
}

/** `_CentresBanner` + the "Talk to Our Team" advisory card under it. */
export function CentresAndAdvice() {
  const [advice, setAdvice] = useState(false)
  return (
    <section className="container home-block home-duo" aria-label="Care centres and advice">
      <Link to="/centres" className="centre-banner">
        <img src={centrePhoto} alt="" loading="lazy" />
        <span className="centre-banner-body">
          <span className="centre-banner-tag">
            <ShieldIcon size={14} /> Field audited
          </span>
          <strong>Explore Health Care Centres</strong>
          <span>ICU step-down, rehab &amp; senior living</span>
          <span className="centre-banner-cta">
            View centres <ArrowIcon size={14} />
          </span>
        </span>
      </Link>

      <button type="button" className="advice-card" onClick={() => setAdvice(true)}>
        <span className="advice-icon">
          <HeadsetIcon size={24} />
        </span>
        <span className="advice-text">
          <strong>
            Talk to Our Team <span className="advice-free">FREE</span>
          </strong>
          <span>Need advice or help choosing care? Speak with our clinical coordinators.</span>
        </span>
        <ArrowIcon size={16} />
      </button>

      {advice && (
        <Modal onClose={() => setAdvice(false)} labelledBy="advice-title">
          <div className="advice-sheet">
            <div className="advice-sheet-head">
              <span className="advice-icon is-soft">
                <HeadsetIcon size={24} />
              </span>
              <div>
                <h2 id="advice-title">Clinical Advisory &amp; Help Desk</h2>
                <p>Speak with an ALLCURO Care Coordinator</p>
              </div>
            </div>
            <p className="advice-note">
              Our medical team helps you select the exact clinician, shift duration, or medical care required for your loved one.
            </p>
            <a className="advice-action is-call" href={site.phoneHref}>
              <PhoneIcon size={20} />
              <span>
                <strong>Call Clinical Coordinator Now</strong>
                <small>24/7 free consultation · {site.phoneDisplay}</small>
              </span>
              <ArrowIcon size={16} />
            </a>
            <a className="advice-action is-wa" href={site.whatsappHref} target="_blank" rel="noreferrer">
              <WhatsAppIcon size={20} />
              <span>
                <strong>Chat on WhatsApp</strong>
                <small>Send a prescription or question · Replies in 5 mins</small>
              </span>
              <ArrowIcon size={16} />
            </a>
          </div>
        </Modal>
      )}
    </section>
  )
}
