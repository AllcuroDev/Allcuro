import { PR } from '../routes'
import { usePartnerSession } from '../session'
import { EmptyState, PBody, PCard, PPageHead, PSectionTitle } from '../ui'
import { Stars } from './parts'

// Performance & reviews — ratings/performance_screen.dart.
//
// There is no visits or reviews backend yet. The only real numbers are the
// rating and review count an admin keeps on public.partners; everything else
// shows an empty state until visits start happening.

export function NurseRatingsPage() {
  const session = usePartnerSession()
  const reviewCount = session.reviewCount ?? 0
  const rating = session.rating
  const hasRating = rating != null && reviewCount > 0

  return (
    <>
      <PPageHead title="Performance & Reviews" subtitle="Attendance, quality metrics & patient ratings" back={PR.nurseHome} />
      <PBody narrow>
        <section className="pn-stack" aria-labelledby="pn-rating">
          <PSectionTitle>
            <span id="pn-rating">Your rating</span>
          </PSectionTitle>
          <PCard>
            {hasRating ? (
              <div className="pn-stack pn-center">
                <strong className="pn-timer">{rating.toFixed(1)} ★</strong>
                <Stars value={rating} />
                <span className="p-muted pn-small">
                  from {reviewCount} {reviewCount === 1 ? 'review' : 'reviews'}
                </span>
              </div>
            ) : (
              <EmptyState icon="star" title="No reviews yet" text="Families can rate you after a completed visit. Your rating and their feedback will show up here." />
            )}
          </PCard>
        </section>

        <section className="pn-stack" aria-labelledby="pn-perf">
          <PSectionTitle>
            <span id="pn-perf">Visits &amp; attendance</span>
          </PSectionTitle>
          <PCard>
            <EmptyState
              icon="chart"
              title="No performance data yet"
              text="Completed visits, attendance and on-time arrival appear here after your first bookings."
            />
          </PCard>
        </section>
      </PBody>
    </>
  )
}
