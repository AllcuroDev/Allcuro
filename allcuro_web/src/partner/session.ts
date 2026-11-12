import { digitsOnly } from '../lib/format'
import { confirmOtp, requestOtp, signOut, toE164 } from '../lib/phoneAuth'
import { persistedStore } from '../lib/store'
import { supabase } from '../lib/supabase'

// Partner (nurse / clinician / centre) session — the web twin of the partner
// app's AuthSession + AuthViewModel (allcuro_partner/lib/features/auth).
//
// Sign-in is real phone OTP through Supabase Auth (lib/phoneAuth.ts). Each role
// a partner signs up for is one row in public.partners (unique per user +
// role). Every change here is written to that row; the row's status is the
// truth for approval — only an admin can move a partner to verified (approved),
// site visit, rejected or suspended (enforced by the partners_guard trigger).
// The local store is a cache so the portal renders instantly.

export type ProviderRole = 'nurse' | 'clinician' | 'centre'

/** incomplete → onboarding (setup hub) → underReview → verified (live, approved by admin). */
export type NurseVerificationStatus = 'incomplete' | 'onboarding' | 'underReview' | 'verified' | 'rejected' | 'suspended'

/** incomplete → onboarding → pendingReview → siteVisitScheduled → verified. */
export type CentreVerificationStatus =
  | 'incomplete'
  | 'onboarding'
  | 'pendingReview'
  | 'siteVisitScheduled'
  | 'verified'
  | 'rejected'
  | 'suspended'

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
  /** Note from the admin, shown when a profile is rejected or suspended. */
  adminNote: string
  /** public.partners ids, per role. */
  partnerIds: Partial<Record<ProviderRole, string>>
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
  adminNote: '',
  partnerIds: {},
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

// ---------------------------------------------------------------- DB mapping

type DbStatus = 'incomplete' | 'onboarding' | 'under_review' | 'site_visit_scheduled' | 'approved' | 'rejected' | 'suspended'

const toDbStatus = (st: NurseVerificationStatus | CentreVerificationStatus): DbStatus =>
  (
    ({
      incomplete: 'incomplete',
      onboarding: 'onboarding',
      underReview: 'under_review',
      pendingReview: 'under_review',
      siteVisitScheduled: 'site_visit_scheduled',
      verified: 'approved',
      rejected: 'rejected',
      suspended: 'suspended',
    }) as const
  )[st]

function fromDbStatus(st: DbStatus, centre: true): CentreVerificationStatus
function fromDbStatus(st: DbStatus, centre: false): NurseVerificationStatus
function fromDbStatus(st: DbStatus, centre: boolean): NurseVerificationStatus | CentreVerificationStatus {
  switch (st) {
    case 'under_review':
      return centre ? 'pendingReview' : 'underReview'
    case 'site_visit_scheduled':
      return centre ? 'siteVisitScheduled' : 'underReview'
    case 'approved':
      return 'verified'
    default:
      return st
  }
}

interface PartnerRow {
  id: string
  role: ProviderRole
  status: DbStatus
  display_name: string
  admin_note: string
  identity: Partial<VerifiedIdentity> | null
  bank: PartnerSession['bank']
  details: Record<string, unknown> | null
}

const kindFor = (role: ProviderRole, identity: VerifiedIdentity | null) =>
  role === 'centre'
    ? 'centre'
    : role === 'nurse'
      ? 'nurse'
      : identity?.profession === 'Physiotherapist'
        ? 'physiotherapist'
        : 'doctor'

const str = (v: unknown) => (typeof v === 'string' ? v : '')
const strs = (v: unknown) => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : [])

/** The row for `role`, built from the session (the wizard bag holds most answers). */
function rowFor(s: PartnerSession, role: ProviderRole) {
  const identity = role === 'clinician' ? s.clinicianIdentity : role === 'nurse' ? s.nurseIdentity : null
  const status = role === 'centre' ? s.centreStatus : role === 'clinician' ? s.clinicianStatus : s.nurseStatus
  const g = s.signup
  const base = {
    role,
    kind: kindFor(role, identity),
    status: toDbStatus(status),
    display_name: s.name,
    phone: s.phone ? toE164(s.phone) : '',
    city: str(g.city),
    address: str(g.address) || identity?.address || '',
    bank: s.bank,
    details: g,
  }
  if (role === 'centre')
    return {
      ...base,
      centre_type: str(g.centreType),
      headline: str(g.centreType),
      year_established: Number(g.yearEstablished) || null,
      email: str(g.businessEmail),
      staff_ratio: str(g.staffRatio),
      food_menu: str(g.sampleFoodMenu),
      services_included: strs(g.servicesIncluded),
      room_types: strs(g.roomTypes),
    }
  return {
    ...base,
    qualification: identity?.qualification ?? str(g.qualification),
    headline: identity?.qualification ?? str(g.qualification),
    registration_number: identity?.registrationNumber ?? str(g.registrationNumber),
    council: identity?.council ?? str(g.council),
    experience_years: Number(g.experienceYears) || 0,
    previous_employer: str(g.previousEmployer),
    employment_type: str(g.employmentType) || 'Full-time',
    specialisations: strs(g.specialisations),
    skills: strs(g.skills),
    identity: identity
      ? {
          fullName: identity.fullName,
          dob: identity.dob,
          gender: identity.gender,
          aadhaarLast4: identity.aadhaarLast4,
          registrationLabel: identity.registrationLabel,
          profession: identity.profession,
        }
      : {},
  }
}

let pushChain: Promise<unknown> = Promise.resolve()

/**
 * Upserts the active role's row. Serialised so quick successive edits land in
 * order. Errors are logged, not thrown: the portal keeps working from the cache.
 */
function push(role: ProviderRole | null = partnerSession.get().role) {
  if (!role || !supabase) return pushChain
  const db = supabase
  pushChain = pushChain.then(async () => {
    const { data: auth } = await db.auth.getSession()
    const userId = auth.session?.user.id
    if (!userId) return
    const s = partnerSession.get()
    const { data, error } = await db
      .from('partners')
      .upsert({ user_id: userId, ...rowFor(s, role) }, { onConflict: 'user_id,role' })
      .select('id, role, status, display_name, admin_note, identity, bank, details')
      .single<PartnerRow>()
    if (error) {
      console.warn('Partner profile not saved:', error.message)
      return
    }
    applyRow(data)
  })
  return pushChain
}

/** Writes a DB row's admin-controlled bits (status, note, id) back into the cache. */
function applyRow(r: PartnerRow) {
  partnerSession.set((s) => {
    const next = { ...s, partnerIds: { ...s.partnerIds, [r.role]: r.id } }
    if (r.role === 'centre') next.centreStatus = fromDbStatus(r.status, true)
    else if (r.role === 'clinician') next.clinicianStatus = fromDbStatus(r.status, false)
    else next.nurseStatus = fromDbStatus(r.status, false)
    if (r.role === s.role) next.adminNote = r.admin_note ?? ''
    return next
  })
}

/** Loads every partners row for the signed-in user into the cache. */
export async function refreshPartner() {
  if (!supabase) return
  const { data: auth } = await supabase.auth.getSession()
  const userId = auth.session?.user.id
  if (!userId) {
    if (partnerSession.get().isLoggedIn) partnerSession.set((s) => ({ ...s, isLoggedIn: false }))
    return
  }
  const { data } = await supabase
    .from('partners')
    .select('id, role, status, display_name, admin_note, identity, bank, details')
    .eq('user_id', userId)
  const rows = (data ?? []) as PartnerRow[]
  partnerSession.set((s) => {
    const next: PartnerSession = { ...s, isLoggedIn: true }
    // A role with no row in the database hasn't been saved yet: never trust a
    // cached status for it (e.g. "verified" left over from the old demo mode).
    const has = (role: ProviderRole) => rows.some((r) => r.role === role)
    if (!has('nurse')) next.nurseStatus = 'incomplete'
    if (!has('clinician')) next.clinicianStatus = 'incomplete'
    if (!has('centre')) next.centreStatus = 'incomplete'
    next.partnerIds = {}
    for (const r of rows) {
      next.partnerIds = { ...next.partnerIds, [r.role]: r.id }
      if (r.role === 'centre') next.centreStatus = fromDbStatus(r.status, true)
      else if (r.role === 'clinician') next.clinicianStatus = fromDbStatus(r.status, false)
      else next.nurseStatus = fromDbStatus(r.status, false)
      const id = r.identity
      if (id?.fullName && r.role !== 'centre') {
        const restored = { address: '', registrationNumber: '', council: '', qualification: '', ...id } as VerifiedIdentity
        if (r.role === 'clinician') next.clinicianIdentity = next.clinicianIdentity ?? restored
        else next.nurseIdentity = next.nurseIdentity ?? restored
      }
    }
    // Pick the role to open: the cached one if it still exists, else the only one.
    if (!next.role || !rows.some((r) => r.role === next.role)) next.role = rows.length === 1 ? rows[0].role : (next.role ?? null)
    const active = rows.find((r) => r.role === next.role)
    if (active) {
      next.name = active.display_name || next.name
      next.bank = active.bank ?? next.bank
      next.signup = { ...(active.details ?? {}), ...next.signup }
      next.adminNote = active.admin_note ?? ''
    }
    return next
  })
}

// Pick up approval changes when the portal opens or the tab comes back into view.
if (typeof window !== 'undefined' && supabase) {
  void refreshPartner()
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible' && partnerSession.get().isLoggedIn) void refreshPartner()
  })
}

// ---------------------------------------------------------------- auth

export async function partnerSendOtp(phone: string) {
  try {
    await requestOtp(phone)
  } catch (e) {
    throw new PartnerAuthError(e instanceof Error ? e.message : 'Could not send the code.')
  }
}

export async function partnerVerifyOtp(phone: string, otp: string) {
  try {
    await confirmOtp(phone, otp)
  } catch (e) {
    throw new PartnerAuthError(e instanceof Error ? e.message : 'Could not verify the code.')
  }
  const digits = digitsOnly(phone)
  const prev = partnerSession.get()
  // A different number is a different account: start from a clean cache.
  partnerSession.set(prev.phone === digits ? { ...prev, isLoggedIn: true } : { ...initial, isLoggedIn: true, phone: digits })
  await refreshPartner()
}

export const selectRole = (role: ProviderRole) => {
  partnerSession.set((s) => ({ ...s, role }))
  void refreshPartner()
}

/** Switch role from the profile screen (the app sends you back to role select). */
export const clearRole = () => partnerSession.set((s) => ({ ...s, role: null }))

export function saveIdentity(identity: VerifiedIdentity) {
  partnerSession.set((s) =>
    s.role === 'clinician'
      ? { ...s, clinicianIdentity: identity, name: s.name || identity.fullName }
      : { ...s, nurseIdentity: identity, name: s.name || identity.fullName },
  )
  void push()
}

/** Partners can move themselves only up to "submitted for review"; the DB ignores anything further. */
export function setPractitionerStatus(status: NurseVerificationStatus) {
  partnerSession.set((s) => (s.role === 'clinician' ? { ...s, clinicianStatus: status } : { ...s, nurseStatus: status }))
  return push()
}

export const setCentreStatus = (status: CentreVerificationStatus) => {
  partnerSession.set((s) => ({ ...s, centreStatus: status }))
  return push()
}

export const setPartnerName = (name: string) => {
  partnerSession.set((s) => ({ ...s, name }))
  void push()
}

export const saveSignup = (patch: Record<string, unknown>) => {
  partnerSession.set((s) => ({ ...s, signup: { ...s.signup, ...patch } }))
  void push()
}

export const saveBank = (bank: PartnerSession['bank']) => {
  partnerSession.set((s) => ({ ...s, bank }))
  void push()
}

export const partnerLogout = () => {
  partnerSession.set((s) => ({ ...s, isLoggedIn: false }))
  void signOut()
}

/** Header badge text for the current role and verification stage. */
export function statusBadge(s: PartnerSession): { label: string; tone: 'ok' | 'warn' | 'info' } {
  const st = s.role === 'centre' ? s.centreStatus : practitionerStatus(s)
  switch (st) {
    case 'verified':
      return { label: 'Verified · Live', tone: 'ok' }
    case 'underReview':
    case 'pendingReview':
      return { label: 'Under review', tone: 'info' }
    case 'siteVisitScheduled':
      return { label: 'Site visit scheduled', tone: 'info' }
    case 'rejected':
      return { label: 'Changes requested', tone: 'warn' }
    case 'suspended':
      return { label: 'Suspended', tone: 'warn' }
    default:
      return { label: 'Setup pending', tone: 'warn' }
  }
}
