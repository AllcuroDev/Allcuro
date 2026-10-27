import { useState } from 'react'
import { BuildingIcon, CheckIcon, ShieldIcon } from '../components/Icons'
import { Link } from '../components/Link'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Bill, Field, OptionCard, PageHead, Rating, Select, StepTitle, TextArea } from '../components/ui'
import { CENTRE_DEPOSIT, billTotal, centreFormalities, roomOptions, stayDurations } from '../data/booking'
import { centreById, centres } from '../data/providers'
import { inr } from '../lib/format'
import { navigate } from '../router'
import { requireLogin, useAuth } from '../state/auth'
import { createBooking, type Payment } from '../state/bookings'
import { NotFound } from './CategoryPage'

const CENTRE_FILTERS = ['All Centres', 'Elderly', 'Rehab', 'Physiotherapy', 'Palliative']

/** Verified care centres (the app's CentresListScreen). */
export function CentresPage() {
  const [filter, setFilter] = useState(CENTRE_FILTERS[0])
  const list =
    filter === CENTRE_FILTERS[0]
      ? centres
      : centres.filter((c) => [c.type, ...c.services].some((t) => t.toLowerCase().includes(filter.toLowerCase())))

  return (
    <div className="container page">
      <PageHead back="/" title="Home Care Centres" subtitle="Physically inspected beds with 24/7 nursing" />
      <div className="chip-row filter-row" role="group" aria-label="Filter centres">
        {CENTRE_FILTERS.map((f) => (
          <button
            key={f}
            type="button"
            className={`chip ${f === filter ? 'is-active' : ''}`}
            aria-pressed={f === filter}
            onClick={() => setFilter(f)}
          >
            {f}
          </button>
        ))}
      </div>
      <div className="card-grid">
        {list.map((c) => (
          <Link key={c.id} to={`/centres/${c.id}`} className="place-card">
            <div className="place-photo">
              <img src={c.photo} alt="" loading="lazy" />
              <span className="place-badge">
                <ShieldIcon size={14} /> ALLCURO VERIFIED
              </span>
              {c.bedsLeft <= 3 && <span className="place-urgent">Only {c.bedsLeft} beds left</span>}
            </div>
            <div className="place-body">
              <div className="place-row">
                <h3>{c.name}</h3>
                <Rating value={c.rating} count={c.reviews} />
              </div>
              <p className="muted">
                {c.type} · {c.locality}, {c.city}
              </p>
              <p className="place-price">
                <strong>{inr(c.pricePerDay)}</strong> / day · {inr(c.pricePerMonth)} / month
              </p>
              <span className="muted small">
                Staff ratio {c.staffRatio} · Est. {c.since}
              </span>
            </div>
          </Link>
        ))}
        {!list.length && <p className="empty">No centres match “{filter}” yet.</p>}
      </div>
    </div>
  )
}

/** One centre with its licence, sub-scores, services and prices (the app's CentreDetailScreen). */
export function CentrePage({ id }: { id: string }) {
  const c = centreById(id)
  if (!c) return <NotFound />

  return (
    <>
      <div className="container page">
        <PageHead back="/centres" title={c.name} subtitle={`${c.type} · ${c.locality}, ${c.city}`} />
        <div className="detail-grid">
          <div className="stack">
            <div className="place-photo place-photo-lg">
              <img src={c.photo} alt={c.name} />
              <span className="place-badge">
                <ShieldIcon size={14} /> VERIFIED · {c.photoCount} photos
              </span>
            </div>
            <section className="panel">
              <Rating value={c.rating} count={c.reviews} />
              <p className="licence">LICENCE NO. {c.licence}</p>
              <p className="muted small">Registered under the Clinical Establishments Act</p>
              <p className="muted small">
                Operating since {c.since} · Staff-to-patient {c.staffRatio}
              </p>
              {c.bedsLeft <= 5 && <p className="warn-note">Only {c.bedsLeft} beds left this week</p>}
            </section>
          </div>

          <div className="stack">
            <section className="panel">
              <h3 className="panel-title">Quality sub-scores</h3>
              <ul className="score-list">
                {c.scores.map((s) => (
                  <li key={s.label}>
                    <span>{s.label}</span>
                    <span className="score-bar" aria-hidden="true">
                      <span style={{ width: `${(s.value / 5) * 100}%` }} />
                    </span>
                    <strong>{s.value.toFixed(1)}</strong>
                  </li>
                ))}
              </ul>
            </section>
            <section className="panel">
              <h3 className="panel-title">Services included</h3>
              <ul className="list-yes two-col">
                {c.services.map((s) => (
                  <li key={s}>
                    <CheckIcon size={16} /> <span>{s}</span>
                  </li>
                ))}
              </ul>
            </section>
            <section className="panel price-split">
              <div>
                <span className="muted small">Per day</span>
                <strong>{inr(c.pricePerDay)}</strong>
              </div>
              <div>
                <span className="muted small">Per month</span>
                <strong>{inr(c.pricePerMonth)}</strong>
              </div>
            </section>
            <section className="panel">
              <h3 className="panel-title">Verified reviews</h3>
              <ul className="quote-list">
                <li>
                  “Rooms were spotless and the nurses updated us daily. My father recovered faster than we expected.”
                  <small>Meera K. · Verified stay</small>
                </li>
                <li>
                  “Physio team is excellent. Food could have more variety.”
                  <small>Anand R. · Verified stay</small>
                </li>
              </ul>
            </section>
          </div>
        </div>
      </div>
      <ActionBar label="Starting from" amount={`${inr(c.pricePerDay)} / day`}>
        <Link to={`/centres/${c.id}/book`} className="btn btn-primary btn-lg">
          Check Availability
        </Link>
      </ActionBar>
    </>
  )
}

const GENDERS = ['Female', 'Male', 'Other']

/** Room, stay length, patient details and the deposit (the app's CentreBookingScreen). */
export function CentreBookingPage({ id }: { id: string }) {
  const c = centreById(id)
  const { profile } = useAuth()
  const [room, setRoom] = useState(2)
  const [stay, setStay] = useState(2)
  const [patient, setPatient] = useState({ name: profile?.name ?? '', age: '', gender: GENDERS[0], notes: '' })
  const [paying, setPaying] = useState(false)
  const [error, setError] = useState('')
  if (!c) return <NotFound />

  const r = roomOptions[room]
  const d = stayDurations[stay]
  const lines = [
    { label: `${r.title} (${d.days} days)`, amount: r.pricePerDay * d.days },
    { label: 'Refundable security deposit (held in escrow)', amount: CENTRE_DEPOSIT },
  ]

  const submit = () => {
    if (!patient.name.trim()) return setError('Please enter the patient’s name.')
    if (!parseInt(patient.age, 10)) return setError('Please enter the patient’s age.')
    setError('')
    requireLogin(() => setPaying(true), {
      title: 'Login to Confirm Admission',
      subtitle: 'Verify your mobile number to reserve the room',
    })
  }

  const onPaid = async (payment: Payment) => {
    const booking = await createBooking({
      type: 'centre',
      title: `${c.name} · ${r.title}`,
      when: `Check-in: Tomorrow, 10:00 AM · ${d.days} Days`,
      amount: billTotal(lines),
      liveStatus: 'assigned',
      patientName: patient.name.trim(),
      patientAge: parseInt(patient.age, 10),
      patientGender: patient.gender,
      address: `${c.name}, ${c.locality}, ${c.city}`,
      locality: `${c.locality}, ${c.city}`,
      providerName: c.name,
      providerPhone: c.phone,
      providerRating: c.rating,
      providerQualifications: `Field Audited · ${c.staffRatio} Staff Ratio · Licence ${c.licence}`,
      roomType: r.title,
      condition: patient.notes.trim() || undefined,
      formalities: centreFormalities,
      payment,
    })
    navigate(`/bookings/${booking.id}`, { replace: true })
  }

  return (
    <>
      <div className="container page page-narrow">
        <PageHead back={`/centres/${c.id}`} title="Care Centre Admission" subtitle={`${c.name} · ${c.locality}`} />

        <section className="form-section">
          <StepTitle n={1}>Select room / bed category</StepTitle>
          <div className="stack-sm">
            {roomOptions.map((o, i) => (
              <OptionCard key={o.title} name="room" checked={i === room} onSelect={() => setRoom(i)}>
                <span className="option-icon">
                  <BuildingIcon />
                </span>
                <span className="option-text">
                  <strong>{o.title}</strong>
                  <small>{o.description}</small>
                </span>
                <strong className="option-price">{inr(o.pricePerDay)}/day</strong>
              </OptionCard>
            ))}
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={2}>Stay duration</StepTitle>
          <div className="duration-grid three">
            {stayDurations.map((s, i) => (
              <button
                key={s.days}
                type="button"
                className={`duration-tile ${i === stay ? 'is-active' : ''}`}
                aria-pressed={i === stay}
                onClick={() => setStay(i)}
              >
                <strong>{s.days} Days</strong>
                <small>{s.label}</small>
              </button>
            ))}
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={3}>Patient information & medical summary</StepTitle>
          <div className="panel form-grid">
            <Field
              label="Patient full name"
              placeholder="e.g. Kavita Nair"
              value={patient.name}
              onChange={(e) => setPatient({ ...patient, name: e.target.value })}
            />
            <div className="form-row">
              <Field
                label="Age"
                inputMode="numeric"
                value={patient.age}
                onChange={(e) => setPatient({ ...patient, age: e.target.value.replace(/\D/g, '').slice(0, 3) })}
              />
              <Select
                label="Gender"
                options={GENDERS}
                value={patient.gender}
                onChange={(e) => setPatient({ ...patient, gender: e.target.value })}
              />
            </div>
            <TextArea
              label="Medical condition & rehab goals"
              placeholder="e.g. Post-stroke rehabilitation and medication assistance"
              value={patient.notes}
              onChange={(e) => setPatient({ ...patient, notes: e.target.value })}
            />
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={4}>Bring these to the centre desk</StepTitle>
          <ul className="panel list-yes">
            <li>
              <CheckIcon size={16} /> <span>Share your check-in OTP with the receptionist</span>
            </li>
            {centreFormalities
              .filter((f) => !f.includes('OTP'))
              .map((f) => (
                <li key={f}>
                  <CheckIcon size={16} /> <span>{f}</span>
                </li>
              ))}
          </ul>
        </section>

        <section className="form-section">
          <StepTitle n={5}>Pricing breakdown</StepTitle>
          <div className="panel">
            <Bill lines={lines} />
          </div>
        </section>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
      </div>

      <ActionBar label="Total estimate" amount={inr(billTotal(lines))}>
        <button type="button" className="btn btn-primary btn-lg" onClick={submit}>
          Confirm Admission & Get Pass
        </button>
      </ActionBar>

      {paying && (
        <PaymentDialog
          title={`${c.name} · ${r.title} · ${d.days} days`}
          lines={lines}
          onClose={() => setPaying(false)}
          onPaid={onPaid}
        />
      )}
    </>
  )
}
