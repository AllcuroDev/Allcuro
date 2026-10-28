# ALLCURO Healthcare — Supabase Backend Integration Guide

This guide details how Supabase powers **Auth**, **PostgreSQL Database**, **Row-Level Security (RLS) Roles & Permissions**, and **Storage** for the entire ALLCURO ecosystem.

---

## 1. Quick Setup in Supabase Dashboard

1. Create a new project at [supabase.com](https://supabase.com).
2. Go to **SQL Editor** $\rightarrow$ Click **New Query** $\rightarrow$ Paste the entire contents of [`supabase/schema.sql`](file:///Users/abhishek/Desktop/allcuro_total/supabase/schema.sql) $\rightarrow$ Click **Run**.
3. Go to **Project Settings** $\rightarrow$ **API** to retrieve:
   - `Project URL`
   - `anon public key`
   - `service_role secret` (for backend/admin operations)
4. Run [`supabase/services.sql`](supabase/services.sql) the same way. It creates the public services catalog (`service_categories`, `services`) and seeds all 48 services across 7 categories. Anyone can read active rows without logging in; only admins can edit. Re-running it re-applies the seed.

---

## 2. User Roles & Permission Matrix

| Role | Permissions | Auth Claims / Metadata |
|---|---|---|
| **`customer`** | Can search verified nurses, centres & equipment; book shifts & stays; view own bookings & invoice history; manage emergency family SOS contact. | `raw_user_meta_data: { "role": "customer" }` |
| **`nurse`** | Can manage availability, view assigned patient shifts, GPS check-in/out, upload qualification/police clearances into private vault, and track payout ledger. | `raw_user_meta_data: { "role": "nurse" }` |
| **`centre`** | Can manage bed & room inventory, accept elder placement requests, upload CEA/Fire NOC certificates, and track Razorpay split payouts. | `raw_user_meta_data: { "role": "centre" }` |
| **`admin`** | Full access across all tables, KYC verification queue approval/rejection, live SOS alert dispatch, and compliance tracking. | `raw_user_meta_data: { "role": "admin" }` |

---

## 3. Storage Buckets

1. **`kyc-documents` (Private)**
   - Uploads for Aadhaar, Nursing Council Registrations, Fire Safety NOC, Biomedical Waste PCB certificates.
   - Access via time-limited Supabase signed URLs (`createSignedUrl`).
2. **`avatars` (Public)**
   - Profile photos for patients, nurses, and care centre managers.
3. **`centre-photos` (Public)**
   - 360 tour images, room photos, and amenities for care facilities.
4. **`equipment-images` (Public)**
   - Oxygen concentrators, hospital beds, wheelchairs, and ICU monitoring equipment catalog photos.

---

## 4. Environment Variables Setup

### In `allcuro_admin/.env`:
```env
SUPABASE_URL=https://<your-project-id>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

### In `allcuro_web/.env` (copy `.env.example`):
```env
SUPABASE_URL=https://<your-project-id>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```
The website loads services from Supabase, falling back to the bundled catalog if these are unset or the request fails.

### In `allcuro/` and `allcuro_partner/` (Flutter):
Both apps already depend on `supabase_flutter` and call `SupabaseConfig.init()` in `main()` (`lib/core/network/supabase_config.dart`). Keys are passed at build time, not stored in code:
```bash
cp supabase.example.json supabase.json   # fill in URL + anon key; supabase.json is git-ignored
flutter run --dart-define-from-file=supabase.json
```
Without the keys the apps run on their bundled demo data. The customer app loads the services catalog through `servicesCatalogProvider` (`lib/features/services/data/services_repository.dart`).

### Creating an admin
1. **Authentication → Users → Add user** (email + password).
2. In the SQL Editor (after `schema.sql` has been run):
   ```sql
   insert into public.profiles (id, role, full_name, email)
   select id, 'admin', 'Admin', email from auth.users where email = 'you@example.com'
   on conflict (id) do update set role = 'admin';
   ```
3. Sign in from the admin panel's **Services Catalog** section to add, edit, hide or upload images for services.

---

## 5. Icons, Images & Assets

Category and service logos have one home per platform. The database stores URLs, never images.

| Asset | Where it lives | Why |
|---|---|---|
| Category and service logos (3D artwork) | **Storage `service-images`** → `service_categories.image_url`, `services.image_url`. Uploaded and replaced from the admin's **Services Catalog**. | One copy for the website and admin; editable without a release. |
| The same artwork, for the customer app | **Bundled** in `allcuro/assets/images/{categories,services}/` | The app renders instantly and offline. Changes ship with an app release. |
| Small UI care icons (`icons/care/*.svg`) | **Bundled** in `allcuro/assets/` and `allcuro_web/src/assets/` | Fallback while a logo loads, plus other UI glyphs. |
| Logo, hero/marketing photos | **Bundled** in each project | Part of each site's design. |
| Nurse/patient photos | **Storage `avatars`** (public) → `profiles.avatar_url` | User-generated. |
| Centre photos, equipment photos | **Storage `centre-photos`, `equipment-images`** (public) | Uploaded by partners and admins. |
| KYC documents | **Storage `kyc-documents`** (private, signed URLs only) | Sensitive. Never public. |

**How each platform draws a logo**
- **Website and admin:** `image_url` from Supabase. Until it loads, or if it's empty, the website shows the tinted SVG care icon for the row's `icon` key.
- **Customer app:** its bundled artwork, found by the `icon` (services) or `art` (categories) key.

**Rules**
- **Changing a logo:** upload it in the admin (website updates on next load), and replace the matching file in `allcuro/assets/images` for the next app release.
- **Formats:** WebP (or PNG) at 256×256, kept under ~60 KB. The `service-images` bucket rejects files over 512 KB.
- **Storage names:** the admin saves uploads as `services/<service-id>-<timestamp>.<ext>`. A new name per upload means caches never serve a stale image. The first, shared upload of the app's artwork lives under `…/bundled/`, and the admin never deletes those files because several services can point at one.
- **Never** put images in the database as base64, and never make `kyc-documents` public.
