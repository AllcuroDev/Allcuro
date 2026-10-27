import { useState } from 'react'
import { bookingPath, customShiftPrices, slotSheetTimes, visitDurations } from '../data/booking'
import type { Nurse } from '../data/providers'
import { inr } from '../lib/format'
import { navigate } from '../router'
import { requireLogin } from '../state/auth'
import { ArrowIcon, ShieldIcon } from './Icons'
import { Link } from './Link'
import { Avatar, Modal, Rating } from './ui'

export function NurseCard({ nurse, serviceId }: { nurse: Nurse; serviceId?: string }) {
  const [slotOpen, setSlotOpen] = useState(false)
  const from = Math.min(...nurse.shifts.map((s) => s.price))

  return (
    <article className="nurse-card">
      <Link to={`/nurses/${nurse.id}`} className="nurse-card-main">
        <img src={nurse.photo} alt="" className="nurse-photo" loading="lazy" />
        <div className="nurse-card-text">
          <h3>
            {nurse.name} <ShieldIcon size={16} />
          </h3>
          <p>
            {nurse.level} · {nurse.experience} yrs exp · {nurse.city}
          </p>
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
        <span className="avail-dot">Available today</span>
        <span className="nurse-from">from {inr(from)}</span>
        <Link to={`/nurses/${nurse.id}`} className="btn btn-outline btn-sm">
          Profile
        </Link>
        <button type="button" className="btn btn-primary btn-sm" onClick={() => setSlotOpen(true)}>
          Book Slot <ArrowIcon size={16} />
        </button>
      </div>
      {slotOpen && <SlotSheet nurse={nurse} serviceId={serviceId} onClose={() => setSlotOpen(false)} />}
    </article>
  )
}

/** Visit length + arrival time for one nurse (the app's _NurseSlotBookingSheet). */
function SlotSheet({ nurse, serviceId, onClose }: { nurse: Nurse; serviceId?: string; onClose: () => void }) {
  const [duration, setDuration] = useState<string>('30min')
  const [hours, setHours] = useState(4)
  const [slot, setSlot] = useState(slotSheetTimes[0])

  const preset = visitDurations.find((d) => d.id === duration)
  const price = preset ? preset.price : (customShiftPrices[hours] ?? hours * 450)

  const proceed = () => {
    onClose()
    const durationKey = preset ? preset.id : `${hours}h`
    requireLogin(() => navigate(bookingPath({ service: serviceId, nurse: nurse.id, duration: durationKey, slot })), {
      title: 'Login to Book',
      subtitle: `Verify your mobile number to book ${nurse.name}`,
    })
  }

  return (
    <Modal onClose={onClose} labelledBy="slot-title">
      <div className="slot-head">
        <Avatar name={nurse.name} size={48} />
        <div>
          <h2 id="slot-title">{nurse.name}</h2>
          <p>
            {nurse.level} · {nurse.experience} yrs exp · ★ {nurse.rating.toFixed(1)}
          </p>
        </div>
      </div>

      <h3 className="sheet-label">Select visit duration</h3>
      <p className="sheet-hint">Price adjusts to the time and clinical work needed.</p>
      <div className="duration-grid">
        {visitDurations.map((d) => (
          <button
            key={d.id}
            type="button"
            className={`duration-tile ${duration === d.id ? 'is-active' : ''}`}
            aria-pressed={duration === d.id}
            onClick={() => setDuration(d.id)}
          >
            <strong>{d.title}</strong>
            <span className="duration-price">{inr(d.price)}</span>
            <small>{d.subtitle}</small>
          </button>
        ))}
        <button
          type="button"
          className={`duration-tile ${duration === 'custom' ? 'is-active' : ''}`}
          aria-pressed={duration === 'custom'}
          onClick={() => setDuration('custom')}
        >
          <strong>Custom</strong>
          <span className="duration-price">₹1,999+</span>
          <small>Extended Shifts</small>
        </button>
      </div>
      {duration === 'custom' && (
        <div className="chip-row hours-row">
          <span>Shift hours:</span>
          {Object.keys(customShiftPrices).map((h) => (
            <button
              key={h}
              type="button"
              className={`chip ${hours === +h ? 'is-active' : ''}`}
              aria-pressed={hours === +h}
              onClick={() => setHours(+h)}
            >
              {h}h
            </button>
          ))}
        </div>
      )}

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
          <strong>{inr(price)}</strong>
          <span>{preset ? preset.label : `${hours} Hours (Bedside Monitoring)`}</span>
        </div>
        <button type="button" className="btn btn-primary" onClick={proceed}>
          Confirm & Book <ArrowIcon size={16} />
        </button>
      </div>
    </Modal>
  )
}
