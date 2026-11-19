import { delay } from '../../lib/store'

// Option lists, formatters and the stand-in identity lookups for the partner
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

/** Qualification choices, since the registry lookup below doesn't return one yet. */
export const NURSE_QUALIFICATION_OPTIONS = ['GNM', 'ANM', 'B.Sc Nursing', 'Post Basic B.Sc Nursing', 'M.Sc Nursing']
export const CLINICIAN_QUALIFICATION_OPTIONS: Record<ClinicianProfession, string[]> = {
  Doctor: ['MBBS', 'MD', 'MS', 'DNB'],
  Physiotherapist: ['BPT', 'MPT'],
}

export const GENDER_OPTIONS = ['Female', 'Male', 'Other']

export const CENTRE_TYPE_OPTIONS = ['Elderly care', 'Rehab', 'Day-care', 'Physiotherapy', 'Palliative']
export const OWNERSHIP_TYPE_OPTIONS = ['Individual', 'Partnership', 'Trust', 'Company']

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

// ---------------------------------------------------------------- identity checks
//
// There is no council-registry or UIDAI e-KYC integration yet. These stand-ins
// validate the format of what the partner typed and echo it back: they never
// invent a name, date of birth or address. ALLCURO checks the details against
// the council register and the uploaded documents before approving a profile.

/** The Aadhaar OTP the stand-in accepts until real e-KYC is wired up — shown next to the OTP field. */
export const AADHAAR_DEMO_OTP = '123456'

export interface RegistryRecord {
  registeredName: string
  council: string
  qualification: string
}

/** What the Aadhaar step confirms. Date of birth, gender and address are entered by the partner. */
export interface AadhaarProfile {
  name: string
}

export async function verifyNuid(opts: { nuid: string; registeredName: string; qualification: string }): Promise<RegistryRecord> {
  await delay(600)
  if (!/^[A-Za-z0-9]{6,20}$/.test(opts.nuid.trim())) {
    throw new Error('Enter the NUID exactly as shown on your NRTS registration.')
  }
  if (!opts.registeredName.trim()) throw new Error('Enter your full name as registered.')
  return { registeredName: opts.registeredName.trim(), council: 'Indian Nursing Council (NRTS)', qualification: opts.qualification }
}

export async function verifyCouncilRegistration(opts: {
  registrationNumber: string
  council: string
  registeredName: string
  qualification: string
}): Promise<RegistryRecord> {
  await delay(600)
  if (!/^[A-Za-z0-9/-]{4,20}$/.test(opts.registrationNumber.trim())) {
    throw new Error('Enter a valid registration number (letters, digits, / or -).')
  }
  if (!opts.registeredName.trim()) throw new Error('Enter your full name as registered.')
  return { registeredName: opts.registeredName.trim(), council: opts.council, qualification: opts.qualification }
}

export async function sendAadhaarOtp(aadhaar: string) {
  await delay(700)
  // Aadhaar numbers are 12 digits and never start with 0 or 1.
  if (!/^[2-9]\d{11}$/.test(aadhaar)) throw new Error('Enter a valid 12-digit Aadhaar number.')
}

export async function verifyAadhaarOtp(opts: { otp: string; registeredName: string }): Promise<AadhaarProfile> {
  await delay(800)
  if (opts.otp !== AADHAAR_DEMO_OTP) throw new Error('Incorrect OTP. Please try again.')
  return { name: opts.registeredName }
}
