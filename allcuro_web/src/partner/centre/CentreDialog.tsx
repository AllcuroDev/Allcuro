import { useEffect, useId, useRef, type FormEvent, type ReactNode } from 'react'
import { PIcon } from '../ui'

// Native <dialog> modals for the centre pages (the app's Dialog /
// showModalBottomSheet). Mount it to open it; unmount to close.

export function CentreDialog({
  title,
  onClose,
  children,
  onSubmit,
  submitLabel,
  submitTone = 'primary',
  busy = false,
  wide = false,
}: {
  title: string
  onClose: () => void
  children: ReactNode
  /** When set, the body is a form and the footer shows Cancel + submit. */
  onSubmit?: () => void | Promise<void>
  submitLabel?: string
  submitTone?: 'primary' | 'danger'
  busy?: boolean
  wide?: boolean
}) {
  const ref = useRef<HTMLDialogElement>(null)
  const titleId = useId()

  useEffect(() => {
    const d = ref.current
    if (d && !d.open) d.showModal()
    document.body.classList.add('no-scroll')
    return () => document.body.classList.remove('no-scroll')
  }, [])

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (!busy) void onSubmit?.()
  }

  const inner = (
    <>
      <div className="pc-dialog-head">
        <h2 id={titleId}>{title}</h2>
        <button type="button" className="pc-icon-btn" onClick={onClose} aria-label="Close">
          <PIcon name="close" size={18} />
        </button>
      </div>
      {children}
      {onSubmit && (
        <div className="p-dialog-actions pc-dialog-actions">
          <button type="button" className="p-btn p-btn-outline" onClick={onClose} disabled={busy}>
            Cancel
          </button>
          <button type="submit" className={`p-btn ${submitTone === 'danger' ? 'p-btn-danger' : 'p-btn-primary'}`} disabled={busy}>
            {busy ? 'Please wait…' : submitLabel}
          </button>
        </div>
      )}
    </>
  )

  return (
    <dialog
      ref={ref}
      className={`p-dialog pc-dialog ${wide ? 'is-wide' : ''}`}
      aria-labelledby={titleId}
      onCancel={(e) => {
        e.preventDefault()
        if (!busy) onClose()
      }}
      onClick={(e) => !busy && e.target === ref.current && onClose()}
    >
      {onSubmit ? (
        <form className="p-dialog-body" onSubmit={submit} noValidate>
          {inner}
        </form>
      ) : (
        <div className="p-dialog-body">{inner}</div>
      )}
    </dialog>
  )
}

/** "Remove X?" confirmation. */
export function ConfirmDialog({
  title,
  text,
  confirmLabel,
  onConfirm,
  onClose,
}: {
  title: string
  text: ReactNode
  confirmLabel: string
  onConfirm: () => void
  onClose: () => void
}) {
  return (
    <CentreDialog
      title={title}
      onClose={onClose}
      submitLabel={confirmLabel}
      submitTone="danger"
      onSubmit={() => {
        onConfirm()
        onClose()
      }}
    >
      <p className="pc-dialog-text">{text}</p>
    </CentreDialog>
  )
}
