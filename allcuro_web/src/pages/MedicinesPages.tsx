import { useEffect, useRef, useState, type DragEvent } from 'react'
import { AddressPicker } from '../components/AddressPicker'
import {
  CartIcon,
  CloseIcon,
  FileIcon,
  MinusIcon,
  PinIcon,
  PlusIcon,
  SearchIcon,
  ShieldIcon,
  TrashIcon,
  UploadIcon,
} from '../components/Icons'
import { Link } from '../components/Link'
import { PaymentDialog } from '../components/PaymentDialog'
import { ActionBar, Bill, PageHead, Spinner, StepTitle } from '../components/ui'
import {
  FREE_DELIVERY_MIN,
  MAX_QTY,
  medicineBill,
  medicineCategories,
  percentOff,
  searchMedicines,
  type Medicine,
  type MedicineCategory,
} from '../data/medicines'
import { inr } from '../lib/format'
import { toast } from '../lib/toast'
import { navigate, useQuery } from '../router'
import { requireLogin, useAuth } from '../state/auth'
import { createBooking, type Payment } from '../state/bookings'
import {
  addToCart,
  attachPrescription,
  clearCart,
  fileSize,
  prescriptionProblem,
  removeFromCart,
  removePrescription,
  setQty,
  useCart,
} from '../state/cart'
import { fullAddress, useLocation } from '../state/location'

// Order Medicines: search or upload a prescription → cart → pay → the order
// shows in My Bookings with a delivery OTP and status timeline.

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? '' : 's'}`

/** Search, category chips, medicine list and a prominent prescription upload. */
export function MedicinesPage() {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState<MedicineCategory | null>(null)
  const cart = useCart()
  const list = searchMedicines(query, category)

  return (
    <>
      <div className="container page">
        <PageHead
          back="/"
          title="Order Medicines"
          subtitle="Genuine medicines from licensed pharmacies, delivered within 3 hours"
        />

        <PrescriptionUpload variant="card" />

        <div className="med-toolbar">
          <label className="search-input-wrap med-search">
            <SearchIcon size={18} />
            <input
              type="search"
              className="explorer-search-input"
              placeholder="Search medicines, e.g. paracetamol"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              aria-label="Search medicines"
            />
            {query && (
              <button type="button" className="search-clear-btn" onClick={() => setQuery('')} aria-label="Clear search">
                ×
              </button>
            )}
          </label>
        </div>

        <div className="chip-row filter-row" role="group" aria-label="Filter medicines by type">
          {[null, ...medicineCategories].map((c) => (
            <button
              key={c ?? 'all'}
              type="button"
              className={`chip ${category === c ? 'is-active' : ''}`}
              aria-pressed={category === c}
              onClick={() => setCategory(c)}
            >
              {c ?? 'All'}
            </button>
          ))}
        </div>

        <p className="med-count" role="status">
          {plural(list.length, 'medicine')}
          {query.trim() ? ` for “${query.trim()}”` : ''}
        </p>

        {list.length ? (
          <ul className="med-grid">
            {list.map((m) => (
              <li key={m.id}>
                <MedicineCard medicine={m} qty={cart.qtyOf(m.id)} />
              </li>
            ))}
          </ul>
        ) : (
          <div className="empty">
            <p>Can’t find your medicine? Upload your prescription and our pharmacist will add it.</p>
            <div className="row-actions">
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => document.getElementById(RX_INPUT_ID)?.click()}
              >
                <UploadIcon /> Upload prescription
              </button>
              {(query || category) && (
                <button
                  type="button"
                  className="btn btn-outline"
                  onClick={() => {
                    setQuery('')
                    setCategory(null)
                  }}
                >
                  Show all medicines
                </button>
              )}
            </div>
          </div>
        )}
        <p className="med-fine">Prices include GST. Rx medicines are dispatched only after a licensed pharmacist checks your prescription.</p>
      </div>

      {cart.count > 0 && (
        <ActionBar label={`${plural(cart.count, 'item')} in cart`} amount={inr(cart.totals.itemTotal)}>
          <Link to="/medicines/cart" className="btn btn-primary btn-lg">
            <CartIcon /> View cart
          </Link>
        </ActionBar>
      )}
      <CartAnnouncer />
    </>
  )
}

function MedicineCard({ medicine: m, qty }: { medicine: Medicine; qty: number }) {
  const off = percentOff(m)
  return (
    <article className="med-card">
      <MedGlyph medicine={m} />
      <div className="med-info">
        <h3>{m.name}</h3>
        <p className="med-pack">{m.pack}</p>
        <div className="med-tags">
          {m.rx && <RxBadge />}
          <span className="tag">{m.category}</span>
        </div>
      </div>
      <div className="med-buy">
        <Price medicine={m} off={off} />
        {qty ? (
          <QtyStepper medicine={m} qty={qty} removeAtOne />
        ) : (
          <button
            type="button"
            className="btn btn-outline btn-sm med-add"
            onClick={() => addToCart(m.id)}
            aria-label={`Add ${m.name} to cart`}
          >
            <PlusIcon size={16} /> Add
          </button>
        )}
      </div>
    </article>
  )
}

function Price({ medicine: m, off, qty = 1 }: { medicine: Medicine; off?: number; qty?: number }) {
  return (
    <p className="med-price">
      <strong>{inr(m.price * qty)}</strong>{' '}
      {m.mrp > m.price && (
        <>
          <span className="sr-only">MRP </span>
          <s>{inr(m.mrp * qty)}</s>
          {off != null && <span className="med-off"> {off}% off</span>}
        </>
      )}
    </p>
  )
}

const RxBadge = () => (
  <span className="rx-badge" title="Prescription needed">
    Rx<span className="sr-only"> — prescription needed</span>
  </span>
)

/** − qty + for one medicine. On the list, − at 1 removes it; in the cart there is a separate Remove. */
function QtyStepper({ medicine: m, qty, removeAtOne = false }: { medicine: Medicine; qty: number; removeAtOne?: boolean }) {
  const removes = removeAtOne && qty <= 1
  return (
    <div className="qty" role="group" aria-label={`Quantity of ${m.name}`}>
      <button
        type="button"
        onClick={() => setQty(m.id, qty - 1)}
        disabled={qty <= 1 && !removeAtOne}
        aria-label={removes ? `Remove ${m.name} from cart` : `Decrease quantity of ${m.name}`}
      >
        {removes ? <TrashIcon size={16} /> : <MinusIcon size={16} />}
      </button>
      <output aria-live="polite" aria-label={`${qty} in cart`}>
        {qty}
      </output>
      <button
        type="button"
        onClick={() => setQty(m.id, qty + 1)}
        disabled={qty >= MAX_QTY}
        aria-label={`Increase quantity of ${m.name}`}
      >
        <PlusIcon size={16} />
      </button>
    </div>
  )
}

/** A strip, capsule or bottle drawn inline, picked from the pack size. */
function MedGlyph({ medicine: m }: { medicine: Medicine }) {
  const kind = /bottle/i.test(m.pack) ? 'bottle' : /capsule/i.test(m.pack) ? 'capsule' : /sachet/i.test(m.pack) ? 'sachet' : 'tablet'
  return (
    <span className={`med-glyph is-${kind}`} aria-hidden="true">
      <svg viewBox="0 0 48 48" width="34" height="34" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
        {kind === 'bottle' && (
          <>
            <rect x="15" y="6" width="18" height="7" rx="2" fill="currentColor" fillOpacity="0.18" />
            <path d="M17 13h14v4c3 1.5 4 4 4 7v15a3 3 0 0 1-3 3H16a3 3 0 0 1-3-3V24c0-3 1-5.5 4-7z" />
            <path d="M13 26h22v9H13z" fill="currentColor" fillOpacity="0.18" />
          </>
        )}
        {kind === 'capsule' && (
          <>
            <path d="M27.5 9.5a9.2 9.2 0 0 1 13 13L22.5 40.5a9.2 9.2 0 0 1-13-13z" />
            <path d="M18.5 18.5 27.5 9.5a9.2 9.2 0 0 1 13 13l-9 9z" fill="currentColor" fillOpacity="0.22" />
          </>
        )}
        {kind === 'sachet' && (
          <>
            <path d="M12 8h24l-2 4 2 4v20l-2 4 2 4H12l2-4-2-4V16l2-4z" />
            <path d="M18 24h12M24 18v12" />
          </>
        )}
        {kind === 'tablet' && (
          <>
            <rect x="7" y="11" width="34" height="26" rx="5" />
            <circle cx="17" cy="20" r="3.5" fill="currentColor" fillOpacity="0.22" />
            <circle cx="31" cy="20" r="3.5" fill="currentColor" fillOpacity="0.22" />
            <circle cx="17" cy="29" r="3.5" fill="currentColor" fillOpacity="0.22" />
            <circle cx="31" cy="29" r="3.5" fill="currentColor" fillOpacity="0.22" />
          </>
        )}
      </svg>
    </span>
  )
}

/** Reads cart changes aloud for screen readers ("Cart: 2 items, ₹171"). */
function CartAnnouncer() {
  const { count, totals } = useCart()
  return (
    <span className="sr-only" role="status" aria-live="polite">
      {count ? `Cart: ${plural(count, 'item')}, ${inr(totals.itemTotal)}` : 'Cart is empty'}
    </span>
  )
}

// ---- Prescription upload ----

const RX_INPUT_ID = 'rx-file'

/**
 * Photo or PDF of a prescription: file picker plus drag & drop. The "card"
 * variant (on /medicines) sends the visitor to the cart, where the pharmacist
 * review is shown; the "panel" variant (in the cart) shows every state.
 * `?upload=1` scrolls to it and focuses the upload button.
 */
function PrescriptionUpload({ variant }: { variant: 'card' | 'panel' }) {
  const { prescription, reviewing } = useCart()
  const [error, setError] = useState('')
  const [dragging, setDragging] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const buttonRef = useRef<HTMLButtonElement>(null)
  const sectionRef = useRef<HTMLElement>(null)
  const askedToUpload = useQuery('upload') === '1'

  useEffect(() => {
    if (!askedToUpload) return
    sectionRef.current?.scrollIntoView({ block: 'center' })
    buttonRef.current?.focus({ preventScroll: true })
  }, [askedToUpload])

  const pick = (file: File | undefined) => {
    if (!file) return
    const problem = prescriptionProblem(file)
    setError(problem ?? '')
    if (problem) return
    void attachPrescription(file).then(() => toast('💊 Your pharmacist added the medicines from your prescription'))
    if (variant === 'card') navigate('/medicines/cart')
  }

  const onDrop = (e: DragEvent) => {
    e.preventDefault()
    setDragging(false)
    if (!reviewing) pick(e.dataTransfer.files[0])
  }

  const input = (
    <input
      ref={inputRef}
      id={RX_INPUT_ID}
      type="file"
      accept="image/*,application/pdf"
      className="sr-only"
      tabIndex={-1}
      aria-hidden="true"
      onChange={(e) => {
        pick(e.target.files?.[0])
        e.target.value = ''
      }}
    />
  )
  const openPicker = () => inputRef.current?.click()

  const dropProps = {
    onDragOver: (e: DragEvent) => {
      e.preventDefault()
      if (!reviewing) setDragging(true)
    },
    onDragLeave: () => setDragging(false),
    onDrop,
  }

  const errorNote = error && (
    <p className="form-error rx-error" role="alert">
      {error}
    </p>
  )

  if (variant === 'card') {
    return (
      <section
        ref={sectionRef}
        className={`rx-card ${dragging ? 'is-dragging' : ''} ${askedToUpload ? 'is-asked' : ''}`}
        aria-labelledby="rx-card-title"
        {...dropProps}
      >
        <span className="rx-card-icon" aria-hidden="true">
          <FileIcon size={28} />
        </span>
        <div className="rx-card-text">
          <h2 id="rx-card-title">Have a prescription? Upload it.</h2>
          <p>
            Take a photo or upload a PDF. Our pharmacist reads it and adds the medicines for you. A licensed pharmacist
            verifies every prescription before dispatch.
          </p>
          {prescription && (
            <p className="rx-card-attached">
              <ShieldIcon size={16} /> Attached: {prescription.name} · <Link to="/medicines/cart">View cart</Link>
            </p>
          )}
          {errorNote}
        </div>
        <div className="rx-card-actions">
          {input}
          <button ref={buttonRef} type="button" className="btn btn-primary btn-lg" onClick={openPicker} disabled={!!reviewing}>
            <UploadIcon /> {prescription ? 'Upload another' : 'Upload prescription'}
          </button>
          <span className="rx-drop-hint">or drag & drop a photo or PDF here · up to 10 MB</span>
        </div>
      </section>
    )
  }

  return (
    <section ref={sectionRef} className="form-section" aria-labelledby="rx-title">
      <StepTitle n={2}>
        <span id="rx-title">Prescription</span>
      </StepTitle>
      <div className={`panel rx-panel ${askedToUpload && !prescription ? 'is-asked' : ''}`}>
        {reviewing ? (
          <div className="rx-file" role="status">
            <RxThumb preview={reviewing.preview} />
            <div>
              <strong>Pharmacist is reading your prescription…</strong>
              <span>
                {reviewing.name} · {fileSize(reviewing.size)}
              </span>
            </div>
            <Spinner />
          </div>
        ) : prescription ? (
          <>
            <div className="rx-file">
              <RxThumb preview={prescription.preview} />
              <div>
                <strong className="rx-name">{prescription.name}</strong>
                <span>
                  {fileSize(prescription.size)} · Read by our pharmacist — medicines added to your cart
                </span>
              </div>
            </div>
            <div className="row-actions">
              {input}
              <button ref={buttonRef} type="button" className="btn btn-outline" onClick={openPicker}>
                <UploadIcon /> Replace
              </button>
              <button type="button" className="btn btn-danger-outline" onClick={removePrescription}>
                <CloseIcon size={18} /> Remove
              </button>
            </div>
            {errorNote}
          </>
        ) : (
          <div className={`rx-drop ${dragging ? 'is-dragging' : ''}`} {...dropProps}>
            {input}
            <FileIcon size={28} />
            <p>
              <strong>Upload a photo or PDF of your prescription</strong>
              <span>Drag & drop it here, or choose a file · up to 10 MB</span>
            </p>
            <button ref={buttonRef} type="button" className="btn btn-primary" onClick={openPicker}>
              <UploadIcon /> Upload prescription
            </button>
            {errorNote}
          </div>
        )}
        <p className="trust-note">
          <ShieldIcon size={20} /> A licensed pharmacist verifies your prescription before anything is dispatched.
        </p>
      </div>
    </section>
  )
}

function RxThumb({ preview }: { preview?: string }) {
  return (
    <span className="rx-thumb" aria-hidden="true">
      {preview ? <img src={preview} alt="" /> : <FileIcon size={26} />}
    </span>
  )
}

// ---- Cart & checkout ----

/** Cart lines, prescription, delivery address, bill and payment. */
export function MedicineCartPage() {
  const cart = useCart()
  const { current } = useLocation()
  const { profile } = useAuth()
  const [pickingAddress, setPickingAddress] = useState(false)
  const [paying, setPaying] = useState(false)
  const { items, totals, count } = cart
  const lines = medicineBill(totals)
  const blocked = cart.needsPrescription || !!cart.reviewing
  const orderTitle = `Medicine order · ${plural(count, 'item')}`

  const pay = () =>
    requireLogin(() => setPaying(true), {
      title: 'Login to Order',
      subtitle: 'Verify your mobile number to place your medicine order',
    })

  const onPaid = async (payment: Payment) => {
    const booking = await createBooking({
      type: 'medicine',
      title: orderTitle,
      when: 'Delivery today, within 3 hrs',
      amount: totals.total,
      liveStatus: 'assigned',
      patientName: profile?.name ?? '',
      patientAge: 0,
      patientGender: '',
      address: fullAddress(current),
      locality: current.locality,
      providerName: 'ALLCURO Pharmacy Desk',
      providerPhone: '+91 80 4120 5500',
      providerRating: 4.8,
      providerQualifications: 'Licensed pharmacy · Pharmacist verified',
      formalities: [],
      payment,
      items: items.map((l) => ({ name: l.medicine.name, pack: l.medicine.pack, qty: l.qty, price: l.medicine.price })),
      prescriptionName: cart.prescription?.name,
    })
    navigate(`/bookings/${booking.id}`, { replace: true })
    clearCart()
  }

  return (
    <>
      <div className="container page page-narrow">
        <PageHead
          back="/medicines"
          title="Your medicine cart"
          subtitle={count ? `${plural(count, 'item')} · Delivery within 3 hours` : 'Delivery within 3 hours'}
        />

        <section className="form-section">
          <StepTitle n={1}>Medicines</StepTitle>
          {count ? (
            <ul className="cart-list panel">
              {items.map((l) => (
                <li key={l.id} className="cart-line">
                  <MedGlyph medicine={l.medicine} />
                  <div className="cart-line-info">
                    <strong>{l.medicine.name}</strong>
                    <span className="med-pack">{l.medicine.pack}</span>
                    {(l.medicine.rx || l.fromPrescription) && (
                      <span className="med-tags">
                        {l.medicine.rx && <RxBadge />}
                        {l.fromPrescription && <span className="tag tag-rx">From your prescription</span>}
                      </span>
                    )}
                  </div>
                  <div className="cart-line-buy">
                    <Price medicine={l.medicine} qty={l.qty} />
                    <div className="cart-line-actions">
                      <QtyStepper medicine={l.medicine} qty={l.qty} />
                      <button
                        type="button"
                        className="icon-btn cart-remove"
                        onClick={() => removeFromCart(l.id)}
                        aria-label={`Remove ${l.medicine.name}`}
                      >
                        <TrashIcon size={18} />
                      </button>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty">
              <p>{cart.reviewing ? 'Your pharmacist is adding medicines from your prescription…' : 'Your cart is empty.'}</p>
              <div className="row-actions">
                <Link to="/medicines" className="btn btn-primary">
                  <SearchIcon size={18} /> Search medicines
                </Link>
              </div>
            </div>
          )}
          {count > 0 && (
            <Link to="/medicines" className="link-btn cart-more">
              <PlusIcon size={16} /> Add more medicines
            </Link>
          )}
        </section>

        <PrescriptionUpload variant="panel" />

        {count > 0 && (
          <>
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
            </section>

            <section className="form-section">
              <StepTitle n={4}>Bill summary</StepTitle>
              <div className="panel">
                <Bill lines={lines} />
                <div className="cart-notes">
                  {totals.savings > 0 && <p className="cart-save">You save {inr(totals.savings)} on MRP</p>}
                  <p className="muted small">
                    {totals.toFreeDelivery > 0
                      ? `Add ${inr(totals.toFreeDelivery)} more for free delivery. Free delivery on orders above ${inr(FREE_DELIVERY_MIN)}.`
                      : `You get free delivery on orders above ${inr(FREE_DELIVERY_MIN)}.`}
                  </p>
                  <p className="muted small">All prices include GST.</p>
                </div>
              </div>
              {cart.needsPrescription && !cart.reviewing && (
                <div className="warn-note rx-warn" id="rx-warn" role="alert">
                  <span>Upload a prescription to order Rx medicines</span>
                  <button
                    type="button"
                    className="btn btn-outline btn-sm"
                    onClick={() => document.getElementById(RX_INPUT_ID)?.click()}
                  >
                    <UploadIcon size={16} /> Upload
                  </button>
                </div>
              )}
            </section>
          </>
        )}
      </div>

      {count > 0 && (
        <ActionBar label="Total payable" amount={inr(totals.total)}>
          <button
            type="button"
            className="btn btn-primary btn-lg"
            onClick={pay}
            disabled={blocked}
            aria-describedby={cart.needsPrescription && !cart.reviewing ? 'rx-warn' : undefined}
          >
            Pay securely
          </button>
        </ActionBar>
      )}
      <CartAnnouncer />

      {pickingAddress && <AddressPicker onClose={() => setPickingAddress(false)} />}
      {paying && <PaymentDialog title={orderTitle} lines={lines} onClose={() => setPaying(false)} onPaid={onPaid} />}
    </>
  )
}
