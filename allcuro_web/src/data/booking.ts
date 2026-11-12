// Booking choices and price rules, mirroring the app's booking screens:
//   nurse_quick_booking_screen.dart, service_detail_screen.dart (slot sheet),
//   centre_booking_screen.dart, checkout_repository.dart

/** One bookable line on the booking form: a catalog service or a partner's rate. */
export interface QuickService {
  id: string
  title: string
  duration: string
  price: number
  icon: string
  description: string
}

/** First slot is the instant one: the nurse leaves right away and can be tracked live. */
export const timeSlots = [
  '⚡ Instant (Arrives in 30–45 mins)',
  'Today · Afternoon (02:00 PM – 08:00 PM)',
  'Today · Night Shift (08:00 PM – 08:00 AM)',
  'Tomorrow · Morning (08:00 AM – 02:00 PM)',
]
export const INSTANT_SLOT = timeSlots[0]

export const slotSheetTimes = ['⚡ Within 45 mins (Immediate)', 'Today 2:30 PM', 'Today 6:00 PM', 'Tomorrow 9:00 AM']

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
export function bookingPath(params: { service?: string; nurse?: string; option?: string; slot?: string }) {
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => v && q.set(k, v))
  const s = q.toString()
  return `/book-nurse${s ? `?${s}` : ''}`
}

/** What a catalog service costs after the admin's discount (null when unpriced). */
export const servicePrice = (s: { priceFrom?: number; discountPercent?: number }) =>
  s.priceFrom == null ? null : Math.round(s.priceFrom * (1 - (s.discountPercent ?? 0) / 100))
