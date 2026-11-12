import { IconTile } from '../components/CareIcon'
import { CheckIcon, ClockIcon, MinusIcon, UserIcon, BoltIcon, PhoneIcon, ShieldIcon } from '../components/Icons'
import { NurseCard } from '../components/NurseCard'
import { bookingPath } from '../data/booking'
import { ActionBar, PageHead } from '../components/ui'
import { categories, categoryById, categoryPath, isCompanionService } from '../data/categories'
import { site } from '../data/site'
import { nurses, type Nurse } from '../data/providers'
import { useServices } from '../state/catalog'
import { navigate } from '../router'
import { requireLogin } from '../state/auth'
import { NotFound } from './CategoryPage'

const split = (text: string) =>
  text
    .split(';')
    .map((t) => t.trim().replace(/\.$/, ''))
    .filter(Boolean)

/** Partner kinds that can do a category's services when they haven't picked services explicitly. */
const kindsFor: Record<string, Nurse['kind'][]> = {
  'Nursing Care': ['nurse'],
  'Elder Care': ['nurse', 'caregiver'],
  'Mother & Baby Care': ['nurse', 'caregiver'],
  Physiotherapy: ['physiotherapist'],
  'Doctor Care': ['doctor'],
  Caregivers: ['caregiver'],
}

/** Approved partners who offer this service: picked it on their profile, or are the right kind and haven't narrowed their list. */
const canServe = (n: Nurse, s: { id: string; category: string }) =>
  n.serviceIds.includes(s.id) || (n.serviceIds.length === 0 && (kindsFor[s.category] ?? []).includes(n.kind))

/** One service: what's included, who can come, and the way into booking (the app's ServiceDetailScreen). */
export function ServicePage({ id }: { id: string }) {
  const s = useServices().find((x) => x.id === id)
  if (!s) return <NotFound />
  const cat = categoryById[s.category] ?? categories[0]
  if (!cat) return <NotFound />
  const companion = isCompanionService(s)
  const pros = companion ? [] : nurses.filter((n) => canServe(n, s))

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
              <IconTile name={s.icon} image={s.imageUrl} ink={cat.ink} wash={cat.wash} size={64} />
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
            {companion ? (
              <div className="panel stack-sm">
                <p className="trust-note">
                  <ShieldIcon size={20} /> A verified ALLCURO companion will be assigned
                </p>
                <p className="muted">
                  Book now and our care desk assigns a police-verified hospital companion for your visit. Companions
                  give non-clinical support only — the hospital’s doctors and nurses handle all medical care. You’ll see
                  who is coming and a visit OTP in My Bookings.
                </p>
                <div className="row-actions">
                  <button type="button" className="btn btn-primary" onClick={book}>
                    <BoltIcon /> Book Service
                  </button>
                  <a className="btn btn-outline" href={site.phoneHref}>
                    <PhoneIcon size={18} /> Call {site.phoneDisplay}
                  </a>
                </div>
              </div>
            ) : pros.length ? (
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
