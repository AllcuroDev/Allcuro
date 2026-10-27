import { useState } from 'react'
import {
  addAddress,
  detectGpsLocation,
  fullAddress,
  selectAddress,
  useLocation,
  type AddressTag,
} from '../state/location'
import { CheckIcon, NavigateIcon, PinIcon, PlusIcon } from './Icons'
import { Field, Modal, Spinner } from './ui'
import { toast } from '../lib/toast'

// The app's LocationSheet: pick a saved address, use GPS, or add a new one.

const TAGS: { tag: AddressTag; label: string }[] = [
  { tag: 'home', label: 'Home' },
  { tag: 'parents', label: 'Parents' },
  { tag: 'work', label: 'Work' },
  { tag: 'other', label: 'Other' },
]

export function AddressPicker({ onClose }: { onClose: () => void }) {
  const { current, saved } = useLocation()
  const [adding, setAdding] = useState(false)
  const [detecting, setDetecting] = useState(false)
  const [form, setForm] = useState({ houseNo: '', landmark: '', locality: '', tag: 'home' as AddressTag })
  const [error, setError] = useState('')

  const useGps = async () => {
    setDetecting(true)
    await detectGpsLocation()
    setDetecting(false)
    toast('📍 Location updated to your current position')
    onClose()
  }

  const save = () => {
    if (!form.houseNo.trim()) {
      setError('Please enter flat / house number')
      return
    }
    addAddress(form)
    toast('📍 Address saved and selected')
    onClose()
  }

  return (
    <Modal onClose={onClose} labelledBy="addr-title">
      <h2 id="addr-title" className="login-title">
        Select care location
      </h2>
      <p className="login-sub">Nurses and deliveries are sent to this address.</p>

      <button type="button" className="addr-action" onClick={useGps} disabled={detecting}>
        <span className="addr-action-icon">{detecting ? <Spinner /> : <NavigateIcon size={18} />}</span>
        <span>
          <strong>{detecting ? 'Detecting your location…' : 'Use current location'}</strong>
          <small>Fastest nurse dispatch in your area</small>
        </span>
      </button>

      {!adding ? (
        <button type="button" className="addr-action" onClick={() => setAdding(true)}>
          <span className="addr-action-icon">
            <PlusIcon />
          </span>
          <span>
            <strong>Add new address</strong>
            <small>Home, clinic, hospital or a relative’s house</small>
          </span>
        </button>
      ) : (
        <div className="addr-form">
          <Field
            label="Flat / House No / Building"
            value={form.houseNo}
            onChange={(e) => setForm({ ...form, houseNo: e.target.value })}
            autoFocus
          />
          <Field label="Street / Landmark" value={form.landmark} onChange={(e) => setForm({ ...form, landmark: e.target.value })} />
          <Field
            label="Area & City"
            placeholder="Indiranagar, Bengaluru"
            value={form.locality}
            onChange={(e) => setForm({ ...form, locality: e.target.value })}
          />
          <span className="field-label">Save as</span>
          <div className="chip-row">
            {TAGS.map((t) => (
              <button
                key={t.tag}
                type="button"
                className={`chip ${form.tag === t.tag ? 'is-active' : ''}`}
                aria-pressed={form.tag === t.tag}
                onClick={() => setForm({ ...form, tag: t.tag })}
              >
                {t.label}
              </button>
            ))}
          </div>
          {error && <p className="form-error">{error}</p>}
          <div className="row-actions">
            <button type="button" className="btn btn-outline" onClick={() => setAdding(false)}>
              Cancel
            </button>
            <button type="button" className="btn btn-primary" onClick={save}>
              Save address
            </button>
          </div>
        </div>
      )}

      <span className="eyebrow addr-saved-label">SAVED ADDRESSES</span>
      <ul className="addr-list">
        {saved.map((a) => (
          <li key={a.id}>
            <button
              type="button"
              className={`addr-item ${a.id === current.id ? 'is-active' : ''}`}
              aria-pressed={a.id === current.id}
              onClick={() => {
                selectAddress(a.id)
                toast(`📍 Location changed to ${a.title}`)
                onClose()
              }}
            >
              <PinIcon />
              <span>
                <strong>{a.title}</strong>
                <small>{fullAddress(a)}</small>
              </span>
              {a.id === current.id && <CheckIcon />}
            </button>
          </li>
        ))}
      </ul>
    </Modal>
  )
}
