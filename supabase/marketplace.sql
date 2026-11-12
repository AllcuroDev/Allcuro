-- ==============================================================================
-- ALLCURO — MARKETPLACE: partners, approval, admin pricing, and editable content
--
-- Run after schema.sql and services.sql. Safe to re-run.
--
--   partners            One profile per partner account and role (nurse,
--                       doctor/physio, centre…). Written by the partner from the
--                       partner portal/app; only an admin can approve it.
--   partner_offerings   What a partner offers (catalog services or shift/room
--                       rates). Partners pick services; ONLY admins set price
--                       and discount.
--   partners_public,    What customers see: approved partners only, without
--   partner_offerings_public  private fields (bank, Aadhaar, documents).
--   equipment           Rental catalog (extends the table from schema.sql).
--   medicines           Order Medicines catalog.
--   faqs, site_settings Website/app copy and contact details.
--
-- Prices and discounts on services, equipment, medicines and partners are
-- admin-only: triggers below reset them if anyone else tries to change them.
-- ==============================================================================

do $$
begin
  if to_regprocedure('public.is_admin()') is null or to_regclass('public.services') is null then
    raise exception 'Run supabase/schema.sql and supabase/services.sql first.';
  end if;
end $$;

-- ------------------------------------------------------------------------------
-- 0. Phone sign-in: keep profiles.phone in "+91…" form and let a user insert
--    their own profile row if the auth trigger missed it.
-- ------------------------------------------------------------------------------
drop policy if exists "Users can create own profile" on public.profiles;
create policy "Users can create own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id and role = 'customer');

-- SECURITY: schema.sql's sign-up trigger trusted `role` from the sign-up
-- metadata, which any client can set — so anyone could sign up as 'admin'.
-- New accounts are customers (or nurse/centre if they ask); admins are only
-- ever made by hand in the SQL editor (see SUPABASE_BACKEND_GUIDE.md).
create or replace function public.handle_new_user()
returns trigger as $$
declare
  requested text := new.raw_user_meta_data->>'role';
begin
  insert into public.profiles (id, role, full_name, phone, email, avatar_url)
  values (
    new.id,
    case when requested in ('nurse', 'centre') then requested::user_role else 'customer'::user_role end,
    coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), 'Member'),
    nullif(new.phone, ''),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- A user may edit their profile but never their own role or KYC status.
create or replace function public.profiles_guard()
returns trigger as $$
begin
  if not public.is_admin() then
    new.role := old.role;
    new.kyc_status := old.kyc_status;
  end if;
  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists profiles_guard on public.profiles;
create trigger profiles_guard before update on public.profiles
  for each row execute procedure public.profiles_guard();

drop policy if exists "Admins can update any profile" on public.profiles;
create policy "Admins can update any profile"
  on public.profiles for update
  to authenticated
  using (is_admin());

-- ------------------------------------------------------------------------------
-- 1. PARTNERS
-- ------------------------------------------------------------------------------
-- status lifecycle:
--   incomplete → onboarding → under_review → (site_visit_scheduled) → approved
--                                         ↘ rejected (partner fixes & resubmits)
--   approved → suspended (admin)
-- Partners can only move themselves up to under_review. Everything after that
-- is the admin's call.
create table if not exists public.partners (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    role text not null check (role in ('nurse', 'clinician', 'centre')),
    -- What customers browse by: 'nurse', 'doctor', 'physiotherapist',
    -- 'caregiver', 'centre'.
    kind text not null default 'nurse'
      check (kind in ('nurse', 'doctor', 'physiotherapist', 'caregiver', 'centre')),
    slug text unique,                       -- URL segment, e.g. 'priya-sharma-3f2a'
    status text not null default 'incomplete'
      check (status in ('incomplete', 'onboarding', 'under_review', 'site_visit_scheduled',
                        'approved', 'rejected', 'suspended')),

    -- Public profile ------------------------------------------------------------
    display_name text not null default '',
    photo_url text,
    headline text not null default '',      -- e.g. 'B.Sc Nursing', 'Rehab & recovery'
    bio text not null default '',
    city text not null default '',
    locality text not null default '',
    languages text[] not null default '{}',
    skills text[] not null default '{}',    -- tags shown on cards and used for filters
    highlights text[] not null default '{}',
    qualification text not null default '',
    specialisations text[] not null default '{}',
    experience_years integer not null default 0,
    employment_type text not null default 'Full-time',
    is_available boolean not null default true,

    -- Centre-only public fields --------------------------------------------------
    centre_type text not null default '',
    year_established integer,
    staff_ratio text not null default '',
    total_beds integer not null default 0,
    beds_available integer not null default 0,
    services_included text[] not null default '{}',
    room_types text[] not null default '{}',
    photos text[] not null default '{}',
    food_menu text not null default '',
    licence_no text not null default '',
    public_phone text not null default '',

    -- Admin-only: price, discount, ratings, review notes -------------------------
    price_per_day numeric(10, 2),          -- centres: admin-set daily package
    price_per_month numeric(10, 2),
    discount_percent numeric(5, 2) not null default 0 check (discount_percent between 0 and 100),
    rating numeric(3, 2),
    review_count integer not null default 0,
    allcuro_code text unique,              -- 'AC-N-10428', issued on approval
    admin_note text not null default '',   -- shown to the partner when rejected
    site_visit_at timestamp with time zone,
    reviewed_by uuid references public.profiles(id),
    reviewed_at timestamp with time zone,

    -- Private: owner + admin only (never in partners_public) ---------------------
    phone text not null default '',
    email text not null default '',
    address text not null default '',
    registration_number text not null default '',
    council text not null default '',
    previous_employer text not null default '',
    identity jsonb not null default '{}'::jsonb, -- dob, gender, aadhaar last 4…
    bank jsonb,                                  -- holder, account, ifsc, upi…
    details jsonb not null default '{}'::jsonb,  -- other wizard answers

    submitted_at timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique (user_id, role)
);

create index if not exists partners_status_idx on public.partners (status, kind);

-- Guard: what a partner may change on their own row.
create or replace function public.partners_guard()
returns trigger as $$
declare
  prefix text;
begin
  -- Slug for the public URL, set once.
  if new.slug is null or new.slug = '' then
    new.slug := trim(both '-' from regexp_replace(lower(coalesce(nullif(new.display_name, ''), new.kind)), '[^a-z0-9]+', '-', 'g'))
                || '-' || substr(replace(new.id::text, '-', ''), 1, 4);
  end if;
  new.updated_at := timezone('utc'::text, now());

  if public.is_admin() then
    if tg_op = 'UPDATE' and new.status is distinct from old.status then
      new.reviewed_by := auth.uid();
      new.reviewed_at := timezone('utc'::text, now());
    end if;
  else
    if tg_op = 'INSERT' then
      new.user_id := auth.uid();
      if new.status not in ('incomplete', 'onboarding', 'under_review') then
        new.status := 'incomplete';
      end if;
      new.price_per_day := null;
      new.price_per_month := null;
      new.discount_percent := 0;
      new.rating := null;
      new.review_count := 0;
      new.allcuro_code := null;
      new.admin_note := '';
      new.site_visit_at := null;
      new.reviewed_by := null;
      new.reviewed_at := null;
    else
      new.user_id := old.user_id;
      new.role := old.role;
      new.price_per_day := old.price_per_day;
      new.price_per_month := old.price_per_month;
      new.discount_percent := old.discount_percent;
      new.rating := old.rating;
      new.review_count := old.review_count;
      new.allcuro_code := old.allcuro_code;
      new.admin_note := old.admin_note;
      new.site_visit_at := old.site_visit_at;
      new.reviewed_by := old.reviewed_by;
      new.reviewed_at := old.reviewed_at;
      -- Partners may only move forward through sign-up, or resubmit after a
      -- rejection. Approval, site visits and suspension are the admin's.
      if new.status is distinct from old.status then
        if not (
          (old.status in ('incomplete', 'onboarding') and new.status in ('incomplete', 'onboarding', 'under_review'))
          or (old.status = 'rejected' and new.status in ('onboarding', 'under_review'))
        ) then
          new.status := old.status;
        end if;
      end if;
    end if;
  end if;

  if new.status = 'under_review' and (tg_op = 'INSERT' or old.status is distinct from 'under_review') then
    new.submitted_at := timezone('utc'::text, now());
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists partners_guard on public.partners;
create trigger partners_guard before insert or update on public.partners
  for each row execute procedure public.partners_guard();

-- Issue a partner code ('AC-N-10001') the first time an admin approves.
create sequence if not exists public.partner_code_seq start 10001;

create or replace function public.partners_issue_code()
returns trigger as $$
begin
  if new.status = 'approved' and new.allcuro_code is null then
    new.allcuro_code := 'AC-' ||
      case new.kind when 'nurse' then 'N' when 'doctor' then 'DR' when 'physiotherapist' then 'PT'
                    when 'caregiver' then 'CG' else 'C' end
      || '-' || nextval('public.partner_code_seq');
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists partners_issue_code on public.partners;
create trigger partners_issue_code before insert or update of status on public.partners
  for each row execute procedure public.partners_issue_code();

alter table public.partners enable row level security;

drop policy if exists "Partners read own rows, admins read all" on public.partners;
create policy "Partners read own rows, admins read all"
  on public.partners for select
  to authenticated
  using (user_id = auth.uid() or is_admin());

drop policy if exists "Partners create own row" on public.partners;
create policy "Partners create own row"
  on public.partners for insert
  to authenticated
  with check (user_id = auth.uid() or is_admin());

drop policy if exists "Partners update own row, admins any" on public.partners;
create policy "Partners update own row, admins any"
  on public.partners for update
  to authenticated
  using (user_id = auth.uid() or is_admin());

drop policy if exists "Admins delete partners" on public.partners;
create policy "Admins delete partners"
  on public.partners for delete
  to authenticated
  using (is_admin());

grant select, insert, update on public.partners to authenticated;
grant delete on public.partners to authenticated;

-- ------------------------------------------------------------------------------
-- 2. PARTNER OFFERINGS — services and rates. Partner picks; admin prices.
-- ------------------------------------------------------------------------------
create table if not exists public.partner_offerings (
    id uuid primary key default gen_random_uuid(),
    partner_id uuid not null references public.partners(id) on delete cascade,
    service_id text references public.services(id) on delete cascade, -- null for a custom rate
    label text not null default '',            -- 'Day Shift (12 hrs)'; defaults to the service name
    unit text not null default 'per visit',    -- 'per visit', 'per shift', 'per day', 'per month'
    price numeric(10, 2),                      -- admin-only. null → the service's catalog price
    discount_percent numeric(5, 2),            -- admin-only. null → the service's discount
    is_active boolean not null default true,
    sort_order integer not null default 0,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    check (service_id is not null or label <> '')
);

create unique index if not exists partner_offerings_service_uniq
  on public.partner_offerings (partner_id, service_id) where service_id is not null;

create or replace function public.partner_offerings_guard()
returns trigger as $$
begin
  new.updated_at := timezone('utc'::text, now());
  if not public.is_admin() then
    if tg_op = 'INSERT' then
      new.price := null;
      new.discount_percent := null;
    else
      new.partner_id := old.partner_id;
      new.price := old.price;
      new.discount_percent := old.discount_percent;
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists partner_offerings_guard on public.partner_offerings;
create trigger partner_offerings_guard before insert or update on public.partner_offerings
  for each row execute procedure public.partner_offerings_guard();

alter table public.partner_offerings enable row level security;

drop policy if exists "Partner reads own offerings, admin all" on public.partner_offerings;
create policy "Partner reads own offerings, admin all"
  on public.partner_offerings for select
  to authenticated
  using (is_admin() or partner_id in (select id from public.partners where user_id = auth.uid()));

drop policy if exists "Partner manages own offerings, admin all" on public.partner_offerings;
create policy "Partner manages own offerings, admin all"
  on public.partner_offerings for all
  to authenticated
  using (is_admin() or partner_id in (select id from public.partners where user_id = auth.uid()))
  with check (is_admin() or partner_id in (select id from public.partners where user_id = auth.uid()));

grant select, insert, update, delete on public.partner_offerings to authenticated;

-- ------------------------------------------------------------------------------
-- 3. SERVICE DISCOUNTS (admin-only, like the price itself)
-- ------------------------------------------------------------------------------
alter table public.services add column if not exists discount_percent numeric(5, 2) not null default 0;

-- ------------------------------------------------------------------------------
-- 4. PUBLIC VIEWS — what customers (anon) can read. Approved partners only.
--    These run as the view owner, so they bypass partners' RLS on purpose and
--    expose only the columns listed here.
-- ------------------------------------------------------------------------------
drop view if exists public.partner_offerings_public;
drop view if exists public.partners_public;

create view public.partners_public as
  select
    p.id, p.slug, p.kind, p.role, p.allcuro_code,
    p.display_name, p.photo_url, p.headline, p.bio, p.city, p.locality,
    p.languages, p.skills, p.highlights, p.qualification, p.specialisations,
    p.experience_years, p.employment_type, p.is_available,
    p.centre_type, p.year_established, p.staff_ratio, p.total_beds, p.beds_available,
    p.services_included, p.room_types, p.photos, p.food_menu, p.licence_no, p.public_phone,
    p.price_per_day, p.price_per_month, p.discount_percent,
    p.rating, p.review_count, p.reviewed_at as approved_at
  from public.partners p
  where p.status = 'approved';

create view public.partner_offerings_public as
  select
    o.id, o.partner_id, o.service_id,
    coalesce(nullif(o.label, ''), s.name) as label,
    o.unit,
    coalesce(o.price, s.price_from) as price,
    coalesce(o.discount_percent, s.discount_percent, 0) as discount_percent,
    round(coalesce(o.price, s.price_from) * (1 - coalesce(o.discount_percent, s.discount_percent, 0) / 100)) as final_price,
    o.sort_order
  from public.partner_offerings o
  join public.partners p on p.id = o.partner_id and p.status = 'approved'
  left join public.services s on s.id = o.service_id
  where o.is_active and (s.id is null or s.is_active)
    and coalesce(o.price, s.price_from) is not null;

grant select on public.partners_public, public.partner_offerings_public to anon, authenticated;

-- ------------------------------------------------------------------------------
-- 5. EQUIPMENT — extend schema.sql's table so the admin can edit everything.
-- ------------------------------------------------------------------------------
alter table public.equipment add column if not exists slug text;
alter table public.equipment add column if not exists description text not null default '';
alter table public.equipment add column if not exists features text[] not null default '{}';
alter table public.equipment add column if not exists discount_percent numeric(5, 2) not null default 0;
alter table public.equipment add column if not exists available_pincodes text not null default '';
alter table public.equipment add column if not exists sort_order integer not null default 0;
alter table public.equipment add column if not exists is_active boolean not null default true;
alter table public.equipment add column if not exists updated_at timestamp with time zone default timezone('utc'::text, now());
create unique index if not exists equipment_slug_uniq on public.equipment (slug);

drop trigger if exists equipment_touch on public.equipment;
create trigger equipment_touch before update on public.equipment
  for each row execute procedure public.touch_updated_at();

drop policy if exists "Public can view equipment catalog" on public.equipment;
drop policy if exists "Anyone can view active equipment" on public.equipment;
create policy "Anyone can view active equipment"
  on public.equipment for select
  to anon, authenticated
  using (is_active or is_admin());

drop policy if exists "Admins manage equipment" on public.equipment;
create policy "Admins manage equipment"
  on public.equipment for all
  to authenticated
  using (is_admin())
  with check (is_admin());

grant select on public.equipment to anon, authenticated;
grant insert, update, delete on public.equipment to authenticated;

insert into public.equipment
  (slug, title, category, condition, daily_rate, monthly_rate, deposit_amount, stock_quantity, description, available_pincodes, sort_order)
select * from (values
  ('wheelchair', 'Foldable wheelchair', 'Mobility', 'Refurbished · Grade A', 120, 1800, 2000, 10,
   'Lightweight foldable wheelchair with brakes and removable footrests. Sanitised before every delivery.', '560076', 1),
  ('oxygen', 'Oxygen concentrator 5L', 'Respiratory', 'New', 450, 8500, 10000, 6,
   '5 L/min oxygen concentrator with purity indicator. Setup and a usage demo included on delivery.', '560076', 2),
  ('bed', 'Electric hospital bed', 'Hospital furniture', 'Refurbished · Grade A', 380, 6900, 8000, 4,
   'Three-function electric bed with side rails and mattress. Installed by our technician.', '560076', 3)
) as v(slug, title, category, condition, daily_rate, monthly_rate, deposit_amount, stock_quantity, description, available_pincodes, sort_order)
where not exists (select 1 from public.equipment e where e.slug = v.slug);

-- Older rows created before slugs existed.
update public.equipment
set slug = trim(both '-' from regexp_replace(lower(title), '[^a-z0-9]+', '-', 'g')) || '-' || substr(replace(id::text, '-', ''), 1, 4)
where slug is null;

-- ------------------------------------------------------------------------------
-- 6. MEDICINES
-- ------------------------------------------------------------------------------
create table if not exists public.medicines (
    id text primary key,                   -- slug, e.g. 'paracetamol-650'
    name text not null,
    pack text not null default '',
    category text not null default '',
    mrp numeric(10, 2) not null,
    price numeric(10, 2) not null,         -- selling price after discount
    rx boolean not null default false,     -- prescription required
    image_url text,
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    check (price <= mrp)
);

drop trigger if exists medicines_touch on public.medicines;
create trigger medicines_touch before update on public.medicines
  for each row execute procedure public.touch_updated_at();

alter table public.medicines enable row level security;
drop policy if exists "Anyone can view active medicines" on public.medicines;
create policy "Anyone can view active medicines"
  on public.medicines for select to anon, authenticated using (is_active or is_admin());
drop policy if exists "Admins manage medicines" on public.medicines;
create policy "Admins manage medicines"
  on public.medicines for all to authenticated using (is_admin()) with check (is_admin());
grant select on public.medicines to anon, authenticated;
grant insert, update, delete on public.medicines to authenticated;

insert into public.medicines (id, name, pack, mrp, price, rx, category, sort_order) values
  ('paracetamol-650', 'Paracetamol 650 mg Tablet', 'Strip of 15 tablets', 34, 30, false, 'Fever & Pain', 1),
  ('ibuprofen-400', 'Ibuprofen 400 mg Tablet', 'Strip of 15 tablets', 42, 36, false, 'Fever & Pain', 2),
  ('cetirizine-10', 'Cetirizine 10 mg Tablet', 'Strip of 10 tablets', 22, 19, false, 'Cold & Allergy', 3),
  ('cough-syrup', 'Ambroxol Cough Syrup', 'Bottle of 100 ml', 115, 98, false, 'Cold & Allergy', 4),
  ('ors-orange', 'ORS Electrolyte Powder (Orange)', 'Pack of 5 sachets', 110, 99, false, 'Stomach Care', 5),
  ('antacid-gel', 'Antacid Gel (Mint)', 'Bottle of 170 ml', 129, 110, false, 'Stomach Care', 6),
  ('pantoprazole-40', 'Pantoprazole 40 mg Tablet', 'Strip of 15 tablets', 155, 132, true, 'Stomach Care', 7),
  ('metformin-500', 'Metformin 500 mg SR Tablet', 'Strip of 20 tablets', 48, 41, true, 'Diabetes & Thyroid', 8),
  ('glimepiride-1', 'Glimepiride 1 mg Tablet', 'Strip of 10 tablets', 92, 78, true, 'Diabetes & Thyroid', 9),
  ('thyroxine-50', 'Thyroxine 50 mcg Tablet', 'Bottle of 100 tablets', 180, 153, true, 'Diabetes & Thyroid', 10),
  ('amlodipine-5', 'Amlodipine 5 mg Tablet', 'Strip of 15 tablets', 64, 55, true, 'BP & Heart', 11),
  ('telmisartan-40', 'Telmisartan 40 mg Tablet', 'Strip of 15 tablets', 118, 99, true, 'BP & Heart', 12),
  ('atorvastatin-10', 'Atorvastatin 10 mg Tablet', 'Strip of 15 tablets', 140, 119, true, 'BP & Heart', 13),
  ('amoxicillin-500', 'Amoxicillin 500 mg Capsule', 'Strip of 10 capsules', 98, 84, true, 'Antibiotics', 14),
  ('azithromycin-500', 'Azithromycin 500 mg Tablet', 'Strip of 3 tablets', 119, 101, true, 'Antibiotics', 15),
  ('vitamin-d3', 'Vitamin D3 60,000 IU Capsule', 'Strip of 4 capsules', 136, 115, false, 'Vitamins', 16),
  ('calcium-d3', 'Calcium + Vitamin D3 Tablet', 'Strip of 15 tablets', 125, 106, false, 'Vitamins', 17),
  ('multivitamin', 'Multivitamin Tablet', 'Bottle of 30 tablets', 320, 272, false, 'Vitamins', 18)
on conflict (id) do nothing;

-- ------------------------------------------------------------------------------
-- 7. FAQS + SITE SETTINGS
-- ------------------------------------------------------------------------------
create table if not exists public.faqs (
    id uuid primary key default gen_random_uuid(),
    question text not null,
    answer text not null,
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.faqs enable row level security;
drop policy if exists "Anyone can view active faqs" on public.faqs;
create policy "Anyone can view active faqs"
  on public.faqs for select to anon, authenticated using (is_active or is_admin());
drop policy if exists "Admins manage faqs" on public.faqs;
create policy "Admins manage faqs"
  on public.faqs for all to authenticated using (is_admin()) with check (is_admin());
grant select on public.faqs to anon, authenticated;
grant insert, update, delete on public.faqs to authenticated;

insert into public.faqs (question, answer, sort_order)
select * from (values
  ('Can I book a nurse for just 30 minutes?', 'Yes. For procedures like injections, wound dressing or catheter care, you can book a 30 or 45-minute visit without paying for a full shift.', 1),
  ('How quickly can someone reach my home?', 'Our verified clinicians are spread across the city. For urgent needs, an available clinician can usually reach your door within 45 to 60 minutes.', 2),
  ('Are caregivers different from registered nurses?', 'Yes. Registered nurses hold B.Sc or GNM qualifications and handle clinical care such as injections and post-operative care. Caregivers help with daily living — bathing, feeding, moving around and companionship.', 3),
  ('Are the prices final?', 'The price shown is the starting visit charge. Medicines, dressing materials and lab charges are extra where mentioned, and you see the full breakdown before you pay.', 4),
  ('Can I reschedule or ask for a different person?', 'Yes. You can reschedule or request a replacement through our 24/7 care desk with no penalty.', 5)
) as v(question, answer, sort_order)
where not exists (select 1 from public.faqs);

create table if not exists public.site_settings (
    key text primary key,                  -- 'contact', 'home'
    value jsonb not null default '{}'::jsonb,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

drop trigger if exists site_settings_touch on public.site_settings;
create trigger site_settings_touch before update on public.site_settings
  for each row execute procedure public.touch_updated_at();

alter table public.site_settings enable row level security;
drop policy if exists "Anyone can view site settings" on public.site_settings;
create policy "Anyone can view site settings"
  on public.site_settings for select to anon, authenticated using (true);
drop policy if exists "Admins manage site settings" on public.site_settings;
create policy "Admins manage site settings"
  on public.site_settings for all to authenticated using (is_admin()) with check (is_admin());
grant select on public.site_settings to anon, authenticated;
grant insert, update, delete on public.site_settings to authenticated;

insert into public.site_settings (key, value) values
  ('contact', '{"phoneDisplay": "+91 80 4120 5500", "phone": "+918041205500", "whatsapp": "918041205500", "email": "care@allcuro.care"}'),
  ('home', '{"headline": "Healthcare", "highlight": "at your doorstep", "tilesTitle": "What are you looking for?"}')
on conflict (key) do nothing;

-- ------------------------------------------------------------------------------
-- 8. STORAGE — partner photos, equipment and medicine images
-- ------------------------------------------------------------------------------
insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('centre-photos', 'centre-photos', true),
  ('equipment-images', 'equipment-images', true),
  ('kyc-documents', 'kyc-documents', false)
on conflict (id) do nothing;

-- Users upload into a folder named after their user id: avatars/<uid>/photo.jpg
drop policy if exists "Users upload own avatars" on storage.objects;
create policy "Users upload own avatars"
  on storage.objects for insert to authenticated
  with check (bucket_id in ('avatars', 'centre-photos') and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users replace own avatars" on storage.objects;
create policy "Users replace own avatars"
  on storage.objects for update to authenticated
  using (bucket_id in ('avatars', 'centre-photos') and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users delete own avatars" on storage.objects;
create policy "Users delete own avatars"
  on storage.objects for delete to authenticated
  using (bucket_id in ('avatars', 'centre-photos') and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users manage own KYC files" on storage.objects;
create policy "Users manage own KYC files"
  on storage.objects for all to authenticated
  using (bucket_id = 'kyc-documents' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()))
  with check (bucket_id = 'kyc-documents' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

drop policy if exists "Admins manage catalog images" on storage.objects;
create policy "Admins manage catalog images"
  on storage.objects for all to authenticated
  using (bucket_id in ('equipment-images', 'avatars', 'centre-photos') and public.is_admin())
  with check (bucket_id in ('equipment-images', 'avatars', 'centre-photos') and public.is_admin());
