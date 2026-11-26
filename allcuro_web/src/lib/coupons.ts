import { useEffect, useState } from 'react'
import { useAuth } from '../state/auth'
import { supabase } from './supabase'
import { toast } from './toast'

// Coupons and automatic discounts created in the admin panel (public.coupons,
// supabase/coupons.sql). The tables aren't readable by customers; checkout asks
// the database functions, which only answer a signed-in user.

/** What the booking is for; a coupon can be limited to some of these. */
export type CouponScope = 'nurse' | 'centre' | 'equipment' | 'medicine'

export interface AppliedDiscount {
  couponId: string
  /** The typed code; null for an automatic discount. */
  code: string | null
  title: string
  amount: number
}

/** A coupon problem with a message fit to show the customer. */
export class CouponError extends Error {}

const db = () => {
  if (!supabase) throw new CouponError('Coupons are unavailable right now.')
  return supabase
}

// Postgres `raise exception` text arrives as error.message.
const fail = (message?: string): never => {
  throw new CouponError(message || 'That coupon code isn’t valid.')
}

export async function validateCoupon(code: string, amount: number, scope: CouponScope): Promise<AppliedDiscount> {
  const { data, error } = await db().rpc('validate_coupon', { p_code: code, p_amount: amount, p_applies_to: scope })
  if (error) fail(error.message)
  const row = (data as { coupon_id: string; code: string; title: string; discount: number }[] | null)?.[0]
  if (!row) return fail()
  return { couponId: row.coupon_id, code: row.code, title: row.title, amount: Number(row.discount) }
}

export async function bestAutoDiscount(amount: number, scope: CouponScope): Promise<AppliedDiscount | null> {
  const { data, error } = await db().rpc('best_auto_discount', { p_amount: amount, p_applies_to: scope })
  if (error) return null
  const row = (data as { coupon_id: string; title: string; discount: number }[] | null)?.[0]
  return row ? { couponId: row.coupon_id, code: null, title: row.title, amount: Number(row.discount) } : null
}

/** Records the use at payment (re-checking every rule); returns the discount the server allowed. */
export async function redeemCoupon(couponId: string, amount: number, scope: CouponScope, bookingRef: string | null) {
  const { data, error } = await db().rpc('redeem_coupon', {
    p_coupon_id: couponId,
    p_amount: amount,
    p_applies_to: scope,
    p_booking_ref: bookingRef,
  })
  if (error) fail(error.message)
  return Number(data)
}

/**
 * Discount state for a checkout page. Signed-in customers get the best
 * automatic discount, or the coupon they typed instead; guests get nothing.
 * Re-checked whenever the order amount changes.
 */
export function useCheckoutDiscount(base: number, scope: CouponScope) {
  const { isLoggedIn } = useAuth()
  const [code, setCode] = useState<string | null>(null)
  const [found, setFound] = useState<(AppliedDiscount & { base: number }) | null>(null)

  useEffect(() => {
    if (!isLoggedIn || !supabase || base <= 0) return
    let live = true
    void (async () => {
      if (code) {
        try {
          const d = await validateCoupon(code, base, scope)
          if (live) setFound({ ...d, base })
          return
        } catch (e) {
          if (!live) return
          toast(e instanceof CouponError ? `${code}: ${e.message}` : 'Coupon removed.', 'danger')
          setCode(null)
          return
        }
      }
      const auto = await bestAutoDiscount(base, scope).catch(() => null)
      if (live) setFound(auto && { ...auto, base })
    })()
    return () => {
      live = false
    }
  }, [isLoggedIn, base, scope, code])

  // Stale results (another amount, a removed code, signed out) never count.
  const applied: AppliedDiscount | null =
    isLoggedIn && found && found.base === base && found.code === code
      ? { couponId: found.couponId, code: found.code, title: found.title, amount: found.amount }
      : null

  return {
    applied,
    /** Validates a typed code; throws CouponError with a readable message. */
    apply: async (raw: string) => {
      const d = await validateCoupon(raw.trim(), base, scope)
      setFound({ ...d, base })
      setCode(d.code)
      return d
    },
    remove: () => {
      setCode(null)
      setFound(null)
    },
    /** Call from onPaid, before creating the booking. Throws CouponError if it can no longer be used. */
    redeem: async (bookingRef: string | null = null) => {
      if (!applied) return 0
      return redeemCoupon(applied.couponId, base, scope, bookingRef)
    },
  }
}
