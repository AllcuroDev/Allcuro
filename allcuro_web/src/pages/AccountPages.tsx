import { useEffect, useState } from 'react'
import { AddressPicker } from '../components/AddressPicker'
import { ArrowIcon, LogoutIcon, PinIcon, ShieldIcon } from '../components/Icons'
import { Link } from '../components/Link'
import { LoginForm } from '../components/LoginForm'
import { Avatar, Field, Modal, PageHead, Select } from '../components/ui'
import { toast } from '../lib/toast'
import { site } from '../data/site'
import { formatPhone } from '../lib/format'
import { navigate, useQuery } from '../router'
import { completeOnboarding, logout, onboardingCities, useAuth } from '../state/auth'
import { isActive, useBookings } from '../state/bookings'
import { fullAddress, useLocation } from '../state/location'

/** Only same-site paths, so `?next=` can't send people elsewhere. */
const safeNext = (next: string | null) => (next && next.startsWith('/') && !next.startsWith('//') ? next : '/bookings')

/** Phone + OTP sign-in and first-time setup (the app's PhoneAuthScreen + OnboardingScreen). */
export function LoginPage() {
  const { status } = useAuth()
  const next = safeNext(useQuery('next'))

  // Already fully signed in: nothing to do here.
  useEffect(() => {
    if (status === 'onboarded') navigate(next, { replace: true })
  }, [status, next])

  return (
    <div className="container page login-page">
      <div className="login-card panel">
        <LoginForm headingId="login-title" onDone={() => navigate(next, { replace: true })} />
      </div>
      <aside className="login-aside">
        <h2>Why families trust ALLCURO</h2>
        <ul className="list-yes">
          <li>
            <ShieldIcon size={18} /> <span>Police-verified, HPR-registered nurses and caregivers</span>
          </li>
          <li>
            <ShieldIcon size={18} /> <span>Live tracking and a visit OTP for every home visit</span>
          </li>
          <li>
            <ShieldIcon size={18} /> <span>Clear prices before you pay — no surprise charges</span>
          </li>
          <li>
            <ShieldIcon size={18} /> <span>24/7 care desk on {site.phoneDisplay}</span>
          </li>
        </ul>
      </aside>
    </div>
  )
}

/** Shown in place of account-only pages for guests. */
export function SignInPrompt({ reason }: { reason: string }) {
  const here = window.location.pathname + window.location.search
  return (
    <div className="empty">
      <p>{reason}</p>
      <Link to={`/login?next=${encodeURIComponent(here)}`} className="btn btn-primary btn-lg">
        Sign in with phone <ArrowIcon />
      </Link>
    </div>
  )
}

/** Member profile, KYC tier, saved addresses and sign-out (the app's ProfileScreen). */
export function ProfilePage() {
  const { profile, isLoggedIn, status } = useAuth()
  const { current, saved } = useLocation()
  const bookings = useBookings()
  const [editing, setEditing] = useState(false)
  const [pickingAddress, setPickingAddress] = useState(false)

  if (!isLoggedIn || !profile) {
    return (
      <div className="container page page-narrow">
        <PageHead back="/" title="My Profile" />
        <SignInPrompt reason="Sign in to manage your profile, addresses and bookings." />
      </div>
    )
  }
  if (status === 'authenticated') {
    return (
      <div className="container page page-narrow">
        <div className="login-card panel">
          <LoginForm headingId="setup-title" onDone={() => toast('✓ Profile saved')} />
        </div>
      </div>
    )
  }

  const verified = profile.kycTier === 'id_verified'
  const active = bookings.filter(isActive).length

  return (
    <div className="container page page-narrow">
      <PageHead back="/" title="My Profile" subtitle="Account, addresses & safety contacts" />
      <div className="stack">
        <section className="panel profile-card">
          <Avatar name={profile.name} size={64} />
          <div>
            <h2>{profile.name}</h2>
            <p className="muted">{formatPhone(profile.phone)}</p>
            <span className={`status-pill ${verified ? '' : 'is-warm'}`}>
              {verified ? 'ID Verified · Live-in Bookings Unlocked' : 'Light KYC Active · Short Stays Unlocked'}
            </span>
          </div>
          <button type="button" className="btn btn-outline btn-sm" onClick={() => setEditing(true)}>
            Edit
          </button>
        </section>

        <section className="panel">
          <dl className="info-list">
            <div>
              <dt>Phone Number</dt>
              <dd>{formatPhone(profile.phone)}</dd>
            </div>
            <div>
              <dt>Email</dt>
              <dd>{profile.email || '—'}</dd>
            </div>
            <div>
              <dt>Care Location</dt>
              <dd>{profile.city}</dd>
            </div>
            <div>
              <dt>Emergency Family SOS</dt>
              <dd>{profile.emergencyContact || '—'}</dd>
            </div>
          </dl>
        </section>

        <section>
          <h2 className="step-title">Account & preferences</h2>
          <div className="menu-list">
            <Link to="/bookings" className="menu-row">
              <strong>My bookings</strong>
              <span>{active ? `${active} active` : 'View history'}</span>
            </Link>
            <button type="button" className="menu-row" onClick={() => setPickingAddress(true)}>
              <strong>Saved addresses</strong>
              <span>
                <PinIcon size={14} /> {current.title} · {saved.length} saved
              </span>
            </button>
            <button
              type="button"
              className="menu-row"
              onClick={() =>
                !verified &&
                toast('Our care desk verifies Aadhaar at your first live-in booking or high-value rental.', 'info')
              }
            >
              <strong>ID verification</strong>
              <span>{verified ? 'Verified' : 'Unlocks live-in bookings'}</span>
            </button>
            <a className="menu-row" href={site.phoneHref}>
              <strong>Help & SOS</strong>
              <span>24/7 · {site.phoneDisplay}</span>
            </a>
            <Link to="/#faq" className="menu-row">
              <strong>FAQs</strong>
              <span>Common questions about home care</span>
            </Link>
          </div>
        </section>

        <p className="muted small">Default care address: {fullAddress(current)}</p>

        <button
          type="button"
          className="btn btn-outline btn-lg btn-block btn-danger-outline"
          onClick={() => {
            logout()
            toast('Signed out', 'info')
            navigate('/')
          }}
        >
          <LogoutIcon /> Sign Out
        </button>
      </div>

      {editing && <EditProfile onClose={() => setEditing(false)} />}
      {pickingAddress && <AddressPicker onClose={() => setPickingAddress(false)} />}
    </div>
  )
}

function EditProfile({ onClose }: { onClose: () => void }) {
  const { profile } = useAuth()
  const [form, setForm] = useState({
    name: profile?.name ?? '',
    email: profile?.email ?? '',
    city: profile?.city ?? onboardingCities[0],
    emergencyContact: profile?.emergencyContact ?? '',
  })
  const [error, setError] = useState('')
  const cities = onboardingCities.includes(form.city) ? onboardingCities : [form.city, ...onboardingCities]

  return (
    <Modal onClose={onClose} labelledBy="edit-title">
      <h2 id="edit-title" className="login-title">
        Edit profile
      </h2>
      <form
        onSubmit={async (e) => {
          e.preventDefault()
          try {
            await completeOnboarding(form)
            toast('✓ Profile updated')
            onClose()
          } catch (err) {
            setError(err instanceof Error ? err.message : 'Could not save. Please try again.')
          }
        }}
      >
        <Field label="Full Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        <Field label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
        <Select label="Care Location" options={cities} value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
        <Field
          label="Emergency Family Contact"
          value={form.emergencyContact}
          onChange={(e) => setForm({ ...form, emergencyContact: e.target.value })}
        />
        {error && <p className="form-error">{error}</p>}
        <button type="submit" className="btn btn-primary btn-lg btn-block">
          Save changes
        </button>
      </form>
    </Modal>
  )
}
