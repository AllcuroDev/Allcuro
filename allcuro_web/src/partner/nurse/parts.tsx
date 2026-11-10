import { useId, useState, type ReactNode } from 'react'
import { Modal } from '../../components/ui'
import { toast } from '../../lib/toast'
import { PIcon } from '../ui'
import { SOS_PHONE } from './data'
import { telUrl } from './state'
import './nurse.css'

// Small building blocks shared by the nurse pages.

/** Heading for the tab pages (Requests / Schedule) — the app's ScreenHeader without a back button. */
export function PageIntro({ title, subtitle, aside }: { title: string; subtitle?: string; aside?: ReactNode }) {
  return (
    <div className="pn-intro">
      <div>
        <h1>{title}</h1>
        {subtitle && <p>{subtitle}</p>}
      </div>
      {aside}
    </div>
  )
}

export function ProgressBar({ value, tone = 'primary', label }: { value: number; tone?: 'primary' | 'ok' | 'amber'; label: string }) {
  const pct = Math.max(0, Math.min(100, value))
  return (
    <div className={`pn-progress is-${tone}`} role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(pct)} aria-label={label}>
      <span style={{ width: `${pct}%` }} />
    </div>
  )
}

export function Stars({ value, size = 16 }: { value: number; size?: number }) {
  return (
    <span className="pn-stars" role="img" aria-label={`${value} out of 5 stars`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <span key={i} className={i <= Math.round(value) ? 'is-on' : ''}>
          <PIcon name="star" size={size} />
        </span>
      ))}
    </span>
  )
}

/** Red SOS pill + the "Emergency SOS" confirmation dialog (home and visit screens). */
export function SosButton({ text, gps, callLabel, sentMessage }: { text: string; gps: string; callLabel: string; sentMessage: string }) {
  const [open, setOpen] = useState(false)
  const id = useId()
  return (
    <>
      <button type="button" className="pn-sos" onClick={() => setOpen(true)} aria-haspopup="dialog">
        <PIcon name="sos" size={16} /> SOS
      </button>
      {open && (
        <Modal onClose={() => setOpen(false)} labelledBy={id} className="pn-modal">
          <div className="pn-sos-head">
            <span className="pn-sos-icon">
              <PIcon name="sos" size={22} />
            </span>
            <h2 id={id}>Emergency SOS</h2>
          </div>
          <p className="pn-modal-text">{text}</p>
          <div className="pn-gps">
            <PIcon name="pin" size={18} />
            <span>{gps}</span>
          </div>
          <div className="pn-modal-actions">
            <button type="button" className="p-btn p-btn-ghost pn-muted-btn" onClick={() => setOpen(false)}>
              Cancel
            </button>
            <a
              href={telUrl(SOS_PHONE)}
              className="p-btn p-btn-danger"
              onClick={() => {
                setOpen(false)
                toast(sentMessage, 'danger')
              }}
            >
              <PIcon name="phone" size={16} /> {callLabel}
            </a>
          </div>
        </Modal>
      )}
    </>
  )
}
