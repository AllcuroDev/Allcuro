-- ==============================================================================
-- ALLCURO HEALTHCARE MARKETPLACE — SUPABASE MASTER BACKEND SCHEMA
-- Includes Auth Triggers, Custom Roles, Tables, Storage Buckets & RLS Policies
-- ==============================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. ENUMS
-- ------------------------------------------------------------------------------
create type user_role as enum ('customer', 'nurse', 'centre', 'admin');
create type kyc_status as enum ('incomplete', 'under_review', 'site_visit_scheduled', 'verified', 'flagged');
create type booking_status as enum ('pending', 'confirmed', 'en_route', 'on_duty', 'sos_alert', 'completed', 'cancelled');
create type provider_type as enum ('nurse', 'centre', 'equipment');
create type payout_status as enum ('pending', 'processing', 'settled', 'failed');
create type alert_severity as enum ('info', 'warning', 'critical');

-- ------------------------------------------------------------------------------
-- 2. CORE PROFILES TABLE (Linked to auth.users)
-- ------------------------------------------------------------------------------
create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    role user_role not null default 'customer',
    full_name text not null,
    phone text unique,
    email text,
    avatar_url text,
    city text default 'Bengaluru',
    address text,
    emergency_contact text,
    kyc_status kyc_status default 'incomplete',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ------------------------------------------------------------------------------
-- 3. NURSES TABLE
-- ------------------------------------------------------------------------------
create table public.nurses (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null unique,
    qualification text not null, -- 'GNM', 'ANM', 'B.Sc Nursing', 'Critical Care'
    experience_years integer default 0,
    council_reg_no text,
    employment_type text default 'Full-time',
    previous_employer text,
    skills text[] default '{}',
    hourly_rate numeric(10, 2) default 250.00,
    daily_rate numeric(10, 2) default 2200.00,
    rating numeric(3, 2) default 5.00,
    total_shifts integer default 0,
    is_available boolean default true,
    risk_score text default 'Low',
    razorpay_route_account_id text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ------------------------------------------------------------------------------
-- 4. HOME CARE CENTRES TABLE
-- ------------------------------------------------------------------------------
create table public.home_care_centres (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null unique,
    name text not null,
    centre_type text not null, -- 'Elderly Care', 'Rehabilitation', 'Palliative Care'
    locality text not null,
    city text not null default 'Bengaluru',
    total_beds integer default 20,
    occupied_beds integer default 0,
    price_per_day numeric(10, 2) not null default 2500.00,
    staff_to_patient_ratio text default '1:4',
    clinical_establishment_reg text,
    fire_noc_expiry date,
    biomedical_waste_cleared boolean default true,
    field_audit_passed boolean default false,
    photos text[] default '{}',
    services_included text[] default '{}',
    room_types text[] default '{}',
    rating numeric(3, 2) default 4.90,
    razorpay_route_account_id text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ------------------------------------------------------------------------------
-- 5. MEDICAL EQUIPMENT CATALOG
-- ------------------------------------------------------------------------------
create table public.equipment (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    category text not null, -- 'Mobility', 'Respiratory', 'Hospital Beds', 'ICU Monitoring'
    condition text not null default 'Brand New', -- 'Brand New', 'Refurbished - Grade A'
    daily_rate numeric(10, 2) not null,
    monthly_rate numeric(10, 2) not null,
    deposit_amount numeric(10, 2) not null,
    stock_quantity integer default 10,
    photo_url text,
    specifications jsonb default '{}'::jsonb,
    is_available boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ------------------------------------------------------------------------------
-- 6. MULTI-SIDED BOOKINGS TABLE
-- ------------------------------------------------------------------------------
create table public.bookings (
    id uuid default uuid_generate_v4() primary key,
    booking_code text unique not null, -- e.g. 'BK-78901'
    customer_id uuid references public.profiles(id) not null,
    provider_type provider_type not null,
    nurse_id uuid references public.nurses(id),
    centre_id uuid references public.home_care_centres(id),
    equipment_id uuid references public.equipment(id),
    service_title text not null,
    patient_name text not null,
    patient_age integer,
    delivery_address text not null,
    start_date timestamp with time zone not null,
    end_date timestamp with time zone,
    status booking_status default 'pending' not null,
    total_amount numeric(10, 2) not null,
    platform_commission numeric(10, 2) not null,
    partner_payout numeric(10, 2) not null,
    security_deposit numeric(10, 2) default 0.00,
    emergency_contact text,
    gps_checkin_time timestamp with time zone,
    gps_checkout_time timestamp with time zone,
    razorpay_order_id text,
    razorpay_payment_id text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ------------------------------------------------------------------------------
-- 7. KYC DOCUMENTS TABLE
-- ------------------------------------------------------------------------------
create table public.kyc_documents (
    id uuid default uuid_generate_v4() primary key,
    profile_id uuid references public.profiles(id) on delete cascade not null,
    doc_type text not null, -- 'govt_id', 'nursing_council', 'fire_noc', 'cea_license', 'bio_waste'
    doc_name text not null,
    file_path text not null, -- Path inside Supabase Storage bucket 'kyc-documents'
    status kyc_status default 'under_review' not null,
    verification_notes text,
    verified_by uuid references public.profiles(id),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ------------------------------------------------------------------------------
-- 8. COMPLIANCE ALERTS TABLE
-- ------------------------------------------------------------------------------
create table public.compliance_alerts (
    id uuid default uuid_generate_v4() primary key,
    profile_id uuid references public.profiles(id) on delete cascade not null,
    item_title text not null,
    expiry_date date not null, -- days left: see compliance_alerts_with_days below
    severity alert_severity default 'warning' not null,
    auto_action text,
    is_resolved boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Days left until expiry, computed at read time (a stored generated column
-- can't use current_date). security_invoker keeps the table's RLS in force.
create view public.compliance_alerts_with_days
with (security_invoker = true) as
  select *, (expiry_date - current_date) as days_remaining
  from public.compliance_alerts;

-- ------------------------------------------------------------------------------
-- 9. RAZORPAY ROUTE SPLIT-PAYOUTS LEDGER
-- ------------------------------------------------------------------------------
create table public.payout_splits (
    id uuid default uuid_generate_v4() primary key,
    booking_id uuid references public.bookings(id) on delete cascade not null,
    gross_amount numeric(10, 2) not null,
    allcuro_commission numeric(10, 2) not null,
    partner_payout numeric(10, 2) not null,
    gateway_fee numeric(10, 2) default 0.00,
    razorpay_route_subaccount text not null,
    status payout_status default 'pending' not null,
    settled_at timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ------------------------------------------------------------------------------
-- 10. AUTH TRIGGER TO CREATE PROFILE AUTOMATICALLY
-- ------------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, role, full_name, phone, email, avatar_url)
  values (
    new.id,
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'customer'),
    coalesce(new.raw_user_meta_data->>'full_name', 'Member'),
    nullif(new.phone, ''),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Backfill profiles for users who signed up before this trigger existed.
insert into public.profiles (id, role, full_name, phone, email, avatar_url)
select
  u.id,
  coalesce((u.raw_user_meta_data->>'role')::user_role, 'customer'),
  coalesce(u.raw_user_meta_data->>'full_name', 'Member'),
  nullif(u.phone, ''),
  u.email,
  u.raw_user_meta_data->>'avatar_url'
from auth.users u
on conflict (id) do nothing;

-- ------------------------------------------------------------------------------
-- 11. ROW-LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.nurses enable row level security;
alter table public.home_care_centres enable row level security;
alter table public.equipment enable row level security;
alter table public.bookings enable row level security;
alter table public.kyc_documents enable row level security;
alter table public.compliance_alerts enable row level security;
alter table public.payout_splits enable row level security;

-- Helper function to check if user is admin
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer;

-- Profiles Policies
create policy "Users can view own profile or admin can view all"
  on public.profiles for select
  using (auth.uid() = id or is_admin());

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Public Discovery Policies
create policy "Public can view verified nurses"
  on public.nurses for select
  using (is_available = true or is_admin() or user_id = auth.uid());

create policy "Public can view verified centres"
  on public.home_care_centres for select
  using (true);

create policy "Public can view equipment catalog"
  on public.equipment for select
  using (true);

-- Bookings Policies
create policy "Users can view own bookings"
  on public.bookings for select
  using (customer_id = auth.uid() or is_admin() or nurse_id in (select id from public.nurses where user_id = auth.uid()));

create policy "Customers can create bookings"
  on public.bookings for insert
  with check (customer_id = auth.uid());

-- Admin Full Access
create policy "Admins have full access to KYC documents"
  on public.kyc_documents for all
  using (is_admin() or profile_id = auth.uid());

create policy "Admins have full access to compliance alerts"
  on public.compliance_alerts for all
  using (is_admin() or profile_id = auth.uid());

create policy "Admins have full access to payout splits"
  on public.payout_splits for all
  using (is_admin());

-- ------------------------------------------------------------------------------
-- 12. STORAGE BUCKETS CONFIGURATION
-- ------------------------------------------------------------------------------
insert into storage.buckets (id, name, public) values 
  ('kyc-documents', 'kyc-documents', false),
  ('avatars', 'avatars', true),
  ('centre-photos', 'centre-photos', true),
  ('equipment-images', 'equipment-images', true)
on conflict (id) do nothing;
