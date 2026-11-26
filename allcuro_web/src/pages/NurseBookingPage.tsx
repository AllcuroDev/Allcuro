import { useMemo, useState, type CSSProperties } from 'react'
import { AddressPicker } from '../components/AddressPicker'
import { IconTile } from '../components/CareIcon'
import { CheckIcon, ClockIcon, PinIcon, SearchIcon, ShieldIcon } from '../components/Icons'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Bill, Field, OptionCard, PageHead, Select, StepTitle, TextArea, Spinner } from '../components/ui'
import { useCheckoutDiscount } from '../lib/coupons'
import { CouponBox } from '../components/CouponBox'
import { billTotal, INSTANT_SLOT, servicePrice, timeSlots, visitBill, type QuickService } from '../data/booking'
import { nurseById } from '../data/providers'
import { site } from '../data/site'
import { categories, categoryById, isCompanionService } from '../data/categories'
import type { Service } from '../data/types'
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
  const options = useMemo<(QuickService & { service: Service })[]>(() => {
    const isNursing = (x: (typeof services)[number]) =>
      x.category === 'Nursing Care' || (x.alsoIn ?? []).includes('Nursing Care') || x.id === serviceId
    const out: (QuickService & { service: Service })[] = []
    for (const x of services) {
      if (!isNursing(x)) continue
      const price = nurse?.shifts.find((sh) => sh.serviceId === x.id)?.price ?? servicePrice(x)
      if (price == null) continue
      out.push({ id: x.id, title: x.name, duration: x.duration, price, icon: x.icon, description: x.description, service: x })
    }
    // The admin's "Quick Book Nurse" picks lead, then the rest in catalog order.
    const rank = (o: (typeof out)[number]) => o.service.quickBookRank ?? Number.MAX_SAFE_INTEGER
    return out.sort((a, b) => rank(a) - rank(b))
  }, [services, serviceId, nurse])

  const slots = useMemo(() => {
    if (!slotParam || slotParam.startsWith('⚡')) return timeSlots
    return [slotParam, ...timeSlots]
  }, [slotParam])

  // Hospital Companion services are non-clinical: the desk assigns a companion, not a nurse.
  const pickedService = services.find((x) => x.id === serviceId)

  const [optionId, setOptionId] = useState(optionParam ?? serviceId ?? options[0]?.id ?? '')
  const [slot, setSlot] = useState(slotParam && !slotParam.startsWith('⚡') ? slotParam : INSTANT_SLOT)
  const [patient, setPatient] = useState({ name: profile?.name ?? '', age: '', gender: GENDERS[0], notes: '' })
  const [pickingAddress, setPickingAddress] = useState(false)
  const [paying, setPaying] = useState(false)
  const [error, setError] = useState('')

  const option = options.find((o) => o.id === optionId) ?? options[0]
  // The full list shows until a service is chosen; a service picked on the site starts chosen.
  const [choosing, setChoosing] = useState(!optionParam && !serviceId)
  const companion = !!pickedService && !!option && isCompanionService(pickedService) && option.id === pickedService.id
  const discounts = useCheckoutDiscount(option?.price ?? 0, 'nurse')
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

  const discount = discounts.applied?.amount ?? 0
  const lines = visitBill(option.title, option.price, discount)
  const total = billTotal(lines)

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
    // Records the coupon use (and re-checks its limits) before the booking exists.
    await discounts.redeem()
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
          {companion ? (
            <ServiceOption option={option} checked onSelect={() => {}} />
          ) : choosing ? (
            <ServicePicker
              options={options}
              selectedId={option.id}
              onSelect={(id) => {
                setOptionId(id)
                setChoosing(false)
              }}
            />
          ) : (
            <div className="svc-picked">
              <ServiceOption option={option} checked onSelect={() => setChoosing(true)} />
              <button type="button" className="link-btn" onClick={() => setChoosing(true)}>
                Change service
              </button>
            </div>
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
            <CouponBox {...discounts} />
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

type BookOption = QuickService & { service: Service }

/** Every nursing service with its icon, like /services/nursing: sub-type pills, search, then cards. */
function ServicePicker({
  options,
  selectedId,
  onSelect,
}: {
  options: BookOption[]
  selectedId: string
  onSelect: (id: string) => void
}) {
  const [sub, setSub] = useState('all')
  const [query, setQuery] = useState('')
  const subs = useMemo(
    () => ['all', ...new Set(options.map((o) => o.service.subcategory).filter(Boolean))],
    [options],
  )
  const q = query.trim().toLowerCase()
  const shown = options.filter(
    (o) =>
      (sub === 'all' || o.service.subcategory === sub) &&
      (!q ||
        o.title.toLowerCase().includes(q) ||
        o.description.toLowerCase().includes(q) ||
        o.service.subcategory.toLowerCase().includes(q)),
  )

  return (
    <div className="svc-picker">
      <label className="search-input-wrap">
        <SearchIcon size={18} />
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search nursing services"
          className="explorer-search-input"
          aria-label="Search nursing services"
        />
        {query && (
          <button type="button" className="search-clear-btn" onClick={() => setQuery('')} aria-label="Clear search">
            ×
          </button>
        )}
      </label>
      {subs.length > 2 && (
        <div className="subcat-pills" role="group" aria-label="Filter by type">
          {subs.map((x) => (
            <button
              key={x}
              type="button"
              className={`subcat-pill ${sub === x ? 'is-active' : ''}`}
              onClick={() => setSub(x)}
              aria-pressed={sub === x}
            >
              {x === 'all' ? 'All' : x}
            </button>
          ))}
        </div>
      )}
      {shown.length > 0 ? (
        <div className="services-grid" role="radiogroup" aria-label="Nursing service">
          {shown.map((o, i) => (
            <ServiceOption key={o.id} option={o} index={i} checked={o.id === selectedId} onSelect={() => onSelect(o.id)} />
          ))}
        </div>
      ) : (
        <p className="svc-picker-empty">
          No services match &ldquo;{query}&rdquo;.{' '}
          <button
            type="button"
            className="link-btn"
            onClick={() => {
              setQuery('')
              setSub('all')
            }}
          >
            Show all
          </button>
        </p>
      )}
    </div>
  )
}

function ServiceOption({
  option: o,
  checked,
  index = 0,
  onSelect,
}: {
  option: BookOption
  checked: boolean
  index?: number
  onSelect: () => void
}) {
  const cat = categoryById[o.service.category] ?? categories[0]
  return (
    <button
      type="button"
      role="radio"
      aria-checked={checked}
      className={`service-card svc-option ${checked ? 'is-on' : ''}`}
      style={{ '--i': index % 12 } as CSSProperties}
      onClick={onSelect}
    >
      <IconTile name={o.icon} image={o.service.imageUrl} ink={cat.ink} wash={cat.wash} size="var(--card-icon)" />
      <span className="card-body">
        <span className="card-title">{o.title}</span>
        <span className="card-meta">
          {o.service.badge && <span className="card-badge">{o.service.badge}</span>}
          <ClockIcon size={13} />
          <span className="card-meta-text">
            {o.duration}
            {o.service.professional && ` · ${o.service.professional}`}
          </span>
        </span>
      </span>
      <span className="card-price">
        {inr(o.price)}
        {checked && <CheckIcon size={18} />}
      </span>
    </button>
  )
}
