import { useEffect, useRef, useState } from 'react'
import { categories, categoryById } from '../data/categories'
import { site } from '../data/site'
import type { Service } from '../data/types'
import { IconTile } from './CareIcon'
import { Link } from './Link'
import { ArrowIcon, CheckIcon, ClockIcon, CloseIcon, MinusIcon, PhoneIcon, ShieldIcon, SparklesIcon, UserIcon, WhatsAppIcon } from './Icons'

const split = (text: string) =>
  text
    .split(';')
    .map((t) => t.trim().replace(/\.$/, ''))
    .filter(Boolean)

export function ServiceDialog({ service: s, onClose }: { service: Service; onClose: () => void }) {
  const ref = useRef<HTMLDialogElement>(null)
  const cat = categoryById[s.category] ?? categories[0]
  const [frequency, setFrequency] = useState<'single' | 'triple' | 'weekly'>('single')

  useEffect(() => {
    const d = ref.current
    if (!d) return
    // Closing here would fire `close` → onClose and unmount the dialog the
    // moment StrictMode re-runs this effect; unmounting removes it anyway.
    if (!d.open) d.showModal()
    document.body.classList.add('no-scroll')
    return () => document.body.classList.remove('no-scroll')
  }, [])

  // Calculate pricing estimates based on selected frequency
  const rawNum = parseInt(s.price.replace(/[^\d]/g, ''), 10) || 499
  const isShift = s.price.includes('/12h') || s.price.includes('/24h') || s.duration.includes('hr') || s.duration.includes('shift')

  let effectivePrice = s.price
  let savingsText = ''

  if (rawNum > 0 && !isNaN(rawNum)) {
    if (frequency === 'single') {
      effectivePrice = s.price
    } else if (frequency === 'triple') {
      const discounted = Math.round(rawNum * 3 * 0.9)
      const saved = (rawNum * 3) - discounted
      effectivePrice = `₹${discounted.toLocaleString('en-IN')}`
      savingsText = `Save ₹${saved} (10% off)`
    } else if (frequency === 'weekly') {
      const discounted = Math.round(rawNum * 7 * 0.85)
      const saved = (rawNum * 7) - discounted
      effectivePrice = `₹${discounted.toLocaleString('en-IN')}`
      savingsText = `Save ₹${saved} (15% off)`
    }
  }

  const freqLabel = frequency === 'single' ? (isShift ? 'Single Shift' : 'Single Visit') : frequency === 'triple' ? '3-Care Sessions' : '7-Day Care Plan'
  const whatsapp = `${site.whatsappHref}?text=${encodeURIComponent(
    `Hello ALLCURO Clinical Desk, I would like to book: ${s.name} (${freqLabel} - ${effectivePrice}). Please confirm availability.`
  )}`

  return (
    <dialog
      ref={ref}
      className="dialog"
      aria-labelledby="dlg-title"
      onClose={onClose}
      onClick={(e) => e.target === ref.current && onClose()}
    >
      <div className="dialog-body">
        <button type="button" className="dialog-close" onClick={onClose} aria-label="Close">
          <CloseIcon size={20} />
        </button>

        <div className="dlg-head">
          <IconTile name={s.icon} image={s.imageUrl} ink={cat.ink} wash={cat.wash} size={64} />
          <div>
            <div className="dlg-category-bar">
              <span className="svc-cat" style={{ color: cat.ink }}>
                {cat.label} · {s.subcategory}
              </span>
              {s.badge && <span className="badge badge-glow">{s.badge}</span>}
            </div>
            <h3 id="dlg-title">{s.name}</h3>
          </div>
        </div>

        <p className="dlg-desc">{s.description}</p>

        {/* Unique Feature: Interactive Care Frequency / Duration Selector */}
        <div className="dlg-package-selector">
          <p className="package-title">
            <SparklesIcon size={16} /> Choose Care Plan
          </p>
          <div className="package-chips">
            <button
              type="button"
              className={`package-chip ${frequency === 'single' ? 'is-active' : ''}`}
              onClick={() => setFrequency('single')}
            >
              <span>{isShift ? '1 Shift' : '1 Visit'}</span>
              <small>Pay as you go</small>
            </button>
            <button
              type="button"
              className={`package-chip ${frequency === 'triple' ? 'is-active' : ''}`}
              onClick={() => setFrequency('triple')}
            >
              <span>3 Sessions</span>
              <small className="discount-tag">10% OFF</small>
            </button>
            <button
              type="button"
              className={`package-chip ${frequency === 'weekly' ? 'is-active' : ''}`}
              onClick={() => setFrequency('weekly')}
            >
              <span>Weekly Plan</span>
              <small className="discount-tag">15% OFF</small>
            </button>
          </div>
        </div>

        <div className="dlg-facts">
          <div>
            <span>Estimated Total</span>
            <div className="price-container">
              <strong className="dlg-price">{effectivePrice}</strong>
              {savingsText && <span className="savings-badge">{savingsText}</span>}
            </div>
          </div>
          <div>
            <span>
              <ClockIcon size={16} /> Duration
            </span>
            <strong>{s.duration}</strong>
          </div>
          <div>
            <span>
              <UserIcon size={16} /> Who Comes
            </span>
            <strong>{s.professional}</strong>
          </div>
        </div>

        <div className="dlg-lists">
          <div>
            <h4>What’s included</h4>
            <ul className="list-yes">
              {split(s.includes).map((t) => (
                <li key={t}>
                  <CheckIcon size={16} /> <span>{t}</span>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4>Not included</h4>
            <ul className="list-no">
              {split(s.notIncluded).map((t) => (
                <li key={t}>
                  <MinusIcon size={16} /> <span>{t}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Clinical Trust & Safety Guarantee Banner */}
        <div className="dlg-trust-strip">
          <div className="trust-pill">
            <ShieldIcon size={16} />
            <span>100% Police &amp; Council Verified</span>
          </div>
          <div className="trust-pill">
            <CheckIcon size={16} />
            <span>Sterile Sealed Medical Kits</span>
          </div>
          <div className="trust-pill">
            <ClockIcon size={16} />
            <span>24/7 Clinical Desk Supervision</span>
          </div>
        </div>

        {s.notes && <p className="dlg-note"><strong>Note:</strong> {s.notes}</p>}

        <div className="dlg-actions">
          <Link className="btn btn-primary btn-lg" to={`/service/${s.id}`} onClick={onClose}>
            <ArrowIcon size={18} /> Book online
          </Link>
          <a className="btn btn-outline btn-lg" href={whatsapp} target="_blank" rel="noreferrer">
            <WhatsAppIcon size={18} /> Book via WhatsApp ({effectivePrice})
          </a>
          <a className="btn btn-outline btn-lg" href={site.phoneHref}>
            <PhoneIcon size={18} /> Call Clinical Desk
          </a>
        </div>
      </div>
    </dialog>
  )
}
