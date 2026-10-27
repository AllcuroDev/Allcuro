import { useState } from 'react'
import { CheckIcon, ShieldIcon } from '../components/Icons'
import { NurseCard } from '../components/NurseCard'
import { bookingPath } from '../data/booking'
import { ActionBar, PageHead, Rating } from '../components/ui'
import { nurseById, nurseFilters, nurses, type Nurse } from '../data/providers'
import { inr } from '../lib/format'
import { navigate, useQuery } from '../router'
import { requireLogin } from '../state/auth'
import { NotFound } from './CategoryPage'

const matches = (n: Nurse, words: string[]) =>
  words.length === 0 || words.some((w) => n.level.includes(w) || n.tags.some((t) => t.includes(w)))

/** Verified nurses with specialty filters (the app's NursesListScreen). */
export function NursesPage() {
  const initial = useQuery('specialty')
  const [filter, setFilter] = useState(nurseFilters.find((f) => f.label === initial)?.label ?? nurseFilters[0].label)
  const active = nurseFilters.find((f) => f.label === filter)!
  const list = nurses.filter((n) => matches(n, active.match))
  const isFiltered = active.match.length > 0

  return (
    <div className="container page">
      <PageHead
        back="/"
        title={isFiltered ? `${filter} Nurses` : 'Nurses & Attendants'}
        subtitle={isFiltered ? `Certified nurses specialised in ${filter}` : 'Police-verified, HPR-registered and rated by families'}
      />
      <div className="chip-row filter-row" role="group" aria-label="Filter by specialty">
        {nurseFilters.map((f) => (
          <button
            key={f.label}
            type="button"
            className={`chip ${f.label === filter ? 'is-active' : ''}`}
            aria-pressed={f.label === filter}
            onClick={() => setFilter(f.label)}
          >
            {f.label}
          </button>
        ))}
      </div>
      {list.length ? (
        <div className="card-grid">
          {list.map((n) => (
            <NurseCard key={n.id} nurse={n} />
          ))}
        </div>
      ) : (
        <div className="empty">
          <p>No nurses found for “{filter}”.</p>
          <button type="button" className="btn btn-outline" onClick={() => setFilter(nurseFilters[0].label)}>
            View all nurses
          </button>
        </div>
      )}
    </div>
  )
}

const CHECKS = ['Police verified', 'Medically fit', 'Reference checked']

/** One nurse's profile, checks and shifts (the app's NurseDetailScreen). */
export function NursePage({ id }: { id: string }) {
  const nurse = nurseById(id)
  if (!nurse) return <NotFound />
  const from = Math.min(...nurse.shifts.map((s) => s.price))

  const book = () =>
    requireLogin(() => navigate(bookingPath({ nurse: nurse.id })), {
      title: 'Quick Login to Book',
      subtitle: `Enter your phone number to book ${nurse.name}`,
    })

  return (
    <>
      <div className="container page">
        <PageHead back="/nurses" title={nurse.name} subtitle={`ID ${nurse.allcuroId} · ${nurse.employment}`} />
        <div className="detail-grid">
          <section className="panel profile-hero">
            <img src={nurse.photo} alt={`${nurse.name}, ${nurse.level}`} className="profile-photo" />
            <div>
              <h2>
                {nurse.name} <ShieldIcon size={18} />
              </h2>
              <p className="muted">
                {nurse.level} · {nurse.experience} yrs experience · {nurse.city}
              </p>
              <Rating value={nurse.rating} count={nurse.reviews} />
              <ul className="check-row">
                {CHECKS.map((c) => (
                  <li key={c}>
                    <CheckIcon size={15} /> {c}
                  </li>
                ))}
              </ul>
            </div>
          </section>

          <div className="stack">
            <section className="panel">
              <h3 className="panel-title">Specialisations</h3>
              <div className="tag-row">
                {nurse.tags.map((t) => (
                  <span key={t} className="tag">
                    {t}
                  </span>
                ))}
              </div>
              <h3 className="panel-title">Languages</h3>
              <p>{nurse.languages.join(' · ')}</p>
            </section>

            <section className="panel">
              <h3 className="panel-title">Shift availability</h3>
              <ul className="shift-list">
                {nurse.shifts.map((s) => (
                  <li key={s.label}>
                    <span>{s.label}</span>
                    <strong>{inr(s.price)}</strong>
                    <span className={s.available ? 'avail-dot' : 'muted'}>{s.available ? 'Available' : 'Booked'}</span>
                  </li>
                ))}
              </ul>
            </section>

            <section className="panel">
              <h3 className="panel-title">What families say</h3>
              <ul className="quote-list">
                {nurse.highlights.map((h) => (
                  <li key={h}>“{h}”</li>
                ))}
              </ul>
            </section>
          </div>
        </div>
      </div>
      <ActionBar label="From" amount={inr(from)}>
        <button type="button" className="btn btn-primary btn-lg" onClick={book}>
          Book this nurse
        </button>
      </ActionBar>
    </>
  )
}
