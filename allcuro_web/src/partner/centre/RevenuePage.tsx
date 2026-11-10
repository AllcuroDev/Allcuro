import { inr } from '../../lib/format'
import { PR } from '../routes'
import { PBody, PPageHead, PSectionTitle } from '../ui'
import { REVENUE_STATS, SETTLEMENTS } from './data'
import './centre.css'

// Revenue overview (features/centre/presentation/revenue/revenue_screen.dart) — mock stats + settlements.

export function CentreRevenuePage() {
  const stats = [
    { label: 'Total bookings this month', value: String(REVENUE_STATS.bookingsThisMonth), tone: 'neutral' },
    { label: 'Gross revenue', value: inr(REVENUE_STATS.gross), tone: 'ok' },
    { label: 'Commission deducted', value: inr(REVENUE_STATS.commission), tone: 'warn' },
    { label: 'Pending settlement', value: inr(REVENUE_STATS.pendingSettlement), tone: 'ok' },
  ]
  return (
    <>
      <PPageHead title="Revenue" back={PR.centreHome} />
      <PBody>
        <div className="pc-statgrid">
          {stats.map((s) => (
            <div key={s.label} className={`pc-statcard is-${s.tone}`}>
              <strong>{s.value}</strong>
              <span>{s.label}</span>
            </div>
          ))}
        </div>

        <section className="pc-stack" aria-labelledby="pc-settle">
          <PSectionTitle>
            <span id="pc-settle">Recent settlements</span>
          </PSectionTitle>
          <ul className="p-list">
            {SETTLEMENTS.map((s) => (
              <li key={s.bookingRef} className="p-card pc-settle">
                <span className="p-row-grow">
                  {s.date} · {s.bookingRef}
                </span>
                <span className="pc-settle-amt">
                  <span className="p-muted pc-small">Gross {inr(s.gross)}</span>
                  <strong>Net {inr(s.net)}</strong>
                </span>
              </li>
            ))}
          </ul>
        </section>
      </PBody>
    </>
  )
}
