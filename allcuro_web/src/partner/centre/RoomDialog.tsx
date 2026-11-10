import { useState } from 'react'
import { toast } from '../../lib/toast'
import { ChipGroup, PField } from '../ui'
import { CentreDialog } from './CentreDialog'
import { DEFAULT_ROOM_AMENITIES, ROOM_AMENITIES, ROOM_BED_COUNTS, ROOM_WARDS, type Room } from './data'
import { addRoom, updateRoom } from './state'

// rooms/add_edit_room_dialog.dart — add a room (ward, number, beds, price,
// amenities) or edit an existing one.

export function RoomDialog({ room, onClose }: { room?: Room; onClose: () => void }) {
  const [ward, setWard] = useState(room?.ward ?? ROOM_WARDS[0])
  const [title, setTitle] = useState(room?.roomNumber ?? '')
  const [bedCount, setBedCount] = useState(room?.beds.length ?? 2)
  const [rate, setRate] = useState(room ? String(room.rate) : '2500')
  const [amenities, setAmenities] = useState<string[]>(room?.amenities ?? DEFAULT_ROOM_AMENITIES)
  const [tried, setTried] = useState(false)

  const titleErr = !title.trim() ? 'Please enter room name' : null
  const rateNum = parseInt(rate.replace(/\D/g, ''), 10)
  const rateErr = !rate.trim() || !rateNum ? 'Enter price' : null
  const occupiedDropped = room ? room.beds.slice(bedCount).filter((b) => b.occupied).length : 0
  const wards = room && !ROOM_WARDS.includes(room.ward) ? [...ROOM_WARDS, room.ward] : ROOM_WARDS
  const bedOptions = room && !ROOM_BED_COUNTS.includes(room.beds.length) ? [...ROOM_BED_COUNTS, room.beds.length].sort((a, b) => a - b) : ROOM_BED_COUNTS

  const submit = () => {
    setTried(true)
    if (titleErr || rateErr) return
    const draft = { ward, title, bedCount, rate: rateNum, amenities }
    if (room) {
      updateRoom(room.id, draft)
      toast(`Updated ${title.trim()}`)
    } else {
      const added = addRoom(draft)
      toast(`Added ${added.roomNumber} with ${bedCount} beds`)
    }
    onClose()
  }

  return (
    <CentreDialog
      title={room ? 'Edit Room & Beds' : 'Add Room & Beds'}
      onClose={onClose}
      onSubmit={submit}
      submitLabel={room ? 'Save Room' : 'Add Room to Inventory'}
    >
      <PField label="Ward / Section">
        <select value={ward} onChange={(e) => setWard(e.target.value)}>
          {wards.map((w) => (
            <option key={w}>{w}</option>
          ))}
        </select>
      </PField>
      <PField label="Room Number / Title" error={tried ? titleErr : null}>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Room 204, ICU-03, Deluxe 101" autoFocus />
      </PField>
      <div className="pc-two">
        <PField label="Bed Capacity" error={occupiedDropped ? `Removes ${occupiedDropped} occupied bed${occupiedDropped > 1 ? 's' : ''}` : null}>
          <select value={bedCount} onChange={(e) => setBedCount(Number(e.target.value))}>
            {bedOptions.map((n) => (
              <option key={n} value={n}>
                {n} Bed{n > 1 ? 's' : ''}
              </option>
            ))}
          </select>
        </PField>
        <PField label="Price Per Day (₹)" error={tried ? rateErr : null}>
          <span className="pc-prefix">
            <span aria-hidden="true">₹</span>
            <input value={rate} onChange={(e) => setRate(e.target.value.replace(/\D/g, ''))} inputMode="numeric" />
          </span>
        </PField>
      </div>
      <div className="p-field" role="group" aria-labelledby="pc-amen-label">
        <span className="p-field-label" id="pc-amen-label">
          Amenities Included
        </span>
        <ChipGroup options={ROOM_AMENITIES} value={amenities} onChange={setAmenities} />
      </div>
    </CentreDialog>
  )
}
