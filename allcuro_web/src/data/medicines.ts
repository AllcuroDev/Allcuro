import type { BillLine } from './booking'

// Medicine catalog (filled from public.medicines by state/content.ts and
// edited in the admin) and the cart's price rules. Prices are in rupees and
// GST-inclusive.

export interface Medicine {
  id: string
  name: string
  pack: string
  mrp: number
  price: number
  /** Prescription-only: the order needs a prescription before it can be paid. */
  rx: boolean
  category: MedicineCategory
  imageUrl?: string
}

/** Categories present in the loaded catalog, in catalog order. */
export const medicineCategories: string[] = []

export type MedicineCategory = string

export const medicines: Medicine[] = []

export const medicineById = (id: string) => medicines.find((x) => x.id === id)

/** Name, category or pack contains the query (case-insensitive). */
export function searchMedicines(query: string, category: MedicineCategory | null) {
  const q = query.trim().toLowerCase()
  return medicines.filter(
    (x) =>
      (!category || x.category === category) &&
      (!q || [x.name, x.category, x.pack].some((f) => f.toLowerCase().includes(q))),
  )
}

/** Whole-number % off MRP, e.g. 12. */
export const percentOff = (x: Pick<Medicine, 'mrp' | 'price'>) => Math.round(((x.mrp - x.price) / x.mrp) * 100)

/** What a pharmacist "reads" from an uploaded prescription in demo mode. */
export const PRESCRIPTION_DEMO_ITEMS: { id: string; qty: number }[] = [
  { id: 'metformin-500', qty: 2 },
  { id: 'amlodipine-5', qty: 1 },
  { id: 'pantoprazole-40', qty: 1 },
]

export const MIN_QTY = 1
export const MAX_QTY = 10
export const FREE_DELIVERY_MIN = 499
export const DELIVERY_FEE = 39
export const MAX_PRESCRIPTION_BYTES = 10 * 1024 * 1024

export interface PricedLine {
  medicine: Medicine
  qty: number
}

export interface MedicineTotals {
  itemTotal: number
  mrpTotal: number
  savings: number
  deliveryFee: number
  total: number
  /** Still needed for free delivery (0 once reached). */
  toFreeDelivery: number
}

/** Same rules as the app: free delivery from ₹499 of items, otherwise ₹39. */
export function medicineTotals(lines: PricedLine[]): MedicineTotals {
  const itemTotal = lines.reduce((sum, l) => sum + l.medicine.price * l.qty, 0)
  const mrpTotal = lines.reduce((sum, l) => sum + l.medicine.mrp * l.qty, 0)
  const deliveryFee = itemTotal >= FREE_DELIVERY_MIN ? 0 : DELIVERY_FEE
  return {
    itemTotal,
    mrpTotal,
    savings: mrpTotal - itemTotal,
    deliveryFee,
    total: itemTotal + deliveryFee,
    toFreeDelivery: Math.max(0, FREE_DELIVERY_MIN - itemTotal),
  }
}

/** Bill rows for the cart and PaymentDialog; they add up to `total`. */
export function medicineBill(t: MedicineTotals): BillLine[] {
  return [
    { label: 'Item total (MRP)', amount: t.mrpTotal },
    ...(t.savings ? [{ label: 'Discount on MRP', amount: -t.savings }] : []),
    { label: t.deliveryFee ? 'Delivery fee' : 'Delivery fee (free above ₹499)', amount: t.deliveryFee },
  ]
}
