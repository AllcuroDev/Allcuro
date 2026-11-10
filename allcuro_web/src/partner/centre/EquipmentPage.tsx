import { useState } from 'react'
import { inr } from '../../lib/format'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { EmptyState, PBody, PCard, PIcon, PPageHead, Toggle, type PIconName } from '../ui'
import { ConfirmDialog } from './CentreDialog'
import { EQUIPMENT_CATEGORY_LABEL, EQUIPMENT_CONDITION_LABEL, type EquipmentCategory, type EquipmentItem } from './data'
import { EquipmentDialog } from './EquipmentDialog'
import { removeEquipment, toggleEquipmentAvailable, useEquipment } from './state'
import './centre.css'

// Medical equipment & rentals (features/centre/presentation/equipment/equipment_management_screen.dart).

const CATEGORY_ICON: Record<EquipmentCategory, PIconName> = {
  respiratory: 'heart',
  hospitalBeds: 'bed',
  mobility: 'navigate',
  icuMonitoring: 'chart',
  physiotherapy: 'bolt',
}

export function CentreEquipmentPage() {
  const list = useEquipment()
  const [editing, setEditing] = useState<EquipmentItem | 'new' | null>(null)
  const [removing, setRemoving] = useState<EquipmentItem | null>(null)

  return (
    <>
      <PPageHead
        title="Medical Equipment & Rentals"
        subtitle="Rent ICU beds, oxygen concentrators & mobility devices to patients"
        back={PR.centreHome}
      />
      <PBody>
        <PCard className="pc-summary">
          <span className="pc-summary-icon">
            <PIcon name="box" size={22} />
          </span>
          <span className="p-row-grow">
            <strong>{list.length} Equipment Items Listed</strong>
            <span className="p-muted pc-small">Security deposits are held in escrow and settled automatically upon device return.</span>
          </span>
        </PCard>

        <div className="pc-bar">
          <h2>Your equipment catalog</h2>
          <button type="button" className="p-btn p-btn-primary p-btn-sm pc-pill-btn" onClick={() => setEditing('new')}>
            <PIcon name="plus" size={16} /> Add item
          </button>
        </div>

        {list.length === 0 ? (
          <PCard>
            <EmptyState
              icon="box"
              title="No medical equipment listed yet"
              text="Add oxygen concentrators, hospital beds, or wheelchairs to earn additional revenue."
              action={
                <button type="button" className="p-btn p-btn-primary" onClick={() => setEditing('new')}>
                  <PIcon name="plus" size={16} /> Add First Equipment
                </button>
              }
            />
          </PCard>
        ) : (
          <ul className="pc-grid">
            {list.map((item) => (
              <li key={item.id}>
                <article className={`p-card pc-equip ${item.isAvailable ? '' : 'is-off'}`}>
                  <div className="pc-equip-head">
                    <span className="pc-equip-icon" aria-hidden="true">
                      <PIcon name={CATEGORY_ICON[item.category]} size={20} />
                    </span>
                    <div className="p-row-grow">
                      <h3>{item.title}</h3>
                      <span className="p-muted pc-small">
                        {EQUIPMENT_CATEGORY_LABEL[item.category]} · {EQUIPMENT_CONDITION_LABEL[item.condition]}
                      </span>
                    </div>
                  </div>
                  {item.specifications && <p className="pc-equip-specs">{item.specifications}</p>}
                  <dl className="pc-rates">
                    <div>
                      <dt>Daily Rate</dt>
                      <dd>{inr(item.dailyRate)}/d</dd>
                    </div>
                    <div>
                      <dt>Monthly</dt>
                      <dd>{inr(item.monthlyRate)}/mo</dd>
                    </div>
                    <div>
                      <dt>Deposit</dt>
                      <dd>{inr(item.depositAmount)}</dd>
                    </div>
                    <div>
                      <dt>Stock</dt>
                      <dd>{item.stockQuantity} pcs</dd>
                    </div>
                  </dl>
                  <div className="pc-equip-foot">
                    <span className="pc-switch-row">
                      <Toggle
                        checked={item.isAvailable}
                        onChange={() => {
                          toggleEquipmentAvailable(item.id)
                          toast(item.isAvailable ? `${item.title} paused for rentals` : `${item.title} available for rent`, 'info')
                        }}
                        label={`Available for rent: ${item.title}`}
                      />
                      <span className="pc-small">{item.isAvailable ? 'Available for rent' : 'Paused'}</span>
                    </span>
                    <span className="pc-card-actions">
                      <button type="button" className="p-btn p-btn-ghost p-btn-sm" onClick={() => setEditing(item)} aria-label={`Edit ${item.title}`}>
                        <PIcon name="edit" size={16} /> Edit
                      </button>
                      <button type="button" className="p-btn p-btn-ghost p-btn-sm pc-danger-text" onClick={() => setRemoving(item)} aria-label={`Remove ${item.title}`}>
                        <PIcon name="trash" size={16} /> Remove
                      </button>
                    </span>
                  </div>
                </article>
              </li>
            ))}
          </ul>
        )}

        <button type="button" className="pc-dashed" onClick={() => setEditing('new')}>
          + Add more equipment &amp; devices
        </button>
      </PBody>

      {editing && <EquipmentDialog item={editing === 'new' ? undefined : editing} onClose={() => setEditing(null)} />}
      {removing && (
        <ConfirmDialog
          title="Remove equipment?"
          text={
            <>
              <strong>{removing.title}</strong> will be removed from your rental catalog.
            </>
          }
          confirmLabel="Remove"
          onConfirm={() => {
            removeEquipment(removing.id)
            toast(`Removed ${removing.title}`, 'info')
          }}
          onClose={() => setRemoving(null)}
        />
      )}
    </>
  )
}
