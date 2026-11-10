import { digitsOnly } from '../lib/format'
import { delay, persistedStore } from '../lib/store'

// Partner (nurse / clinician / centre) sign-in session — the web twin of the
// partner app's AuthSession + AuthViewModel (allcuro_partner/lib/features/auth).
// Demo mode like the app: the OTP is always DEMO_OTP and everything lives in
// localStorage, kept separate from the customer sign-in (`state/auth.ts`).

export const PARTNER_OTP = '123456'

export type ProviderRole = 'nurse' | 'clinician' | 'centre'

/** incomplete → onboarding (setup hub) → underReview → verified (live). */
export type NurseVerificationStatus = 'incomplete' | 'onboarding' | 'underReview' | 'verified'

/** incomplete → onboarding → pendingReview → siteVisitScheduled → verified. */
export type CentreVerificationStatus = 'incomplete' | 'onboarding' | 'pendingReview' | 'siteVisitScheduled' | 'verified'

/** Registration + Aadhaar proved before the nurse / clinician sign-up wizard (identity/data/verified_identity.dart). */
export interface VerifiedIdentity {
  fullName: string
  dob: string // ISO date
  gender: string
  address: string
  aadhaarLast4: string
  registrationLabel: string
  registrationNumber: string
  council: string
  qualification: string
  /** Clinicians only: 'Doctor' | 'Physiotherapist'. */
  profession?: string
}

export interface PartnerSession {
  isLoggedIn: boolean
  phone: string
  role: ProviderRole | null
  nurseStatus: NurseVerificationStatus
  clinicianStatus: NurseVerificationStatus
  centreStatus: CentreVerificationStatus
  nurseIdentity: VerifiedIdentity | null
  clinicianIdentity: VerifiedIdentity | null
  /** Display name — filled in by the sign-up wizards (centre name for a centre). */
  name: string
  /** Bank / UPI payout details saved from the bank account screen. */
  bank: { holder: string; account: string; ifsc: string; bankName: string; upi?: string } | null
  /** Free-form per-role sign-up answers saved by the wizards (skills, city, beds…). */
  signup: Record<string, unknown>
}

const initial: PartnerSession = {
  isLoggedIn: false,
  phone: '',
  role: null,
  nurseStatus: 'incomplete',
  clinicianStatus: 'incomplete',
  centreStatus: 'incomplete',
  nurseIdentity: null,
  clinicianIdentity: null,
  name: '',
  bank: null,
  signup: {},
}

export const partnerSession = persistedStore<PartnerSession>('partner.session', initial)
export const usePartnerSession = () => partnerSession.use()

export const usesNurseShell = (role: ProviderRole | null) => role === 'nurse' || role === 'clinician'

/** Status of whichever visit-based role (nurse or clinician) is active. */
export const practitionerStatus = (s: PartnerSession): NurseVerificationStatus =>
  s.role === 'clinician' ? s.clinicianStatus : s.nurseStatus

export const practitionerIdentity = (s: PartnerSession): VerifiedIdentity | null =>
  s.role === 'clinician' ? s.clinicianIdentity : s.nurseIdentity

export const identityPending = (s: PartnerSession) =>
  usesNurseShell(s.role) && practitionerIdentity(s) == null

export const signupIncomplete = (s: PartnerSession) =>
  s.role === 'centre'
    ? s.centreStatus === 'incomplete'
    : s.role
      ? practitionerStatus(s) === 'incomplete'
      : false

export class PartnerAuthError extends Error {}

export async function partnerSendOtp(phone: string) {
  await delay(600)
  if (digitsOnly(phone).length !== 10) throw new PartnerAuthError('Enter a valid 10-digit mobile number.')
}

export async function partnerVerifyOtp(phone: string, otp: string) {
  await delay(600)
  if (otp.trim() !== PARTNER_OTP) throw new PartnerAuthError(`Incorrect code. Use demo code ${PARTNER_OTP}.`)
  const digits = digitsOnly(phone)
  const prev = partnerSession.get()
  // Same number signs back into the same partner account (role + progress kept).
  partnerSession.set(prev.phone === digits ? { ...prev, isLoggedIn: true } : { ...initial, isLoggedIn: true, phone: digits })
}

export const selectRole = (role: ProviderRole) => partnerSession.set((s) => ({ ...s, role }))

/** Switch role from the profile screen (the app sends you back to role select). */
export const clearRole = () => partnerSession.set((s) => ({ ...s, role: null }))

export function saveIdentity(identity: VerifiedIdentity) {
  partnerSession.set((s) =>
    s.role === 'clinician'
      ? { ...s, clinicianIdentity: identity, name: s.name || identity.fullName }
      : { ...s, nurseIdentity: identity, name: s.name || identity.fullName },
  )
}

export function setPractitionerStatus(status: NurseVerificationStatus) {
  partnerSession.set((s) => (s.role === 'clinician' ? { ...s, clinicianStatus: status } : { ...s, nurseStatus: status }))
}

export const setCentreStatus = (status: CentreVerificationStatus) =>
  partnerSession.set((s) => ({ ...s, centreStatus: status }))

export const setPartnerName = (name: string) => partnerSession.set((s) => ({ ...s, name }))

export const saveSignup = (patch: Record<string, unknown>) =>
  partnerSession.set((s) => ({ ...s, signup: { ...s.signup, ...patch } }))

export const saveBank = (bank: PartnerSession['bank']) => partnerSession.set((s) => ({ ...s, bank }))

export const partnerLogout = () => partnerSession.set((s) => ({ ...s, isLoggedIn: false }))

/** Header badge text for the current role and verification stage. */
export function statusBadge(s: PartnerSession): { label: string; tone: 'ok' | 'warn' | 'info' } {
  if (usesNurseShell(s.role)) {
    switch (practitionerStatus(s)) {
      case 'verified':
        return { label: 'Verified · Live', tone: 'ok' }
      case 'underReview':
        return { label: 'Under review', tone: 'info' }
      default:
        return { label: 'Setup pending', tone: 'warn' }
    }
  }
  switch (s.centreStatus) {
    case 'verified':
      return { label: 'Verified · Live', tone: 'ok' }
    case 'siteVisitScheduled':
      return { label: 'Site visit scheduled', tone: 'info' }
    case 'pendingReview':
      return { label: 'Pending review', tone: 'info' }
    default:
      return { label: 'Setup pending', tone: 'warn' }
  }
}
