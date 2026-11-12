import { useId, useState } from 'react'
import { Link } from '../../components/Link'
import { Modal } from '../../components/ui'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { practitionerIdentity, practitionerStatus, setPractitionerStatus, usePartnerSession } from '../session'
import { PBody, PCard, PIcon, PSectionTitle, Toggle, ToolTile, type PIconName } from '../ui'
import { SOS_GPS_HOME, type JobRequestSummary, type NurseVisit } from './data'
import { ProgressBar, SosButton } from './parts'
import {
  availabilityStore,
  effectiveSkills,
  givePoliceConsent,
  greeting,
  kycStore,
  mapsUrl,
  requestsStore,
  setDutyStatus,
  setupProgress,
  shiftsStore,
  telUrl,
  timingHours,
  visitStore,
} from './state'

// Partner home for nurses and clinicians — features/nurse/presentation/home/nurse_home_screen.dart.
// Three stages driven by verification status: setup hub (onboarding),
// under-review audit card, and the live dashboard (verified).

export function NurseHomePage() {
  const session = usePartnerSession()
  const status = practitionerStatus(session)
  const identity = practitionerIdentity(session)
  const name = session.name || identity?.fullName || 'Priya Sharma'
  const isVerified = status === 'verified'
  const isUnderReview = status === 'underReview'
  const isClinician = session.role === 'clinician'

  return (
    <PBody>
      <div className="pn-greet">
        <div className="pn-greet-text">
          <span>{greeting()}</span>
          <h1>{name}</h1>
          <Link to={PR.profile} className="pn-link">
            View profile <PIcon name="chevron" size={14} />
          </Link>
        </div>
        <SosButton
          text="Triggering SOS broadcasts your location to ALLCURO Emergency HQ and dials the 24x7 clinical command desk."
          gps={SOS_GPS_HOME}
          callLabel="Call Allcuro SOS HQ"
          sentMessage="Emergency SOS alert sent! Allcuro team is contacting you."
        />
      </div>

      {isVerified && <DutyStatusBar />}

      <div className="pn-home-grid">
        <div className="pn-col">
          {!isVerified && !isUnderReview && <SetupHub />}
          {isUnderReview && <UnderReviewCard />}
          {isVerified && <LiveDashboard />}
        </div>

        <aside className="pn-col" aria-label={isVerified ? 'Tools' : 'Setup modules'}>
          <PSectionTitle>{isVerified ? (isClinician ? 'Clinical Tools & Practice' : 'Nursing Tools & Practice') : 'Setup Modules'}</PSectionTitle>
          <div className="p-tools pn-tools">
            <ToolTile to={PR.nurseAvailability} icon="clock" label="Availability" />
            <ToolTile to={PR.nurseRatings} icon="chart" label="Performance" />
            <ToolTile to={PR.bankAccount} icon="bank" label="Bank Payout" />
            <ToolTile to={PR.nurseEarnings} icon="wallet" label="Earnings" />
            <ToolTile to={PR.nurseDocuments} icon="file" label="Documents" />
            <ToolTile to={PR.nurseTraining} icon="book" label="Training" />
            <ToolTile to={PR.nurseReferral} icon="gift" label="Referral" />
            <ToolTile to={PR.nurseSupport} icon="help" label="24x7 SOS" />
            <ToolTile to={PR.profile} icon="user" label="Profile" />
          </div>
        </aside>
      </div>
    </PBody>
  )
}

// ---------------------------------------------------------------- duty bar

function DutyStatusBar() {
  const a = availabilityStore.use()
  return (
    <div className={`pn-duty ${a.isOnDuty ? 'is-on' : ''}`}>
      <span className="pn-duty-dot" aria-hidden="true" />
      <div className="pn-duty-text">
        <strong>{a.isOnDuty ? 'ON-DUTY (Available for shifts)' : 'OFF-DUTY (Paused)'}</strong>
        <Link to={PR.nurseAvailability} className="pn-duty-timing" aria-label={`Change shift timing, currently ${a.timing}`}>
          Timing: {timingHours(a.timing)} <PIcon name="edit" size={13} />
        </Link>
      </div>
      <Toggle checked={a.isOnDuty} onChange={(v) => void setDutyStatus(v)} label="On duty" />
    </div>
  )
}

// ---------------------------------------------------------------- verified dashboard

function LiveDashboard() {
  const requests = requestsStore.use()
  const shifts = shiftsStore.use()
  const visit = visitStore.use()
  const active = shifts.filter((s) => s.status !== 'completed')
  const nextShift = shifts.find((s) => s.status === 'ongoing' || s.status === 'upcoming')

  return (
    <>
      {visit.status !== 'completed' && <ActiveVisitCard visit={visit} />}

      <div className="pn-stat-row">
        <div className="pn-stat is-coral">
          <div className="pn-stat-top">
            <strong>{requests.length}</strong>
            <span>Action Required</span>
          </div>
          <span className="pn-stat-label">Pending requests</span>
        </div>
        <div className="pn-stat is-primary">
          <div className="pn-stat-top">
            <strong>{active.length}</strong>
            <span>Scheduled</span>
          </div>
          <span className="pn-stat-label">Shifts this week</span>
        </div>
      </div>

      <section className="pn-stack" aria-labelledby="pn-upcoming">
        <PSectionTitle action={<Link to={PR.nurseSchedule}>View schedule</Link>}>
          <span id="pn-upcoming">Upcoming Schedule</span>
        </PSectionTitle>
        {nextShift ? (
          <PCard className="pn-rowcard">
            <span className="pn-circle">
              <PIcon name="calendar" size={20} />
            </span>
            <div className="p-row-grow">
              <strong className="pn-title">{nextShift.timing}</strong>
              <span className="p-muted pn-small">
                {nextShift.serviceType} · {nextShift.patientName} · {nextShift.locality}
              </span>
            </div>
          </PCard>
        ) : (
          <PCard>
            <span className="p-muted">No upcoming shifts right now</span>
          </PCard>
        )}
      </section>

      <section className="pn-stack" aria-labelledby="pn-newreq">
        <PSectionTitle action={<Link to={PR.nurseRequests}>See all</Link>}>
          <span id="pn-newreq">New Patient Requests</span>
        </PSectionTitle>
        {requests.length === 0 ? (
          <p className="p-muted pn-pad">No pending requests right now</p>
        ) : (
          <ul className="p-list">
            {requests.slice(0, 2).map((r) => (
              <li key={r.id}>
                <RequestPreview request={r} />
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  )
}

function ActiveVisitCard({ visit }: { visit: NurseVisit }) {
  const isReached = visit.status === 'reached'
  const isInProgress = visit.status === 'inProgress'
  return (
    <section className="pn-active" aria-label="Current visit">
      <div className="pn-active-top">
        <span className="pn-live-pill">
          <span aria-hidden="true" />
          {isInProgress ? 'ACTIVE IN-PROGRESS VISIT' : isReached ? 'ARRIVED AT LOCATION' : 'CURRENT BOOKING ACTION'}
        </span>
        <span className="pn-ref">{visit.bookingId}</span>
      </div>
      <div className="pn-active-body">
        <span className="pn-circle">
          <PIcon name="pin" size={22} />
        </span>
        <div className="p-row-grow">
          <strong className="pn-title pn-lg">
            {visit.patientName} ({visit.patientAge}y, {visit.patientGender})
          </strong>
          <span className="pn-coral pn-small">{visit.medicalCondition}</span>
          <span className="p-muted pn-small">{visit.locality}</span>
        </div>
      </div>
      <div className="pn-active-actions">
        <a
          className="p-btn p-btn-outline pn-btn-primary-text"
          href={mapsUrl(visit.address)}
          target="_blank"
          rel="noreferrer"
          onClick={() => toast(`Navigating to ${visit.address}…`, 'info')}
        >
          <PIcon name="navigate" size={16} /> Maps
        </a>
        <a className="p-btn p-btn-outline" href={telUrl(visit.patientPhone)} onClick={() => toast(`Dialing ${visit.patientPhone}…`)}>
          <PIcon name="phone" size={16} /> Call
        </a>
        <Link to={PR.nurseVisitExecution} className="p-btn p-btn-primary pn-grow2">
          <PIcon name="play" size={16} /> {isInProgress ? 'Clinical Log' : 'Start Visit'}
        </Link>
      </div>
    </section>
  )
}

function RequestPreview({ request: r }: { request: JobRequestSummary }) {
  return (
    <Link to={PR.nurseRequestDetail(r.id)} className="p-card pn-rowcard pn-tap">
      <span className="pn-circle is-coral">
        <PIcon name="bolt" size={18} />
      </span>
      <span className="p-row-grow pn-ellipsis-col">
        <strong className="pn-title pn-ellipsis">{r.serviceType}</strong>
        <span className="p-muted pn-small pn-ellipsis">
          {r.patientName} · {r.locality}
        </span>
      </span>
      <strong className="pn-pay">{r.pay}</strong>
      <PIcon name="chevron" size={18} />
    </Link>
  )
}

// ---------------------------------------------------------------- setup hub

function SetupHub() {
  const session = usePartnerSession()
  const kyc = kycStore.use()
  const avail = availabilityStore.use()
  const identity = practitionerIdentity(session)
  const p = setupProgress(kyc, avail, session)
  const pct = Math.round((p.completed / p.total) * 100)
  const skills = effectiveSkills(avail, session)
  const [consentOpen, setConsentOpen] = useState(false)
  const [busy, setBusy] = useState(false)
  const consentId = useId()

  const submit = async () => {
    setBusy(true)
    await new Promise((r) => setTimeout(r, 400))
    setPractitionerStatus('underReview')
    toast(session.role === 'clinician' ? 'Profile submitted for council verification!' : 'Profile submitted for nursing council verification!')
    setBusy(false)
  }

  return (
    <PCard as="section" className="pn-hub">
      <div className="pn-hub-head">
        <PIcon name="clipboard" size={20} />
        <h2>Profile &amp; KYC Activation</h2>
        <span className="p-pill is-ok">
          {p.completed} of {p.total} Done ({pct}%)
        </span>
      </div>
      <ProgressBar value={pct} label="Profile setup progress" />
      <p className="p-muted pn-small">Your identity is verified. Add certificates, bank details and skills to activate patient matching.</p>

      <ol className="pn-checks">
        <CheckTile
          n={1}
          to={PR.profile}
          title="Identity & Basic Profile"
          subtitle={
            identity
              ? `Aadhaar & ${identity.registrationLabel} ${identity.registrationNumber} verified at sign-up`
              : 'Aadhaar & registration verified at sign-up'
          }
          done={p.profileDone}
          status="Verified"
        />
        <CheckTile
          n={2}
          to={PR.nurseDocuments}
          title="Certificates & HPR Registration"
          subtitle="Degree / diploma certificate & ABHA-HPR license"
          done={p.docsDone}
          status={p.docsDone ? 'Uploaded' : 'Upload Docs'}
        />
        <CheckTile
          n={3}
          to={PR.nurseDocuments}
          title="Medical Fitness & TB Screening"
          subtitle="Annual health declaration for home care safety"
          done={p.medicalDone}
          status={p.medicalDone ? 'Completed' : 'Upload Report'}
        />
        <CheckTile
          n={4}
          to={PR.bankAccount}
          title="Bank Account & Payout Setup"
          subtitle="Razorpay Route direct split deposits"
          done={p.bankDone}
          status={p.bankDone ? 'Configured' : 'Add Bank Info'}
        />
        <CheckTile
          n={5}
          to={PR.nurseAvailability}
          title="Skills & Specialisations"
          subtitle={`${skills.length} skills selected`}
          done={p.skillsDone}
          status={p.skillsDone ? 'Configured' : 'Configure'}
        />
        <CheckTile
          n={6}
          onClick={p.policeDone ? undefined : () => setConsentOpen(true)}
          title="Police Background Clearance Consent"
          subtitle="Automated background check using your verified Aadhaar"
          done={p.policeDone}
          status={p.policeDone ? 'Consented' : 'Give Consent'}
        />
      </ol>

      <button type="button" className="p-btn p-btn-primary p-btn-block pn-accent-btn" disabled={!p.canSubmit || busy} onClick={submit}>
        {busy ? 'Submitting…' : 'Submit Profile for Admin Verification'}
      </button>
      {!p.canSubmit && <p className="p-muted pn-small pn-center">Complete certificates, bank account and skills to submit.</p>}

      {consentOpen && (
        <Modal onClose={() => setConsentOpen(false)} labelledBy={consentId} className="pn-modal">
          <div className="pn-sos-head">
            <span className="pn-circle">
              <PIcon name="shield" size={20} />
            </span>
            <h2 id={consentId}>Police background check</h2>
          </div>
          <p className="pn-modal-text">
            I authorise ALLCURO to run an automated police background verification using my verified Aadhaar. The result is shared only with
            ALLCURO operations and is required before patient matching.
          </p>
          <div className="pn-modal-actions">
            <button type="button" className="p-btn p-btn-ghost pn-muted-btn" onClick={() => setConsentOpen(false)}>
              Cancel
            </button>
            <button
              type="button"
              className="p-btn p-btn-primary"
              onClick={() => {
                givePoliceConsent()
                setConsentOpen(false)
                toast('Consent recorded. Background check initiated.')
              }}
            >
              I consent
            </button>
          </div>
        </Modal>
      )}
    </PCard>
  )
}

function CheckTile({
  n,
  title,
  subtitle,
  done,
  status,
  to,
  onClick,
}: {
  n: number
  title: string
  subtitle: string
  done: boolean
  status: string
  to?: string
  onClick?: () => void
}) {
  const inner = (
    <>
      <span className={`pn-check-num ${done ? 'is-done' : ''}`} aria-hidden="true">
        {done ? <PIcon name="check" size={14} /> : n}
      </span>
      <span className="p-row-grow pn-ellipsis-col">
        <strong className="pn-ellipsis">{title}</strong>
        <span className="pn-ellipsis">{subtitle}</span>
      </span>
      <span className={`p-pill ${done ? 'is-ok' : 'pn-pill-primary'}`}>{status}</span>
      {(to || onClick) && <PIcon name="chevron" size={16} />}
    </>
  )
  const cls = `pn-check ${done ? 'is-done' : ''}`
  const label = `Step ${n}: ${title} — ${done ? 'done' : 'pending'}`
  return (
    <li>
      {to ? (
        <Link to={to} className={cls} aria-label={label}>
          {inner}
        </Link>
      ) : onClick ? (
        <button type="button" className={cls} onClick={onClick} aria-label={label}>
          {inner}
        </button>
      ) : (
        <div className={cls} aria-label={label}>
          {inner}
        </div>
      )}
    </li>
  )
}

// ---------------------------------------------------------------- under review

const AUDIT_STEPS: { title: string; done: boolean; time: string }[] = [
  { title: 'Aadhaar & Registration (verified at sign-up)', done: true, time: 'Verified' },
  { title: 'Certificates & HPR Registry Review', done: true, time: 'Passed' },
  { title: 'Police Background Verification Clearance', done: true, time: 'Clean Record' },
  { title: 'ALLCURO Nurse Badge & Shift Matching', done: false, time: 'Final Review' },
]

function UnderReviewCard() {
  const session = usePartnerSession()
  const isClinician = session.role === 'clinician'
  return (
    <PCard as="section" className="pn-hub">
      <div className="pn-hub-head">
        <PIcon name="shield" size={20} />
        <h2>Profile Under Verification</h2>
        <span className="p-pill is-warn">Under Review</span>
      </div>
      <p className="p-muted pn-small">
        Your certificates and police background clearance are being reviewed by ALLCURO ops. Verified {isClinician ? 'clinicians' : 'nurses'} get
        instant access to shift requests.
      </p>
      <ul className="pn-audit">
        {AUDIT_STEPS.map((s) => {
          const icon: PIconName = s.done ? 'check' : 'clock'
          return (
            <li key={s.title} className={s.done ? 'is-done' : ''}>
              <span className="pn-audit-icon" aria-hidden="true">
                <PIcon name={icon} size={13} />
              </span>
              <span>
                <strong>{isClinician ? s.title.replace('Nurse Badge', 'Clinician Badge') : s.title}</strong>
                <small>{s.time}</small>
              </span>
            </li>
          )
        })}
      </ul>
      <div className="pn-simulate">
        <span className="p-muted pn-small">
          The ALLCURO team approves your profile from the admin panel. Families can find and book you as soon as it’s approved.
        </span>
        <Link to={PR.publicProfile} className="p-btn p-btn-outline p-btn-sm">
          Edit public profile
        </Link>
      </div>
    </PCard>
  )
}
