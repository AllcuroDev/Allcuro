import { digitsOnly } from '../lib/format'
import { delay, memoryStore, persistedStore } from '../lib/store'

// Phone + OTP sign-in and light-touch KYC, mirroring the app's AuthService /
// AuthViewModel (allcuro/lib/features/auth). Demo mode: there is no SMS
// gateway yet, so the code is always DEMO_OTP — same as the app.

export const DEMO_OTP = '123456'

export type AuthStatus = 'unauthenticated' | 'authenticated' | 'onboarded'

export interface Profile {
  name: string
  phone: string
  email: string
  city: string
  emergencyContact: string
  kycTier: 'light' | 'id_verified'
}

interface AuthState {
  status: AuthStatus
  profile: Profile | null
}

const auth = persistedStore<AuthState>('auth', { status: 'unauthenticated', profile: null })

export const useAuth = () => {
  const state = auth.use()
  return { ...state, isLoggedIn: state.status !== 'unauthenticated' }
}

export const isLoggedIn = () => auth.get().status !== 'unauthenticated'
export const currentPhone = () => auth.get().profile?.phone ?? ''

export class AuthError extends Error {}

export async function sendOtp(phone: string) {
  await delay(600)
  if (digitsOnly(phone).length !== 10) throw new AuthError('Enter a valid 10-digit phone number.')
}

export async function verifyOtp(phone: string, otp: string) {
  await delay(600)
  if (otp.trim() !== DEMO_OTP) throw new AuthError(`Incorrect code. Use demo code ${DEMO_OTP}.`)
  const digits = digitsOnly(phone)
  const previous = auth.get().profile
  // Signing back in with the same number keeps the profile set up last time.
  const returning = previous?.phone === digits && previous.name
  auth.set({
    status: returning ? 'onboarded' : 'authenticated',
    profile: returning
      ? previous
      : { name: '', phone: digits, email: '', city: '', emergencyContact: '', kycTier: 'light' },
  })
  return returning ? 'onboarded' : 'authenticated'
}

export const onboardingCities = [
  'Indiranagar, Bengaluru',
  'Koramangala, Bengaluru',
  'HSR Layout, Bengaluru',
  'Whitefield, Bengaluru',
  'Jayanagar, Bengaluru',
  'Bandra West, Mumbai',
  'South Delhi, New Delhi',
  'Jubilee Hills, Hyderabad',
]

export async function completeOnboarding(details: Pick<Profile, 'name' | 'email' | 'city' | 'emergencyContact'>) {
  if (!details.name.trim()) throw new AuthError('Please enter your full name.')
  if (!details.city.trim()) throw new AuthError('Please select your city / area.')
  await delay(500)
  auth.set((s) => ({
    status: 'onboarded',
    profile: {
      ...(s.profile ?? { phone: '', kycTier: 'light' }),
      name: details.name.trim(),
      email: details.email.trim(),
      city: details.city.trim(),
      emergencyContact: details.emergencyContact.trim(),
    },
  }))
}

export const setKycTier = (kycTier: Profile['kycTier']) =>
  auth.set((s) => (s.profile ? { ...s, profile: { ...s.profile, kycTier } } : s))

/** Keeps the profile so the same number signs straight back in, like the app's logout. */
export const logout = () => auth.set((s) => ({ ...s, status: 'unauthenticated' }))

// ---- "Login to book" prompt (the app's QuickLoginSheet) ----

interface LoginPrompt {
  title: string
  subtitle: string
  onSuccess?: () => void
}

export const loginPrompt = memoryStore<LoginPrompt | null>(null)

/** Runs `action` now if signed in; otherwise asks the visitor to sign in first and runs it after. */
export function requireLogin(
  action: () => void,
  {
    title = 'Login to Book',
    subtitle = 'Verify your mobile number to proceed with booking',
  }: { title?: string; subtitle?: string } = {},
) {
  if (isLoggedIn()) action()
  else loginPrompt.set({ title, subtitle, onSuccess: action })
}
