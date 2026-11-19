import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { ChevronRight, ClipboardList, IndianRupee, Package, Pill, RefreshCw, ShieldCheck, Users } from 'lucide-react';
import { supabase, type PartnerKind, type PartnerStatus } from '../lib/supabase';
import { KIND_LABEL } from '../lib/partners';
import type { NavSection } from '../types/admin';
import { EmptyState } from './EmptyState';

// Real numbers only: partners from public.partners, catalogue counts from
// services / equipment / medicines. Bookings and revenue have no backend yet,
// so they show an empty state instead of figures.

type PartnerRow = { kind: PartnerKind; status: PartnerStatus; is_available: boolean; total_beds: number; beds_available: number };
type Catalog = { live: number; total: number };

const KINDS: PartnerKind[] = ['nurse', 'doctor', 'physiotherapist', 'caregiver', 'centre'];

const GROUPS: { id: 'live' | 'review' | 'progress' | 'stopped'; label: string; statuses: PartnerStatus[] }[] = [
  { id: 'live', label: 'Live', statuses: ['approved'] },
  { id: 'review', label: 'Awaiting review', statuses: ['under_review', 'site_visit_scheduled'] },
  { id: 'progress', label: 'Signing up', statuses: ['incomplete', 'onboarding'] },
  { id: 'stopped', label: 'Changes req. / suspended', statuses: ['rejected', 'suspended'] },
];

async function countCatalog(table: 'services' | 'equipment' | 'medicines'): Promise<Catalog> {
  const [all, live] = await Promise.all([
    supabase.from(table).select('id', { count: 'exact', head: true }),
    supabase.from(table).select('id', { count: 'exact', head: true }).eq('is_active', true),
  ]);
  return { total: all.count ?? 0, live: live.count ?? 0 };
}

export const OverviewView: React.FC<{ onNavigate: (s: NavSection) => void }> = ({ onNavigate }) => {
  const [partners, setPartners] = useState<PartnerRow[] | null>(null);
  const [catalog, setCatalog] = useState<Record<'services' | 'equipment' | 'medicines', Catalog> | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const [p, services, equipment, medicines] = await Promise.all([
      supabase.from('partners').select('kind, status, is_available, total_beds, beds_available'),
      countCatalog('services'),
      countCatalog('equipment'),
      countCatalog('medicines'),
    ]);
    setError(p.error?.message ?? null);
    setPartners((p.data as PartnerRow[]) ?? []);
    setCatalog({ services, equipment, medicines });
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  const stats = useMemo(() => {
    const rows = partners ?? [];
    const grid = Object.fromEntries(KINDS.map((k) => [k, { live: 0, review: 0, progress: 0, stopped: 0 }])) as Record<
      PartnerKind,
      Record<(typeof GROUPS)[number]['id'], number>
    >;
    for (const r of rows) {
      const g = GROUPS.find((x) => x.statuses.includes(r.status));
      if (g && grid[r.kind]) grid[r.kind][g.id] += 1;
    }
    const live = rows.filter((r) => r.status === 'approved');
    const liveCentres = live.filter((r) => r.kind === 'centre');
    return {
      grid,
      total: rows.length,
      live: live.length,
      takingBookings: live.filter((r) => r.is_available).length,
      review: rows.filter((r) => r.status === 'under_review' || r.status === 'site_visit_scheduled').length,
      progress: rows.filter((r) => r.status === 'incomplete' || r.status === 'onboarding').length,
      liveCentres: liveCentres.length,
      beds: liveCentres.reduce((n, r) => n + r.total_beds, 0),
      freeBeds: liveCentres.reduce((n, r) => n + r.beds_available, 0),
    };
  }, [partners]);

  const loading = partners === null;
  const n = (v: number) => (loading ? '—' : v.toLocaleString('en-IN'));

  return (
    <div className="overview-view-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Marketplace Overview</h1>
          <p className="view-subtitle">Live numbers from Supabase — partners, catalogue and (once bookings start) revenue.</p>
        </div>
        <div className="catalog-header-actions">
          <button className="btn-sm-outline" onClick={() => void load()} title="Reload from Supabase">
            <RefreshCw size={13} /> Refresh
          </button>
        </div>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      <div className="payouts-metric-cards-grid">
        <button className={`payout-metric-card overview-metric ${stats.review > 0 ? 'is-attention' : ''}`} onClick={() => onNavigate('verification')}>
          <span className="payout-metric-label">Awaiting your approval</span>
          <div className="payout-metric-val">{n(stats.review)}</div>
          <span className="payout-metric-sub">
            {stats.review > 0 ? 'Review now' : 'Nothing waiting'} <ChevronRight size={13} />
          </span>
        </button>
        <button className="payout-metric-card overview-metric highlight-green" onClick={() => onNavigate('verification')}>
          <span className="payout-metric-label">Live partners</span>
          <div className="payout-metric-val">{n(stats.live)}</div>
          <span className="payout-metric-sub">{n(stats.takingBookings)} taking bookings</span>
        </button>
        <button className="payout-metric-card overview-metric" onClick={() => onNavigate('verification')}>
          <span className="payout-metric-label">Still signing up</span>
          <div className="payout-metric-val">{n(stats.progress)}</div>
          <span className="payout-metric-sub">{n(stats.total)} registered in total</span>
        </button>
        <button className="payout-metric-card overview-metric" onClick={() => onNavigate('centres_beds')}>
          <span className="payout-metric-label">Beds free at live centres</span>
          <div className="payout-metric-val">{loading ? '—' : stats.beds > 0 ? `${stats.freeBeds} / ${stats.beds}` : '0'}</div>
          <span className="payout-metric-sub">
            {n(stats.liveCentres)} live centre{stats.liveCentres === 1 ? '' : 's'}
          </span>
        </button>
      </div>

      <div className="overview-two-col-grid">
        <div className="white-card-box">
          <div className="box-header-row">
            <div className="box-title-flex">
              <Users size={16} className="title-icon" />
              <span className="box-title">Partners by type</span>
            </div>
            <button className="btn-sm-outline" onClick={() => onNavigate('verification')}>
              <ShieldCheck size={13} /> Manage
            </button>
          </div>
          <div className="table-scroll">
            <table className="custom-data-table">
              <thead>
                <tr>
                  <th>Type</th>
                  {GROUPS.map((g) => (
                    <th key={g.id}>{g.label}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {KINDS.map((k) => (
                  <tr key={k}>
                    <td className="partner-name-bold">{KIND_LABEL[k]}s</td>
                    {GROUPS.map((g) => (
                      <td key={g.id} className={stats.grid[k][g.id] ? 'txn-id-bold' : 'date-sub'}>
                        {loading ? '—' : stats.grid[k][g.id]}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {!loading && stats.total === 0 && (
            <p className="date-sub overview-note">
              No partners yet — nurses, doctors, physios, caregivers and centres register from the partner portal or app.
            </p>
          )}
        </div>

        <div className="white-card-box">
          <div className="box-header-row">
            <div className="box-title-flex">
              <ClipboardList size={16} className="title-icon" />
              <span className="box-title">Catalogue on the website &amp; app</span>
            </div>
          </div>
          <div className="category-revenue-list">
            {(
              [
                ['services', 'Services', ClipboardList, 'cat-icon-badge purple-circle'],
                ['equipment', 'Equipment for rent', Package, 'cat-icon-badge blue-circle'],
                ['medicines', 'Medicines', Pill, 'cat-icon-badge green-circle'],
              ] as const
            ).map(([key, label, Icon, cls]) => (
              <button key={key} className="cat-row-item overview-cat-row" onClick={() => onNavigate(key)}>
                <div className={cls}>
                  <Icon size={15} />
                </div>
                <div className="cat-info">
                  <span className="cat-name">{label}</span>
                  <span className="cat-sub">
                    {catalog ? `${catalog[key].total - catalog[key].live} hidden` : '—'}
                  </span>
                </div>
                <span className="cat-val">{catalog ? `${catalog[key].live} live` : '—'}</span>
                <ChevronRight size={14} className="chevron" />
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="overview-bookings">
        <EmptyState
          icon={IndianRupee}
          title="No bookings or revenue yet"
          willShow={['Bookings, cancellations and fulfilment rate', 'Revenue (GMV) by service and city', 'Allcuro commission and partner payouts']}
        >
          These figures start once families can book and pay online. Everything above is already live.
        </EmptyState>
      </div>
    </div>
  );
};
