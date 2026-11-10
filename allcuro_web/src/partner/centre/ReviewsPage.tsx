import { useState } from 'react'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { PBody, PCard, PPageHead } from '../ui'
import { REVIEWS, REVIEW_SUMMARY, type Review } from './data'
import { replyStore, useReplies } from './state'
import './centre.css'

// Reviews & ratings (features/centre/presentation/reviews/reviews_screen.dart):
// rating summary + family reviews, each with a "Respond publicly" reply box.

function Stars({ value, size = 'sm' }: { value: number; size?: 'sm' | 'lg' }) {
  return (
    <span className={`pc-stars is-${size}`} role="img" aria-label={`${value} out of 5 stars`}>
      {[0, 1, 2, 3, 4].map((i) => (
        <span key={i} className={i < Math.round(value - 0.4) ? 'is-on' : ''} aria-hidden="true">
          ★
        </span>
      ))}
    </span>
  )
}

export function CentreReviewsPage() {
  const replies = useReplies()
  return (
    <>
      <PPageHead title="Reviews & ratings" back={PR.centreHome} />
      <PBody narrow>
        <PCard className="pc-rating">
          <strong>{REVIEW_SUMMARY.rating}</strong>
          <Stars value={REVIEW_SUMMARY.rating} size="lg" />
          <span className="p-muted">{REVIEW_SUMMARY.count} reviews</span>
        </PCard>
        <ul className="pc-cards">
          {REVIEWS.map((r) => (
            <li key={r.id}>
              <ReviewCard review={r} reply={replies[r.id]} />
            </li>
          ))}
        </ul>
      </PBody>
    </>
  )
}

function ReviewCard({ review: r, reply }: { review: Review; reply?: string }) {
  const [replying, setReplying] = useState(false)
  const [text, setText] = useState(reply ?? '')
  const boxId = `pc-reply-${r.id}`

  const post = () => {
    if (!text.trim()) return
    replyStore.set((m) => ({ ...m, [r.id]: text.trim() }))
    setReplying(false)
    toast('Reply posted publicly')
  }
  const remove = () => {
    replyStore.set((m) => {
      const next = { ...m }
      delete next[r.id]
      return next
    })
    setText('')
    toast('Reply removed', 'info')
  }

  return (
    <article className="p-card pc-review-card">
      <div className="pc-review-head">
        <h3>{r.familyName}</h3>
        <span className="p-muted pc-small">{r.relativeDate}</span>
      </div>
      <Stars value={r.stars} />
      <p>{r.comment}</p>

      {reply && !replying && (
        <div className="pc-reply">
          <span className="pc-small">Your public reply</span>
          <p>{reply}</p>
          <div className="pc-card-actions">
            <button type="button" className="p-btn p-btn-ghost p-btn-sm" onClick={() => setReplying(true)}>
              Edit reply
            </button>
            <button type="button" className="p-btn p-btn-ghost p-btn-sm pc-danger-text" onClick={remove}>
              Delete
            </button>
          </div>
        </div>
      )}

      {!reply && (
        <button
          type="button"
          className="p-btn p-btn-ghost p-btn-sm pc-link-btn"
          aria-expanded={replying}
          aria-controls={boxId}
          onClick={() => setReplying((v) => !v)}
        >
          {replying ? 'Cancel' : 'Respond publicly'}
        </button>
      )}

      {replying && (
        <div className="pc-stack-sm" id={boxId}>
          <label className="sr-only" htmlFor={`${boxId}-t`}>
            Public reply to {r.familyName}
          </label>
          <textarea id={`${boxId}-t`} className="p-input pc-textarea" rows={3} value={text} onChange={(e) => setText(e.target.value)} placeholder="Write a public reply…" autoFocus />
          <div className="pc-card-actions">
            {reply && (
              <button type="button" className="p-btn p-btn-outline p-btn-sm" onClick={() => setReplying(false)}>
                Cancel
              </button>
            )}
            <button type="button" className="p-btn p-btn-primary p-btn-sm" onClick={post} disabled={!text.trim()}>
              Post reply
            </button>
          </div>
        </div>
      )}
    </article>
  )
}
