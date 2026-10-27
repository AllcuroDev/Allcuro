// Booking choices and price rules, mirroring the app's booking screens:
//   nurse_quick_booking_screen.dart, service_detail_screen.dart (slot sheet),
//   centre_booking_screen.dart, checkout_repository.dart

export interface QuickService {
  id: string
  title: string
  duration: string
  price: number
  icon: string
  description: string
}

export const quickServices: QuickService[] = [
  {
    id: 'vitals',
    title: 'Vital Signs & Health Monitoring',
    duration: '45 mins visit',
    price: 499,
    icon: 'vitals',
    description: 'BP, Blood Sugar, SpO2, Pulse, Temp & clinical charting.',
  },
  {
    id: 'wound-iv',
    title: 'Post-Op Wound Dressing & IV',
    duration: '1 hr visit',
    price: 999,
    icon: 'iv_drip',
    description: 'Surgical wound cleaning, sterile dressing & IV infusion.',
  },
  {
    id: 'day-shift',
    title: '12-Hour Day Shift Nursing',
    duration: '12 hours (8 AM - 8 PM)',
    price: 1600,
    icon: 'home_nurse',
    description: 'Dedicated post-op recovery, medication & toilet care.',
  },
  {
    id: 'live-in',
    title: '24-Hour Live-in Attendant Care',
    duration: '24 hours / full-day',
    price: 2800,
    icon: 'elder_care',
    description: '24x7 mobility, feeding, hygiene & overnight assistance.',
  },
]

/** First slot is the instant one: the nurse leaves right away and can be tracked live. */
export const timeSlots = [
  '⚡ Instant (Arrives in 30–45 mins)',
  'Today · Afternoon (02:00 PM – 08:00 PM)',
  'Today · Night Shift (08:00 PM – 08:00 AM)',
  'Tomorrow · Morning (08:00 AM – 02:00 PM)',
]
export const INSTANT_SLOT = timeSlots[0]

/** Visit length picked on a nurse card ("Book Slot" sheet). */
export const visitDurations = [
  { id: '30min', title: '30 Mins', subtitle: 'Quick Visit', label: '30 Mins (Quick Procedure)', price: 399 },
  { id: '1hr', title: '1 Hour', subtitle: 'Standard Care', label: '1 Hour (Standard Visit)', price: 699 },
  { id: '2hr', title: '2 Hours', subtitle: 'Extended Visit', label: '2 Hours (Extended Care)', price: 1199 },
] as const

export const customShiftPrices: Record<number, number> = { 4: 1999, 8: 3499, 12: 4899, 24: 8499 }

export const slotSheetTimes = ['⚡ Within 45 mins (Immediate)', 'Today 2:30 PM', 'Today 6:00 PM', 'Tomorrow 9:00 AM']

export const roomOptions = [
  {
    title: 'General Shared Ward',
    pricePerDay: 1500,
    description: '3-bed shared room with 24x7 nursing & assisted meals.',
  },
  {
    title: 'Semi-Private Room (Twin Sharing)',
    pricePerDay: 2200,
    description: 'Twin sharing room with AC, private wardrobe & 1:4 nurse ratio.',
  },
  {
    title: 'Private Deluxe Room',
    pricePerDay: 3500,
    description: 'Dedicated private room, attached bath, TV & 1:2 caregiver ratio.',
  },
  {
    title: 'ICU Step-Down / High Dependency',
    pricePerDay: 5500,
    description: 'Continuous vitals monitoring, oxygen/BiPAP line & dedicated nurse.',
  },
]

export const stayDurations = [
  { days: 7, label: 'Short Stay' },
  { days: 15, label: 'Recovery' },
  { days: 30, label: 'Monthly Care' },
]

export const CENTRE_DEPOSIT = 5000

export const centreFormalities = [
  'Govt Photo ID (Aadhaar / Passport) of patient',
  'Hospital Discharge Summary & Doctor Prescription',
  'Digital Admission Pass & Check-In OTP',
  'Signed Care Agreement & Emergency Contact Consent',
]

export const deliverySlots = ['Today · 4 PM – 8 PM', 'Tomorrow · 9 AM – 1 PM', 'Tomorrow · 2 PM – 6 PM']

export const PLATFORM_FEE = 99
export const GST_RATE = 0.18

export interface BillLine {
  label: string
  amount: number
}

/** Home visits: service + ALLCURO quality & safety fee + 18% GST (nurse_quick_booking_screen.dart). */
export function visitBill(serviceLabel: string, base: number, discount = 0): BillLine[] {
  const fee = PLATFORM_FEE
  const gst = Math.floor((base - discount + fee) * GST_RATE)
  return [
    { label: serviceLabel, amount: base },
    ...(discount ? [{ label: 'Coupon discount', amount: -discount }] : []),
    { label: 'ALLCURO Quality & Safety Fee', amount: fee },
    { label: 'GST (18%)', amount: gst },
  ]
}

export const billTotal = (lines: BillLine[]) => lines.reduce((sum, l) => sum + l.amount, 0)

/**
 * Coupons. The app shows a success message for any code; the website only
 * accepts known ones so the discount on the bill is believable.
 */
export const coupons: Record<string, { label: string; off: (base: number) => number }> = {
  FIRSTCARE: { label: '20% off your first booking (up to ₹480)', off: (b) => Math.min(480, Math.round(b * 0.2)) },
  CARE100: { label: '₹100 off', off: (b) => Math.min(100, b) },
}

/** Link to the booking form, carrying whatever has been chosen so far. */
export function bookingPath(params: { service?: string; nurse?: string; duration?: string; slot?: string }) {
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => v && q.set(k, v))
  const s = q.toString()
  return `/book-nurse${s ? `?${s}` : ''}`
}
