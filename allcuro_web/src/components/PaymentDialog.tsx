import { useState, type FormEvent } from 'react'
import { billTotal, type BillLine } from '../data/booking'
import { digitsOnly, inr } from '../lib/format'
import { delay } from '../lib/store'
import type { Payment } from '../state/bookings'
import { CardIcon, CheckIcon, LockIcon, ShieldIcon } from './Icons'
import { Bill, Modal, Spinner } from './ui'

// Payment step. The app simulates the Razorpay hand-off (checkout_screen.dart);
// the website does the same until a payment gateway and backend order API
// exist — nothing is charged. Swap `processPayment` for Razorpay Checkout then.

type Method = 'upi' | 'card' | 'netbanking' | 'later'

const METHODS: { id: Method; label: string; hint: string }[] = [
  { id: 'upi', label: 'UPI', hint: 'Google Pay, PhonePe, Paytm or any UPI app' },
  { id: 'card', label: 'Credit / Debit Card', hint: 'Visa, Mastercard, RuPay' },
  { id: 'netbanking', label: 'Net Banking', hint: 'All major Indian banks' },
  { id: 'later', label: 'Pay after visit', hint: 'Cash or UPI to the ALLCURO desk once the visit is done' },
]

const BANKS = ['State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra Bank']

async function processPayment(method: Method): Promise<Pick<Payment, 'method' | 'reference' | 'payLater'>> {
  await delay(method === 'later' ? 500 : 1400)
  const label = METHODS.find((m) => m.id === method)!.label
  return { method: label, reference: `pay_${Math.random().toString(36).slice(2, 12)}`, payLater: method === 'later' }
}

interface Props {
  title: string
  lines: BillLine[]
  /** Offer "Pay after visit" (home visits only). */
  allowPayLater?: boolean
  onClose: () => void
  /** Called once the payment succeeds; should create the booking and move on. */
  onPaid: (payment: Payment) => Promise<void>
}

export function PaymentDialog({ title, lines, allowPayLater = false, onClose, onPaid }: Props) {
  const [method, setMethod] = useState<Method>('upi')
  const [upiId, setUpiId] = useState('')
  const [card, setCard] = useState({ number: '', expiry: '', cvv: '', name: '' })
  const [bank, setBank] = useState(BANKS[0])
  const [phase, setPhase] = useState<'choose' | 'processing' | 'done'>('choose')
  const [error, setError] = useState('')
  const total = billTotal(lines)

  const validate = () => {
    if (method === 'upi' && !/^[\w.-]{2,}@[a-z]{2,}$/i.test(upiId.trim())) return 'Enter a valid UPI ID, e.g. name@okaxis'
    if (method === 'card') {
      if (digitsOnly(card.number).length < 15) return 'Enter the full card number'
      if (!/^(0[1-9]|1[0-2])\/\d{2}$/.test(card.expiry)) return 'Enter expiry as MM/YY'
      if (digitsOnly(card.cvv).length < 3) return 'Enter the 3-digit CVV'
    }
    return ''
  }

  const pay = async (e: FormEvent) => {
    e.preventDefault()
    const problem = validate()
    setError(problem)
    if (problem) return
    setPhase('processing')
    try {
      const result = await processPayment(method)
      setPhase('done')
      await delay(900)
      await onPaid({ ...result, paidAt: Date.now(), lines })
    } catch {
      setPhase('choose')
      setError('Payment could not be completed. No money was taken — please try again.')
    }
  }

  const methods = METHODS.filter((m) => allowPayLater || m.id !== 'later')

  return (
    <Modal onClose={onClose} labelledBy="pay-title" dismissable={phase === 'choose'} className="pay-dialog">
      {phase === 'choose' && (
        <form onSubmit={pay} noValidate>
          <span className="eyebrow">
            <LockIcon size={14} /> SECURE CHECKOUT
          </span>
          <h2 id="pay-title" className="login-title">
            Pay {inr(total)}
          </h2>
          <p className="login-sub">{title}</p>

          <details className="pay-bill">
            <summary>View price breakdown</summary>
            <Bill lines={lines} />
          </details>

          <fieldset className="pay-methods">
            <legend className="field-label">Choose payment method</legend>
            {methods.map((m) => (
              <label key={m.id} className={`pay-method ${method === m.id ? 'is-checked' : ''}`}>
                <input
                  type="radio"
                  name="pay-method"
                  checked={method === m.id}
                  onChange={() => {
                    setMethod(m.id)
                    setError('')
                  }}
                />
                <span>
                  <strong>{m.label}</strong>
                  <small>{m.hint}</small>
                </span>
              </label>
            ))}
          </fieldset>

          {method === 'upi' && (
            <label className="field">
              <span className="field-label">UPI ID</span>
              <input
                className="input"
                placeholder="yourname@okaxis"
                value={upiId}
                onChange={(e) => setUpiId(e.target.value)}
                autoComplete="off"
              />
            </label>
          )}
          {method === 'card' && (
            <div className="card-fields">
              <label className="field card-number">
                <span className="field-label">Card number</span>
                <span className="input-icon">
                  <CardIcon />
                  <input
                    className="input"
                    inputMode="numeric"
                    autoComplete="cc-number"
                    placeholder="1234 5678 9012 3456"
                    value={card.number}
                    onChange={(e) =>
                      setCard({ ...card, number: digitsOnly(e.target.value).slice(0, 16).replace(/(\d{4})(?=\d)/g, '$1 ') })
                    }
                  />
                </span>
              </label>
              <label className="field">
                <span className="field-label">Expiry</span>
                <input
                  className="input"
                  inputMode="numeric"
                  autoComplete="cc-exp"
                  placeholder="MM/YY"
                  value={card.expiry}
                  onChange={(e) => {
                    const d = digitsOnly(e.target.value).slice(0, 4)
                    setCard({ ...card, expiry: d.length > 2 ? `${d.slice(0, 2)}/${d.slice(2)}` : d })
                  }}
                />
              </label>
              <label className="field">
                <span className="field-label">CVV</span>
                <input
                  className="input"
                  inputMode="numeric"
                  autoComplete="cc-csc"
                  type="password"
                  placeholder="•••"
                  value={card.cvv}
                  onChange={(e) => setCard({ ...card, cvv: digitsOnly(e.target.value).slice(0, 4) })}
                />
              </label>
            </div>
          )}
          {method === 'netbanking' && (
            <label className="field">
              <span className="field-label">Your bank</span>
              <select className="input" value={bank} onChange={(e) => setBank(e.target.value)}>
                {BANKS.map((b) => (
                  <option key={b}>{b}</option>
                ))}
              </select>
            </label>
          )}

          {error && <p className="form-error">{error}</p>}

          <button type="submit" className="btn btn-primary btn-lg btn-block">
            {method === 'later' ? 'Confirm Booking' : `Pay ${inr(total)} securely`}
          </button>
          <p className="login-fine">
            <ShieldIcon size={16} /> Demo checkout — no money is charged. Payments will run through Razorpay.
          </p>
        </form>
      )}

      {phase !== 'choose' && (
        <div className="pay-status" role="status">
          {phase === 'processing' ? (
            <>
              <span className="pay-status-icon">
                <Spinner />
              </span>
              <h2 id="pay-title" className="login-title">
                {method === 'later' ? 'Confirming your booking…' : 'Processing payment…'}
              </h2>
              <p className="login-sub">Please don’t close this window.</p>
            </>
          ) : (
            <>
              <span className="pay-status-icon is-done">
                <CheckIcon size={34} />
              </span>
              <h2 id="pay-title" className="login-title">
                {method === 'later' ? 'Booking confirmed' : `${inr(total)} paid`}
              </h2>
              <p className="login-sub">Setting up your booking…</p>
            </>
          )}
        </div>
      )}
    </Modal>
  )
}
