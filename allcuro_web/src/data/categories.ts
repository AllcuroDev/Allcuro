import type { Category, Service } from './types'

// Labels, icons and tones follow the home-screen grid and `CareTone`
// in allcuro/lib/core/ui/care_icon.dart. Slugs match the app's
// `/category-services/:slug` routes.
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
]

export const categoryById = Object.fromEntries(categories.map((c) => [c.id, c])) as Record<
  string,
  Category
>

/** Slug of the page that lists every service across all categories. */
export const ALL_SLUG = 'all'

export const categoryPath = (slug: string) => `/services/${slug}`

/** Where a category tile links: its own page (Care Centres → /centres) or its services list. */
export const categoryHref = (c: Pick<Category, 'slug' | 'href'>) => c.href ?? categoryPath(c.slug)

/** A service shows under its own category and any it is also listed in. */
export const inCategory = (s: Service, categoryId: string) =>
  s.category === categoryId || (s.alsoIn?.includes(categoryId) ?? false)
