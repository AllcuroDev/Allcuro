// Nurses, doctors, physiotherapists, caregivers, care centres and rentable
// equipment. Only partners an admin has approved appear here: state/content.ts
// fills these live arrays from public.partners_public,
// public.partner_offerings_public (admin-set prices) and public.equipment.

export interface ShiftOption {
  label: string
  /** 'per visit', 'per shift', 'per day', 'per month' */
  unit: string
  serviceId?: string
  /** Price before discount. */
  mrp: number
  /** Price the customer pays, after the admin's discount. */
  price: number
  available: boolean
}

export type PartnerKind = 'nurse' | 'doctor' | 'physiotherapist' | 'caregiver'

export interface Nurse {
  /** URL slug. */
  id: string
  /** public.partners id. */
  partnerId: string
  kind: PartnerKind
  name: string
  /** Empty until the partner uploads a photo: show initials instead. */
  photo: string
  allcuroId: string
  level: string
  experience: number
  city: string
  languages: string[]
  tags: string[]
  /** null until the first review. */
  rating: number | null
  reviews: number
  highlights: string[]
  bio: string
  shifts: ShiftOption[]
  /** Catalog services this partner offers. */
  serviceIds: string[]
  employment: 'Full-time' | 'Part-time' | 'Live-in'
  available: boolean
}

export interface Centre {
  id: string
  partnerId: string
  name: string
  type: string
  locality: string
  city: string
  photo: string
  photos: string[]
  photoCount: number
  rating: number | null
  reviews: number
  since: number | null
  licence: string
  staffRatio: string
  /** Daily price before discount; null until the admin sets prices. */
  mrpPerDay: number | null
  pricePerDay: number | null
  pricePerMonth: number | null
  discountPercent: number
  bedsLeft: number
  services: string[]
  roomTypes: string[]
  about: string
  phone: string
}

export interface Equipment {
  id: string
  name: string
  category: string
  photo: string
  description: string
  features: string[]
  /** Daily rate before discount. */
  mrpPerDay: number
  perDay: number
  perMonth: number
  discountPercent: number
  deposit: number
  condition: string
  availableIn: string
  inStock: boolean
}

export const nurses: Nurse[] = []

/** Filters on the nurses list, matched against kind, `level` and `tags` (as in nurses_list_screen.dart). */
export const nurseFilters: { label: string; match: string[] }[] = [
  { label: 'All', match: [] },
  { label: 'Nurses', match: ['kind:nurse'] },
  { label: 'Doctors', match: ['kind:doctor'] },
  { label: 'Physiotherapists', match: ['kind:physiotherapist'] },
  { label: 'Caregivers', match: ['kind:caregiver'] },
  { label: 'Elderly Care', match: ['Elderly', 'Bed Bath', 'Mobility', 'Attendant'] },
  { label: 'Post-Op Recovery', match: ['Post-Op', 'Wound', 'Injections'] },
  { label: 'ICU / Critical Care', match: ['Critical', 'ICU', 'Ventilator', 'Tracheostomy'] },
  { label: 'Palliative', match: ['Palliative'] },
  { label: 'Pediatric', match: ['Mother & Baby', 'Midwife'] },
]

export const centres: Centre[] = []

export const equipment: Equipment[] = []

/** Categories present in the loaded equipment catalog. */
export const equipmentCategories: string[] = []

/** "From" price for a partner's card: the lowest price the admin has set. null until priced. */
export const lowestPrice = (n: Pick<Nurse, 'shifts'>) =>
  n.shifts.length ? Math.min(...n.shifts.map((s) => s.price)) : null

/** Customer-facing title for a partner kind. */
export const kindLabel: Record<PartnerKind, string> = {
  nurse: 'Nurse',
  doctor: 'Doctor',
  physiotherapist: 'Physiotherapist',
  caregiver: 'Caregiver',
}

export const nurseById = (id: string | null | undefined) => nurses.find((n) => n.id === id)
export const centreById = (id: string | null | undefined) => centres.find((c) => c.id === id)
export const equipmentById = (id: string | null | undefined) => equipment.find((e) => e.id === id)
