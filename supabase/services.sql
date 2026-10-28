-- ==============================================================================
-- ALLCURO — PUBLIC SERVICES CATALOG
-- Service categories + services, readable by anyone (no login) and editable by
-- admins only. Run after schema.sql (uses public.is_admin()). Safe to re-run:
-- the seed upserts by id.
-- ==============================================================================

do $$
begin
  if to_regprocedure('public.is_admin()') is null then
    raise exception 'Run supabase/schema.sql first: it creates public.profiles and public.is_admin().';
  end if;
end $$;

-- ------------------------------------------------------------------------------
-- 1. TABLES
-- ------------------------------------------------------------------------------
create table if not exists public.service_categories (
    id text primary key,                 -- 'Nursing Care', 'Elder Care', ...
    slug text not null unique,           -- URL segment: /services/:slug
    label text not null,
    blurb text not null default '',
    icon text not null default '',       -- care icon key shared by web + app
    art text not null default '',        -- illustration key
    ink text not null default '#26593B', -- deep glyph colour
    wash text not null default '#E7F4EB',-- soft tile background
    href text,                           -- page to open instead of a services list, e.g. '/centres'
    image_url text,                      -- optional Storage artwork; overrides `art`
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists public.services (
    id text primary key,                 -- slug, e.g. 'assisted-bathing'
    name text not null,
    category_id text not null references public.service_categories(id) on update cascade,
    extra_category_ids text[] not null default '{}', -- also listed under these, e.g. {Caregivers}
    subcategory text not null default '',
    description text not null default '',
    includes text not null default '',
    not_included text not null default '',
    duration text not null default '',
    professional text not null default '',
    price text not null,                 -- display price, e.g. '₹699–999', '₹999+'
    price_from numeric(10, 2),           -- lowest numeric price, for sorting/filters
    notes text not null default '',
    badge text not null default '',      -- 'Popular', 'Value', 'Advanced', 'High Skill'
    icon text not null default '',       -- bundled care icon key, e.g. 'bath'
    image_url text,                      -- optional Storage artwork; overrides `icon`
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Columns added after the first release of this file (no-ops on a fresh run).
alter table public.service_categories add column if not exists image_url text;
alter table public.services add column if not exists image_url text;
alter table public.service_categories add column if not exists href text;
alter table public.services add column if not exists extra_category_ids text[] not null default '{}';

create index if not exists services_category_idx on public.services (category_id, sort_order);

-- Keep updated_at current on edits from the admin panel.
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

drop trigger if exists service_categories_touch on public.service_categories;
create trigger service_categories_touch before update on public.service_categories
  for each row execute procedure public.touch_updated_at();

drop trigger if exists services_touch on public.services;
create trigger services_touch before update on public.services
  for each row execute procedure public.touch_updated_at();

-- ------------------------------------------------------------------------------
-- 2. ROW-LEVEL SECURITY — public read, admin write
-- ------------------------------------------------------------------------------
alter table public.service_categories enable row level security;
alter table public.services enable row level security;

drop policy if exists "Anyone can view active service categories" on public.service_categories;
create policy "Anyone can view active service categories"
  on public.service_categories for select
  to anon, authenticated
  using (is_active or is_admin());

drop policy if exists "Admins manage service categories" on public.service_categories;
create policy "Admins manage service categories"
  on public.service_categories for all
  to authenticated
  using (is_admin())
  with check (is_admin());

drop policy if exists "Anyone can view active services" on public.services;
create policy "Anyone can view active services"
  on public.services for select
  to anon, authenticated
  using (is_active or is_admin());

drop policy if exists "Admins manage services" on public.services;
create policy "Admins manage services"
  on public.services for all
  to authenticated
  using (is_admin())
  with check (is_admin());

grant select on public.service_categories, public.services to anon, authenticated;
grant insert, update, delete on public.service_categories, public.services to authenticated;

-- ------------------------------------------------------------------------------
-- 3. STORAGE — artwork for services/categories added after an app release.
-- Public URLs for everyone; only admins upload, replace or delete.
-- ------------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('service-images', 'service-images', true, 524288,
        array['image/png', 'image/webp', 'image/jpeg', 'image/svg+xml'])
on conflict (id) do nothing;

-- The bucket is public, so this only exposes what its URLs already do; the
-- Storage API needs it to list and delete (replace) files.
drop policy if exists "Anyone can view service images" on storage.objects;
create policy "Anyone can view service images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'service-images');

drop policy if exists "Admins upload service images" on storage.objects;
create policy "Admins upload service images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'service-images' and is_admin());

drop policy if exists "Admins update service images" on storage.objects;
create policy "Admins update service images"
  on storage.objects for update to authenticated
  using (bucket_id = 'service-images' and is_admin());

drop policy if exists "Admins delete service images" on storage.objects;
create policy "Admins delete service images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'service-images' and is_admin());

-- ------------------------------------------------------------------------------
-- 4. SEED — generated from allcuro_web/src/data/{categories,services}.ts, which
-- follow the customer app's home grid. Care Centres opens /centres (no services);
-- Caregivers lists services that also belong to Elder Care / Mother & Baby.
-- ------------------------------------------------------------------------------
insert into public.service_categories (id, slug, label, blurb, href, icon, art, ink, wash, sort_order) values
  ('Nursing Care', 'nursing', 'Nursing Services', 'Catheter, IV, injections, wound care & vital monitoring', null, 'nursing', 'nursing', '#26593B', '#E7F4EB', 1),
  ('Mother & Baby Care', 'mother-baby', 'Mother & Baby', 'Postnatal recovery, lactation guidance & newborn care', null, 'mother_baby', 'mother_baby', '#BE185D', '#FDEEF4', 2),
  ('Elder Care', 'elder-care', 'Elder Care', 'Assisted bathing, mobility, daily companionship & support', null, 'elder_care', 'elder_care', '#B45309', '#FEF3E2', 3),
  ('Physiotherapy', 'physiotherapy', 'Physiotherapy', 'Mobility rehab, stroke recovery & post-op therapy', null, 'physio', 'physio', '#1D4ED8', '#EAF0FE', 4),
  ('Doctor Care', 'doctor-care', 'Doctor Visit', 'Doctor & geriatric physician consultations at home', null, 'doctor', 'doctor', '#6D28D9', '#F2EDFE', 5),
  ('Care Centres', 'care-centres', 'Care Centres', 'Verified assisted living, hospice & recovery facilities', '/centres', 'care_centre', 'care_centre', '#0369A1', '#E6F3FB', 6),
  ('Caregivers', 'caregiver', 'Caregivers', 'Compassionate bedside care, feeding & daily mobility', null, 'caregiver', 'caregiver', '#C2410C', '#FFEFE6', 7)
on conflict (id) do update set
  slug = excluded.slug, label = excluded.label, blurb = excluded.blurb, href = excluded.href, icon = excluded.icon,
  art = excluded.art, ink = excluded.ink, wash = excluded.wash, sort_order = excluded.sort_order;

insert into public.services (id, name, category_id, extra_category_ids, subcategory, description, includes, not_included, duration, professional, price, price_from, notes, badge, icon, sort_order) values
  ('assisted-bathing', 'Assisted Bathing', 'Elder Care', array['Caregivers'], 'Personal Care', 'Safe, respectful help with bathing and getting ready.', 'Bath/shower help; drying; dressing; basic grooming.', 'Medical wound care or medication.', '30–45 min', 'Caregiver', '₹499', 499, 'Products extra', '', 'bath', 1),
  ('sponge-bath', 'Sponge Bath', 'Elder Care', array['Caregivers'], 'Personal Care', 'Gentle bed bath for an elder who cannot safely use the bathroom.', 'Body cleansing; drying; clothing change; skin observation.', 'Wound treatment.', '30–40 min', 'Caregiver', '₹449', 449, '', '', 'sponge_bath', 2),
  ('toileting-assistance', 'Toileting Assistance', 'Elder Care', array['Caregivers'], 'Personal Care', 'Support with safe toilet or commode use while maintaining dignity.', 'Transfer; toileting; cleaning; hygiene.', 'Catheter insertion.', '20–30 min', 'Caregiver', '₹299', 299, '', 'Value', 'toilet', 3),
  ('diaper-change-hygiene', 'Diaper Change & Hygiene', 'Elder Care', array['Caregivers'], 'Personal Care', 'Hygienic and dignified diaper changing support.', 'Change; hygiene; skin observation; disposal.', 'Pressure-injury treatment.', '15–20 min', 'Caregiver', '₹249', 249, 'Diaper extra', 'Value', 'diaper', 4),
  ('hair-wash-grooming', 'Hair Wash & Grooming', 'Elder Care', array['Caregivers'], 'Personal Care', 'Keeps your loved one clean, fresh and comfortable.', 'Hair wash; combing; basic grooming.', 'Salon procedures.', '30 min', 'Caregiver', '₹299', 299, 'Products extra', 'Value', 'grooming', 5),
  ('feeding-assistance', 'Feeding Assistance', 'Elder Care', array['Caregivers'], 'Personal Care', 'Support for elders who need help eating or drinking.', 'Positioning; feeding; hydration; post-meal comfort.', 'Tube feeding unless separately assigned.', '30–45 min', 'Caregiver', '₹349', 349, '', '', 'feeding', 6),
  ('mobility-assistance', 'Mobility Assistance', 'Elder Care', array['Caregivers'], 'Mobility', 'Safe support for moving around the home.', 'Bed-to-chair; walking; wheelchair support.', 'Physiotherapy treatment.', '30 min', 'Caregiver', '₹299', 299, '', 'Value', 'wheelchair', 7),
  ('companionship-visit', 'Companionship Visit', 'Elder Care', array['Caregivers'], 'Daily Support', 'A caring visit for conversation, engagement and routine support.', 'Conversation; reading; simple activity; safe indoor walk.', 'Clinical assessment.', '60 min', 'Caregiver', '₹399', 399, '', '', 'companionship', 8),
  ('medication-reminder', 'Medication Reminder', 'Elder Care', array['Caregivers'], 'Daily Support', 'Reminder support for the prescribed medication schedule.', 'Reminder; checklist; family update.', 'Dose changes or medication administration.', '20–30 min', 'Caregiver', '₹299', 299, '', 'Value', 'med_reminder', 9),
  ('vital-signs-check', 'Vital Signs Check', 'Elder Care', array['Caregivers'], 'Monitoring', 'A nurse checks and records key vital signs at home.', 'BP; pulse; temperature; SpO₂; documentation.', 'Diagnosis or prescription changes.', '20 min', 'Nurse', '₹399', 399, '', '', 'vitals', 10),
  ('bp-blood-sugar-check', 'BP + Blood Sugar Check', 'Elder Care', array['Caregivers'], 'Monitoring', 'Quick monitoring of blood pressure and capillary glucose.', 'BP; glucose; recording; escalation advice.', 'Diagnosis/treatment changes.', '20 min', 'Nurse', '₹399', 399, 'Strip/lancet extra', '', 'bp_sugar', 11),
  ('dementia-support-visit', 'Dementia Support Visit', 'Elder Care', array['Caregivers'], 'Specialised', 'Structured support for an elder living with memory or cognitive difficulties.', 'Routine support; orientation; safety observation; caregiver guidance.', 'Medical diagnosis or medication changes.', '45–60 min', 'Trained Caregiver/Nurse', '₹699', 699, '', '', 'memory', 12),
  ('bedridden-care-visit', 'Bedridden Care Visit', 'Elder Care', array['Caregivers'], 'Specialised', 'Support for elders who spend most of their time in bed.', 'Positioning; hygiene; feeding; skin observation; comfort.', 'Complex wound treatment.', '45–60 min', 'Caregiver/Nurse', '₹699+', 699, 'Case dependent', '', 'bed', 13),
  ('nurse-home-visit', 'Nurse Home Visit', 'Nursing Care', '{}', 'Nursing', 'A qualified nurse visits the home for basic clinical care.', 'Vitals; nursing assessment; prescribed care; documentation.', 'Doctor consultation.', '30–45 min', 'GNM/B.Sc Nurse', '₹699', 699, '', 'Popular', 'home_nurse', 14),
  ('injection-administration', 'Injection Administration', 'Nursing Care', '{}', 'Nursing', 'Prescribed IM/SC injection administered safely at home.', 'Prescription check; injection; observation; documentation.', 'Medicine cost.', '20–30 min', 'Nurse', '₹499', 499, 'Medicine/consumables extra', '', 'injection', 15),
  ('iv-medication-administration', 'IV Medication Administration', 'Nursing Care', '{}', 'Nursing', 'Prescribed IV medicine administered at home when appropriate.', 'IV assessment; administration; monitoring; documentation.', 'Medicine cost; emergency care.', '30–60 min', 'Trained Nurse', '₹999+', 999, 'Medicine/consumables extra', 'High Skill', 'iv_drip', 16),
  ('iv-infusion', 'IV Infusion', 'Nursing Care', '{}', 'Nursing', 'Prescribed IV fluids/infusion with monitoring.', 'IV setup; monitoring; documentation.', 'Fluid/medicine cost.', '1–2 hr', 'Trained Nurse', '₹999+', 999, 'Medicine/consumables extra', 'High Skill', 'iv_drip', 17),
  ('wound-dressing', 'Wound Dressing', 'Nursing Care', '{}', 'Nursing', 'Professional dressing care to support wound healing.', 'Assessment; prescribed cleaning; dressing; documentation.', 'Surgical debridement.', '30–60 min', 'Nurse', '₹699–999', 699, 'Materials extra', '', 'bandage', 18),
  ('pressure-injury-dressing', 'Pressure Injury Dressing', 'Nursing Care', '{}', 'Nursing', 'Specialised dressing support for pressure injuries.', 'Assessment; prescribed dressing; pressure-care advice.', 'Advanced debridement unless specifically offered.', '45–60 min', 'Nurse', '₹899–1,299', 899, 'Materials extra', 'Value', 'patch', 19),
  ('catheter-care', 'Catheter Care', 'Nursing Care', '{}', 'Nursing', 'Safe urinary catheter and drainage-bag care.', 'Hygiene; tubing/bag check; output observation; documentation.', 'Insertion unless booked separately.', '20–30 min', 'Nurse', '₹599', 599, 'Materials extra', 'High Skill', 'urine_bag', 20),
  ('foley-catheter-insertion', 'Foley Catheter Insertion', 'Nursing Care', '{}', 'Nursing', 'Urinary catheter insertion when prescribed and appropriate.', 'Sterile insertion; drainage setup; documentation.', 'Doctor assessment; catheter kit.', '30–45 min', 'Nurse', '₹999', 999, 'Kit extra', 'High Skill', 'catheter', 21),
  ('ryle-s-tube-care', 'Ryle''s Tube Care', 'Nursing Care', '{}', 'Nursing', 'Support for patients using a nasogastric feeding tube.', 'Tube/site check; prescribed care; feeding support if within scope.', 'Changing feeding plan.', '30 min', 'Nurse', '₹699', 699, 'Materials extra', '', 'nasal_tube', 22),
  ('ryle-s-tube-insertion', 'Ryle''s Tube Insertion', 'Nursing Care', '{}', 'Nursing', 'Nasogastric tube insertion when prescribed and appropriate.', 'Insertion; protocol-based placement verification; documentation.', 'Radiology confirmation where required.', '30–45 min', 'Trained Nurse', '₹1,199', 1199, 'Tube/materials extra', 'Advanced', 'nasal_tube', 23),
  ('suture-staple-removal', 'Suture/Staple Removal', 'Nursing Care', '{}', 'Nursing', 'Removal of surgical sutures or staples after medical advice.', 'Site check; removal; dressing if required.', 'Treatment of wound complications.', '20–30 min', 'Nurse', '₹599', 599, 'Materials extra', '', 'scissors', 24),
  ('nebulization', 'Nebulization', 'Nursing Care', '{}', 'Nursing', 'Prescribed nebulization delivered and monitored at home.', 'Setup; prescribed medicine; monitoring.', 'Prescription changes.', '20–30 min', 'Nurse', '₹399', 399, 'Medicine extra', '', 'nebulizer', 25),
  ('tracheostomy-care', 'Tracheostomy Care', 'Nursing Care', '{}', 'Advanced Nursing', 'Specialised nursing support for a tracheostomy patient.', 'Site care; secretion observation; prescribed suction support.', 'Emergency airway management.', '30–60 min', 'Trained Nurse', '₹999+', 999, 'Materials extra', 'Advanced', 'lungs', 26),
  ('suctioning', 'Suctioning', 'Nursing Care', '{}', 'Advanced Nursing', 'Nursing suction support when prescribed.', 'Assessment; prescribed suction; monitoring; documentation.', 'Emergency respiratory management.', '20–30 min', 'Trained Nurse', '₹799+', 799, 'Consumables extra', 'Advanced', 'airflow', 27),
  ('colostomy-care', 'Colostomy Care', 'Nursing Care', '{}', 'Advanced Nursing', 'Support with stoma and pouch care at home.', 'Pouch change; peristomal skin observation; hygiene.', 'Stoma complication treatment.', '30–45 min', 'Nurse', '₹899+', 899, 'Pouch/materials extra', 'Advanced', 'pouch', 28),
  ('physiotherapy-assessment', 'Physiotherapy Assessment', 'Physiotherapy', '{}', 'Physiotherapy', 'Assessment of mobility, strength, pain and function.', 'History; functional assessment; goals; home plan.', 'Medical diagnosis.', '45–60 min', 'Physiotherapist', '₹799', 799, '', 'Popular', 'clipboard', 29),
  ('general-physiotherapy', 'General Physiotherapy', 'Physiotherapy', '{}', 'Physiotherapy', 'Home-based rehabilitation for common conditions.', 'Assessment-linked exercises; mobility; education.', 'Medical diagnosis.', '45 min', 'Physiotherapist', '₹699', 699, '', '', 'dumbbell', 30),
  ('elder-mobility-therapy', 'Elder Mobility Therapy', 'Physiotherapy', '{}', 'Physiotherapy', 'Helps older adults improve safe movement and function.', 'Strength; balance; mobility; functional exercises.', 'Emergency rehabilitation.', '45 min', 'Physiotherapist', '₹699', 699, '', '', 'walker', 31),
  ('stroke-rehabilitation', 'Stroke Rehabilitation', 'Physiotherapy', '{}', 'Physiotherapy', 'Home rehabilitation focused on mobility and daily function.', 'Assessment; exercise; balance; functional training.', 'Acute stroke management.', '45–60 min', 'Physiotherapist', '₹899', 899, '', '', 'brain', 32),
  ('doctor-home-consultation', 'Doctor Home Consultation', 'Doctor Care', '{}', 'Doctor', 'A doctor assesses the patient at home and advises next steps.', 'History; examination; medical advice; prescription where appropriate.', 'Emergency services.', '30–45 min', 'Doctor', '₹1,299+', 1299, '', 'Value', 'doctor', 33),
  ('geriatric-home-consultation', 'Geriatric Home Consultation', 'Doctor Care', '{}', 'Doctor', 'Medical review focused on older-adult health needs.', 'Assessment; medication review; care planning.', 'Emergency care.', '45–60 min', 'Doctor', '₹1,499+', 1499, '', 'Advanced', 'med_kit', 34),
  ('antenatal-home-visit', 'Antenatal Home Visit', 'Mother & Baby Care', '{}', 'Pregnancy', 'A nurse supports routine pregnancy monitoring at home.', 'Vitals; symptom review; education; fetal assessment as appropriate.', 'Diagnostic tests/emergencies.', '45 min', 'Nurse', '₹699', 699, '', 'Popular', 'pregnancy', 35),
  ('pregnancy-bp-monitoring', 'Pregnancy BP Monitoring', 'Mother & Baby Care', '{}', 'Pregnancy', 'Convenient BP monitoring for pregnant women who need observation.', 'BP; warning-sign screening; documentation.', 'Diagnosis or medication changes.', '20–30 min', 'Nurse', '₹399', 399, '', '', 'vitals', 36),
  ('fetal-heart-rate-check', 'Fetal Heart Rate Check', 'Mother & Baby Care', '{}', 'Pregnancy', 'Home fetal heart-rate assessment when clinically appropriate.', 'FHR assessment; documentation; escalation if abnormal.', 'Formal CTG unless separately booked.', '20–30 min', 'Nurse', '₹499', 499, '', '', 'heartbeat', 37),
  ('postnatal-mother-care', 'Postnatal Mother Care', 'Mother & Baby Care', '{}', 'Postnatal', 'Professional support during recovery after delivery.', 'Vitals; recovery observation; hygiene education; warning signs.', 'Doctor treatment of complications.', '45 min', 'Nurse', '₹699', 699, '', '', 'caregiver', 38),
  ('c-section-recovery-visit', 'C-Section Recovery Visit', 'Mother & Baby Care', '{}', 'Postnatal', 'Nursing support during recovery after caesarean birth.', 'Wound observation; mobility; hygiene; warning signs.', 'Wound complications.', '45–60 min', 'Nurse', '₹799', 799, 'Materials extra', '', 'bandage', 39),
  ('breastfeeding-support', 'Breastfeeding Support', 'Mother & Baby Care', '{}', 'Postnatal', 'Practical help for comfortable breastfeeding.', 'Positioning; latch guidance; feeding education.', 'Treatment of severe breast complications.', '45–60 min', 'Lactation-trained Nurse', '₹799', 799, '', '', 'mother', 40),
  ('postnatal-hygiene-support', 'Postnatal Hygiene Support', 'Mother & Baby Care', array['Caregivers'], 'Postnatal', 'Gentle personal-care assistance while mother recovers.', 'Bath/hygiene; dressing support; comfort.', 'Clinical wound care.', '30–45 min', 'Caregiver/Nurse', '₹499', 499, '', '', 'clean', 41),
  ('newborn-home-assessment', 'Newborn Home Assessment', 'Mother & Baby Care', '{}', 'Newborn', 'A trained professional checks the baby''s basic care and health needs.', 'Temperature; feeding; breathing observation; weight if equipment available; parent education.', 'Diagnosis or emergency treatment.', '45 min', 'Nurse', '₹699', 699, '', 'Popular', 'baby', 42),
  ('baby-bath', 'Baby Bath', 'Mother & Baby Care', array['Caregivers'], 'Newborn', 'Gentle newborn bathing support at home.', 'Bath; drying; dressing; basic skin observation.', 'Treatment of skin disease.', '30–40 min', 'Trained Caregiver/Nurse', '₹399', 399, 'Products extra', '', 'baby_bath', 43),
  ('newborn-hygiene-care', 'Newborn Hygiene Care', 'Mother & Baby Care', array['Caregivers'], 'Newborn', 'Routine hygiene support to keep baby clean and comfortable.', 'Diaper change; cleaning; clothing change.', 'Medical treatment.', '20–30 min', 'Caregiver', '₹299', 299, 'Diapers/products extra', 'Value', 'diaper', 44),
  ('umbilical-cord-care-education', 'Umbilical Cord Care Education', 'Mother & Baby Care', '{}', 'Newborn', 'Parents learn safe cord-care practices and warning signs.', 'Demonstration; hygiene education; warning signs.', 'Treatment of infection.', '20 min', 'Nurse', '₹399', 399, '', '', 'onesie', 45),
  ('baby-feeding-support', 'Baby Feeding Support', 'Mother & Baby Care', array['Caregivers'], 'Newborn', 'Support with routine feeding, positioning and burping.', 'Feeding support; positioning; burping.', 'Clinical feeding disorders.', '30 min', 'Caregiver/Nurse', '₹349', 349, '', '', 'bottle', 46),
  ('baby-grooming', 'Baby Grooming', 'Mother & Baby Care', array['Caregivers'], 'Newborn', 'Gentle grooming for a clean and comfortable baby.', 'Face cleaning; hair care; diaper/clothing change.', 'Specialist procedures.', '20–30 min', 'Caregiver', '₹299', 299, 'Products extra', 'Value', 'brush', 47),
  ('mother-baby-2-hour-support', 'Mother & Baby 2-Hour Support', 'Mother & Baby Care', array['Caregivers'], 'Mother + Baby', 'Combined practical support for mother and baby.', 'Mother hygiene; baby hygiene; feeding assistance; routine support.', 'Clinical procedures unless separately booked.', '2 hr', 'Trained Caregiver', '₹699', 699, '', '', 'mother_baby', 48)
on conflict (id) do update set
  name = excluded.name, category_id = excluded.category_id, extra_category_ids = excluded.extra_category_ids,
  subcategory = excluded.subcategory, description = excluded.description, includes = excluded.includes,
  not_included = excluded.not_included, duration = excluded.duration, professional = excluded.professional,
  price = excluded.price, price_from = excluded.price_from, notes = excluded.notes, badge = excluded.badge,
  icon = excluded.icon, sort_order = excluded.sort_order;

-- Retired from the catalog (Oct 2026): Tests at Home and Diet & Wellness.
delete from public.services
where id in ('ecg-at-home', 'blood-sample-collection', 'dietitian-consultation', 'lactation-consultation');
update public.services
set extra_category_ids = array_remove(array_remove(extra_category_ids, 'Diagnostics'), 'Wellness')
where extra_category_ids && array['Diagnostics', 'Wellness'];
delete from public.service_categories where id in ('Diagnostics', 'Wellness');
