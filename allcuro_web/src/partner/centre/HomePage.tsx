import { Link } from '../../components/Link'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { setCentreStatus, usePartnerSession } from '../session'
import { PBadge, PBody, PCard, PIcon, PSectionTitle, ToolTile, type PIconName } from '../ui'
import { DEFAULT_CENTRE_NAME, SITE_VISIT } from './data'
import { useBusy } from './hooks'
import {
  bedCounts,
  setupProgress,
  submitCentreForReview,
  useCompliance,
  useEquipment,
  useRequests,
  useRooms,
  useStaff,
} from './state'
import './centre.css'

// Centre home (features/centre/presentation/home/centre_home_screen.dart).
// Three stages by verification status:
//   incomplete / onboarding → Facility Activation Setup hub
//   pendingReview / siteVisitScheduled → Application under review + site visit
//   verified → live dashboard (occupancy, stats, new placement requests)

const TOOLS: { to: string; icon: PIconName; label: string }[] = [
  { to: PR.centreRooms, icon: 'bed', label: 'Rooms & Beds' },
  { to: PR.centreEquipment, icon: 'box', label: 'Equipment' },
  { to: PR.centreStaff, icon: 'users', label: 'Care Staff' },
  { to: PR.bankAccount, icon: 'bank', label: 'Bank Payout' },
  { to: PR.centreCompliance, icon: 'shield', label: 'Compliance' },
  { to: PR.centreListing, icon: 'store', label: 'Listing' },
  { to: PR.centreRevenue, icon: 'wallet', label: 'Revenue' },
  { to: PR.centreReviews, icon: 'star', label: 'Reviews' },
  { to: PR.centrePromotions, icon: 'megaphone', label: 'Promotions' },
]

function greeting() {
  const h = new Date().getHours()
  return h < 12 ? 'Good morning,' : h < 17 ? 'Good afternoon,' : 'Good evening,'
}

export function CentreHomePage() {
  const s = usePartnerSession()
  const status = s.centreStatus
  const isVerified = status === 'verified'
  const isUnderReview = status === 'pendingReview' || status === 'siteVisitScheduled'

  return (
    <PBody>
      <div className="pc-greet">
        <div className="pc-greet-text">
          <span className="p-muted">{greeting()}</span>
          <h1>{s.name || DEFAULT_CENTRE_NAME}</h1>
        </div>
        <Link to={PR.profile} className="p-btn p-btn-outline p-btn-sm pc-greet-profile">
          <PIcon name="user" size={16} /> Centre profile
        </Link>
      </div>

      <div className="pc-home-grid">
        <div className="pc-home-main">
          {!isVerified && !isUnderReview && <SetupHub />}
          {isUnderReview && <SiteVisitCard />}
          {isVerified && <LiveDashboard />}
        </div>

        <section className="pc-home-side" aria-labelledby="pc-tools-title">
          <PSectionTitle>
            <span id="pc-tools-title">{isVerified ? 'Facility Management & Tools' : 'Manage Facility Modules'}</span>
          </PSectionTitle>
          <div className="p-tools pc-tools">
            {TOOLS.map((t) => (
              <ToolTile key={t.label} to={t.to} icon={t.icon} label={t.label} />
            ))}
          </div>
        </section>
      </div>
    </PBody>
  )
}

// ---------------------------------------------------------------- stage 1: setup hub

function SetupHub() {
  const s = usePartnerSession()
  const rooms = useRooms()
  const staff = useStaff()
  const equipment = useEquipment()
  const docs = useCompliance()
  const p = setupProgress(s, rooms, staff, equipment, docs)
  const pct = Math.round(p.percentage * 100)
  const [busy, run] = useBusy()

  const submit = () =>
    run('submit', async () => {
      await submitCentreForReview()
      toast('Application submitted! Physical site visit scheduled.')
    })

  const steps: { n: number; title: string; subtitle: string; done: boolean; status: string; to: string }[] = [
    {
      n: 1,
      title: 'Entity & Facility Details',
      subtitle: 'Entity name, registration number & address',
      done: p.entityDone,
      status: 'Done',
      to: PR.profile,
    },
    {
      n: 2,
      title: 'Regulatory & KYC Compliance',
      subtitle: 'CEA license, Fire NOC & Bio-waste clearance',
      done: p.docsDone,
      status: p.docsDone ? 'Uploaded' : 'Upload Docs',
      to: PR.centreCompliance,
    },
    {
      n: 3,
      title: 'Bank Account & Payout Setup',
      subtitle: 'Razorpay Route split settlement bank info',
      done: p.bankDone,
      status: p.bankDone ? 'Configured' : 'Add Bank Info',
      to: PR.bankAccount,
    },
    {
      n: 4,
      title: 'Rooms & Bed Inventory',
      subtitle: `${rooms.length} room(s) and bed capacity configured`,
      done: p.roomsDone,
      status: p.roomsDone ? `${rooms.length} Rooms` : 'Add Rooms',
      to: PR.centreRooms,
    },
    {
      n: 5,
      title: 'In-House Nursing & Care Staff',
      subtitle: `${staff.length} active duty staff in roster`,
      done: p.staffDone,
      status: p.staffDone ? `${staff.length} Staff` : 'Add Nurses',
      to: PR.centreStaff,
    },
    {
      n: 6,
      title: 'Medical Equipment & Rentals',
      subtitle: `${equipment.length} rental equipment items listed`,
      done: p.equipmentDone,
      status: p.equipmentDone ? `${equipment.length} Items` : 'Add Equipment',
      to: PR.centreEquipment,
    },
  ]

  return (
    <PCard as="section" className="pc-hub">
      <div className="pc-card-head">
        <span className="pc-head-icon">
          <PIcon name="clipboard" size={18} />
        </span>
        <h2>Facility Activation Setup</h2>
        <PBadge tone="ok">
          {p.completed} of 6 Done ({pct}%)
        </PBadge>
      </div>
      <div className="pc-progress" role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={pct} aria-label="Setup progress">
        <span style={{ width: `${pct}%` }} />
      </div>
      <p className="p-muted pc-small">
        Complete mandatory statutory documents, bank details, and room/equipment inventory before sending for ALLCURO review &amp;
        on-site audit.
      </p>

      <ol className="pc-steps">
        {steps.map((st) => (
          <li key={st.n}>
            <Link to={st.to} className={`pc-step ${st.done ? 'is-done' : ''}`}>
              <span className="pc-step-dot" aria-hidden="true">
                {st.done ? <PIcon name="check" size={14} /> : st.n}
              </span>
              <span className="pc-step-text">
                <strong>{st.title}</strong>
                <span>{st.subtitle}</span>
              </span>
              <span className={`pc-step-status ${st.done ? 'is-done' : ''}`}>
                <span className="sr-only">{st.done ? 'Complete: ' : 'To do: '}</span>
                {st.status}
              </span>
              <PIcon name="chevron" size={16} />
            </Link>
          </li>
        ))}
      </ol>

      {!p.canSubmit && (
        <p className="p-muted pc-small">
          Compliance documents, bank account and at least one room are required before you can submit.
        </p>
      )}
      <button type="button" className="p-btn p-btn-primary p-btn-block pc-pill-btn" disabled={!p.canSubmit || !!busy} onClick={submit}>
        {busy ? 'Submitting…' : 'Submit for Review & Schedule Site Visit'}
      </button>
    </PCard>
  )
}

// ---------------------------------------------------------------- stage 2: under review

function SiteVisitCard() {
  const approve = () => {
    setCentreStatus('verified')
    toast('Physical audit cleared — your centre is now live!')
  }
  return (
    <PCard as="section" className="pc-review">
      <div className="pc-card-head">
        <span className="pc-head-icon">
          <PIcon name="shield" size={18} />
        </span>
        <h2>Application Under Review</h2>
        <PBadge tone="warn">Site Visit Scheduled</PBadge>
      </div>

      <div className="pc-visit">
        <div className="p-row">
          <PIcon name="calendar" size={16} />
          <strong>Physical Field Inspection: {SITE_VISIT.when}</strong>
        </div>
        <p>
          ALLCURO City Operations Officer ({SITE_VISIT.officer}) will inspect bed count, fire clearances, biomedical waste protocols,
          and room hygiene on site.
        </p>
      </div>

      <h3 className="pc-subhead">Verification Checklist &amp; Audit Trail</h3>
      <ol className="pc-audit">
        {SITE_VISIT.audit.map((a) => (
          <li key={a.title} className={a.done ? 'is-done' : ''}>
            <span className="pc-audit-dot" aria-hidden="true">
              {a.done && <PIcon name="check" size={12} />}
            </span>
            <span>
              <strong>{a.title}</strong>
              <span className="sr-only">{a.done ? ' (done)' : ' (pending)'}</span>
              <small>{a.time}</small>
            </span>
          </li>
        ))}
      </ol>

      <div className="pc-review-links">
        <Link to={PR.centreCompliance} className="p-btn p-btn-outline p-btn-sm">
          <PIcon name="shield" size={16} /> Compliance docs
        </Link>
        <Link to={PR.centreRooms} className="p-btn p-btn-outline p-btn-sm">
          <PIcon name="bed" size={16} /> Rooms &amp; beds
        </Link>
        <Link to={PR.centreEquipment} className="p-btn p-btn-outline p-btn-sm">
          <PIcon name="box" size={16} /> Equipment
        </Link>
      </div>

      <div className="pc-demo">
        <span>Simulate physical audit clearance to unlock live dashboard.</span>
        <button type="button" className="p-btn p-btn-primary p-btn-sm pc-pill-btn" onClick={approve}>
          Approve &amp; Go Live
        </button>
      </div>
    </PCard>
  )
}

// ---------------------------------------------------------------- stage 3: live dashboard

function LiveDashboard() {
  const rooms = useRooms()
  const req = useRequests()
  const { total, occupied, vacant, occupancy } = bedCounts(rooms)
  const preview = req.pending.slice(0, 2)

  return (
    <>
      <Link to={PR.centreRooms} className="p-card pc-occupancy" aria-label={`Bed occupancy ${occupied} of ${total} beds. Manage rooms and admissions`}>
        <div className="pc-occupancy-top">
          <strong>Bed occupancy</strong>
          <span>
            {occupied} / {total} beds
          </span>
        </div>
        <div className="pc-progress is-thick" aria-hidden="true">
          <span style={{ width: `${Math.round(occupancy * 100)}%` }} />
        </div>
        <span className="p-muted pc-small">{vacant} beds vacant · tap to manage rooms &amp; admissions</span>
      </Link>

      <div className="pc-statpair">
        <div className="pc-statcard is-warn">
          <strong>{req.pending.length}</strong>
          <span>Pending requests</span>
        </div>
        <div className="pc-statcard is-ok">
          <strong>{req.admittedThisMonth}</strong>
          <span>Admitted this month</span>
        </div>
      </div>

      <section className="pc-stack" aria-labelledby="pc-new-req">
        <PSectionTitle action={<Link to={PR.centreRequests}>See all</Link>}>
          <span id="pc-new-req">New placement requests</span>
        </PSectionTitle>
        {preview.length === 0 ? (
          <p className="p-muted">No placement requests right now</p>
        ) : (
          <ul className="p-list">
            {preview.map((r) => (
              <li key={r.id}>
                <Link to={PR.centreRequests} className="p-card pc-req-preview">
                  <span className="p-row-grow">
                    <strong>{r.careType}</strong>
                    <span className="p-muted">{r.familyContact}</span>
                  </span>
                  <PIcon name="chevron" size={18} />
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  )
}
