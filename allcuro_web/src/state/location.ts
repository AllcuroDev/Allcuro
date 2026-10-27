import { delay, persistedStore } from '../lib/store'

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

export const fullAddress = (a: UserAddress) => `${a.addressLine}, ${a.locality}`

const initialAddresses: UserAddress[] = [
  {
    id: 'addr-1',
    title: 'Home',
    addressLine: 'Flat 402, Green Glen Palms, 12th Main',
    locality: 'Indiranagar, Bengaluru',
    arrivalTime: '44 mins',
    tag: 'home',
  },
  {
    id: 'addr-2',
    title: "Parents' Home",
    addressLine: 'Sanjeevani Villa, 4th Cross, 100ft Road',
    locality: 'Indiranagar, Bengaluru',
    arrivalTime: '38 mins',
    tag: 'parents',
  },
  {
    id: 'addr-3',
    title: 'Work / Office',
    addressLine: 'Prestige Tech Park, Outer Ring Road',
    locality: 'Marathahalli, Bengaluru',
    arrivalTime: '52 mins',
    tag: 'work',
  },
]

interface LocationState {
  currentId: string
  saved: UserAddress[]
}

const store = persistedStore<LocationState>('location', { currentId: 'addr-1', saved: initialAddresses })

export function useLocation() {
  const { currentId, saved } = store.use()
  return { current: saved.find((a) => a.id === currentId) ?? saved[0], saved }
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
    locality: locality.trim() || 'Indiranagar, Bengaluru',
    arrivalTime: '44 mins',
    tag,
  }
  store.set((s) => ({ currentId: address.id, saved: [address, ...s.saved] }))
  return address
}

/** Simulated GPS fix, as in the app — there is no reverse-geocoding service yet. */
export async function detectGpsLocation() {
  await delay(700)
  const gps: UserAddress = {
    id: 'gps',
    title: 'Current Location',
    addressLine: '12th Main Road, HAL 2nd Stage',
    locality: 'Indiranagar, Bengaluru',
    arrivalTime: '44 mins',
    tag: 'other',
  }
  store.set((s) => ({ currentId: gps.id, saved: [gps, ...s.saved.filter((a) => a.id !== gps.id)] }))
}
