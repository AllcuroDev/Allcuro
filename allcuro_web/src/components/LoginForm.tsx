import { useEffect, useState, type FormEvent } from 'react'
import { digitsOnly, formatPhone } from '../lib/format'
import {
  AuthError,
  DEMO_OTP,
  completeOnboarding,
  onboardingCities,
  sendOtp,
  useAuth,
  verifyOtp,
} from '../state/auth'
import { seedDemoBookings } from '../state/bookings'
import { selectAddress, useLocation } from '../state/location'
import { ArrowIcon, ShieldIcon } from './Icons'
import { Field, Select, Spinner } from './ui'

// Phone → OTP → (first time only) profile setup. Mirrors PhoneAuthScreen +
// OnboardingScreen in the app; used by /login and by the "Login to book" dialog.

type Step = 'phone' | 'otp' | 'profile'

const RESEND_SECONDS = 30
const errorText = (e: unknown, fallback: string) => (e instanceof AuthError ? e.message : fallback)

export function LoginForm({ onDone, headingId }: { onDone: () => void; headingId: string }) {
  const { status } = useAuth()
  // Signed in earlier but never finished setup: go straight to the profile step.
  const [step, setStep] = useState<Step>(status === 'authenticated' ? 'profile' : 'phone')
  const [phone, setPhone] = useState('')

  return (
    <div className="login-form">
      {step === 'phone' && (
        <PhoneStep
          headingId={headingId}
          initial={phone}
          onSent={(p) => {
            setPhone(p)
            setStep('otp')
          }}
        />
      )}
      {step === 'otp' && (
        <OtpStep
          headingId={headingId}
          phone={phone}
          onEdit={() => setStep('phone')}
          onVerified={(result) => {
            seedDemoBookings(phone)
            if (result === 'onboarded') onDone()
            else setStep('profile')
          }}
        />
      )}
      {step === 'profile' && <ProfileStep headingId={headingId} onDone={onDone} />}
    </div>
  )
}

function PhoneStep({
  headingId,
  initial,
  onSent,
}: {
  headingId: string
  initial: string
  onSent: (phone: string) => void
}) {
  const [phone, setPhone] = useState(initial)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const valid = digitsOnly(phone).length === 10

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      await sendOtp(phone)
      onSent(digitsOnly(phone))
    } catch (err) {
      setError(errorText(err, 'Something went wrong. Please try again.'))
    } finally {
      setBusy(false)
    }
  }

  return (
    <form onSubmit={submit} noValidate>
      <h2 id={headingId} className="login-title">
        Healthcare at your doorstep
      </h2>
      <p className="login-sub">Enter your phone number to access certified care.</p>

      <label className="field">
        <span className="field-label">Mobile Number</span>
        <span className="phone-input">
          <span className="phone-prefix">🇮🇳 +91</span>
          <input
            className="input"
            type="tel"
            inputMode="numeric"
            autoComplete="tel-national"
            placeholder="98765 43210"
            maxLength={11}
            value={phone}
            onChange={(e) => setPhone(digitsOnly(e.target.value).slice(0, 10))}
            autoFocus
            aria-invalid={!!error}
          />
        </span>
      </label>
      {error && <p className="form-error">{error}</p>}

      <button type="submit" className="btn btn-primary btn-lg btn-block" disabled={!valid || busy}>
        {busy ? <Spinner /> : <>Continue <ArrowIcon /></>}
      </button>
      <p className="login-fine">
        <ShieldIcon size={16} /> We only use your number for booking updates and OTPs.
      </p>
    </form>
  )
}

function OtpStep({
  headingId,
  phone,
  onEdit,
  onVerified,
}: {
  headingId: string
  phone: string
  onEdit: () => void
  onVerified: (result: 'onboarded' | 'authenticated') => void
}) {
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [cooldown, setCooldown] = useState(RESEND_SECONDS)

  useEffect(() => {
    if (cooldown <= 0) return
    const id = setTimeout(() => setCooldown((c) => c - 1), 1000)
    return () => clearTimeout(id)
  }, [cooldown])

  const verify = async (value = code) => {
    setBusy(true)
    setError('')
    try {
      onVerified(await verifyOtp(phone, value))
    } catch (err) {
      setError(errorText(err, 'Verification failed. Please try again.'))
      setBusy(false)
    }
  }

  const resend = async () => {
    setError('')
    try {
      await sendOtp(phone)
      setCooldown(RESEND_SECONDS)
    } catch (err) {
      setError(errorText(err, 'Could not resend code. Try again later.'))
    }
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        verify()
      }}
      noValidate
    >
      <h2 id={headingId} className="login-title">
        Verify OTP
      </h2>
      <p className="login-sub">
        Code sent to <strong>{formatPhone(phone)}</strong>.{' '}
        <button type="button" className="link-btn" onClick={onEdit}>
          Edit
        </button>
      </p>

      <label className="field">
        <span className="field-label">Enter verification code</span>
        <input
          className="input otp-input"
          inputMode="numeric"
          autoComplete="one-time-code"
          maxLength={6}
          value={code}
          onChange={(e) => {
            const v = digitsOnly(e.target.value).slice(0, 6)
            setCode(v)
            if (v.length === 6) verify(v)
          }}
          autoFocus
          aria-invalid={!!error}
        />
      </label>
      {error && <p className="form-error">{error}</p>}

      <div className="otp-row">
        <button type="button" className="link-btn" onClick={() => setCode(DEMO_OTP)}>
          Demo mode: use {DEMO_OTP}
        </button>
        <button type="button" className="link-btn" disabled={cooldown > 0} onClick={resend}>
          {cooldown > 0 ? `Resend in ${cooldown}s` : 'Resend code'}
        </button>
      </div>

      <button type="submit" className="btn btn-primary btn-lg btn-block" disabled={code.length !== 6 || busy}>
        {busy ? <Spinner /> : 'Verify & Continue'}
      </button>
    </form>
  )
}

function ProfileStep({ headingId, onDone }: { headingId: string; onDone: () => void }) {
  const { profile } = useAuth()
  const { saved } = useLocation()
  const [name, setName] = useState(profile?.name ?? '')
  const [email, setEmail] = useState(profile?.email ?? '')
  const [city, setCity] = useState(profile?.city || onboardingCities[0])
  const [emergency, setEmergency] = useState(profile?.emergencyContact ?? '')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      await completeOnboarding({ name, email, city, emergencyContact: emergency })
      // Point the care location at a saved address in the chosen area, if there is one.
      const match = saved.find((a) => a.locality === city)
      if (match) selectAddress(match.id)
      onDone()
    } catch (err) {
      setError(errorText(err, 'Could not complete profile setup. Please try again.'))
      setBusy(false)
    }
  }

  return (
    <form onSubmit={submit} noValidate>
      <span className="eyebrow">ALLCURO PROFILE</span>
      <h2 id={headingId} className="login-title">
        Complete Your Setup
      </h2>
      <p className="login-sub">
        One-time details to unlock verified home nursing visits, care centre stays and emergency dispatch.
      </p>

      <Field label="Full Name" value={name} onChange={(e) => setName(e.target.value)} autoComplete="name" autoFocus />
      <Field
        label="Email Address (Optional)"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        autoComplete="email"
      />
      <Select
        label="Primary Care Location (City / Area)"
        options={onboardingCities}
        value={city}
        onChange={(e) => setCity(e.target.value)}
      />
      <Field
        label="Emergency Family Contact (For Safety & SOS)"
        placeholder="+91 91234 56789 (Brother)"
        value={emergency}
        onChange={(e) => setEmergency(e.target.value)}
        hint="Used for 24/7 SOS safety alerts during home visits."
      />
      {error && <p className="form-error">{error}</p>}

      <button type="submit" className="btn btn-primary btn-lg btn-block" disabled={busy}>
        {busy ? <Spinner /> : 'Start Exploring Care'}
      </button>
    </form>
  )
}
