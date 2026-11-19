import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Building2, ClipboardCheck, Phone, RefreshCw, Users } from 'lucide-react';
import { supabase, type PartnerRecord } from '../lib/supabase';
import { STATUS_LABEL, statusClass } from '../lib/partners';
import { EmptyState } from './EmptyState';

// Real care centres from public.partners (kind = 'centre'). Beds available is
// what families see on the website; the admin can correct it here inline.

type Centre = Pick<
  PartnerRecord,
  | 'id'
  | 'display_name'
  | 'status'
  | 'city'
  | 'locality'
  | 'centre_type'
  | 'staff_ratio'
  | 'licence_no'
  | 'public_phone'
  | 'total_beds'
  | 'beds_available'
  | 'price_per_day'
  | 'is_available'
  | 'allcuro_code'
>;

const COLUMNS =
  'id, display_name, status, city, locality, centre_type, staff_ratio, licence_no, public_phone, total_beds, beds_available, price_per_day, is_available, allcuro_code';

export const BedOccupancyView: React.FC<{ onOpenPartners?: () => void }> = ({ onOpenPartners }) => {
  const [centres, setCentres] = useState<Centre[] | null>(null);
  const [draft, setDraft] = useState<Record<string, string>>({});
  const [savingId, setSavingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const { data, error: err } = await supabase
      .from('partners')
      .select(COLUMNS)
      .eq('kind', 'centre')
      .order('display_name');
    setError(err?.message ?? null);
    setCentres((data as Centre[]) ?? []);
    setDraft({});
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  // Live centres first, then by name.
  const sorted = useMemo(
    () => [...(centres ?? [])].sort((a, b) => Number(b.status === 'approved') - Number(a.status === 'approved')),
    [centres],
  );

  const live = sorted.filter((c) => c.status === 'approved');
  const totalBeds = live.reduce((n, c) => n + c.total_beds, 0);
  const freeBeds = live.reduce((n, c) => n + c.beds_available, 0);

  const saveBeds = async (c: Centre) => {
    const raw = draft[c.id];
    const value = Math.floor(Number(raw));
    if (raw === '' || !Number.isFinite(value) || value < 0) return setError('Beds available must be 0 or more.');
    if (c.total_beds > 0 && value > c.total_beds)
      return setError(`${c.display_name} has ${c.total_beds} beds in total — beds available can't be higher.`);
    setSavingId(c.id);
    setError(null);
    const { data, error: err } = await supabase
      .from('partners')
      .update({ beds_available: value })
      .eq('id', c.id)
      .select(COLUMNS)
      .single();
    setSavingId(null);
    if (err) return setError(err.message);
    setCentres((prev) => (prev ?? []).map((x) => (x.id === c.id ? (data as Centre) : x)));
    setDraft((d) => {
      const next = { ...d };
      delete next[c.id];
      return next;
    });
  };

  return (
    <div className="bed-occupancy-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Care Centres &amp; Beds</h1>
          <p className="view-subtitle">
            Registered care centres and the beds families see as available. Update a centre’s free beds here when they call in.
          </p>
        </div>
        <div className="catalog-header-actions">
          {live.length > 0 && (
            <span className="count-tag beds-summary-tag">
              {freeBeds} of {totalBeds} beds free across {live.length} live centre{live.length === 1 ? '' : 's'}
            </span>
          )}
          <button className="btn-sm-outline" onClick={() => void load()} title="Reload from Supabase">
            <RefreshCw size={13} /> Refresh
          </button>
        </div>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      {centres === null ? (
        <div className="catalog-empty">Loading centres…</div>
      ) : sorted.length === 0 ? (
        <EmptyState
          icon={Building2}
          title="No care centres registered yet"
          action={
            onOpenPartners && (
              <button className="btn-sm-outline" onClick={onOpenPartners}>
                Go to Partners &amp; Approvals
              </button>
            )
          }
        >
          Centres sign up from the partner portal. Once they do, their beds, prices and status show up here — and you can
          approve them under Partners &amp; Approvals.
        </EmptyState>
      ) : (
        <div className="centres-matrix-grid">
          {sorted.map((c) => {
            const occupied = Math.max(0, c.total_beds - c.beds_available);
            const pct = c.total_beds > 0 ? Math.round((occupied / c.total_beds) * 100) : 0;
            const value = draft[c.id] ?? String(c.beds_available);
            const dirty = draft[c.id] !== undefined && draft[c.id] !== String(c.beds_available);
            return (
              <div key={c.id} className="centre-matrix-card">
                <div className="matrix-top-row">
                  <div>
                    <span className="centre-id">
                      <span className={`catalog-status ${statusClass(c.status)}`}>{STATUS_LABEL[c.status]}</span>
                      {c.allcuro_code && <> · {c.allcuro_code}</>}
                    </span>
                    <h3 className="centre-name">{c.display_name || 'Unnamed centre'}</h3>
                    <span className="centre-locality">{[c.locality, c.city].filter(Boolean).join(', ') || 'No address yet'}</span>
                  </div>
                  <div className="price-tag-wrap">
                    {c.price_per_day != null ? (
                      <>
                        <span className="price-bold">₹{c.price_per_day.toLocaleString('en-IN')}</span>
                        <span className="price-sub">/ day</span>
                      </>
                    ) : (
                      <span className="price-sub">Price not set</span>
                    )}
                  </div>
                </div>

                <div className="occupancy-progress-section">
                  <div className="progress-labels-row">
                    <span>Occupancy</span>
                    <span>
                      {c.total_beds > 0 ? `${occupied} / ${c.total_beds} beds (${pct}%)` : 'Total beds not set'}
                    </span>
                  </div>
                  <div className="progress-track">
                    <div className="progress-fill" style={{ width: `${pct}%` }} />
                  </div>
                  <div className="beds-edit-row">
                    <label>
                      Beds available
                      <input
                        className="catalog-inline-input is-num"
                        type="number"
                        min={0}
                        max={c.total_beds > 0 ? c.total_beds : undefined}
                        value={value}
                        onChange={(e) => setDraft((d) => ({ ...d, [c.id]: e.target.value }))}
                        onKeyDown={(e) => e.key === 'Enter' && dirty && void saveBeds(c)}
                      />
                    </label>
                    <button
                      className="btn-sm-primary"
                      disabled={!dirty || savingId === c.id}
                      onClick={() => void saveBeds(c)}
                    >
                      {savingId === c.id ? 'Saving…' : 'Update'}
                    </button>
                    {!c.is_available && <span className="date-sub">Not accepting admissions</span>}
                  </div>
                </div>

                <div className="centre-trust-meta-grid">
                  <div className="trust-cell">
                    <Building2 size={14} className="icon-emerald" />
                    <div>
                      <div className="trust-title">Centre type</div>
                      <div className="trust-val">{c.centre_type || '—'}</div>
                    </div>
                  </div>
                  <div className="trust-cell">
                    <Users size={14} className="icon-emerald" />
                    <div>
                      <div className="trust-title">Staff ratio</div>
                      <div className="trust-val">{c.staff_ratio || '—'}</div>
                    </div>
                  </div>
                  <div className="trust-cell">
                    <ClipboardCheck size={14} className="icon-emerald" />
                    <div>
                      <div className="trust-title">Licence no.</div>
                      <div className="trust-val">{c.licence_no || '—'}</div>
                    </div>
                  </div>
                  <div className="trust-cell">
                    <Phone size={14} className="icon-emerald" />
                    <div>
                      <div className="trust-title">Front desk</div>
                      <div className="trust-val">{c.public_phone || '—'}</div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
