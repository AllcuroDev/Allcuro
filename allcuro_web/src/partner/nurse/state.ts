import { delay, persistedStore } from '../../lib/store'
import { saveSignup, uploadedDocs, type PartnerSession } from '../session'
import {
  CERTIFICATE_DOC_IDS,
  MEDICAL_DOC_ID,
  REQUIRED_DOCS,
  SHIFT_TIME_OPTIONS,
  TRAINING_MODULES,
  type ChecklistKey,
  type ComplianceDoc,
  type Course,
  type JobRequestDetail,
  type JobRequestSummary,
  type NurseVisit,
  type Shift,
  type VisitStatus,
  type VitalSignsLog,
} from './data'

// State for the nurse / clinician pages — the web twin of the app's
// NurseService + PartnerOnboardingState nurse fields.
//
// There is no bookings backend yet, so requests, shifts and the active visit
// start empty (nothing is invented). The stores are kept so the pages are
// ready for real data. What the partner sets up themselves (duty status,
// availability, documents, training progress) is cached in localStorage, and
// skills go to public.partners through the sign-up bag.

// Caches from the old demo build held seeded patients, payouts and reviews.
// Drop them so returning browsers don't keep showing fabricated data.
if (typeof localStorage !== 'undefined') {
  for (const key of ['requests', 'shifts', 'visit', 'performance', 'payouts', 'availability', 'kyc', 'courses']) {
    try {
      localStorage.removeItem(`allcuro.partner.nurse.${key}`)
    } catch {
      // Storage blocked: nothing cached to clear.
    }
  }
}

// ---------------------------------------------------------------- requests & shifts

export const requestsStore = persistedStore<JobRequestSummary[]>('partner.nurse.v2.requests', [])
export const shiftsStore = persistedStore<Shift[]>('partner.nurse.v2.shifts', [])
const requestDetailsStore = persistedStore<Record<string, JobRequestDetail>>('partner.nurse.v2.requestDetails', {})

export const requestDetail = (id: string): JobRequestDetail | null => requestDetailsStore.get()[id] ?? null

/** Accepting books the request onto the schedule as an upcoming shift. */
export async function acceptRequest(id: string) {
  await delay(200)
  const req = requestsStore.get().find((r) => r.id === id)
  requestsStore.set((list) => list.filter((r) => r.id !== id))
  if (req && !shiftsStore.get().some((s) => s.id === `shift-${id}`)) {
    shiftsStore.set((list) => [
      ...list,
      {
        id: `shift-${id}`,
        patientName: req.patientName,
        serviceType: req.serviceType,
        timing: req.timing,
        locality: req.locality,
        status: 'upcoming',
      },
    ])
  }
}

export async function declineRequest(id: string) {
  await delay(200)
  requestsStore.set((list) => list.filter((r) => r.id !== id))
}

// ---------------------------------------------------------------- active visit

/** The visit in progress, if any. null until bookings exist. */
export const visitStore = persistedStore<NurseVisit | null>('partner.nurse.v2.visit', null)

const patchVisit = (patch: Partial<NurseVisit>) => visitStore.set((v) => (v ? { ...v, ...patch } : v))

export async function setVisitStatus(status: VisitStatus) {
  await delay(200)
  patchVisit({ status })
}

export async function verifyArrivalGpsAndSelfie() {
  await delay(400)
  patchVisit({ isGpsVerified: true, isSelfieVerified: true, status: 'reached' })
}

export async function checkInVisit() {
  await delay(200)
  patchVisit({ status: 'inProgress', checkInTime: Date.now() })
}

export async function logVitals(vitals: VitalSignsLog) {
  await delay(200)
  visitStore.set((v) => (v ? { ...v, vitalsLog: vitals, checklist: { ...v.checklist, vitalsLogged: true } } : v))
}

export const setChecklistItem = (key: ChecklistKey, value: boolean) =>
  visitStore.set((v) => (v ? { ...v, checklist: { ...v.checklist, [key]: value } } : v))

/** Completes the visit when the patient's OTP matches. */
export async function completeVisitWithOtp(otp: string): Promise<boolean> {
  await delay(300)
  const v = visitStore.get()
  if (!v || otp.trim() !== v.expectedOtp) return false
  patchVisit({ status: 'completed', checkOutTime: Date.now() })
  shiftsStore.set((list) => list.map((s) => (s.id === v.shiftId ? { ...s, status: 'completed' } : s)))
  return true
}

// ---------------------------------------------------------------- duty & availability

export interface AvailabilityState {
  isOnDuty: boolean
  /** One of SHIFT_TIME_OPTIONS. */
  timing: string
  /** `${day}-${slot}` keys, e.g. "Mon-Morning". */
  daySlots: string[]
  /** ISO dates (yyyy-mm-dd). */
  blockedDates: string[]
  /** null → use what the sign-up wizard saved (or the app's defaults). */
  skills: string[] | null
  hourlyRate: number
  dailyRate: number
}

export const availabilityStore = persistedStore<AvailabilityState>('partner.nurse.v2.availability', {
  isOnDuty: false,
  timing: SHIFT_TIME_OPTIONS[2],
  daySlots: [],
  blockedDates: [],
  skills: null,
  hourlyRate: 250,
  dailyRate: 2200,
})

export async function setDutyStatus(isOnDuty: boolean, timing?: string) {
  availabilityStore.set((a) => ({ ...a, isOnDuty, timing: timing ?? a.timing }))
  await delay(150)
}

export const setShiftTiming = (timing: string) => availabilityStore.set((a) => ({ ...a, timing }))

export const toggleDaySlot = (day: string, slot: string) =>
  availabilityStore.set((a) => {
    const key = `${day}-${slot}`
    return { ...a, daySlots: a.daySlots.includes(key) ? a.daySlots.filter((k) => k !== key) : [...a.daySlots, key] }
  })

export const addBlockedDate = (iso: string) =>
  availabilityStore.set((a) => (a.blockedDates.includes(iso) ? a : { ...a, blockedDates: [...a.blockedDates, iso].sort() }))

export const removeBlockedDate = (iso: string) =>
  availabilityStore.set((a) => ({ ...a, blockedDates: a.blockedDates.filter((d) => d !== iso) }))

/** Saves skills locally and to public.partners (via the sign-up bag). Rates are admin-set; the args are kept for the app's API. */
export const saveSkillsAndRates = (skills: string[], hourlyRate: number, dailyRate: number) => {
  availabilityStore.set((a) => ({ ...a, skills, hourlyRate, dailyRate }))
  saveSignup({ skills })
}

/** Skills chosen here, else the sign-up wizard's. */
export function effectiveSkills(a: AvailabilityState, s: PartnerSession): string[] {
  if (a.skills) return a.skills
  const fromSignup = s.signup.skills
  if (Array.isArray(fromSignup) && fromSignup.every((x) => typeof x === 'string')) return fromSignup as string[]
  return []
}

/** "12-Hr Day (08:00 AM – 08:00 PM)" → "08:00 AM – 08:00 PM" for the compact duty bar. */
export const timingHours = (timing: string) => timing.match(/\(([^)]+)\)/)?.[1] ?? timing

// ---------------------------------------------------------------- KYC & setup hub

/** The required documents, marked uploaded from what the partner actually uploaded (partners.details.documents). */
export function nurseDocs(s: PartnerSession): ComplianceDoc[] {
  const uploaded = uploadedDocs(s)
  return REQUIRED_DOCS.map((d) => {
    const u = uploaded[d.id]
    if (!u) return d
    const when = new Date(u.uploadedAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
    return { ...d, fileName: u.fileName, expiry: `Uploaded ${when} · awaiting ALLCURO review`, isUploaded: true, isVerified: false }
  })
}

/** Police background-check consent, saved on the partner row (also asked in the sign-up wizard). */
export const hasPoliceConsent = (s: PartnerSession) => s.signup.policeConsent === true || s.signup.backgroundConsent === true

export const givePoliceConsent = () => saveSignup({ policeConsent: true })

export interface SetupProgress {
  profileDone: boolean
  docsDone: boolean
  medicalDone: boolean
  bankDone: boolean
  skillsDone: boolean
  policeDone: boolean
  completed: number
  total: number
  canSubmit: boolean
}

/** Same rules as PartnerOnboardingState's nurse getters. */
export function setupProgress(a: AvailabilityState, s: PartnerSession): SetupProgress {
  const docs = nurseDocs(s)
  const profileDone = true // finished in the sign-up wizard
  const docsDone = docs.filter((d) => CERTIFICATE_DOC_IDS.includes(d.id) && d.isUploaded).length >= CERTIFICATE_DOC_IDS.length
  const medicalDone = docs.some((d) => d.id === MEDICAL_DOC_ID && d.isUploaded)
  const bankDone = s.bank != null && !!s.bank.account && !!s.bank.ifsc && !!s.bank.holder
  const skillsDone = effectiveSkills(a, s).length > 0
  const policeDone = hasPoliceConsent(s)
  const flags = [profileDone, docsDone, medicalDone, bankDone, skillsDone, policeDone]
  return {
    profileDone,
    docsDone,
    medicalDone,
    bankDone,
    skillsDone,
    policeDone,
    completed: flags.filter(Boolean).length,
    total: flags.length,
    canSubmit: profileDone && docsDone && bankDone && skillsDone,
  }
}

// ---------------------------------------------------------------- training

export const coursesStore = persistedStore<Course[]>('partner.nurse.v2.courses', TRAINING_MODULES)

/** "Continue" bumps progress by 25% like the app (no real course player). */
export const continueCourse = (index: number) =>
  coursesStore.set((list) => list.map((c, i) => (i === index ? { ...c, progress: Math.min(100, c.progress + 25) } : c)))

// ---------------------------------------------------------------- formatting helpers

export const formatTimer = (seconds: number) => {
  const s = Math.max(0, Math.floor(seconds))
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${pad(Math.floor(s / 3600))}:${pad(Math.floor((s % 3600) / 60))}:${pad(s % 60)}`
}

/** "08 hrs 15 mins" */
export const formatDuration = (ms: number) => {
  const mins = Math.max(0, Math.round(ms / 60000))
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${pad(Math.floor(mins / 60))} hrs ${pad(mins % 60)} mins`
}

export const formatIsoDate = (iso: string) =>
  new Date(`${iso}T00:00:00`).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })

export const todayIso = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export const maskedAadhaar = (last4: string) => `XXXX XXXX ${last4}`

export const greeting = (hour = new Date().getHours()) =>
  hour < 12 ? 'Good morning,' : hour < 17 ? 'Good afternoon,' : 'Good evening,'

export const visitStatusLabel: Record<VisitStatus, string> = {
  assigned: 'ASSIGNED',
  enRoute: 'EN ROUTE',
  reached: 'REACHED',
  inProgress: 'IN PROGRESS',
  completed: 'COMPLETED',
}

export const mapsUrl = (address: string) => `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(address)}`
export const telUrl = (phone: string) => `tel:${phone.replace(/[^\d+]/g, '')}`
