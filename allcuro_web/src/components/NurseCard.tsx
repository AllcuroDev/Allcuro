import { useState } from 'react'
import { bookingPath, slotSheetTimes } from '../data/booking'
import { kindLabel, lowestPrice, type Nurse } from '../data/providers'
import { site } from '../data/site'
import { inr, ratingText } from '../lib/format'
import { navigate } from '../router'
import { requireLogin } from '../state/auth'
import { ArrowIcon, ShieldIcon } from './Icons'
import { Link } from './Link'
import { Avatar, Modal, PartnerPhoto, Rating } from './ui'

/** An approved partner on a list: photo, qualification, tags and the admin-set "from" price. */
export function NurseCard({ nurse, serviceId }: { nurse: Nurse; serviceId?: string }) {
  const [slotOpen, setSlotOpen] = useState(false)
  const from = lowestPrice(nurse)
  return (
    <article className="nurse-card">
      <Link to={`/nurses/${nurse.id}`} className="nurse-card-main">
        <PartnerPhoto src={nurse.photo} name={nurse.name} className="nurse-photo" size={72} />
        <div className="nurse-card-text">
          <h3>
            {nurse.name} <ShieldIcon size={16} />
          </h3>
          <p>{[nurse.level || kindLabel[nurse.kind], nurse.experience ? `${nurse.experience} yrs exp` : '', nurse.city].filter(Boolean).join(' · ')}</p>
          <div className="tag-row">
            {nurse.tags.slice(0, 3).map((t) => (
              <span key={t} className="tag">
                {t}
              </span>
            ))}
          </div>
        </div>
        <Rating value={nurse.rating} count={nurse.reviews} />
      </Link>
      <div className="nurse-card-foot">
        <span className={nurse.available ? 'avail-dot' : 'muted'}>{nurse.available ? 'Available' : 'Busy right now'}</span>
        <span className="nurse-from">{from != null ? `from ${inr(from)}` : 'Price on request'}</span>
        <Link to={`/nurses/${nurse.id}`} className="btn btn-outline btn-sm">
          Profile
        </Link>
        {from != null ? (
          <button type="button" className="btn btn-primary btn-sm" onClick={() => setSlotOpen(true)}>
            Book Slot <ArrowIcon size={16} />
          </button>
        ) : (
          <a className="btn btn-primary btn-sm" href={site.phoneHref}>
            Call to book
          </a>
        )}
      </div>
      {slotOpen && <SlotSheet nurse={nurse} serviceId={serviceId} onClose={() => setSlotOpen(false)} />}
    </article>
  )
}

/** Pick one of the partner's rates + an arrival time (the app's _NurseSlotBookingSheet). */
function SlotSheet({ nurse, serviceId, onClose }: { nurse: Nurse; serviceId?: string; onClose: () => void }) {
  const initial = Math.max(
    0,
    nurse.shifts.findIndex((s) => s.serviceId && s.serviceId === serviceId),
  )
  const [rate, setRate] = useState(initial)
  const [slot, setSlot] = useState(slotSheetTimes[0])
  const picked = nurse.shifts[rate]

  const proceed = () => {
    onClose()
    requireLogin(
      () => navigate(bookingPath({ service: picked?.serviceId ?? serviceId, nurse: nurse.id, option: picked?.serviceId ?? `rate-${rate}`, slot })),
      { title: 'Login to Book', subtitle: `Verify your mobile number to book ${nurse.name}` },
    )
  }

  return (
    <Modal onClose={onClose} labelledBy="slot-title">
      <div className="slot-head">
        <Avatar name={nurse.name} size={48} />
        <div>
          <h2 id="slot-title">{nurse.name}</h2>
          <p>
            {nurse.level} · {nurse.experience} yrs exp · {ratingText(nurse.rating, nurse.reviews)}
          </p>
        </div>
      </div>

      <h3 className="sheet-label">Select a service</h3>
      <div className="duration-grid">
        {nurse.shifts.map((s, i) => (
          <button
            key={`${s.label}-${i}`}
            type="button"
            className={`duration-tile ${rate === i ? 'is-active' : ''}`}
            aria-pressed={rate === i}
            onClick={() => setRate(i)}
          >
            <strong>{s.label}</strong>
            <span className="duration-price">
              {s.mrp > s.price && <s className="muted">{inr(s.mrp)}</s>} {inr(s.price)}
            </span>
            <small>{s.unit}</small>
          </button>
        ))}
      </div>

      <h3 className="sheet-label">Preferred arrival time</h3>
      <div className="chip-row">
        {slotSheetTimes.map((s) => (
          <button
            key={s}
            type="button"
            className={`chip ${slot === s ? 'is-active' : ''}`}
            aria-pressed={slot === s}
            onClick={() => setSlot(s)}
          >
            {s}
          </button>
        ))}
      </div>

      <div className="sheet-total">
        <div>
          <strong>{picked ? inr(picked.price) : '—'}</strong>
          <span>{picked?.label}</span>
        </div>
        <button type="button" className="btn btn-primary" onClick={proceed} disabled={!picked}>
          Confirm & Book <ArrowIcon size={16} />
        </button>
      </div>
    </Modal>
  )
}
