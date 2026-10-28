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
VITE_SUPABASE_URL=https://<your-project-id>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-key>
```

### In `allcuro_web/.env` (copy `.env.example`):
```env
VITE_SUPABASE_URL=https://<your-project-id>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-key>
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

Ship the visual language with the apps, and keep content in Supabase. The database stores keys and URLs, never images.

| Asset | Where it lives | Why |
|---|---|---|
| Care icons (`icons/care/*.svg`), category illustrations, 3D service artwork (`images/services/*.png`), logo, hero/marketing photos | **Bundled** in `allcuro/assets/` and `allcuro_web/src/assets/` | Instant, works offline, no network cost. Changes ship with a release. |
| Artwork for a service added *after* a release | **Storage `service-images`** (public, admin-upload only) → `services.image_url` | New services appear without an app update. |
| Nurse/patient photos | **Storage `avatars`** (public) → `profiles.avatar_url` | User-generated. |
| Centre photos, equipment photos | **Storage `centre-photos`, `equipment-images`** (public) | Uploaded by partners and admins. |
| KYC documents | **Storage `kyc-documents`** (private, signed URLs only) | Sensitive. Never public. |

**How a service picks its image** (same order on web and app):
1. `image_url` set → load it from Storage. *(Loaded into `Service.imageUrl` / `MasterServiceItem.imageUrl`; the icon tiles don't draw it yet.)*
2. Otherwise `icon` (e.g. `bath`) → bundled `images/services/bath.png`, then `icons/care/bath.svg`.
3. Otherwise → the generic nursing glyph.

**Rules**
- **The icon key is the contract.** A file named `bath.png` / `bath.svg` must exist in both `allcuro/assets` and `allcuro_web/src/assets` for every `icon` value used in the database. Add new artwork to both folders in the same commit.
- **Formats:** SVG for flat icons; WebP (or PNG) for 3D artwork, exported at 256×256 and kept under ~60 KB. The current 3D PNGs are ~130 KB each, so converting them to WebP roughly halves the app size they add.
- **Storage uploads:** use lowercase-kebab names (`services/<service-id>-<timestamp>.webp`). The `service-images` bucket only accepts images under 512 KB. A new file name per upload means caches never serve a stale image.
- **Never** put images in the database as base64, and never make `kyc-documents` public.
