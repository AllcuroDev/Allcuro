# ALLCURO Website — Developer Context & Architecture

> **Directory:** `/allcuro_web`  
> **Target Audience:** Patients, families, and elderly people in India looking for home healthcare — many of them older or less confident online.  
> **Stack:** React 19, Vite 8, TypeScript, plain CSS (no UI library), Leaflet (tracker map only, lazy-loaded), Google Fonts (Plus Jakarta Sans). Styles: `index.css` (site) + `app.css` (booking, tracking & account pages).

---

## 1. Purpose

The public marketing website for ALLCURO. It shows every service clearly, with its price, and lets visitors **sign in, book, pay and track** the same way as the customer app (`/allcuro`): phone + OTP login, nurse visits, care-centre admissions, equipment rental, payment, live nurse tracking, the centre admission pass, and My Bookings. Phone and WhatsApp stay available on every page.

**Demo mode, like the app:** there is no backend yet. Login uses the fixed OTP `123456`; profile, addresses and bookings live in `localStorage` (per phone number); payment is a simulated checkout (no money is charged); the live tracker follows the app's simulated 90-second route. Everything goes through `src/state/*` and `PaymentDialog`'s `processPayment`, so wiring Supabase / Razorpay only touches those files.

---

## 2. Routes & Page Map

Routing is a tiny history-API router (`src/router.ts` + `src/components/Link.tsx`); there is no router library.

| Route | Component | Purpose |
|---|---|---|
| `/` | `Home` in `App.tsx` | Landing page (sections below). |
| `/services/:slug` | `CategoryPage` (`pages/CategoryPage.tsx`) | Lists one category's services, grouped by subcategory. Slugs: `nursing`, `elder-care`, `mother-baby`, `physiotherapy`, `doctor-care`, `diagnostics`, `wellness` (same as the app's `/category-services/:slug`). |
| `/services/all` | `CategoryPage` | Every service, grouped by category. |
| `/service/:id` | `ServicePage` | One service: included / not included, professionals who can do it (nurse cards → "Book Slot" sheet), Book Service. App: `/services/:serviceId`. |
| `/book-nurse` | `NurseBookingPage` | Service, nurse, slot, patient, address, coupon, bill → payment. Query: `service`, `nurse`, `duration`, `slot`. App: `/nurse-quick-booking`. |
| `/nurses`, `/nurses/:id` | `NursesPage`, `NursePage` | Nurse list with specialty filters; nurse profile. |
| `/centres`, `/centres/:id`, `/centres/:id/book` | `CentresPages.tsx` | Centre list, detail, admission booking (room, stay, patient, deposit) → payment. |
| `/equipment`, `/equipment/:id/rent` | `EquipmentPages.tsx` | Equipment list; rental checkout (plan, delivery slot, address, coupon) → payment. App: `/checkout?item=`. |
| `/bookings` | `BookingsPage` | Active / past bookings with OTPs. |
| `/bookings/:id` | `BookingDetailPage` | Nurse → live tracker (Leaflet map, OTP, steps, vitals, call, rate, SOS); centre → admission pass; equipment → delivery tracker. App: `/nurse-tracker/:id`, `/centre-pass/:id`. |
| `/login?next=` | `LoginPage` | Phone → OTP → first-time profile setup (app: `/auth/phone` + `/onboarding`). |
| `/profile` | `ProfilePage` | Profile, KYC tier, saved addresses, sign out. |
| anything else | `NotFound` | Links to all services / home. |

Booking actions call `requireLogin()` (`state/auth.ts`), which opens `LoginDialog` for guests — the app's `QuickLoginSheet` — and continues the booking after sign-in. Routes are matched in the `routes` table in `App.tsx`.

**Home page sections (top to bottom):**

| Anchor | Component | Purpose |
|---|---|---|
| `#top` | `Hero` (`components/Hero.tsx`) | "Healthcare at your doorstep" plus a compact bordered box of 8 illustrated category tiles (7 care types + All Services) linking to `/services/:slug`. Photo collage on the right with a "100% verified" card. Layout inspired by Urban Company. |
| `#why-allcuro` | `TrustBand` (`components/Hero.tsx`) | Green gradient band: 100% Verified, Flexible Slots, Transparent Pricing, 24/7 Care Desk (same claims as the app home screen). |
| `#how-it-works` | `HowItWorks` (`components/Sections.tsx`) | Three numbered step cards (same copy as the app). |
| — | `MoreCare` (`components/Sections.tsx`) | Care centres and equipment rental teaser cards. |
| `#faq` | `Faq` (`components/Sections.tsx`) | `<details>` accordion; content from the app's `faq_screen.dart`. |
| — | `CallBand`, `Footer` (`components/Sections.tsx`) | Closing call/WhatsApp CTA, contact details, and the emergency note ("call 112"). |

**Category page:** breadcrumb, category header (icon, blurb, count), a sticky "Types of care" sidebar for switching categories (a horizontal pill strip on phones), and service rows (icon, name, badge, description, duration, professional, price, "View details"). A row opens `ServiceDialog` (`components/ServiceDialog.tsx`), a native `<dialog>` showing price, time, who comes, what's included and what's not, notes, and Call / WhatsApp booking buttons. Each category page ends with the `CallBand`.

**Hosting note:** because routes are real paths, the host must rewrite unknown paths to `index.html` (SPA fallback). `vite dev` and `vite preview` already do this.

---

## 3. Data — Single Source of Truth Is the App

| File | Source in the customer app | Notes |
|---|---|---|
| `src/data/services.ts` | `allcuro/lib/features/services/data/master_services_catalog.dart` + icon map in `allcuro/lib/core/ui/care_icon.dart` | **Generated** — do not hand-edit if the app catalog changes; regenerate it (see below). |
| `src/data/categories.ts` | Home grid in `home_screen.dart` + `CareTone` in `care_icon.dart` | Category id = `mainCategory` string from the catalog. Each has `ink` (glyph) and `wash` (tile) colours. |
| `src/data/faqs.ts` | `allcuro/lib/features/profile/presentation/faq_screen.dart` | Plus one pricing FAQ. |
| `src/data/providers.ts` | `nurses_service.dart`, `centres_service.dart`, `equipment_service.dart` | Nurses, centres, equipment. |
| `src/data/booking.ts` | `nurse_quick_booking_screen.dart`, `service_detail_screen.dart`, `centre_booking_screen.dart`, `checkout_repository.dart` | Booking options and price rules (fee ₹99 + 18% GST, centre deposit, coupons). |
| `src/data/route.ts` | `nurse_live_map.dart` | Simulated nurse route for the tracker. |
| `src/state/` | Auth / bookings / location view models | localStorage-backed stores (`lib/store.ts`). |
| `src/data/site.ts` | — | Phone, WhatsApp, email, cities. **Currently placeholders from the app's demo data — replace before launch.** |
| `src/assets/icons/care/*.svg` | `allcuro/assets/icons/care/` | Duotone 24×24 icons drawn in `currentColor`; rendered inline by `CareIcon` so they take the category tone. |
| `src/assets/images/` | `allcuro/assets/images/` | Nurse, centre, and equipment photos. |

**Regenerating `services.ts` after the app catalog changes:** the catalog is parsed from the Dart `MasterServiceItem(...)` blocks (`id`, `name`, `mainCategory` → `category`, etc.) and each service's `icon` is the SVG file name from `CareIcons._byService`. Keep the field names in `src/data/types.ts` in sync with the Dart model. New `mainCategory` values also need an entry in `categories.ts`.

---

## 4. Design System & Theme Tokens

Tokens in `src/index.css` mirror `AppColors` / `AppRadius` in `allcuro/lib/core/theme/app_theme.dart`:

- **Colors:**
  - Primary: `#26593B` (Forest Green) · Primary Soft: `#DDF4E4` (Mint) · Primary Deep: `#0C341E` · Accent: `#3A8357`
  - Background: `#FEFDFC` (Warm off-white) · Card: `#FFFFFF` · Ink: `#111512` · Border: `#E3E7E4`
  - Warm accent: `#ED6C00` / `#FFF3E6` (urgent / badges / focus ring)
  - Gradient: `#143621 → #26593B → #43845B` (trust band, call band, help card)
  - Category tones (`CareTone`): Nursing green, Elder amber, Mother & Baby pink, Physio blue, Doctor violet, Diagnostics cyan, Wellness teal.
- **Typography:** Plus Jakarta Sans, kept calm and minimal: headings `600`, labels/buttons/nav `500`, body `400`. No `700+` weights except the logo wordmark. Hero title is `clamp(1.9rem, 3.4vw, 2.6rem)`; section titles top out around `1.9rem`.
- **Category illustrations:** `src/assets/images/categories/*.png` are 3D claymorphic squircle artworks (matching the customer app). They have clean anti-aliased squircle edges with transparent background and soft natural 3D shadows so they blend seamlessly into the hero card and category tiles without background-box glitches. Category → artwork mapping is the `art` field in `categories.ts`; URLs come from `components/art.ts`.
- **Radius scale:** 12 / 14 / 16 / 20 / 24 / 32 px.
- **Light theme only**, matching the app.
- **Motion:** kept subtle. `main.tsx` adds `.motion` to `<html>` unless the visitor prefers reduced motion, and all self-running animation is scoped to it. `src/motion.ts` provides `useReveal` (fades in any `.reveal` element on scroll; `--d` staggers it) and `useSpotlight` (a soft cursor glow on `.spotlight` cards). Both are called once in `App.tsx`. On the home page, `FlowBackground` draws a DNA helix behind How it works → FAQ (inside `.flow-area`); it forms and twists as you scroll, and its shape and speed are set by the constants at the top of the file.

---

## 5. Key Rules for Development

1. **Services first.** The hero category tiles are the main way into the site: one tap reaches a category page with every service and its price. Every service in the app catalog must appear on a category page; the dialog only adds detail.
2. **Elder-friendly by default:**
   - Base font size is 17px (`font-size: 106.25%` on `:root`). Size everything in `rem` so browser zoom / OS text-size settings scale the whole page.
   - Tap targets are at least 44–48px; primary CTAs are 52px.
   - Keep high contrast: body copy uses `--muted-fg: #4F5752`, slightly darker than the app's muted colour.
   - Plain-language copy: short sentences, no jargon in headings.
3. **Phone is the primary CTA.** Every major section ends in a way to call or WhatsApp. All contact details come from `src/data/site.ts`; never hard-code them.
4. **No horizontal overflow.** Layout breakpoints are 1080 / 880 / 640px. On phones the category switcher scrolls horizontally inside its own row (the grid track uses `minmax(0, 1fr)` so it cannot widen the page), and the hero tiles drop to 3 columns.
5. **No unverified claims.** Trust copy must match what the app states (verification, 45–60 min urgent arrival, 24/7 desk). Do not add patient counts or ratings without real data.
6. **Accessibility:** skip link, `aria-current` on the breadcrumb and active category, native `<dialog>` for modals, `<details>` for the FAQ, visible orange `:focus-visible` ring, and `prefers-reduced-motion` respected.

---

## 6. Running & Building

```bash
npm install
npm run dev       # Vite dev server
npm run build     # tsc -b && vite build → dist/
npm run preview   # serve the production build
npm run lint
```
