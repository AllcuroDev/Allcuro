import { useMemo, useState } from 'react'
import { AddressPicker } from '../components/AddressPicker'
import { CareIcon } from '../components/CareIcon'
import { PinIcon, ShieldIcon } from '../components/Icons'
import { Link } from '../components/Link'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Avatar, Bill, Field, OptionCard, PageHead, Select, StepTitle, TextArea, Spinner } from '../components/ui'
import { toast } from '../lib/toast'
import { billTotal, coupons, INSTANT_SLOT, servicePrice, timeSlots, visitBill, type QuickService } from '../data/booking'
import { nurseById } from '../data/providers'
import { site } from '../data/site'
import { isCompanionService } from '../data/categories'
import { useServices } from '../state/catalog'
import { inr, ratingText } from '../lib/format'
import { navigate, useQuery } from '../router'
import { requireLogin, useAuth } from '../state/auth'
import { createBooking, type Payment } from '../state/bookings'
import { fullAddress, useLocation } from '../state/location'

const GENDERS = ['Male', 'Female', 'Other']

/** Home nurse booking (the app's NurseQuickBookingScreen), reached from a service or a nurse. */
export function NurseBookingPage() {
  const serviceId = useQuery('service')
  const nurseId = useQuery('nurse')
  const optionParam = useQuery('option')
  const slotParam = useQuery('slot')
  const { profile } = useAuth()
  const { current } = useLocation()
  const services = useServices()

  const nurse = nurseById(nurseId) ?? null

  // The service picked on the site goes first, then the chosen partner's other
  // rates; with neither, the first few nursing services. All prices are the
  // admin's (the partner's rate card, else the catalog price less discount).
  const options = useMemo<QuickService[]>(() => {
    const out: QuickService[] = []
    const fromService = (x: (typeof services)[number], price: number | null): QuickService | null =>
      price == null
        ? null
        : { id: x.id, title: x.name, duration: x.duration, price, icon: x.icon, description: x.description }
    const s = services.find((x) => x.id === serviceId)
    if (s) {
      const own = nurse?.shifts.find((sh) => sh.serviceId === s.id)
      const o = fromService(s, own?.price ?? servicePrice(s))
      if (o) out.push(o)
    }
    nurse?.shifts.forEach((sh, i) => {
      if (s && sh.serviceId === s.id) return
      const svc = services.find((x) => x.id === sh.serviceId)
      out.push({
        id: `rate-${i}`,
        title: sh.label,
        duration: sh.unit,
        price: sh.price,
        icon: svc?.icon ?? 'home_nurse',
        description: svc?.description ?? `With ${nurse.name}`,
      })
    })
    if (!out.length)
      services
        .filter((x) => x.category === 'Nursing Care')
        .forEach((x) => {
          const o = out.length < 4 ? fromService(x, servicePrice(x)) : null
          if (o) out.push(o)
        })
    return out
  }, [services, serviceId, nurse])

  const slots = useMemo(() => {
    if (!slotParam || slotParam.startsWith('⚡')) return timeSlots
    return [slotParam, ...timeSlots]
  }, [slotParam])

  // Hospital Companion services are non-clinical: the desk assigns a companion, not a nurse.
  const pickedService = services.find((x) => x.id === serviceId)

  const [optionId, setOptionId] = useState(optionParam ?? options[0]?.id ?? '')
  const [slot, setSlot] = useState(slotParam && !slotParam.startsWith('⚡') ? slotParam : INSTANT_SLOT)
  const [patient, setPatient] = useState({ name: profile?.name ?? '', age: '', gender: GENDERS[0], notes: '' })
  const [couponInput, setCouponInput] = useState('')
  const [coupon, setCoupon] = useState<string | null>(null)
  const [pickingAddress, setPickingAddress] = useState(false)
  const [paying, setPaying] = useState(false)
  const [error, setError] = useState('')

  const option = options.find((o) => o.id === optionId) ?? options[0]
  const companion = !!pickedService && !!option && isCompanionService(pickedService) && option.id === pickedService.id
  if (!option)
    return (
      <div className="container page page-narrow">
        <PageHead back="/" title="Book a Nurse" subtitle="Prices for this booking aren’t set yet" />
        <div className="empty">
          <p>Our care desk will confirm the price and assign a verified professional.</p>
          <a className="btn btn-primary" href={site.phoneHref}>
            Call {site.phoneDisplay}
          </a>
        </div>
      </div>
    )

  const discount = coupon ? coupons[coupon].off(option.price) : 0
  const lines = visitBill(option.title, option.price, discount)
  const total = billTotal(lines)

  const applyCoupon = () => {
    const code = couponInput.trim().toUpperCase()
    if (!coupons[code]) {
      toast('That coupon code isn’t valid. Try FIRSTCARE.', 'danger')
      return
    }
    setCoupon(code)
    toast(`Coupon applied: ${coupons[code].label}`)
  }

  const submit = () => {
    if (!patient.name.trim()) return setError('Please enter the patient’s name.')
    const age = parseInt(patient.age, 10)
    if (!age || age < 0 || age > 120) return setError('Please enter the patient’s age.')
    setError('')
    requireLogin(() => setPaying(true), {
      title: 'Quick Login to Confirm',
      subtitle: 'Enter your phone number to complete and track your booking',
    })
  }

  const onPaid = async (payment: Payment) => {
    const instant = slot === INSTANT_SLOT
    const booking = await createBooking({
      type: 'nurse',
      title: companion
        ? `Hospital Companion · ${option.title}`
        : nurse
          ? `${nurse.name} (${nurse.level}) · ${option.title}`
          : option.title,
      when: slot,
      amount: total,
      liveStatus: 'assigned',
      startTrip: instant,
      patientName: patient.name.trim(),
      patientAge: parseInt(patient.age, 10),
      patientGender: patient.gender,
      address: fullAddress(current),
      locality: current.locality,
      ...(companion
        ? {
            providerName: 'ALLCURO Hospital Companion',
            providerPhone: site.phoneDisplay,
            providerRating: 0,
            providerQualifications: 'Police-verified companion · Non-clinical support',
          }
        : nurse
          ? {
              providerName: nurse.name,
              providerPhone: site.phoneDisplay,
              providerRating: nurse.rating ?? 0,
              providerQualifications: `${nurse.level} · ${nurse.experience} yrs exp · HPR Verified`,
            }
          : {
              providerName: 'ALLCURO verified nurse',
              providerPhone: site.phoneDisplay,
              providerRating: 0,
              providerQualifications: 'Assigned by the care desk',
            }),
      condition: patient.notes.trim() || option.title,
      formalities: [],
      payment,
    })
    navigate(`/bookings/${booking.id}`, { replace: true })
  }

  return (
    <>
      <div className="container page page-narrow">
        {companion ? (
          <PageHead
            back={`/service/${serviceId}`}
            title="Book a Hospital Companion"
            subtitle="Non-clinical support during a hospital visit"
          />
        ) : (
          <PageHead back="/" title="Book a Nurse" subtitle="Verified home nursing at your doorstep" />
        )}

        <p className="trust-note">
          <ShieldIcon size={20} />{' '}
          {companion
            ? 'Govt ID & police-verified companions · Non-clinical support only'
            : '100% Govt ID & HPR registered nurses · Police checked · Clinical-grade safety'}
        </p>

        <section className="form-section">
          <StepTitle n={1}>{companion ? 'Select service' : 'Select nursing service'}</StepTitle>
          <div className="stack-sm">
            {options.map((o) => (
              <OptionCard key={o.id} name="service" checked={o.id === option.id} onSelect={() => setOptionId(o.id)}>
                <span className="option-icon">
                  <CareIcon name={o.icon} size={22} />
                </span>
                <span className="option-text">
                  <strong>{o.title}</strong>
                  <small>
                    {o.duration} · {o.description}
                  </small>
                </span>
                <strong className="option-price">{inr(o.price)}</strong>
              </OptionCard>
            ))}
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={2}>{companion ? 'Your companion' : 'Your nurse'}</StepTitle>
          {companion ? (
            <div className="panel nurse-pick">
              <Avatar name="Hospital Companion" />
              <div>
                <strong>A verified ALLCURO companion will be assigned</strong>
                <small>You’ll see their name, photo ID and a visit OTP in My Bookings.</small>
              </div>
            </div>
          ) : nurse ? (
            <div className="panel nurse-pick">
              <Avatar name={nurse.name} />
              <div>
                <strong>{nurse.name}</strong>
                <span>
                  {nurse.level} · {nurse.experience} yrs · {ratingText(nurse.rating, nurse.reviews)}
                </span>
              </div>
              <Link to={serviceId ? `/service/${serviceId}` : '/nurses'} className="link-btn">
                Change
              </Link>
            </div>
          ) : (
            <div className="panel nurse-pick">
              <Avatar name="ALLCURO" />
              <div>
                <strong>Best-matched verified nurse near you</strong>
                <small>Our care desk assigns an approved nurse; you’ll see their details in My Bookings.</small>
              </div>
              <Link to="/nurses" className="link-btn">
                Choose
              </Link>
            </div>
          )}
        </section>

        <section className="form-section">
          <StepTitle n={3}>Timing & shift slot</StepTitle>
          <div className="stack-sm">
            {slots.map((s) => (
              <OptionCard key={s} name="slot" compact checked={s === slot} onSelect={() => setSlot(s)}>
                <span className="option-text">
                  <strong>{s}</strong>
                </span>
              </OptionCard>
            ))}
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={4}>Patient information</StepTitle>
          <div className="panel form-grid">
            <Field
              label="Patient full name"
              placeholder="e.g. Ramesh Iyer"
              value={patient.name}
              onChange={(e) => setPatient({ ...patient, name: e.target.value })}
            />
            <div className="form-row">
              <Field
                label="Age"
                inputMode="numeric"
                placeholder="68"
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
            <div className="field">
              <span className="field-label">Service address</span>
              <div className="address-box">
                <PinIcon />
                <span>
                  <strong>{current.title}</strong>
                  <small>{fullAddress(current)}</small>
                </span>
                <button type="button" className="link-btn" onClick={() => setPickingAddress(true)}>
                  Change
                </button>
              </div>
            </div>
            <TextArea
              label="Medical condition & special instructions"
              placeholder="e.g. Post-op knee recovery, IV antibiotics"
              value={patient.notes}
              onChange={(e) => setPatient({ ...patient, notes: e.target.value })}
            />
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={5}>Bill summary</StepTitle>
          <div className="panel">
            <div className="coupon-row">
              <input
                className="input"
                placeholder="Have a coupon? e.g. FIRSTCARE"
                value={couponInput}
                onChange={(e) => setCouponInput(e.target.value)}
                aria-label="Coupon code"
              />
              <button type="button" className="btn btn-dark" onClick={applyCoupon} disabled={!couponInput.trim()}>
                Apply
              </button>
            </div>
            <Bill lines={lines} />
          </div>
        </section>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
      </div>

      <ActionBar label="Total payable" amount={inr(total)}>
        <button type="button" className="btn btn-primary btn-lg" onClick={submit} disabled={paying}>
          {paying ? <Spinner /> : companion ? 'Book Companion' : 'Book Nurse Now'}
        </button>
      </ActionBar>

      {pickingAddress && <AddressPicker onClose={() => setPickingAddress(false)} />}
      {paying && (
        <PaymentDialog
          title={companion ? `${option.title} · Hospital Companion` : nurse ? `${option.title} · ${nurse.name}` : option.title}
          lines={lines}
          allowPayLater
          onClose={() => setPaying(false)}
          onPaid={onPaid}
        />
      )}
    </>
  )
}
