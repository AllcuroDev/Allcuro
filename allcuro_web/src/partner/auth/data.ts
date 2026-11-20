import { functionsUrl, supabaseAnonKey } from '../../lib/supabase'

// Option lists, formatters and the registry / Aadhaar checks for the partner
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
// Registration checks go through the `nuid` and `doctor` Supabase Edge
// Functions (Indian Nursing Council NRTS and NMC Indian Medical Register) —
// see partner_verification_apis/API_USAGE.md. Aadhaar KYC is the number plus a
// photo of the card, reviewed by ALLCURO; there is no UIDAI e-KYC.
//
// Browser calls only work once this site's origin is in the functions'
// ALLOWED_ORIGINS secret.

/** What the register returned, in display order. Stored in partners.identity.registry for the admin. */
export interface RegistryRecord {
  registeredName: string
  council: string
  qualification: string
  registeredSince?: number | null
  /** Doctors: the NMC record's date of birth (ISO date) and permanent address. */
  dob?: string | null
  address?: string
  source: 'INC NRTS' | 'NMC IMR'
  /** False when the register was down and the partner continued; ALLCURO verifies by hand. */
  autoVerified: boolean
  checkedAt: string
  fields: { label: string; value: string }[]
  verifyUrl?: string | null
}

export interface MedicalCouncil {
  code: string
  name: string
}

/** A failed check. `portalDown` = the government site was unreachable (HTTP 502), not a failed verification. */
export class VerificationError extends Error {
  readonly portalDown: boolean
  constructor(message: string, portalDown = false) {
    super(message)
    this.portalDown = portalDown
  }
}

const s = (v: unknown) => (v == null ? '' : String(v).trim())
const rows = (r: [string, string][]) => r.filter(([, v]) => v.trim() !== '').map(([label, value]) => ({ label, value }))

/** "SHARMA, YUKTI" → "Yukti Sharma". */
export function titleCaseName(raw: string) {
  let t = raw.trim()
  const comma = t.indexOf(',')
  if (comma > 0) t = `${t.slice(comma + 1)} ${t.slice(0, comma)}`
  return t
    .split(/\s+/)
    .filter(Boolean)
    .map((w) => (w.length === 1 ? w.toUpperCase() : w[0].toUpperCase() + w.slice(1).toLowerCase()))
    .join(' ')
}

/** "21-08-1999 00:00" → "1999-08-21". */
function dmyToIso(v: string) {
  const m = /^(\d{1,2})-(\d{1,2})-(\d{4})/.exec(v)
  return m ? `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}` : null
}

async function callFunction(path: string, notFound?: (body: Record<string, unknown>) => string) {
  if (!functionsUrl) throw new VerificationError('Registration checks need the site to be connected to ALLCURO (Supabase keys missing from this build).')
  let res: Response
  try {
    res = await fetch(`${functionsUrl}/${path}`, { headers: { Authorization: `Bearer ${supabaseAnonKey}`, apikey: supabaseAnonKey } })
  } catch {
    throw new VerificationError('Could not reach the verification service. Check your connection and try again.')
  }
  const body = (await res.json().catch(() => ({}))) as Record<string, unknown>
  if (res.ok) return body
  if (res.status === 404 && notFound) throw new VerificationError(notFound(body))
  if (res.status === 400) throw new VerificationError(s(body.error) || 'Some details are missing or invalid.')
  if (res.status === 502)
    throw new VerificationError(
      'The government register is not responding right now. Try again in a few minutes, or continue and ALLCURO will verify your registration manually.',
      true,
    )
  throw new VerificationError(`Verification failed (HTTP ${res.status}). Please try again.`)
}

/** Nurse: NUID → INC NRTS. Only an "Active" record passes. */
export async function verifyNuid(nuid: string): Promise<RegistryRecord> {
  const id = nuid.trim().toUpperCase()
  if (!/^[A-Z0-9]{3,12}$/.test(id)) throw new VerificationError('Enter your NUID: 3–12 letters or digits, exactly as on your NRTS registration.')
  const notFound = () => `No nurse registration was found for NUID ${id}. Check the number and try again.`
  const r = await callFunction(`nuid/${encodeURIComponent(id)}`, notFound)
  if (r.found !== true) throw new VerificationError(notFound())
  const status = s(r.status)
  if (status.toLowerCase() !== 'active')
    throw new VerificationError(
      `Your NUID is marked "${status || 'inactive'}" by the Indian Nursing Council. Only active registrations can join ALLCURO.`,
    )
  const name = titleCaseName(s(r.name))
  return {
    registeredName: name,
    council: s(r.council) || 'Indian Nursing Council',
    qualification: s(r.registeredAs),
    source: 'INC NRTS',
    autoVerified: true,
    checkedAt: new Date().toISOString(),
    verifyUrl: s(r.verifyUrl) || null,
    fields: rows([
      ['Name', name],
      ['NUID', s(r.nuid)],
      ['Status', status],
      ['Council', s(r.council)],
      ['Registered as', s(r.registeredAs)],
      ['Registration no.', s(r.registrationNumber)],
      ['Designation', s(r.designation)],
      ['Current employment', s(r.currentEmployment)],
      ['Institute', s(r.institute)],
      ['Sector', s(r.sector)],
    ]),
  }
}

/** Doctor: name + registration number (+ optional council / year) → NMC Indian Medical Register. */
export async function verifyDoctor(opts: { name: string; regNo: string; council?: MedicalCouncil | null; year?: number | null }): Promise<RegistryRecord> {
  if (opts.name.trim().length < 2) throw new VerificationError('Enter your full name as on your NMC registration.')
  if (!opts.regNo.trim()) throw new VerificationError('Enter your medical registration number.')
  const params = new URLSearchParams({ name: opts.name.trim(), regNo: opts.regNo.trim() })
  if (opts.year) params.set('year', String(opts.year))
  if (opts.council) params.set('state', opts.council.code)
  const body = await callFunction(`doctor?${params}`, (b) =>
    b.reason === 'name_mismatch'
      ? 'This registration number exists, but under a different name. Enter your name exactly as on your NMC registration.'
      : b.reason === 'removed'
        ? 'The NMC register marks this registration as removed. Contact ALLCURO support if this is a mistake.'
        : `No doctor was found with this registration number${opts.council || opts.year ? ' for the council / year you picked' : ''}. Check the details and try again.`,
  )
  const d = body.doctor as Record<string, unknown> | undefined
  if (body.verified !== true || !d) throw new VerificationError('Your registration could not be verified. Check the details and try again.')
  const name = titleCaseName(s(d.name))
  const extras = Array.isArray(d.additionalQualifications) ? (d.additionalQualifications as Record<string, unknown>[]) : []
  return {
    registeredName: name,
    council: s(d.stateMedicalCouncil) || opts.council?.name || 'NMC',
    qualification: s(d.qualification),
    registeredSince: Number(d.yearOfInfo) || null,
    dob: dmyToIso(s(d.dateOfBirth)),
    address: s(d.permanentAddress),
    source: 'NMC IMR',
    autoVerified: true,
    checkedAt: new Date().toISOString(),
    fields: rows([
      ['Name', name],
      ['Registration no.', s(d.registrationNumber)],
      ['Registered on', s(d.registrationDate)],
      ['Medical council', s(d.stateMedicalCouncil)],
      ['Qualification', [s(d.qualification), s(d.qualificationYear)].filter(Boolean).join(', ')],
      ['University', s(d.university)],
      ...extras.map((q): [string, string] => ['Additional', [s(q.qualification), s(q.year)].filter(Boolean).join(', ')]),
      ["Father's / husband's name", s(d.fatherOrHusbandName)],
      ['Date of birth', s(d.dateOfBirth).split(' ')[0]],
    ]),
  }
}

/** Register down: keep what the partner typed, flagged for a manual check. */
export function manualRecord(opts: { isDoctor: boolean; name: string; regNo: string; council?: MedicalCouncil | null; year?: number | null }): RegistryRecord {
  const name = opts.name.trim().replace(/\s+/g, ' ')
  return {
    registeredName: name,
    council: opts.isDoctor ? (opts.council?.name ?? 'National Medical Commission') : 'Indian Nursing Council',
    qualification: '',
    registeredSince: opts.year ?? null,
    source: opts.isDoctor ? 'NMC IMR' : 'INC NRTS',
    autoVerified: false,
    checkedAt: new Date().toISOString(),
    fields: rows([
      ['Name (entered)', name],
      [opts.isDoctor ? 'Registration no.' : 'NUID', opts.regNo.trim().toUpperCase()],
      ['Medical council', opts.council?.name ?? ''],
      ['Year', opts.year ? String(opts.year) : ''],
      ['Check', 'Register unavailable — to be verified by ALLCURO'],
    ]),
  }
}

export async function doctorCouncils(): Promise<MedicalCouncil[]> {
  const body = await callFunction('doctor/states')
  return Array.isArray(body.states) ? (body.states as MedicalCouncil[]).filter((c) => c && c.code && c.name) : []
}

export async function doctorYears(): Promise<number[]> {
  const body = await callFunction('doctor/years')
  return Array.isArray(body.years) ? (body.years as number[]).filter((y) => Number.isFinite(y)).sort((a, b) => b - a) : []
}

// Verhoeff tables — the Aadhaar check digit.
const VD = [
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
  [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
  [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
  [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
  [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
  [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
  [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
  [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
  [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
]
const VP = [
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
  [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
  [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
  [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
  [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
  [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
  [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
]

/** 12 digits, not starting with 0 or 1, valid Verhoeff check digit. */
export function isValidAadhaar(digits: string) {
  if (!/^[2-9]\d{11}$/.test(digits)) return false
  let c = 0
  digits
    .split('')
    .reverse()
    .forEach((ch, i) => {
      c = VD[c][VP[i % 8][Number(ch)]]
    })
  return c === 0
}
