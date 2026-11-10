import { useRef, useState } from 'react'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { PBody, PIcon, PPageHead } from '../ui'
import { CentreDialog } from './CentreDialog'
import type { ComplianceDoc } from './data'
import { markDocUploaded, useCompliance } from './state'
import './centre.css'

// Regulatory & KYC compliance (features/centre/presentation/compliance/compliance_screen.dart):
// statutory clearances needed before ALLCURO's site visit. Upload / re-upload
// each one; a fresh upload goes back to "awaiting verification".

const MAX_MB = 15

export function CentreCompliancePage() {
  const docs = useCompliance()
  const [uploading, setUploading] = useState<ComplianceDoc | null>(null)
  const uploaded = docs.filter((d) => d.isUploaded).length
  const allUploaded = uploaded === docs.length

  return (
    <>
      <PPageHead title="Regulatory & KYC Compliance" subtitle="Mandatory statutory clearances to activate facility beds" back={PR.centreHome} />
      <PBody>
        <div className={`p-note ${allUploaded ? 'is-ok' : ''}`} role="status">
          <PIcon name={allUploaded ? 'shield' : 'sos'} size={18} />
          <span>
            {allUploaded
              ? `All ${uploaded} regulatory compliance documents uploaded`
              : `${uploaded} of ${docs.length} documents uploaded. Complete remaining for site visit.`}
          </span>
        </div>

        <ul className="pc-grid">
          {docs.map((doc) => (
            <li key={doc.id}>
              <article className="p-card pc-doc">
                <span className="pc-doc-icon" aria-hidden="true">
                  <PIcon name="file" size={20} />
                </span>
                <div className="p-row-grow">
                  <h3>{doc.title}</h3>
                  <span className="p-muted pc-small pc-doc-meta">
                    {doc.fileName} · {doc.expiry}
                  </span>
                  {doc.isUploaded && !doc.isVerified && <span className="pc-small pc-doc-pending">Awaiting ALLCURO verification</span>}
                  <button type="button" className="p-btn p-btn-ghost p-btn-sm pc-link-btn" onClick={() => setUploading(doc)}>
                    <PIcon name="upload" size={15} /> {doc.isUploaded ? 'Re-upload / Update' : 'Upload Document'}
                  </button>
                </div>
                <span className={`p-pill ${doc.isUploaded ? 'is-ok' : 'is-warn'}`}>{doc.isUploaded ? 'Uploaded' : 'Pending'}</span>
              </article>
            </li>
          ))}
        </ul>
      </PBody>

      {uploading && <UploadDialog doc={uploading} onClose={() => setUploading(null)} />}
    </>
  )
}

function UploadDialog({ doc, onClose }: { doc: ComplianceDoc; onClose: () => void }) {
  const input = useRef<HTMLInputElement>(null)
  const [error, setError] = useState<string | null>(null)

  const onFile = (file: File | undefined) => {
    if (!file) return
    if (file.size > MAX_MB * 1024 * 1024) {
      setError(`That file is larger than ${MAX_MB} MB.`)
      return
    }
    markDocUploaded(doc.id, file.name)
    toast(`Uploaded new file for ${doc.title}`)
    onClose()
  }

  return (
    <CentreDialog title={`Upload ${doc.title.split('(')[0].trim()}`} onClose={onClose}>
      <p className="pc-dialog-text">Upload PDF, JPG or PNG certificate (Max {MAX_MB}MB). Verified by ALLCURO compliance operations.</p>
      <button type="button" className="pc-choose" onClick={() => input.current?.click()}>
        <span className="pc-summary-icon">
          <PIcon name="upload" size={20} />
        </span>
        <span className="p-row-grow">
          <strong>Choose Document from Device</strong>
          <span className="p-muted pc-small">Select file from local storage</span>
        </span>
        <PIcon name="chevron" size={18} />
      </button>
      <input
        ref={input}
        type="file"
        accept="application/pdf,image/jpeg,image/png"
        className="sr-only"
        tabIndex={-1}
        aria-hidden="true"
        onChange={(e) => {
          onFile(e.target.files?.[0])
          e.target.value = ''
        }}
      />
      {error && (
        <p className="p-field-error" role="alert">
          {error}
        </p>
      )}
    </CentreDialog>
  )
}
