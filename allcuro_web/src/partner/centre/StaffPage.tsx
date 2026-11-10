import { useState } from 'react'
import { initials, inr } from '../../lib/format'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { EmptyState, PBody, PCard, PIcon, PPageHead } from '../ui'
import { ConfirmDialog } from './CentreDialog'
import { STAFF_ROLE_LABEL, type StaffMember } from './data'
import { StaffDialog } from './StaffDialog'
import { removeStaff, renewStaffCertificate, useStaff } from './state'
import './centre.css'

// Staff & in-house care roster (features/centre/presentation/staff/staff_management_screen.dart).

export function CentreStaffPage() {
  const staff = useStaff()
  const [editing, setEditing] = useState<StaffMember | 'new' | null>(null)
  const [removing, setRemoving] = useState<StaffMember | null>(null)
  const expiring = staff.filter((m) => m.certificateExpiring).length

  return (
    <>
      <PPageHead
        title="Staff & In-House Care Roster"
        subtitle="Duty nurses, caregivers & staff-to-patient trust metrics"
        back={PR.centreHome}
      />
      <PBody>
        <PCard className="pc-summary">
          <span className="pc-summary-icon">
            <PIcon name="users" size={22} />
          </span>
          <span className="p-row-grow">
            <strong>{staff.length} Active Care Staff Members</strong>
            <span className="p-muted pc-small">Your staff roster and qualifications feed the trust badges families review.</span>
          </span>
        </PCard>

        {expiring > 0 && (
          <div className="p-note" role="note">
            <PIcon name="clock" size={18} />
            <span>
              {expiring} staff certificate{expiring > 1 ? 's are' : ' is'} due for renewal. Renew to keep the &ldquo;Certified&rdquo; badge on your listing.
            </span>
          </div>
        )}

        <div className="pc-bar">
          <h2>Caregivers &amp; Nurses</h2>
          <button type="button" className="p-btn p-btn-primary p-btn-sm pc-pill-btn" onClick={() => setEditing('new')}>
            <PIcon name="plus" size={16} /> Add Staff
          </button>
        </div>

        {staff.length === 0 ? (
          <PCard>
            <EmptyState
              icon="users"
              title="No care staff configured yet"
              text="Add your GNM nurses, B.Sc specialists or care attendants."
              action={
                <button type="button" className="p-btn p-btn-primary" onClick={() => setEditing('new')}>
                  Add Staff Member
                </button>
              }
            />
          </PCard>
        ) : (
          <ul className="pc-grid">
            {staff.map((m) => (
              <li key={m.id}>
                <article className="p-card pc-staff">
                  <span className="pc-staff-avatar" aria-hidden="true">
                    {initials(m.name) || '?'}
                  </span>
                  <div className="p-row-grow">
                    <h3>{m.name}</h3>
                    <span className="pc-staff-role">{STAFF_ROLE_LABEL[m.roleType]}</span>
                    <span className="p-muted pc-small">
                      {m.qualification} · Ratio {m.ratio}
                    </span>
                    <span className="pc-rate">{inr(m.shiftRate)} / shift</span>
                  </div>
                  <span className={`p-pill ${m.certificateExpiring ? 'is-warn' : 'is-ok'}`}>{m.certificateExpiring ? 'Renewal Due' : 'Certified'}</span>
                  <div className="pc-card-actions">
                    {m.certificateExpiring && (
                      <button
                        type="button"
                        className="p-btn p-btn-ghost p-btn-sm"
                        onClick={() => {
                          renewStaffCertificate(m.id)
                          toast(`Renewed certificate uploaded for ${m.name}`)
                        }}
                      >
                        <PIcon name="upload" size={16} /> Renew
                      </button>
                    )}
                    <button type="button" className="p-btn p-btn-ghost p-btn-sm" onClick={() => setEditing(m)} aria-label={`Edit ${m.name}`}>
                      <PIcon name="edit" size={16} /> Edit
                    </button>
                    <button type="button" className="p-btn p-btn-ghost p-btn-sm pc-danger-text" onClick={() => setRemoving(m)} aria-label={`Remove ${m.name}`}>
                      <PIcon name="trash" size={16} /> Remove
                    </button>
                  </div>
                </article>
              </li>
            ))}
          </ul>
        )}

        <button type="button" className="pc-dashed" onClick={() => setEditing('new')}>
          + Add another staff member / duty nurse
        </button>
      </PBody>

      {editing && <StaffDialog member={editing === 'new' ? undefined : editing} onClose={() => setEditing(null)} />}
      {removing && (
        <ConfirmDialog
          title="Remove staff member?"
          text={
            <>
              <strong>{removing.name}</strong> will be removed from your duty roster.
            </>
          }
          confirmLabel="Remove"
          onConfirm={() => {
            removeStaff(removing.id)
            toast(`Removed ${removing.name}`, 'info')
          }}
          onClose={() => setRemoving(null)}
        />
      )}
    </>
  )
}
