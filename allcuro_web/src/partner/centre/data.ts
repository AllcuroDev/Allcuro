// Centre-side demo data — the partner app's mock data source
// (allcuro_partner/lib/features/centre/data/centre_service.dart, the seeded
// PartnerOnboardingState in features/auth/presentation/onboarding_view_model.dart
// and the self-contained demo lists in the listing / revenue / reviews /
// promotions screens). Mutable copies live in ./state.ts.

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

export interface Settlement {
  date: string
  bookingRef: string
  gross: number
  net: number
}

export interface Review {
  id: string
  familyName: string
  stars: number
  comment: string
  relativeDate: string
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

export const DEFAULT_CENTRE_NAME = 'Sanjeevani Elder Care Sanctuary'

// ---------------------------------------------------------------- seeds

export const SEED_REQUESTS: PlacementRequest[] = [
  {
    id: 'plc-1',
    careType: 'Post-op recovery care',
    familyContact: 'Family of Deepak Shetty',
    preference: 'Prefers ground floor, single room',
    duration: '2 weeks · Starts in 3 days',
  },
  {
    id: 'plc-2',
    careType: 'Long-term elderly care',
    familyContact: 'Family of Radha Krishnan',
    preference: 'Shared room okay, needs wheelchair access',
    duration: 'Ongoing · Starts next week',
  },
  {
    id: 'plc-3',
    careType: 'Rehab & physiotherapy',
    familyContact: 'Family of Anitha George',
    preference: 'Prefers a centre with in-house physio',
    duration: '4 weeks · Starts today',
  },
]

export const SEED_ADMITTED_THIS_MONTH = 7

export const SEED_ROOMS: Room[] = [
  {
    id: 'r-101',
    ward: 'Care Wing A',
    roomNumber: 'Room 101 · Semi-Private',
    rate: 2200,
    amenities: DEFAULT_ROOM_AMENITIES,
    beds: [
      { id: 'b-101-1', label: 'Bed 101-A', occupied: true },
      { id: 'b-101-2', label: 'Bed 101-B', occupied: false },
    ],
  },
  {
    id: 'r-102',
    ward: 'Care Wing A',
    roomNumber: 'Room 102 · Deluxe Single Suite',
    rate: 3500,
    amenities: [...DEFAULT_ROOM_AMENITIES, 'TV & Wi-Fi', 'Attendant Bed'],
    beds: [{ id: 'b-102-1', label: 'Bed 102-A', occupied: false }],
  },
  {
    id: 'r-icu-1',
    ward: 'ICU & High Dependency',
    roomNumber: 'ICU Unit 01',
    rate: 4800,
    amenities: ['AC', 'Oxygen Support', 'Cardiac Monitor', 'Hospital Electric Bed', 'Nurse Call Bell'],
    beds: [
      { id: 'b-icu-1', label: 'ICU Bed 1', occupied: true },
      { id: 'b-icu-2', label: 'ICU Bed 2', occupied: false },
    ],
  },
]

export const SEED_STAFF: StaffMember[] = [
  {
    id: 's-1',
    name: 'Rekha Menon',
    roleType: 'gnmNurse',
    qualification: 'GNM · 5 yrs exp',
    experienceYears: 5,
    ratio: '1:4',
    shiftRate: 1800,
    isCertified: true,
    certificateExpiring: false,
  },
  {
    id: 's-2',
    name: 'Joseph Thomas',
    roleType: 'bscNursing',
    qualification: 'B.Sc Nursing · 8 yrs exp',
    experienceYears: 8,
    ratio: '1:2',
    shiftRate: 2400,
    isCertified: true,
    certificateExpiring: false,
  },
  {
    id: 's-3',
    name: 'Farida Sheikh',
    roleType: 'careAttendant',
    qualification: 'Certified Attendant · 3 yrs exp',
    experienceYears: 3,
    ratio: '1:4',
    shiftRate: 1200,
    isCertified: true,
    certificateExpiring: true,
  },
]

export const SEED_EQUIPMENT: EquipmentItem[] = [
  {
    id: 'eq-1',
    title: 'Philips EverFlo 5L Oxygen Concentrator',
    category: 'respiratory',
    condition: 'brandNew',
    dailyRate: 250,
    monthlyRate: 4500,
    depositAmount: 5000,
    stockQuantity: 6,
    specifications: '0.5 to 5 LPM continuous oxygen, 93% ± 3% purity, quiet operation.',
    isAvailable: true,
  },
  {
    id: 'eq-2',
    title: 'Motorized 5-Function ICU Hospital Bed with Mattress',
    category: 'hospitalBeds',
    condition: 'brandNew',
    dailyRate: 350,
    monthlyRate: 6500,
    depositAmount: 8000,
    stockQuantity: 4,
    specifications: 'Remote-controlled backrest, leg elevation, Trendelenburg, and height adjust.',
    isAvailable: true,
  },
  {
    id: 'eq-3',
    title: 'ResMed AirSense 10 AutoSet BiPAP/CPAP Machine',
    category: 'respiratory',
    condition: 'refurbishedGradeA',
    dailyRate: 300,
    monthlyRate: 5500,
    depositAmount: 6000,
    stockQuantity: 3,
    specifications: 'Auto-adjusting pressure, integrated heated humidifier, cellular connectivity.',
    isAvailable: true,
  },
  {
    id: 'eq-4',
    title: 'Karma Champion Deluxe Folding Wheelchair',
    category: 'mobility',
    condition: 'brandNew',
    dailyRate: 100,
    monthlyRate: 1800,
    depositAmount: 2000,
    stockQuantity: 8,
    specifications: 'Lightweight aluminum frame, ergonomic armrests, puncture-proof wheels.',
    isAvailable: true,
  },
]

export const SEED_COMPLIANCE_DOCS: ComplianceDoc[] = [
  {
    id: 'cd-1',
    title: 'Clinical Establishment Act Licence (CEA)',
    docType: 'cea_license',
    fileName: 'karnataka_cea_reg_2026.pdf',
    expiry: 'Expires 14 Mar 2027',
    isUploaded: true,
    isVerified: true,
  },
  {
    id: 'cd-2',
    title: 'Fire Safety NOC Certificate',
    docType: 'fire_noc',
    fileName: 'fire_safety_clearance.pdf',
    expiry: 'Valid till 30 Nov 2026',
    isUploaded: true,
    isVerified: true,
  },
  {
    id: 'cd-3',
    title: 'Biomedical Waste Authorisation',
    docType: 'biowaste_noc',
    fileName: 'kspcb_biowaste_mou.pdf',
    expiry: 'Valid till 18 Jan 2027',
    isUploaded: true,
    isVerified: true,
  },
  {
    id: 'cd-4',
    title: 'Building & Ward Inspection Photos',
    docType: 'facility_photos',
    fileName: 'facility_photos_batch_6.zip',
    expiry: 'Uploaded 16 Aug 2026',
    isUploaded: true,
    isVerified: true,
  },
]

/** Revenue screen mock stats + "Recent settlements". */
export const REVENUE_STATS = {
  bookingsThisMonth: 12,
  gross: 184000,
  commission: 18400,
  pendingSettlement: 42000,
}

export const SETTLEMENTS: Settlement[] = [
  { date: '10 Aug', bookingRef: '#BK-1042', gross: 15000, net: 13500 },
  { date: '07 Aug', bookingRef: '#BK-1038', gross: 22000, net: 19800 },
  { date: '03 Aug', bookingRef: '#BK-1029', gross: 9600, net: 8640 },
  { date: '29 Jul', bookingRef: '#BK-1017', gross: 18400, net: 16560 },
  { date: '24 Jul', bookingRef: '#BK-1004', gross: 12000, net: 10800 },
]

export const REVIEW_SUMMARY = { rating: 4.6, count: 48 }

export const REVIEWS: Review[] = [
  {
    id: 'rv-1',
    familyName: 'Anita Rao',
    stars: 5,
    comment: 'The nursing staff were attentive and my father recovered well under their care. Highly recommend.',
    relativeDate: '2 days ago',
  },
  {
    id: 'rv-2',
    familyName: 'Vikram Shah',
    stars: 4,
    comment: 'Clean rooms and good food. Communication about the daily care plan could be a bit quicker.',
    relativeDate: '1 week ago',
  },
  {
    id: 'rv-3',
    familyName: 'Meena Iyer',
    stars: 5,
    comment: 'Staff-to-patient ratio really shows — someone was always around when we visited.',
    relativeDate: '2 weeks ago',
  },
  {
    id: 'rv-4',
    familyName: 'Suresh Nair',
    stars: 4,
    comment: "Good overall experience during my mother's stay. Would have liked more frequent updates.",
    relativeDate: '3 weeks ago',
  },
]

export const FEATURED_PRICE_LABEL = '₹499/week'

export const CAMPAIGNS: Campaign[] = [
  { id: 'first-booking', name: '10% off first booking', description: "Applies automatically to a family's first placement." },
  { id: 'free-assessment', name: 'Free assessment visit', description: 'Waive the initial in-home assessment fee.' },
  { id: 'referral', name: 'Referral bonus', description: 'Discount for families referred by an existing client.' },
]

/** Site-visit card on the "under review" home (centre_home_screen.dart). */
export const SITE_VISIT = {
  when: 'Tomorrow 11:30 AM',
  officer: 'Kiran Rao',
  audit: [
    { title: 'KYC & Regulatory Clearances Submitted', done: true, time: '16 Aug 2026' },
    { title: 'Police & CEA Registry Verification', done: true, time: 'Passed' },
    { title: 'Physical Site Audit & Inspection', done: false, time: 'Officer Assigned' },
    { title: 'Final Approval & Live Placement Activation', done: false, time: 'Pending Audit' },
  ],
}
