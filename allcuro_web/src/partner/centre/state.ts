import { delay, persistedStore, type Store } from '../../lib/store'
import { partnerSession, saveSignup, setCentreStatus, uploadedDocs, usePartnerSession, type PartnerSession } from '../session'
import {
  REQUIRED_COMPLIANCE_DOCS,
  STAFF_QUALIFICATION,
  type ComplianceDoc,
  type EquipmentItem,
  type PlacementRequest,
  type Room,
  type StaffMember,
  type StaffRoleType,
} from './data'

// Centre state — the web twin of the app's CentreService (requests) and
// PartnerOnboardingNotifier (rooms, staff, equipment, compliance docs).
//
// Nothing is seeded. Rooms, staff and equipment are what the centre adds; they
// live in the partner row's details (via the sign-up bag), and the bed totals
// go to partners.total_beds / beds_available. There is no placements backend
// yet, so requests start empty.

const newId = (prefix: string) => `${prefix}-${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`

// Caches from the old demo build held seeded families, rooms and staff.
if (typeof localStorage !== 'undefined') {
  for (const key of ['requests', 'rooms', 'staff', 'equipment', 'compliance', 'listing', 'promotions', 'replies']) {
    try {
      localStorage.removeItem(`allcuro.partner.centre.${key}`)
    } catch {
      // Storage blocked: nothing cached to clear.
    }
  }
}

const NONE: never[] = []
const listIn = <T>(signup: Record<string, unknown>, key: string): T[] => {
  const v = signup[key]
  return Array.isArray(v) ? (v as T[]) : NONE
}

/** A list kept in the sign-up bag (so it reaches public.partners.details). */
function signupList<T>(key: string): Store<T[]> {
  const get = () => listIn<T>(partnerSession.get().signup, key)
  return {
    get,
    set: (next) => saveSignup({ [key]: typeof next === 'function' ? next(get()) : next }),
    use: () => listIn<T>(partnerSession.use().signup, key),
  }
}

// ---------------------------------------------------------------- placement requests

export interface RequestsState {
  pending: PlacementRequest[]
  waitlisted: PlacementRequest[]
  admittedThisMonth: number
}

export const requestsStore = persistedStore<RequestsState>('partner.centre.v2.requests', {
  pending: [],
  waitlisted: [],
  admittedThisMonth: 0,
})
export const useRequests = () => requestsStore.use()

const withoutRequest = (s: RequestsState, id: string) => ({
  ...s,
  pending: s.pending.filter((r) => r.id !== id),
  waitlisted: s.waitlisted.filter((r) => r.id !== id),
})

export async function acceptRequest(id: string) {
  await delay(300)
  requestsStore.set((s) => ({ ...withoutRequest(s, id), admittedThisMonth: s.admittedThisMonth + 1 }))
}

export async function declineRequest(id: string) {
  await delay(300)
  requestsStore.set((s) => withoutRequest(s, id))
}

export async function waitlistRequest(id: string) {
  await delay(300)
  requestsStore.set((s) => {
    const req = s.pending.find((r) => r.id === id)
    if (!req) return s
    return { ...s, pending: s.pending.filter((r) => r.id !== id), waitlisted: [...s.waitlisted, req] }
  })
}

// ---------------------------------------------------------------- rooms & beds

export const roomsStore = signupList<Room>('rooms')
export const useRooms = () => roomsStore.use()

export interface RoomDraft {
  ward: string
  title: string
  bedCount: number
  rate: number
  amenities: string[]
}

export function addRoom(d: RoomDraft): Room {
  const id = newId('r')
  const title = d.title.trim()
  const room: Room = {
    id,
    ward: d.ward,
    roomNumber: `${title} · ${d.ward.split(' ')[0]}`,
    rate: d.rate,
    amenities: d.amenities,
    beds: Array.from({ length: d.bedCount }, (_, i) => ({
      id: `b-${id}-${i + 1}`,
      label: `Bed ${title}-${String.fromCharCode(65 + i)}`,
      occupied: false,
    })),
  }
  roomsStore.set((rooms) => [...rooms, room])
  return room
}

/** Edit keeps existing beds (and their occupancy); extra beds are added or trailing ones removed. */
export function updateRoom(id: string, d: RoomDraft) {
  const title = d.title.trim()
  roomsStore.set((rooms) =>
    rooms.map((r) => {
      if (r.id !== id) return r
      const beds = r.beds.slice(0, d.bedCount)
      for (let i = beds.length; i < d.bedCount; i++) {
        beds.push({ id: `b-${id}-${Date.now().toString(36)}-${i + 1}`, label: `Bed ${title}-${String.fromCharCode(65 + i)}`, occupied: false })
      }
      return { ...r, ward: d.ward, roomNumber: title, rate: d.rate, amenities: d.amenities, beds }
    }),
  )
}

export const removeRoom = (id: string) => roomsStore.set((rooms) => rooms.filter((r) => r.id !== id))

export const toggleBed = (roomId: string, bedId: string) =>
  roomsStore.set((rooms) =>
    rooms.map((r) =>
      r.id !== roomId ? r : { ...r, beds: r.beds.map((b) => (b.id === bedId ? { ...b, occupied: !b.occupied } : b)) },
    ),
  )

export function bedCounts(rooms: Room[]) {
  const total = rooms.reduce((n, r) => n + r.beds.length, 0)
  const occupied = rooms.reduce((n, r) => n + r.beds.filter((b) => b.occupied).length, 0)
  return { total, occupied, vacant: total - occupied, occupancy: total === 0 ? 0 : occupied / total }
}

export function groupByWard(rooms: Room[]): [string, Room[]][] {
  const map = new Map<string, Room[]>()
  for (const r of rooms) map.set(r.ward, [...(map.get(r.ward) ?? []), r])
  return [...map.entries()]
}

// ---------------------------------------------------------------- staff

export const staffStore = signupList<StaffMember>('staff')
export const useStaff = () => staffStore.use()

export interface StaffDraft {
  name: string
  roleType: StaffRoleType
  experienceYears: string
  ratio: string
  shiftRate: string
}

const staffFields = (d: StaffDraft) => ({
  name: d.name.trim(),
  roleType: d.roleType,
  qualification: `${STAFF_QUALIFICATION[d.roleType]} · ${d.experienceYears.trim()} yrs exp`,
  experienceYears: parseInt(d.experienceYears, 10) || 0,
  ratio: d.ratio,
  shiftRate: parseFloat(d.shiftRate) || 0,
})

export function addStaff(d: StaffDraft): StaffMember {
  const member: StaffMember = { id: newId('s'), ...staffFields(d), isCertified: false, certificateExpiring: false }
  staffStore.set((list) => [...list, member])
  return member
}

export const updateStaff = (id: string, d: StaffDraft) =>
  staffStore.set((list) => list.map((m) => (m.id === id ? { ...m, ...staffFields(d) } : m)))

export const removeStaff = (id: string) => staffStore.set((list) => list.filter((m) => m.id !== id))

// ---------------------------------------------------------------- equipment

export const equipmentStore = signupList<EquipmentItem>('equipment')
export const useEquipment = () => equipmentStore.use()

export type EquipmentDraft = Omit<EquipmentItem, 'id' | 'isAvailable'>

export function addEquipment(d: EquipmentDraft): EquipmentItem {
  const item: EquipmentItem = { id: newId('eq'), ...d, isAvailable: true }
  equipmentStore.set((list) => [...list, item])
  return item
}

export const updateEquipment = (id: string, d: EquipmentDraft) =>
  equipmentStore.set((list) => list.map((e) => (e.id === id ? { ...e, ...d } : e)))

export const removeEquipment = (id: string) => equipmentStore.set((list) => list.filter((e) => e.id !== id))

export const toggleEquipmentAvailable = (id: string) =>
  equipmentStore.set((list) => list.map((e) => (e.id === id ? { ...e, isAvailable: !e.isAvailable } : e)))

// ---------------------------------------------------------------- compliance

/** The required documents, marked uploaded from what the centre actually uploaded (partners.details.documents). */
export function centreDocs(s: PartnerSession): ComplianceDoc[] {
  const uploaded = uploadedDocs(s)
  return REQUIRED_COMPLIANCE_DOCS.map((d) => {
    const u = uploaded[d.id]
    if (!u) return d
    const when = new Date(u.uploadedAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
    return { ...d, fileName: u.fileName, expiry: `Uploaded ${when}`, isUploaded: true, isVerified: false }
  })
}

export const useCompliance = () => centreDocs(usePartnerSession())

// ---------------------------------------------------------------- listing

/** The centre's own listing preferences, saved on the partner row. The listed price itself is set by ALLCURO. */
export interface ListingState {
  /** Suggested ₹/day; ALLCURO sets the final listed price. */
  price: string
  ratio: string
  accepting: boolean
}

export function listingFrom(s: PartnerSession): ListingState {
  const g = s.signup
  return {
    price: typeof g.suggestedPricePerDay === 'string' ? g.suggestedPricePerDay : '',
    ratio: typeof g.staffRatio === 'string' ? g.staffRatio : '',
    accepting: g.acceptingPlacements !== false,
  }
}

export const saveListing = (l: ListingState) => saveSignup({ suggestedPricePerDay: l.price, staffRatio: l.ratio, acceptingPlacements: l.accepting })

// ---------------------------------------------------------------- promotions

export interface PromotionsState {
  featured: boolean
  campaigns: Record<string, boolean>
}

export const promotionsStore = persistedStore<PromotionsState>('partner.centre.v2.promotions', { featured: false, campaigns: {} })
export const usePromotions = () => promotionsStore.use()

// ---------------------------------------------------------------- setup hub

/** PartnerOnboardingState's centre getters, over the web stores + session. */
export function setupProgress(s: PartnerSession, rooms: Room[], staff: StaffMember[], equipment: EquipmentItem[], docs: ComplianceDoc[]) {
  const entityDone = true // finished at the initial sign-up
  const docsDone = docs.filter((d) => d.isUploaded).length >= 3
  const bankDone = !!s.bank && !!s.bank.account.trim() && !!s.bank.ifsc.trim() && !!s.bank.holder.trim()
  const roomsDone = rooms.length > 0
  const staffDone = staff.length > 0
  const equipmentDone = equipment.length > 0
  const completed = [entityDone, docsDone, bankDone, roomsDone, staffDone, equipmentDone].filter(Boolean).length
  return {
    entityDone,
    docsDone,
    bankDone,
    roomsDone,
    staffDone,
    equipmentDone,
    completed,
    percentage: completed / 6,
    canSubmit: entityDone && docsDone && bankDone && roomsDone,
  }
}

/** submitCentreForReview — goes to the admin's queue; the admin schedules the site visit and approves. */
export async function submitCentreForReview() {
  await setCentreStatus('pendingReview')
}
