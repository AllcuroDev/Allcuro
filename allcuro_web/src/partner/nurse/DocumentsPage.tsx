import { useRef, useState } from 'react'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { practitionerIdentity, uploadPartnerDocument, usePartnerSession } from '../session'
import { PBody, PIcon, PPageHead } from '../ui'
import type { ComplianceDoc } from './data'
import { maskedAadhaar, nurseDocs } from './state'

// Document vault & KYC — documents/document_vault_screen.dart. Aadhaar and
// council registration were given at sign-up, so only certificates are
// uploaded here — to the private kyc-documents bucket, recorded on the
// partner row for the admin to review.

export function NurseDocumentsPage() {
  const session = usePartnerSession()
  const identity = practitionerIdentity(session)
  const docs = nurseDocs(session)
  const isClinician = session.role === 'clinician'

  return (
    <>
      <PPageHead title="Document Vault & KYC" subtitle="Upload your certificates so ALLCURO can review your profile" back={PR.nurseHome} />
      <PBody narrow>
        <div className="p-note">
          <PIcon name="shield" size={18} />
          <strong className="pn-fw500">
            {identity
              ? `Aadhaar ${maskedAadhaar(identity.aadhaarLast4)} & ${identity.registrationLabel} ${identity.registrationNumber} were added at sign-up — no uploads needed for them`
              : 'Aadhaar & registration are added at sign-up — no uploads needed for them'}
          </strong>
        </div>
        <p className="p-muted pn-small pn-m0">
          Upload PDF, JPG or PNG (Max 15MB). ALLCURO checks them against the {isClinician ? 'State Medical / Physiotherapy Council' : 'State Nursing Council'} register.
        </p>
        <ul className="p-list">
          {docs.map((d) => (
            <li key={d.id}>
              <DocRow doc={d} title={(isClinician && d.clinicianTitle) || d.title} />
            </li>
          ))}
        </ul>
      </PBody>
    </>
  )
}

function DocRow({ doc, title }: { doc: ComplianceDoc; title: string }) {
  const ref = useRef<HTMLInputElement>(null)
  const [busy, setBusy] = useState(false)
  const status = busy
    ? { label: 'Uploading…', tone: 'is-info' }
    : !doc.isUploaded
    ? { label: 'Not uploaded', tone: 'is-warn' }
    : doc.isVerified
      ? { label: 'Verified', tone: 'is-ok' }
      : { label: 'Awaiting review', tone: 'is-info' }
  return (
    <div className={`p-upload ${doc.isUploaded ? 'is-done' : ''} pn-doc`}>
      <span className="p-upload-icon">
        <PIcon name={doc.isUploaded ? 'file' : 'upload'} size={20} />
      </span>
      <span className="p-upload-text">
        <strong>{title}</strong>
        <span>{doc.isUploaded ? doc.fileName : doc.expiry}</span>
        {doc.isUploaded && <span>{doc.expiry}</span>}
      </span>
      <span className="pn-doc-side">
        <span className={`p-pill ${status.tone}`}>{status.label}</span>
        <button type="button" className="p-btn p-btn-outline p-btn-sm" disabled={busy} onClick={() => ref.current?.click()} aria-label={`${doc.isUploaded ? 'Replace' : 'Upload'} ${title}`}>
          {doc.isUploaded ? 'Replace' : 'Upload'}
        </button>
      </span>
      <input
        ref={ref}
        type="file"
        accept="image/jpeg,image/png,application/pdf"
        className="sr-only"
        tabIndex={-1}
        aria-hidden="true"
        onChange={(e) => {
          const f = e.target.files?.[0]
          e.target.value = ''
          if (!f) return
          if (f.size > 15 * 1024 * 1024) {
            toast('File is larger than 15MB.', 'danger')
            return
          }
          setBusy(true)
          uploadPartnerDocument(doc.id, f)
            .then(() => toast(`Uploaded ${title}`))
            .catch((err: unknown) => toast(err instanceof Error ? err.message : 'Upload failed.', 'danger'))
            .finally(() => setBusy(false))
        }}
      />
    </div>
  )
}
