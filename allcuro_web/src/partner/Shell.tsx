import type { ReactNode } from 'react'
import { Link } from '../components/Link'
import { initials } from '../lib/format'
import { PR } from './routes'
import { partnerLogout, statusBadge, usePartnerSession, usesNurseShell, type PartnerSession } from './session'
import { PIcon, type PIconName } from './ui'

// Role-aware partner shell — the app's ProviderShell (core/ui/app_shell.dart).
//
// Phones (≤ 1023px) look like the app: tab pages get the green header and a
// bottom tab bar; tool pages (earnings, documents…) are full-screen with their
// own back header.
//
// Desktop (≥ 1024px) is a web app layout: a fixed left sidebar (brand, area,
// status, the three main tabs, every tool, profile, sign out) and a slim top
// bar with notifications and the avatar — on every signed-in page.

type NavItem = { to: string; label: string; icon: PIconName }

const NURSE_TABS: NavItem[] = [
  { to: PR.nurseHome, label: 'Home', icon: 'grid' },
  { to: PR.nurseRequests, label: 'Requests', icon: 'clipboard' },
  { to: PR.nurseSchedule, label: 'Schedule', icon: 'calendar' },
]

const NURSE_TOOLS: NavItem[] = [
  { to: PR.nurseVisitExecution, label: 'Active visit', icon: 'navigate' },
  { to: PR.nurseAvailability, label: 'Availability', icon: 'clock' },
  { to: PR.nurseEarnings, label: 'Earnings', icon: 'wallet' },
  { to: PR.nurseRatings, label: 'Performance', icon: 'star' },
  { to: PR.nurseDocuments, label: 'Documents', icon: 'file' },
  { to: PR.nurseTraining, label: 'Training', icon: 'book' },
  { to: PR.nurseReferral, label: 'Refer & earn', icon: 'gift' },
  { to: PR.nurseSupport, label: 'Help & SOS', icon: 'help' },
]

const CENTRE_TABS: NavItem[] = [
  { to: PR.centreHome, label: 'Home', icon: 'grid' },
  { to: PR.centreRequests, label: 'Requests', icon: 'clipboard' },
  { to: PR.centreRooms, label: 'Rooms & beds', icon: 'bed' },
]

const CENTRE_TOOLS: NavItem[] = [
  { to: PR.centreStaff, label: 'Care staff', icon: 'users' },
  { to: PR.centreEquipment, label: 'Equipment', icon: 'box' },
  { to: PR.centreCompliance, label: 'Compliance', icon: 'shield' },
  { to: PR.centreListing, label: 'Listing', icon: 'store' },
  { to: PR.centreRevenue, label: 'Revenue', icon: 'chart' },
  { to: PR.centreReviews, label: 'Reviews', icon: 'star' },
  { to: PR.centrePromotions, label: 'Promotions', icon: 'megaphone' },
]

const ACCOUNT: NavItem[] = [
  { to: PR.bankAccount, label: 'Bank & payouts', icon: 'bank' },
  { to: PR.profile, label: 'Profile', icon: 'user' },
]

const brandFor = (s: PartnerSession) =>
  s.role === 'centre' ? 'ALLCURO PARTNER' : s.role === 'clinician' ? 'ALLCURO CLINICIAN' : 'ALLCURO NURSE'

function NavLinks({ items, path }: { items: NavItem[]; path: string }) {
  return (
    <ul className="p-side-list">
      {items.map((t) => (
        <li key={t.to}>
          <Link to={t.to} className="p-side-link" aria-current={path === t.to || path.startsWith(t.to + '/') ? 'page' : undefined}>
            <PIcon name={t.icon} size={19} />
            {t.label}
          </Link>
        </li>
      ))}
    </ul>
  )
}

export function PartnerShell({ path, tabbed, title, children }: { path: string; tabbed: boolean; title: string; children: ReactNode }) {
  const s = usePartnerSession()
  const nurse = usesNurseShell(s.role)
  const tabs = nurse ? NURSE_TABS : CENTRE_TABS
  const tools = nurse ? NURSE_TOOLS : CENTRE_TOOLS
  const badge = statusBadge(s)
  const area = (s.signup.city as string | undefined) || (s.signup.address as string | undefined) || 'Set your service area'
  const avatar = s.name ? initials(s.name) : <PIcon name="user" size={18} />

  return (
    <div className={`p-shell ${tabbed ? 'is-tabbed' : 'is-sub'}`}>
      {/* ---------------- desktop sidebar ---------------- */}
      <aside className="p-side" aria-label="Partner navigation">
        <Link to={tabs[0].to} className="p-brand" aria-label="Partner home">
          <span className="p-brand-mark">
            <PIcon name="heart" size={20} />
          </span>
          <span className="p-brand-text">{brandFor(s)}</span>
        </Link>
        <div className="p-side-status">
          <span className="p-area">
            <PIcon name="pin" size={15} /> {area}
          </span>
          <span className={`p-badge is-${badge.tone}`}>{badge.label}</span>
        </div>
        <nav className="p-side-nav" aria-label="Partner sections">
          <NavLinks items={tabs} path={path} />
          <p className="p-side-label">{nurse ? 'Tools & practice' : 'Facility management'}</p>
          <NavLinks items={tools} path={path} />
          <p className="p-side-label">Account</p>
          <NavLinks items={ACCOUNT} path={path} />
        </nav>
        <div className="p-side-foot">
          <Link to="/" className="p-side-link">
            <PIcon name="back" size={19} /> Customer site
          </Link>
          <button type="button" className="p-side-link" onClick={partnerLogout}>
            <PIcon name="logout" size={19} /> Sign out
          </button>
        </div>
      </aside>

      <div className="p-shell-main">
        {/* ---------------- desktop top bar ---------------- */}
        <div className="p-topbar">
          <h1 className="p-topbar-title">{title}</h1>
          <div className="p-header-actions">
            <button type="button" className="p-round p-round-light" aria-label="Notifications">
              <PIcon name="bell" size={19} />
              <span className="p-dot">2</span>
            </button>
            <Link to={PR.profile} className="p-topbar-user" aria-label="Profile">
              <span className="p-avatar is-solid">{avatar}</span>
              <span className="p-topbar-name">
                <strong>{s.name || 'Your profile'}</strong>
                <small>{badge.label}</small>
              </span>
            </Link>
          </div>
        </div>

        {/* ---------------- phone header (tab pages only) ---------------- */}
        {tabbed && (
          <header className="p-header">
            <div className="p-wrap p-header-top">
              <Link to={tabs[0].to} className="p-brand" aria-label="Partner home">
                <span className="p-brand-mark">
                  <PIcon name="heart" size={20} />
                </span>
                <span className="p-brand-text">{brandFor(s)}</span>
              </Link>
              <div className="p-header-actions">
                <button type="button" className="p-round" aria-label="Notifications">
                  <PIcon name="bell" size={19} />
                  <span className="p-dot">2</span>
                </button>
                <Link to={PR.profile} className="p-avatar" aria-label="Profile">
                  {avatar}
                </Link>
              </div>
            </div>
            <div className="p-wrap p-header-sub">
              <span className="p-area">
                <PIcon name="pin" size={15} /> {area}
              </span>
              <span className={`p-badge is-${badge.tone}`}>{badge.label}</span>
            </div>
          </header>
        )}

        <main className={`p-main ${tabbed ? 'p-main-tabbed' : ''}`}>{children}</main>
      </div>

      {tabbed && (
        <nav className="p-tabs-bottom" aria-label="Partner sections">
          {tabs.map((t) => (
            <Link key={t.to} to={t.to} className="p-btab" aria-current={path === t.to ? 'page' : undefined}>
              <PIcon name={t.icon} size={22} />
              <span>{t.label}</span>
            </Link>
          ))}
        </nav>
      )}
    </div>
  )
}
