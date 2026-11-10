import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { PBody, PCard, PPageHead, PSectionTitle, Toggle } from '../ui'
import { CAMPAIGNS, FEATURED_PRICE_LABEL } from './data'
import { promotionsStore, usePromotions } from './state'
import './centre.css'

// Promotions & paid visibility (features/centre/presentation/promotions/promotions_screen.dart).
// Demo only — nothing is billed.

export function CentrePromotionsPage() {
  const p = usePromotions()

  const setFeatured = (v: boolean) => {
    promotionsStore.set((s) => ({ ...s, featured: v }))
    toast(v ? 'Featured placement activated (demo)' : 'Featured placement turned off', v ? 'success' : 'info')
  }
  const setCampaign = (id: string, name: string, v: boolean) => {
    promotionsStore.set((s) => ({ ...s, campaigns: { ...s.campaigns, [id]: v } }))
    toast(v ? `${name} campaign is on` : `${name} campaign is off`, 'info')
  }

  return (
    <>
      <PPageHead title="Promotions" subtitle="Opt into paid visibility and discount campaigns" back={PR.centreHome} />
      <PBody narrow>
        <PCard className="pc-switch-card">
          <span className="p-row-grow">
            <strong>Featured placement</strong>
            <span className="p-muted pc-small">Appear at the top of search results in your area — {FEATURED_PRICE_LABEL}</span>
          </span>
          <Toggle checked={p.featured} onChange={setFeatured} label="Featured placement" />
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
                  <Toggle checked={!!p.campaigns[c.id]} onChange={(v) => setCampaign(c.id, c.name, v)} label={c.name} />
                </PCard>
              </li>
            ))}
          </ul>
        </section>
      </PBody>
    </>
  )
}
