import { useState } from 'react'
import { inr } from '../../lib/format'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { PBody, PCard, PIcon, PPageHead, PSectionTitle, type PIconName } from '../ui'
import type { CustomerFeedbackItem } from './data'
import { ProgressBar } from './parts'
import { daysAgoLabel, performanceStore } from './state'

// Performance & reviews — ratings/performance_screen.dart (the route the app
// opens for "Performance"), with the per-review "Respond" reply box from
// ratings/ratings_screen.dart.

export function NurseRatingsPage() {
  const perf = performanceStore.use()
  const resolution = perf.totalComplaints === 0 ? 100 : Math.round((perf.resolvedComplaints / perf.totalComplaints) * 100)
  const active = perf.totalComplaints - perf.resolvedComplaints

  return (
    <>
      <PPageHead title="Performance & Reviews" subtitle="Attendance, quality metrics & patient ratings" back={PR.nurseHome} />
      <PBody>
        <div className="pn-metrics">
          <Metric icon="star" tone="amber" value={`${perf.averageRating} ★`} label="Average Rating" sub={`from ${perf.totalRatingsCount} reviews`} />
          <Metric icon="check" tone="primary" value={`${perf.totalJobsCompleted}`} label="Jobs Completed" sub={`${perf.monthlyJobsCompleted} this month · ${perf.weeklyJobsCompleted} this week`} />
          <Metric icon="calendar" tone="ok" value={`${perf.attendanceRate}%`} label="Attendance Rate" sub={`${perf.onTimeArrivalRate}% on-time arrival`} />
          <Metric icon="shield" tone="coral" value={`${active} Active`} label="Complaints" sub={`${resolution}% resolution rate`} />
        </div>

        <div className="pn-two-col">
          <div className="pn-col">
            <PCard as="section" className="pn-stack">
              <div className="pn-card-head">
                <h2>Rating Distribution</h2>
                <span className="pn-ok-text pn-small">Top 5% Partner in Bengaluru</span>
              </div>
              <ul className="pn-bars">
                {([5, 4, 3, 2, 1] as const).map((star) => {
                  const count = perf.ratingDistribution[star]
                  return (
                    <li key={star}>
                      <span className="pn-bars-label">{star} ★</span>
                      <ProgressBar value={perf.totalRatingsCount ? (count / perf.totalRatingsCount) * 100 : 0} tone="amber" label={`${star} star ratings`} />
                      <span className="pn-bars-count">{count}</span>
                    </li>
                  )
                })}
              </ul>
            </PCard>

            <PCard as="section" className="pn-rowcard">
              <span className="pn-circle">
                <PIcon name="wallet" size={22} />
              </span>
              <div className="p-row-grow">
                <span className="p-muted pn-small">This Month’s Earnings</span>
                <strong className="pn-timer">{inr(perf.thisMonthEarnings)}</strong>
                <span className="p-muted pn-small">
                  This week {inr(perf.thisWeekEarnings)} · Pending payout {inr(perf.pendingPayout)}
                </span>
              </div>
              <span className="p-pill is-ok">Payout Active</span>
            </PCard>

            <PCard as="section" className="pn-rowcard">
              <span className="pn-ok-text">
                <PIcon name="shield" size={20} />
              </span>
              <p className="pn-small pn-m0">Zero disciplinary strikes. 100% compliance with ALLCURO clinical guidelines.</p>
            </PCard>
          </div>

          <section className="pn-col" aria-labelledby="pn-reviews">
            <PSectionTitle>
              <span id="pn-reviews">Customer Reviews &amp; Booking Feedback</span>
            </PSectionTitle>
            <ul className="p-list">
              {perf.feedbacks.map((f) => (
                <li key={f.id}>
                  <FeedbackTile feedback={f} />
                </li>
              ))}
            </ul>
          </section>
        </div>
      </PBody>
    </>
  )
}

function Metric({ icon, tone, value, label, sub }: { icon: PIconName; tone: 'amber' | 'primary' | 'ok' | 'coral'; value: string; label: string; sub: string }) {
  return (
    <PCard className={`pn-metric is-${tone}`}>
      <div className="pn-metric-top">
        <span className="pn-metric-icon">
          <PIcon name={icon} size={18} />
        </span>
        <strong>{value}</strong>
      </div>
      <span className="pn-title pn-small">{label}</span>
      <span className="p-muted pn-xs">{sub}</span>
    </PCard>
  )
}

function FeedbackTile({ feedback: f }: { feedback: CustomerFeedbackItem }) {
  const [replying, setReplying] = useState(false)
  const [reply, setReply] = useState('')
  const [sent, setSent] = useState<string | null>(null)
  return (
    <PCard className="pn-stack pn-gap8">
      <div className="pn-card-head">
        <strong className="pn-title">{f.patientName}</strong>
        <span className="pn-rating">
          <PIcon name="star" size={16} /> {f.rating.toFixed(1)}
        </span>
      </div>
      <span className="pn-primary-text pn-xs">
        {f.serviceName} · Ref: {f.bookingId} · {daysAgoLabel(f.daysAgo)}
      </span>
      <p className="pn-small pn-m0">{f.comment}</p>
      {sent && (
        <div className="pn-reply-sent">
          <strong className="pn-xs">Your reply</strong>
          <p className="pn-small pn-m0">{sent}</p>
        </div>
      )}
      {!sent && (
        <button type="button" className="p-btn p-btn-ghost p-btn-sm pn-self-start" onClick={() => setReplying((r) => !r)} aria-expanded={replying}>
          {replying ? 'Cancel' : 'Respond'}
        </button>
      )}
      {replying && !sent && (
        <form
          className="pn-inline-form"
          onSubmit={(e) => {
            e.preventDefault()
            if (!reply.trim()) return
            setSent(reply.trim())
            setReplying(false)
            toast('Reply posted to the family.')
          }}
        >
          <label className="sr-only" htmlFor={`reply-${f.id}`}>
            Reply to {f.patientName}
          </label>
          <input id={`reply-${f.id}`} className="p-input" placeholder="Write a reply…" value={reply} onChange={(e) => setReply(e.target.value)} />
          <button type="submit" className="p-btn p-btn-primary p-btn-sm" disabled={!reply.trim()}>
            Send
          </button>
        </form>
      )}
    </PCard>
  )
}
