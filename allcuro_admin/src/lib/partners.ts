import { supabase, type PartnerKind, type PartnerStatus } from './supabase';

// Labels and helpers for public.partners (see supabase/marketplace.sql).

export const KIND_LABEL: Record<PartnerKind, string> = {
  nurse: 'Nurse',
  doctor: 'Doctor',
  physiotherapist: 'Physiotherapist',
  caregiver: 'Caregiver',
  centre: 'Care centre',
};

export const STATUS_LABEL: Record<PartnerStatus, string> = {
  incomplete: 'Signing up',
  onboarding: 'Setting up',
  under_review: 'Awaiting review',
  site_visit_scheduled: 'Site visit',
  approved: 'Live',
  rejected: 'Changes requested',
  suspended: 'Suspended',
};

export const statusClass = (s: PartnerStatus) =>
  s === 'approved' ? 'is-live' : s === 'rejected' || s === 'suspended' ? 'is-hidden' : 'is-pending';

export const fmtDate = (iso: string | null) =>
  iso ? new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

/** Count shown on the sidebar's badge. */
export async function countPendingPartners() {
  const { count } = await supabase
    .from('partners')
    .select('id', { count: 'exact', head: true })
    .in('status', ['under_review', 'site_visit_scheduled']);
  return count ?? 0;
}

