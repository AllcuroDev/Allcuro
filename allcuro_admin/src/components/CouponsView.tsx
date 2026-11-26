import React, { useCallback, useEffect, useState } from 'react';
import { Eye, EyeOff, Pencil, Plus, RefreshCw, Search, Trash2, X } from 'lucide-react';
import { supabase, type CouponRecord, type CouponScope } from '../lib/supabase';
import { inr } from '../lib/catalog';

// Coupons (customer types a code) and automatic discounts (applied at checkout
// with no code) — public.coupons, see supabase/coupons.sql. Both work only for
// signed-in customers; the website and app check them through database
// functions, which also enforce the limits set here.

const SCOPES: { id: CouponScope; label: string }[] = [
  { id: 'nurse', label: 'Home visits (nurse, doctor, physio…)' },
  { id: 'centre', label: 'Care centre admissions' },
  { id: 'equipment', label: 'Equipment rental' },
  { id: 'medicine', label: 'Medicines' },
];

type Filter = 'all' | 'coupon' | 'discount';

const blank = (): CouponRecord => ({
  id: '',
  kind: 'coupon',
  code: '',
  title: '',
  description: '',
  discount_type: 'percent',
  discount_value: 10,
  max_discount: null,
  min_order: 0,
  applies_to: [],
  starts_at: null,
  expires_at: null,
  usage_limit: null,
  per_user_limit: 1,
  first_booking_only: false,
  is_active: true,
});

const valueLabel = (c: Pick<CouponRecord, 'discount_type' | 'discount_value' | 'max_discount'>) =>
  c.discount_type === 'percent'
    ? `${c.discount_value}% off${c.max_discount ? ` (up to ${inr(c.max_discount)})` : ''}`
    : `${inr(c.discount_value)} off`;

const shortDate = (iso: string) => new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

/** Live, scheduled, expired or hidden. */
function status(c: CouponRecord, used: number) {
  const now = Date.now();
  if (!c.is_active) return { label: 'Hidden', cls: 'is-hidden' };
  if (c.expires_at && Date.parse(c.expires_at) < now) return { label: 'Expired', cls: 'is-hidden' };
  if (c.usage_limit != null && used >= c.usage_limit) return { label: 'Used up', cls: 'is-hidden' };
  if (c.starts_at && Date.parse(c.starts_at) > now) return { label: 'Scheduled', cls: 'is-pending' };
  return { label: 'Live', cls: 'is-live' };
}

// <input type="datetime-local"> works in local time without a zone.
const toLocalInput = (iso: string | null) => {
  if (!iso) return '';
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};
const fromLocalInput = (v: string) => (v ? new Date(v).toISOString() : null);

export const CouponsView: React.FC = () => {
  const [rows, setRows] = useState<CouponRecord[]>([]);
  const [uses, setUses] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<Filter>('all');
  const [editing, setEditing] = useState<{ row: CouponRecord; isNew: boolean } | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const [coupons, redemptions] = await Promise.all([
      supabase.from('coupons').select('*').order('created_at', { ascending: false }),
      supabase.from('coupon_redemptions').select('coupon_id'),
    ]);
    setError(coupons.error?.message ?? redemptions.error?.message ?? null);
    setRows((coupons.data as CouponRecord[]) ?? []);
    const counts: Record<string, number> = {};
    for (const r of (redemptions.data as { coupon_id: string }[]) ?? []) counts[r.coupon_id] = (counts[r.coupon_id] ?? 0) + 1;
    setUses(counts);
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  const q = query.trim().toLowerCase();
  const visible = rows.filter(
    (r) => (filter === 'all' || r.kind === filter) && `${r.code ?? ''} ${r.title} ${r.description}`.toLowerCase().includes(q),
  );

  const toggle = async (r: CouponRecord) => {
    const { error: err } = await supabase.from('coupons').update({ is_active: !r.is_active }).eq('id', r.id);
    if (err) return setError(err.message);
    setRows((prev) => prev.map((x) => (x.id === r.id ? { ...x, is_active: !r.is_active } : x)));
  };

  const remove = async (r: CouponRecord) => {
    const used = uses[r.id] ?? 0;
    const warn = used ? ` It has been used ${used} time${used === 1 ? '' : 's'}; that history will be deleted too. Hiding it keeps the history.` : '';
    if (!window.confirm(`Delete "${r.code ?? r.title}"?${warn}`)) return;
    const { error: err } = await supabase.from('coupons').delete().eq('id', r.id);
    if (err) return setError(err.message);
    setRows((prev) => prev.filter((x) => x.id !== r.id));
  };

  return (
    <div className="services-catalog-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Coupons &amp; Discounts</h1>
          <p className="view-subtitle">
            Coupon codes customers type at checkout, and automatic discounts applied for them. Signed-in customers only.
          </p>
        </div>
        <div className="catalog-header-actions">
          <button className="btn-sm-outline" onClick={() => void load()}>
            <RefreshCw size={13} /> Refresh
          </button>
          <button className="btn-sm-outline" onClick={() => setEditing({ row: { ...blank(), kind: 'discount', code: null }, isNew: true })}>
            <Plus size={14} /> New discount
          </button>
          <button className="btn-sm-primary" onClick={() => setEditing({ row: blank(), isNew: true })}>
            <Plus size={14} /> New coupon
          </button>
        </div>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      <div className="payouts-table-box">
        <div className="catalog-toolbar">
          <div className="catalog-chips">
            {(['all', 'coupon', 'discount'] as Filter[]).map((k) => (
              <button key={k} className={`catalog-chip ${filter === k ? 'active' : ''}`} onClick={() => setFilter(k)}>
                {k === 'all' ? `All (${rows.length})` : k === 'coupon' ? 'Coupon codes' : 'Automatic discounts'}
              </button>
            ))}
          </div>
          <label className="catalog-search">
            <Search size={14} />
            <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search code or name" />
          </label>
        </div>
        {loading ? (
          <div className="catalog-empty">Loading coupons…</div>
        ) : visible.length === 0 ? (
          <div className="catalog-empty">{rows.length ? 'Nothing matches.' : 'No coupons or discounts yet. Create one to get started.'}</div>
        ) : (
          <table className="custom-data-table">
            <thead>
              <tr>
                <th>Code / name</th>
                <th>Discount</th>
                <th>Conditions</th>
                <th>Valid</th>
                <th>Used</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {visible.map((r) => {
                const used = uses[r.id] ?? 0;
                const st = status(r, used);
                return (
                  <tr key={r.id} className={st.cls === 'is-live' || st.cls === 'is-pending' ? '' : 'catalog-row-hidden'}>
                    <td>
                      <div className="partner-name-bold">
                        {r.kind === 'coupon' ? <code>{r.code}</code> : 'Automatic'}
                        {r.kind === 'discount' && <span className="catalog-badge">No code</span>}
                      </div>
                      <div className="date-sub">{r.title}</div>
                    </td>
                    <td className="txn-id-bold">{valueLabel(r)}</td>
                    <td>
                      <div className="date-sub">{r.min_order > 0 ? `Min. order ${inr(r.min_order)}` : 'Any amount'}</div>
                      <div className="date-sub">
                        {r.applies_to.length ? r.applies_to.map((s) => SCOPES.find((x) => x.id === s)?.label.split(' (')[0] ?? s).join(', ') : 'All bookings'}
                      </div>
                      {r.first_booking_only && <div className="date-sub">New customers only</div>}
                    </td>
                    <td>
                      <div className="date-sub">{r.starts_at ? `From ${shortDate(r.starts_at)}` : 'From now'}</div>
                      <div className="date-sub">{r.expires_at ? `Until ${shortDate(r.expires_at)}` : 'No end date'}</div>
                    </td>
                    <td>
                      {used}
                      {r.usage_limit != null && ` / ${r.usage_limit}`}
                      {r.per_user_limit != null && <div className="date-sub">{r.per_user_limit} per customer</div>}
                    </td>
                    <td>
                      <span className={`catalog-status ${st.cls}`}>{st.label}</span>
                    </td>
                    <td>
                      <div className="catalog-row-actions">
                        <button className="btn-sm-outline" onClick={() => void toggle(r)} title={r.is_active ? 'Hide' : 'Show'}>
                          {r.is_active ? <EyeOff size={13} /> : <Eye size={13} />}
                        </button>
                        <button className="btn-sm-outline" onClick={() => void remove(r)} title="Delete">
                          <Trash2 size={13} />
                        </button>
                        <button className="btn-sm-outline" onClick={() => setEditing({ row: r, isNew: false })}>
                          <Pencil size={13} /> Edit
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {editing && (
        <CouponEditor
          initial={editing.row}
          isNew={editing.isNew}
          takenCodes={rows.filter((r) => r.id !== editing.row.id && r.code).map((r) => r.code!.toUpperCase())}
          onClose={() => setEditing(null)}
          onSaved={(saved) => {
            setRows((prev) => (editing.isNew ? [saved, ...prev] : prev.map((x) => (x.id === saved.id ? saved : x))));
            setEditing(null);
          }}
        />
      )}
    </div>
  );
};

const numOrNull = (v: string) => (v.trim() === '' ? null : Number(v));

const CouponEditor: React.FC<{
  initial: CouponRecord;
  isNew: boolean;
  takenCodes: string[];
  onClose: () => void;
  onSaved: (r: CouponRecord) => void;
}> = ({ initial, isNew, takenCodes, onClose, onSaved }) => {
  const [c, setC] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const set = <K extends keyof CouponRecord>(k: K, v: CouponRecord[K]) => setC((prev) => ({ ...prev, [k]: v }));

  const isCoupon = c.kind === 'coupon';
  const code = (c.code ?? '').trim().toUpperCase();
  const problem =
    isCoupon && !/^[A-Z0-9_-]{3,24}$/.test(code)
      ? 'Code: 3–24 letters, numbers, - or _'
      : isCoupon && takenCodes.includes(code)
        ? 'That code is already used'
        : !c.title.trim()
          ? 'Add a name customers will see'
          : !(c.discount_value > 0)
            ? 'Discount must be more than 0'
            : c.discount_type === 'percent' && c.discount_value > 100
              ? 'A percentage can’t be over 100'
              : c.starts_at && c.expires_at && Date.parse(c.starts_at) >= Date.parse(c.expires_at)
                ? 'End date must be after the start date'
                : null;

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (problem) return setError(problem);
    setBusy(true);
    const { id, created_at: _created, ...fields } = c;
    void _created;
    const payload = {
      ...fields,
      code: isCoupon ? code : null,
      title: c.title.trim(),
      description: c.description.trim(),
      max_discount: c.discount_type === 'percent' ? c.max_discount : null,
    };
    const query = isNew ? supabase.from('coupons').insert(payload) : supabase.from('coupons').update(payload).eq('id', id);
    const { data, error: err } = await query.select().single();
    setBusy(false);
    if (err) return setError(err.code === '23505' ? 'That code is already used' : err.message);
    onSaved(data as CouponRecord);
  };

  const toggleScope = (s: CouponScope) =>
    set('applies_to', c.applies_to.includes(s) ? c.applies_to.filter((x) => x !== s) : [...c.applies_to, s]);

  return (
    <div className="catalog-modal-backdrop" onClick={onClose}>
      <form className="catalog-modal" onClick={(e) => e.stopPropagation()} onSubmit={save}>
        <div className="catalog-modal-head">
          <h2>{isNew ? (isCoupon ? 'New coupon' : 'New automatic discount') : `Edit ${initial.code ?? initial.title}`}</h2>
          <button type="button" className="catalog-icon-btn" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>
        <div className="catalog-form-grid">
          <label className="catalog-field">
            <span>Type</span>
            <select value={c.kind} onChange={(e) => set('kind', e.target.value as CouponRecord['kind'])}>
              <option value="coupon">Coupon — customer enters a code</option>
              <option value="discount">Automatic discount — no code</option>
            </select>
            <small>{isCoupon ? 'Shown in the bill once the code is applied.' : 'The best matching discount is applied at checkout.'}</small>
          </label>
          {isCoupon ? (
            <label className="catalog-field">
              <span>Code</span>
              <input
                required
                value={c.code ?? ''}
                placeholder="FIRSTCARE"
                onChange={(e) => set('code', e.target.value.toUpperCase().replace(/\s/g, ''))}
              />
            </label>
          ) : (
            <span />
          )}
          <label className="catalog-field is-wide">
            <span>Name customers see</span>
            <input required value={c.title} placeholder="20% off your first booking" onChange={(e) => set('title', e.target.value)} />
          </label>
          <label className="catalog-field is-wide">
            <span>Internal note (optional)</span>
            <input value={c.description} placeholder="Diwali campaign, WhatsApp blast…" onChange={(e) => set('description', e.target.value)} />
          </label>

          <label className="catalog-field">
            <span>Discount method</span>
            <select value={c.discount_type} onChange={(e) => set('discount_type', e.target.value as CouponRecord['discount_type'])}>
              <option value="percent">Percentage off (%)</option>
              <option value="flat">Flat amount off (₹)</option>
            </select>
          </label>
          <label className="catalog-field">
            <span>{c.discount_type === 'percent' ? 'Percent off' : 'Amount off (₹)'}</span>
            <input
              type="number"
              min={1}
              max={c.discount_type === 'percent' ? 100 : undefined}
              step="1"
              required
              value={c.discount_value}
              onChange={(e) => set('discount_value', Number(e.target.value) || 0)}
            />
          </label>
          {c.discount_type === 'percent' && (
            <label className="catalog-field">
              <span>Maximum discount (₹, optional)</span>
              <input
                type="number"
                min={1}
                value={c.max_discount ?? ''}
                placeholder="No cap"
                onChange={(e) => set('max_discount', numOrNull(e.target.value))}
              />
            </label>
          )}
          <label className="catalog-field">
            <span>Minimum order (₹)</span>
            <input type="number" min={0} value={c.min_order} onChange={(e) => set('min_order', Number(e.target.value) || 0)} />
            <small>Checked against the service / rent price before fees and GST.</small>
          </label>

          <div className="catalog-field is-wide">
            <span>Works on</span>
            <div className="catalog-chips">
              <button
                type="button"
                className={`catalog-chip ${c.applies_to.length === 0 ? 'active' : ''}`}
                onClick={() => set('applies_to', [])}
              >
                Everything
              </button>
              {SCOPES.map((s) => (
                <button
                  key={s.id}
                  type="button"
                  className={`catalog-chip ${c.applies_to.includes(s.id) ? 'active' : ''}`}
                  onClick={() => toggleScope(s.id)}
                >
                  {s.label}
                </button>
              ))}
            </div>
          </div>

          <label className="catalog-field">
            <span>Starts (optional)</span>
            <input type="datetime-local" value={toLocalInput(c.starts_at)} onChange={(e) => set('starts_at', fromLocalInput(e.target.value))} />
          </label>
          <label className="catalog-field">
            <span>Ends (optional)</span>
            <input type="datetime-local" value={toLocalInput(c.expires_at)} onChange={(e) => set('expires_at', fromLocalInput(e.target.value))} />
          </label>
          <label className="catalog-field">
            <span>Total uses (optional)</span>
            <input
              type="number"
              min={1}
              value={c.usage_limit ?? ''}
              placeholder="Unlimited"
              onChange={(e) => set('usage_limit', numOrNull(e.target.value))}
            />
          </label>
          <label className="catalog-field">
            <span>Uses per customer (optional)</span>
            <input
              type="number"
              min={1}
              value={c.per_user_limit ?? ''}
              placeholder="Unlimited"
              onChange={(e) => set('per_user_limit', numOrNull(e.target.value))}
            />
          </label>
          <label className="catalog-check is-wide">
            <input type="checkbox" checked={c.first_booking_only} onChange={(e) => set('first_booking_only', e.target.checked)} />
            New customers only (customer has never used a coupon or discount before)
          </label>
          <label className="catalog-check is-wide">
            <input type="checkbox" checked={c.is_active} onChange={(e) => set('is_active', e.target.checked)} />
            Active on the website and app
          </label>
        </div>
        {error && <div className="catalog-notice is-error">{error}</div>}
        <div className="catalog-modal-actions">
          <button type="button" className="btn-sm-outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn-sm-primary" disabled={busy}>
            {busy ? 'Saving…' : isCoupon ? 'Save coupon' : 'Save discount'}
          </button>
        </div>
      </form>
    </div>
  );
};
