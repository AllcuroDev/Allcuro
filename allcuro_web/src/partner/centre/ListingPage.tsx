import { useRef, useState } from 'react'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { PBody, PCard, PField, PIcon, PPageHead, Toggle } from '../ui'
import { listingStore, useListing } from './state'
import './centre.css'

// Listing management (features/centre/presentation/listing/listing_management_screen.dart):
// what families see on the centre's public listing. Edits are a draft until "Save changes".

export function CentreListingPage() {
  const saved = useListing()
  const [draft, setDraft] = useState(saved)
  const [tried, setTried] = useState(false)
  const photoInput = useRef<HTMLInputElement>(null)

  const priceErr = !draft.price.trim() ? 'Enter a price per day' : null
  const ratioErr = !/^\d+\s*:\s*\d+$/.test(draft.ratio.trim()) ? 'Use a ratio like 1:4' : null
  const dirty = JSON.stringify(draft) !== JSON.stringify(saved)

  const save = () => {
    setTried(true)
    if (priceErr || ratioErr) return
    listingStore.set({ ...draft, ratio: draft.ratio.replace(/\s/g, '') })
    toast('Listing updated')
  }

  return (
    <>
      <PPageHead title="Listing management" subtitle="What families see on your public listing" back={PR.centreHome} />
      <PBody narrow>
        <form
          className="pc-stack"
          noValidate
          onSubmit={(e) => {
            e.preventDefault()
            save()
          }}
        >
          <div className="p-form-grid">
            <PField label="Price per package (₹/day)" error={tried ? priceErr : null}>
              <span className="pc-prefix">
                <span aria-hidden="true">₹</span>
                <input value={draft.price} inputMode="numeric" onChange={(e) => setDraft({ ...draft, price: e.target.value.replace(/\D/g, '') })} />
              </span>
            </PField>
            <PField label="Staff-to-patient ratio" error={tried ? ratioErr : null}>
              <input value={draft.ratio} onChange={(e) => setDraft({ ...draft, ratio: e.target.value })} placeholder="1:4" />
            </PField>
          </div>

          <div className="pc-stack-sm">
            <span className="p-field-label">Photos</span>
            <button type="button" className="p-card pc-choose" onClick={() => photoInput.current?.click()}>
              <PIcon name="camera" size={18} />
              <span className="p-row-grow">
                {draft.photoCount} photo{draft.photoCount === 1 ? '' : 's'} uploaded
              </span>
              <span className="pc-link">Add more</span>
            </button>
            <input
              ref={photoInput}
              type="file"
              accept="image/*"
              multiple
              className="sr-only"
              tabIndex={-1}
              aria-hidden="true"
              onChange={(e) => {
                const n = e.target.files?.length ?? 0
                if (n) setDraft((d) => ({ ...d, photoCount: d.photoCount + n }))
                e.target.value = ''
              }}
            />
          </div>

          <div className="pc-stack-sm">
            <span className="p-field-label">Availability</span>
            <PCard className="pc-switch-card">
              <span className="p-row-grow" id="pc-accepting">
                Accepting new placements
              </span>
              <Toggle checked={draft.accepting} onChange={(v) => setDraft({ ...draft, accepting: v })} label="Accepting new placements" />
            </PCard>
          </div>

          <button type="submit" className="p-btn p-btn-primary p-btn-block pc-pill-btn" disabled={!dirty}>
            Save changes
          </button>
        </form>
      </PBody>
    </>
  )
}
