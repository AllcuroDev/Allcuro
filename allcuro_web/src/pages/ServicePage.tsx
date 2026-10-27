import { IconTile } from '../components/CareIcon'
import { CheckIcon, ClockIcon, MinusIcon, UserIcon, BoltIcon } from '../components/Icons'
import { NurseCard } from '../components/NurseCard'
import { bookingPath } from '../data/booking'
import { ActionBar, PageHead } from '../components/ui'
import { categories, categoryById, categoryPath } from '../data/categories'
import { nurses, type Nurse } from '../data/providers'
import { services } from '../data/services'
import { navigate } from '../router'
import { requireLogin } from '../state/auth'
import { NotFound } from './CategoryPage'

const split = (text: string) =>
  text
    .split(';')
    .map((t) => t.trim().replace(/\.$/, ''))
    .filter(Boolean)

/** Which professionals can do a category's services. Categories without home nurses (doctor visits, labs) list none. */
const canServe: Record<string, (n: Nurse) => boolean> = {
  'Nursing Care': (n) => !/Physio|Attendant/.test(n.level),
  'Elder Care': (n) => /Attendant|GNM|ANM/.test(n.level),
  'Mother & Baby Care': (n) => /ANM|B\.Sc/.test(n.level),
  Physiotherapy: (n) => /Physio/.test(n.level),
}

/** One service: what's included, who can come, and the way into booking (the app's ServiceDetailScreen). */
export function ServicePage({ id }: { id: string }) {
  const s = services.find((x) => x.id === id)
  if (!s) return <NotFound />
  const cat = categoryById[s.category] ?? categories[0]
  const pros = nurses.filter(canServe[s.category] ?? (() => false))

  const book = () => requireLogin(() => navigate(bookingPath({ service: s.id })))

  return (
    <>
      <div className="container page">
        <PageHead
          back={categoryPath(cat.slug)}
          title={s.name}
          subtitle={`${cat.label} · ${s.subcategory}`}
          aside={<span className="price-pill">{s.price}</span>}
        />

        <div className="detail-grid">
          <section className="panel">
            <div className="svc-hero">
              <IconTile name={s.icon} ink={cat.ink} wash={cat.wash} size={64} />
              <p>{s.description}</p>
            </div>
            <div className="fact-row">
              <span>
                <ClockIcon size={16} /> {s.duration}
              </span>
              <span>
                <UserIcon size={16} /> {s.professional}
              </span>
              {s.badge && <span className="badge badge-glow">{s.badge}</span>}
            </div>

            <div className="dlg-lists">
              <div>
                <h4>What’s included</h4>
                <ul className="list-yes">
                  {split(s.includes).map((t) => (
                    <li key={t}>
                      <CheckIcon size={16} /> <span>{t}</span>
                    </li>
                  ))}
                </ul>
              </div>
              <div>
                <h4>Not included</h4>
                <ul className="list-no">
                  {split(s.notIncluded).map((t) => (
                    <li key={t}>
                      <MinusIcon size={16} /> <span>{t}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
            {s.notes && s.notes !== '—' && (
              <p className="dlg-note">
                <strong>Note:</strong> {s.notes}
              </p>
            )}
          </section>

          <section aria-labelledby="pros-title">
            <h2 id="pros-title" className="step-title">
              {pros.length ? 'Choose your professional' : 'How it works'}
            </h2>
            {pros.length ? (
              <div className="stack">
                {pros.map((n) => (
                  <NurseCard key={n.id} nurse={n} serviceId={s.id} />
                ))}
              </div>
            ) : (
              <p className="panel muted">
                Book now and our care desk assigns a verified {s.professional.toLowerCase()} near you. You’ll see who is
                coming, their ID and a visit OTP in My Bookings.
              </p>
            )}
          </section>
        </div>
      </div>

      <ActionBar label={s.duration} amount={s.price}>
        <button type="button" className="btn btn-primary btn-lg" onClick={book}>
          <BoltIcon /> Book Service
        </button>
      </ActionBar>
    </>
  )
}
