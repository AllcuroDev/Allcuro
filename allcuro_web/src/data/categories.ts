import type { Category, Service } from './types'

// The home-care categories. This built-in list always shows (hero tiles,
// footer, service pages); when public.service_categories loads, state/content.ts
// replaces it in place with the admin's version (labels, order, logos).
export const categories: Category[] = [
  {
    id: 'Nursing Care',
    slug: 'nursing',
    label: 'Nursing Services',
    blurb: 'Catheter, IV, injections, wound care & vital monitoring',
    icon: 'nursing',
    art: 'nursing',
    ink: '#26593B',
    wash: '#E7F4EB',
  },
  {
    id: 'Mother & Baby Care',
    slug: 'mother-baby',
    label: 'Mother & Baby',
    blurb: 'Postnatal recovery, lactation guidance & newborn care',
    icon: 'mother_baby',
    art: 'mother_baby',
    ink: '#BE185D',
    wash: '#FDEEF4',
  },
  {
    id: 'Elder Care',
    slug: 'elder-care',
    label: 'Elder Care',
    blurb: 'Assisted bathing, mobility, daily companionship & support',
    icon: 'elder_care',
    art: 'elder_care',
    ink: '#B45309',
    wash: '#FEF3E2',
  },
  {
    id: 'Physiotherapy',
    slug: 'physiotherapy',
    label: 'Physiotherapy',
    blurb: 'Mobility rehab, stroke recovery & post-op therapy',
    icon: 'physio',
    art: 'physio',
    ink: '#1D4ED8',
    wash: '#EAF0FE',
  },
  {
    id: 'Doctor Care',
    slug: 'doctor-care',
    label: 'Doctor Visit',
    blurb: 'Doctor & geriatric physician consultations at home',
    icon: 'doctor',
    art: 'doctor',
    ink: '#6D28D9',
    wash: '#F2EDFE',
  },
  {
    id: 'Care Centres',
    slug: 'care-centres',
    label: 'Care Centres',
    blurb: 'Verified assisted living, hospice & recovery facilities',
    href: '/centres',
    icon: 'care_centre',
    art: 'care_centre',
    ink: '#0369A1',
    wash: '#E6F3FB',
  },
  {
    id: 'Caregivers',
    slug: 'caregiver',
    label: 'Caregivers',
    blurb: 'Compassionate bedside care, feeding & daily mobility',
    icon: 'caregiver',
    art: 'caregiver',
    ink: '#C2410C',
    wash: '#FFEFE6',
  },
  {
    id: 'Hospital Companion',
    slug: 'hospital-companion',
    label: 'Hospital Companion',
    blurb: 'Non-clinical support during a hospital visit',
    icon: 'companionship',
    // No dedicated artwork yet: the caregiver illustration is the closest match.
    art: 'caregiver',
    ink: '#0F766E',
    wash: '#E3F5F2',
  },
]

export const categoryById: Record<string, Category> = Object.fromEntries(categories.map((c) => [c.id, c]))

/** Slug of the page that lists every service across all categories. */
export const ALL_SLUG = 'all'

export const categoryPath = (slug: string) => `/services/${slug}`

/** Where a category tile links: its own page (Care Centres → /centres) or its services list. */
export const categoryHref = (c: Pick<Category, 'slug' | 'href'>) => c.href ?? categoryPath(c.slug)

/** A service shows under its own category and any it is also listed in. */
export const inCategory = (s: Service, categoryId: string) =>
  s.category === categoryId || (s.alsoIn?.includes(categoryId) ?? false)

/** Hospital Companion services are non-clinical: no nurse list, a companion is assigned by the care desk. */
export const COMPANION_CATEGORY = 'Hospital Companion'
export const isCompanionService = (s: Pick<Service, 'category'>) => s.category === COMPANION_CATEGORY
