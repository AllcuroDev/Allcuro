import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export const isSupabaseConfigured = Boolean(
  import.meta.env.VITE_SUPABASE_URL && import.meta.env.VITE_SUPABASE_ANON_KEY,
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
  notes: string;
  badge: string;
  icon: string;
  image_url: string | null;
  sort_order: number;
  is_active: boolean;
}
