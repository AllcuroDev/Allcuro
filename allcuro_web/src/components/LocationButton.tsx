import { useState } from 'react'
import { site } from '../data/site'
import { useAuth } from '../state/auth'
import { fullAddress, selectCity, useCity, useDetectedPlace, useLocation } from '../state/location'
import { toast } from '../lib/toast'
import { AddressPicker } from './AddressPicker'
import { CheckIcon, ChevronDownIcon, PinIcon } from './Icons'
import { Modal } from './ui'

// One-line location next to the ALLCURO name. Signed out: just the city, which
// the visitor can change. Signed in: the saved address in use
// ("Home · Indiranagar, Bengaluru"), opening the address picker.
export function LocationButton() {
  const { isLoggedIn } = useAuth()
  const { current } = useLocation()
  const city = useCity(site.cities[0] ?? 'Bengaluru')
  const detected = useDetectedPlace()
  const [open, setOpen] = useState(false)

  // Signed out: the auto-detected area when we have one, else the chosen city.
  const place = detected || city
  const label = isLoggedIn ? (current.id === 'gps' ? fullAddress(current) : `${current.title}, ${current.locality}`) : place
  return (
    <>
      <button type="button" className="loc-btn" onClick={() => setOpen(true)} aria-label={`Care location: ${label}. Change`}>
        <span className="loc-icon">
          <PinIcon size={16} />
        </span>
        <span className="loc-text">
          {isLoggedIn ? (
            <>
              {/* A detected location shows its street rather than "Current Location". */}
              <strong>{current.id === 'gps' && current.addressLine !== 'Current location' ? current.addressLine : current.title}</strong>
              {current.locality && <span className="loc-line"> · {current.locality}</span>}
            </>
          ) : (
            <strong>
              {/* "560038, Bengaluru": the PIN part hides on narrow phones so the city stays readable. */}
              {place.includes(', ') && <span className="loc-pre">{place.slice(0, place.lastIndexOf(', ') + 2)}</span>}
              {place.includes(', ') ? place.slice(place.lastIndexOf(', ') + 2) : place}
            </strong>
          )}
        </span>
        <ChevronDownIcon size={16} />
      </button>
      {open && (isLoggedIn ? <AddressPicker onClose={() => setOpen(false)} /> : <CityPicker current={city} onClose={() => setOpen(false)} />)}
    </>
  )
}

function CityPicker({ current, onClose }: { current: string; onClose: () => void }) {
  return (
    <Modal onClose={onClose} labelledBy="city-title">
      <h2 id="city-title" className="login-title">
        Select your city
      </h2>
      <p className="login-sub">Sign in to save the exact address for visits and deliveries.</p>
      <ul className="addr-list">
        {site.cities.map((c) => (
          <li key={c}>
            <button
              type="button"
              className={`addr-item ${c === current ? 'is-active' : ''}`}
              aria-pressed={c === current}
              onClick={() => {
                selectCity(c)
                toast(`📍 Showing care in ${c}`)
                onClose()
              }}
            >
              <PinIcon />
              <span>
                <strong>{c}</strong>
              </span>
              {c === current && <CheckIcon />}
            </button>
          </li>
        ))}
      </ul>
    </Modal>
  )
}
