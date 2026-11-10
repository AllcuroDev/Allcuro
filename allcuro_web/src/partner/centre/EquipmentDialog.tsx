import { useState } from 'react'
import { toast } from '../../lib/toast'
import { PField } from '../ui'
import { CentreDialog } from './CentreDialog'
import {
  EQUIPMENT_CATEGORY_OPTIONS,
  EQUIPMENT_CONDITION_LABEL,
  type EquipmentCategory,
  type EquipmentCondition,
  type EquipmentItem,
} from './data'
import { addEquipment, updateEquipment } from './state'

// The equipment screen's _AddEquipmentDialog — list a rental device, or edit one.

const digits = (v: string) => v.replace(/\D/g, '')

export function EquipmentDialog({ item, onClose }: { item?: EquipmentItem; onClose: () => void }) {
  const [title, setTitle] = useState(item?.title ?? '')
  const [category, setCategory] = useState<EquipmentCategory>(item?.category ?? 'respiratory')
  const [condition, setCondition] = useState<EquipmentCondition>(item?.condition ?? 'brandNew')
  const [daily, setDaily] = useState(item ? String(item.dailyRate) : '250')
  const [monthly, setMonthly] = useState(item ? String(item.monthlyRate) : '4500')
  const [deposit, setDeposit] = useState(item ? String(item.depositAmount) : '5000')
  const [stock, setStock] = useState(item ? String(item.stockQuantity) : '5')
  const [specs, setSpecs] = useState(item?.specifications ?? '')
  const [tried, setTried] = useState(false)

  const req = (v: string) => (tried && !v.trim() ? 'Required' : null)
  const titleErr = tried && !title.trim() ? 'Please enter equipment title' : null

  const submit = () => {
    setTried(true)
    if (!title.trim() || !daily || !monthly || !deposit || !stock) return
    const draft = {
      title: title.trim(),
      category,
      condition,
      dailyRate: Number(daily) || 250,
      monthlyRate: Number(monthly) || 4500,
      depositAmount: Number(deposit) || 5000,
      stockQuantity: Number(stock) || 5,
      specifications: specs.trim(),
    }
    if (item) {
      updateEquipment(item.id, draft)
      toast(`Updated ${draft.title}`)
    } else {
      addEquipment(draft)
      toast(`Added ${draft.title} to equipment rentals`)
    }
    onClose()
  }

  return (
    <CentreDialog
      title={item ? 'Edit Medical Equipment' : 'Add Medical Equipment'}
      onClose={onClose}
      onSubmit={submit}
      submitLabel={item ? 'Save Changes' : 'Save & Add to Catalog'}
    >
      <PField label="Equipment Title / Model" error={titleErr}>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Philips 10L Oxygen Concentrator" autoFocus />
      </PField>
      <div className="pc-two">
        <PField label="Category">
          <select value={category} onChange={(e) => setCategory(e.target.value as EquipmentCategory)}>
            {EQUIPMENT_CATEGORY_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </PField>
        <PField label="Condition">
          <select value={condition} onChange={(e) => setCondition(e.target.value as EquipmentCondition)}>
            {(Object.keys(EQUIPMENT_CONDITION_LABEL) as EquipmentCondition[]).map((c) => (
              <option key={c} value={c}>
                {EQUIPMENT_CONDITION_LABEL[c]}
              </option>
            ))}
          </select>
        </PField>
      </div>
      <div className="pc-two">
        <PField label="Daily Rate (₹)" error={req(daily)}>
          <span className="pc-prefix">
            <span aria-hidden="true">₹</span>
            <input value={daily} onChange={(e) => setDaily(digits(e.target.value))} inputMode="numeric" />
          </span>
        </PField>
        <PField label="Monthly Rate (₹)" error={req(monthly)}>
          <span className="pc-prefix">
            <span aria-hidden="true">₹</span>
            <input value={monthly} onChange={(e) => setMonthly(digits(e.target.value))} inputMode="numeric" />
          </span>
        </PField>
      </div>
      <div className="pc-two">
        <PField label="Deposit (₹)" error={req(deposit)}>
          <span className="pc-prefix">
            <span aria-hidden="true">₹</span>
            <input value={deposit} onChange={(e) => setDeposit(digits(e.target.value))} inputMode="numeric" />
          </span>
        </PField>
        <PField label="Stock Quantity" error={req(stock)}>
          <input value={stock} onChange={(e) => setStock(digits(e.target.value).slice(0, 4))} inputMode="numeric" />
        </PField>
      </div>
      <PField label="Specifications / Features">
        <textarea
          value={specs}
          onChange={(e) => setSpecs(e.target.value)}
          rows={2}
          placeholder="e.g. 10 LPM continuous flow, purity 93%, includes humidifier bottle"
        />
      </PField>
    </CentreDialog>
  )
}
