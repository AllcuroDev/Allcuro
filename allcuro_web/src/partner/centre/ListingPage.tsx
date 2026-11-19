import { useState } from 'react'
import { Link } from '../../components/Link'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { usePartnerSession } from '../session'
import { PBody, PCard, PField, PIcon, PPageHead, Toggle } from '../ui'
import { listingFrom, saveListing } from './state'
import './centre.css'

// Listing management (features/centre/presentation/listing/listing_management_screen.dart):
// the centre's listing preferences, saved on its partner row. Edits are a
// draft until "Save changes". ALLCURO sets the final listed price; photos are
// managed on the public profile page.

export function CentreListingPage() {
  const s = usePartnerSession()
  const saved = listingFrom(s)
  const [draft, setDraft] = useState(saved)
  const [tried, setTried] = useState(false)

  const priceErr = !draft.price.trim() ? 'Enter a price per day' : null
  const ratioErr = !/^\d+\s*:\s*\d+$/.test(draft.ratio.trim()) ? 'Use a ratio like 1:4' : null
  const dirty = JSON.stringify(draft) !== JSON.stringify(saved)

  const save = () => {
    setTried(true)
    if (priceErr || ratioErr) return
    saveListing({ ...draft, ratio: draft.ratio.replace(/\s/g, '') })
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
            <PField label="Your suggested price (₹/day)" error={tried ? priceErr : null} hint="ALLCURO confirms the final listed price">
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
            <Link to={PR.publicProfile} className="p-card pc-choose">
              <PIcon name="camera" size={18} />
              <span className="p-row-grow">Add and manage photos on your public profile</span>
              <span className="pc-link">Open</span>
            </Link>
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
