import { useNow } from '../lib/format'
import { isActive, statusLabel, useBookings } from '../state/bookings'
import { ArrowIcon, NurseIcon } from './Icons'
import { Link } from './Link'

/** Docked card for a nurse visit that's under way — the app's home-screen "live visit" popup. */
export function ActiveVisitBar() {
  const now = useNow(5000)
  const visit = useBookings().find((b) => b.type === 'nurse' && isActive(b))
  if (!visit) return null

  return (
    <Link to={`/bookings/${visit.id}`} className="visit-bar" aria-label={`Track your visit with ${visit.providerName}`}>
      <span className="booking-icon">
        <NurseIcon />
      </span>
      <span className="visit-bar-text">
        <strong>{visit.providerName}</strong>
        <small>
          Live Nurse Visit · {statusLabel(visit, now)} · OTP {visit.otp}
        </small>
      </span>
      <span className="visit-bar-cta">
        Track <ArrowIcon size={16} />
      </span>
    </Link>
  )
}
