import { createClient } from '@supabase/supabase-js';

// SUPABASE_URL / SUPABASE_ANON_KEY are inlined at build time (see vite.config.ts).
const supabaseUrl = (import.meta.env.SUPABASE_URL as string) || 'https://your-project.supabase.co';
const supabaseAnonKey = (import.meta.env.SUPABASE_ANON_KEY as string) || 'your-anon-key';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export const isSupabaseConfigured = Boolean(
  import.meta.env.SUPABASE_URL && import.meta.env.SUPABASE_ANON_KEY,
);

export interface ProfileRecord {
  id: string;
  role: 'customer' | 'nurse' | 'centre' | 'admin';
  full_name: string;
  phone?: string;
  email?: string;
  city?: string;
  kyc_status: 'incomplete' | 'under_review' | 'site_visit_scheduled' | 'verified' | 'flagged';
  created_at: string;
}

/** A row of public.service_categories — see supabase/services.sql. */
export interface ServiceCategoryRecord {
  id: string;
  slug: string;
  label: string;
  blurb: string;
  /** Page to open instead of a services list, e.g. '/centres'. */
  href: string | null;
  icon: string;
  art: string;
  ink: string;
  wash: string;
  image_url: string | null;
  sort_order: number;
  is_active: boolean;
}

/** A row of public.services — see supabase/services.sql. */
export interface ServiceRecord {
  id: string;
  name: string;
  category_id: string;
  /** Also listed under these categories, e.g. ['Caregivers']. */
  extra_category_ids: string[];
  subcategory: string;
  description: string;
  includes: string;
  not_included: string;
  duration: string;
  professional: string;
  price: string;
  price_from: number | null;
  /** Admin-set discount, 0–100. */
  discount_percent: number;
  notes: string;
  badge: string;
  icon: string;
  image_url: string | null;
  sort_order: number;
  is_active: boolean;
}

export type PartnerStatus =
  | 'incomplete'
  | 'onboarding'
  | 'under_review'
  | 'site_visit_scheduled'
  | 'approved'
  | 'rejected'
  | 'suspended';

export type PartnerKind = 'nurse' | 'doctor' | 'physiotherapist' | 'caregiver' | 'centre';

/** A row of public.partners — see supabase/marketplace.sql. */
export interface PartnerRecord {
  id: string;
  user_id: string;
  role: 'nurse' | 'clinician' | 'centre';
  kind: PartnerKind;
  slug: string;
  status: PartnerStatus;
  display_name: string;
  photo_url: string | null;
  headline: string;
  bio: string;
  city: string;
  locality: string;
  languages: string[];
  skills: string[];
  highlights: string[];
  qualification: string;
  specialisations: string[];
  experience_years: number;
  employment_type: string;
  is_available: boolean;
  centre_type: string;
  year_established: number | null;
  staff_ratio: string;
  total_beds: number;
  beds_available: number;
  services_included: string[];
  room_types: string[];
  photos: string[];
  food_menu: string;
  licence_no: string;
  public_phone: string;
  price_per_day: number | null;
  price_per_month: number | null;
  discount_percent: number;
  rating: number | null;
  review_count: number;
  allcuro_code: string | null;
  admin_note: string;
  site_visit_at: string | null;
  reviewed_at: string | null;
  phone: string;
  email: string;
  address: string;
  registration_number: string;
  council: string;
  previous_employer: string;
  identity: Record<string, unknown>;
  bank: Record<string, unknown> | null;
  details: Record<string, unknown>;
  submitted_at: string | null;
  created_at: string;
  updated_at: string;
}

/** A row of public.partner_offerings. price/discount null → the catalog service's. */
export interface OfferingRecord {
  id: string;
  partner_id: string;
  service_id: string | null;
  label: string;
  unit: string;
  price: number | null;
  discount_percent: number | null;
  is_active: boolean;
  sort_order: number;
}

/** A row of public.equipment. */
export interface EquipmentRecord {
  id: string;
  slug: string;
  title: string;
  category: string;
  condition: string;
  description: string;
  features: string[];
  daily_rate: number;
  monthly_rate: number;
  deposit_amount: number;
  discount_percent: number;
  stock_quantity: number;
  photo_url: string | null;
  available_pincodes: string;
  is_available: boolean;
  is_active: boolean;
  sort_order: number;
}

/** A row of public.medicines. */
export interface MedicineRecord {
  id: string;
  name: string;
  pack: string;
  category: string;
  mrp: number;
  price: number;
  rx: boolean;
  image_url: string | null;
  sort_order: number;
  is_active: boolean;
}

export interface FaqRecord {
  id: string;
  question: string;
  answer: string;
  sort_order: number;
  is_active: boolean;
}
