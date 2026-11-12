import { useState } from 'react'
import { CheckIcon, ShieldIcon } from '../components/Icons'
import { NurseCard } from '../components/NurseCard'
import { bookingPath } from '../data/booking'
import { ActionBar, PageHead, PartnerPhoto, Rating } from '../components/ui'
import { kindLabel, lowestPrice, nurseById, nurseFilters, nurses, type Nurse } from '../data/providers'
import { site } from '../data/site'
import { inr } from '../lib/format'
import { navigate, useQuery } from '../router'
import { requireLogin } from '../state/auth'
import { NotFound } from './CategoryPage'

const matches = (n: Nurse, words: string[]) =>
  words.length === 0 ||
  words.some((w) => (w.startsWith('kind:') ? n.kind === w.slice(5) : n.level.includes(w) || n.tags.some((t) => t.includes(w))))

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
        title={isFiltered ? filter : 'Nurses, Doctors & Caregivers'}
        subtitle="Every professional here is verified and approved by ALLCURO"
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
          <p>
            {nurses.length
              ? `No approved professionals under “${filter}” yet.`
              : 'No professionals have been approved yet. Call our care desk and we’ll arrange care for you.'}
          </p>
          {nurses.length ? (
            <button type="button" className="btn btn-outline" onClick={() => setFilter(nurseFilters[0].label)}>
              View everyone
            </button>
          ) : (
            <a className="btn btn-primary" href={site.phoneHref}>
              Call {site.phoneDisplay}
            </a>
          )}
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
  const from = lowestPrice(nurse)

  const book = () =>
    requireLogin(() => navigate(bookingPath({ nurse: nurse.id })), {
      title: 'Quick Login to Book',
      subtitle: `Enter your phone number to book ${nurse.name}`,
    })

  return (
    <>
      <div className="container page">
        <PageHead
          back="/nurses"
          title={nurse.name}
          subtitle={[kindLabel[nurse.kind], nurse.allcuroId && `ID ${nurse.allcuroId}`, nurse.employment].filter(Boolean).join(' · ')}
        />
        <div className="detail-grid">
          <section className="panel profile-hero">
            <PartnerPhoto src={nurse.photo} name={nurse.name} className="profile-photo" size={120} />
            <div>
              <h2>
                {nurse.name} <ShieldIcon size={18} />
              </h2>
              <p className="muted">
                {[nurse.level, nurse.experience ? `${nurse.experience} yrs experience` : '', nurse.city].filter(Boolean).join(' · ')}
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
            {nurse.bio && (
              <section className="panel">
                <h3 className="panel-title">About</h3>
                <p>{nurse.bio}</p>
              </section>
            )}
            <section className="panel">
              <h3 className="panel-title">Specialisations</h3>
              <div className="tag-row">
                {nurse.tags.map((t) => (
                  <span key={t} className="tag">
                    {t}
                  </span>
                ))}
              </div>
              {nurse.languages.length > 0 && (
                <>
                  <h3 className="panel-title">Languages</h3>
                  <p>{nurse.languages.join(' · ')}</p>
                </>
              )}
            </section>

            <section className="panel">
              <h3 className="panel-title">Services & rates</h3>
              {nurse.shifts.length ? (
                <ul className="shift-list">
                  {nurse.shifts.map((s, i) => (
                    <li key={`${s.label}-${i}`}>
                      <span>
                        {s.label} <small className="muted">· {s.unit}</small>
                      </span>
                      <strong>
                        {s.mrp > s.price && <s className="muted">{inr(s.mrp)}</s>} {inr(s.price)}
                      </strong>
                      <span className={s.available ? 'avail-dot' : 'muted'}>{s.available ? 'Available' : 'Busy'}</span>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="muted">Rates are being set up. Call {site.phoneDisplay} to book.</p>
              )}
            </section>

            {nurse.highlights.length > 0 && (
              <section className="panel">
                <h3 className="panel-title">Highlights</h3>
                <ul className="quote-list">
                  {nurse.highlights.map((h) => (
                    <li key={h}>{h}</li>
                  ))}
                </ul>
              </section>
            )}
          </div>
        </div>
      </div>
      {from != null ? (
        <ActionBar label="From" amount={inr(from)}>
          <button type="button" className="btn btn-primary btn-lg" onClick={book}>
            Book {nurse.name.split(' ')[0]}
          </button>
        </ActionBar>
      ) : (
        <ActionBar label="Pricing" amount="On request">
          <a href={site.phoneHref} className="btn btn-primary btn-lg">
            Call {site.phoneDisplay}
          </a>
        </ActionBar>
      )}
    </>
  )
}
