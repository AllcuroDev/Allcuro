// Centre-side models and reference lists — the web twin of
// allcuro_partner/lib/features/centre/data. Nothing here is seeded: there is no
// placements / revenue / reviews backend yet, and rooms, staff, equipment and
// documents are whatever the centre adds itself (see ./state.ts).

// ---------------------------------------------------------------- models

/** One incoming placement request (models/placement_request_summary.dart). */
export interface PlacementRequest {
  id: string
  careType: string
  familyContact: string
  preference: string
  duration: string
}

/** One bed inside a room (models/bed_slot.dart). */
export interface BedSlot {
  id: string
  label: string
  occupied: boolean
}

/** A room with its beds, grouped by ward (models/room.dart). */
export interface Room {
  id: string
  ward: string
  roomNumber: string
  /** Rupees per day. */
  rate: number
  amenities: string[]
  beds: BedSlot[]
}

export type StaffRoleType = 'gnmNurse' | 'anmNurse' | 'bscNursing' | 'criticalCareNurse' | 'careAttendant' | 'physiotherapist'

/** models/staff_member.dart */
export interface StaffMember {
  id: string
  name: string
  roleType: StaffRoleType
  qualification: string
  experienceYears: number
  /** Staff-to-patient ratio, e.g. '1:4'. */
  ratio: string
  shiftRate: number
  isCertified: boolean
  certificateExpiring: boolean
}

export type EquipmentCategory = 'respiratory' | 'mobility' | 'hospitalBeds' | 'icuMonitoring' | 'physiotherapy'
export type EquipmentCondition = 'brandNew' | 'refurbishedGradeA' | 'refurbishedGradeB'

/** models/equipment_item.dart */
export interface EquipmentItem {
  id: string
  title: string
  category: EquipmentCategory
  condition: EquipmentCondition
  dailyRate: number
  monthlyRate: number
  depositAmount: number
  stockQuantity: number
  specifications: string
  isAvailable: boolean
}

/** ComplianceDocItem (onboarding_view_model.dart). */
export interface ComplianceDoc {
  id: string
  title: string
  docType: string
  fileName: string
  expiry: string
  isUploaded: boolean
  isVerified: boolean
}

export interface Campaign {
  id: string
  name: string
  description: string
}

// ---------------------------------------------------------------- labels & options

export const STAFF_ROLE_LABEL: Record<StaffRoleType, string> = {
  gnmNurse: 'GNM Staff Nurse',
  anmNurse: 'ANM Duty Nurse',
  bscNursing: 'B.Sc Senior Nurse',
  criticalCareNurse: 'Critical Care Specialist',
  careAttendant: 'Trained Care Attendant',
  physiotherapist: 'Physiotherapy Specialist',
}

/** Role dropdown in the add-staff dialog, in the app's order. */
export const STAFF_ROLE_OPTIONS: { value: StaffRoleType; label: string }[] = [
  { value: 'gnmNurse', label: 'GNM Staff Nurse (General Care)' },
  { value: 'bscNursing', label: 'B.Sc Senior Nurse (Post-Op / Critical)' },
  { value: 'criticalCareNurse', label: 'Critical Care / ICU Specialist Nurse' },
  { value: 'anmNurse', label: 'ANM Duty Nurse (Vitals & Dressings)' },
  { value: 'careAttendant', label: 'Certified Care Attendant (Elderly Help)' },
  { value: 'physiotherapist', label: 'Physiotherapy & Rehab Specialist' },
]

/** Short qualification prefix the dialog writes into `qualification`. */
export const STAFF_QUALIFICATION: Record<StaffRoleType, string> = {
  gnmNurse: 'GNM',
  bscNursing: 'B.Sc Nursing',
  anmNurse: 'ANM',
  criticalCareNurse: 'Critical Care Specialist',
  physiotherapist: 'B.P.T Physio',
  careAttendant: 'Certified Attendant',
}

export const STAFF_RATIO_OPTIONS: { value: string; label: string }[] = [
  { value: '1:1', label: '1:1 (Dedicated)' },
  { value: '1:2', label: '1:2 (High Care)' },
  { value: '1:3', label: '1:3 (Standard)' },
  { value: '1:4', label: '1:4 (Assisted)' },
]

export const EQUIPMENT_CATEGORY_LABEL: Record<EquipmentCategory, string> = {
  respiratory: 'Respiratory Care',
  mobility: 'Mobility & Ortho',
  hospitalBeds: 'Hospital & ICU Beds',
  icuMonitoring: 'ICU & Cardiac Monitoring',
  physiotherapy: 'Physiotherapy & Rehab',
}

export const EQUIPMENT_CATEGORY_OPTIONS: { value: EquipmentCategory; label: string }[] = [
  { value: 'respiratory', label: 'Respiratory' },
  { value: 'hospitalBeds', label: 'Hospital Beds' },
  { value: 'mobility', label: 'Mobility / Wheelchairs' },
  { value: 'icuMonitoring', label: 'ICU Monitoring' },
  { value: 'physiotherapy', label: 'Physiotherapy' },
]

export const EQUIPMENT_CONDITION_LABEL: Record<EquipmentCondition, string> = {
  brandNew: 'Brand New',
  refurbishedGradeA: 'Refurbished - Grade A',
  refurbishedGradeB: 'Refurbished - Grade B',
}

export const ROOM_WARDS = [
  'Care Wing A',
  'Care Wing B',
  'Deluxe Private Suite',
  'ICU & High Dependency',
  'Rehabilitation & Physio Ward',
]

export const ROOM_BED_COUNTS = [1, 2, 3, 4, 6]

export const ROOM_AMENITIES = [
  'AC',
  'Attached Restroom',
  'Nurse Call Bell',
  'Oxygen Support',
  'Cardiac Monitor',
  'Attendant Bed',
  'Hospital Electric Bed',
  'TV & Wi-Fi',
]

export const DEFAULT_ROOM_AMENITIES = ['AC', 'Attached Restroom', 'Nurse Call Bell']

/** Statutory documents a centre uploads before the site visit (reference list; all start not uploaded). */
export const REQUIRED_COMPLIANCE_DOCS: ComplianceDoc[] = [
  {
    id: 'cd-1',
    title: 'Clinical Establishment Act Licence (CEA)',
    docType: 'cea_license',
    fileName: '',
    expiry: 'State CEA registration certificate',
    isUploaded: false,
    isVerified: false,
  },
  {
    id: 'cd-2',
    title: 'Fire Safety NOC Certificate',
    docType: 'fire_noc',
    fileName: '',
    expiry: 'Valid fire department NOC',
    isUploaded: false,
    isVerified: false,
  },
  {
    id: 'cd-3',
    title: 'Biomedical Waste Authorisation',
    docType: 'biowaste_noc',
    fileName: '',
    expiry: 'Pollution control board authorisation',
    isUploaded: false,
    isVerified: false,
  },
  {
    id: 'cd-4',
    title: 'Building & Ward Inspection Photos',
    docType: 'facility_photos',
    fileName: '',
    expiry: 'Photos of wards, rooms and common areas (ZIP or PDF)',
    isUploaded: false,
    isVerified: false,
  },
]

/** Promotion options a centre can opt into (reference content — no results are tracked yet). */
export const CAMPAIGNS: Campaign[] = [
  { id: 'first-booking', name: '10% off first booking', description: "Applies automatically to a family's first placement." },
  { id: 'free-assessment', name: 'Free assessment visit', description: 'Waive the initial in-home assessment fee.' },
  { id: 'referral', name: 'Referral bonus', description: 'Discount for families referred by an existing client.' },
]
