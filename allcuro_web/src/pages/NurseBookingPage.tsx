import { useMemo, useState } from 'react'
import { AddressPicker } from '../components/AddressPicker'
import { CareIcon } from '../components/CareIcon'
import { PinIcon, ShieldIcon } from '../components/Icons'
import { Link } from '../components/Link'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Avatar, Bill, Field, OptionCard, PageHead, Select, StepTitle, TextArea, Spinner } from '../components/ui'
import { toast } from '../lib/toast'
import {
  billTotal,
  coupons,
  customShiftPrices,
  INSTANT_SLOT,
  quickServices,
  timeSlots,
  visitBill,
  visitDurations,
  type QuickService,
} from '../data/booking'
import { nurseById, nurses } from '../data/providers'
import { services } from '../data/services'
import { inr, priceFrom } from '../lib/format'
import { navigate, useQuery } from '../router'
import { requireLogin, useAuth } from '../state/auth'
import { createBooking, type Payment } from '../state/bookings'
import { fullAddress, useLocation } from '../state/location'

const GENDERS = ['Male', 'Female', 'Other']

/** Price for the visit length picked in the "Book Slot" sheet, e.g. "1hr" or "8h". */
function durationOption(key: string | null): { label: string; price: number } | null {
  if (!key) return null
  const preset = visitDurations.find((d) => d.id === key)
  if (preset) return { label: preset.label, price: preset.price }
  const hours = parseInt(key, 10)
  if (!hours) return null
  return { label: `${hours} Hours (Bedside Monitoring)`, price: customShiftPrices[hours] ?? hours * 450 }
}

/** Home nurse booking (the app's NurseQuickBookingScreen), reached from a service, a nurse, or the 45-min shortcut. */
export function NurseBookingPage() {
  const serviceId = useQuery('service')
  const nurseId = useQuery('nurse')
  const durationKey = useQuery('duration')
  const slotParam = useQuery('slot')
  const { profile } = useAuth()
  const { current } = useLocation()

  // The service picked on the site goes first; the app's four quick options follow.
  const options = useMemo<QuickService[]>(() => {
    const s = services.find((x) => x.id === serviceId)
    if (!s) return quickServices
    const d = durationOption(durationKey)
    const picked: QuickService = {
      id: s.id,
      title: s.name,
      duration: d ? d.label : s.duration,
      price: d ? d.price : priceFrom(s.price),
      icon: s.icon,
      description: s.description,
    }
    return [picked, ...quickServices]
  }, [serviceId, durationKey])

  const slots = useMemo(() => {
    if (!slotParam || slotParam.startsWith('⚡')) return timeSlots
    return [slotParam, ...timeSlots]
  }, [slotParam])

  const [optionId, setOptionId] = useState(options[serviceId ? 0 : 1]?.id ?? options[0].id)
  const [slot, setSlot] = useState(slotParam && !slotParam.startsWith('⚡') ? slotParam : INSTANT_SLOT)
  const [patient, setPatient] = useState({ name: profile?.name ?? '', age: '', gender: GENDERS[0], notes: '' })
  const [couponInput, setCouponInput] = useState('')
  const [coupon, setCoupon] = useState<string | null>(null)
  const [pickingAddress, setPickingAddress] = useState(false)
  const [paying, setPaying] = useState(false)
  const [error, setError] = useState('')

  const option = options.find((o) => o.id === optionId) ?? options[0]
  const nurse = nurseById(nurseId) ?? nurses[0]
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
      title: `${nurse.name} (${nurse.level}) · ${option.title}`,
      when: slot,
      amount: total,
      liveStatus: 'assigned',
      startTrip: instant,
      patientName: patient.name.trim(),
      patientAge: parseInt(patient.age, 10),
      patientGender: patient.gender,
      address: fullAddress(current),
      locality: current.locality,
      providerName: nurse.name,
      providerPhone: '+91 98450 12345',
      providerRating: nurse.rating,
      providerQualifications: `${nurse.level} · ${nurse.experience} yrs exp · HPR Verified`,
      condition: patient.notes.trim() || option.title,
      formalities: [],
      payment,
    })
    navigate(`/bookings/${booking.id}`, { replace: true })
  }

  return (
    <>
      <div className="container page page-narrow">
        <PageHead back="/" title="Quick Nurse Booking" subtitle="Verified home nursing delivered in 30–45 mins" />

        <p className="trust-note">
          <ShieldIcon size={20} /> 100% Govt ID & HPR registered nurses · Police checked · Clinical-grade safety
        </p>

        <section className="form-section">
          <StepTitle n={1}>Select nursing service</StepTitle>
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
          <StepTitle n={2}>Your nurse</StepTitle>
          <div className="panel nurse-pick">
            <Avatar name={nurse.name} />
            <div>
              <strong>{nurse.name}</strong>
              <span>
                {nurse.level} · {nurse.experience} yrs · ★ {nurse.rating.toFixed(1)}
              </span>
              {!nurseId && <small>Best-matched verified nurse near you</small>}
            </div>
            <Link to={serviceId ? `/service/${serviceId}` : '/nurses'} className="link-btn">
              Change
            </Link>
          </div>
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
          {paying ? <Spinner /> : 'Book Nurse Now'}
        </button>
      </ActionBar>

      {pickingAddress && <AddressPicker onClose={() => setPickingAddress(false)} />}
      {paying && (
        <PaymentDialog
          title={`${option.title} · ${nurse.name}`}
          lines={lines}
          allowPayLater
          onClose={() => setPaying(false)}
          onPaid={onPaid}
        />
      )}
    </>
  )
}
