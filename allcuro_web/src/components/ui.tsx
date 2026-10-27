import {
  useEffect,
  useRef,
  type InputHTMLAttributes,
  type ReactNode,
  type SelectHTMLAttributes,
  type TextareaHTMLAttributes,
} from 'react'
import type { BillLine } from '../data/booking'
import { billTotal } from '../data/booking'
import { inr, initials } from '../lib/format'
import { toasts } from '../lib/toast'
import { goBack } from '../router'
import { BackIcon, CheckIcon, CloseIcon, StarIcon } from './Icons'

// Building blocks shared by the booking, tracking and account pages.

/** Back button + title, like the app's ScreenHeader. */
export function PageHead({
  title,
  subtitle,
  back,
  aside,
}: {
  title: ReactNode
  subtitle?: ReactNode
  /** Where "back" goes when the visitor arrived on this page directly. */
  back: string
  aside?: ReactNode
}) {
  return (
    <div className="page-head">
      <button type="button" className="icon-btn" onClick={() => goBack(back)} aria-label="Go back">
        <BackIcon />
      </button>
      <div className="page-head-text">
        <h1>{title}</h1>
        {subtitle && <p>{subtitle}</p>}
      </div>
      {aside}
    </div>
  )
}

/** Native <dialog> modal with the site's dialog styling (see ServiceDialog). */
export function Modal({
  onClose,
  labelledBy,
  className = '',
  dismissable = true,
  children,
}: {
  onClose: () => void
  labelledBy: string
  className?: string
  /** False while something is in flight (e.g. a payment) so it can't be closed halfway. */
  dismissable?: boolean
  children: ReactNode
}) {
  const ref = useRef<HTMLDialogElement>(null)

  useEffect(() => {
    const d = ref.current
    if (d && !d.open) d.showModal()
    document.body.classList.add('no-scroll')
    return () => document.body.classList.remove('no-scroll')
  }, [])

  return (
    <dialog
      ref={ref}
      className={`dialog dialog-sm ${className}`}
      aria-labelledby={labelledBy}
      onCancel={(e) => {
        e.preventDefault()
        if (dismissable) onClose()
      }}
      onClick={(e) => dismissable && e.target === ref.current && onClose()}
    >
      <div className="dialog-body">
        {dismissable && (
          <button type="button" className="dialog-close" onClick={onClose} aria-label="Close">
            <CloseIcon size={20} />
          </button>
        )}
        {children}
      </div>
    </dialog>
  )
}

export function StepTitle({ n, children }: { n?: number; children: ReactNode }) {
  return (
    <h2 className="step-title">
      {n != null && <span className="step-num">{n}</span>}
      {children}
    </h2>
  )
}

/** Selectable card used for services, rooms and slots (a styled radio). */
export function OptionCard({
  name,
  checked,
  onSelect,
  children,
  compact = false,
}: {
  name: string
  checked: boolean
  onSelect: () => void
  children: ReactNode
  compact?: boolean
}) {
  return (
    <label className={`option-card ${checked ? 'is-checked' : ''} ${compact ? 'is-compact' : ''}`}>
      <input type="radio" name={name} checked={checked} onChange={onSelect} className="sr-only" />
      <span className="option-radio" aria-hidden="true" />
      <span className="option-body">{children}</span>
    </label>
  )
}

export function Field({
  label,
  hint,
  ...input
}: InputHTMLAttributes<HTMLInputElement> & { label: string; hint?: string }) {
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <input className="input" {...input} />
      {hint && <span className="field-hint">{hint}</span>}
    </label>
  )
}

export function TextArea({
  label,
  ...input
}: TextareaHTMLAttributes<HTMLTextAreaElement> & { label: string }) {
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <textarea className="input" rows={2} {...input} />
    </label>
  )
}

export function Select({
  label,
  options,
  ...select
}: SelectHTMLAttributes<HTMLSelectElement> & { label: string; options: string[] }) {
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <select className="input" {...select}>
        {options.map((o) => (
          <option key={o}>{o}</option>
        ))}
      </select>
    </label>
  )
}

export function Bill({ lines, totalLabel = 'Total Payable' }: { lines: BillLine[]; totalLabel?: string }) {
  return (
    <dl className="bill">
      {lines.map((l) => (
        <div key={l.label} className={l.amount < 0 ? 'is-discount' : ''}>
          <dt>{l.label}</dt>
          <dd>{l.amount < 0 ? `– ${inr(-l.amount)}` : inr(l.amount)}</dd>
        </div>
      ))}
      <div className="bill-total">
        <dt>{totalLabel}</dt>
        <dd>{inr(billTotal(lines))}</dd>
      </div>
    </dl>
  )
}

export interface Step {
  title: string
  subtitle: string
}

/** Vertical progress list (the app's _StepTile column). `current` is the index in progress. */
export function StepList({ steps, current }: { steps: Step[]; current: number }) {
  return (
    <ol className="step-list">
      {steps.map((s, i) => {
        const state = i < current ? 'is-done' : i === current ? 'is-current' : ''
        return (
          <li key={s.title} className={state} aria-current={i === current ? 'step' : undefined}>
            <span className="step-dot" aria-hidden="true">
              {i < current && <CheckIcon size={13} />}
            </span>
            <div>
              <strong>{s.title}</strong>
              <span>{s.subtitle}</span>
            </div>
          </li>
        )
      })}
    </ol>
  )
}

export function Avatar({ name, size = 48 }: { name: string; size?: number }) {
  return (
    <span className="avatar" style={{ width: size, height: size, fontSize: size * 0.34 }} aria-hidden="true">
      {initials(name)}
    </span>
  )
}

export function Rating({ value, count }: { value: number; count?: number }) {
  return (
    <span className="rating">
      <StarIcon size={15} />
      <strong>{value.toFixed(1)}</strong>
      {count != null && <span>({count})</span>}
    </span>
  )
}

/** Bottom action bar with the running total — the app's bottomBar. */
export function ActionBar({ label, amount, children }: { label: string; amount: string; children: ReactNode }) {
  return (
    <div className="action-bar">
      <div className="container action-bar-inner">
        <div>
          <span className="action-bar-label">{label}</span>
          <strong className="action-bar-amount">{amount}</strong>
        </div>
        {children}
      </div>
    </div>
  )
}

export const Spinner = () => <span className="spinner" aria-hidden="true" />

// ---- Toasts (the app's SnackBars); call `toast()` from lib/toast ----

export function Toaster() {
  const items = toasts.use()
  return (
    <div className="toaster" role="status" aria-live="polite">
      {items.map((t) => (
        <div key={t.id} className={`toast toast-${t.tone}`}>
          {t.text}
        </div>
      ))}
    </div>
  )
}
