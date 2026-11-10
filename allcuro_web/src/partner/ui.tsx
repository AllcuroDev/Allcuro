import { useRef, useState, type ReactNode } from 'react'
import { Link } from '../components/Link'
import { goBack } from '../router'

// Shared building blocks for the partner portal — the web twins of the
// partner app's core/ui (Surface, ToolTile, UploadTile, EmptyState,
// ScreenHeader, WizardScaffold). Styles live in partner.css (`p-` prefix).

// ---------------------------------------------------------------- icons

const paths = {
  grid: 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z',
  clipboard: 'M9 4h6v3H9zM7 5H5v16h14V5h-2M9 12h6M9 16h4',
  calendar: 'M4 6h16v15H4zM4 10h16M8 3v4M16 3v4',
  bed: 'M3 18V6M3 14h18v4M21 18v-4a3 3 0 0 0-3-3h-8v3M6.5 11.5a1.5 1.5 0 1 0 0-.01',
  heart: 'M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10zM8 12h2l1-2 2 4 1-2h2',
  bell: 'M6 16V11a6 6 0 1 1 12 0v5l2 2H4zM10 21h4',
  user: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0',
  pin: 'M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21zM12 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z',
  back: 'M15 5l-7 7 7 7',
  chevron: 'M9 5l7 7-7 7',
  check: 'M5 12.5l4.5 4.5L19 7.5',
  close: 'M6 6l12 12M18 6L6 18',
  plus: 'M12 5v14M5 12h14',
  upload: 'M12 16V4M7 9l5-5 5 5M4 20h16',
  file: 'M7 3h7l5 5v13H7zM14 3v5h5',
  wallet: 'M4 7h15v12H4zM4 7l11-3v3M15 13h2',
  star: 'M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z',
  shield: 'M12 3l7 3v6c0 4.5-3 7.6-7 9-4-1.4-7-4.5-7-9V6zM9 12l2 2 4-4',
  clock: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2',
  phone: 'M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2',
  sos: 'M12 3l9 16H3zM12 10v4M12 17v.01',
  book: 'M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2zM4 21V5M8 7h7',
  gift: 'M4 10h16v11H4zM3 7h18v3H3zM12 7v14M12 7S10 3 8 4s0 3 4 3c4 0 6-2 4-3s-4 3-4 3',
  help: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6V14M12 17v.01',
  chart: 'M4 20V10M10 20V4M16 20v-7M22 20H2',
  users: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21a7 7 0 0 1 14 0M16 3.5a4 4 0 0 1 0 7.5M18 14a6 6 0 0 1 4 6',
  box: 'M3 7l9-4 9 4v10l-9 4-9-4zM3 7l9 4 9-4M12 11v10',
  megaphone: 'M3 10v4h4l8 5V5L7 10zM18 9a4 4 0 0 1 0 6',
  store: 'M4 9l1.5-5h13L20 9M4 9v11h16V9M4 9h16M9 20v-6h6v6',
  bank: 'M3 9l9-5 9 5M5 9v9M10 9v9M14 9v9M19 9v9M3 20h18',
  logout: 'M15 4h4v16h-4M10 8l-4 4 4 4M6 12h10',
  navigate: 'M3 11l18-8-8 18-2-8z',
  play: 'M7 4l13 8-13 8z',
  edit: 'M4 20h4L19 9l-4-4L4 16zM14 6l4 4',
  trash: 'M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13',
  camera: 'M4 8h3l2-3h6l2 3h3v11H4zM12 16a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  rupee: 'M7 4h10M7 8h10M7 4c5 0 7 1.5 7 4s-2 4-7 4l7 8',
  bolt: 'M13 2L4 14h7l-1 8 9-12h-7z',
  copy: 'M8 8h12v12H8zM4 16V4h12',
} as const

export type PIconName = keyof typeof paths

export function PIcon({ name, size = 20 }: { name: PIconName; size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      className="p-icon"
    >
      <path d={paths[name]} />
    </svg>
  )
}

// ---------------------------------------------------------------- layout

/** Back button + title for pages outside the tab shell (the app's ScreenHeader). */
export function PPageHead({
  title,
  subtitle,
  back,
  aside,
}: {
  title: ReactNode
  subtitle?: ReactNode
  /** Where back goes when the visitor landed directly on this page. */
  back: string
  aside?: ReactNode
}) {
  return (
    <div className="p-pagehead">
      <div className="p-wrap p-pagehead-inner">
        <button type="button" className="p-round p-round-light" onClick={() => goBack(back)} aria-label="Go back">
          <PIcon name="back" />
        </button>
        <div className="p-pagehead-text">
          <h1>{title}</h1>
          {subtitle && <p>{subtitle}</p>}
        </div>
        {aside}
      </div>
    </div>
  )
}

/** Page body width wrapper. */
export const PBody = ({ children, narrow = false }: { children: ReactNode; narrow?: boolean }) => (
  <div className={`p-wrap p-body ${narrow ? 'is-narrow' : ''}`}>{children}</div>
)

/** White card (the app's Surface). */
export function PCard({ children, className = '', as: Tag = 'div' }: { children: ReactNode; className?: string; as?: 'div' | 'section' | 'li' }) {
  return <Tag className={`p-card ${className}`}>{children}</Tag>
}

export function PSectionTitle({ children, action }: { children: ReactNode; action?: ReactNode }) {
  return (
    <div className="p-section-title">
      <h2>{children}</h2>
      {action}
    </div>
  )
}

/** Icon tile that links to a tool screen (the app's ToolTile). */
export function ToolTile({ to, icon, label, hint }: { to: string; icon: PIconName; label: string; hint?: string }) {
  return (
    <Link to={to} className="p-tool">
      <span className="p-tool-icon">
        <PIcon name={icon} size={22} />
      </span>
      <span className="p-tool-label">{label}</span>
      {hint && <span className="p-tool-hint">{hint}</span>}
    </Link>
  )
}

export function StatTile({ label, value, hint, tone = 'default' }: { label: string; value: ReactNode; hint?: string; tone?: 'default' | 'ok' | 'warn' }) {
  return (
    <div className={`p-stat is-${tone}`}>
      <span className="p-stat-label">{label}</span>
      <strong className="p-stat-value">{value}</strong>
      {hint && <span className="p-stat-hint">{hint}</span>}
    </div>
  )
}

export function PBadge({ children, tone = 'default' }: { children: ReactNode; tone?: 'default' | 'ok' | 'warn' | 'info' | 'danger' }) {
  return <span className={`p-pill is-${tone}`}>{children}</span>
}

export function EmptyState({ icon = 'clipboard', title, text, action }: { icon?: PIconName; title: string; text?: string; action?: ReactNode }) {
  return (
    <div className="p-empty">
      <span className="p-empty-icon">
        <PIcon name={icon} size={28} />
      </span>
      <h3>{title}</h3>
      {text && <p>{text}</p>}
      {action}
    </div>
  )
}

// ---------------------------------------------------------------- forms

export function PField({
  label,
  hint,
  error,
  children,
}: {
  label: string
  hint?: string
  error?: string | null
  children: ReactNode
}) {
  return (
    <label className={`p-field ${error ? 'has-error' : ''}`}>
      <span className="p-field-label">{label}</span>
      {children}
      {error ? <span className="p-field-error">{error}</span> : hint && <span className="p-field-hint">{hint}</span>}
    </label>
  )
}

/** Toggle chips for multi-select (skills, languages, amenities…). */
export function ChipGroup({
  options,
  value,
  onChange,
  single = false,
}: {
  options: string[]
  value: string[]
  onChange: (next: string[]) => void
  single?: boolean
}) {
  return (
    <div className="p-chips">
      {options.map((o) => {
        const on = value.includes(o)
        return (
          <button
            key={o}
            type="button"
            className={`p-chip ${on ? 'is-on' : ''}`}
            aria-pressed={on}
            onClick={() => onChange(single ? [o] : on ? value.filter((v) => v !== o) : [...value, o])}
          >
            {on && <PIcon name="check" size={14} />} {o}
          </button>
        )
      })}
    </div>
  )
}

export function Toggle({ checked, onChange, label }: { checked: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <button type="button" role="switch" aria-checked={checked} aria-label={label} className={`p-switch ${checked ? 'is-on' : ''}`} onClick={() => onChange(!checked)}>
      <span />
    </button>
  )
}

/** Document upload row (the app's UploadTile). Keeps only the file name — demo mode. */
export function UploadTile({
  label,
  hint,
  fileName,
  onFile,
  accept = 'image/*,application/pdf',
}: {
  label: string
  hint?: string
  fileName?: string | null
  onFile: (name: string | null) => void
  accept?: string
}) {
  const ref = useRef<HTMLInputElement>(null)
  return (
    <div className={`p-upload ${fileName ? 'is-done' : ''}`}>
      <span className="p-upload-icon">
        <PIcon name={fileName ? 'check' : 'upload'} size={20} />
      </span>
      <span className="p-upload-text">
        <strong>{label}</strong>
        <span>{fileName ?? hint ?? 'PDF or photo, up to 5 MB'}</span>
      </span>
      <input
        ref={ref}
        type="file"
        accept={accept}
        className="sr-only"
        onChange={(e) => {
          const f = e.target.files?.[0]
          if (f) onFile(f.name)
          e.target.value = ''
        }}
      />
      {fileName ? (
        <button type="button" className="p-btn p-btn-ghost p-btn-sm" onClick={() => onFile(null)}>
          Remove
        </button>
      ) : (
        <button type="button" className="p-btn p-btn-outline p-btn-sm" onClick={() => ref.current?.click()}>
          Upload
        </button>
      )}
    </div>
  )
}

// ---------------------------------------------------------------- wizard

/**
 * Multi-step form shell (the app's WizardScaffold): step progress, the
 * current step's body, and Back / Continue. `canContinue` gates Continue;
 * the last step's button runs `onFinish`.
 */
export function Wizard({
  title,
  steps,
  step,
  onStep,
  canContinue,
  onFinish,
  finishLabel = 'Submit',
  back,
  children,
}: {
  title: string
  steps: string[]
  step: number
  onStep: (n: number) => void
  canContinue: boolean
  onFinish: () => void | Promise<void>
  finishLabel?: string
  back: string
  children: ReactNode
}) {
  const [busy, setBusy] = useState(false)
  const last = step === steps.length - 1
  const next = async () => {
    if (!canContinue || busy) return
    if (!last) {
      onStep(step + 1)
      window.scrollTo({ top: 0, behavior: 'smooth' })
      return
    }
    setBusy(true)
    try {
      await onFinish()
    } finally {
      setBusy(false)
    }
  }
  return (
    <>
      <PPageHead title={title} subtitle={`Step ${step + 1} of ${steps.length} · ${steps[step]}`} back={back} />
      <PBody narrow>
        <ol className="p-steps" aria-label="Progress">
          {steps.map((s, i) => (
            <li key={s} className={i < step ? 'is-done' : i === step ? 'is-current' : ''} aria-current={i === step ? 'step' : undefined}>
              <span className="p-steps-dot">{i < step ? <PIcon name="check" size={14} /> : i + 1}</span>
              <span className="p-steps-label">{s}</span>
            </li>
          ))}
        </ol>
        <div className="p-wizard-body">{children}</div>
        <div className="p-wizard-actions">
          {step > 0 && (
            <button type="button" className="p-btn p-btn-outline" onClick={() => onStep(step - 1)} disabled={busy}>
              Back
            </button>
          )}
          <button type="button" className="p-btn p-btn-primary" onClick={next} disabled={!canContinue || busy}>
            {busy ? 'Please wait…' : last ? finishLabel : 'Continue'}
          </button>
        </div>
      </PBody>
    </>
  )
}
