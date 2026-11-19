import { PR } from '../routes'
import { EmptyState, PBody, PCard, PPageHead } from '../ui'
import './centre.css'

// Revenue overview (features/centre/presentation/revenue/revenue_screen.dart).
// There is no bookings / settlements backend yet, so this is an empty state.

export function CentreRevenuePage() {
  return (
    <>
      <PPageHead title="Revenue" back={PR.centreHome} />
      <PBody narrow>
        <PCard>
          <EmptyState
            icon="wallet"
            title="No revenue yet"
            text="Bookings, commission and settlements appear here once families start booking your centre."
          />
        </PCard>
      </PBody>
    </>
  )
}
