import { useId, useState } from 'react'
import { Modal } from '../../components/ui'
import { inr } from '../../lib/format'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { usePartnerSession } from '../session'
import { PBody, PCard, PIcon, PPageHead, PSectionTitle } from '../ui'
import {
  EARNINGS_INCENTIVES,
  EARNINGS_THIS_MONTH,
  REFERRAL_BONUS,
  REFERRAL_CODE,
  REFERRALS,
  SEED_PAYOUTS,
  SOS_PHONE,
  STATEMENT,
} from './data'
import { ProgressBar } from './parts'
import { continueCourse, coursesStore, creditedPayoutsStore, telUrl } from './state'

// The smaller tool screens from the home grid: earnings, training,
// referral and support (features/nurse/presentation/{earnings,training,referral,support}).

// ---------------------------------------------------------------- earnings

export function NurseEarningsPage() {
  const credited = creditedPayoutsStore.use()
  const payouts = [...credited, ...SEED_PAYOUTS]
  const thisMonth = EARNINGS_THIS_MONTH + credited.reduce((sum, p) => sum + p.amount, 0)

  return (
    <>
      <PPageHead title="Earnings" back={PR.nurseHome} />
      <PBody narrow>
        <div className="pn-stat-row">
          <div className="pn-stat is-primary">
            <strong className="pn-stat-big">{inr(thisMonth)}</strong>
            <span className="pn-stat-label">This month</span>
          </div>
          <div className="pn-stat is-ok">
            <strong className="pn-stat-big">{inr(EARNINGS_INCENTIVES)}</strong>
            <span className="pn-stat-label">Incentives</span>
          </div>
        </div>

        <section className="pn-stack" aria-labelledby="pn-breakdown">
          <PSectionTitle>
            <span id="pn-breakdown">Per-shift breakdown</span>
          </PSectionTitle>
          <ul className="p-list">
            {payouts.map((p, i) => (
              <li key={`${p.date}-${i}`}>
                <PCard className="pn-rowcard">
                  <div className="p-row-grow">
                    <strong className="pn-title">{p.description}</strong>
                    <span className="p-muted pn-small">{p.date}</span>
                  </div>
                  <strong>{inr(p.amount)}</strong>
                </PCard>
              </li>
            ))}
          </ul>
        </section>

        <PCard as="section" className="pn-stack pn-gap8">
          <h2 className="pn-h2">Monthly statement</h2>
          <span className="p-muted pn-small">{STATEMENT.month}</span>
          <span className="p-muted pn-small">TDS deducted: {inr(STATEMENT.tds)}</span>
          <button type="button" className="p-btn p-btn-primary p-btn-block pn-accent-btn" onClick={() => toast('Payslip downloaded (demo)')}>
            <PIcon name="file" size={16} /> Download payslip
          </button>
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
  const message = `Join ALLCURO as a home care partner and use my code ${REFERRAL_CODE} when you sign up.`

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(REFERRAL_CODE)
      toast('Copied to clipboard')
    } catch {
      toast(`Your code is ${REFERRAL_CODE}`, 'info')
    }
  }

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
      <PPageHead title={`Refer a ${noun}`} subtitle={`Earn ${inr(REFERRAL_BONUS)} when they complete their first 5 shifts`} back={PR.nurseHome} />
      <PBody narrow>
        <PCard as="section" className="pn-stack pn-center">
          <span className="p-muted pn-small">Your referral code</span>
          <strong className="pn-code">{REFERRAL_CODE}</strong>
          <div className="pn-btn-pair">
            <button type="button" className="p-btn p-btn-outline pn-btn-primary-text pn-border-primary" onClick={copy}>
              <PIcon name="copy" size={16} /> Copy code
            </button>
            <button type="button" className="p-btn p-btn-primary pn-accent-btn" onClick={share}>
              <PIcon name="gift" size={16} /> Share
            </button>
          </div>
        </PCard>
        <section className="pn-stack" aria-labelledby="pn-refs">
          <PSectionTitle>
            <span id="pn-refs">Your referrals</span>
          </PSectionTitle>
          <ul className="p-list">
            {REFERRALS.map((r) => (
              <li key={r.name}>
                <PCard className="pn-rowcard">
                  <strong className="p-row-grow pn-title">{r.name}</strong>
                  <span className={`p-pill is-${r.tone}`}>{r.status}</span>
                </PCard>
              </li>
            ))}
          </ul>
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
          <button type="button" className="p-card pn-rowcard pn-tap" onClick={() => toast('Chat coming soon — demo', 'info')}>
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
                  toast('Calling ALLCURO Ops… (demo)', 'danger')
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
