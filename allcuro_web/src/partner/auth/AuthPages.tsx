import { useRef, useState, type FormEvent } from 'react'
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
} from '../session'
import { PBadge, PBody, PCard, PField, PIcon, PPageHead, type PIconName } from '../ui'
import {
  AuthWizard,
  BrandBack,
  BrandMark,
  BrandScreen,
  ButtonSpinner,
  ChoiceChips,
  ConfirmDialog,
  ConsentBox,
  ErrorBanner,
  SectionLabel,
  StepHeader,
  VerifiedCard,
} from './AuthUi'
import {
  AADHAAR_DEMO_OTP,
  ACCOUNT_TYPES,
  COUNCIL_OPTIONS,
  PROFESSIONS,
  formatDob,
  groupAadhaar,
  sendAadhaarOtp,
  verifyAadhaarOtp,
  verifyCouncilRegistration,
  verifyNuid,
  type AadhaarProfile,
  type ClinicianProfession,
  type RegistryRecord,
} from './data'

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

const ROLES: { role: ProviderRole; icon: PIconName; title: string; description: string }[] = [
  { role: 'nurse', icon: 'heart', title: "I'm a Nurse", description: 'Accept shift requests, manage your schedule, and see job details.' },
  {
    role: 'clinician',
    icon: 'clipboard',
    title: "I'm a Doctor / Physiotherapist",
    description: 'Take home-visit consultations and therapy sessions on your schedule.',
  },
  { role: 'centre', icon: 'store', title: 'I run a Homecare Centre', description: 'Manage bed availability and respond to placement requests.' },
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
      <p className="pa-lead">Pick one — you can switch later from your profile.</p>
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

/** features/identity — 1) professional registration, 2) Aadhaar e-KYC via OTP. */
export function IdentityVerificationPage() {
  const s = usePartnerSession()
  const isClinician = s.role === 'clinician'

  const [stepIndex, setStepIndex] = useState(0)
  const [profession, setProfession] = useState<ClinicianProfession | null>(null)
  const [council, setCouncil] = useState<string | null>(null)
  const [regNo, setRegNo] = useState('')
  const [registry, setRegistry] = useState<RegistryRecord | null>(null)
  const [aadhaar, setAadhaar] = useState('')
  const [consent, setConsent] = useState(false)
  const [otpSent, setOtpSent] = useState(false)
  const [otp, setOtp] = useState('')
  const [profile, setProfile] = useState<AadhaarProfile | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [confirmExit, setConfirmExit] = useState(false)

  const isPhysio = profession === 'Physiotherapist'
  const registrationLabel = !isClinician ? 'NUID' : isPhysio ? 'Physio Reg. No.' : 'Medical Reg. No.'
  const last4 = aadhaar.length === 12 ? aadhaar.slice(8) : ''

  const run = async (action: () => Promise<void>) => {
    setBusy(true)
    setError(null)
    try {
      await action()
    } catch (e) {
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

  // Editing the Aadhaar number after an OTP went out starts that part over.
  const editAadhaar = (digits: string) => {
    setAadhaar(digits)
    setOtpSent(false)
    setOtp('')
    setProfile(null)
    setError(null)
  }

  const verifyRegistration = () =>
    run(async () => {
      setRegistry(
        isClinician
          ? await verifyCouncilRegistration({ isPhysiotherapist: isPhysio, registrationNumber: regNo, council: council! })
          : await verifyNuid(regNo),
      )
    })

  const sendOtp = () =>
    run(async () => {
      await sendAadhaarOtp(aadhaar)
      setOtpSent(true)
      setOtp('')
    })

  const verifyOtp = () =>
    run(async () => {
      setProfile(await verifyAadhaarOtp({ otp, isClinician, registeredName: registry?.registeredName ?? '' }))
    })

  const finish = () => {
    if (!registry || !profile) return
    // The portal guard moves on to the sign-up wizard once this is saved.
    saveIdentity({
      fullName: profile.name,
      dob: profile.dob,
      gender: profile.gender,
      address: profile.address,
      aadhaarLast4: aadhaar.slice(-4),
      registrationLabel,
      registrationNumber: regNo.trim().toUpperCase(),
      council: registry.council,
      qualification: registry.qualification,
      profession: profession ?? undefined,
    })
  }

  const next = () => {
    setStepIndex(1)
    setError(null)
  }

  // The bottom button's label and action for the current step (null = disabled).
  let primary: [string, (() => void) | null]
  if (stepIndex === 0) {
    if (registry) primary = ['Continue', next]
    else {
      const ready = regNo.trim() !== '' && (!isClinician || (profession != null && council != null))
      primary = [isClinician ? 'Verify registration' : 'Verify NUID', ready ? verifyRegistration : null]
    }
  } else if (!otpSent) primary = ['Send OTP', aadhaar.length === 12 && consent ? sendOtp : null]
  else if (!profile) primary = ['Verify OTP', otp.length === 6 ? verifyOtp : null]
  else primary = ['Continue to profile', finish]

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
              title={isClinician ? 'Verify your registration' : 'Verify your NUID'}
              subtitle={
                isClinician
                  ? 'We check your registration number against the council register before you can practise on ALLCURO.'
                  : "Enter your Nurse Unique ID (NUID) from the Indian Nursing Council's NRTS. We fetch your registration from the council's records."
              }
            />
            {isClinician && (
              <>
                <div>
                  <SectionLabel id="pa-prof-label">I am a</SectionLabel>
                  <ChoiceChips
                    labelledBy="pa-prof-label"
                    options={PROFESSIONS}
                    value={profession}
                    onChange={(p) =>
                      editRegistration(() => {
                        if (p !== profession) setCouncil(null)
                        setProfession(p as ClinicianProfession)
                      })
                    }
                  />
                </div>
                {profession && (
                  <div>
                    <SectionLabel id="pa-council-label">{isPhysio ? 'Registered with' : 'Medical council'}</SectionLabel>
                    <ChoiceChips
                      labelledBy="pa-council-label"
                      options={COUNCIL_OPTIONS[profession]}
                      value={council}
                      onChange={(c) => editRegistration(() => setCouncil(c))}
                    />
                  </div>
                )}
              </>
            )}
            <PField
              label={isClinician ? (isPhysio ? 'Physiotherapy registration number' : 'Doctor registration number') : 'NUID (Nurse Unique ID)'}
              hint={isClinician ? 'Letters, digits, / or -' : 'Letters and digits only'}
            >
              <input
                value={regNo}
                placeholder={isClinician ? 'e.g. KMC-123456' : 'As shown on your NRTS registration'}
                maxLength={20}
                autoCapitalize="characters"
                autoComplete="off"
                onChange={(e) => {
                  const v = e.target.value.replace(isClinician ? /[^A-Za-z0-9/-]/g : /[^A-Za-z0-9]/g, '').slice(0, 20)
                  editRegistration(() => setRegNo(v))
                }}
              />
            </PField>
            {error && <ErrorBanner message={error} />}
            {registry && (
              <VerifiedCard
                title={isClinician ? 'Registration verified' : 'NUID verified'}
                rows={[
                  ['Name', registry.registeredName],
                  ['Council', registry.council],
                  ['Qualification', registry.qualification],
                  ['Registered since', String(registry.registeredSince)],
                ]}
              />
            )}
          </>
        ) : (
          <>
            <StepHeader
              title="Aadhaar verification"
              subtitle="We confirm your identity with Aadhaar e-KYC. Your name, date of birth, gender and address are taken from Aadhaar and can't be edited later."
            />
            <PField label="Aadhaar number" hint={profile ? undefined : '12 digits, as printed on your Aadhaar card'}>
              <input
                value={groupAadhaar(aadhaar)}
                placeholder="XXXX XXXX XXXX"
                inputMode="numeric"
                autoComplete="off"
                readOnly={profile != null}
                maxLength={14}
                onChange={(e) => editAadhaar(digitsOnly(e.target.value).slice(0, 12))}
              />
            </PField>
            {!profile && (
              <ConsentBox checked={consent} onChange={setConsent}>
                I consent to ALLCURO using my Aadhaar number to fetch my e-KYC details from UIDAI for identity verification.
              </ConsentBox>
            )}
            {otpSent && !profile && (
              <div className="pa-otp-field">
                <PField label="OTP sent to your Aadhaar-linked mobile">
                  <input
                    value={otp}
                    placeholder="6-digit OTP"
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    autoFocus
                    maxLength={6}
                    onChange={(e) => {
                      setOtp(digitsOnly(e.target.value).slice(0, 6))
                      setError(null)
                    }}
                  />
                </PField>
                <div className="pa-otp-meta">
                  <span>
                    Sent for Aadhaar XXXX XXXX {last4} · Demo OTP: <strong>{AADHAAR_DEMO_OTP}</strong>
                  </span>
                  <button type="button" className="p-btn p-btn-ghost p-btn-sm" disabled={busy} onClick={sendOtp}>
                    Resend
                  </button>
                </div>
              </div>
            )}
            {error && <ErrorBanner message={error} />}
            {profile && (
              <>
                <VerifiedCard
                  title="Aadhaar verified"
                  rows={[
                    ['Name', profile.name],
                    ['Date of birth', formatDob(profile.dob)],
                    ['Gender', profile.gender],
                    ['Address', profile.address],
                    ['Aadhaar', `XXXX XXXX ${last4}`],
                  ]}
                />
                <p className="pa-match">
                  <PIcon name="check" size={16} /> Name matches your {registrationLabel} record
                </p>
              </>
            )}
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
            <input value={form.holder} onChange={set('holder')} placeholder="e.g. Sanjeevani Care / Priya Sharma" autoComplete="name" />
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
  const city = (s.signup.city as string | undefined) || 'Bengaluru'
  const hasBank = s.bank != null

  const practitionerName = identity
    ? identity.profession === 'Doctor' && !identity.fullName.startsWith('Dr.')
      ? `Dr. ${identity.fullName}`
      : identity.fullName
    : s.name || (isClinician ? 'Dr. Arjun Rao' : 'Priya Sharma')
  const name = isCentre ? s.name || 'Sanjeevani Elder Care Sanctuary' : practitionerName
  const subtitle = isCentre
    ? `Homecare Centre Partner · ${city}`
    : isClinician
      ? `${identity?.profession ?? 'Doctor / Physiotherapist'}${identity?.qualification ? ` (${identity.qualification})` : ''} · ${city}`
      : `Registered Nurse (${identity?.qualification ?? 'GNM'}) · ${city}`
  const home = usesNurseShell(s.role) ? PR.nurseHome : PR.centreHome

  const [statusLabel, statusTone] = isCentre ? CENTRE_STATUS[s.centreStatus] : NURSE_STATUS[practitionerStatus(s)]

  const tiles: SetupTile[] = isCentre
    ? [
        { icon: 'shield', title: 'Compliance & Legal NOCs', subtitle: 'CEA, Fire Safety, Biomedical waste clearance', done: false, to: PR.centreCompliance },
        { icon: 'users', title: 'Staff Roster & Duty Nurses', subtitle: 'Manage nurse-to-patient staff ratios', done: true, to: PR.centreStaff },
        { icon: 'bed', title: 'Room Inventory & Pricing', subtitle: 'AC private rooms, packages and photos', done: true, to: PR.centreRooms },
        { icon: 'store', title: 'Public Listing Management', subtitle: 'Facility amenities, photos and brochure', done: true, to: PR.centreListing },
        { icon: 'bank', title: 'Bank Account & Payout Setup', subtitle: 'Direct Razorpay Route deposits', done: hasBank, to: PR.bankAccount },
      ]
    : [
        { icon: 'file', title: 'Document Vault', subtitle: 'Degree certificates & HPR registry', done: true, to: PR.nurseDocuments },
        { icon: 'heart', title: 'Medical Fitness & TB Report', subtitle: 'Upload annual fitness self-declaration', done: false, to: PR.nurseDocuments },
        { icon: 'bank', title: 'Bank Account & Payout Setup', subtitle: 'Direct Razorpay Route deposits', done: hasBank, to: PR.bankAccount },
        { icon: 'star', title: 'Skills & Specialisations', subtitle: 'ICU, Tracheostomy, Palliative Care tags', done: true, to: PR.nurseAvailability },
      ]

  // Submit for the admin's review. Approval itself happens in the admin panel.
  const st = isCentre ? s.centreStatus : practitionerStatus(s)
  const canSubmit = st === 'onboarding' || st === 'rejected'
  const submitForReview = () => (isCentre ? setCentreStatus('pendingReview') : setPractitionerStatus('underReview'))

  return (
    <>
      <PPageHead title={isCentre ? 'Centre Profile' : isClinician ? 'Clinician Profile' : 'Nurse Profile'} back={home} />
      <PBody narrow>
        <div className="pa-profile-head">
          <span className="pa-profile-avatar" aria-hidden="true">
            {initials(name) || 'AP'}
          </span>
          <div className="p-row-grow">
            <h2>{name}</h2>
            <p className="p-muted">{subtitle}</p>
            {s.phone && <p className="p-muted">{formatPhone(s.phone)}</p>}
          </div>
        </div>

        {identity && (
          <VerifiedCard
            title="Verified identity"
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
              : 'Complete remaining profile modules anytime. Verified profiles receive 3x more bookings.'}
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
