// Mock data for the nurse / clinician side of the partner portal — the web
// twin of allcuro_partner/lib/features/nurse/data (nurse_service.dart and its
// models) plus the static lists the app's tool screens keep inline
// (earnings, training, referral, availability options, KYC documents).

// ---------------------------------------------------------------- models

/** One incoming shift request as shown in a list (models/job_request_summary.dart). */
export interface JobRequestSummary {
  id: string
  serviceType: string
  patientName: string
  locality: string
  timing: string
  pay: string
}

/** Full request detail (models/job_request_detail.dart). */
export interface JobRequestDetail {
  id: string
  patientName: string
  patientInitials: string
  serviceSummary: string
  address: string
  timingDetail: string
  condition: string
  familyContactNote: string
  careRequirements: string[]
  payPerShift: string
  payEstimateLabel: string
  payEstimateValue: string
}

export type ShiftStatus = 'upcoming' | 'ongoing' | 'completed'

/** A confirmed booking on the schedule (models/shift.dart). */
export interface Shift {
  id: string
  patientName: string
  serviceType: string
  timing: string
  locality: string
  status: ShiftStatus
}

export type VisitStatus = 'assigned' | 'enRoute' | 'reached' | 'inProgress' | 'completed'

export interface VitalSignsLog {
  bloodPressure: string
  pulse: number
  bloodSugar: number
  temperature: number
  spO2: number
  /** epoch ms */
  loggedAt: number
}

export interface ClinicalChecklist {
  vitalsLogged: boolean
  ivAntibioticsAdministered: boolean
  surgicalWoundDressed: boolean
  toiletCareAssisted: boolean
  injectionsGiven: boolean
  ivDripMonitored: boolean
  exerciseMobilitySupported: boolean
}

export type ChecklistKey = keyof ClinicalChecklist

/** Rows of the clinical checklist, in the app's order. */
export const CHECKLIST_ITEMS: { key: ChecklistKey; title: string }[] = [
  { key: 'vitalsLogged', title: 'Vital signs logged (BP, Sugar, Pulse, Temp)' },
  { key: 'ivAntibioticsAdministered', title: 'Administering IV antibiotics (Cefuroxime)' },
  { key: 'surgicalWoundDressed', title: 'Dressing changes for surgical wounds' },
  { key: 'toiletCareAssisted', title: 'Toilet care assistance & personal hygiene' },
  { key: 'injectionsGiven', title: 'Injections given' },
  { key: 'ivDripMonitored', title: 'IV drip monitoring' },
  { key: 'exerciseMobilitySupported', title: 'Exercise & physiotherapy support' },
]

export const checklistDone = (c: ClinicalChecklist) => CHECKLIST_ITEMS.filter((i) => c[i.key]).length

/** The active home visit (models/nurse_visit_model.dart). Times are epoch ms. */
export interface NurseVisit {
  id: string
  bookingId: string
  serviceType: string
  patientName: string
  patientAge: number
  patientGender: string
  address: string
  locality: string
  patientPhone: string
  emergencyPhone: string
  medicalCondition: string
  instructions: string[]
  payAmount: string
  /** Rupee value of payAmount, credited to earnings on completion. */
  payValue: number
  timing: string
  expectedOtp: string
  status: VisitStatus
  isGpsVerified: boolean
  isSelfieVerified: boolean
  checkInTime: number | null
  checkOutTime: number | null
  vitalsLog: VitalSignsLog | null
  checklist: ClinicalChecklist
  /** Schedule entry this visit belongs to (marked completed with it). */
  shiftId: string
}

export interface CustomerFeedbackItem {
  id: string
  bookingId: string
  patientName: string
  serviceName: string
  rating: number
  comment: string
  daysAgo: number
}

/** models/nurse_performance_model.dart */
export interface NursePerformance {
  totalJobsCompleted: number
  monthlyJobsCompleted: number
  weeklyJobsCompleted: number
  attendanceRate: number
  onTimeArrivalRate: number
  averageRating: number
  totalRatingsCount: number
  ratingDistribution: Record<1 | 2 | 3 | 4 | 5, number>
  totalComplaints: number
  resolvedComplaints: number
  thisMonthEarnings: number
  thisWeekEarnings: number
  pendingPayout: number
  feedbacks: CustomerFeedbackItem[]
}

// ---------------------------------------------------------------- mock data

export const SEED_REQUESTS: JobRequestSummary[] = [
  {
    id: 'req-1',
    serviceType: 'Elderly care · Live-in',
    patientName: 'Lakshmi Rao',
    locality: 'HSR Layout, Bengaluru',
    timing: 'Starts in 2 days · 30 days',
    pay: '₹1,400 / shift',
  },
  {
    id: 'req-2',
    serviceType: 'ICU support · Night shift',
    patientName: 'Suresh Babu',
    locality: 'Koramangala, Bengaluru',
    timing: 'Starts tomorrow · 8:00 PM – 8:00 AM',
    pay: '₹1,800 / shift',
  },
]

export const REQUEST_DETAILS: Record<string, JobRequestDetail> = {
  'req-1': {
    id: 'req-1',
    patientName: 'Lakshmi Rao',
    patientInitials: 'LR',
    serviceSummary: 'Elderly care · Live-in · 30 days',
    address: 'HSR Layout, Sector 2, Bengaluru',
    timingDetail: 'Starts in 2 days · Full-day, live-in',
    condition: 'Post-stroke recovery, needs mobility support',
    familyContactNote: 'Available after you accept',
    careRequirements: ['Mobility assistance', 'Medication reminders', 'Vitals monitoring'],
    payPerShift: '₹1,400',
    payEstimateLabel: 'Estimated for 30 days',
    payEstimateValue: '₹42,000',
  },
  'req-2': {
    id: 'req-2',
    patientName: 'Suresh Babu',
    patientInitials: 'SB',
    serviceSummary: 'ICU support · Night shift · 7 nights',
    address: 'Koramangala 5th Block, Bengaluru',
    timingDetail: 'Starts tomorrow · 8:00 PM – 8:00 AM',
    condition: 'Post-surgical ICU monitoring, ventilator support',
    familyContactNote: 'Available after you accept',
    careRequirements: ['Vitals monitoring', 'Ventilator support', 'Medication administration'],
    payPerShift: '₹1,800',
    payEstimateLabel: 'Estimated for 7 nights',
    payEstimateValue: '₹12,600',
  },
}

export const SEED_SHIFTS: Shift[] = [
  {
    id: 'shift-1',
    patientName: 'Ramesh Iyer',
    serviceType: 'Post-op care & Vitals',
    timing: 'Today · 08:00 AM – 08:00 PM',
    locality: 'Indiranagar, 12th Main',
    status: 'ongoing',
  },
  {
    id: 'shift-2',
    patientName: 'Kavita Nair',
    serviceType: 'Elderly care',
    timing: 'Tomorrow · Full day',
    locality: 'Whitefield',
    status: 'upcoming',
  },
  {
    id: 'shift-3',
    patientName: 'Arjun Verma',
    serviceType: 'Physiotherapy support',
    timing: 'Fri, 14 Mar · 6:00 PM – 10:00 PM',
    locality: 'JP Nagar',
    status: 'upcoming',
  },
]

export const EMPTY_CHECKLIST: ClinicalChecklist = {
  vitalsLogged: false,
  ivAntibioticsAdministered: false,
  surgicalWoundDressed: false,
  toiletCareAssisted: false,
  injectionsGiven: false,
  ivDripMonitored: false,
  exerciseMobilitySupported: false,
}

export const SEED_VISIT: NurseVisit = {
  id: 'visit-101',
  bookingId: 'ALC-NUR-8921',
  serviceType: 'Post-Surgical Nursing & Vitals Check',
  patientName: 'Ramesh Iyer',
  patientAge: 68,
  patientGender: 'Male',
  address: 'Flat 402, Green Glen Palms, 12th Main, Indiranagar, Bengaluru',
  locality: 'Indiranagar, Bengaluru',
  patientPhone: '+91 98450 12345',
  emergencyPhone: '+91 80 4718 9000',
  medicalCondition: 'Post-Op Knee Replacement (Day 4) · Hypertension',
  instructions: [
    'Monitor surgical wound on right knee for any discharge',
    'Check BP and blood sugar before 10 AM dose',
    'Administer Cefuroxime IV 750mg slow infusion',
    'Assist with gentle quadriceps mobility exercises',
  ],
  payAmount: '₹1,600',
  payValue: 1600,
  timing: 'Today · 08:00 AM – 08:00 PM',
  expectedOtp: '4829',
  status: 'enRoute',
  isGpsVerified: false,
  isSelfieVerified: false,
  checkInTime: null,
  checkOutTime: null,
  vitalsLog: null,
  checklist: EMPTY_CHECKLIST,
  shiftId: 'shift-1',
}

/** The app also accepts this universal demo code at check-out. */
export const DEMO_VISIT_OTP = '1234'

export const SEED_PERFORMANCE: NursePerformance = {
  totalJobsCompleted: 142,
  monthlyJobsCompleted: 24,
  weeklyJobsCompleted: 6,
  attendanceRate: 98.6,
  onTimeArrivalRate: 96.8,
  averageRating: 4.92,
  totalRatingsCount: 118,
  ratingDistribution: { 5: 108, 4: 8, 3: 2, 2: 0, 1: 0 },
  totalComplaints: 0,
  resolvedComplaints: 0,
  thisMonthEarnings: 46800,
  thisWeekEarnings: 11200,
  pendingPayout: 3200,
  feedbacks: [
    {
      id: 'fb-1',
      bookingId: 'ALC-NUR-8830',
      patientName: 'Meena Pillai',
      serviceName: 'Post-Op Wound Care & IV Injections',
      rating: 5.0,
      comment:
        'Sister Priya was exceptionally gentle with my mother dressing changes. Monitored vitals accurately and explained everything clearly.',
      daysAgo: 2,
    },
    {
      id: 'fb-2',
      bookingId: 'ALC-NUR-8754',
      patientName: 'Karthik Somayaji',
      serviceName: 'Elderly ICU Step-down Care',
      rating: 5.0,
      comment: 'Punctual and very skilled in handling IV drip & catheter care. Made our recovery stress-free.',
      daysAgo: 5,
    },
    {
      id: 'fb-3',
      bookingId: 'ALC-NUR-8699',
      patientName: 'Sunita Agarwal',
      serviceName: 'Diabetic Foot Dressing & Vitals',
      rating: 4.8,
      comment: 'Professional, polite, and verified via OTP quickly. Logged sugar and blood pressure with precision.',
      daysAgo: 9,
    },
  ],
}

// ---------------------------------------------------------------- earnings

export interface ShiftPayout {
  date: string
  description: string
  amount: number
}

export const SEED_PAYOUTS: ShiftPayout[] = [
  { date: '10 Aug', description: 'Post-op care · Ramesh Iyer', amount: 1400 },
  { date: '08 Aug', description: 'Elderly care · Lakshmi Menon', amount: 1200 },
  { date: '05 Aug', description: 'Wound dressing · Anand Pillai', amount: 900 },
  { date: '03 Aug', description: 'Night care · Fathima Beevi', amount: 1600 },
  { date: '01 Aug', description: 'Post-op care · Suresh Kumar', amount: 1400 },
]

export const EARNINGS_THIS_MONTH = 34200
export const EARNINGS_INCENTIVES = 2000
export const STATEMENT = { month: 'July 2026', tds: 1200 }

// ---------------------------------------------------------------- training

export interface Course {
  title: string
  duration: string
  progress: number
}

export const SEED_COURSES: Course[] = [
  { title: 'Wound care essentials', duration: '45 min', progress: 0 },
  { title: 'Medication administration', duration: '30 min', progress: 40 },
  { title: 'Elderly mobility support', duration: '50 min', progress: 100 },
  { title: 'Infection control basics', duration: '25 min', progress: 60 },
  { title: 'Post-op recovery care', duration: '40 min', progress: 0 },
]

// ---------------------------------------------------------------- referral

export const REFERRAL_CODE = 'PRIYA250'
export const REFERRAL_BONUS = 500

export const REFERRALS: { name: string; status: string; tone: 'ok' | 'info' | 'warn' }[] = [
  { name: 'Anjali Nair', status: 'Bonus paid', tone: 'ok' },
  { name: 'Deepak Rao', status: 'Joined', tone: 'info' },
  { name: 'Meera Pillai', status: 'Pending', tone: 'warn' },
]

// ---------------------------------------------------------------- availability

export const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] as const

export const SHIFT_TIME_OPTIONS = [
  'Morning (08:00 AM – 02:00 PM)',
  'Evening (02:00 PM – 08:00 PM)',
  '12-Hr Day (08:00 AM – 08:00 PM)',
  'Night Shift (08:00 PM – 08:00 AM)',
  '24-Hr Live-in Care',
]

export const DAY_SLOTS = ['Morning', 'Evening', '12-Hr Day', 'Night Shift', '24-Hr'] as const

export const SEED_DAY_SLOTS = ['Mon-Morning', 'Tue-12-Hr Day', 'Wed-12-Hr Day', 'Thu-Night Shift', 'Fri-12-Hr Day', 'Sat-Morning']

/** Leave days blocked in the app's mock (ISO dates). */
export const SEED_BLOCKED_DATES = ['2026-08-30', '2026-08-31']

export const NURSE_SKILL_OPTIONS = [
  'Post-Surgical Care',
  'ICU & Tracheostomy Care',
  'IV Infusion & Injections',
  'Wound & Bed Sore Dressing',
  'Elderly Mobility & Vitals',
  'Catheter & Ryles Tube Care',
  'Palliative Care',
  'Mother & Newborn Care',
  'Dementia Care',
  'Diabetic Care',
]

export const CLINICIAN_SKILL_OPTIONS = [
  'General Physician Home Visit',
  'Post-Surgical Review',
  'Chronic Disease Management',
  'Geriatric Assessment',
  'Orthopaedic Physiotherapy',
  'Neuro Rehabilitation',
  'Cardio-Pulmonary Rehab',
  'Sports Injury Rehab',
  'Palliative Care',
]

export const SEED_SKILLS = [
  'Post-Surgical Care',
  'ICU & Tracheostomy Care',
  'IV Infusion & Injections',
  'Wound & Bed Sore Dressing',
  'Elderly Mobility & Vitals',
]

// ---------------------------------------------------------------- KYC documents

export interface ComplianceDoc {
  id: string
  title: string
  /** Title shown to doctors / physiotherapists instead. */
  clinicianTitle?: string
  docType: string
  fileName: string
  expiry: string
  isUploaded: boolean
  isVerified: boolean
}

/** Aadhaar and council registration are verified at sign-up, so they aren't uploads here. */
export const SEED_DOCS: ComplianceDoc[] = [
  {
    id: 'nd-hpr',
    title: 'Healthcare Professionals Registry (HPR / ABHA ID)',
    docType: 'hpr_registry',
    fileName: 'hpr_council_enrollment.pdf',
    expiry: 'ABHA-HPR: 91-4820-9921-1209 (Verified)',
    isUploaded: true,
    isVerified: true,
  },
  {
    id: 'nd-3',
    title: 'Nursing Degree / GNM Diploma Certificate',
    clinicianTitle: 'Degree Certificate (MBBS / BPT / MPT)',
    docType: 'degree_certificate',
    fileName: 'gnm_diploma_certificate.pdf',
    expiry: 'Verified',
    isUploaded: true,
    isVerified: true,
  },
  {
    id: 'nd-med',
    title: 'Medical Fitness & TB Screening Report',
    docType: 'medical_fitness',
    fileName: '',
    expiry: 'Annual health declaration for home care safety',
    isUploaded: false,
    isVerified: false,
  },
]

/** Documents that count towards the "Certificates & HPR Registration" setup step. */
export const CERTIFICATE_DOC_IDS = ['nd-hpr', 'nd-3']
export const MEDICAL_DOC_ID = 'nd-med'

// ---------------------------------------------------------------- SOS

export const SOS_PHONE = '+918047189000'
export const SOS_GPS_HOME = 'Live GPS: 12.9716° N, 77.5946° E (Bengaluru)'
export const SOS_GPS_VISIT = 'Indiranagar 12th Main (12.9716° N, 77.5946° E)'
