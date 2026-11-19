import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Ban, CheckCircle2, Download, RefreshCw, Search, ShieldCheck, Star } from 'lucide-react';
import { supabase, type PartnerKind, type PartnerRecord, type PartnerStatus } from '../lib/supabase';
import { KIND_LABEL, STATUS_LABEL, fmtDate, statusClass } from '../lib/partners';
import { PartnerEditor } from './partners/PartnerEditor';

// Every nurse, doctor, physiotherapist, caregiver and care centre who signed
// up from the partner portal or app (public.partners). Nothing reaches the
// customer website or app until it is approved here; prices and discounts are
// set here too.

type Tab = 'review' | 'approved' | 'progress' | 'stopped' | 'all';

const KINDS: PartnerKind[] = ['nurse', 'doctor', 'physiotherapist', 'caregiver', 'centre'];

const KIND_PLURAL: Record<PartnerKind, string> = {
  nurse: 'Nurses',
  doctor: 'Doctors',
  physiotherapist: 'Physios',
  caregiver: 'Caregivers',
  centre: 'Centres',
};

/** One CSV cell: quoted, and neutralised if a spreadsheet would read it as a formula. */
const csvCell = (v: string) => {
  // Phone numbers like "+91 98…" are plain numbers, not formulas — leave them as is.
  const safe = /^[=+\-@\t\r]/.test(v) && !/^[+-]?[\d\s()-]+$/.test(v) ? `'${v}` : v;
  return `"${safe.replace(/"/g, '""')}"`;
};

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
  const [busyId, setBusyId] = useState<string | null>(null);

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

  // Keeps the sidebar badge in step with approvals, inline suspends and editor saves.
  // Skipped while loading so the badge doesn't flash to 0.
  useEffect(() => {
    if (loading || error) return;
    onCountChange?.(rows.filter((r) => r.status === 'under_review' || r.status === 'site_visit_scheduled').length);
  }, [rows, loading, error, onCountChange]);

  const counts = useMemo(() => {
    const c: Record<Tab, number> = { review: 0, approved: 0, progress: 0, stopped: 0, all: rows.length };
    for (const r of rows) for (const t of TABS) if (t.statuses?.includes(r.status)) c[t.id] += 1;
    return c;
  }, [rows]);

  // Rows in the current tab (before the type chip / search narrow it down).
  const inTab = useMemo(() => {
    const statuses = TABS.find((t) => t.id === tab)?.statuses;
    return rows.filter((r) => !statuses || statuses.includes(r.status));
  }, [rows, tab]);

  const kindCounts = useMemo(() => {
    const c = Object.fromEntries(KINDS.map((k) => [k, 0])) as Record<PartnerKind, number>;
    for (const r of inTab) c[r.kind] += 1;
    return c;
  }, [inTab]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    return inTab.filter(
      (r) =>
        (kind === 'all' || r.kind === kind) &&
        (!q ||
          `${r.display_name} ${r.city} ${r.locality} ${r.phone} ${r.email} ${r.allcuro_code ?? ''}`.toLowerCase().includes(q)),
    );
  }, [inTab, kind, query]);

  /** Inline change from the table; the row (and so the sidebar badge) updates from the saved record. */
  const patch = async (r: PartnerRecord, changes: Partial<PartnerRecord>) => {
    setBusyId(r.id);
    setError(null);
    const { data, error: err } = await supabase.from('partners').update(changes).eq('id', r.id).select().single();
    setBusyId(null);
    if (err) return setError(`${r.display_name || 'Partner'}: ${err.message}`);
    setRows((prev) => prev.map((x) => (x.id === r.id ? (data as PartnerRecord) : x)));
  };

  const toggleAvailable = (r: PartnerRecord) => {
    const next = !r.is_available;
    const name = r.display_name || 'this partner';
    const msg = next
      ? `Start taking bookings for ${name}? Families can book them again on the website and app.`
      : `Stop new bookings for ${name}? Their profile stays visible but shows as unavailable.`;
    if (window.confirm(msg)) void patch(r, { is_available: next });
  };

  const suspend = (r: PartnerRecord) => {
    if (window.confirm(`Suspend ${r.display_name || 'this partner'}? They disappear from the website and app immediately.`))
      void patch(r, { status: 'suspended' });
  };

  const reinstate = (r: PartnerRecord) => {
    if (window.confirm(`Reinstate ${r.display_name || 'this partner'}? They go live on the website and app again.`))
      void patch(r, { status: 'approved' });
  };

  const exportCsv = () => {
    const header = ['Name', 'Type', 'Status', 'Phone', 'Email', 'City', 'Allcuro code', 'Submitted'];
    const lines = visible.map((r) =>
      [
        r.display_name,
        KIND_LABEL[r.kind],
        STATUS_LABEL[r.status],
        r.phone,
        r.email,
        [r.locality, r.city].filter(Boolean).join(', '),
        r.allcuro_code ?? '',
        r.submitted_at ? r.submitted_at.slice(0, 10) : '',
      ]
        .map((v) => csvCell(v ?? ''))
        .join(','),
    );
    // BOM so Excel opens it as UTF-8 (₹, non-Latin names).
    const blob = new Blob(['\uFEFF' + [header.join(','), ...lines].join('\r\n')], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `allcuro-partners-${tab}${kind === 'all' ? '' : `-${kind}`}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

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
          <button
            className="btn-sm-outline"
            onClick={exportCsv}
            disabled={visible.length === 0}
            title="Download the rows shown below as a CSV file"
          >
            <Download size={13} /> Export CSV
          </button>
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

      <div className="partner-kind-strip">
        {KINDS.map((k) => (
          <button
            key={k}
            className={`partner-kind-stat ${kind === k ? 'active' : ''}`}
            onClick={() => setKind(kind === k ? 'all' : k)}
            title={kind === k ? 'Show all types' : `Show only ${KIND_PLURAL[k].toLowerCase()}`}
          >
            <span className="partner-kind-num">{loading ? '—' : kindCounts[k]}</span>
            <span className="partner-kind-label">{KIND_PLURAL[k]}</span>
          </button>
        ))}
      </div>

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
              : 'No partners match this tab, type and search.'}
          </div>
        ) : (
          <div className="table-scroll">
          <table className="custom-data-table">
            <thead>
              <tr>
                <th>Partner</th>
                <th>Type</th>
                <th>City</th>
                <th>Phone</th>
                <th>Rating</th>
                <th>Submitted</th>
                <th>Status</th>
                <th>Taking bookings</th>
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
                  <td className="nowrap">
                    {r.phone ? <a className="partner-phone" href={`tel:${r.phone}`}>{r.phone}</a> : '—'}
                  </td>
                  <td className="nowrap">
                    {r.rating != null ? (
                      <span className="partner-rating">
                        <Star size={12} /> {r.rating.toFixed(1)} <span className="date-sub">({r.review_count})</span>
                      </span>
                    ) : (
                      <span className="date-sub">New{r.review_count ? ` (${r.review_count})` : ''}</span>
                    )}
                  </td>
                  <td className="nowrap">{fmtDate(r.submitted_at)}</td>
                  <td>
                    <span className={`catalog-status ${statusClass(r.status)}`}>{STATUS_LABEL[r.status]}</span>
                  </td>
                  <td>
                    {r.status === 'approved' ? (
                      <label className="partner-switch" title={r.is_available ? 'Taking bookings — click to pause' : 'Paused — click to resume'}>
                        <input
                          type="checkbox"
                          checked={r.is_available}
                          disabled={busyId === r.id}
                          onChange={() => toggleAvailable(r)}
                        />
                        <span className="partner-switch-track" />
                        <span className="partner-switch-text">{r.is_available ? 'Yes' : 'Paused'}</span>
                      </label>
                    ) : (
                      <span className="date-sub">—</span>
                    )}
                  </td>
                  <td>
                    <div className="catalog-row-actions">
                      {r.status === 'approved' && (
                        <button
                          className="btn-sm-outline is-danger"
                          disabled={busyId === r.id}
                          onClick={() => suspend(r)}
                          title="Hide from the website and app"
                        >
                          <Ban size={13} /> Suspend
                        </button>
                      )}
                      {r.status === 'suspended' && (
                        <button
                          className="btn-sm-outline"
                          disabled={busyId === r.id}
                          onClick={() => reinstate(r)}
                          title="Make live again"
                        >
                          <CheckCircle2 size={13} /> Reinstate
                        </button>
                      )}
                      <button className="btn-sm-primary" onClick={() => setOpen(r)}>
                        <ShieldCheck size={13} />{' '}
                        {r.status === 'under_review' || r.status === 'site_visit_scheduled' ? 'Review' : 'Open'}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          </div>
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
