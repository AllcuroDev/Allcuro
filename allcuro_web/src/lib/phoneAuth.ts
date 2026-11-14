import { digitsOnly } from './format'
import { supabase } from './supabase'

// Real phone sign-in through Supabase Auth (SMS OTP). Shared by the customer
// site (state/auth.ts) and the partner portal (partner/session.ts).
//
// Supabase setup: Authentication → Sign In / Providers → Phone → enable, and
// connect an SMS provider (Twilio, MessageBird, Vonage or Textlocal). For
// testing without sending SMS, add numbers under "Test phone numbers & OTPs".

/** "98765 43210" → "+919876543210" (India). */
export const toE164 = (phone: string) => `+91${digitsOnly(phone).slice(-10)}`

export class PhoneAuthError extends Error {}

type Stage = 'send' | 'verify'

/**
 * Turns a Supabase/Twilio error into something a user can act on. Anything we
 * don't recognise is shown as-is (never hidden behind a generic message) and
 * the raw error is logged so sign-in problems can be diagnosed from the console.
 */
function friendly(stage: Stage, error: { message: string; status?: number; code?: string }) {
  console.warn(`[phone auth] ${stage} failed:`, error)
  const m = error.message.toLowerCase()
  if (m.includes('rate limit') || m.includes('too many') || m.includes('security purposes'))
    return 'Too many attempts. Please wait a minute and try again.'
  if (stage === 'verify' && (m.includes('expired') || m.includes('invalid') || m.includes('token')))
    return 'That code is incorrect or has expired. Request a new one.'
  if (m.includes('phone') && m.includes('disabled'))
    return 'Phone sign-in is turned off in Supabase (Authentication → Providers → Phone).'
  if (m.includes('signups not allowed') || m.includes('signup is disabled'))
    return 'New sign-ups are turned off in Supabase (Authentication → Sign In / Providers).'
  if (m.includes('database error'))
    return 'Your account could not be created (database trigger error). Please contact ALLCURO support.'
  if (stage === 'send') return `Could not send the code: ${error.message}`
  return error.message
}

const client = () => {
  if (!supabase) throw new PhoneAuthError('Sign-in is unavailable: this build has no Supabase keys.')
  return supabase
}

/** Sends a 6-digit code by SMS. Creates the account on first use. */
export async function requestOtp(phone: string) {
  if (digitsOnly(phone).length !== 10) throw new PhoneAuthError('Enter a valid 10-digit mobile number.')
  const { error } = await client().auth.signInWithOtp({ phone: toE164(phone) })
  if (error) throw new PhoneAuthError(friendly('send', error))
}

/** Checks the code and signs in. Returns the signed-in user's id. */
export async function confirmOtp(phone: string, code: string) {
  const token = code.trim()
  if (!/^\d{6}$/.test(token)) throw new PhoneAuthError('Enter the 6-digit code we sent you.')
  const { data, error } = await client().auth.verifyOtp({ phone: toE164(phone), token, type: 'sms' })
  if (error) throw new PhoneAuthError(friendly('verify', error))
  if (!data.user) throw new PhoneAuthError('Could not sign in. Please try again.')
  return data.user.id
}

export async function signOut() {
  await supabase?.auth.signOut()
}

/** Id of the signed-in user, or null. */
export async function currentUserId() {
  if (!supabase) return null
  const { data } = await supabase.auth.getSession()
  return data.session?.user.id ?? null
}
