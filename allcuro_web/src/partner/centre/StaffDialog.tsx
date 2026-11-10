import { useState } from 'react'
import { toast } from '../../lib/toast'
import { PField } from '../ui'
import { CentreDialog } from './CentreDialog'
import { STAFF_RATIO_OPTIONS, STAFF_ROLE_LABEL, STAFF_ROLE_OPTIONS, type StaffMember, type StaffRoleType } from './data'
import { addStaff, updateStaff } from './state'

// staff/add_edit_staff_dialog.dart — add a duty nurse / caregiver to the roster or edit one.

export function StaffDialog({ member, onClose }: { member?: StaffMember; onClose: () => void }) {
  const [name, setName] = useState(member?.name ?? '')
  const [roleType, setRoleType] = useState<StaffRoleType>(member?.roleType ?? 'gnmNurse')
  const [experienceYears, setExp] = useState(member ? String(member.experienceYears) : '4')
  const [ratio, setRatio] = useState(member?.ratio ?? '1:4')
  const [shiftRate, setRate] = useState(member ? String(member.shiftRate) : '1800')
  const [tried, setTried] = useState(false)

  const errs = {
    name: !name.trim() ? 'Please enter staff name' : null,
    exp: !experienceYears.trim() ? 'Enter years' : null,
    rate: !shiftRate.trim() ? 'Enter shift rate' : null,
  }

  const submit = () => {
    setTried(true)
    if (errs.name || errs.exp || errs.rate) return
    const draft = { name, roleType, experienceYears, ratio, shiftRate }
    if (member) {
      updateStaff(member.id, draft)
      toast(`Updated ${name.trim()}`)
    } else {
      const m = addStaff(draft)
      toast(`Added ${m.name} (${STAFF_ROLE_LABEL[m.roleType]}) to duty roster`)
    }
    onClose()
  }

  return (
    <CentreDialog
      title={member ? 'Edit Care Staff' : 'Add Care Staff & Nurse'}
      onClose={onClose}
      onSubmit={submit}
      submitLabel={member ? 'Save Changes' : 'Add Staff to Roster'}
    >
      <PField label="Staff Full Name" error={tried ? errs.name : null}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Deepa Nair, Ramesh Bhat" autoComplete="off" autoFocus />
      </PField>
      <PField label="Role & Qualification">
        <select value={roleType} onChange={(e) => setRoleType(e.target.value as StaffRoleType)}>
          {STAFF_ROLE_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </PField>
      <div className="pc-two">
        <PField label="Experience (Years)" error={tried ? errs.exp : null}>
          <input value={experienceYears} onChange={(e) => setExp(e.target.value.replace(/\D/g, '').slice(0, 2))} inputMode="numeric" />
        </PField>
        <PField label="Staff-to-Patient Ratio">
          <select value={ratio} onChange={(e) => setRatio(e.target.value)}>
            {STAFF_RATIO_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </PField>
      </div>
      <PField label="Shift Rate / Service Package (₹)" error={tried ? errs.rate : null} hint="Per 12-hour shift">
        <span className="pc-prefix">
          <span aria-hidden="true">₹</span>
          <input value={shiftRate} onChange={(e) => setRate(e.target.value.replace(/\D/g, ''))} inputMode="numeric" placeholder="e.g. 1800 per 12h shift" />
        </span>
      </PField>
    </CentreDialog>
  )
}
