import { useState } from 'react'
import { Link } from '../../components/Link'
import { goBack } from '../../router'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { EmptyState, PBody, PCard, PIcon, PPageHead, type PIconName } from '../ui'
import type { JobRequestSummary } from './data'
import { PageIntro } from './parts'
import { acceptRequest, declineRequest, requestDetail, requestsStore, restoreDemoRequests } from './state'

// Shift requests — requests/job_requests_screen.dart (tab) and
// requests/job_detail_screen.dart (full-screen detail).

export function NurseRequestsPage() {
  const requests = requestsStore.use()
  return (
    <PBody>
      <PageIntro title="Requests" subtitle="New shift requests waiting for your response" />
      {requests.length === 0 ? (
        <PCard>
          <EmptyState
            icon="clipboard"
            title="No pending requests right now"
            text="New patient requests in your service area will show up here."
            action={
              <button type="button" className="p-btn p-btn-outline p-btn-sm" onClick={restoreDemoRequests}>
                Reload demo requests
              </button>
            }
          />
        </PCard>
      ) : (
        <ul className="p-list pn-grid2">
          {requests.map((r) => (
            <li key={r.id}>
              <RequestCard request={r} />
            </li>
          ))}
        </ul>
      )}
    </PBody>
  )
}

function RequestCard({ request: r }: { request: JobRequestSummary }) {
  const [busy, setBusy] = useState<null | 'accept' | 'decline'>(null)
  const act = async (kind: 'accept' | 'decline') => {
    setBusy(kind)
    if (kind === 'accept') {
      await acceptRequest(r.id)
      toast(`Accepted — ${r.patientName} added to your schedule.`)
    } else {
      await declineRequest(r.id)
      toast(`Declined request from ${r.patientName}.`, 'info')
    }
  }
  return (
    <PCard className="pn-req">
      <Link to={PR.nurseRequestDetail(r.id)} className="pn-req-main" aria-label={`Open request: ${r.serviceType}, ${r.patientName}`}>
        <span className="p-row-grow pn-ellipsis-col">
          <strong className="pn-title pn-ellipsis">{r.serviceType}</strong>
          <span className="p-muted pn-small pn-ellipsis">
            {r.patientName} · {r.locality}
          </span>
        </span>
        <strong className="pn-pay">{r.pay}</strong>
      </Link>
      <div className="pn-timing">
        <PIcon name="clock" size={14} />
        <span className="pn-ellipsis">{r.timing}</span>
      </div>
      <div className="pn-btn-pair">
        <button type="button" className="p-btn p-btn-outline pn-pill-btn" disabled={busy != null} onClick={() => act('decline')}>
          {busy === 'decline' ? 'Declining…' : 'Decline'}
        </button>
        <button type="button" className="p-btn p-btn-primary pn-pill-btn pn-accent-btn" disabled={busy != null} onClick={() => act('accept')}>
          {busy === 'accept' ? 'Accepting…' : 'Accept'}
        </button>
      </div>
    </PCard>
  )
}

export function NurseRequestDetailPage({ id }: { id: string }) {
  const requests = requestsStore.use()
  const d = requestDetail(id)
  const pending = requests.some((r) => r.id === id)
  const [busy, setBusy] = useState<null | 'accept' | 'decline'>(null)

  if (!d || !pending) {
    return (
      <>
        <PPageHead title="Request details" subtitle={`Ref. ${id}`} back={PR.nurseRequests} />
        <PBody narrow>
          <PCard>
            <EmptyState
              icon="clipboard"
              title={d ? 'This request is no longer pending' : 'Could not load this request'}
              text={d ? 'It was already accepted or declined. Accepted requests appear in your schedule.' : `No request found for id "${id}".`}
              action={
                <Link to={d ? PR.nurseSchedule : PR.nurseRequests} className="p-btn p-btn-primary p-btn-sm">
                  {d ? 'Open schedule' : 'Back to requests'}
                </Link>
              }
            />
          </PCard>
        </PBody>
      </>
    )
  }

  const act = async (kind: 'accept' | 'decline') => {
    setBusy(kind)
    if (kind === 'accept') {
      await acceptRequest(id)
      toast(`Accepted — ${d.patientName} added to your schedule.`)
    } else {
      await declineRequest(id)
      toast(`Declined request from ${d.patientName}.`, 'info')
    }
    goBack(PR.nurseRequests)
  }

  const rows: { icon: PIconName; label: string; value: string }[] = [
    { icon: 'pin', label: 'Address', value: d.address },
    { icon: 'clock', label: 'Timing', value: d.timingDetail },
    { icon: 'heart', label: 'Condition', value: d.condition },
    { icon: 'users', label: 'Family contact', value: d.familyContactNote },
  ]

  return (
    <>
      <PPageHead title="Request details" subtitle={`Ref. ${d.id}`} back={PR.nurseRequests} />
      <PBody narrow>
        <div className="pn-patient">
          <span className="pn-avatar-lg" aria-hidden="true">
            {d.patientInitials}
          </span>
          <div>
            <h2>{d.patientName}</h2>
            <p className="p-muted">{d.serviceSummary}</p>
          </div>
        </div>

        <PCard>
          <dl className="pn-details">
            {rows.map((r) => (
              <div key={r.label}>
                <PIcon name={r.icon} size={18} />
                <dt>{r.label}</dt>
                <dd>{r.value}</dd>
              </div>
            ))}
          </dl>
        </PCard>

        <section className="pn-stack">
          <h3 className="pn-overline">Care requirements</h3>
          <ul className="pn-tags">
            {d.careRequirements.map((t) => (
              <li key={t}>{t}</li>
            ))}
          </ul>
        </section>

        <section className="pn-stack">
          <h3 className="pn-overline">Pay breakdown</h3>
          <PCard>
            <div className="pn-payrow">
              <span className="p-muted">Per shift</span>
              <strong>{d.payPerShift}</strong>
            </div>
            <div className="pn-payrow">
              <span className="p-muted">{d.payEstimateLabel}</span>
              <strong>{d.payEstimateValue}</strong>
            </div>
          </PCard>
        </section>

        <div className="pn-sticky-actions">
          <button type="button" className="p-btn p-btn-outline" disabled={busy != null} onClick={() => act('decline')}>
            {busy === 'decline' ? 'Declining…' : 'Decline'}
          </button>
          <button type="button" className="p-btn p-btn-primary pn-accent-btn" disabled={busy != null} onClick={() => act('accept')}>
            {busy === 'accept' ? 'Accepting…' : 'Accept request'}
          </button>
        </div>
      </PBody>
    </>
  )
}
