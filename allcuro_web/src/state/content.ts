import { categories, categoryById } from '../data/categories'
import { faqs } from '../data/faqs'
import { medicineCategories, medicines, type Medicine } from '../data/medicines'
import { centres, equipment, equipmentCategories, nurses, type Centre, type Equipment, type Nurse } from '../data/providers'
import { site } from '../data/site'
import type { Category, Service } from '../data/types'
import { supabase } from '../lib/supabase'
import { memoryStore } from '../lib/store'

// Everything the customer site shows comes from Supabase: categories, services,
// approved partners (nurses, doctors, physios, caregivers, centres) with the
// prices the admin set, equipment, medicines, FAQs and contact details. Nothing
// is bundled.
//
// The data modules (data/categories.ts, data/providers.ts, …) export live
// arrays that are refilled in place here, so pages keep importing them as
// before. <CustomerSite> calls useContentStatus(), and its re-render when the
// status changes redraws every page with the loaded rows.

export type ContentStatus = 'loading' | 'ready' | 'error'

const status = memoryStore<ContentStatus>('loading')
const servicesStore = memoryStore<Service[]>([])

export const useContentStatus = () => status.use()
export const contentReady = () => status.get() === 'ready'
export const servicesStoreRef = servicesStore

const refill = <T>(target: T[], rows: T[]) => {
  target.splice(0, target.length, ...rows)
}

// ---------------------------------------------------------------- row types

interface CategoryRow {
  id: string
  slug: string
  label: string
  blurb: string
  icon: string
  art: string
  ink: string
  wash: string
  href: string | null
  image_url: string | null
}

interface ServiceRow {
  id: string
  name: string
  category_id: string
  subcategory: string
  description: string
  includes: string
  not_included: string
  duration: string
  professional: string
  price: string
  price_from: number | null
  discount_percent: number | null
  notes: string
  badge: string
  icon: string
  image_url: string | null
  extra_category_ids: string[] | null
}

interface PartnerRow {
  id: string
  slug: string
  kind: Nurse['kind'] | 'centre'
  allcuro_code: string | null
  display_name: string
  photo_url: string | null
  headline: string
  bio: string
  city: string
  locality: string
  languages: string[]
  skills: string[]
  highlights: string[]
  qualification: string
  specialisations: string[]
  experience_years: number
  employment_type: string
  is_available: boolean
  centre_type: string
  year_established: number | null
  staff_ratio: string
  beds_available: number
  services_included: string[]
  room_types: string[]
  photos: string[]
  licence_no: string
  public_phone: string
  price_per_day: number | null
  price_per_month: number | null
  discount_percent: number
  rating: number | null
  review_count: number
}

interface OfferingRow {
  id: string
  partner_id: string
  service_id: string | null
  label: string
  unit: string
  price: number
  discount_percent: number
  final_price: number
}

interface EquipmentRow {
  id: string
  slug: string
  title: string
  category: string
  condition: string
  description: string
  features: string[] | null
  daily_rate: number
  monthly_rate: number
  deposit_amount: number
  discount_percent: number | null
  stock_quantity: number | null
  photo_url: string | null
  available_pincodes: string
  is_available: boolean
}

interface MedicineRow {
  id: string
  name: string
  pack: string
  category: string
  mrp: number
  price: number
  rx: boolean
  image_url: string | null
}

// ---------------------------------------------------------------- mapping

const off = (price: number, pct: number | null | undefined) => Math.round(price * (1 - (Number(pct) || 0) / 100))

const toCategory = (r: CategoryRow): Category => ({
  id: r.id as Category['id'],
  slug: r.slug,
  label: r.label,
  blurb: r.blurb,
  href: r.href ?? undefined,
  icon: r.icon,
  art: r.art,
  ink: r.ink,
  wash: r.wash,
  imageUrl: r.image_url ?? undefined,
})

const toService = (r: ServiceRow): Service => ({
  id: r.id,
  name: r.name,
  category: r.category_id,
  subcategory: r.subcategory,
  description: r.description,
  includes: r.includes,
  notIncluded: r.not_included,
  duration: r.duration,
  professional: r.professional,
  price: r.price,
  priceFrom: r.price_from ?? undefined,
  discountPercent: Number(r.discount_percent) || 0,
  notes: r.notes,
  badge: r.badge,
  icon: r.icon,
  imageUrl: r.image_url ?? undefined,
  alsoIn: r.extra_category_ids ?? [],
})

function toNurse(p: PartnerRow, offers: OfferingRow[]): Nurse {
  return {
    id: p.slug,
    partnerId: p.id,
    kind: p.kind as Nurse['kind'],
    name: p.display_name,
    photo: p.photo_url ?? '',
    allcuroId: p.allcuro_code ?? '',
    level: p.headline || p.qualification,
    experience: p.experience_years,
    city: [p.locality, p.city].filter(Boolean).join(', '),
    languages: p.languages,
    tags: [...p.skills, ...p.specialisations.filter((s) => !p.skills.includes(s))],
    rating: p.rating == null ? null : Number(p.rating),
    reviews: p.review_count,
    highlights: p.highlights,
    bio: p.bio,
    shifts: offers.map((o) => ({
      label: o.label,
      unit: o.unit,
      serviceId: o.service_id ?? undefined,
      mrp: Number(o.price),
      price: Number(o.final_price),
      available: p.is_available,
    })),
    serviceIds: offers.flatMap((o) => (o.service_id ? [o.service_id] : [])),
    employment: (p.employment_type || 'Full-time') as Nurse['employment'],
    available: p.is_available,
  }
}

function toCentre(p: PartnerRow): Centre {
  const day = p.price_per_day == null ? null : Number(p.price_per_day)
  const month = p.price_per_month == null ? null : Number(p.price_per_month)
  return {
    id: p.slug,
    partnerId: p.id,
    name: p.display_name,
    type: p.centre_type || p.headline,
    locality: p.locality,
    city: p.city,
    photo: p.photos[0] ?? p.photo_url ?? '',
    photos: p.photos,
    photoCount: p.photos.length,
    rating: p.rating == null ? null : Number(p.rating),
    reviews: p.review_count,
    since: p.year_established,
    licence: p.licence_no,
    staffRatio: p.staff_ratio,
    mrpPerDay: day,
    pricePerDay: day == null ? null : off(day, p.discount_percent),
    pricePerMonth: month == null ? null : off(month, p.discount_percent),
    discountPercent: Number(p.discount_percent) || 0,
    bedsLeft: p.beds_available,
    services: p.services_included,
    roomTypes: p.room_types,
    about: p.bio,
    phone: p.public_phone || site.phoneDisplay,
  }
}

const toEquipment = (r: EquipmentRow): Equipment => ({
  id: r.slug,
  name: r.title,
  category: r.category,
  photo: r.photo_url ?? '',
  description: r.description,
  features: r.features ?? [],
  mrpPerDay: Number(r.daily_rate),
  perDay: off(Number(r.daily_rate), r.discount_percent),
  perMonth: off(Number(r.monthly_rate), r.discount_percent),
  discountPercent: Number(r.discount_percent) || 0,
  deposit: Number(r.deposit_amount),
  condition: r.condition,
  availableIn: r.available_pincodes,
  inStock: r.is_available && (r.stock_quantity ?? 1) > 0,
})

const toMedicine = (r: MedicineRow): Medicine => ({
  id: r.id,
  name: r.name,
  pack: r.pack,
  mrp: Number(r.mrp),
  price: Number(r.price),
  rx: r.rx,
  category: r.category,
  imageUrl: r.image_url ?? undefined,
})

// ---------------------------------------------------------------- loading

async function load() {
  if (!supabase) {
    status.set('error')
    return
  }
  const db = supabase
  const [cats, svcs, partners, offers, eq, meds, faq, settings] = await Promise.all([
    db.from('service_categories').select('id, slug, label, blurb, icon, art, ink, wash, href, image_url').eq('is_active', true).order('sort_order'),
    db
      .from('services')
      .select(
        'id, name, category_id, subcategory, description, includes, not_included, duration, professional, price, price_from, discount_percent, notes, badge, icon, image_url, extra_category_ids',
      )
      .eq('is_active', true)
      .order('sort_order'),
    db.from('partners_public').select('*').order('rating', { ascending: false, nullsFirst: false }),
    db.from('partner_offerings_public').select('*').order('sort_order'),
    db.from('equipment').select('*').eq('is_active', true).order('sort_order'),
    db.from('medicines').select('id, name, pack, category, mrp, price, rx, image_url').eq('is_active', true).order('sort_order'),
    db.from('faqs').select('question, answer').eq('is_active', true).order('sort_order'),
    db.from('site_settings').select('key, value'),
  ])

  const failed = [cats, svcs, partners, offers, eq, meds, faq, settings].find((r) => r.error)
  if (failed?.error) console.warn('Content: some data failed to load —', failed.error.message)

  // Keep the built-in categories unless the database actually returned some.
  const catRows = ((cats.data ?? []) as CategoryRow[]).map(toCategory)
  if (catRows.length) {
    refill(categories, catRows)
    for (const k of Object.keys(categoryById)) delete categoryById[k]
    for (const c of catRows) categoryById[c.id] = c
  }

  servicesStore.set(((svcs.data ?? []) as ServiceRow[]).map(toService))

  const offersBy = new Map<string, OfferingRow[]>()
  for (const o of (offers.data ?? []) as OfferingRow[]) {
    offersBy.set(o.partner_id, [...(offersBy.get(o.partner_id) ?? []), o])
  }
  const partnerRows = (partners.data ?? []) as PartnerRow[]
  refill(
    nurses,
    partnerRows.filter((p) => p.kind !== 'centre').map((p) => toNurse(p, offersBy.get(p.id) ?? [])),
  )
  refill(centres, partnerRows.filter((p) => p.kind === 'centre').map(toCentre))

  const eqRows = ((eq.data ?? []) as EquipmentRow[]).map(toEquipment)
  refill(equipment, eqRows)
  refill(equipmentCategories, [...new Set(eqRows.map((e) => e.category))])

  const medRows = ((meds.data ?? []) as MedicineRow[]).map(toMedicine)
  refill(medicines, medRows)
  refill(medicineCategories, [...new Set(medRows.map((m) => m.category).filter(Boolean))])

  refill(
    faqs,
    ((faq.data ?? []) as { question: string; answer: string }[]).map((f) => ({ q: f.question, a: f.answer })),
  )

  const settingsBy = Object.fromEntries(
    ((settings.data ?? []) as { key: string; value: Record<string, string> }[]).map((s) => [s.key, s.value]),
  )
  applySettings(settingsBy.contact, settingsBy.home)

  status.set(cats.error && svcs.error ? 'error' : 'ready')
}

function applySettings(contact?: Record<string, string>, home?: Record<string, string>) {
  if (contact) {
    if (contact.phoneDisplay) site.phoneDisplay = contact.phoneDisplay
    if (contact.phone) site.phoneHref = `tel:${contact.phone.replace(/[^\d+]/g, '')}`
    if (contact.whatsapp) site.whatsappHref = `https://wa.me/${contact.whatsapp.replace(/\D/g, '')}`
    if (contact.email) site.email = contact.email
    if (contact.cities) site.cities = String(contact.cities).split(',').map((c) => c.trim()).filter(Boolean)
  }
  if (home) {
    if (home.headline) site.heroHeadline = home.headline
    if (home.highlight != null) site.heroHighlight = home.highlight
    if (home.tilesTitle) site.tilesTitle = home.tilesTitle
  }
}

void load()
