import type { BillLine } from '../data/booking'
import { delay, persistedStore } from '../lib/store'
import { currentPhone, useAuth } from './auth'

// Bookings, mirroring allcuro/lib/features/bookings (Booking model +
// BookingsService). Kept per signed-in phone number in localStorage until the
// backend exists.

export type BookingType = 'nurse' | 'centre' | 'equipment' | 'medicine'
export type LiveStatus = 'assigned' | 'enRoute' | 'reached' | 'inProgress' | 'completed'

export interface Payment {
  method: string
  reference: string
  paidAt: number
  lines: BillLine[]
  /** "Pay after visit": nothing charged online yet. */
  payLater?: boolean
}

/** One line of a medicine order, as it was when the order was placed. */
export interface OrderItem {
  name: string
  pack: string
  qty: number
  /** Unit price (GST-inclusive). */
  price: number
}

export interface Booking {
  id: string
  type: BookingType
  title: string
  when: string
  amount: number
  otp: string
  /** Fixed status for bookings that do not move on their own (seeded demo data, scheduled visits). */
  liveStatus: LiveStatus
  /** Set for instant nurse visits: the trip timeline runs from this moment. */
  tripStartedAt?: number
  createdAt: number
  patientName: string
  patientAge: number
  patientGender: string
  address: string
  locality: string
  providerName: string
  providerPhone: string
  providerRating: number
  providerQualifications: string
  vitalsSummary?: string
  condition?: string
  roomType?: string
  formalities: string[]
  payment?: Payment
  rating?: { stars: number; review: string }
  /** Medicine orders: what was ordered, and the prescription file sent with it. */
  items?: OrderItem[]
  prescriptionName?: string
}

// ---- Medicine order timeline ----
// No pharmacy backend yet: an order moves through its stages on a clock from
// the moment it was placed, the way the nurse tracker follows its trip.

export const MEDICINE_STAGES = ['Order placed', 'Pharmacist verified', 'Packed', 'Out for delivery', 'Delivered'] as const
const MEDICINE_STAGE_AT_MS = [0, 2 * 60_000, 10 * 60_000, 30 * 60_000, 120 * 60_000]

/** Index into MEDICINE_STAGES (4 = delivered). */
export function medicineStageAt(b: Booking, now: number) {
  if (b.liveStatus === 'completed') return MEDICINE_STAGES.length - 1
  const t = now - b.createdAt
  let stage = 0
  MEDICINE_STAGE_AT_MS.forEach((at, i) => {
    if (t >= at) stage = i
  })
  return stage
}

// ---- Live visit timeline (instant nurse bookings) ----
// The app animates a 90-second trip until partner-app GPS pings exist; the
// website follows the same timeline from the moment of booking.

export const ASSIGN_MS = 8_000
export const TRIP_MS = 90_000
const VISIT_START_MS = 20_000

export function liveStatusAt(b: Booking, now: number): LiveStatus {
  if (!b.tripStartedAt) return b.liveStatus
  const t = now - b.tripStartedAt
  if (t < ASSIGN_MS) return 'assigned'
  if (t < ASSIGN_MS + TRIP_MS) return 'enRoute'
  if (t < ASSIGN_MS + TRIP_MS + VISIT_START_MS) return 'reached'
  return 'inProgress'
}

/** 0 = nurse just left, 1 = arrived. */
export function tripProgress(b: Booking, now: number) {
  if (!b.tripStartedAt) return b.liveStatus === 'enRoute' ? 0.5 : 1
  return Math.min(1, Math.max(0, (now - b.tripStartedAt - ASSIGN_MS) / TRIP_MS))
}

export function statusLabel(b: Booking, now: number) {
  if (b.type === 'medicine') {
    return ['Confirmed', 'Pharmacist Verified', 'Packed', 'Out for Delivery', 'Delivered'][medicineStageAt(b, now)]
  }
  const s = liveStatusAt(b, now)
  if (b.type === 'centre') return s === 'completed' ? 'Discharged' : 'Confirmed'
  if (b.type === 'equipment') return s === 'completed' ? 'Returned' : s === 'inProgress' ? 'Active' : 'Order Confirmed'
  return {
    assigned: b.tripStartedAt ? 'Nurse Assigned' : 'Confirmed',
    enRoute: 'Nurse On The Way',
    reached: 'Nurse Arrived',
    inProgress: 'In Progress',
    completed: 'Completed',
  }[s]
}

export const isActive = (b: Booking, now = Date.now()) =>
  b.type === 'medicine' ? medicineStageAt(b, now) < MEDICINE_STAGES.length - 1 : b.liveStatus !== 'completed'

// ---- Store ----

const store = persistedStore<Record<string, Booking[]>>('bookings', {})

// Older builds seeded these sample bookings on first sign-in; clear them from
// browsers that still have them saved.
const OLD_SAMPLE_IDS = new Set(['ALC-NUR-8921', 'ALC-CTR-4920', 'ALC-EQP-83102', 'ALC-NUR-82554'])
if (Object.values(store.get()).some((list) => list.some((b) => OLD_SAMPLE_IDS.has(b.id))))
  store.set((all) =>
    Object.fromEntries(Object.entries(all).map(([phone, list]) => [phone, list.filter((b) => !OLD_SAMPLE_IDS.has(b.id))])),
  )

const EMPTY: Booking[] = []

/** The signed-in member's bookings, newest first. */
export function useBookings(): Booking[] {
  const all = store.use()
  const { profile, isLoggedIn } = useAuth()
  if (!isLoggedIn || !profile) return EMPTY
  return all[profile.phone] ?? EMPTY
}

export const useBooking = (id: string) => useBookings().find((b) => b.id === id)

const PREFIX: Record<BookingType, string> = {
  nurse: 'ALC-NUR',
  centre: 'ALC-CTR',
  equipment: 'ALC-EQP',
  medicine: 'ALC-MED',
}
const randomDigits = (n: number) => String(Math.floor(Math.random() * 10 ** n)).padStart(n, '0')

export type NewBooking = Omit<Booking, 'id' | 'otp' | 'createdAt' | 'tripStartedAt'> & {
  /** Instant visit: the nurse sets off now and the live tracker starts running. */
  startTrip?: boolean
}

export async function createBooking({ startTrip, ...input }: NewBooking): Promise<Booking> {
  await delay(200)
  const phone = currentPhone()
  const otp = String(1000 + Math.floor(Math.random() * 9000))
  const now = Date.now()
  const booking: Booking = {
    ...input,
    id: `${PREFIX[input.type]}-${randomDigits(5)}`,
    otp,
    createdAt: now,
    tripStartedAt: startTrip ? now : undefined,
    formalities: input.formalities.map((f) => (f.includes('Check-In OTP') ? `${f} (${otp})` : f)),
  }
  store.set((all) => ({ ...all, [phone]: [booking, ...(all[phone] ?? [])] }))
  return booking
}

export function rateBooking(id: string, stars: number, review: string) {
  const phone = currentPhone()
  store.set((all) => ({
    ...all,
    [phone]: (all[phone] ?? []).map((b) => (b.id === id ? { ...b, rating: { stars, review } } : b)),
  }))
}
