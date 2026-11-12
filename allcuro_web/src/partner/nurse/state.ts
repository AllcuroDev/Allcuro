import { delay, persistedStore } from '../../lib/store'
import { saveSignup, type PartnerSession } from '../session'
import {
  CERTIFICATE_DOC_IDS,
  DEMO_VISIT_OTP,
  EMPTY_CHECKLIST,
  MEDICAL_DOC_ID,
  REQUEST_DETAILS,
  SEED_BLOCKED_DATES,
  SEED_COURSES,
  SEED_DAY_SLOTS,
  SEED_DOCS,
  SEED_PERFORMANCE,
  SEED_REQUESTS,
  SEED_SHIFTS,
  SEED_SKILLS,
  SEED_VISIT,
  SHIFT_TIME_OPTIONS,
  type ChecklistKey,
  type ComplianceDoc,
  type Course,
  type JobRequestDetail,
  type JobRequestSummary,
  type NursePerformance,
  type NurseVisit,
  type Shift,
  type ShiftPayout,
  type VisitStatus,
  type VitalSignsLog,
} from './data'

// Mutable demo state for the nurse / clinician pages — the web twin of the
// app's NurseService (in-memory mock) + PartnerOnboardingState nurse fields.
// Kept in localStorage so accept/decline, the active visit, duty status,
// documents and availability survive reloads.

// ---------------------------------------------------------------- requests & shifts

export const requestsStore = persistedStore<JobRequestSummary[]>('partner.nurse.requests', SEED_REQUESTS)
export const shiftsStore = persistedStore<Shift[]>('partner.nurse.shifts', SEED_SHIFTS)

export const requestDetail = (id: string): JobRequestDetail | null => REQUEST_DETAILS[id] ?? null

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

/** Demo helper: bring the sample requests back once they are all handled. */
export const restoreDemoRequests = () => requestsStore.set(SEED_REQUESTS.filter((r) => !shiftsStore.get().some((s) => s.id === `shift-${r.id}`)))

// ---------------------------------------------------------------- active visit

export const visitStore = persistedStore<NurseVisit>('partner.nurse.visit', SEED_VISIT)
export const performanceStore = persistedStore<NursePerformance>('partner.nurse.performance', SEED_PERFORMANCE)
/** Payouts credited by visits completed on the web (shown above the app's mock ledger). */
export const creditedPayoutsStore = persistedStore<ShiftPayout[]>('partner.nurse.payouts', [])

const patchVisit = (patch: Partial<NurseVisit>) => visitStore.set((v) => ({ ...v, ...patch }))

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
  visitStore.set((v) => ({ ...v, vitalsLog: vitals, checklist: { ...v.checklist, vitalsLogged: true } }))
}

export const setChecklistItem = (key: ChecklistKey, value: boolean) =>
  visitStore.set((v) => ({ ...v, checklist: { ...v.checklist, [key]: value } }))

/** Completes the visit when the patient's OTP (or the demo 1234) matches; credits the pay. */
export async function completeVisitWithOtp(otp: string): Promise<boolean> {
  await delay(300)
  const v = visitStore.get()
  const code = otp.trim()
  if (code !== v.expectedOtp && code !== DEMO_VISIT_OTP) return false
  patchVisit({ status: 'completed', checkOutTime: Date.now() })
  shiftsStore.set((list) => list.map((s) => (s.id === v.shiftId ? { ...s, status: 'completed' } : s)))
  performanceStore.set((p) => ({
    ...p,
    totalJobsCompleted: p.totalJobsCompleted + 1,
    monthlyJobsCompleted: p.monthlyJobsCompleted + 1,
    weeklyJobsCompleted: p.weeklyJobsCompleted + 1,
    totalRatingsCount: p.totalRatingsCount + 1,
    thisMonthEarnings: p.thisMonthEarnings + v.payValue,
    thisWeekEarnings: p.thisWeekEarnings + v.payValue,
    pendingPayout: p.pendingPayout + v.payValue,
  }))
  const date = new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })
  creditedPayoutsStore.set((list) => [{ date, description: `${v.serviceType} · ${v.patientName}`, amount: v.payValue }, ...list])
  return true
}

/** Demo helper: start the sample visit over (the shift goes back to ongoing). */
export function resetDemoVisit() {
  visitStore.set({ ...SEED_VISIT, checklist: EMPTY_CHECKLIST })
  shiftsStore.set((list) => list.map((s) => (s.id === SEED_VISIT.shiftId ? { ...s, status: 'ongoing' } : s)))
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

export const availabilityStore = persistedStore<AvailabilityState>('partner.nurse.availability', {
  isOnDuty: true,
  timing: SHIFT_TIME_OPTIONS[2],
  daySlots: SEED_DAY_SLOTS,
  blockedDates: SEED_BLOCKED_DATES,
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

/** Skills chosen here, else the sign-up wizard's, else the app's demo set (nurses only). */
export function effectiveSkills(a: AvailabilityState, s: PartnerSession): string[] {
  if (a.skills) return a.skills
  const fromSignup = s.signup.skills
  if (Array.isArray(fromSignup) && fromSignup.every((x) => typeof x === 'string')) return fromSignup as string[]
  return s.role === 'clinician' ? [] : SEED_SKILLS
}

/** "12-Hr Day (08:00 AM – 08:00 PM)" → "08:00 AM – 08:00 PM" for the compact duty bar. */
export const timingHours = (timing: string) => timing.match(/\(([^)]+)\)/)?.[1] ?? timing

// ---------------------------------------------------------------- KYC & setup hub

export interface KycState {
  docs: ComplianceDoc[]
  policeConsent: boolean
}

export const kycStore = persistedStore<KycState>('partner.nurse.kyc', { docs: SEED_DOCS, policeConsent: false })

export function markDocUploaded(id: string, fileName: string) {
  kycStore.set((k) => ({
    ...k,
    docs: k.docs.map((d) => (d.id === id ? { ...d, fileName, expiry: 'Uploaded just now', isUploaded: true, isVerified: false } : d)),
  }))
}

export const givePoliceConsent = () => kycStore.set((k) => ({ ...k, policeConsent: true }))

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
export function setupProgress(k: KycState, a: AvailabilityState, s: PartnerSession): SetupProgress {
  const profileDone = true // finished in the sign-up wizard
  const docsDone = k.docs.filter((d) => CERTIFICATE_DOC_IDS.includes(d.id) && d.isUploaded).length >= 2
  const medicalDone = k.docs.some((d) => d.id === MEDICAL_DOC_ID && d.isUploaded)
  const bankDone = s.bank != null && !!s.bank.account && !!s.bank.ifsc && !!s.bank.holder
  const skillsDone = effectiveSkills(a, s).length > 0
  const policeDone = k.policeConsent
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

export const coursesStore = persistedStore<Course[]>('partner.nurse.courses', SEED_COURSES)

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

export const daysAgoLabel = (days: number) =>
  days <= 0 ? 'Today' : days === 1 ? 'Yesterday' : days < 7 ? `${days} days ago` : days < 14 ? '1 week ago' : `${Math.floor(days / 7)} weeks ago`

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
