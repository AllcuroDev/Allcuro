-- ==============================================================================
-- ALLCURO — COUPONS & DISCOUNTS
--
-- Run after schema.sql, services.sql and marketplace.sql. Safe to re-run.
--
--   coupons             Created by admins in the admin panel. Two kinds:
--                         'coupon'    the customer types the code at checkout;
--                         'discount'  no code — applied automatically at
--                                     checkout (the best one wins).
--   coupon_redemptions  One row per use, so total and per-customer limits hold.
--
-- Customers never read the tables directly (codes can't be listed). Checkout
-- calls the functions below, which only work for a signed-in user:
--   validate_coupon(code, amount, applies_to)   -> discount preview
--   best_auto_discount(amount, applies_to)      -> best automatic discount
--   redeem_coupon(code, amount, applies_to, booking_ref)   at payment
-- `code` is null in redeem_coupon for an automatic discount (pass its id via
-- p_coupon_id instead).
-- ==============================================================================

do $$
begin
  if to_regprocedure('public.is_admin()') is null then
    raise exception 'Run supabase/schema.sql first.';
  end if;
end $$;

create table if not exists public.coupons (
    id uuid primary key default gen_random_uuid(),
    kind text not null default 'coupon' check (kind in ('coupon', 'discount')),
    -- Upper-case code for coupons; null for automatic discounts.
    code text,
    title text not null,                       -- "20% off your first booking"
    description text not null default '',
    discount_type text not null default 'percent' check (discount_type in ('percent', 'flat')),
    discount_value numeric(10, 2) not null check (discount_value > 0),
    max_discount numeric(10, 2) check (max_discount is null or max_discount > 0),   -- cap for percent
    min_order numeric(10, 2) not null default 0 check (min_order >= 0),
    -- Empty = everything. Otherwise any of: nurse, centre, equipment, medicine.
    applies_to text[] not null default '{}',
    starts_at timestamp with time zone,
    expires_at timestamp with time zone,
    usage_limit integer check (usage_limit is null or usage_limit > 0),          -- all customers together
    per_user_limit integer check (per_user_limit is null or per_user_limit > 0), -- each customer
    first_booking_only boolean not null default false,
    is_active boolean not null default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint coupons_code_needed check (kind = 'discount' or (code is not null and code <> '')),
    constraint coupons_percent_range check (discount_type = 'flat' or discount_value <= 100),
    constraint coupons_dates check (starts_at is null or expires_at is null or starts_at < expires_at)
);

create unique index if not exists coupons_code_key on public.coupons (upper(code)) where code is not null;

create table if not exists public.coupon_redemptions (
    id uuid primary key default gen_random_uuid(),
    coupon_id uuid not null references public.coupons(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    booking_ref text,                          -- e.g. 'ALC-NUR-12345'
    order_amount numeric(10, 2) not null,
    discount_amount numeric(10, 2) not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists coupon_redemptions_coupon_idx on public.coupon_redemptions (coupon_id);
create index if not exists coupon_redemptions_user_idx on public.coupon_redemptions (user_id);

-- Codes are stored upper-case; updated_at follows edits.
create or replace function public.coupons_normalize()
returns trigger language plpgsql as $$
begin
  new.code := nullif(upper(trim(coalesce(new.code, ''))), '');
  if new.kind = 'discount' then new.code := null; end if;
  new.applies_to := coalesce(new.applies_to, '{}');
  new.updated_at := timezone('utc'::text, now());
  return new;
end $$;

drop trigger if exists coupons_normalize on public.coupons;
create trigger coupons_normalize before insert or update on public.coupons
  for each row execute procedure public.coupons_normalize();

-- ------------------------------------------------------------------------------
-- Row level security: admins only. Customers go through the functions below.
-- ------------------------------------------------------------------------------
alter table public.coupons enable row level security;
alter table public.coupon_redemptions enable row level security;

drop policy if exists "Admins manage coupons" on public.coupons;
create policy "Admins manage coupons"
  on public.coupons for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists "Admins read redemptions, users their own" on public.coupon_redemptions;
create policy "Admins read redemptions, users their own"
  on public.coupon_redemptions for select to authenticated using (is_admin() or user_id = auth.uid());

drop policy if exists "Admins manage redemptions" on public.coupon_redemptions;
create policy "Admins manage redemptions"
  on public.coupon_redemptions for all to authenticated using (is_admin()) with check (is_admin());

revoke all on public.coupons from anon;
revoke all on public.coupon_redemptions from anon;
grant select, insert, update, delete on public.coupons to authenticated;
grant select, insert, update, delete on public.coupon_redemptions to authenticated;

-- ------------------------------------------------------------------------------
-- Checks shared by the customer functions. Returns the discount in rupees, or
-- raises a readable error (shown to the customer as is).
-- ------------------------------------------------------------------------------
create or replace function public.coupon_discount(c public.coupons, p_amount numeric, p_applies_to text, p_user uuid)
returns numeric language plpgsql stable security definer set search_path = public as $$
declare
  used_total integer;
  used_mine integer;
  off numeric;
begin
  if not c.is_active then raise exception 'This coupon is no longer active.'; end if;
  if c.starts_at is not null and now() < c.starts_at then raise exception 'This coupon isn’t active yet.'; end if;
  if c.expires_at is not null and now() > c.expires_at then raise exception 'This coupon has expired.'; end if;
  if cardinality(c.applies_to) > 0 and not (p_applies_to = any (c.applies_to)) then
    raise exception 'This coupon can’t be used for this booking.';
  end if;
  if p_amount < c.min_order then
    raise exception 'Add ₹% more to use this coupon (minimum order ₹%).', ceil(c.min_order - p_amount), trim_scale(c.min_order);
  end if;
  if c.usage_limit is not null then
    select count(*) into used_total from coupon_redemptions where coupon_id = c.id;
    if used_total >= c.usage_limit then raise exception 'This coupon has been fully used.'; end if;
  end if;
  if c.per_user_limit is not null then
    select count(*) into used_mine from coupon_redemptions where coupon_id = c.id and user_id = p_user;
    if used_mine >= c.per_user_limit then raise exception 'You’ve already used this coupon.'; end if;
  end if;
  if c.first_booking_only and exists (select 1 from coupon_redemptions where user_id = p_user) then
    raise exception 'This coupon is only for your first booking.';
  end if;

  off := case when c.discount_type = 'percent' then round(p_amount * c.discount_value / 100) else c.discount_value end;
  if c.max_discount is not null then off := least(off, c.max_discount); end if;
  return greatest(0, least(off, p_amount));
end $$;

revoke all on function public.coupon_discount(public.coupons, numeric, text, uuid) from public, anon, authenticated;

-- Preview a typed code at checkout.
create or replace function public.validate_coupon(p_code text, p_amount numeric, p_applies_to text)
returns table (coupon_id uuid, code text, title text, discount numeric)
language plpgsql stable security definer set search_path = public as $$
declare
  c coupons;
begin
  if auth.uid() is null then raise exception 'Please sign in to apply a coupon.'; end if;
  select * into c from coupons where kind = 'coupon' and upper(coupons.code) = upper(trim(p_code));
  if not found then raise exception 'That coupon code isn’t valid.'; end if;
  return query select c.id, c.code, c.title, coupon_discount(c, p_amount, p_applies_to, auth.uid());
end $$;

-- The automatic discount that saves the customer the most (no row when none apply).
create or replace function public.best_auto_discount(p_amount numeric, p_applies_to text)
returns table (coupon_id uuid, title text, discount numeric)
language plpgsql stable security definer set search_path = public as $$
declare
  c coupons;
  off numeric;
  best_off numeric := 0;
  best coupons;
begin
  if auth.uid() is null then return; end if;
  for c in select * from coupons where kind = 'discount' and is_active loop
    begin
      off := coupon_discount(c, p_amount, p_applies_to, auth.uid());
    exception when others then
      continue;
    end;
    if off > best_off then
      best_off := off;
      best := c;
    end if;
  end loop;
  if best_off > 0 then
    return query select best.id, best.title, best_off;
  end if;
end $$;

-- Record a use at payment. Re-checks every rule, locking the coupon so two
-- payments can't both take its last use. Returns the discount applied.
create or replace function public.redeem_coupon(p_coupon_id uuid, p_amount numeric, p_applies_to text, p_booking_ref text)
returns numeric
language plpgsql volatile security definer set search_path = public as $$
declare
  c coupons;
  off numeric;
begin
  if auth.uid() is null then raise exception 'Please sign in to apply a coupon.'; end if;
  select * into c from coupons where id = p_coupon_id for update;
  if not found then raise exception 'That coupon code isn’t valid.'; end if;
  off := coupon_discount(c, p_amount, p_applies_to, auth.uid());
  insert into coupon_redemptions (coupon_id, user_id, booking_ref, order_amount, discount_amount)
  values (c.id, auth.uid(), p_booking_ref, p_amount, off);
  return off;
end $$;

revoke all on function public.validate_coupon(text, numeric, text) from public, anon;
revoke all on function public.best_auto_discount(numeric, text) from public, anon;
revoke all on function public.redeem_coupon(uuid, numeric, text, text) from public, anon;
grant execute on function public.validate_coupon(text, numeric, text) to authenticated;
grant execute on function public.best_auto_discount(numeric, text) to authenticated;
grant execute on function public.redeem_coupon(uuid, numeric, text, text) to authenticated;

-- Starter coupons matching the codes the website used to hard-code (only when empty).
insert into public.coupons (kind, code, title, discount_type, discount_value, max_discount, per_user_limit, first_booking_only)
select * from (values
  ('coupon', 'FIRSTCARE', '20% off your first booking (up to ₹480)', 'percent', 20::numeric, 480::numeric, 1, true),
  ('coupon', 'CARE100', '₹100 off', 'flat', 100::numeric, null::numeric, null::integer, false)
) as v(kind, code, title, discount_type, discount_value, max_discount, per_user_limit, first_booking_only)
where not exists (select 1 from public.coupons);
