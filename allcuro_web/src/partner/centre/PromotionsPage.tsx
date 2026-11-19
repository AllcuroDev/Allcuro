import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { saveSignup, usePartnerSession } from '../session'
import { EmptyState, PBody, PCard, PPageHead, PSectionTitle, Toggle } from '../ui'
import { CAMPAIGNS } from './data'
import './centre.css'

// Promotions & paid visibility (features/centre/presentation/promotions/promotions_screen.dart).
// Promotions aren't live yet: the toggles record the centre's interest on its
// partner row (details.promotionInterest) so ALLCURO can follow up. Nothing is billed.

interface PromotionInterest {
  featured?: boolean
  campaigns?: Record<string, boolean>
}

export function CentrePromotionsPage() {
  const s = usePartnerSession()
  const p = (s.signup.promotionInterest ?? {}) as PromotionInterest
  const campaigns = p.campaigns ?? {}

  const save = (next: PromotionInterest) => saveSignup({ promotionInterest: next })
  const setFeatured = (v: boolean) => {
    save({ ...p, featured: v })
    toast(v ? 'Noted — we’ll contact you about featured placement.' : 'Featured placement interest removed', 'info')
  }
  const setCampaign = (id: string, name: string, v: boolean) => {
    save({ ...p, campaigns: { ...campaigns, [id]: v } })
    toast(v ? `Noted your interest in “${name}”` : `Removed “${name}”`, 'info')
  }

  return (
    <>
      <PPageHead title="Promotions" subtitle="Opt into paid visibility and discount campaigns" back={PR.centreHome} />
      <PBody narrow>
        <p className="p-muted pc-small">Promotions aren’t live yet. Turn on what interests you and ALLCURO will get in touch before anything starts or is billed.</p>
        <PCard className="pc-switch-card">
          <span className="p-row-grow">
            <strong>Featured placement</strong>
            <span className="p-muted pc-small">Appear at the top of search results in your area.</span>
          </span>
          <Toggle checked={!!p.featured} onChange={setFeatured} label="Featured placement" />
        </PCard>

        <section className="pc-stack" aria-labelledby="pc-campaigns">
          <PSectionTitle>
            <span id="pc-campaigns">Discount campaigns</span>
          </PSectionTitle>
          <ul className="p-list">
            {CAMPAIGNS.map((c) => (
              <li key={c.id}>
                <PCard className="pc-switch-card">
                  <span className="p-row-grow">
                    <strong>{c.name}</strong>
                    <span className="p-muted pc-small">{c.description}</span>
                  </span>
                  <Toggle checked={!!campaigns[c.id]} onChange={(v) => setCampaign(c.id, c.name, v)} label={c.name} />
                </PCard>
              </li>
            ))}
          </ul>
        </section>

        <section className="pc-stack" aria-labelledby="pc-results">
          <PSectionTitle>
            <span id="pc-results">Results</span>
          </PSectionTitle>
          <PCard>
            <EmptyState icon="chart" title="No campaign results yet" text="Views and bookings from promotions will show up here once they run." />
          </PCard>
        </section>
      </PBody>
    </>
  )
}
