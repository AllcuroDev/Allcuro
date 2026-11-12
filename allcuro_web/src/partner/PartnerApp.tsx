import { useEffect, type ReactNode } from 'react'
import { navigate, usePath } from '../router'
import { Toaster } from '../components/ui'
import { PR } from './routes'
import {
  identityPending,
  signupIncomplete,
  usePartnerSession,
  usesNurseShell,
  type PartnerSession,
} from './session'
import { PartnerShell } from './Shell'
import {
  BankAccountPage,
  IdentityVerificationPage,
  PartnerPhoneAuthPage,
  PartnerProfilePage,
  PartnerWelcomePage,
  RoleSelectPage,
} from './auth/AuthPages'
import { CentreSignupPage, ClinicianSignupPage, NurseSignupPage } from './auth/SignupPages'
import { PublicProfilePage } from './PublicProfilePage'
import * as Nurse from './nurse'
import * as Centre from './centre'
import './partner.css'

// The partner portal: the partner app (allcuro_partner) on the web. It is a
// separate experience from the customer site — no customer header/footer —
// reached from the "For partners" links in the site footer.

type Route = { pattern: RegExp; page: (param: string) => ReactNode; title: string; tab?: boolean }

const routes: Route[] = [
  { pattern: /^\/partner\/welcome$/, page: () => <PartnerWelcomePage />, title: 'Partner with ALLCURO' },
  { pattern: /^\/partner\/phone-auth$/, page: () => <PartnerPhoneAuthPage />, title: 'Partner sign in' },
  { pattern: /^\/partner\/role-select$/, page: () => <RoleSelectPage />, title: 'Choose your role' },
  { pattern: /^\/partner\/verify-identity$/, page: () => <IdentityVerificationPage />, title: 'Verify identity' },
  { pattern: /^\/partner\/profile$/, page: () => <PartnerProfilePage />, title: 'Partner profile' },
  { pattern: /^\/partner\/public-profile$/, page: () => <PublicProfilePage />, title: 'Public profile' },
  { pattern: /^\/partner\/bank-account$/, page: () => <BankAccountPage />, title: 'Bank account' },

  { pattern: /^\/partner\/nurse\/signup$/, page: () => <NurseSignupPage />, title: 'Nurse sign-up' },
  { pattern: /^\/partner\/clinician\/signup$/, page: () => <ClinicianSignupPage />, title: 'Doctor / physio sign-up' },
  { pattern: /^\/partner\/centre\/signup$/, page: () => <CentreSignupPage />, title: 'Centre sign-up' },

  { pattern: /^\/partner\/nurse\/home$/, page: () => <Nurse.NurseHomePage />, title: 'Partner home', tab: true },
  { pattern: /^\/partner\/nurse\/requests$/, page: () => <Nurse.NurseRequestsPage />, title: 'Visit requests', tab: true },
  { pattern: /^\/partner\/nurse\/schedule$/, page: () => <Nurse.NurseSchedulePage />, title: 'My schedule', tab: true },
  { pattern: /^\/partner\/nurse\/requests\/([\w-]+)$/, page: (id) => <Nurse.NurseRequestDetailPage key={id} id={id} />, title: 'Request details' },
  { pattern: /^\/partner\/nurse\/availability$/, page: () => <Nurse.NurseAvailabilityPage />, title: 'Availability' },
  { pattern: /^\/partner\/nurse\/earnings$/, page: () => <Nurse.NurseEarningsPage />, title: 'Earnings' },
  { pattern: /^\/partner\/nurse\/training$/, page: () => <Nurse.NurseTrainingPage />, title: 'Training' },
  { pattern: /^\/partner\/nurse\/ratings$/, page: () => <Nurse.NurseRatingsPage />, title: 'Ratings & performance' },
  { pattern: /^\/partner\/nurse\/visit-execution$/, page: () => <Nurse.NurseVisitExecutionPage />, title: 'Active visit' },
  { pattern: /^\/partner\/nurse\/documents$/, page: () => <Nurse.NurseDocumentsPage />, title: 'Document vault' },
  { pattern: /^\/partner\/nurse\/referral$/, page: () => <Nurse.NurseReferralPage />, title: 'Refer & earn' },
  { pattern: /^\/partner\/nurse\/support$/, page: () => <Nurse.NurseSupportPage />, title: 'Help & support' },

  { pattern: /^\/partner\/centre\/home$/, page: () => <Centre.CentreHomePage />, title: 'Centre home', tab: true },
  { pattern: /^\/partner\/centre\/requests$/, page: () => <Centre.CentreRequestsPage />, title: 'Placement requests', tab: true },
  { pattern: /^\/partner\/centre\/rooms$/, page: () => <Centre.CentreRoomsPage />, title: 'Rooms & beds', tab: true },
  { pattern: /^\/partner\/centre\/listing$/, page: () => <Centre.CentreListingPage />, title: 'Listing' },
  { pattern: /^\/partner\/centre\/revenue$/, page: () => <Centre.CentreRevenuePage />, title: 'Revenue' },
  { pattern: /^\/partner\/centre\/reviews$/, page: () => <Centre.CentreReviewsPage />, title: 'Reviews' },
  { pattern: /^\/partner\/centre\/compliance$/, page: () => <Centre.CentreCompliancePage />, title: 'Compliance' },
  { pattern: /^\/partner\/centre\/equipment$/, page: () => <Centre.CentreEquipmentPage />, title: 'Equipment' },
  { pattern: /^\/partner\/centre\/staff$/, page: () => <Centre.CentreStaffPage />, title: 'Care staff' },
  { pattern: /^\/partner\/centre\/promotions$/, page: () => <Centre.CentrePromotionsPage />, title: 'Promotions' },
]

/** Same rules as the partner app's go_router `redirect` (core/router/app_router.dart). */
function redirectFor(s: PartnerSession, path: string): string | null {
  if (!s.isLoggedIn) return path === PR.welcome || path === PR.phoneAuth ? null : PR.welcome
  if (!s.role) return path === PR.roleSelect ? null : PR.roleSelect

  const nurseShell = usesNurseShell(s.role)
  const home = nurseShell ? PR.nurseHome : PR.centreHome
  const ownPrefix = nurseShell ? '/partner/nurse' : '/partner/centre'

  if (identityPending(s)) return path === PR.identityVerification ? null : PR.identityVerification

  const signupRoute = s.role === 'nurse' ? PR.nurseSignup : s.role === 'clinician' ? PR.clinicianSignup : PR.centreSignup
  if (signupIncomplete(s)) return path === signupRoute ? null : signupRoute

  if (([PR.root, PR.welcome, PR.phoneAuth, PR.roleSelect, PR.identityVerification, signupRoute] as string[]).includes(path)) return home
  if (!path.startsWith(ownPrefix) && path !== PR.profile && path !== PR.publicProfile && path !== PR.bankAccount) return home
  return null
}

/** Signed-in pages (everything after sign-up) live inside the shell; welcome, sign-in, role select, identity and sign-up don't. */
const inApp = (path: string) =>
  path === PR.profile ||
  path === PR.publicProfile ||
  path === PR.bankAccount ||
  (/^\/partner\/(nurse|centre)\//.test(path) && !path.endsWith('/signup'))

export default function PartnerApp() {
  const path = usePath().replace(/(.)\/$/, '$1')
  const session = usePartnerSession()
  const target = redirectFor(session, path)

  useEffect(() => {
    if (target && target !== path) navigate(target, { replace: true })
  }, [target, path])

  const route = routes.find((r) => r.pattern.test(path))

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'instant' })
    document.title = `${route?.title ?? 'Partner'} — ALLCURO Partner`
  }, [path, route])

  if (target && target !== path) return null
  if (!route) return null
  const param = path.match(route.pattern)?.[1] ?? ''
  const page = route.page(param)

  return (
    <div className="partner">
      {inApp(path) ? (
        <PartnerShell path={path} tabbed={!!route.tab} title={route.title}>
          {page}
        </PartnerShell>
      ) : (
        <main className="p-main">{page}</main>
      )}
      <Toaster />
    </div>
  )
}
