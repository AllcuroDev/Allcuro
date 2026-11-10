import { useState } from 'react'
import { inr } from '../../lib/format'
import { toast } from '../../lib/toast'
import { EmptyState, PBody, PCard, PIcon } from '../ui'
import { ConfirmDialog } from './CentreDialog'
import type { Room } from './data'
import { RoomDialog } from './RoomDialog'
import { bedCounts, groupByWard, removeRoom, toggleBed, useRooms } from './state'
import './centre.css'

// Rooms & bed inventory (features/centre/presentation/rooms/room_inventory_screen.dart):
// rooms grouped by ward, tap a bed to flip occupied / vacant, add / edit / remove rooms.

export function CentreRoomsPage() {
  const rooms = useRooms()
  const { total, occupied, vacant } = bedCounts(rooms)
  const [editing, setEditing] = useState<Room | 'new' | null>(null)
  const [removing, setRemoving] = useState<Room | null>(null)

  return (
    <PBody>
      <header className="pc-tab-head">
        <h1>Rooms &amp; bed inventory</h1>
        <p>Real-time bed availability &amp; admission management</p>
      </header>

      <PCard className="pc-summary">
        <span className="pc-summary-icon">
          <PIcon name="bed" size={22} />
        </span>
        <span className="p-row-grow">
          <strong>
            {total} Total Beds ({vacant} Vacant · {occupied} Occupied)
          </strong>
          <span className="p-muted pc-small">Tap any bed chip to toggle its occupied/vacant status.</span>
        </span>
      </PCard>

      <div className="pc-bar">
        <h2>Wards &amp; Rooms</h2>
        <button type="button" className="p-btn p-btn-primary p-btn-sm pc-pill-btn" onClick={() => setEditing('new')}>
          <PIcon name="plus" size={16} /> Add Room
        </button>
      </div>

      {rooms.length === 0 ? (
        <PCard>
          <EmptyState
            icon="bed"
            title="No rooms configured yet"
            text="Add your ICU, Semi-private or Deluxe rooms to make them bookable."
            action={
              <button type="button" className="p-btn p-btn-primary" onClick={() => setEditing('new')}>
                Add First Room
              </button>
            }
          />
        </PCard>
      ) : (
        groupByWard(rooms).map(([ward, list]) => (
          <section key={ward} className="pc-ward" aria-label={ward}>
            <h3 className="pc-eyebrow">{ward}</h3>
            <ul className="pc-grid">
              {list.map((room) => (
                <li key={room.id}>
                  <RoomCard room={room} onEdit={() => setEditing(room)} onRemove={() => setRemoving(room)} />
                </li>
              ))}
            </ul>
          </section>
        ))
      )}

      {editing && <RoomDialog room={editing === 'new' ? undefined : editing} onClose={() => setEditing(null)} />}
      {removing && (
        <ConfirmDialog
          title="Remove room?"
          text={
            <>
              <strong>{removing.roomNumber}</strong> and its {removing.beds.length} bed{removing.beds.length === 1 ? '' : 's'} will be
              removed from your inventory.
            </>
          }
          confirmLabel="Remove room"
          onConfirm={() => {
            removeRoom(removing.id)
            toast(`Removed ${removing.roomNumber}`, 'info')
          }}
          onClose={() => setRemoving(null)}
        />
      )}
    </PBody>
  )
}

function RoomCard({ room, onEdit, onRemove }: { room: Room; onEdit: () => void; onRemove: () => void }) {
  const vacant = room.beds.filter((b) => !b.occupied).length
  return (
    <article className="p-card pc-room">
      <div className="pc-room-head">
        <h4>{room.roomNumber}</h4>
        <span className="pc-rate">{inr(room.rate)} / day</span>
      </div>
      <span className={`pc-room-vacancy ${vacant > 0 ? 'is-ok' : ''}`}>
        {vacant > 0 ? `${vacant} of ${room.beds.length} beds vacant` : 'Fully occupied'}
      </span>
      {room.amenities.length > 0 && <p className="p-muted pc-small pc-amen">{room.amenities.join(' · ')}</p>}
      <div className="pc-beds">
        {room.beds.map((bed) => (
          <button
            key={bed.id}
            type="button"
            className={`pc-bed ${bed.occupied ? 'is-occupied' : ''}`}
            aria-pressed={bed.occupied}
            aria-label={`${bed.label}, ${bed.occupied ? 'occupied' : 'vacant'}. Tap to mark ${bed.occupied ? 'vacant' : 'occupied'}`}
            onClick={() => toggleBed(room.id, bed.id)}
          >
            <PIcon name="bed" size={15} />
            <strong>{bed.label}</strong>
            <small>{bed.occupied ? '(Occupied)' : '(Vacant)'}</small>
          </button>
        ))}
      </div>
      <div className="pc-card-actions">
        <button type="button" className="p-btn p-btn-ghost p-btn-sm" onClick={onEdit} aria-label={`Edit ${room.roomNumber}`}>
          <PIcon name="edit" size={16} /> Edit
        </button>
        <button type="button" className="p-btn p-btn-ghost p-btn-sm pc-danger-text" onClick={onRemove} aria-label={`Remove ${room.roomNumber}`}>
          <PIcon name="trash" size={16} /> Remove
        </button>
      </div>
    </article>
  )
}
