import { useId, useState } from 'react'
import { Link } from '../../components/Link'
import { Modal } from '../../components/ui'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { usePartnerSession } from '../session'
import { EmptyState, PBody, PCard, PIcon, PPageHead, PSectionTitle } from '../ui'
import { SOS_PHONE } from './data'
import { ProgressBar } from './parts'
import { continueCourse, coursesStore, telUrl } from './state'

// The smaller tool screens from the home grid: earnings, training,
// referral and support (features/nurse/presentation/{earnings,training,referral,support}).
// There is no payouts or referrals backend yet, so those pages show empty
// states instead of numbers.

// ---------------------------------------------------------------- earnings

export function NurseEarningsPage() {
  const session = usePartnerSession()
  return (
    <>
      <PPageHead title="Earnings" back={PR.nurseHome} />
      <PBody narrow>
        <PCard>
          <EmptyState
            icon="wallet"
            title="No earnings yet"
            text="Payouts appear here after your first completed visit, with a per-visit breakdown and monthly statements."
            action={
              !session.bank ? (
                <Link to={PR.bankAccount} className="p-btn p-btn-primary p-btn-sm">
                  Add bank account
                </Link>
              ) : undefined
            }
          />
        </PCard>
      </PBody>
    </>
  )
}

// ---------------------------------------------------------------- training

export function NurseTrainingPage() {
  const courses = coursesStore.use()
  const certified = courses.filter((c) => c.progress >= 100).length
  return (
    <>
      <PPageHead title="Training & certification" subtitle="Micro-courses that unlock skill-based pricing tiers" back={PR.nurseHome} />
      <PBody narrow>
        <p className="p-muted pn-small pn-m0">
          {certified} of {courses.length} courses certified
        </p>
        <ul className="p-list">
          {courses.map((c, i) => {
            const done = c.progress >= 100
            return (
              <li key={c.title}>
                <PCard className="pn-stack pn-gap8">
                  <div className="pn-card-head">
                    <strong className="pn-title">{c.title}</strong>
                    {done ? (
                      <span className="p-pill is-ok">
                        Certified <PIcon name="check" size={12} />
                      </span>
                    ) : (
                      <button
                        type="button"
                        className="p-btn p-btn-ghost p-btn-sm"
                        onClick={() => {
                          continueCourse(i)
                          if (c.progress + 25 >= 100) toast(`Certified in ${c.title}!`)
                        }}
                        aria-label={`Continue ${c.title}`}
                      >
                        {c.progress === 0 ? 'Start' : 'Continue'}
                      </button>
                    )}
                  </div>
                  <span className="p-muted pn-small">
                    {c.duration} · {c.progress}% complete
                  </span>
                  <ProgressBar value={c.progress} tone={done ? 'ok' : 'primary'} label={`${c.title} progress`} />
                </PCard>
              </li>
            )
          })}
        </ul>
      </PBody>
    </>
  )
}

// ---------------------------------------------------------------- referral

export function NurseReferralPage() {
  const session = usePartnerSession()
  const noun = session.role === 'clinician' ? 'clinician' : 'nurse'
  const link = `${window.location.origin}${PR.welcome}`
  const message = `Join ALLCURO as a home care partner: ${link}`

  const share = async () => {
    if (navigator.share) {
      try {
        await navigator.share({ title: 'ALLCURO Partner', text: message })
      } catch {
        // Share sheet dismissed.
      }
    } else {
      window.open(`https://wa.me/?text=${encodeURIComponent(message)}`, '_blank', 'noopener')
    }
  }

  return (
    <>
      <PPageHead title={`Refer a ${noun}`} subtitle="Invite colleagues to join ALLCURO" back={PR.nurseHome} />
      <PBody narrow>
        <PCard as="section" className="pn-stack pn-center">
          <span className="p-muted pn-small">Know a {noun} who’d be a good fit? Send them the partner sign-up link.</span>
          <button type="button" className="p-btn p-btn-primary pn-accent-btn" onClick={share}>
            <PIcon name="gift" size={16} /> Share invite
          </button>
        </PCard>
        <section className="pn-stack" aria-labelledby="pn-refs">
          <PSectionTitle>
            <span id="pn-refs">Your referrals</span>
          </PSectionTitle>
          <PCard>
            <EmptyState icon="users" title="No referrals yet" text="Colleagues who join through your invite will be listed here." />
          </PCard>
        </section>
      </PBody>
    </>
  )
}

// ---------------------------------------------------------------- support

export function NurseSupportPage() {
  const [confirm, setConfirm] = useState(false)
  const id = useId()
  return (
    <>
      <PPageHead title="Support & SOS" back={PR.nurseHome} />
      <PBody narrow>
        <button type="button" className="pn-sos-big" onClick={() => setConfirm(true)} aria-haspopup="dialog">
          <PIcon name="sos" size={22} /> Emergency SOS — Call ALLCURO Ops
        </button>

        <section className="pn-stack" aria-labelledby="pn-general">
          <PSectionTitle>
            <span id="pn-general">General support</span>
          </PSectionTitle>
          <button type="button" className="p-card pn-rowcard pn-tap" onClick={() => toast('Chat with support is coming soon.', 'info')}>
            <span className="pn-primary-text">
              <PIcon name="help" size={22} />
            </span>
            <strong className="p-row-grow pn-title pn-left">Chat with support</strong>
            <PIcon name="chevron" size={18} />
          </button>
          <p className="p-muted pn-small pn-m0">Support hours: Mon–Sat, 8 AM – 10 PM</p>
        </section>

        {confirm && (
          <Modal onClose={() => setConfirm(false)} labelledBy={id} className="pn-modal">
            <h2 id={id} className="pn-h2">
              Call ALLCURO Ops?
            </h2>
            <p className="pn-modal-text">This is for genuine emergencies during an active shift.</p>
            <div className="pn-modal-actions">
              <button type="button" className="p-btn p-btn-ghost pn-muted-btn" onClick={() => setConfirm(false)}>
                Cancel
              </button>
              <a
                href={telUrl(SOS_PHONE)}
                className="p-btn p-btn-danger"
                onClick={() => {
                  setConfirm(false)
                  toast('Calling ALLCURO Ops…', 'danger')
                }}
              >
                <PIcon name="phone" size={16} /> Call
              </a>
            </div>
          </Modal>
        )}
      </PBody>
    </>
  )
}
