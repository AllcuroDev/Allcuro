import { site } from '../data/site'
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

/** Locality + city for a GPS fix, from a key-less client-side reverse geocoder. */
async function reverseGeocode(lat: number, lng: number): Promise<{ area: string; city: string } | null> {
  try {
    const res = await fetch(
      `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=en`,
    )
    if (!res.ok) return null
    const d = (await res.json()) as { locality?: string; city?: string; principalSubdivision?: string; postcode?: string }
    const city = d.city || d.principalSubdivision || ''
    // Neighbourhood when the geocoder knows it, else the PIN code.
    const area = d.locality && d.locality !== city ? d.locality : d.postcode || ''
    return city || area ? { area, city } : null
  } catch {
    return null
  }
}

/** Served city ("Delhi-NCR") matching a geocoded city name ("Gurugram"), if any. */
const CITY_ALIASES: Record<string, string[]> = {
  bengaluru: ['bengaluru', 'bangalore'],
  'delhi-ncr': ['delhi', 'gurugram', 'gurgaon', 'noida', 'ghaziabad', 'faridabad'],
  mumbai: ['mumbai', 'bombay', 'thane', 'navi mumbai'],
  hyderabad: ['hyderabad', 'secunderabad'],
}
function servedCity(name: string, served: string[]) {
  const n = name.toLowerCase()
  return served.find((c) => {
    const aliases = CITY_ALIASES[c.toLowerCase()] ?? [c.toLowerCase()]
    return aliases.some((a) => n.includes(a))
  })
}

/**
 * The browser's real location, named by reverse geocoding when it can be
 * (falls back to coordinates). Becomes the current address, and the city
 * shown to signed-out visitors when it is one we serve.
 * Throws with a readable message when location is unavailable or denied.
 */
export async function detectGpsLocation() {
  if (!('geolocation' in navigator)) throw new Error('Your browser can’t share its location. Please add the address instead.')
  const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
    navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }),
  ).catch(() => {
    throw new Error('We couldn’t get your location. Allow location access, or add the address instead.')
  })
  const { latitude, longitude } = pos.coords
  const place = await reverseGeocode(latitude, longitude)
  const gps: UserAddress = {
    id: 'gps',
    title: 'Current Location',
    addressLine: 'Current location',
    locality: place
      ? [place.area, place.city].filter(Boolean).join(', ')
      : `${latitude.toFixed(5)}, ${longitude.toFixed(5)}`,
    arrivalTime: '',
    tag: 'other',
  }
  store.set((s) => ({ currentId: gps.id, saved: [gps, ...s.saved.filter((a) => a.id !== gps.id)] }))
  const city = place?.city && servedCity(place.city, site.cities)
  if (city) cityStore.set(city)
  detectedStore.set(gps.locality)
}

let autoStarted = false
/**
 * Runs once when the site opens: finds the visitor's location unless they
 * already chose an address themselves. Fails quietly (they can still pick one).
 */
export function autoDetectLocation() {
  if (autoStarted) return
  autoStarted = true
  const { currentId, saved } = store.get()
  const chosen = saved.find((a) => a.id === currentId)
  if (chosen && chosen.id !== 'gps') return
  detectGpsLocation().catch(() => {})
}

// ---- City for signed-out visitors ----
// Before signing in a visitor only picks a city (from the admin's "Cities
// served" list, site.cities); saved addresses are shown once they sign in.

const cityStore = persistedStore<string>('city', '')

/** Area name from the last auto-detected location ("Indiranagar, Bengaluru"). */
const detectedStore = persistedStore<string>('detected', '')
export const useDetectedPlace = () => detectedStore.use()

/** The visitor's chosen city, or the first city served. */
export function useCity(fallback: string) {
  return cityStore.use() || fallback
}

export const selectCity = (city: string) => {
  cityStore.set(city)
  // A city picked by hand wins over the detected area.
  detectedStore.set('')
}
