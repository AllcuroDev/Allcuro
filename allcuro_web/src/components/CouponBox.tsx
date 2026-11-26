import { useState, type FormEvent } from 'react'
import { CouponError, type AppliedDiscount } from '../lib/coupons'
import { inr } from '../lib/format'
import { toast } from '../lib/toast'
import { requireLogin, useAuth } from '../state/auth'
import { CheckIcon } from './Icons'
import { Spinner } from './ui'

/**
 * Coupon entry for a checkout page (state from useCheckoutDiscount). Guests are
 * asked to sign in first: coupons and offers are for signed-in customers only.
 */
export function CouponBox({
  applied,
  apply,
  remove,
}: {
  applied: AppliedDiscount | null
  apply: (code: string) => Promise<AppliedDiscount>
  remove: () => void
}) {
  const { isLoggedIn } = useAuth()
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  if (!isLoggedIn)
    return (
      <div className="coupon-row coupon-guest">
        <span>Have a coupon? Sign in to apply coupons and offers.</span>
        <button
          type="button"
          className="btn btn-outline"
          onClick={() =>
            requireLogin(() => {}, { title: 'Sign in to Apply Coupons', subtitle: 'Coupons and offers are for signed-in customers' })
          }
        >
          Sign in
        </button>
      </div>
    )

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!input.trim()) return
    setBusy(true)
    setError('')
    try {
      const d = await apply(input)
      setInput('')
      toast(`Coupon applied: ${d.title}`)
    } catch (err) {
      setError(err instanceof CouponError ? err.message : 'Couldn’t check that coupon. Please try again.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="coupon-box">
      {applied && (
        <div className="coupon-applied" role="status">
          <CheckIcon size={18} />
          <span>
            <strong>{applied.code ?? 'Offer applied'}</strong>
            <small>
              {applied.title} · You save {inr(applied.amount)}
            </small>
          </span>
          {applied.code && (
            <button type="button" className="link-btn" onClick={remove}>
              Remove
            </button>
          )}
        </div>
      )}
      {!applied?.code && (
        <form className="coupon-row" onSubmit={submit}>
          <input
            className="input"
            placeholder={applied ? 'Have a coupon code instead?' : 'Have a coupon code?'}
            value={input}
            onChange={(e) => {
              setInput(e.target.value.toUpperCase())
              setError('')
            }}
            aria-label="Coupon code"
            aria-invalid={!!error}
            autoCapitalize="characters"
          />
          <button type="submit" className="btn btn-dark" disabled={!input.trim() || busy}>
            {busy ? <Spinner /> : 'Apply'}
          </button>
        </form>
      )}
      {error && (
        <p className="coupon-error" role="alert">
          {error}
        </p>
      )}
    </div>
  )
}
