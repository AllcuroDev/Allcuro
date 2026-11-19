import { PR } from '../routes'
import { usePartnerSession } from '../session'
import { EmptyState, PBody, PCard, PPageHead } from '../ui'
import './centre.css'

// Reviews & ratings (features/centre/presentation/reviews/reviews_screen.dart).
// There is no reviews backend yet. The only real numbers are the rating and
// review count an admin keeps on public.partners.

function Stars({ value }: { value: number }) {
  return (
    <span className="pc-stars is-lg" role="img" aria-label={`${value} out of 5 stars`}>
      {[0, 1, 2, 3, 4].map((i) => (
        <span key={i} className={i < Math.round(value - 0.4) ? 'is-on' : ''} aria-hidden="true">
          ★
        </span>
      ))}
    </span>
  )
}

export function CentreReviewsPage() {
  const s = usePartnerSession()
  const count = s.reviewCount ?? 0
  const rating = s.rating
  return (
    <>
      <PPageHead title="Reviews & ratings" back={PR.centreHome} />
      <PBody narrow>
        {rating != null && count > 0 ? (
          <PCard className="pc-rating">
            <strong>{rating.toFixed(1)}</strong>
            <Stars value={rating} />
            <span className="p-muted">
              {count} {count === 1 ? 'review' : 'reviews'}
            </span>
          </PCard>
        ) : (
          <PCard>
            <EmptyState
              icon="star"
              title="No reviews yet"
              text="Families can review your centre after a stay. Their ratings and comments will show up here, and you’ll be able to reply."
            />
          </PCard>
        )}
      </PBody>
    </>
  )
}
