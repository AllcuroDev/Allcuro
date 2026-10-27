import { useEffect, useState } from 'react'

/** Indian digit grouping, matching `inr()` in allcuro/lib/core/utils/currency.dart: 123456 → ₹1,23,456. */
export const inr = (amount: number) =>
  `${amount < 0 ? '-' : ''}₹${Math.abs(Math.round(amount)).toLocaleString('en-IN')}`

/** "Priya Sharma" → "PS" */
export const initials = (name: string) =>
  name
    .replace(/^Dr\.\s*/, '')
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('')

/** First number in a catalog price such as "₹1,299+" or "₹799–999". */
export const priceFrom = (label: string) => parseInt(label.replace(/,/g, '').match(/\d+/)?.[0] ?? '0', 10)

export const digitsOnly = (s: string) => s.replace(/\D/g, '')

/** "9876543210" → "+91 98765 43210" */
export const formatPhone = (digits: string) =>
  digits.length === 10 ? `+91 ${digits.slice(0, 5)} ${digits.slice(5)}` : digits

/** Current time, refreshed every `ms` — drives the live tracker. */
export function useNow(ms = 1000) {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), ms)
    return () => clearInterval(id)
  }, [ms])
  return now
}
