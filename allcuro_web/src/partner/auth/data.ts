import { delay } from '../../lib/store'

// Option lists, formatters and the mock identity lookups for the partner
// auth / onboarding pages — ported from the partner app:
//   identity/data/identity_service.dart, identity/presentation/identity_verification_steps.dart,
//   clinician/presentation/signup/clinician_signup_steps.dart,
//   centre/presentation/signup/centre_signup_steps.dart.

export type ClinicianProfession = 'Doctor' | 'Physiotherapist'

export const PROFESSIONS: ClinicianProfession[] = ['Doctor', 'Physiotherapist']

export const COUNCIL_OPTIONS: Record<ClinicianProfession, string[]> = {
  Doctor: [
    'National Medical Commission (IMR)',
    'Karnataka Medical Council',
    'Maharashtra Medical Council',
    'Delhi Medical Council',
    'Tamil Nadu Medical Council',
    'Telangana State Medical Council',
    'Other state medical council',
  ],
  Physiotherapist: [
    'State Allied & Healthcare Council',
    'State Physiotherapy Council',
    'Indian Association of Physiotherapists',
  ],
}

export const SPECIALISATION_OPTIONS: Record<ClinicianProfession, string[]> = {
  Doctor: ['General Physician', 'Geriatrics', 'Internal Medicine', 'Paediatrics', 'Palliative care', 'Wound care'],
  Physiotherapist: ['Orthopaedic', 'Neuro rehab', 'Cardio-pulmonary', 'Geriatric', 'Post-surgical rehab', 'Sports'],
}

export const REGISTRATION_LABELS: Record<ClinicianProfession, string> = {
  Doctor: 'NMC / State Medical Council reg. no.',
  Physiotherapist: 'State Physiotherapy Council / IAP reg. no.',
}

/** Nurse skills the app pre-selects at sign-up (edited later from Availability). */
export const NURSE_DEFAULT_SKILLS = ['ICU / Critical Care', 'Tracheostomy Care', 'Post-Op Dressing']

export const CENTRE_TYPE_OPTIONS = ['Elderly care', 'Rehab', 'Day-care', 'Physiotherapy', 'Palliative']
export const OWNERSHIP_TYPE_OPTIONS = ['Individual', 'Partnership', 'Trust', 'Company']

/** Demo defaults the centre wizard starts with (centre_signup_view_model.dart). */
export const CENTRE_DEFAULTS = {
  businessEmail: 'admin@sanjeevanicaredemo.in',
  centreName: 'Sanjeevani Elder Care Sanctuary',
  centreType: 'Elderly care',
  yearEstablished: '2019',
  ownershipType: 'Company',
  staffRatio: '1:4',
  sampleFoodMenu: 'Nutritious south & north Indian meals tailored for elders',
  staff: [
    { name: 'Sister Mary', qualification: 'B.Sc Nursing (ICU)', role: 'Head Nurse' },
    { name: 'Nurse John', qualification: 'GNM', role: 'Staff Nurse' },
  ],
  photoCount: 5,
  pricePerPackage: '2800',
  servicesIncluded: ['24/7 Nursing', 'Doctor-on-call', 'Meals Included'],
  roomTypes: ['Private AC Room', 'Semi-Private Room'],
}

export const ACCOUNT_TYPES = ['Current Account', 'Savings Account']

// ---------------------------------------------------------------- formatting

/** ISO date → "14/05/1996", like the app's _formatDate. */
export function formatDob(iso: string) {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return iso
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`
}

/** "123456789012" → "1234 5678 9012" (the app's _AadhaarFormatter). */
export const groupAadhaar = (digits: string) => digits.replace(/(\d{4})(?=\d)/g, '$1 ')

const normaliseName = (n: string) => n.trim().toLowerCase().replace(/\s+/g, ' ')

// ---------------------------------------------------------------- mock identity service

/** The only Aadhaar OTP the mock accepts — shown next to the OTP field. */
export const AADHAAR_DEMO_OTP = '123456'

export interface RegistryRecord {
  registeredName: string
  council: string
  qualification: string
  registeredSince: number
}

export interface AadhaarProfile {
  name: string
  dob: string // ISO date
  gender: string
  address: string
}

export async function verifyNuid(nuid: string): Promise<RegistryRecord> {
  await delay(900)
  if (!/^[A-Za-z0-9]{6,20}$/.test(nuid.trim())) {
    throw new Error('Enter the NUID exactly as shown on your NRTS registration.')
  }
  return { registeredName: 'Priya Sharma', council: 'Karnataka State Nursing Council', qualification: 'GNM', registeredSince: 2017 }
}

export async function verifyCouncilRegistration(opts: {
  isPhysiotherapist: boolean
  registrationNumber: string
  council: string
}): Promise<RegistryRecord> {
  await delay(900)
  if (!/^[A-Za-z0-9/-]{4,20}$/.test(opts.registrationNumber.trim())) {
    throw new Error('Enter a valid registration number (letters, digits, / or -).')
  }
  return {
    registeredName: 'Arjun Rao',
    council: opts.council,
    qualification: opts.isPhysiotherapist ? 'BPT' : 'MBBS',
    registeredSince: 2013,
  }
}

export async function sendAadhaarOtp(aadhaar: string) {
  await delay(700)
  // Aadhaar numbers are 12 digits and never start with 0 or 1.
  if (!/^[2-9]\d{11}$/.test(aadhaar)) throw new Error('Enter a valid 12-digit Aadhaar number.')
}

export async function verifyAadhaarOtp(opts: { otp: string; isClinician: boolean; registeredName: string }): Promise<AadhaarProfile> {
  await delay(800)
  if (opts.otp !== AADHAAR_DEMO_OTP) throw new Error('Incorrect OTP. Please try again.')
  const profile: AadhaarProfile = opts.isClinician
    ? { name: 'Arjun Rao', dob: '1988-11-02', gender: 'Male', address: '221, 27th Main, HSR Layout Sector 2, Bengaluru, Karnataka 560102' }
    : { name: 'Priya Sharma', dob: '1996-05-14', gender: 'Female', address: '12, 4th Cross, Indiranagar, Bengaluru, Karnataka 560038' }
  if (normaliseName(profile.name) !== normaliseName(opts.registeredName)) {
    throw new Error(
      `The name on your Aadhaar (${profile.name}) does not match your registration (${opts.registeredName}). Contact support to resolve this.`,
    )
  }
  return profile
}
