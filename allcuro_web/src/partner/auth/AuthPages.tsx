import { useEffect, useMemo, useRef, useState, type FormEvent } from 'react'
import { Link } from '../../components/Link'
import { digitsOnly, formatPhone, initials, useNow } from '../../lib/format'
import { toast } from '../../lib/toast'
import { goBack, navigate } from '../../router'
import { PR } from '../routes'
import {
  clearRole,
  partnerLogout,
  partnerSendOtp,
  partnerVerifyOtp,
  practitionerIdentity,
  practitionerStatus,
  saveBank,
  saveIdentity,
  saveSignup,
  selectRole,
  setCentreStatus,
  setPractitionerStatus,
  usePartnerSession,
  usesNurseShell,
  type CentreVerificationStatus,
  type NurseVerificationStatus,
  type ProviderRole,
  type UploadedDoc,
  uploadKycFile,
} from '../session'
import { PBadge, PBody, PCard, PField, PIcon, PPageHead, type PIconName } from '../ui'
import {
  AuthWizard,
  BrandBack,
  BrandMark,
  BrandScreen,
  ButtonSpinner,
  ConfirmDialog,
  ConsentBox,
  ErrorBanner,
  SectionLabel,
  StepHeader,
  SummaryList,
} from './AuthUi'
import {
  ACCOUNT_TYPES,
  VerificationError,
  doctorCouncils,
  doctorYears,
  groupAadhaar,
  isValidAadhaar,
  manualRecord,
  verifyDoctor,
  verifyNuid,
  type MedicalCouncil,
  type RegistryRecord,
} from './data'
import { useCompliance, useEquipment, useRooms, useStaff } from '../centre/state'
import { CERTIFICATE_DOC_IDS, MEDICAL_DOC_ID } from '../nurse/data'
import { availabilityStore, effectiveSkills, nurseDocs } from '../nurse/state'

const errorText = (e: unknown) => (e instanceof Error ? e.message : String(e))

// ================================================================ welcome

/** welcome_screen.dart (+ the splash's entrance animation). */
export function PartnerWelcomePage() {
  return (
    <BrandScreen className="pa-welcome">
      <BrandMark size="lg" />
      <div className="pa-welcome-copy">
        <p className="pa-eyebrow">ALLCURO PARTNER</p>
        <h1 className="pa-hero">
          Care work,
          <br />
          coordinated better.
        </h1>
        <p className="pa-lead">Shift requests, bed availability, and your schedule — all in one place built for ALLCURO care partners.</p>
        <ul className="pa-welcome-points" aria-label="Who this is for">
          <li>
            <PIcon name="heart" size={18} /> Nurses
          </li>
          <li>
            <PIcon name="user" size={18} /> Doctors &amp; physiotherapists
          </li>
          <li>
            <PIcon name="store" size={18} /> Homecare centres
          </li>
        </ul>
      </div>
      <div className="pa-welcome-actions">
        <Link to={PR.phoneAuth} className="p-btn pa-cta">
          Get started <PIcon name="chevron" size={20} />
        </Link>
        <p className="pa-fineprint">By continuing, you agree to our Terms of Service and Privacy Policy.</p>
        <Link to="/" className="pa-text-link">
          Looking for care? Go to the ALLCURO site
        </Link>
      </div>
    </BrandScreen>
  )
}

// ================================================================ phone → OTP

const RESEND_COOLDOWN_S = 30

/** phone_auth_screen.dart + phone_auth_view_model.dart. */
export function PartnerPhoneAuthPage() {
  const [step, setStep] = useState<'phone' | 'otp'>('phone')
  const [phone, setPhone] = useState('')
  const [otp, setOtp] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [resendAt, setResendAt] = useState(0)
  const [otpFocused, setOtpFocused] = useState(false)
  const otpRef = useRef<HTMLInputElement>(null)
  const now = useNow(500)
  const secondsLeft = Math.max(0, Math.ceil((resendAt - now) / 1000))

  const submitPhone = async (e?: FormEvent) => {
    e?.preventDefault()
    if (phone.length !== 10 || busy) return
    setBusy(true)
    setError(null)
    try {
      await partnerSendOtp(phone)
      setOtp('')
      setStep('otp')
      setResendAt(Date.now() + RESEND_COOLDOWN_S * 1000)
    } catch (err) {
      setError(errorText(err))
    } finally {
      setBusy(false)
    }
  }

  const verify = async (code = otp) => {
    if (code.length !== 6 || busy) return
    setBusy(true)
    setError(null)
    try {
      // On success the session flips to signed-in and the portal guard moves on.
      await partnerVerifyOtp(phone, code)
    } catch (err) {
      setError(errorText(err))
      setBusy(false)
    }
  }

  const resend = async () => {
    if (secondsLeft > 0 || busy) return
    setResendAt(Date.now() + RESEND_COOLDOWN_S * 1000)
    setBusy(true)
    setError(null)
    try {
      await partnerSendOtp(phone)
      toast('A new code has been sent', 'info')
    } catch (err) {
      setError(errorText(err))
    } finally {
      setBusy(false)
    }
  }

  const editNumber = () => {
    setStep('phone')
    setError(null)
    setResendAt(0)
  }

  return (
    <BrandScreen className="pa-auth">
      <BrandBack onClick={step === 'otp' ? editNumber : () => goBack(PR.welcome)} label={step === 'otp' ? 'Change phone number' : 'Go back'} />

      {step === 'phone' ? (
        <form className="pa-auth-step" key="phone" onSubmit={submitPhone} noValidate>
          <h1 className="pa-title">
            Enter your phone
            <br />
            number
          </h1>
          <label className="pa-label" htmlFor="pa-phone">
            Phone number
          </label>
          <div className="pa-phone">
            <span className="pa-phone-cc">+91</span>
            <span className="pa-phone-sep" aria-hidden="true" />
            <input
              id="pa-phone"
              type="tel"
              inputMode="numeric"
              autoComplete="tel-national"
              autoFocus
              placeholder="98765 43210"
              value={phone}
              maxLength={10}
              onChange={(e) => setPhone(digitsOnly(e.target.value).slice(0, 10))}
              aria-invalid={error ? true : undefined}
              aria-describedby={error ? 'pa-phone-err' : 'pa-phone-hint'}
            />
          </div>
          {error ? (
            <p className="pa-err-text" id="pa-phone-err" role="alert">
              {error}
            </p>
          ) : (
            <p className="pa-hint-text" id="pa-phone-hint">
              We'll send a 6-digit code by SMS to sign you in.
            </p>
          )}
          <div className="pa-auth-foot">
            <button type="submit" className="p-btn pa-cta" disabled={phone.length !== 10 || busy} aria-busy={busy}>
              {busy ? <ButtonSpinner /> : 'Continue'}
            </button>
          </div>
        </form>
      ) : (
        <form
          className="pa-auth-step"
          key="otp"
          onSubmit={(e) => {
            e.preventDefault()
            verify()
          }}
          noValidate
        >
          <h1 className="pa-title">Verification</h1>
          <p className="pa-lead">
            We've sent a code to {formatPhone(phone)}.{' '}
            <button type="button" className="pa-inline-link" onClick={editNumber}>
              Edit
            </button>
          </p>
          <div className="pa-otp-head">
            <label className="pa-label" htmlFor="pa-otp">
              Enter code
            </label>
            {secondsLeft > 0 ? (
              <span className="pa-countdown" aria-live="polite">
                Resend in 0:{String(secondsLeft).padStart(2, '0')}
              </span>
            ) : (
              <button type="button" className="pa-inline-link" onClick={resend} disabled={busy}>
                Resend code
              </button>
            )}
          </div>
          <div className="pa-otp" onClick={() => otpRef.current?.focus()}>
            <div className="pa-otp-boxes" aria-hidden="true">
              {Array.from({ length: 6 }, (_, i) => (
                <span key={i} className={`pa-otp-box ${otpFocused && i === Math.min(otp.length, 5) ? 'is-active' : ''} ${otp[i] ? 'is-filled' : ''}`}>
                  {otp[i] ?? ''}
                </span>
              ))}
            </div>
            <input
              ref={otpRef}
              id="pa-otp"
              className="pa-otp-input"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              autoFocus
              maxLength={6}
              value={otp}
              onFocus={() => setOtpFocused(true)}
              onBlur={() => setOtpFocused(false)}
              onChange={(e) => {
                const v = digitsOnly(e.target.value).slice(0, 6)
                setOtp(v)
                if (v.length === 6) verify(v)
              }}
              aria-invalid={error ? true : undefined}
              aria-describedby="pa-otp-demo"
            />
          </div>
          {error && (
            <p className="pa-err-text" role="alert">
              {error}
            </p>
          )}
          <div className="pa-auth-foot">
            <p className="pa-demo" id="pa-otp-demo">
              Enter the 6-digit code we sent by SMS.
            </p>
            <button type="submit" className="p-btn pa-cta" disabled={otp.length !== 6 || busy} aria-busy={busy}>
              {busy ? <ButtonSpinner /> : 'Verify'}
            </button>
          </div>
        </form>
      )}
    </BrandScreen>
  )
}

// ================================================================ role select

// Homecare centres, physiotherapists and caregivers sign up here later —
// their onboarding isn't open yet.
const ROLES: { role: ProviderRole; icon: PIconName; title: string; description: string }[] = [
  { role: 'nurse', icon: 'heart', title: "I'm a Nurse", description: 'Verify your NUID, then accept shift requests and manage your schedule.' },
  {
    role: 'clinician',
    icon: 'clipboard',
    title: "I'm a Doctor",
    description: 'Verify your NMC registration and take home-visit consultations on your schedule.',
  },
]

/** role_select_screen.dart. Picking a role updates the session; the guard routes onward. */
export function RoleSelectPage() {
  const s = usePartnerSession()
  return (
    <BrandScreen className="pa-roles">
      <BrandMark size="sm" />
      <p className="pa-eyebrow">ALLCURO PARTNER</p>
      <h1 className="pa-title">
        How will you
        <br />
        work with us?
      </h1>
      <p className="pa-lead">Pick one to start your verification.</p>
      <ul className="pa-role-list">
        {ROLES.map((r) => (
          <li key={r.role}>
            <button type="button" className="pa-role" onClick={() => selectRole(r.role)}>
              <span className="pa-role-icon">
                <PIcon name={r.icon} size={22} />
              </span>
              <span className="pa-role-text">
                <strong>{r.title}</strong>
                <span>{r.description}</span>
              </span>
              <PIcon name="chevron" />
            </button>
          </li>
        ))}
      </ul>
      <p className="pa-signed-in">
        Signed in as {formatPhone(s.phone)} ·{' '}
        <button type="button" className="pa-inline-link" onClick={partnerLogout}>
          Use another number
        </button>
      </p>
    </BrandScreen>
  )
}

// ================================================================ identity verification

/**
 * features/identity — 1) registration checked with the council register
 * (nurse: NUID → INC NRTS; doctor: name + reg. no. → NMC Indian Medical
 * Register), 2) Aadhaar KYC: number + card photo, reviewed by ALLCURO.
 */
export function IdentityVerificationPage() {
  const s = usePartnerSession()
  const isDoctor = s.role === 'clinician'

  const [stepIndex, setStepIndex] = useState(0)
  const [registeredName, setRegisteredName] = useState('')
  const [regNo, setRegNo] = useState('')
  const [council, setCouncil] = useState<MedicalCouncil | null>(null)
  const [year, setYear] = useState<number | null>(null)
  const [councils, setCouncils] = useState<MedicalCouncil[]>([])
  const [years, setYears] = useState<number[]>([])
  const [registry, setRegistry] = useState<RegistryRecord | null>(null)
  const [portalDown, setPortalDown] = useState(false)
  const [aadhaar, setAadhaar] = useState('')
  const [front, setFront] = useState<File | null>(null)
  const [back, setBack] = useState<File | null>(null)
  const [consent, setConsent] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [confirmExit, setConfirmExit] = useState(false)

  // Doctors: State Medical Councils and years for the optional filters.
  useEffect(() => {
    if (!isDoctor) return
    let live = true
    Promise.all([doctorCouncils(), doctorYears()])
      .then(([c, y]) => {
        if (!live) return
        setCouncils(c)
        setYears(y)
      })
      .catch(() => undefined) // Optional — the check works without them.
    return () => {
      live = false
    }
  }, [isDoctor])

  const run = async (action: () => Promise<void>) => {
    setBusy(true)
    setError(null)
    try {
      await action()
    } catch (e) {
      setPortalDown(e instanceof VerificationError && e.portalDown)
      setError(errorText(e))
    } finally {
      setBusy(false)
    }
  }

  // Any change to what identifies the registration invalidates a previous lookup.
  const editRegistration = (change: () => void) => {
    change()
    setRegistry(null)
    setError(null)
  }

  const verifyRegistration = () =>
    run(async () => {
      setPortalDown(false)
      setRegistry(isDoctor ? await verifyDoctor({ name: registeredName, regNo, council, year }) : await verifyNuid(regNo))
    })

  const continueWithoutCheck = () => {
    if (!isDoctor && registeredName.trim().length < 2) {
      setError('Enter your full name as registered with the nursing council to continue.')
      return
    }
    setRegistry(manualRecord({ isDoctor, name: registeredName, regNo, council, year }))
    setPortalDown(false)
    setError(null)
    setStepIndex(1)
  }

  const aadhaarInvalid = aadhaar.length === 12 && !isValidAadhaar(aadhaar)

  const completeKyc = () =>
    run(async () => {
      if (!registry) return
      if (!isValidAadhaar(aadhaar)) throw new Error('That is not a valid Aadhaar number. Check the 12 digits on your card.')
      const documents: Record<string, UploadedDoc> = {}
      if (front) documents.aadhaar_front = await uploadKycFile('aadhaar_front', front)
      if (back) documents.aadhaar_back = await uploadKycFile('aadhaar_back', back)
      // The portal guard moves on to the sign-up wizard once this is saved.
      await saveIdentity(
        {
          fullName: registry.registeredName || registeredName.trim(),
          dob: registry.dob ?? '',
          gender: '',
          address: registry.address ?? '',
          aadhaarLast4: aadhaar.slice(-4),
          registrationLabel: isDoctor ? 'Medical Reg. No.' : 'NUID',
          registrationNumber: regNo.trim().toUpperCase(),
          council: registry.council,
          qualification: registry.qualification,
          profession: isDoctor ? 'Doctor' : undefined,
          registry,
        },
        documents,
      )
    })

  const registrationReady = isDoctor ? registeredName.trim().length >= 2 && regNo.trim() !== '' : regNo.trim().length >= 3
  const kycReady = aadhaar.length === 12 && !aadhaarInvalid && front != null && consent

  let primary: [string, (() => void) | null]
  if (stepIndex === 0) {
    primary = registry
      ? ['Continue to Aadhaar KYC', () => (setStepIndex(1), setError(null))]
      : [isDoctor ? 'Verify with NMC' : 'Verify NUID', registrationReady ? verifyRegistration : null]
  } else primary = ['Complete KYC', kycReady ? completeKyc : null]

  const showName = isDoctor || portalDown || (registry != null && !registry.autoVerified)

  return (
    <>
      <AuthWizard
        label="Identity verification"
        stepIndex={stepIndex}
        stepCount={2}
        onBack={() => {
          if (stepIndex > 0) {
            setStepIndex(0)
            setError(null)
          } else setConfirmExit(true)
        }}
        primaryLabel={primary[0]}
        onPrimary={primary[1]}
        busy={busy}
      >
        {stepIndex === 0 ? (
          <>
            <StepHeader
              title={isDoctor ? 'Verify your NMC registration' : 'Verify your NUID'}
              subtitle={
                isDoctor
                  ? "We check your name and registration number against the National Medical Commission's Indian Medical Register."
                  : "Enter your Nurse Unique ID (NUID). We fetch your registration from the Indian Nursing Council's NRTS register."
              }
            />
            {showName && (
              <PField label="Full name (as registered)" hint={isDoctor ? 'As on your NMC / council registration' : 'As on your nursing council registration'}>
                <input
                  value={registeredName}
                  autoComplete="name"
                  maxLength={80}
                  readOnly={registry != null}
                  onChange={(e) => {
                    const v = e.target.value
                    editRegistration(() => setRegisteredName(v))
                  }}
                />
              </PField>
            )}
            <PField
              label={isDoctor ? 'Medical registration number' : 'NUID (Nurse Unique ID)'}
              hint={isDoctor ? 'Exactly as on your registration certificate' : '3–12 letters and digits'}
            >
              <input
                value={regNo}
                placeholder={isDoctor ? 'e.g. 112345' : 'e.g. ABC123456'}
                maxLength={isDoctor ? 20 : 12}
                autoCapitalize="characters"
                autoComplete="off"
                readOnly={registry != null}
                onChange={(e) => {
                  const v = e.target.value.replace(isDoctor ? /[^A-Za-z0-9/-]/g : /[^A-Za-z0-9]/g, '').slice(0, isDoctor ? 20 : 12)
                  editRegistration(() => setRegNo(v))
                }}
              />
            </PField>
            {isDoctor && (
              <>
                <PField label="State Medical Council (optional)">
                  <select
                    value={council?.code ?? ''}
                    disabled={registry != null || councils.length === 0}
                    onChange={(e) => {
                      const c = councils.find((x) => x.code === e.target.value) ?? null
                      editRegistration(() => setCouncil(c))
                    }}
                  >
                    <option value="">{councils.length === 0 ? 'Loading councils…' : 'Any council'}</option>
                    {councils.map((c) => (
                      <option key={c.code} value={c.code}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </PField>
                <PField label="Year of registration (optional)">
                  <select
                    value={year ?? ''}
                    disabled={registry != null || years.length === 0}
                    onChange={(e) => {
                      const y = Number(e.target.value) || null
                      editRegistration(() => setYear(y))
                    }}
                  >
                    <option value="">{years.length === 0 ? 'Loading years…' : 'Any year'}</option>
                    {years.map((y) => (
                      <option key={y} value={y}>
                        {y}
                      </option>
                    ))}
                  </select>
                </PField>
              </>
            )}
            {error && <ErrorBanner message={error} />}
            {portalDown && !registry && (
              <button type="button" className="p-btn p-btn-outline" disabled={busy} onClick={continueWithoutCheck}>
                Continue — ALLCURO will verify manually
              </button>
            )}
            {registry && (
              <>
                <p className="pa-match">
                  <PIcon name="check" size={16} />{' '}
                  {registry.autoVerified
                    ? isDoctor
                      ? 'Found in the Indian Medical Register'
                      : 'NUID verified with the Indian Nursing Council'
                    : 'Saved — ALLCURO will verify your registration'}
                </p>
                <dl className="pa-summary">
                  {registry.fields.map((f, i) => (
                    <div key={i}>
                      <dt>{f.label}</dt>
                      <dd>{f.value}</dd>
                    </div>
                  ))}
                </dl>
                <button type="button" className="pa-inline-link" onClick={() => editRegistration(() => undefined)}>
                  Not you? Edit details
                </button>
              </>
            )}
          </>
        ) : (
          <>
            <StepHeader
              title="Aadhaar KYC"
              subtitle="Enter your Aadhaar number and upload a clear photo of your Aadhaar card. ALLCURO matches it with your registration before your profile goes live."
            />
            {registry && (
              <p className="pa-match">
                <PIcon name="shield" size={16} /> KYC for {registry.registeredName || registeredName}
              </p>
            )}
            <PField label="Aadhaar number" hint={aadhaarInvalid ? "This doesn't look like a valid Aadhaar number. Check the digits." : '12 digits, as printed on your Aadhaar card'}>
              <input
                value={groupAadhaar(aadhaar)}
                placeholder="XXXX XXXX XXXX"
                inputMode="numeric"
                autoComplete="off"
                maxLength={14}
                aria-invalid={aadhaarInvalid}
                onChange={(e) => {
                  setAadhaar(digitsOnly(e.target.value).slice(0, 12))
                  setError(null)
                }}
              />
            </PField>
            <div>
              <SectionLabel id="pa-aadhaar-photo">Aadhaar card photo</SectionLabel>
              <div className="pa-kyc-photos" aria-labelledby="pa-aadhaar-photo">
                <KycPhotoPicker label="Front side (required)" file={front} disabled={busy} onPick={setFront} />
                <KycPhotoPicker label="Back side (optional — has your address)" file={back} disabled={busy} onPick={setBack} />
              </div>
            </div>
            <ConsentBox checked={consent} onChange={setConsent}>
              I consent to ALLCURO storing my Aadhaar card photo and the last 4 digits of my Aadhaar number to verify my identity.
            </ConsentBox>
            {error && <ErrorBanner message={error} />}
          </>
        )}
      </AuthWizard>
      {confirmExit && (
        <ConfirmDialog
          title="Exit verification?"
          text="You'll need to log in again and verify to continue setting up your account."
          onCancel={() => setConfirmExit(false)}
          onConfirm={partnerLogout}
        />
      )}
    </>
  )
}

/** One Aadhaar card photo: an upload row with a thumbnail once picked. */
function KycPhotoPicker({ label, file, disabled, onPick }: { label: string; file: File | null; disabled: boolean; onPick: (f: File) => void }) {
  const ref = useRef<HTMLInputElement>(null)
  const preview = useMemo(() => (file ? URL.createObjectURL(file) : null), [file])
  useEffect(() => () => void (preview && URL.revokeObjectURL(preview)), [preview])
  return (
    <div className={`p-upload ${file ? 'is-done' : ''}`}>
      {preview ? (
        <img className="pa-kyc-thumb" src={preview} alt="" />
      ) : (
        <span className="p-upload-icon">
          <PIcon name="upload" size={20} />
        </span>
      )}
      <span className="p-upload-text">
        <strong>{label}</strong>
        <span>{file ? file.name : 'JPG or PNG, up to 10MB'}</span>
      </span>
      <button type="button" className="p-btn p-btn-outline p-btn-sm" disabled={disabled} onClick={() => ref.current?.click()}>
        {file ? 'Replace' : 'Upload'}
      </button>
      <input
        ref={ref}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="sr-only"
        tabIndex={-1}
        aria-hidden="true"
        onChange={(e) => {
          const f = e.target.files?.[0]
          e.target.value = ''
          if (!f) return
          if (f.size > 10 * 1024 * 1024) return toast('Photo is larger than 10MB.', 'danger')
          onPick(f)
        }}
      />
    </div>
  )
}

// ================================================================ bank account

/** bank_account_screen.dart — payout account, saved via saveBank (+ type & PAN in the sign-up bag). */
export function BankAccountPage() {
  const s = usePartnerSession()
  const back = s.role === 'centre' ? PR.centreHome : PR.nurseHome
  const [form, setForm] = useState(() => ({
    holder: s.bank?.holder ?? '',
    bankName: s.bank?.bankName ?? '',
    account: s.bank?.account ?? '',
    confirm: s.bank?.account ?? '',
    ifsc: s.bank?.ifsc ?? '',
    pan: (s.signup.bankPan as string | undefined) ?? '',
    accountType: (s.signup.bankAccountType as string | undefined) ?? 'Current Account',
  }))
  const [submitted, setSubmitted] = useState(false)

  const errors = {
    holder: form.holder.trim() ? null : 'Please enter account holder name',
    bankName: form.bankName.trim() ? null : 'Please enter bank name',
    account: form.account.trim().length >= 8 ? null : 'Enter valid account number',
    confirm: form.confirm.trim() ? null : 'Please confirm account number',
    ifsc: form.ifsc.trim().length >= 8 ? null : 'Enter valid 11-digit IFSC',
    pan: form.pan.trim().length >= 10 ? null : 'Enter valid 10-character PAN',
  }
  const shown = (k: keyof typeof errors) => (submitted ? errors[k] : null)
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm((f) => ({ ...f, [k]: e.target.value }))

  const save = (e: FormEvent) => {
    e.preventDefault()
    setSubmitted(true)
    if (Object.values(errors).some(Boolean)) return
    if (form.account.trim() !== form.confirm.trim()) {
      toast('Account numbers do not match', 'danger')
      return
    }
    saveBank({
      holder: form.holder.trim(),
      bankName: form.bankName.trim(),
      account: form.account.trim(),
      ifsc: form.ifsc.trim().toUpperCase(),
      upi: s.bank?.upi,
    })
    saveSignup({ bankAccountType: form.accountType, bankPan: form.pan.trim().toUpperCase() })
    toast('Bank account and payout details updated successfully')
    goBack(PR.profile)
  }

  return (
    <>
      <PPageHead title="Bank & Payout Setup" subtitle="Direct Razorpay Route settlements to your verified account" back={back} />
      <PBody narrow>
        <PCard className="pa-info-card">
          <span className="pa-info-icon">
            <PIcon name="shield" size={22} />
          </span>
          <div>
            <strong>Automated Split Settlement</strong>
            <p className="p-muted">All patient booking fees are credited directly via NPCI/IMPS within 24 hours of shift completion.</p>
          </div>
        </PCard>
        {s.bank && (
          <p className="p-note is-ok">
            <PIcon name="check" size={18} /> Payouts go to {s.bank.bankName} ····{s.bank.account.slice(-4)}. Update the details below to change it.
          </p>
        )}
        <form className="pa-bank-form" onSubmit={save} noValidate>
          <h2 className="pa-h2">Account details</h2>
          <PField label="Account Holder / Entity Name" error={shown('holder')}>
            <input value={form.holder} onChange={set('holder')} placeholder="As on your bank account" autoComplete="name" />
          </PField>
          <PField label="Bank Name" error={shown('bankName')}>
            <input value={form.bankName} onChange={set('bankName')} placeholder="e.g. HDFC Bank, ICICI Bank, SBI" />
          </PField>
          <div className="p-form-grid">
            <PField label="Account Number" error={shown('account')}>
              <input
                value={form.account}
                onChange={(e) => setForm((f) => ({ ...f, account: digitsOnly(e.target.value).slice(0, 18) }))}
                placeholder="Your 9–18 digit account number"
                inputMode="numeric"
                autoComplete="off"
              />
            </PField>
            <PField label="Re-Enter Account Number" error={shown('confirm')}>
              <input
                value={form.confirm}
                onChange={(e) => setForm((f) => ({ ...f, confirm: digitsOnly(e.target.value).slice(0, 18) }))}
                placeholder="Re-enter for confirmation"
                inputMode="numeric"
                autoComplete="off"
                onPaste={(e) => e.preventDefault()}
              />
            </PField>
            <PField label="IFSC Code" error={shown('ifsc')}>
              <input
                value={form.ifsc}
                onChange={(e) => setForm((f) => ({ ...f, ifsc: e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 11) }))}
                placeholder="e.g. HDFC0001234"
                autoCapitalize="characters"
              />
            </PField>
            <PField label="PAN Card Number (for TDS Exemption)" error={shown('pan')}>
              <input
                value={form.pan}
                onChange={(e) => setForm((f) => ({ ...f, pan: e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 10) }))}
                placeholder="e.g. ABCDE1234F"
                autoCapitalize="characters"
              />
            </PField>
          </div>
          <fieldset className="pa-fieldset">
            <legend className="p-field-label">Account Type</legend>
            <div className="pa-seg">
              {ACCOUNT_TYPES.map((t) => (
                <label key={t} className={`pa-seg-opt ${form.accountType === t ? 'is-on' : ''}`}>
                  <input type="radio" name="accountType" value={t} checked={form.accountType === t} onChange={() => setForm((f) => ({ ...f, accountType: t }))} />
                  {t}
                </label>
              ))}
            </div>
          </fieldset>
          <button type="submit" className="p-btn p-btn-primary p-btn-block pa-pill">
            Save &amp; Verify Account
          </button>
        </form>
      </PBody>
    </>
  )
}

// ================================================================ profile

type SetupTile = { icon: PIconName; title: string; subtitle: string; done: boolean; to: string }

const NURSE_STATUS: Record<NurseVerificationStatus, [string, 'default' | 'warn' | 'ok']> = {
  incomplete: ['Incomplete', 'default'],
  onboarding: ['Setup in progress', 'warn'],
  underReview: ['Under review', 'warn'],
  verified: ['Verified', 'ok'],
  rejected: ['Changes requested', 'warn'],
  suspended: ['Suspended', 'warn'],
}

const CENTRE_STATUS: Record<CentreVerificationStatus, [string, 'default' | 'warn' | 'ok']> = {
  incomplete: ['Incomplete', 'default'],
  onboarding: ['Setup in progress', 'warn'],
  pendingReview: ['Pending admin review', 'warn'],
  siteVisitScheduled: ['Site-visit scheduled', 'warn'],
  verified: ['Verified & live', 'ok'],
  rejected: ['Changes requested', 'warn'],
  suspended: ['Suspended', 'warn'],
}

/** profile_screen.dart — identity, verification status + demo advance, setup links, account actions. */
export function PartnerProfilePage() {
  const s = usePartnerSession()
  const [confirmSwitch, setConfirmSwitch] = useState(false)
  const isCentre = s.role === 'centre'
  const isClinician = s.role === 'clinician'
  const identity = practitionerIdentity(s)
  const city = (s.signup.city as string | undefined) || ''
  const inCity = city ? ` · ${city}` : ''
  const hasBank = s.bank != null
  const practitionerDocs = nurseDocs(s)
  const availability = availabilityStore.use()
  const rooms = useRooms()
  const staff = useStaff()
  const centreDocs = useCompliance()
  const equipment = useEquipment()
  const certificatesDone = practitionerDocs.filter((d) => CERTIFICATE_DOC_IDS.includes(d.id) && d.isUploaded).length >= CERTIFICATE_DOC_IDS.length
  const medicalDone = practitionerDocs.some((d) => d.id === MEDICAL_DOC_ID && d.isUploaded)
  const skillCount = effectiveSkills(availability, s).length

  const practitionerName = identity
    ? identity.profession === 'Doctor' && !identity.fullName.startsWith('Dr.')
      ? `Dr. ${identity.fullName}`
      : identity.fullName
    : s.name || 'Partner'
  const name = isCentre ? s.name || 'Your centre' : practitionerName
  const subtitle = isCentre
    ? `Homecare Centre Partner${inCity}`
    : isClinician
      ? `${identity?.profession ?? 'Doctor / Physiotherapist'}${identity?.qualification ? ` (${identity.qualification})` : ''}${inCity}`
      : `Registered Nurse${identity?.qualification ? ` (${identity.qualification})` : ''}${inCity}`
  const home = usesNurseShell(s.role) ? PR.nurseHome : PR.centreHome

  const [statusLabel, statusTone] = isCentre ? CENTRE_STATUS[s.centreStatus] : NURSE_STATUS[practitionerStatus(s)]

  const tiles: SetupTile[] = isCentre
    ? [
        {
          icon: 'shield',
          title: 'Compliance & Legal NOCs',
          subtitle: 'CEA, Fire Safety, Biomedical waste clearance',
          done: centreDocs.length > 0 && centreDocs.every((d) => d.isUploaded),
          to: PR.centreCompliance,
        },
        { icon: 'users', title: 'Staff Roster & Duty Nurses', subtitle: 'Manage nurse-to-patient staff ratios', done: staff.length > 0, to: PR.centreStaff },
        { icon: 'bed', title: 'Room Inventory & Pricing', subtitle: 'Rooms, beds and amenities', done: rooms.length > 0, to: PR.centreRooms },
        { icon: 'store', title: 'Equipment Rentals', subtitle: 'Equipment you can rent out to families', done: equipment.length > 0, to: PR.centreEquipment },
        { icon: 'bank', title: 'Bank Account & Payout Setup', subtitle: 'Direct Razorpay Route deposits', done: hasBank, to: PR.bankAccount },
      ]
    : [
        { icon: 'file', title: 'Document Vault', subtitle: 'Degree certificates & HPR registry', done: certificatesDone, to: PR.nurseDocuments },
        { icon: 'heart', title: 'Medical Fitness & TB Report', subtitle: 'Upload annual fitness self-declaration', done: medicalDone, to: PR.nurseDocuments },
        { icon: 'bank', title: 'Bank Account & Payout Setup', subtitle: 'Direct Razorpay Route deposits', done: hasBank, to: PR.bankAccount },
        {
          icon: 'star',
          title: 'Skills & Specialisations',
          subtitle: skillCount ? `${skillCount} skills selected` : 'Pick the care you can provide',
          done: skillCount > 0,
          to: PR.nurseAvailability,
        },
      ]

  // Submit for the admin's review. Approval itself happens in the admin panel.
  const st = isCentre ? s.centreStatus : practitionerStatus(s)
  const canSubmit = st === 'onboarding' || st === 'rejected'
  const submitForReview = async () => {
    try {
      await (isCentre ? setCentreStatus('pendingReview') : setPractitionerStatus('underReview'))
    } catch (e) {
      toast(errorText(e), 'danger')
    }
  }

  return (
    <>
      <PPageHead title={isCentre ? 'Centre Profile' : isClinician ? 'Clinician Profile' : 'Nurse Profile'} back={home} />
      <PBody narrow>
        <div className="pa-profile-head">
          <span className="pa-profile-avatar" aria-hidden="true">
            {s.photoUrl ? <img src={s.photoUrl} alt="" /> : initials(name) || 'AP'}
          </span>
          <div className="p-row-grow">
            <h2>{name}</h2>
            <p className="p-muted">{subtitle}</p>
            {s.phone && <p className="p-muted">{formatPhone(s.phone)}</p>}
          </div>
        </div>

        {identity && (
          <SummaryList
            rows={[
              [identity.registrationLabel, identity.registrationNumber],
              ['Council', identity.council],
              ['Aadhaar', `XXXX XXXX ${identity.aadhaarLast4}`],
            ]}
          />
        )}

        <PCard as="section" className="pa-verify-card">
          <div className="pa-verify-head">
            <h2>Verification status</h2>
            <PBadge tone={statusTone}>{statusLabel}</PBadge>
          </div>
          <p className="p-muted">
            {isCentre
              ? 'Complete facility compliance modules to make beds bookable for patients.'
              : 'Complete the remaining profile modules, then submit your profile for approval.'}
          </p>
          <ul className="p-list">
            {tiles.map((t) => (
              <li key={t.title}>
                <Link to={t.to} className={`pa-setup ${t.done ? 'is-done' : ''}`}>
                  <span className="pa-setup-icon">
                    <PIcon name={t.icon} size={18} />
                  </span>
                  <span className="p-row-grow">
                    <strong>{t.title}</strong>
                    <span>{t.subtitle}</span>
                  </span>
                  {t.done ? (
                    <span className="pa-setup-done">
                      <PIcon name="check" size={18} />
                      <span className="sr-only">Done</span>
                    </span>
                  ) : (
                    <PIcon name="chevron" size={18} />
                  )}
                </Link>
              </li>
            ))}
          </ul>
          {s.adminNote && (st === 'rejected' || st === 'suspended') && (
            <div className="p-note pa-warn-note" role="status">
              <PIcon name="shield" size={18} />
              <span>
                <strong>Note from ALLCURO:</strong> {s.adminNote}
              </span>
            </div>
          )}
          <div className="pa-demo-advance">
            <span className="p-muted">
              {st === 'verified'
                ? 'Approved — families can see and book you.'
                : st === 'underReview' || st === 'pendingReview' || st === 'siteVisitScheduled'
                  ? 'Submitted. Our team reviews profiles within 2–4 working days.'
                  : st === 'suspended'
                    ? 'Your profile is hidden from families. Contact support.'
                    : 'Complete your public profile, then submit it for approval.'}
            </span>
            <Link to={PR.publicProfile} className="p-btn p-btn-outline p-btn-sm">
              Edit public profile
            </Link>
            {canSubmit && (
              <button type="button" className="p-btn p-btn-sm" onClick={() => void submitForReview()}>
                Submit for approval
              </button>
            )}
          </div>
        </PCard>

        <PCard as="section" className="pa-account">
          <h2 className="pa-h2">Account</h2>
          <ul className="pa-account-list">
            <li>
              <Link to={PR.bankAccount} className="pa-account-row">
                <PIcon name="bank" /> <span className="p-row-grow">Bank account &amp; payouts</span>
                {hasBank ? <PBadge tone="ok">Added</PBadge> : <PBadge tone="warn">Not added</PBadge>}
                <PIcon name="chevron" size={18} />
              </Link>
            </li>
            <li>
              <button type="button" className="pa-account-row" onClick={() => setConfirmSwitch(true)}>
                <PIcon name="users" /> <span className="p-row-grow">Switch role</span>
                <PIcon name="chevron" size={18} />
              </button>
            </li>
            <li>
              <Link to="/" className="pa-account-row">
                <PIcon name="heart" /> <span className="p-row-grow">Go to the ALLCURO customer site</span>
                <PIcon name="chevron" size={18} />
              </Link>
            </li>
          </ul>
        </PCard>

        <button type="button" className="p-btn p-btn-block pa-logout" onClick={partnerLogout}>
          <PIcon name="logout" /> Log out
        </button>
      </PBody>

      {confirmSwitch && (
        <ConfirmDialog
          title="Switch role?"
          text="You'll go back to role selection. Your progress for each role is kept on this device."
          confirmLabel="Switch role"
          tone="primary"
          onCancel={() => setConfirmSwitch(false)}
          onConfirm={() => {
            clearRole()
            navigate(PR.roleSelect, { replace: true })
          }}
        />
      )}
    </>
  )
}
