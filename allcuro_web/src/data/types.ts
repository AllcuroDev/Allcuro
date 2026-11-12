export type CategoryId =
  | 'Nursing Care'
  | 'Elder Care'
  | 'Mother & Baby Care'
  | 'Physiotherapy'
  | 'Doctor Care'
  | 'Care Centres'
  | 'Caregivers'
  | 'Hospital Companion'

export interface Service {
  id: string
  name: string
  category: CategoryId | string
  subcategory: string
  description: string
  includes: string
  notIncluded: string
  duration: string
  professional: string
  price: string
  /** Lowest numeric price (₹), before any discount. */
  priceFrom?: number
  /** Admin-set discount, 0–100. */
  discountPercent?: number
  notes: string
  badge: string
  icon: string
  /** Other categories this service is also listed under, e.g. ['Caregivers']. */
  alsoIn?: string[]
  /** Supabase Storage artwork uploaded from the admin; overrides `icon` when set. */
  imageUrl?: string
}

export interface Category {
  id: CategoryId
  /** URL segment: /services/:slug */
  slug: string
  label: string
  blurb: string
  /** Page this category opens instead of its services list, e.g. '/centres'. */
  href?: string
  icon: string
  /** Illustration key shared with the app (its logo itself lives in Supabase Storage). */
  art: string
  /** Mirrors `CareTone` in the app: deep glyph colour + soft tile wash. */
  ink: string
  wash: string
  /** Supabase Storage artwork uploaded from the admin. */
  imageUrl?: string
}
