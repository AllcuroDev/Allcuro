import { confirmOtp, requestOtp, signOut } from '../lib/phoneAuth'
import { digitsOnly } from '../lib/format'
import { memoryStore, persistedStore } from '../lib/store'
import { supabase } from '../lib/supabase'

// Customer phone + OTP sign-in through Supabase Auth (lib/phoneAuth.ts), with
// the profile kept in public.profiles. The local store is only a cache so the
// header renders instantly; the Supabase session is the source of truth.

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

interface ProfileRow {
  full_name: string | null
  phone: string | null
  email: string | null
  city: string | null
  emergency_contact: string | null
  kyc_status: string | null
}

/** Reads public.profiles for the signed-in user into the local cache. */
async function loadProfile(userId: string, phoneFallback = '') {
  if (!supabase) return 'authenticated' as const
  const { data } = await supabase
    .from('profiles')
    .select('full_name, phone, email, city, emergency_contact, kyc_status')
    .eq('id', userId)
    .maybeSingle<ProfileRow>()
  const name = data?.full_name && data.full_name !== 'Member' ? data.full_name : ''
  const profile: Profile = {
    name,
    phone: digitsOnly(data?.phone ?? phoneFallback).slice(-10),
    email: data?.email ?? '',
    // profiles.city defaults to 'Bengaluru'; only a named profile counts as set up.
    city: name ? (data?.city ?? '') : '',
    emergencyContact: data?.emergency_contact ?? '',
    kycTier: data?.kyc_status === 'verified' ? 'id_verified' : 'light',
  }
  const status: AuthStatus = profile.name && profile.city ? 'onboarded' : 'authenticated'
  auth.set({ status, profile })
  return status
}

// Keep the cache in step with the real session (expired, signed out in another tab…).
if (supabase) {
  const db = supabase
  void db.auth.getSession().then(({ data }) => {
    const user = data.session?.user
    if (!user) auth.set((s) => ({ ...s, status: 'unauthenticated' }))
    else void loadProfile(user.id, user.phone ?? '')
  })
  db.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT') auth.set((s) => ({ ...s, status: 'unauthenticated' }))
  })
}

export async function sendOtp(phone: string) {
  try {
    await requestOtp(phone)
  } catch (e) {
    throw new AuthError(e instanceof Error ? e.message : 'Could not send the code.')
  }
}

export async function verifyOtp(phone: string, otp: string) {
  let userId: string
  try {
    userId = await confirmOtp(phone, otp)
  } catch (e) {
    throw new AuthError(e instanceof Error ? e.message : 'Could not verify the code.')
  }
  return loadProfile(userId, phone)
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
  if (!supabase) throw new AuthError('Sign-in is unavailable right now.')
  const { data: session } = await supabase.auth.getSession()
  const userId = session.session?.user.id
  if (!userId) throw new AuthError('Your session has expired. Please sign in again.')
  const { error } = await supabase
    .from('profiles')
    .update({
      full_name: details.name.trim(),
      email: details.email.trim() || null,
      city: details.city.trim(),
      emergency_contact: details.emergencyContact.trim() || null,
    })
    .eq('id', userId)
  if (error) throw new AuthError('Could not save your profile. Please try again.')
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

export const logout = () => {
  auth.set({ status: 'unauthenticated', profile: null })
  void signOut()
}

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
