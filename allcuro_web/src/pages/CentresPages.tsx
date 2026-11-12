import { useState } from 'react'
import { BuildingIcon, CheckIcon, ShieldIcon } from '../components/Icons'
import { Link } from '../components/Link'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Bill, Field, OptionCard, PageHead, PageLoading, Rating, Select, StepTitle, TextArea } from '../components/ui'
import { CENTRE_DEPOSIT, billTotal, centreFormalities, stayDurations } from '../data/booking'
import { centreById, centres, type Centre } from '../data/providers'
import { site } from '../data/site'
import { inr } from '../lib/format'
import { navigate } from '../router'
import { requireLogin, useAuth } from '../state/auth'
import { createBooking, type Payment } from '../state/bookings'
import { contentReady } from '../state/content'
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
              <CentrePhoto c={c} />
              <span className="place-badge">
                <ShieldIcon size={14} /> ALLCURO VERIFIED
              </span>
              {c.bedsLeft > 0 && c.bedsLeft <= 3 && <span className="place-urgent">Only {c.bedsLeft} beds left</span>}
            </div>
            <div className="place-body">
              <div className="place-row">
                <h3>{c.name}</h3>
                <Rating value={c.rating} count={c.reviews} />
              </div>
              <p className="muted">
                {c.type} · {c.locality}, {c.city}
              </p>
              <CentrePrice c={c} />
              <span className="muted small">
                {[c.staffRatio && `Staff ratio ${c.staffRatio}`, c.since && `Est. ${c.since}`].filter(Boolean).join(' · ')}
              </span>
            </div>
          </Link>
        ))}
        {!list.length && (
          <p className="empty">
            {!contentReady()
              ? 'Loading centres…'
              : centres.length
                ? `No centres match “${filter}” yet.`
                : 'No verified care centres are listed yet. Call our care desk and we’ll help you find one.'}
          </p>
        )}
      </div>
    </div>
  )
}

/** One centre with its licence, sub-scores, services and prices (the app's CentreDetailScreen). */
export function CentrePage({ id }: { id: string }) {
  const c = centreById(id)
  if (!c) return contentReady() ? <NotFound /> : <PageLoading />

  return (
    <>
      <div className="container page">
        <PageHead back="/centres" title={c.name} subtitle={`${c.type} · ${c.locality}, ${c.city}`} />
        <div className="detail-grid">
          <div className="stack">
            <div className="place-photo place-photo-lg">
              <CentrePhoto c={c} />
              <span className="place-badge">
                <ShieldIcon size={14} /> VERIFIED{c.photoCount > 1 ? ` · ${c.photoCount} photos` : ''}
              </span>
            </div>
            <section className="panel">
              <Rating value={c.rating} count={c.reviews} />
              {c.licence && (
                <>
                  <p className="licence">LICENCE NO. {c.licence}</p>
                  <p className="muted small">Registered under the Clinical Establishments Act</p>
                </>
              )}
              <p className="muted small">
                {[c.since && `Operating since ${c.since}`, c.staffRatio && `Staff-to-patient ${c.staffRatio}`].filter(Boolean).join(' · ')}
              </p>
              {c.bedsLeft > 0 && c.bedsLeft <= 5 && <p className="warn-note">Only {c.bedsLeft} beds left this week</p>}
            </section>
          </div>

          <div className="stack">
            {c.about && (
              <section className="panel">
                <h3 className="panel-title">About the centre</h3>
                <p>{c.about}</p>
              </section>
            )}
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
            {c.roomTypes.length > 0 && (
              <section className="panel">
                <h3 className="panel-title">Room types</h3>
                <div className="tag-row">
                  {c.roomTypes.map((r) => (
                    <span key={r} className="tag">
                      {r}
                    </span>
                  ))}
                </div>
              </section>
            )}
            {c.pricePerDay != null && (
              <section className="panel price-split">
                <div>
                  <span className="muted small">Per day</span>
                  <strong>{inr(c.pricePerDay)}</strong>
                </div>
                {c.pricePerMonth != null && (
                  <div>
                    <span className="muted small">Per month</span>
                    <strong>{inr(c.pricePerMonth)}</strong>
                  </div>
                )}
              </section>
            )}
          </div>
        </div>
      </div>
      {c.pricePerDay != null ? (
        <ActionBar label="Starting from" amount={`${inr(c.pricePerDay)} / day`}>
          <Link to={`/centres/${c.id}/book`} className="btn btn-primary btn-lg">
            Check Availability
          </Link>
        </ActionBar>
      ) : (
        <ActionBar label="Pricing" amount="On request">
          <a href={site.phoneHref} className="btn btn-primary btn-lg">
            Call {site.phoneDisplay}
          </a>
        </ActionBar>
      )}
    </>
  )
}

const GENDERS = ['Female', 'Male', 'Other']

/** Room, stay length, patient details and the deposit (the app's CentreBookingScreen). */
export function CentreBookingPage({ id }: { id: string }) {
  const c = centreById(id)
  const { profile } = useAuth()
  const [room, setRoom] = useState(0)
  const [stay, setStay] = useState(2)
  const [patient, setPatient] = useState({ name: profile?.name ?? '', age: '', gender: GENDERS[0], notes: '' })
  const [paying, setPaying] = useState(false)
  const [error, setError] = useState('')
  if (!c) return contentReady() ? <NotFound /> : <PageLoading />
  if (c.pricePerDay == null) return <NotFound />

  const roomOptions = centreRooms(c)
  const r = roomOptions[room] ?? roomOptions[0]
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
      providerRating: c.rating ?? 0,
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

/** The centre's room types, each at its admin-set daily price. */
function centreRooms(c: Centre) {
  const price = c.pricePerDay ?? 0
  const titles = c.roomTypes.length ? c.roomTypes : ['Standard bed']
  return titles.map((title) => ({ title, description: c.services.slice(0, 3).join(' · '), pricePerDay: price }))
}

function CentrePhoto({ c }: { c: Centre }) {
  if (c.photo) return <img src={c.photo} alt="" loading="lazy" />
  return (
    <span className="place-photo-empty" aria-hidden="true">
      <BuildingIcon size={40} />
    </span>
  )
}

function CentrePrice({ c }: { c: Centre }) {
  if (c.pricePerDay == null) return <p className="place-price muted">Price on request</p>
  return (
    <p className="place-price">
      {c.discountPercent > 0 && c.mrpPerDay != null && <s className="muted">{inr(c.mrpPerDay)}</s>} <strong>{inr(c.pricePerDay)}</strong> / day
      {c.pricePerMonth != null && <> · {inr(c.pricePerMonth)} / month</>}
    </p>
  )
}
