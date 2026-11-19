import { useMemo, useState } from 'react'
import { AddressPicker } from '../components/AddressPicker'
import { CareIcon } from '../components/CareIcon'
import { PinIcon, ShieldIcon } from '../components/Icons'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Bill, Field, OptionCard, PageHead, Select, StepTitle, TextArea, Spinner } from '../components/ui'
import { toast } from '../lib/toast'
import { billTotal, coupons, INSTANT_SLOT, servicePrice, timeSlots, visitBill, type QuickService } from '../data/booking'
import { nurseById } from '../data/providers'
import { site } from '../data/site'
import { isCompanionService } from '../data/categories'
import { useServices } from '../state/catalog'
import { inr } from '../lib/format'
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

  // Every nursing service with a price (plus the one picked on the site, e.g. a
  // companion service). A chosen nurse's own rate wins over the catalog price.
  const options = useMemo<QuickService[]>(() => {
    const isNursing = (x: (typeof services)[number]) =>
      x.category === 'Nursing Care' || (x.alsoIn ?? []).includes('Nursing Care') || x.id === serviceId
    const out: QuickService[] = []
    for (const x of services) {
      if (!isNursing(x)) continue
      const price = nurse?.shifts.find((sh) => sh.serviceId === x.id)?.price ?? servicePrice(x)
      if (price == null) continue
      out.push({ id: x.id, title: x.name, duration: x.duration, price, icon: x.icon, description: x.description })
    }
    return out
  }, [services, serviceId, nurse])

  // The admin's top five (Services catalog → "Quick Book Nurse"), topped up in
  // catalog order if fewer than five are set.
  const quick = useMemo(() => {
    const rank = new Map(services.map((x) => [x.id, x.quickBookRank]))
    const ranked = options
      .filter((o) => rank.get(o.id) != null)
      .sort((x, y) => (rank.get(x.id) ?? 0) - (rank.get(y.id) ?? 0))
    const rest = options.filter((o) => rank.get(o.id) == null)
    return [...ranked, ...rest].slice(0, 5)
  }, [options, services])

  const slots = useMemo(() => {
    if (!slotParam || slotParam.startsWith('⚡')) return timeSlots
    return [slotParam, ...timeSlots]
  }, [slotParam])

  // Hospital Companion services are non-clinical: the desk assigns a companion, not a nurse.
  const pickedService = services.find((x) => x.id === serviceId)

  const [optionId, setOptionId] = useState(optionParam ?? serviceId ?? quick[0]?.id ?? '')
  const [slot, setSlot] = useState(slotParam && !slotParam.startsWith('⚡') ? slotParam : INSTANT_SLOT)
  const [patient, setPatient] = useState({ name: profile?.name ?? '', age: '', gender: GENDERS[0], notes: '' })
  const [couponInput, setCouponInput] = useState('')
  const [coupon, setCoupon] = useState<string | null>(null)
  const [pickingAddress, setPickingAddress] = useState(false)
  const [paying, setPaying] = useState(false)
  const [error, setError] = useState('')

  const option = options.find((o) => o.id === optionId) ?? quick[0]
  const inQuick = quick.some((o) => o.id === option?.id)
  const [showAll, setShowAll] = useState(false)
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
          <StepTitle n={1}>{companion ? 'Select service' : 'What do you need?'}</StepTitle>
          <div className="quick-nurse" role="radiogroup" aria-label="Nursing service">
            {quick.map((o) => (
              <button
                key={o.id}
                type="button"
                role="radio"
                aria-checked={o.id === option.id}
                className={`quick-nurse-tile ${o.id === option.id ? 'is-on' : ''}`}
                onClick={() => {
                  setOptionId(o.id)
                  setShowAll(false)
                }}
              >
                <span className="quick-nurse-icon">
                  <CareIcon name={o.icon} size={24} />
                </span>
                <span className="quick-nurse-name">{o.title}</span>
                <small>{inr(o.price)}</small>
              </button>
            ))}
            {options.length > quick.length && (
              <button
                type="button"
                role="radio"
                aria-checked={!inQuick}
                aria-expanded={showAll || !inQuick}
                className={`quick-nurse-tile ${!inQuick ? 'is-on' : ''}`}
                onClick={() => setShowAll((v) => !v)}
              >
                <span className="quick-nurse-icon">
                  <CareIcon name="see_all" size={24} />
                </span>
                <span className="quick-nurse-name">{inQuick ? 'Other' : option.title}</span>
                <small>{inQuick ? `${options.length - quick.length} more` : inr(option.price)}</small>
              </button>
            )}
          </div>
          {(showAll || !inQuick) && (
            <label className="quick-nurse-all">
              <span className="sr-only">All nursing services</span>
              <select
                className="input"
                value={inQuick ? '' : option.id}
                onChange={(e) => {
                  if (e.target.value) setOptionId(e.target.value)
                }}
              >
                <option value="" disabled>
                  Choose from all nursing services
                </option>
                {options
                  .filter((o) => !quick.some((q) => q.id === o.id))
                  .map((o) => (
                    <option key={o.id} value={o.id}>
                      {o.title} · {inr(o.price)}
                    </option>
                  ))}
              </select>
            </label>
          )}
        </section>

        <section className="form-section">
          <StepTitle n={2}>Timing & shift slot</StepTitle>
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
          <StepTitle n={3}>Patient information</StepTitle>
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
          <StepTitle n={4}>Bill summary</StepTitle>
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
