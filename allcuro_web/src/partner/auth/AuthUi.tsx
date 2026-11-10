import { type ReactNode } from 'react'
import { Modal } from '../../components/ui'
import { PIcon } from '../ui'
import './auth.css'

// Building blocks shared by the partner auth / onboarding pages — the web
// twins of the app's pre-auth gradient screens and core/ui/wizard_scaffold.dart
// (WizardScaffold, WizardStepHeader, WizardVerifiedCard, consent tiles).

/** The ALLCURO Partner heart-monitor mark used on the brand screens. */
export function BrandMark({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  return (
    <span className={`pa-mark is-${size}`} aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
        <rect x="3" y="4" width="18" height="14" rx="3" />
        <path d="M6 11h3l1.5-3 3 6 1.5-3h3M9 21h6" />
      </svg>
    </span>
  )
}

/** Full-height green gradient screen with soft decorative circles (welcome, sign-in, role select). */
export function BrandScreen({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`pa-brand ${className}`}>
      <span className="pa-blob is-1" aria-hidden="true" />
      <span className="pa-blob is-2" aria-hidden="true" />
      <span className="pa-blob is-3" aria-hidden="true" />
      <div className="pa-brand-inner">{children}</div>
      <PartnerShowcase />
    </div>
  )
}

/**
 * Right-hand panel of the brand screens on desktop (hidden on phones): a
 * preview of what the partner app does — a visit request, weekly payouts and
 * bed occupancy — plus the three things partners get. Purely illustrative.
 */
function PartnerShowcase() {
  return (
    <aside className="pa-showcase" aria-hidden="true">
      <p className="pa-showcase-eyebrow">Inside the partner app</p>
      <div className="pa-show-card pa-show-request">
        <div className="pa-show-row">
          <span className="pa-show-pill">New visit request</span>
          <span className="pa-show-muted">2.1 km away</span>
        </div>
        <strong>Post-op wound care · 45 min</strong>
        <span className="pa-show-muted">Indiranagar, Bengaluru · Today 4:30 PM</span>
        <div className="pa-show-row">
          <b>₹1,600</b>
          <span className="pa-show-btn">Accept</span>
        </div>
      </div>
      <div className="pa-show-grid">
        <div className="pa-show-card">
          <span className="pa-show-muted">Payouts this week</span>
          <b className="pa-show-big">₹14,250</b>
          <span className="pa-show-bars">
            {[40, 65, 50, 80, 58, 92, 70].map((h, i) => (
              <span key={i} style={{ height: `${h}%` }} />
            ))}
          </span>
        </div>
        <div className="pa-show-card">
          <span className="pa-show-muted">Bed occupancy</span>
          <b className="pa-show-big">4 / 6</b>
          <span className="pa-show-meter">
            <span style={{ width: '66%' }} />
          </span>
          <span className="pa-show-muted">2 beds open for admission</span>
        </div>
      </div>
      <ul className="pa-show-points">
        <li>
          <PIcon name="wallet" size={18} /> Direct payouts to your bank via Razorpay Route
        </li>
        <li>
          <PIcon name="shield" size={18} /> Verified patients, families and partners
        </li>
        <li>
          <PIcon name="sos" size={18} /> 24×7 operations desk and SOS on every visit
        </li>
      </ul>
    </aside>
  )
}

/** Round back button for the gradient screens. */
export function BrandBack({ onClick, label = 'Go back' }: { onClick: () => void; label?: string }) {
  return (
    <button type="button" className="pa-back" onClick={onClick} aria-label={label}>
      <PIcon name="back" />
    </button>
  )
}

/** Spinner shown inside a busy button. */
export const ButtonSpinner = () => <span className="pa-spinner" aria-hidden="true" />

/**
 * Multi-step shell (the app's WizardScaffold): back button, a progress bar
 * with "N/total", the current step, and a sticky action bar with the primary
 * button (label/action decided by the page) and an optional text action.
 */
export function AuthWizard({
  label,
  stepIndex,
  stepCount,
  onBack,
  primaryLabel,
  onPrimary,
  busy = false,
  secondaryLabel,
  onSecondary,
  children,
}: {
  /** Accessible name of the flow, e.g. "Nurse sign-up". */
  label: string
  stepIndex: number
  stepCount: number
  onBack: () => void
  primaryLabel: string
  /** Null renders the primary button disabled. */
  onPrimary: (() => void) | null
  busy?: boolean
  secondaryLabel?: string
  onSecondary?: () => void
  children: ReactNode
}) {
  const pct = Math.round(((stepIndex + 1) / stepCount) * 100)
  return (
    <div className="pa-wizard-shell">
      {/* Desktop only: brand panel with the step list and help (hidden on phones). */}
      <aside className="pa-wizard-aside">
        <div className="pa-wizard-aside-inner">
          <BrandMark size="md" />
          <p className="pa-eyebrow">ALLCURO PARTNER</p>
          <h2 className="pa-wizard-aside-title">{label}</h2>
          <ol className="pa-aside-steps">
            {Array.from({ length: stepCount }, (_, i) => (
              <li key={i} className={i < stepIndex ? 'is-done' : i === stepIndex ? 'is-current' : ''}>
                <span>{i < stepIndex ? <PIcon name="check" size={14} /> : i + 1}</span>
                Step {i + 1}
                {i === stepIndex && <em>· you are here</em>}
              </li>
            ))}
          </ol>
          <ul className="pa-show-points">
            <li>
              <PIcon name="shield" size={18} /> Your documents are encrypted and only seen by ALLCURO verification staff.
            </li>
            <li>
              <PIcon name="clock" size={18} /> Takes about 5 minutes. You can finish the rest later from your home screen.
            </li>
            <li>
              <PIcon name="phone" size={18} /> Stuck? Our partner desk helps 24×7.
            </li>
          </ul>
        </div>
      </aside>
    <div className="pa-wizard">
      <div className="pa-wizard-top">
        <div className="pa-wizard-bar">
          <button type="button" className="p-round p-round-light" onClick={onBack} aria-label={stepIndex > 0 ? 'Previous step' : 'Exit'}>
            <PIcon name="back" />
          </button>
          <div
            className="pa-progress"
            role="progressbar"
            aria-label={`${label} progress`}
            aria-valuemin={1}
            aria-valuemax={stepCount}
            aria-valuenow={stepIndex + 1}
            aria-valuetext={`Step ${stepIndex + 1} of ${stepCount}`}
          >
            <span style={{ width: `${pct}%` }} />
          </div>
          <span className="pa-progress-count">
            {stepIndex + 1}/{stepCount}
          </span>
        </div>
      </div>

      <form
        className="pa-wizard-form"
        onSubmit={(e) => {
          e.preventDefault()
          if (onPrimary && !busy) onPrimary()
        }}
        aria-label={label}
      >
        <div className="pa-wizard-body" key={stepIndex}>
          {children}
        </div>
        <div className="pa-wizard-actions">
          <button type="submit" className="p-btn p-btn-primary p-btn-block pa-pill" disabled={!onPrimary || busy} aria-busy={busy}>
            {busy ? <ButtonSpinner /> : primaryLabel}
          </button>
          {secondaryLabel && onSecondary && (
            <button type="button" className="p-btn p-btn-ghost p-btn-block" onClick={onSecondary} disabled={busy}>
              {secondaryLabel}
            </button>
          )}
        </div>
      </form>
    </div>
    </div>
  )
}

/** A step's title + optional subtitle (WizardStepHeader). */
export function StepHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <header className="pa-step-head">
      <h1>{title}</h1>
      {subtitle && <p>{subtitle}</p>}
    </header>
  )
}

/** Small uppercase label above a group of chips (WizardSectionLabel). */
export const SectionLabel = ({ children, id }: { children: ReactNode; id?: string }) => (
  <p className="pa-section-label" id={id}>
    {children}
  </p>
)

/** Single-select pill group (WizardChoiceChip × n). */
export function ChoiceChips({
  options,
  value,
  onChange,
  labelledBy,
}: {
  options: string[]
  value: string | null
  onChange: (v: string) => void
  labelledBy: string
}) {
  return (
    <div className="p-chips" role="radiogroup" aria-labelledby={labelledBy}>
      {options.map((o) => (
        <button
          key={o}
          type="button"
          role="radio"
          aria-checked={value === o}
          className={`p-chip pa-chip ${value === o ? 'is-on' : ''}`}
          onClick={() => onChange(o)}
        >
          {value === o && <PIcon name="check" size={14} />} {o}
        </button>
      ))}
    </div>
  )
}

/** Read-only details fetched from a verified source (WizardVerifiedCard). */
export function VerifiedCard({ title, rows }: { title: string; rows: [string, string][] }) {
  return (
    <section className="pa-verified" aria-label={title}>
      <div className="pa-verified-head">
        <span className="pa-verified-icon">
          <PIcon name="shield" size={18} />
        </span>
        <strong>{title}</strong>
        <span className="pa-lock" title="Locked — from a verified source">
          <LockIcon />
          <span className="sr-only">Locked</span>
        </span>
      </div>
      <dl>
        {rows.map(([k, v]) => (
          <div key={k}>
            <dt>{k}</dt>
            <dd>{v || '—'}</dd>
          </div>
        ))}
      </dl>
    </section>
  )
}

/** Label/value summary list used on the review steps (_SummaryRow × n). */
export function SummaryList({ rows }: { rows: [string, string][] }) {
  return (
    <dl className="pa-summary">
      {rows.map(([k, v]) => (
        <div key={k}>
          <dt>{k}</dt>
          <dd>{v || '—'}</dd>
        </div>
      ))}
    </dl>
  )
}

/** Read-only text field with a lock icon (WizardTextField locked: true). */
export function LockedField({ label, value }: { label: string; value: string }) {
  return (
    <label className="p-field">
      <span className="p-field-label">{label}</span>
      <span className="pa-locked-input">
        <input value={value} readOnly aria-readonly="true" />
        <LockIcon />
      </span>
    </label>
  )
}

/** Large tappable checkbox row for consents. */
export function ConsentBox({ checked, onChange, children }: { checked: boolean; onChange: (v: boolean) => void; children: ReactNode }) {
  return (
    <label className={`pa-consent ${checked ? 'is-on' : ''}`}>
      <input type="checkbox" checked={checked} onChange={(e) => onChange(e.target.checked)} />
      <span className="pa-consent-box" aria-hidden="true">
        {checked && <PIcon name="check" size={16} />}
      </span>
      <span>{children}</span>
    </label>
  )
}

export function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="pa-error" role="alert">
      <PIcon name="sos" size={18} />
      <span>{message}</span>
    </div>
  )
}

/** Confirm dialog — "Exit sign-up?" (exiting logs the partner out, like the app) or "Switch role?". */
export function ConfirmDialog({
  title,
  text,
  confirmLabel = 'Log out',
  tone = 'danger',
  onCancel,
  onConfirm,
}: {
  title: string
  text: string
  confirmLabel?: string
  tone?: 'danger' | 'primary'
  onCancel: () => void
  onConfirm: () => void
}) {
  return (
    <Modal onClose={onCancel} labelledBy="pa-confirm-title">
      <div className="pa-dialog">
        <h2 id="pa-confirm-title">{title}</h2>
        <p>{text}</p>
        <div className="p-dialog-actions">
          <button type="button" className="p-btn p-btn-outline" onClick={onCancel}>
            Cancel
          </button>
          <button type="button" className={`p-btn p-btn-${tone}`} onClick={onConfirm}>
            {confirmLabel}
          </button>
        </div>
      </div>
    </Modal>
  )
}

function LockIcon() {
  return (
    <svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="5" y="11" width="14" height="10" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 8 0v3" />
    </svg>
  )
}
