import { delay, persistedStore } from '../../lib/store'
import { setCentreStatus, type PartnerSession } from '../session'
import {
  SEED_ADMITTED_THIS_MONTH,
  SEED_COMPLIANCE_DOCS,
  SEED_EQUIPMENT,
  SEED_REQUESTS,
  SEED_ROOMS,
  SEED_STAFF,
  STAFF_QUALIFICATION,
  type ComplianceDoc,
  type EquipmentItem,
  type PlacementRequest,
  type Room,
  type StaffMember,
  type StaffRoleType,
} from './data'

// Mutable centre state — the web twin of the app's CentreService (requests)
// and PartnerOnboardingNotifier (rooms, staff, equipment, compliance docs),
// plus the listing / promotions / review-reply screens' local state, kept in
// localStorage so it survives reloads in demo mode.

const newId = (prefix: string) => `${prefix}-${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`

// ---------------------------------------------------------------- placement requests

export interface RequestsState {
  pending: PlacementRequest[]
  waitlisted: PlacementRequest[]
  admittedThisMonth: number
}

export const requestsStore = persistedStore<RequestsState>('partner.centre.requests', {
  pending: SEED_REQUESTS,
  waitlisted: [],
  admittedThisMonth: SEED_ADMITTED_THIS_MONTH,
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

/** Demo helper: bring the sample requests back once they've all been handled. */
export const restoreDemoRequests = () =>
  requestsStore.set((s) => ({
    ...s,
    pending: SEED_REQUESTS.filter((r) => !s.waitlisted.some((w) => w.id === r.id)),
  }))

// ---------------------------------------------------------------- rooms & beds

export const roomsStore = persistedStore<Room[]>('partner.centre.rooms', SEED_ROOMS)
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

export const staffStore = persistedStore<StaffMember[]>('partner.centre.staff', SEED_STAFF)
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
  experienceYears: parseInt(d.experienceYears, 10) || 3,
  ratio: d.ratio,
  shiftRate: parseFloat(d.shiftRate) || 1800,
})

export function addStaff(d: StaffDraft): StaffMember {
  const member: StaffMember = { id: newId('s'), ...staffFields(d), isCertified: true, certificateExpiring: false }
  staffStore.set((list) => [...list, member])
  return member
}

export const updateStaff = (id: string, d: StaffDraft) =>
  staffStore.set((list) => list.map((m) => (m.id === id ? { ...m, ...staffFields(d) } : m)))

export const removeStaff = (id: string) => staffStore.set((list) => list.filter((m) => m.id !== id))

/** Marks a staff member's expiring certificate as renewed. */
export const renewStaffCertificate = (id: string) =>
  staffStore.set((list) => list.map((m) => (m.id === id ? { ...m, isCertified: true, certificateExpiring: false } : m)))

// ---------------------------------------------------------------- equipment

export const equipmentStore = persistedStore<EquipmentItem[]>('partner.centre.equipment', SEED_EQUIPMENT)
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

export const complianceStore = persistedStore<ComplianceDoc[]>('partner.centre.compliance', SEED_COMPLIANCE_DOCS)
export const useCompliance = () => complianceStore.use()

/** markDocUploaded(isCentre: true) — a fresh upload waits for ALLCURO re-verification. */
export const markDocUploaded = (docId: string, fileName: string) =>
  complianceStore.set((docs) =>
    docs.map((d) => (d.id === docId ? { ...d, fileName, expiry: 'Uploaded just now', isUploaded: true, isVerified: false } : d)),
  )

// ---------------------------------------------------------------- listing

export interface ListingState {
  price: string
  ratio: string
  photoCount: number
  accepting: boolean
}

export const listingStore = persistedStore<ListingState>('partner.centre.listing', {
  price: '1200',
  ratio: '1:4',
  photoCount: 6,
  accepting: true,
})
export const useListing = () => listingStore.use()

// ---------------------------------------------------------------- promotions

export interface PromotionsState {
  featured: boolean
  campaigns: Record<string, boolean>
}

export const promotionsStore = persistedStore<PromotionsState>('partner.centre.promotions', { featured: false, campaigns: {} })
export const usePromotions = () => promotionsStore.use()

// ---------------------------------------------------------------- review replies

export const replyStore = persistedStore<Record<string, string>>('partner.centre.replies', {})
export const useReplies = () => replyStore.use()

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

/** submitCentreForReview — the app jumps straight to "site visit scheduled". */
export async function submitCentreForReview() {
  await delay(500)
  setCentreStatus('siteVisitScheduled')
}
