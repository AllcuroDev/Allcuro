import { useState } from 'react'
import { AddressPicker } from '../components/AddressPicker'
import { PinIcon, ShieldIcon } from '../components/Icons'
import { Link } from '../components/Link'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Bill, OptionCard, PageHead, StepList, StepTitle } from '../components/ui'
import { toast } from '../lib/toast'
import { billTotal, coupons, deliverySlots, GST_RATE, PLATFORM_FEE, type BillLine } from '../data/booking'
import { equipment, equipmentById, equipmentCategories } from '../data/providers'
import { inr } from '../lib/format'
import { navigate } from '../router'
import { requireLogin, useAuth } from '../state/auth'
import { createBooking, type Payment } from '../state/bookings'
import { fullAddress, useLocation } from '../state/location'
import { NotFound } from './CategoryPage'

/** Medical equipment on rent (the app's EquipmentScreen). */
export function EquipmentPage() {
  const [category, setCategory] = useState<string | null>(null)
  const list = category ? equipment.filter((e) => e.category === category) : equipment

  return (
    <div className="container page">
      <PageHead back="/" title="Medical Equipment" subtitle="Hospital-grade, sanitised & delivered to your home" />
      <div className="chip-row filter-row" role="group" aria-label="Filter equipment">
        <button
          type="button"
          className={`chip ${!category ? 'is-active' : ''}`}
          aria-pressed={!category}
          onClick={() => setCategory(null)}
        >
          All
        </button>
        {equipmentCategories.map((c) => (
          <button
            key={c}
            type="button"
            className={`chip ${category === c ? 'is-active' : ''}`}
            aria-pressed={category === c}
            onClick={() => setCategory(c)}
          >
            {c}
          </button>
        ))}
      </div>
      <div className="card-grid">
        {list.map((e) => (
          <article key={e.id} className="place-card">
            <div className="place-photo">
              <img src={e.photo} alt="" loading="lazy" />
              <span className="place-badge">{e.condition}</span>
            </div>
            <div className="place-body">
              <span className="muted small">{e.category}</span>
              <h3>{e.name}</h3>
              <p className="place-price">
                <strong>{inr(e.perDay)}</strong> / day · {inr(e.perMonth)} / month
              </p>
              <div className="place-row">
                <span className="muted small">Deposit {inr(e.deposit)} (refundable)</span>
                <Link to={`/equipment/${e.id}/rent`} className="btn btn-primary btn-sm">
                  Rent
                </Link>
              </div>
            </div>
          </article>
        ))}
        {!list.length && <p className="empty">Nothing listed under {category} yet — call us and we’ll source it.</p>}
      </div>
    </div>
  )
}

const PLANS = [
  { id: 'week', label: '1 week', days: 7 },
  { id: 'month', label: '1 month', days: 30 },
  { id: 'quarter', label: '3 months', days: 90 },
]

const CHECKOUT_STEPS = [
  { title: 'Select equipment & rental plan', subtitle: '' },
  { title: 'Delivery slot', subtitle: '' },
  { title: 'Address', subtitle: '' },
  { title: 'Review price', subtitle: '' },
  { title: 'Payment', subtitle: '' },
]

/** Rental checkout: plan, delivery slot, address, price and payment (the app's CheckoutScreen). */
export function EquipmentCheckoutPage({ id }: { id: string }) {
  const item = equipmentById(id)
  const { current } = useLocation()
  const { profile } = useAuth()
  const [plan, setPlan] = useState(PLANS[1].id)
  const [slot, setSlot] = useState(deliverySlots[0])
  const [couponInput, setCouponInput] = useState('')
  const [coupon, setCoupon] = useState<string | null>(null)
  const [pickingAddress, setPickingAddress] = useState(false)
  const [paying, setPaying] = useState(false)
  if (!item) return <NotFound />

  const p = PLANS.find((x) => x.id === plan)!
  // Monthly rate beats the daily one beyond a few weeks.
  const rent = p.days >= 30 ? item.perMonth * Math.round(p.days / 30) : Math.min(item.perDay * p.days, item.perMonth)
  const discount = coupon ? coupons[coupon].off(rent) : 0
  const gst = Math.round((rent - discount + PLATFORM_FEE) * GST_RATE)
  const lines: BillLine[] = [
    { label: `${item.name} · ${p.label} rent`, amount: rent },
    ...(discount ? [{ label: 'Coupon discount', amount: -discount }] : []),
    { label: 'Delivery, setup & sanitisation', amount: PLATFORM_FEE },
    { label: 'GST (18%)', amount: gst },
    { label: 'Refundable security deposit', amount: item.deposit },
  ]

  const applyCoupon = () => {
    const code = couponInput.trim().toUpperCase()
    if (!coupons[code]) return toast('That coupon code isn’t valid. Try FIRSTCARE.', 'danger')
    setCoupon(code)
    toast(`Coupon applied: ${coupons[code].label}`)
  }

  const onPaid = async (payment: Payment) => {
    const booking = await createBooking({
      type: 'equipment',
      title: item.name,
      when: `${p.label} rental · Delivery ${slot}`,
      amount: billTotal(lines),
      liveStatus: 'assigned',
      patientName: profile?.name ?? '',
      patientAge: 0,
      patientGender: '',
      address: fullAddress(current),
      locality: current.locality,
      providerName: 'ALLCURO Equipment Desk',
      providerPhone: '+91 80 4120 5500',
      providerRating: 4.8,
      providerQualifications: `${item.condition} · Sanitised & demonstrated on delivery`,
      formalities: [],
      payment,
    })
    navigate(`/bookings/${booking.id}`, { replace: true })
  }

  return (
    <>
      <div className="container page page-narrow">
        <PageHead back="/equipment" title="Checkout & Payment" subtitle={`Renting: ${item.name}`} />

        <div className="panel checkout-steps">
          <StepList steps={CHECKOUT_STEPS} current={paying ? 4 : 3} />
        </div>

        <section className="form-section">
          <StepTitle n={1}>Rental plan</StepTitle>
          <div className="panel equip-summary">
            <img src={item.photo} alt="" />
            <div>
              <strong>{item.name}</strong>
              <span className="muted small">
                {item.condition} · {inr(item.perDay)}/day · {inr(item.perMonth)}/month
              </span>
            </div>
          </div>
          <div className="duration-grid three">
            {PLANS.map((x) => (
              <button
                key={x.id}
                type="button"
                className={`duration-tile ${x.id === plan ? 'is-active' : ''}`}
                aria-pressed={x.id === plan}
                onClick={() => setPlan(x.id)}
              >
                <strong>{x.label}</strong>
              </button>
            ))}
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={2}>Delivery slot</StepTitle>
          <div className="stack-sm">
            {deliverySlots.map((s) => (
              <OptionCard key={s} name="delivery" compact checked={s === slot} onSelect={() => setSlot(s)}>
                <span className="option-text">
                  <strong>{s}</strong>
                </span>
              </OptionCard>
            ))}
          </div>
        </section>

        <section className="form-section">
          <StepTitle n={3}>Delivery address</StepTitle>
          <div className="address-box panel">
            <PinIcon />
            <span>
              <strong>{current.title}</strong>
              <small>{fullAddress(current)}</small>
            </span>
            <button type="button" className="link-btn" onClick={() => setPickingAddress(true)}>
              Change
            </button>
          </div>
          {item.deposit >= 8000 && (
            <p className="trust-note">
              <ShieldIcon size={20} /> High-value rental: keep the patient’s Aadhaar handy — the delivery team verifies ID
              at hand-over.
            </p>
          )}
        </section>

        <section className="form-section">
          <StepTitle n={4}>Review price</StepTitle>
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
      </div>

      <ActionBar label="Total payable" amount={inr(billTotal(lines))}>
        <button
          type="button"
          className="btn btn-primary btn-lg"
          onClick={() =>
            requireLogin(() => setPaying(true), {
              title: 'Login to Rent',
              subtitle: 'Verify your mobile number to place the rental order',
            })
          }
        >
          Pay securely
        </button>
      </ActionBar>

      {pickingAddress && <AddressPicker onClose={() => setPickingAddress(false)} />}
      {paying && (
        <PaymentDialog
          title={`${item.name} · ${p.label} rental`}
          lines={lines}
          onClose={() => setPaying(false)}
          onPaid={onPaid}
        />
      )}
    </>
  )
}
