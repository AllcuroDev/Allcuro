import type { ReactNode } from 'react'
import { toast } from '../../lib/toast'
import { usePartnerSession } from '../session'
import { EmptyState, PBody, PCard, PIcon, PSectionTitle } from '../ui'
import type { PlacementRequest } from './data'
import { useBusy } from './hooks'
import { acceptRequest, bedCounts, declineRequest, restoreDemoRequests, useRequests, useRooms, waitlistRequest } from './state'
import './centre.css'

// Placement requests (features/centre/presentation/requests/centre_requests_screen.dart):
// accept or decline each family's request based on bed availability, or park
// it on the waitlist until a bed frees up.

export function CentreRequestsPage() {
  const req = useRequests()
  const rooms = useRooms()
  const { vacant } = bedCounts(rooms)
  const s = usePartnerSession()
  const [busy, run] = useBusy()

  const accept = (r: PlacementRequest) =>
    run(`${r.id}:accept`, async () => {
      await acceptRequest(r.id)
      toast(`Accepted ${r.careType.toLowerCase()} for ${r.familyContact.replace(/^Family of /, '')}'s family`)
    })
  const waitlist = (r: PlacementRequest) =>
    run(`${r.id}:wait`, async () => {
      await waitlistRequest(r.id)
      toast('Moved to waitlist — the family will be told you have no bed right now', 'info')
    })
  const decline = (r: PlacementRequest) =>
    run(`${r.id}:decline`, async () => {
      await declineRequest(r.id)
      toast('Request declined', 'info')
    })

  return (
    <PBody>
      <header className="pc-tab-head">
        <h1>Requests</h1>
        <p>Placement requests waiting for your response</p>
      </header>

      {s.centreStatus !== 'verified' && (
        <div className="p-note is-info" role="note">
          <PIcon name="clock" size={18} />
          <span>Your centre isn&apos;t live yet. These are sample requests — real families can book once ALLCURO verifies your facility.</span>
        </div>
      )}

      <div className={`p-note ${vacant > 0 ? 'is-ok' : ''}`} role="status">
        <PIcon name="bed" size={18} />
        <span>
          {vacant > 0 ? `${vacant} bed${vacant === 1 ? '' : 's'} vacant right now.` : 'All beds are occupied — consider waitlisting new requests.'}
        </span>
      </div>

      {req.pending.length === 0 ? (
        <PCard>
          <EmptyState
            icon="clipboard"
            title="No placement requests right now"
            text="New requests from families appear here."
            action={
              <button type="button" className="p-btn p-btn-outline p-btn-sm" onClick={restoreDemoRequests}>
                Load sample requests
              </button>
            }
          />
        </PCard>
      ) : (
        <ul className="pc-cards">
          {req.pending.map((r) => (
            <li key={r.id}>
              <RequestCard request={r}>
                <button type="button" className="p-btn p-btn-outline pc-pill-btn" onClick={() => decline(r)} disabled={!!busy}>
                  {busy === `${r.id}:decline` ? 'Declining…' : 'Decline'}
                </button>
                <button type="button" className="p-btn p-btn-outline pc-pill-btn" onClick={() => waitlist(r)} disabled={!!busy}>
                  {busy === `${r.id}:wait` ? 'Saving…' : 'Waitlist'}
                </button>
                <button type="button" className="p-btn p-btn-primary pc-pill-btn" onClick={() => accept(r)} disabled={!!busy}>
                  {busy === `${r.id}:accept` ? 'Accepting…' : 'Accept'}
                </button>
              </RequestCard>
            </li>
          ))}
        </ul>
      )}

      {req.waitlisted.length > 0 && (
        <section className="pc-stack" aria-labelledby="pc-waitlist">
          <PSectionTitle>
            <span id="pc-waitlist">Waitlist ({req.waitlisted.length})</span>
          </PSectionTitle>
          <ul className="pc-cards">
            {req.waitlisted.map((r) => (
              <li key={r.id}>
                <RequestCard request={r} waitlisted>
                  <button type="button" className="p-btn p-btn-outline pc-pill-btn" onClick={() => decline(r)} disabled={!!busy}>
                    {busy === `${r.id}:decline` ? 'Declining…' : 'Decline'}
                  </button>
                  <button
                    type="button"
                    className="p-btn p-btn-primary pc-pill-btn"
                    onClick={() => accept(r)}
                    disabled={!!busy || vacant === 0}
                    title={vacant === 0 ? 'No vacant beds' : undefined}
                  >
                    {busy === `${r.id}:accept` ? 'Accepting…' : 'Admit now'}
                  </button>
                </RequestCard>
              </li>
            ))}
          </ul>
        </section>
      )}
    </PBody>
  )
}

function RequestCard({
  request: r,
  waitlisted = false,
  children,
}: {
  request: PlacementRequest
  waitlisted?: boolean
  children: ReactNode
}) {
  return (
    <article className="p-card pc-req" aria-label={`${r.careType}, ${r.familyContact}`}>
      <div className="pc-req-head">
        <div className="p-row-grow">
          <h3>{r.careType}</h3>
          <span className="p-muted">{r.familyContact}</span>
        </div>
        {waitlisted && <span className="p-pill is-warn">Waitlisted</span>}
      </div>
      <div className="pc-req-pref">
        <PIcon name="help" size={15} />
        <span>{r.preference}</span>
      </div>
      <div className="pc-req-meta">
        <PIcon name="clock" size={15} />
        <span>{r.duration}</span>
      </div>
      <div className={`pc-req-actions ${waitlisted ? 'is-two' : ''}`}>{children}</div>
    </article>
  )
}
