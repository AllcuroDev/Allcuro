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

function friendly(message: string) {
  const m = message.toLowerCase()
  if (m.includes('expired') || m.includes('invalid')) return 'That code is incorrect or has expired. Request a new one.'
  if (m.includes('rate') || m.includes('too many') || m.includes('security purposes'))
    return 'Too many attempts. Please wait a minute and try again.'
  if (m.includes('provider') || m.includes('sms') || m.includes('unsupported phone'))
    return 'SMS sign-in isn’t set up yet. Please contact ALLCURO support.'
  return message
}

const client = () => {
  if (!supabase) throw new PhoneAuthError('Sign-in is unavailable: this build has no Supabase keys.')
  return supabase
}

/** Sends a 6-digit code by SMS. Creates the account on first use. */
export async function requestOtp(phone: string) {
  if (digitsOnly(phone).length !== 10) throw new PhoneAuthError('Enter a valid 10-digit mobile number.')
  const { error } = await client().auth.signInWithOtp({ phone: toE164(phone) })
  if (error) throw new PhoneAuthError(friendly(error.message))
}

/** Checks the code and signs in. Returns the signed-in user's id. */
export async function confirmOtp(phone: string, code: string) {
  const token = code.trim()
  if (!/^\d{6}$/.test(token)) throw new PhoneAuthError('Enter the 6-digit code we sent you.')
  const { data, error } = await client().auth.verifyOtp({ phone: toE164(phone), token, type: 'sms' })
  if (error || !data.user) throw new PhoneAuthError(friendly(error?.message ?? 'Could not sign in.'))
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
