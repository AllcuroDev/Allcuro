import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { RefreshCw, Search, ShieldCheck } from 'lucide-react';
import { supabase, type PartnerKind, type PartnerRecord, type PartnerStatus } from '../lib/supabase';
import { KIND_LABEL, STATUS_LABEL, fmtDate, statusClass } from '../lib/partners';
import { PartnerEditor } from './partners/PartnerEditor';

// Every nurse, doctor, physiotherapist, caregiver and care centre who signed
// up from the partner portal or app (public.partners). Nothing reaches the
// customer website or app until it is approved here; prices and discounts are
// set here too.

type Tab = 'review' | 'approved' | 'progress' | 'stopped' | 'all';

const TABS: { id: Tab; label: string; statuses: PartnerStatus[] | null }[] = [
  { id: 'review', label: 'Awaiting review', statuses: ['under_review', 'site_visit_scheduled'] },
  { id: 'approved', label: 'Live', statuses: ['approved'] },
  { id: 'progress', label: 'Signing up', statuses: ['incomplete', 'onboarding'] },
  { id: 'stopped', label: 'Changes requested / suspended', statuses: ['rejected', 'suspended'] },
  { id: 'all', label: 'All', statuses: null },
];

export const PartnersView: React.FC<{ onCountChange?: (n: number) => void }> = ({ onCountChange }) => {
  const [rows, setRows] = useState<PartnerRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>('review');
  const [kind, setKind] = useState<PartnerKind | 'all'>('all');
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState<PartnerRecord | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const { data, error: err } = await supabase
      .from('partners')
      .select('*')
      .order('submitted_at', { ascending: false, nullsFirst: false })
      .order('created_at', { ascending: false });
    setError(err?.message ?? null);
    setRows((data as PartnerRecord[]) ?? []);
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  useEffect(() => {
    onCountChange?.(rows.filter((r) => r.status === 'under_review' || r.status === 'site_visit_scheduled').length);
  }, [rows, onCountChange]);

  const counts = useMemo(() => {
    const c: Record<Tab, number> = { review: 0, approved: 0, progress: 0, stopped: 0, all: rows.length };
    for (const r of rows) for (const t of TABS) if (t.statuses?.includes(r.status)) c[t.id] += 1;
    return c;
  }, [rows]);

  const visible = useMemo(() => {
    const statuses = TABS.find((t) => t.id === tab)?.statuses;
    const q = query.trim().toLowerCase();
    return rows.filter(
      (r) =>
        (!statuses || statuses.includes(r.status)) &&
        (kind === 'all' || r.kind === kind) &&
        (!q || `${r.display_name} ${r.city} ${r.locality} ${r.phone} ${r.allcuro_code ?? ''}`.toLowerCase().includes(q)),
    );
  }, [rows, tab, kind, query]);

  return (
    <div className="services-catalog-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Partners &amp; Approvals</h1>
          <p className="view-subtitle">
            Nurses, doctors, physios, caregivers and centres who signed up. Only approved partners appear on the website and
            customer app — prices and discounts are set here.
          </p>
        </div>
        <div className="catalog-header-actions">
          <button className="btn-sm-outline" onClick={() => void load()} title="Reload from Supabase">
            <RefreshCw size={13} /> Refresh
          </button>
        </div>
      </div>

      <div className="catalog-tabs" role="tablist">
        {TABS.map((t) => (
          <button
            key={t.id}
            role="tab"
            aria-selected={tab === t.id}
            className={`catalog-tab ${tab === t.id ? 'active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            {t.label} <span className="catalog-tab-count">{counts[t.id]}</span>
          </button>
        ))}
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      <div className="payouts-table-box">
        <div className="catalog-toolbar">
          <div className="catalog-chips">
            {(['all', 'nurse', 'doctor', 'physiotherapist', 'caregiver', 'centre'] as const).map((k) => (
              <button key={k} className={`catalog-chip ${kind === k ? 'active' : ''}`} onClick={() => setKind(k)}>
                {k === 'all' ? 'All types' : KIND_LABEL[k]}
              </button>
            ))}
          </div>
          <label className="catalog-search">
            <Search size={14} />
            <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search name, city, phone" />
          </label>
        </div>

        {loading ? (
          <div className="catalog-empty">Loading partners…</div>
        ) : visible.length === 0 ? (
          <div className="catalog-empty">
            {rows.length === 0
              ? 'No partners have signed up yet. They register from the partner portal (/partner) or the partner app.'
              : 'Nothing here.'}
          </div>
        ) : (
          <table className="custom-data-table">
            <thead>
              <tr>
                <th>Partner</th>
                <th>Type</th>
                <th>City</th>
                <th>Submitted</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {visible.map((r) => (
                <tr key={r.id}>
                  <td>
                    <div className="partner-cell">
                      {r.photo_url || r.photos[0] ? (
                        <img className="catalog-thumb is-round" src={r.photo_url ?? r.photos[0]} alt="" />
                      ) : (
                        <span className="partner-initials">{(r.display_name || '?').slice(0, 2).toUpperCase()}</span>
                      )}
                      <div>
                        <div className="partner-name-bold">{r.display_name || 'Unnamed'}</div>
                        <div className="date-sub">
                          {r.headline || r.qualification || '—'}
                          {r.allcuro_code && (
                            <>
                              {' '}
                              · <span className="code-subaccount">{r.allcuro_code}</span>
                            </>
                          )}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>{KIND_LABEL[r.kind]}</td>
                  <td>{[r.locality, r.city].filter(Boolean).join(', ') || '—'}</td>
                  <td>{fmtDate(r.submitted_at)}</td>
                  <td>
                    <span className={`catalog-status ${statusClass(r.status)}`}>{STATUS_LABEL[r.status]}</span>
                  </td>
                  <td>
                    <button className="btn-sm-primary" onClick={() => setOpen(r)}>
                      <ShieldCheck size={13} /> {r.status === 'under_review' || r.status === 'site_visit_scheduled' ? 'Review' : 'Open'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {open && (
        <PartnerEditor
          initial={open}
          onClose={() => setOpen(null)}
          onSaved={(saved) => {
            setRows((prev) => prev.map((x) => (x.id === saved.id ? saved : x)));
            setOpen(saved);
          }}
          onDeleted={(id) => {
            setRows((prev) => prev.filter((x) => x.id !== id));
            setOpen(null);
          }}
        />
      )}
    </div>
  );
};
