import React, { useEffect, useMemo, useState } from 'react';
import { BarChart3, MapPin } from 'lucide-react';
import { supabase, type PartnerKind, type PartnerStatus } from '../lib/supabase';
import { KIND_LABEL } from '../lib/partners';
import { EmptyState } from './EmptyState';

// Demand and retention need bookings, which aren't live yet. What we can show
// for real today is supply: where registered partners are, by city.

type Row = { kind: PartnerKind; status: PartnerStatus; city: string };

const KINDS: PartnerKind[] = ['nurse', 'doctor', 'physiotherapist', 'caregiver', 'centre'];

export const AnalyticsView: React.FC = () => {
  const [rows, setRows] = useState<Row[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void supabase
      .from('partners')
      .select('kind, status, city')
      .then(({ data, error: err }) => {
        setError(err?.message ?? null);
        setRows((data as Row[]) ?? []);
      });
  }, []);

  const cities = useMemo(() => {
    const map = new Map<string, { live: number; pending: number; byKind: Partial<Record<PartnerKind, number>> }>();
    for (const r of rows ?? []) {
      const city = r.city.trim() || 'City not set';
      const c = map.get(city) ?? { live: 0, pending: 0, byKind: {} };
      if (r.status === 'approved') {
        c.live += 1;
        c.byKind[r.kind] = (c.byKind[r.kind] ?? 0) + 1;
      } else if (r.status === 'under_review' || r.status === 'site_visit_scheduled') c.pending += 1;
      map.set(city, c);
    }
    return [...map.entries()].sort((a, b) => b[1].live - a[1].live || b[1].pending - a[1].pending);
  }, [rows]);

  return (
    <div className="analytics-view-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Cities &amp; Demand</h1>
          <p className="view-subtitle">Where partners are registered today, and — once bookings go live — where families book.</p>
        </div>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      <div className="analytics-grid">
        <div className="white-card-box">
          <div className="box-header-title">
            <span>Partner supply by city</span>
            <span className="count-tag">{cities.length} cities</span>
          </div>
          {rows === null ? (
            <div className="catalog-empty">Loading…</div>
          ) : cities.length === 0 ? (
            <div className="catalog-empty">No partners have registered yet.</div>
          ) : (
            <div className="cluster-list">
              {cities.map(([city, c]) => (
                <div key={city} className="cluster-item">
                  <div className="cluster-name-flex">
                    <MapPin size={16} className="icon-emerald" />
                    <div>
                      <div className="cluster-city">{city}</div>
                      <div className="cluster-meta">
                        {KINDS.filter((k) => c.byKind[k])
                          .map((k) => `${c.byKind[k]} ${KIND_LABEL[k].toLowerCase()}${c.byKind[k] === 1 ? '' : 's'}`)
                          .join(' · ') || 'No live partners yet'}
                      </div>
                    </div>
                  </div>
                  <div className="cluster-stats">
                    <span className="cluster-gmv">{c.live} live</span>
                    <span className="cluster-share">{c.pending} awaiting review</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <EmptyState
          icon={BarChart3}
          title="No demand data yet"
          willShow={['Bookings and revenue by city and locality', 'Repeat-booking rate and customer lifetime value', 'Average ratings across completed visits']}
        >
          Demand and retention metrics are calculated from bookings, which start once the marketplace goes live.
        </EmptyState>
      </div>
    </div>
  );
};
