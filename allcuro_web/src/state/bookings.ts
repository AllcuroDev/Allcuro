import type { BillLine } from '../data/booking'
import { delay, persistedStore } from '../lib/store'
import { currentPhone, useAuth } from './auth'

// Bookings, mirroring allcuro/lib/features/bookings (Booking model +
// BookingsService). Kept per signed-in phone number in localStorage until the
// backend exists.

export type BookingType = 'nurse' | 'centre' | 'equipment'
export type LiveStatus = 'assigned' | 'enRoute' | 'reached' | 'inProgress' | 'completed'

export interface Payment {
  method: string
  reference: string
  paidAt: number
  lines: BillLine[]
  /** "Pay after visit": nothing charged online yet. */
  payLater?: boolean
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

export const isActive = (b: Booking) => b.liveStatus !== 'completed'

// ---- Store ----

const store = persistedStore<Record<string, Booking[]>>('bookings', {})

/** The app ships demo bookings so the tracker and admission pass can be explored straight away. */
const demoBookings = (): Booking[] => [
  {
    id: 'ALC-NUR-8921',
    type: 'nurse',
    title: 'Priya Sharma (GNM) · Post-Op Care',
    when: 'Today · 08:00 AM – 08:00 PM',
    amount: 1600,
    otp: '4829',
    liveStatus: 'inProgress',
    createdAt: Date.now() - 3_600_000,
    patientName: 'Ramesh Iyer',
    patientAge: 68,
    patientGender: 'Male',
    address: 'Flat 402, Green Glen Palms, 12th Main, Indiranagar, Bengaluru',
    locality: 'Indiranagar, Bengaluru',
    providerName: 'Priya Sharma',
    providerPhone: '+91 98450 12345',
    providerRating: 4.92,
    providerQualifications: 'GNM · 4 yrs exp · HPR Verified',
    vitalsSummary: 'BP: 120/80 mmHg · Sugar: 112 mg/dL · Pulse: 74 bpm · Temp: 98.4 °F',
    condition: 'Post-Op Knee Replacement Care & IV Infusion',
    formalities: [],
  },
  {
    id: 'ALC-CTR-4920',
    type: 'centre',
    title: 'Sanjeevani Elder Care · Deluxe Room',
    when: 'Check-in: Tomorrow, 10:00 AM · 30 Days',
    amount: 45000,
    otp: '7391',
    liveStatus: 'assigned',
    createdAt: Date.now() - 7_200_000,
    patientName: 'Kavita Nair',
    patientAge: 74,
    patientGender: 'Female',
    address: 'Sanjeevani Elder Care, 4th Cross, 100ft Road, Indiranagar, Bengaluru',
    locality: 'Indiranagar, Bengaluru',
    providerName: 'Sanjeevani Elder Care Home',
    providerPhone: '+91 80 4120 5500',
    providerRating: 4.88,
    providerQualifications: 'Field Audited · 1:3 Nurse Ratio · Fire & NABH NOC',
    roomType: 'Deluxe Private Room with Assisted Bath',
    formalities: [
      'Govt Photo ID (Aadhaar / Passport) of patient',
      'Hospital Discharge Summary & Doctor Prescription',
      'Digital Admission Pass & Check-In OTP (7391)',
      'Signed Care Agreement & Emergency Contact Consent',
    ],
  },
  {
    id: 'ALC-EQP-83102',
    type: 'equipment',
    title: 'Philips EverFlo 5L Oxygen Concentrator',
    when: 'Monthly Rental · 18 days left',
    amount: 4500,
    otp: '2910',
    liveStatus: 'inProgress',
    createdAt: Date.now() - 86_400_000 * 12,
    patientName: 'Ramesh Iyer',
    patientAge: 68,
    patientGender: 'Male',
    address: 'Indiranagar, Bengaluru',
    locality: 'Indiranagar',
    providerName: 'ALLCURO Equipment Desk',
    providerPhone: '+91 80 4120 5500',
    providerRating: 4.8,
    providerQualifications: 'Sanitised · Delivered & demonstrated',
    formalities: [],
  },
  {
    id: 'ALC-NUR-82554',
    type: 'nurse',
    title: 'Ananya Deshmukh (B.Sc) · IV Infusion',
    when: '14 Aug 2026 · Completed',
    amount: 1200,
    otp: '1839',
    liveStatus: 'completed',
    createdAt: Date.now() - 86_400_000 * 70,
    patientName: 'Ramesh Iyer',
    patientAge: 68,
    patientGender: 'Male',
    address: 'Indiranagar, Bengaluru',
    locality: 'Indiranagar',
    providerName: 'Ananya Deshmukh',
    providerPhone: '+91 98450 22345',
    providerRating: 4.9,
    providerQualifications: 'B.Sc Nursing · HPR Verified',
    vitalsSummary: 'BP: 124/82 mmHg · Pulse: 76 bpm · Normal Recovery',
    formalities: [],
  },
]

const EMPTY: Booking[] = []

/** The signed-in member's bookings, newest first. */
export function useBookings(): Booking[] {
  const all = store.use()
  const { profile, isLoggedIn } = useAuth()
  if (!isLoggedIn || !profile) return EMPTY
  return all[profile.phone] ?? EMPTY
}

export const useBooking = (id: string) => useBookings().find((b) => b.id === id)

/** Gives a member the demo bookings the first time they sign in. */
export function seedDemoBookings(phone: string) {
  if (store.get()[phone]) return
  store.set((all) => ({ ...all, [phone]: demoBookings() }))
}

const PREFIX: Record<BookingType, string> = { nurse: 'ALC-NUR', centre: 'ALC-CTR', equipment: 'ALC-EQP' }
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
