import { PhoneIcon, PillIcon } from '../components/Icons'
import { Link } from '../components/Link'
import { site } from '../data/site'

/** Medicine ordering isn't live yet; every /medicines link lands here. */
export function MedicinesComingSoonPage() {
  return (
    <section className="container">
      <div className="soon">
        <span className="soon-icon" aria-hidden="true">
          <PillIcon size={40} />
        </span>
        <span className="soon-tag">Coming soon</span>
        <h1>Order medicines</h1>
        <p>
          Medicine delivery to your door is on its way. Soon you'll be able to search medicines or upload a
          prescription right here. Until then, our care team is happy to help.
        </p>
        <div className="soon-actions">
          <a className="btn btn-primary" href={site.phoneHref}>
            <PhoneIcon size={16} /> Call {site.phoneDisplay}
          </a>
          <Link to="/" className="btn btn-outline">
            Back to home
          </Link>
        </div>
      </div>
    </section>
  )
}
