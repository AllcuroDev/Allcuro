import { useState } from 'react'
import { useLocation } from '../state/location'
import { AddressPicker } from './AddressPicker'
import { ChevronDownIcon, PinIcon } from './Icons'

// The app header's location line ("Home · Indiranagar… · Nurse in 44 mins"):
// shows the selected care address and opens the address picker.
export function LocationButton() {
  const { current } = useLocation()
  const [open, setOpen] = useState(false)
  return (
    <>
      <button type="button" className="loc-btn" onClick={() => setOpen(true)} aria-label={`Care location: ${current.title}, ${current.locality}. Change`}>
        <span className="loc-icon">
          <PinIcon size={18} />
        </span>
        <span className="loc-text">
          <span className="loc-top">
            <strong>{current.title}</strong>
            <span className="loc-eta">Nurse in {current.arrivalTime}</span>
          </span>
          <span className="loc-line">{current.addressLine}, {current.locality}</span>
        </span>
        <ChevronDownIcon size={18} />
      </button>
      {open && <AddressPicker onClose={() => setOpen(false)} />}
    </>
  )
}
