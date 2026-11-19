import { persistedStore } from '../lib/store'

// Saved care addresses, mirroring allcuro/lib/features/location
// (UserAddress + LocationViewModel).

export type AddressTag = 'home' | 'work' | 'parents' | 'other'

export interface UserAddress {
  id: string
  title: string
  addressLine: string
  locality: string
  arrivalTime: string
  tag: AddressTag
}

export const fullAddress = (a: UserAddress) => [a.addressLine, a.locality].filter(Boolean).join(', ')

/** Shown until the visitor adds an address or uses their location. */
export const UNSET_ADDRESS: UserAddress = {
  id: 'unset',
  title: 'Set your location',
  addressLine: 'Add your address',
  locality: '',
  arrivalTime: '',
  tag: 'other',
}

interface LocationState {
  currentId: string
  saved: UserAddress[]
}

const store = persistedStore<LocationState>('location', { currentId: '', saved: [] })

// Older builds seeded three sample addresses; drop them from saved browsers.
const OLD_SAMPLE_LINES = new Set([
  'Flat 402, Green Glen Palms, 12th Main',
  'Sanjeevani Villa, 4th Cross, 100ft Road',
  'Prestige Tech Park, Outer Ring Road',
])
if (store.get().saved.some((a) => OLD_SAMPLE_LINES.has(a.addressLine)))
  store.set((s) => ({ ...s, saved: s.saved.filter((a) => !OLD_SAMPLE_LINES.has(a.addressLine)) }))

export function useLocation() {
  const { currentId, saved } = store.use()
  return { current: saved.find((a) => a.id === currentId) ?? saved[0] ?? UNSET_ADDRESS, saved }
}

export const selectAddress = (id: string) => store.set((s) => ({ ...s, currentId: id }))

const TITLES: Record<AddressTag, string> = { home: 'Home', work: 'Work', parents: "Parents' Home", other: 'Other' }

export function addAddress({
  houseNo,
  landmark,
  locality,
  tag,
}: {
  houseNo: string
  landmark: string
  locality: string
  tag: AddressTag
}) {
  const address: UserAddress = {
    id: `addr-${Date.now()}`,
    title: TITLES[tag],
    addressLine: landmark.trim() ? `${houseNo.trim()}, ${landmark.trim()}` : houseNo.trim(),
    locality: locality.trim(),
    arrivalTime: '',
    tag,
  }
  store.set((s) => ({ currentId: address.id, saved: [address, ...s.saved] }))
  return address
}

/**
 * The browser's real location. There is no reverse-geocoding service yet, so
 * the address shows the coordinates; the visitor can still add a full address.
 * Throws with a readable message when location is unavailable or denied.
 */
export async function detectGpsLocation() {
  if (!('geolocation' in navigator)) throw new Error('Your browser can’t share its location. Please add the address instead.')
  const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
    navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000 }),
  ).catch(() => {
    throw new Error('We couldn’t get your location. Allow location access, or add the address instead.')
  })
  const gps: UserAddress = {
    id: 'gps',
    title: 'Current Location',
    addressLine: 'Current location',
    locality: `${pos.coords.latitude.toFixed(5)}, ${pos.coords.longitude.toFixed(5)}`,
    arrivalTime: '',
    tag: 'other',
  }
  store.set((s) => ({ currentId: gps.id, saved: [gps, ...s.saved.filter((a) => a.id !== gps.id)] }))
}

// ---- City for signed-out visitors ----
// Before signing in a visitor only picks a city (from the admin's "Cities
// served" list, site.cities); saved addresses are shown once they sign in.

const cityStore = persistedStore<string>('city', '')

/** The visitor's chosen city, or the first city served. */
export function useCity(fallback: string) {
  return cityStore.use() || fallback
}

export const selectCity = (city: string) => cityStore.set(city)
