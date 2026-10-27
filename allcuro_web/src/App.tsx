import { useEffect, type ReactNode } from 'react'
import { ActiveVisitBar } from './components/ActiveVisitBar'
import { FlowBackground } from './components/FlowBackground'
import { Header } from './components/Header'
import { Hero, TrustBand } from './components/Hero'
import { LoginDialog } from './components/LoginDialog'
import { CallBand, Faq, Footer, HowItWorks, MoreCare } from './components/Sections'
import { Toaster } from './components/ui'
import { ALL_SLUG, categories } from './data/categories'
import { centreById, equipmentById, nurseById } from './data/providers'
import { services } from './data/services'
import { LoginPage, ProfilePage } from './pages/AccountPages'
import { BookingDetailPage, BookingsPage } from './pages/BookingsPages'
import { CategoryPage, NotFound } from './pages/CategoryPage'
import { CentreBookingPage, CentrePage, CentresPage } from './pages/CentresPages'
import { EquipmentCheckoutPage, EquipmentPage } from './pages/EquipmentPages'
import { NurseBookingPage } from './pages/NurseBookingPage'
import { NursePage, NursesPage } from './pages/NursesPages'
import { ServicePage } from './pages/ServicePage'
import { useReveal, useSpotlight } from './motion'
import { usePath } from './router'

const HOME_TITLE = 'ALLCURO — Home Nursing & Elder Care'

function Home() {
  return (
    <>
      <Hero />
      <TrustBand />
      <div className="flow-area">
        <FlowBackground />
        <HowItWorks />
        <MoreCare />
        <Faq />
      </div>
      <CallBand />
      <ActiveVisitBar />
    </>
  )
}

/** Path patterns → page + tab title. The first match wins. */
const routes: { pattern: RegExp; page: (id: string) => ReactNode; title: (id: string) => string | undefined }[] = [
  {
    pattern: /^\/services\/([\w-]+)$/,
    page: (slug) => <CategoryPage key={slug} slug={slug} />,
    title: (slug) => {
      const label = slug === ALL_SLUG ? 'All Services' : categories.find((c) => c.slug === slug)?.label
      return label && `${label} at Home`
    },
  },
  {
    pattern: /^\/service\/([\w-]+)$/,
    page: (id) => <ServicePage key={id} id={id} />,
    title: (id) => services.find((s) => s.id === id)?.name,
  },
  { pattern: /^\/book-nurse$/, page: () => <NurseBookingPage />, title: () => 'Book a Nurse' },
  { pattern: /^\/nurses$/, page: () => <NursesPage />, title: () => 'Verified Nurses' },
  { pattern: /^\/nurses\/([\w-]+)$/, page: (id) => <NursePage id={id} />, title: (id) => nurseById(id)?.name },
  { pattern: /^\/centres$/, page: () => <CentresPage />, title: () => 'Care Centres' },
  { pattern: /^\/centres\/([\w-]+)$/, page: (id) => <CentrePage id={id} />, title: (id) => centreById(id)?.name },
  {
    pattern: /^\/centres\/([\w-]+)\/book$/,
    page: (id) => <CentreBookingPage key={id} id={id} />,
    title: () => 'Care Centre Admission',
  },
  { pattern: /^\/equipment$/, page: () => <EquipmentPage />, title: () => 'Medical Equipment on Rent' },
  {
    pattern: /^\/equipment\/([\w-]+)\/rent$/,
    page: (id) => <EquipmentCheckoutPage key={id} id={id} />,
    title: (id) => equipmentById(id) && `Rent ${equipmentById(id)!.name}`,
  },
  { pattern: /^\/bookings$/, page: () => <BookingsPage />, title: () => 'My Bookings' },
  { pattern: /^\/bookings\/([\w-]+)$/, page: (id) => <BookingDetailPage key={id} id={id} />, title: (id) => `Booking ${id}` },
  { pattern: /^\/login$/, page: () => <LoginPage />, title: () => 'Sign in' },
  { pattern: /^\/profile$/, page: () => <ProfilePage />, title: () => 'My Profile' },
]

export default function App() {
  const path = usePath().replace(/(.)\/$/, '$1')
  useReveal(path)
  useSpotlight()

  const route = routes.find((r) => r.pattern.test(path))
  const param = route ? (path.match(route.pattern)?.[1] ?? '') : ''

  // On every page change: jump to the #section if one was asked for, else to the top.
  useEffect(() => {
    const target = window.location.hash && document.getElementById(window.location.hash.slice(1))
    if (target) target.scrollIntoView()
    else window.scrollTo({ top: 0, behavior: 'instant' })

    const label = route?.title(param)
    document.title = label ? `${label} — ALLCURO` : HOME_TITLE
  }, [path, route, param])

  let page
  if (route) page = route.page(param)
  else if (path === '/') page = <Home />
  else page = <NotFound />

  return (
    <>
      <a href="#main" className="skip-link">
        Skip to content
      </a>
      <Header />
      <main id="main">{page}</main>
      <Footer />
      <LoginDialog />
      <Toaster />
    </>
  )
}
