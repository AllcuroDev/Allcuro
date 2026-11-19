// Models and reference lists for the nurse / clinician side of the partner
// portal — the web twin of allcuro_partner/lib/features/nurse/data.
//
// There is no bookings / visits / earnings / reviews backend yet, so nothing
// here is seeded: requests, shifts, the active visit, payouts and reviews all
// start empty and the pages show empty states. Only genuine reference content
// lives here (checklist rows, training modules, option lists, document types).

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

export const EMPTY_CHECKLIST: ClinicalChecklist = {
  vitalsLogged: false,
  ivAntibioticsAdministered: false,
  surgicalWoundDressed: false,
  toiletCareAssisted: false,
  injectionsGiven: false,
  ivDripMonitored: false,
  exerciseMobilitySupported: false,
}

// ---------------------------------------------------------------- training

export interface Course {
  title: string
  duration: string
  progress: number
}

/** The training module list (reference content). Everyone starts at 0%. */
export const TRAINING_MODULES: Course[] = [
  { title: 'Wound care essentials', duration: '45 min', progress: 0 },
  { title: 'Medication administration', duration: '30 min', progress: 0 },
  { title: 'Elderly mobility support', duration: '50 min', progress: 0 },
  { title: 'Infection control basics', duration: '25 min', progress: 0 },
  { title: 'Post-op recovery care', duration: '40 min', progress: 0 },
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

/** Documents a practitioner uploads after sign-up. Aadhaar and council registration are checked at sign-up, so they aren't uploads here. */
export const REQUIRED_DOCS: ComplianceDoc[] = [
  {
    id: 'nd-hpr',
    title: 'Healthcare Professionals Registry (HPR / ABHA ID)',
    docType: 'hpr_registry',
    fileName: '',
    expiry: 'Your ABHA-HPR enrolment certificate',
    isUploaded: false,
    isVerified: false,
  },
  {
    id: 'nd-3',
    title: 'Nursing Degree / GNM Diploma Certificate',
    clinicianTitle: 'Degree Certificate (MBBS / BPT / MPT)',
    docType: 'degree_certificate',
    fileName: '',
    expiry: 'Your final degree or diploma certificate',
    isUploaded: false,
    isVerified: false,
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
/** Shown in the SOS dialog. We don't read the browser's location, so say so honestly. */
export const SOS_LOCATION_NOTE = 'Share your location with the ALLCURO desk once the call connects.'
