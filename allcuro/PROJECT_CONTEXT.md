# ALLCURO Customer App — Developer Context & Architecture

> **Directory:** `/allcuro`  
> **Target Audience:** Patients, families, and elderly caregivers in India.  
> **Stack:** Flutter 3, Riverpod 2.6, GoRouter 14.8, Google Fonts (Plus Jakarta Sans).

---

## 1. Feature Map & Routes

| Route | Screen Component | Purpose |
|---|---|---|
| `/splash` | `SplashScreen` | Animated brand entrance (heartbeat morph). |
| `/welcome` | `WelcomeScreen` | Value proposition & primary CTA. |
| `/auth/phone` | `PhoneAuthScreen` | 2-Step Phone Number + OTP verification (`123456` in demo mode). |
| `/onboarding` | `OnboardingScreen` | Light-touch KYC setup: Name, Email, City/Area, Emergency family contact. |
| `/` | `HomeScreen` | Discovery feed, urgent care (<2h) banner, verified centres carousel, available nurses, and promo codes. |
| `/nurses` | `NursesListScreen` | Filterable list of verified nurses (GNM, ANM, B.Sc, Critical Care). |
| `/nurses/:id`| `NurseDetailScreen` | Profile, background checks (Police, Medical fitness, Ref check), shift options, and review highlights. |
| `/centres` | `CentresListScreen` | Verified homecare centres and hospice listings with bed counts. |
| `/centres/:id`| `CentreDetailScreen`| Detailed centre overview with sub-scores, staff ratio, amenities, and room picker. |
| `/equipment` | `EquipmentScreen` | Medical equipment on rent/buy with deposit calculation and delivery slots. |
| `/medicines` | `MedicinesScreen` | Order Medicines: search + category chips + add to cart, or upload a prescription (`?upload=1` opens the picker). Sticky cart bar. |
| `/medicines/cart` | `MedicineCartScreen` | Cart, prescription (required for Rx items), delivery address, bill (free delivery from ₹499, else ₹39; GST-inclusive), login guard → payment sheet → order. |
| `/medicine-order/:id` | `MedicineOrderScreen` | Order confirmation & tracking: delivery OTP, 5-step status, items, address. |
| `/category-services/hospital-companion` | `CategoryServicesScreen` | Hospital Companion: non-clinical hospital-visit support (3 services). |
| `/bookings` | `BookingsScreen` | Active, upcoming, and past care appointments. | Includes medicine orders (`BookingType.medicine`).
| `/checkout` | `CheckoutScreen` | Transparent price breakdown, Razorpay steps, and address selection. |
| `/profile` | `ProfileScreen` | Member profile, Light KYC tier badge, emergency contacts, and Sign Out. |

---

## 2. Design System & Theme Tokens

- **Colors (`AppColors`):**
  - Primary: `#26593B` (Forest Green)
  - Primary Soft: `#DDF4E4` (Mint tint)
  - Primary Deep: `#0C341E`
  - Accent: `#3A8357`
  - Background: `#FEFDFC` (Warm off-white)
  - Card: `#FFFFFF`
  - Ink Primary: `#111512`
  - Border: `#E3E7E4`
  - Gradient: `#4A8F63` $\rightarrow$ `#2F6B48` $\rightarrow$ `#1B4A30`
- **Typography:**
  - Plus Jakarta Sans via `GoogleFonts.plusJakartaSansTextTheme()`.
  - Headings run `FontWeight.w800` / `w900` with tight letter-spacing.
- **Category Illustrations:**
  - The home category grid uses 3D claymorphic squircle icons from `assets/images/categories/*.png` via `CareIllustrations` + `CareIllustrationTile` in `lib/core/ui/care_icon.dart`.
  - Artworks have clean anti-aliased squircle edges with transparent background and soft natural 3D shadows so they blend seamlessly into any surface. The same assets are shared with the website (`allcuro_web/src/assets/images/categories/`).
  - Individual services keep the duotone line icons (`CareIcons` / `CareIconTile`).
- **Surface & Ripple Feedback:**
  - Always use `Surface(onTap: ...)` for cards and `Tappable(onTap: ...)` for icon links to ensure ripple feedback paints above dark gradients and solid cards.

---

## 3. Auth & State Management (`Riverpod`)

- **`authViewModelProvider`**: Holds `AuthState` (`unauthenticated`, `authenticated`, `onboarded`).
- **`phoneAuthViewModelProvider`**: Controls phone $\rightarrow$ OTP step animation and resend cooldown.
- **`onboardingViewModelProvider`**: Handles profile creation and saves to `SharedPreferences`.
- **Demo Verification Code:** `123456`.

---

## 3b. Order Medicines (`lib/features/medicines/`)

- **Catalog:** `data/medicine.dart` (`MedicineCatalog`, `MedicinePricing`). Mirrors `allcuro_web/src/data/medicines.ts` — keep ids, prices and Rx flags identical.
- **Cart:** `medicineCartProvider` (Riverpod `Notifier`, session-only). Rx items block checkout until a prescription is attached.
- **Prescription:** `pickPrescription()` uses `file_picker` (photo library or PDF/JPG/PNG, ≤ 10 MB; no camera/photo permissions needed). Demo mode simulates a 2.5 s pharmacist review that adds `MedicineCatalog.prescriptionDemoItems`; replace with the pharmacy partner's response once a backend exists.
- **Orders** are stored as `Booking(type: BookingType.medicine, items: [...], prescriptionName: ...)`.

## 4. Key Rules for Development

1. **Zero Overflow (real phones):** `app.dart` caps system text scale at 1.3×. Never size a box that holds text with a fixed height or a grid `childAspectRatio` — derive it from `MediaQuery.textScalerOf(context)` (see `_HomeGridItem.extent`) or use `minHeight`. Test new screens at 320dp wide with 1.3× text (`test/medicines_test.dart` shows the harness).
1b. **Zero Overflow (original rule):** Always ensure horizontal filter lists have adequate container height (`height: 40px` with horizontal-only padding) and avoid hardcoded fixed height on multi-line text cards.
2. **Light-Touch KYC:** Customers do not require full medical KYC up-front; basic mobile OTP + address unlocks short stays and visits, while higher-value equipment rentals prompt for Aadhaar verification at checkout.
3. **Emergency Care Priority:** Keep the 2-hour priority urgent banner prominent on the home screen.
