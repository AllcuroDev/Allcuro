import {
  MAX_PRESCRIPTION_BYTES,
  MAX_QTY,
  medicineById,
  medicineTotals,
  type Medicine,
} from '../data/medicines'
import { memoryStore, persistedStore } from '../lib/store'

// Medicine cart + attached prescription. Kept on this device in localStorage
// (it survives reloads and sign-in) and cleared once the order is paid.
// The prescription travels with the order; a licensed pharmacist checks it
// before dispatch. Nothing is added to the cart automatically.

export interface CartLine {
  id: string
  qty: number
  /** Added by the pharmacist from the uploaded prescription. */
  fromPrescription?: boolean
}

export interface PrescriptionFile {
  name: string
  size: number
  type: string
  /** Small JPEG thumbnail (images under 1.5 MB only) — never the full file, to stay inside the storage quota. */
  preview?: string
  uploadedAt: number
}

const PREVIEW_MAX_BYTES = 1.5 * 1024 * 1024
const PREVIEW_MAX_SIDE = 240
// persistedStore already wraps every localStorage write in try/catch, so a full
// quota only means the value lives in memory for this visit.
const items = persistedStore<CartLine[]>('cart', [])
const prescription = persistedStore<PrescriptionFile | null>('cart.prescription', null)
/** The file being attached right now (not persisted). */
const reviewing = memoryStore<Omit<PrescriptionFile, 'uploadedAt'> | null>(null)

export interface CartItem extends CartLine {
  medicine: Medicine
}

export function useCart() {
  const lines = items.use()
  const rx = prescription.use()
  const pending = reviewing.use()
  const cartItems: CartItem[] = lines.flatMap((l) => {
    const medicine = medicineById(l.id)
    return medicine ? [{ ...l, medicine }] : []
  })
  const hasRxItem = cartItems.some((l) => l.medicine.rx)
  return {
    items: cartItems,
    /** Units in the cart (sum of quantities), as the app's `itemCount`. */
    count: cartItems.reduce((sum, l) => sum + l.qty, 0),
    qtyOf: (id: string) => lines.find((l) => l.id === id)?.qty ?? 0,
    totals: medicineTotals(cartItems),
    prescription: rx,
    reviewing: pending,
    hasRxItem,
    /** Rx medicines need a prescription before the order can be paid. */
    needsPrescription: hasRxItem && !rx,
  }
}

const clamp = (qty: number) => Math.min(MAX_QTY, Math.max(0, Math.round(qty)))

export function addToCart(id: string) {
  items.set((lines) => (lines.some((l) => l.id === id) ? lines : [...lines, { id, qty: 1 }]))
}

/** Sets a line's quantity (1–10); 0 removes it. */
export function setQty(id: string, qty: number) {
  const next = clamp(qty)
  items.set((lines) =>
    next === 0 ? lines.filter((l) => l.id !== id) : lines.map((l) => (l.id === id ? { ...l, qty: next } : l)),
  )
}

export const removeFromCart = (id: string) => items.set((lines) => lines.filter((l) => l.id !== id))

export function clearCart() {
  items.set([])
  prescription.set(null)
}

export const removePrescription = () => prescription.set(null)

/** A friendly reason the file can't be used, or null when it's fine. */
export function prescriptionProblem(file: File): string | null {
  const okType = file.type.startsWith('image/') || file.type === 'application/pdf' || /\.pdf$/i.test(file.name)
  if (!okType) return 'Please upload a photo of the prescription or a PDF.'
  if (file.size > MAX_PRESCRIPTION_BYTES) return 'That file is larger than 10 MB. Please take a smaller photo or upload a PDF.'
  if (file.size === 0) return 'That file looks empty. Please choose the prescription again.'
  return null
}

/** Scales an image down to a small JPEG data URL for the preview. */
async function thumbnail(file: File): Promise<string | undefined> {
  if (!file.type.startsWith('image/') || file.size >= PREVIEW_MAX_BYTES) return undefined
  try {
    const bitmap = await createImageBitmap(file)
    const scale = Math.min(1, PREVIEW_MAX_SIDE / Math.max(bitmap.width, bitmap.height))
    const canvas = document.createElement('canvas')
    canvas.width = Math.max(1, Math.round(bitmap.width * scale))
    canvas.height = Math.max(1, Math.round(bitmap.height * scale))
    canvas.getContext('2d')?.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
    bitmap.close()
    return canvas.toDataURL('image/jpeg', 0.75)
  } catch {
    // Formats the browser can't decode (e.g. HEIC) simply show the file name.
    return undefined
  }
}

/**
 * Attaches a prescription to the order (the pharmacist checks it before
 * dispatch). Call `prescriptionProblem` first.
 */
export async function attachPrescription(file: File) {
  if (reviewing.get()) return
  const meta = { name: file.name, size: file.size, type: file.type || 'application/pdf' }
  reviewing.set(meta)
  try {
    const preview = await thumbnail(file)
    reviewing.set({ ...meta, preview })
    prescription.set({ ...meta, preview, uploadedAt: Date.now() })
  } finally {
    reviewing.set(null)
  }
}

/** "1.2 MB" / "640 KB" */
export const fileSize = (bytes: number) =>
  bytes >= 1024 * 1024 ? `${(bytes / (1024 * 1024)).toFixed(1)} MB` : `${Math.max(1, Math.round(bytes / 1024))} KB`
