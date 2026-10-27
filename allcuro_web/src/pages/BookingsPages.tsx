import { lazy, Suspense, useState } from 'react'
import {
  AlertIcon,
  BoltIcon,
  BoxIcon,
  BuildingIcon,
  NavigateIcon,
  NurseIcon,
  PhoneIcon,
  ShieldIcon,
  StarIcon,
} from '../components/Icons'
import { Link } from '../components/Link'
import { Avatar, Bill, Modal, PageHead, StepList, type Step } from '../components/ui'
import { toast } from '../lib/toast'
import { ROUTE_METRES } from '../data/route'
import { site } from '../data/site'
import { inr, useNow } from '../lib/format'
import { useAuth } from '../state/auth'
import {
  ASSIGN_MS,
  isActive,
  liveStatusAt,
  rateBooking,
  statusLabel,
  tripProgress,
  useBooking,
  useBookings,
  type Booking,
  type LiveStatus,
} from '../state/bookings'
import { NotFound } from './CategoryPage'
import { SignInPrompt } from './AccountPages'

// Leaflet is only needed on the live tracker, so it loads with it.
const LiveMap = lazy(() => import('../components/LiveMap').then((m) => ({ default: m.LiveMap })))

const TYPE_ICON = { nurse: NurseIcon, centre: BuildingIcon, equipment: BoxIcon }
const DETAIL_CTA = {
  nurse: 'Live Track Nurse & View OTP',
  centre: 'View Digital Admission Pass & OTP',
  equipment: 'Track Delivery',
}

/** Nurses, centres & equipment in one list (the app's BookingsScreen). */
export function BookingsPage() {
  const { isLoggedIn } = useAuth()
  const bookings = useBookings()
  const now = useNow(5000)
  const [tab, setTab] = useState<'active' | 'past'>('active')

  if (!isLoggedIn) {
    return (
      <div className="container page page-narrow">
        <PageHead back="/" title="My Bookings" subtitle="Nurses, centres & equipment" />
        <SignInPrompt reason="Sign in to see and track your bookings." />
      </div>
    )
  }

  const list = bookings.filter((b) => (tab === 'active' ? isActive(b) : !isActive(b)))

  return (
    <div className="container page page-narrow">
      <PageHead back="/" title="My Bookings" subtitle="Nurses, centres & equipment" />
      <div className="seg" role="tablist" aria-label="Booking status">
        {(['active', 'past'] as const).map((t) => (
          <button key={t} type="button" role="tab" aria-selected={tab === t} onClick={() => setTab(t)}>
            {t === 'active' ? 'Active & upcoming' : 'Past'}
          </button>
        ))}
      </div>

      {list.length === 0 ? (
        <div className="empty">
          <p>{tab === 'active' ? 'No active bookings right now.' : 'No past bookings yet.'}</p>
          <div className="row-actions">
            <Link to="/book-nurse" className="btn btn-primary">
              <BoltIcon /> Book a nurse in 45 mins
            </Link>
            <Link to="/services/all" className="btn btn-outline">
              See all services
            </Link>
          </div>
        </div>
      ) : (
        <div className="stack">
          {list.map((b) => {
            const Icon = TYPE_ICON[b.type]
            const done = !isActive(b)
            return (
              <article key={b.id} className="booking-card">
                <div className="booking-card-head">
                  <span className="booking-icon">
                    <Icon />
                  </span>
                  <div>
                    <h3>{b.title}</h3>
                    <p>{b.when}</p>
                  </div>
                  <span className={`status-pill ${done ? 'is-muted' : ''}`}>{statusLabel(b, now)}</span>
                </div>
                <div className="booking-card-foot">
                  {done ? <span className="muted small">{b.id}</span> : <span className="otp-chip">OTP: {b.otp}</span>}
                  <strong>{inr(b.amount)}</strong>
                </div>
                <Link to={`/bookings/${b.id}`} className={`btn ${done ? 'btn-outline' : 'btn-primary'} btn-block`}>
                  {done ? 'View details' : DETAIL_CTA[b.type]}
                </Link>
              </article>
            )
          })}
        </div>
      )}
    </div>
  )
}

/** Routes a booking to its tracker: live nurse visit, centre admission pass, or equipment delivery. */
export function BookingDetailPage({ id }: { id: string }) {
  const { isLoggedIn } = useAuth()
  const booking = useBooking(id)
  if (!isLoggedIn) {
    return (
      <div className="container page page-narrow">
        <PageHead back="/bookings" title="Booking" />
        <SignInPrompt reason="Sign in to view this booking." />
      </div>
    )
  }
  if (!booking) return <NotFound />
  if (booking.type === 'centre') return <CentrePass booking={booking} />
  if (booking.type === 'equipment') return <EquipmentTracker booking={booking} />
  return <NurseTracker booking={booking} />
}

// ---- Nurse visit tracker (the app's NurseBookingTrackerScreen) ----

const VISIT_ORDER: LiveStatus[] = ['assigned', 'enRoute', 'reached', 'inProgress', 'completed']

function NurseTracker({ booking: b }: { booking: Booking }) {
  const now = useNow(1000)
  const status = liveStatusAt(b, now)
  const progress = tripProgress(b, now)
  const first = b.providerName.split(' ')[0]
  const [sos, setSos] = useState(false)
  const [rating, setRating] = useState(false)
  const scheduled = !b.tripStartedAt && status === 'assigned'
  const showMap = status === 'enRoute' || (!!b.tripStartedAt && status === 'assigned')
  const minsLeft = Math.max(1, Math.ceil((1 - progress) * 30))
  const kmLeft = ((1 - progress) * ROUTE_METRES) / 1000

  const steps: Step[] = [
    { title: 'Nurse Assigned', subtitle: `${b.providerName} (${b.providerQualifications})` },
    {
      title: 'Nurse En Route',
      subtitle: scheduled ? `Leaves in time for your slot: ${b.when}` : `${first} is travelling to ${b.locality}`,
    },
    { title: 'Arrival & Selfie Verified', subtitle: 'GPS geofence match at your address' },
    { title: 'Service in Progress', subtitle: 'Digital clinical vitals logging active' },
    { title: 'Service Completed', subtitle: 'Final medical report filed with ALLCURO' },
  ]
  const current = status === 'completed' ? steps.length : VISIT_ORDER.indexOf(status)

  return (
    <div className="container page page-narrow">
      <PageHead
        back="/bookings"
        title={
          <>
            {b.id} <span className="status-pill">{statusLabel(b, now)}</span>
          </>
        }
        subtitle={b.title}
        aside={
          <button type="button" className="btn btn-danger btn-sm" onClick={() => setSos(true)}>
            <AlertIcon /> SOS
          </button>
        }
      />

      <div className="stack">
        {showMap && (
          <section className="map-card">
            <Suspense fallback={<div className="live-map" />}>
              <LiveMap progress={progress} nurseName={b.providerName} />
            </Suspense>
            <div className="map-eta">
              <strong>{status === 'assigned' ? `${first} is getting ready` : `Arriving in ${minsLeft} min`}</strong>
              <span>
                {status === 'assigned'
                  ? 'Live location appears as soon as the trip starts'
                  : `${first} is on the way · ${kmLeft.toFixed(1)} km away`}
              </span>
            </div>
          </section>
        )}
        {status === 'reached' && (
          <p className="arrived-note" role="status">
            <ShieldIcon /> {first} has arrived — share your OTP to start the visit.
          </p>
        )}

        {status !== 'completed' && (
          <OtpCard
            label="SERVICE VERIFICATION OTP"
            badge="CONFIDENTIAL"
            otp={b.otp}
            note={`Share this 4-digit code with ${b.providerName} on arrival to securely start your visit.`}
          />
        )}

        <section className="panel">
          <div className="panel-head">
            <h2 className="panel-title">Live Visit Status</h2>
            {status === 'enRoute' && <span className="eta-pill">⚡ ETA {minsLeft} mins</span>}
            {status === 'assigned' && b.tripStartedAt && (
              <span className="eta-pill">Starting in {Math.ceil((ASSIGN_MS - (now - b.tripStartedAt)) / 1000)}s</span>
            )}
          </div>
          <StepList steps={steps} current={current} />
        </section>

        <section className="panel">
          <div className="provider-row">
            <Avatar name={b.providerName} size={52} />
            <div>
              <strong>
                {b.providerName} <ShieldIcon size={16} />
              </strong>
              <span>{b.providerQualifications}</span>
              <span className="rating">
                <StarIcon size={15} /> {b.providerRating} · verified visits
              </span>
            </div>
          </div>
          <div className="row-actions">
            <a className="btn btn-primary" href={`tel:${b.providerPhone.replace(/\s/g, '')}`}>
              <PhoneIcon size={18} /> Call Nurse
            </a>
            <button type="button" className="btn btn-outline" onClick={() => setRating(true)}>
              <StarIcon /> {b.rating ? `Rated ${'★'.repeat(b.rating.stars)}` : 'Rate Nurse'}
            </button>
          </div>
        </section>

        <section className="panel">
          <div className="panel-head">
            <h2 className="panel-title">Real-Time Clinical Vitals</h2>
            {status === 'inProgress' && <span className="live-sync">Live Sync</span>}
          </div>
          <p className="vitals-box">
            {b.vitalsSummary ??
              (status === 'inProgress'
                ? 'Vitals logging in progress by your nurse…'
                : 'Vitals will appear here once measured by your nurse.')}
          </p>
        </section>

        <PatientCard booking={b} />
        <PaymentCard booking={b} />

        <Link to="/bookings" className="btn btn-outline btn-lg btn-block">
          Back to My Bookings
        </Link>
      </div>

      {sos && <SosDialog onClose={() => setSos(false)} />}
      {rating && <RatingDialog booking={b} onClose={() => setRating(false)} />}
    </div>
  )
}

// ---- Centre admission pass (the app's CentreVisitPassScreen) ----

const ADMISSION_STEPS: Step[] = [
  { title: 'Digital Pass Issued', subtitle: 'Room reserved & deposit confirmed in escrow' },
  { title: 'Travel to Care Centre', subtitle: 'Check-in scheduled for 10:00 AM' },
  { title: 'OTP Verification at Reception', subtitle: 'Staff verifies OTP & completes documentation' },
  { title: 'Room Allotted & Admitted', subtitle: 'Care attendant & clinical routine initiated' },
]

function CentrePass({ booking: b }: { booking: Booking }) {
  const maps = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(b.address)}`
  return (
    <div className="container page page-narrow">
      <PageHead
        back="/bookings"
        title={
          <>
            {b.id} <span className="status-pill">DIGITAL PASS ACTIVE</span>
          </>
        }
        subtitle={b.providerName}
      />
      <div className="stack">
        <OtpCard
          label="CENTRE CHECK-IN PASS & OTP"
          badge="CONFIRMED"
          otp={b.otp}
          note={`Show this 4-digit OTP at the ${b.providerName} reception desk on arrival to verify your booking and begin check-in.`}
        />

        <section className="panel">
          <div className="provider-row">
            <span className="booking-icon">
              <BuildingIcon />
            </span>
            <div>
              <strong>{b.providerName}</strong>
              <span className="accent">{b.roomType ?? 'Deluxe Room'}</span>
              <span>{b.address}</span>
              <span>{b.when}</span>
            </div>
          </div>
          <div className="row-actions">
            <a className="btn btn-outline" href={maps} target="_blank" rel="noreferrer">
              <NavigateIcon /> Google Maps
            </a>
            <a className="btn btn-primary" href={`tel:${b.providerPhone.replace(/\s/g, '')}`}>
              <PhoneIcon size={18} /> Call Centre
            </a>
          </div>
        </section>

        <section className="panel">
          <div className="panel-head">
            <h2 className="panel-title">Admission formalities & documents</h2>
            <span className="live-sync">Bring with you</span>
          </div>
          <ul className="list-yes">
            {b.formalities.map((f) => (
              <li key={f}>
                <ShieldIcon size={16} /> <span>{f}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className="panel">
          <h2 className="panel-title">Admission flow</h2>
          <StepList steps={ADMISSION_STEPS} current={1} />
        </section>

        <PatientCard booking={b} />
        <PaymentCard booking={b} />

        <Link to="/bookings" className="btn btn-outline btn-lg btn-block">
          Back to My Bookings
        </Link>
      </div>
    </div>
  )
}

// ---- Equipment delivery ----

function EquipmentTracker({ booking: b }: { booking: Booking }) {
  const delivered = b.liveStatus === 'inProgress' || b.liveStatus === 'completed'
  const steps: Step[] = [
    { title: 'Order Confirmed', subtitle: 'Payment received & equipment reserved' },
    { title: 'Sanitised & Quality Checked', subtitle: 'Hospital-grade cleaning and function test' },
    { title: 'Out for Delivery', subtitle: b.when },
    { title: 'Delivered & Demonstrated', subtitle: 'Setup at home and a short how-to for the family' },
  ]
  return (
    <div className="container page page-narrow">
      <PageHead back="/bookings" title={b.id} subtitle={b.title} />
      <div className="stack">
        {!delivered && (
          <OtpCard
            label="DELIVERY OTP"
            badge="CONFIDENTIAL"
            otp={b.otp}
            note="Share this code with the delivery team once the equipment is set up and working."
          />
        )}
        <section className="panel">
          <h2 className="panel-title">Delivery status</h2>
          <StepList steps={steps} current={delivered ? steps.length : 1} />
        </section>
        <section className="panel">
          <h2 className="panel-title">Delivery address</h2>
          <p>{b.address}</p>
          <div className="row-actions">
            <a className="btn btn-primary" href={site.phoneHref}>
              <PhoneIcon size={18} /> Call Equipment Desk
            </a>
          </div>
        </section>
        <PaymentCard booking={b} />
        <Link to="/bookings" className="btn btn-outline btn-lg btn-block">
          Back to My Bookings
        </Link>
      </div>
    </div>
  )
}

// ---- Shared pieces ----

function OtpCard({ label, badge, otp, note }: { label: string; badge: string; otp: string; note: string }) {
  return (
    <section className="otp-card">
      <div className="otp-card-head">
        <span>
          <ShieldIcon size={16} /> {label}
        </span>
        <span className="otp-badge">{badge}</span>
      </div>
      <strong className="otp-code" aria-label={`OTP ${otp.split('').join(' ')}`}>
        {otp}
      </strong>
      <p>{note}</p>
    </section>
  )
}

function PatientCard({ booking: b }: { booking: Booking }) {
  if (!b.patientName) return null
  return (
    <section className="panel">
      <h2 className="panel-title">Patient & service address</h2>
      <p>
        <strong>
          {b.patientName}
          {b.patientAge ? ` (${b.patientAge}y, ${b.patientGender})` : ''}
        </strong>
      </p>
      {b.condition && <p className="accent">{b.condition}</p>}
      <p className="muted">{b.address}</p>
    </section>
  )
}

function PaymentCard({ booking: b }: { booking: Booking }) {
  if (!b.payment) {
    return (
      <section className="panel">
        <div className="panel-head">
          <h2 className="panel-title">Payment</h2>
          <strong>{inr(b.amount)}</strong>
        </div>
      </section>
    )
  }
  const p = b.payment
  return (
    <section className="panel">
      <div className="panel-head">
        <h2 className="panel-title">Payment</h2>
        <span className={`status-pill ${p.payLater ? 'is-warm' : ''}`}>{p.payLater ? 'Pay after visit' : 'Paid'}</span>
      </div>
      <Bill lines={p.lines} totalLabel={p.payLater ? 'Due after visit' : 'Total paid'} />
      {!p.payLater && (
        <p className="muted small">
          {p.method} · Ref {p.reference} · {new Date(p.paidAt).toLocaleString('en-IN')}
        </p>
      )}
    </section>
  )
}

function SosDialog({ onClose }: { onClose: () => void }) {
  return (
    <Modal onClose={onClose} labelledBy="sos-title">
      <h2 id="sos-title" className="login-title sos-title">
        <AlertIcon size={22} /> Customer SOS Helpdesk
      </h2>
      <p className="login-sub">
        Connects you directly with the ALLCURO 24×7 clinical supervisor for immediate help. In a life-threatening
        emergency, call 112 first.
      </p>
      <div className="row-actions">
        <button type="button" className="btn btn-outline" onClick={onClose}>
          Cancel
        </button>
        <a className="btn btn-danger" href={site.phoneHref} onClick={onClose}>
          <PhoneIcon size={18} /> Call SOS Helpline
        </a>
      </div>
    </Modal>
  )
}

function RatingDialog({ booking, onClose }: { booking: Booking; onClose: () => void }) {
  const [stars, setStars] = useState(booking.rating?.stars ?? 5)
  const [review, setReview] = useState(booking.rating?.review ?? '')
  return (
    <Modal onClose={onClose} labelledBy="rate-title">
      <h2 id="rate-title" className="login-title">
        Rate your nursing experience
      </h2>
      <p className="login-sub">How was your session with {booking.providerName}?</p>
      <div className="star-picker" role="radiogroup" aria-label="Rating">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            role="radio"
            aria-checked={n === stars}
            aria-label={`${n} star${n > 1 ? 's' : ''}`}
            className={n <= stars ? 'is-on' : ''}
            onClick={() => setStars(n)}
          >
            <StarIcon size={34} />
          </button>
        ))}
      </div>
      <label className="field">
        <span className="field-label">Write a review (optional)</span>
        <textarea
          className="input"
          rows={3}
          placeholder="e.g. Very gentle with wound dressing, punctual and caring."
          value={review}
          onChange={(e) => setReview(e.target.value)}
        />
      </label>
      <button
        type="button"
        className="btn btn-primary btn-lg btn-block"
        onClick={() => {
          rateBooking(booking.id, stars, review.trim())
          toast('⭐ Thank you for your feedback! Rating submitted.')
          onClose()
        }}
      >
        Submit Rating & Review
      </button>
    </Modal>
  )
}
