import { useState, type ReactNode } from 'react'
import { digitsOnly } from '../../lib/format'
import { delay } from '../../lib/store'
import { toast } from '../../lib/toast'
import {
  partnerLogout,
  patchIdentity,
  practitionerIdentity,
  saveSignup,
  setCentreStatus,
  setPartnerName,
  setPractitionerStatus,
  usePartnerSession,
} from '../session'
import { ChipGroup, PField, PIcon } from '../ui'
import { AuthWizard, ChoiceChips, ConfirmDialog, ConsentBox, LockedField, SectionLabel, StepHeader, SummaryList } from './AuthUi'
import {
  CENTRE_TYPE_OPTIONS,
  GENDER_OPTIONS,
  OWNERSHIP_TYPE_OPTIONS,
  REGISTRATION_LABELS,
  SPECIALISATION_OPTIONS,
  formatDob,
  type ClinicianProfession,
} from './data'

// The three short sign-up wizards that run after role select (and, for
// nurses / clinicians, after identity verification). Everything else —
// documents, bank, skills, rooms, staff — is finished later from the
// role's home screens, exactly like the partner app.

const SIGNUP_EXIT_TEXT = "You'll need to log in again to pick up where you left off."

/** Wizard step state + the "Exit sign-up?" confirm shared by the three wizards. */
function useWizardSteps(count: number) {
  const [step, setStep] = useState(0)
  const [confirmExit, setConfirmExit] = useState(false)
  const [busy, setBusy] = useState(false)
  const back = () => (step > 0 ? setStep(step - 1) : setConfirmExit(true))
  const next = () => {
    setStep((s) => Math.min(s + 1, count - 1))
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
  const exitDialog: ReactNode = confirmExit ? (
    <ConfirmDialog title="Exit sign-up?" text={SIGNUP_EXIT_TEXT} onCancel={() => setConfirmExit(false)} onConfirm={partnerLogout} />
  ) : null
  /** Runs the submit with the app's 600 ms pause; the portal guard routes on once the status changes. */
  const submit = async (save: () => void | Promise<unknown>) => {
    if (busy) return
    setBusy(true)
    await delay(600)
    try {
      await save()
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not save your profile. Please try again.', 'danger')
      setBusy(false)
    }
  }
  return { step, back, next, busy, submit, exitDialog, isLast: step === count - 1 }
}

function WarnNote({ children }: { children: ReactNode }) {
  return (
    <div className="p-note pa-warn-note">
      <PIcon name="shield" size={20} />
      <span>{children}</span>
    </div>
  )
}

function InfoNote({ children }: { children: ReactNode }) {
  return (
    <div className="p-note is-ok">
      <PIcon name="help" size={18} />
      <span>{children}</span>
    </div>
  )
}

/**
 * Date of birth, gender and address — locked when the council register
 * supplied them (NMC gives DOB and address), otherwise entered here, as on
 * the partner's Aadhaar card.
 */
function usePersonalDetails(identity: ReturnType<typeof practitionerIdentity>) {
  const [dob, setDob] = useState(identity?.dob ?? '')
  const [gender, setGender] = useState<string | null>(identity?.gender || null)
  const [address, setAddress] = useState(identity?.address ?? '')
  const today = new Date().toISOString().slice(0, 10)
  const ready = dob !== '' && dob < today && gender != null && address.trim() !== ''
  const save = () => patchIdentity({ dob, gender: gender ?? '', address: address.trim() })
  const fields = (
    <>
      {identity?.dob ? (
        <LockedField label="Date of birth" value={formatDob(identity.dob)} />
      ) : (
        <PField label="Date of birth (as on Aadhaar)">
          <input type="date" value={dob} max={today} autoComplete="bday" onChange={(e) => setDob(e.target.value)} />
        </PField>
      )}
      <div>
        <SectionLabel id="pa-gender-label">Gender</SectionLabel>
        <ChoiceChips labelledBy="pa-gender-label" options={GENDER_OPTIONS} value={gender} onChange={setGender} />
      </div>
      {identity?.address ? (
        <LockedField label="Address" value={identity.address} />
      ) : (
        <PField label="Address (as on Aadhaar)">
          <textarea rows={3} value={address} autoComplete="street-address" onChange={(e) => setAddress(e.target.value)} />
        </PField>
      )}
    </>
  )
  return { dob, gender, address: address.trim(), ready, save, fields }
}

// ================================================================ nurse

/** nurse/presentation/signup — Basic details → Qualification → Police verification. */
export function NurseSignupPage() {
  const s = usePartnerSession()
  const identity = practitionerIdentity(s)
  const w = useWizardSteps(3)

  // Name, registration and qualification come from the identity step — never a placeholder person.
  const fullName = identity?.fullName ?? ''
  const personal = usePersonalDetails(identity)
  const qualification = identity?.qualification ?? ''
  const registrationNumber = identity?.registrationNumber ?? ''
  const council = identity?.council ?? ''

  const [city, setCity] = useState((s.signup.city as string | undefined) ?? '')
  const [experienceYears, setExperienceYears] = useState('')
  const [previousEmployer, setPreviousEmployer] = useState('')
  const [policeConsent, setPoliceConsent] = useState(false)

  const canContinue =
    w.step === 0 ? fullName.trim() !== '' && personal.ready && city.trim() !== '' : w.step === 1 ? qualification !== '' && experienceYears.trim() !== '' : policeConsent

  const submit = () =>
    w.submit(() => {
      setPartnerName(fullName)
      personal.save()
      saveSignup({
        city: city.trim(),
        address: personal.address,
        dob: personal.dob,
        gender: personal.gender,
        employmentType: 'Full-time',
        qualification,
        registrationNumber,
        council,
        experienceYears: experienceYears.trim(),
        previousEmployer: previousEmployer.trim(),
        policeConsent,
        ...(Array.isArray(s.signup.skills) ? { skills: s.signup.skills } : {}),
      })
      return setPractitionerStatus('onboarding')
    })

  return (
    <>
      <AuthWizard
        label="Nurse sign-up"
        stepIndex={w.step}
        stepCount={3}
        onBack={w.back}
        primaryLabel={w.isLast ? 'Submit & Enter Dashboard' : 'Continue'}
        onPrimary={canContinue ? (w.isLast ? submit : w.next) : null}
        busy={w.busy}
        secondaryLabel="Skip for now"
        onSecondary={submit}
      >
        {w.step === 0 && (
          <>
            <StepHeader title="Tell us about yourself" subtitle="Enter these exactly as on your Aadhaar card. ALLCURO checks them before approval." />
            <LockedField label="Full name" value={fullName} />
            {personal.fields}
            <PField label="City you'll work in" hint="Requests near this city are shown to you first.">
              <input value={city} onChange={(e) => setCity(e.target.value)} placeholder="Bengaluru" autoComplete="address-level2" />
            </PField>
          </>
        )}
        {w.step === 1 && (
          <>
            <StepHeader
              title="Qualification & experience"
              subtitle={council ? `Qualification and NUID are as registered with the ${council}.` : "This decides which specialised requests you're eligible for."}
            />
            <LockedField label="Qualification" value={qualification} />
            <LockedField label="NUID" value={registrationNumber} />
            <PField label="Years of experience">
              <input value={experienceYears} onChange={(e) => setExperienceYears(digitsOnly(e.target.value).slice(0, 2))} placeholder="e.g. 4" inputMode="numeric" />
            </PField>
            <PField label="Previous employer(s)">
              <textarea rows={2} value={previousEmployer} onChange={(e) => setPreviousEmployer(e.target.value)} placeholder="Hospital / agency / centre names" />
            </PField>
          </>
        )}
        {w.step === 2 && (
          <>
            <StepHeader title="Police verification" subtitle="Mandatory for every nurse before your profile is visible to families." />
            <WarnNote>
              We run a background check through a third-party verification partner using the government ID you uploaded. This usually takes 2–4 working days and
              happens automatically — no extra steps needed from you.
            </WarnNote>
            <ConsentBox checked={policeConsent} onChange={setPoliceConsent}>
              I consent to ALLCURO running a police verification / background check on my behalf.
            </ConsentBox>
          </>
        )}
      </AuthWizard>
      {w.exitDialog}
    </>
  )
}

// ================================================================ clinician

/** clinician/presentation/signup — Basic details → Qualification & registration → Verification consent. */
export function ClinicianSignupPage() {
  const s = usePartnerSession()
  const identity = practitionerIdentity(s)
  const w = useWizardSteps(3)

  // The partner app writes 'doctor' / 'physiotherapist'; the portal 'Doctor' / 'Physiotherapist'.
  const professionKey = identity?.profession?.toLowerCase()
  const profession: ClinicianProfession | null =
    professionKey === 'doctor' ? 'Doctor' : professionKey === 'physiotherapist' ? 'Physiotherapist' : null
  const fullName = identity?.fullName ?? ''
  const personal = usePersonalDetails(identity)
  const council = identity?.council ?? ''
  const qualification = identity?.qualification ?? ''
  const registrationNumber = identity?.registrationNumber ?? ''
  const optionsFor = profession ?? 'Doctor'

  const [city, setCity] = useState((s.signup.city as string | undefined) ?? '')
  const [specialisations, setSpecialisations] = useState<string[]>([])
  const [experienceYears, setExperienceYears] = useState('')
  const [consent, setConsent] = useState(false)

  const canContinue =
    w.step === 0
      ? profession != null && fullName.trim() !== '' && personal.ready && city.trim() !== ''
      : w.step === 1
        ? qualification !== '' && registrationNumber.trim() !== '' && experienceYears.trim() !== ''
        : consent

  const submit = () =>
    w.submit(() => {
      setPartnerName(profession === 'Doctor' ? `Dr. ${fullName}` : fullName)
      personal.save()
      saveSignup({
        city: city.trim(),
        address: personal.address,
        dob: personal.dob,
        gender: personal.gender,
        profession,
        qualification,
        registrationNumber,
        council,
        specialisations,
        experienceYears: experienceYears.trim(),
        backgroundConsent: consent,
      })
      return setPractitionerStatus('onboarding')
    })

  const councilName = profession === 'Physiotherapist' ? 'physiotherapy council' : 'medical council'

  return (
    <>
      <AuthWizard
        label="Doctor sign-up"
        stepIndex={w.step}
        stepCount={3}
        onBack={w.back}
        primaryLabel={w.isLast ? 'Submit & Enter Dashboard' : 'Continue'}
        onPrimary={canContinue ? (w.isLast ? submit : w.next) : null}
        busy={w.busy}
        secondaryLabel="Skip for now"
        onSecondary={submit}
      >
        {w.step === 0 && (
          <>
            <StepHeader title="Tell us about yourself" subtitle="Your name and registration come from the NMC register. ALLCURO checks everything before approval." />
            <LockedField label="Full name" value={fullName} />
            {personal.fields}
            <PField label="City you'll work in" hint="Home-visit requests near this city are shown to you first.">
              <input value={city} onChange={(e) => setCity(e.target.value)} placeholder="Bengaluru" autoComplete="address-level2" />
            </PField>
          </>
        )}
        {w.step === 1 && (
          <>
            <StepHeader
              title="Qualification & registration"
              subtitle={
                council ? `Qualification and registration are as recorded with the ${council}.` : "This decides which home-visit requests you're eligible for."
              }
            />
            <LockedField label="Highest qualification" value={qualification} />
            <LockedField label={REGISTRATION_LABELS[optionsFor]} value={registrationNumber} />
            <div className="pa-tall-chips" role="group" aria-label="Specialisations">
              <SectionLabel>Specialisations</SectionLabel>
              <ChipGroup options={SPECIALISATION_OPTIONS[optionsFor]} value={specialisations} onChange={setSpecialisations} />
            </div>
            <PField label="Years of experience">
              <input value={experienceYears} onChange={(e) => setExperienceYears(digitsOnly(e.target.value).slice(0, 2))} placeholder="e.g. 4" inputMode="numeric" />
            </PField>
          </>
        )}
        {w.step === 2 && (
          <>
            <StepHeader title="Verification" subtitle="Mandatory before your profile is visible to families." />
            <WarnNote>
              We verify your registration with the {councilName} and run a background check through a third-party partner. This usually takes 2–4 working days
              and happens automatically.
            </WarnNote>
            <ConsentBox checked={consent} onChange={setConsent}>
              I consent to ALLCURO verifying my registration and running a background check on my behalf.
            </ConsentBox>
          </>
        )}
      </AuthWizard>
      {w.exitDialog}
    </>
  )
}

// ================================================================ centre

/** centre/presentation/signup — Entity details → Business email → Review & submit. */
export function CentreSignupPage() {
  const w = useWizardSteps(3)
  const saved = usePartnerSession().signup
  const text = (k: string) => (typeof saved[k] === 'string' ? (saved[k] as string) : '')

  const [centreName, setCentreName] = useState(text('centreName'))
  const [centreType, setCentreType] = useState<string | null>(text('centreType') || null)
  const [yearEstablished, setYearEstablished] = useState(text('yearEstablished'))
  const [ownershipType, setOwnershipType] = useState<string | null>(text('ownershipType') || null)
  const [businessEmail, setBusinessEmail] = useState(text('businessEmail'))

  const year = Number(yearEstablished)
  const yearError = yearEstablished && (year < 1900 || year > new Date().getFullYear()) ? 'Enter a year between 1900 and this year' : null
  const emailOk = businessEmail.trim().includes('@')

  const canContinue =
    w.step === 0 ? centreName.trim() !== '' && centreType != null && yearEstablished.trim() !== '' && !yearError : w.step === 1 ? emailOk : true

  const submit = () =>
    w.submit(() => {
      setPartnerName(centreName.trim())
      saveSignup({
        centreName: centreName.trim(),
        centreType,
        yearEstablished: yearEstablished.trim(),
        ownershipType,
        businessEmail: businessEmail.trim(),
      })
      setCentreStatus('onboarding')
    })

  return (
    <>
      <AuthWizard
        label="Centre sign-up"
        stepIndex={w.step}
        stepCount={3}
        onBack={w.back}
        primaryLabel={w.isLast ? 'Submit & Enter Dashboard' : 'Continue'}
        onPrimary={canContinue ? (w.isLast ? submit : w.next) : null}
        busy={w.busy}
      >
        {w.step === 0 && (
          <>
            <StepHeader title="Tell us about your centre" />
            <PField label="Centre name">
              <input value={centreName} onChange={(e) => setCentreName(e.target.value)} placeholder="As on your licence" autoComplete="organization" />
            </PField>
            <div>
              <SectionLabel id="pa-ctype">Centre type</SectionLabel>
              <ChoiceChips labelledBy="pa-ctype" options={CENTRE_TYPE_OPTIONS} value={centreType} onChange={setCentreType} />
            </div>
            <PField label="Year established" error={yearError}>
              <input
                value={yearEstablished}
                onChange={(e) => setYearEstablished(digitsOnly(e.target.value).slice(0, 4))}
                placeholder="e.g. 2018"
                inputMode="numeric"
              />
            </PField>
            <div>
              <SectionLabel id="pa-owner">Ownership type</SectionLabel>
              <ChoiceChips labelledBy="pa-owner" options={OWNERSHIP_TYPE_OPTIONS} value={ownershipType} onChange={setOwnershipType} />
            </div>
          </>
        )}
        {w.step === 1 && (
          <>
            <StepHeader title="What's your business email?" subtitle="We'll send verification updates and settlement statements here." />
            <PField label="Business email" error={businessEmail.trim() && !emailOk ? 'Enter a valid email address' : null}>
              <input
                type="email"
                value={businessEmail}
                onChange={(e) => setBusinessEmail(e.target.value)}
                placeholder="ops@yourcentre.com"
                autoComplete="email"
                inputMode="email"
              />
            </PField>
          </>
        )}
        {w.step === 2 && (
          <>
            <StepHeader title="Review & submit" subtitle="Next: Pending Admin Review → Site-Visit → Verified & Live." />
            <SummaryList
              rows={[
                ['Centre name', centreName],
                ['Type', centreType ?? '—'],
                ['Ownership', ownershipType ?? '—'],
                ['Business email', businessEmail],
                ['Year established', yearEstablished],
              ]}
            />
            <InfoNote>Next, add your rooms, staff and compliance documents from the dashboard, then submit them for review.</InfoNote>
          </>
        )}
      </AuthWizard>
      {w.exitDialog}
    </>
  )
}
