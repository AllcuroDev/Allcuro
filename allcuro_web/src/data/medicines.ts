import type { BillLine } from './booking'

// Medicine catalog and price rules for Order Medicines. Kept identical to the
// customer app's medicine catalog so the two show the same items and totals.
// Prices are in rupees and GST-inclusive.

export interface Medicine {
  id: string
  name: string
  pack: string
  mrp: number
  price: number
  /** Prescription-only: the order needs a prescription before it can be paid. */
  rx: boolean
  category: MedicineCategory
}

export const medicineCategories = [
  'Fever & Pain',
  'Cold & Allergy',
  'Stomach Care',
  'Diabetes & Thyroid',
  'BP & Heart',
  'Antibiotics',
  'Vitamins',
] as const

export type MedicineCategory = (typeof medicineCategories)[number]

const m = (
  id: string,
  name: string,
  pack: string,
  mrp: number,
  price: number,
  rx: boolean,
  category: MedicineCategory,
): Medicine => ({ id, name, pack, mrp, price, rx, category })

export const medicines: Medicine[] = [
  m('paracetamol-650', 'Paracetamol 650 mg Tablet', 'Strip of 15 tablets', 34, 30, false, 'Fever & Pain'),
  m('ibuprofen-400', 'Ibuprofen 400 mg Tablet', 'Strip of 15 tablets', 42, 36, false, 'Fever & Pain'),
  m('cetirizine-10', 'Cetirizine 10 mg Tablet', 'Strip of 10 tablets', 22, 19, false, 'Cold & Allergy'),
  m('cough-syrup', 'Ambroxol Cough Syrup', 'Bottle of 100 ml', 115, 98, false, 'Cold & Allergy'),
  m('ors-orange', 'ORS Electrolyte Powder (Orange)', 'Pack of 5 sachets', 110, 99, false, 'Stomach Care'),
  m('antacid-gel', 'Antacid Gel (Mint)', 'Bottle of 170 ml', 129, 110, false, 'Stomach Care'),
  m('pantoprazole-40', 'Pantoprazole 40 mg Tablet', 'Strip of 15 tablets', 155, 132, true, 'Stomach Care'),
  m('metformin-500', 'Metformin 500 mg SR Tablet', 'Strip of 20 tablets', 48, 41, true, 'Diabetes & Thyroid'),
  m('glimepiride-1', 'Glimepiride 1 mg Tablet', 'Strip of 10 tablets', 92, 78, true, 'Diabetes & Thyroid'),
  m('thyroxine-50', 'Thyroxine 50 mcg Tablet', 'Bottle of 100 tablets', 180, 153, true, 'Diabetes & Thyroid'),
  m('amlodipine-5', 'Amlodipine 5 mg Tablet', 'Strip of 15 tablets', 64, 55, true, 'BP & Heart'),
  m('telmisartan-40', 'Telmisartan 40 mg Tablet', 'Strip of 15 tablets', 118, 99, true, 'BP & Heart'),
  m('atorvastatin-10', 'Atorvastatin 10 mg Tablet', 'Strip of 15 tablets', 140, 119, true, 'BP & Heart'),
  m('amoxicillin-500', 'Amoxicillin 500 mg Capsule', 'Strip of 10 capsules', 98, 84, true, 'Antibiotics'),
  m('azithromycin-500', 'Azithromycin 500 mg Tablet', 'Strip of 3 tablets', 119, 101, true, 'Antibiotics'),
  m('vitamin-d3', 'Vitamin D3 60,000 IU Capsule', 'Strip of 4 capsules', 136, 115, false, 'Vitamins'),
  m('calcium-d3', 'Calcium + Vitamin D3 Tablet', 'Strip of 15 tablets', 125, 106, false, 'Vitamins'),
  m('multivitamin', 'Multivitamin Tablet', 'Bottle of 30 tablets', 320, 272, false, 'Vitamins'),
]

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
