import { useState } from 'react'
import { Link } from '../../components/Link'
import { PR } from '../routes'
import { EmptyState, PBody, PCard, PIcon } from '../ui'
import type { ShiftStatus } from './data'
import { PageIntro } from './parts'
import { shiftsStore, visitStore } from './state'

// Shift calendar filterable by status — schedule/nurse_schedule_screen.dart.

const FILTERS: { value: ShiftStatus; label: string }[] = [
  { value: 'upcoming', label: 'Upcoming' },
  { value: 'ongoing', label: 'Ongoing' },
  { value: 'completed', label: 'Completed' },
]

export function NurseSchedulePage() {
  const shifts = shiftsStore.use()
  const visit = visitStore.use()
  const [filter, setFilter] = useState<ShiftStatus>('upcoming')
  const filtered = shifts.filter((s) => s.status === filter)

  return (
    <PBody>
      <PageIntro title="Schedule" subtitle="Your confirmed and past shifts" />
      <div className="pn-filters" role="tablist" aria-label="Filter shifts">
        {FILTERS.map((f) => {
          const count = shifts.filter((s) => s.status === f.value).length
          return (
            <button
              key={f.value}
              type="button"
              role="tab"
              aria-selected={filter === f.value}
              className={`pn-filter ${filter === f.value ? 'is-on' : ''}`}
              onClick={() => setFilter(f.value)}
            >
              {f.label} <span className="pn-filter-count">{count}</span>
            </button>
          )
        })}
      </div>

      {filtered.length === 0 ? (
        <PCard>
          <EmptyState icon="calendar" title="No shifts here yet" />
        </PCard>
      ) : (
        <ul className="p-list pn-grid2" role="tabpanel">
          {filtered.map((s) => {
            const isVisit = s.id === visit.shiftId && s.status === 'ongoing'
            return (
              <li key={s.id}>
                <PCard className="pn-rowcard pn-shift">
                  <span className={`pn-circle ${s.status === 'ongoing' ? '' : 'is-muted'}`}>
                    <PIcon name={s.status === 'completed' ? 'check' : 'calendar'} size={20} />
                  </span>
                  <div className="p-row-grow">
                    <strong className="pn-title">
                      {s.serviceType} · {s.patientName}
                    </strong>
                    <span className="p-muted pn-small">{s.timing}</span>
                    <span className="p-muted pn-small">{s.locality}</span>
                    {isVisit && (
                      <Link to={PR.nurseVisitExecution} className="pn-link pn-mt">
                        Open visit log <PIcon name="chevron" size={14} />
                      </Link>
                    )}
                  </div>
                  {s.status === 'ongoing' && <span className="pn-live">LIVE</span>}
                </PCard>
              </li>
            )
          })}
        </ul>
      )}
    </PBody>
  )
}
