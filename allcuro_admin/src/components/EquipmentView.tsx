import React, { useCallback, useEffect, useState } from 'react';
import { Eye, EyeOff, Pencil, Plus, RefreshCw, Trash2, X } from 'lucide-react';
import { supabase, type EquipmentRecord } from '../lib/supabase';
import { afterDiscount, inr, slugify } from '../lib/catalog';
import { ImageField } from './catalog/ImageField';

// Rental equipment shown on /equipment on the website and in the app
// (public.equipment). Everything — title, photo, rates, deposit, discount,
// stock — is edited here.

const CATEGORIES = ['Mobility', 'Respiratory', 'Hospital furniture', 'Monitoring', 'ICU-grade'];
const CONDITIONS = ['New', 'Refurbished · Grade A', 'Refurbished · Grade B'];

const blank = (sort: number): EquipmentRecord => ({
  id: '',
  slug: '',
  title: '',
  category: CATEGORIES[0],
  condition: CONDITIONS[0],
  description: '',
  features: [],
  daily_rate: 0,
  monthly_rate: 0,
  deposit_amount: 0,
  discount_percent: 0,
  stock_quantity: 1,
  photo_url: null,
  available_pincodes: '',
  is_available: true,
  is_active: true,
  sort_order: sort,
});

export const EquipmentView: React.FC = () => {
  const [rows, setRows] = useState<EquipmentRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<{ row: EquipmentRecord; isNew: boolean } | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const { data, error: err } = await supabase.from('equipment').select('*').order('sort_order');
    setError(err?.message ?? null);
    setRows((data as EquipmentRecord[]) ?? []);
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  const toggle = async (r: EquipmentRecord) => {
    const { error: err } = await supabase.from('equipment').update({ is_active: !r.is_active }).eq('id', r.id);
    if (err) return setError(err.message);
    setRows((prev) => prev.map((x) => (x.id === r.id ? { ...x, is_active: !r.is_active } : x)));
  };

  const remove = async (r: EquipmentRecord) => {
    if (!window.confirm(`Delete "${r.title}"? Hide it instead to keep its booking history readable.`)) return;
    const { error: err } = await supabase.from('equipment').delete().eq('id', r.id);
    if (err) return setError(err.message);
    setRows((prev) => prev.filter((x) => x.id !== r.id));
  };

  return (
    <div className="services-catalog-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Equipment on Rent</h1>
          <p className="view-subtitle">Rental catalog on the website and customer app — rates, deposits, discounts and stock</p>
        </div>
        <div className="catalog-header-actions">
          <button className="btn-sm-outline" onClick={() => void load()}>
            <RefreshCw size={13} /> Refresh
          </button>
          <button
            className="btn-sm-primary"
            onClick={() => setEditing({ row: blank(rows.reduce((m, r) => Math.max(m, r.sort_order), 0) + 1), isNew: true })}
          >
            <Plus size={14} /> Add equipment
          </button>
        </div>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      <div className="payouts-table-box">
        {loading ? (
          <div className="catalog-empty">Loading equipment…</div>
        ) : rows.length === 0 ? (
          <div className="catalog-empty">No equipment yet. Run supabase/marketplace.sql to seed it, or add one.</div>
        ) : (
          <table className="custom-data-table">
            <thead>
              <tr>
                <th>Photo</th>
                <th>Equipment</th>
                <th>Per day</th>
                <th>Per month</th>
                <th>Deposit</th>
                <th>Stock</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id} className={r.is_active ? '' : 'catalog-row-hidden'}>
                  <td>{r.photo_url ? <img className="catalog-thumb" src={r.photo_url} alt="" /> : '—'}</td>
                  <td>
                    <div className="partner-name-bold">{r.title}</div>
                    <div className="date-sub">
                      {r.category} · {r.condition}
                    </div>
                  </td>
                  <td>
                    <div className="txn-id-bold">{inr(afterDiscount(r.daily_rate, r.discount_percent))}</div>
                    {Number(r.discount_percent) > 0 && (
                      <div className="date-sub">
                        <s>{inr(r.daily_rate)}</s> · {Number(r.discount_percent)}% off
                      </div>
                    )}
                  </td>
                  <td>{inr(afterDiscount(r.monthly_rate, r.discount_percent))}</td>
                  <td>{inr(r.deposit_amount)}</td>
                  <td>{r.stock_quantity}</td>
                  <td>
                    <span className={`catalog-status ${r.is_active ? 'is-live' : 'is-hidden'}`}>{r.is_active ? 'Live' : 'Hidden'}</span>
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
              ))}
            </tbody>
          </table>
        )}
      </div>

      {editing && (
        <EquipmentEditor
          initial={editing.row}
          isNew={editing.isNew}
          onClose={() => setEditing(null)}
          onSaved={(saved) => {
            setRows((prev) =>
              (editing.isNew ? [...prev, saved] : prev.map((x) => (x.id === saved.id ? saved : x))).sort((a, b) => a.sort_order - b.sort_order),
            );
            setEditing(null);
          }}
        />
      )}
    </div>
  );
};

const EquipmentEditor: React.FC<{
  initial: EquipmentRecord;
  isNew: boolean;
  onClose: () => void;
  onSaved: (r: EquipmentRecord) => void;
}> = ({ initial, isNew, onClose, onSaved }) => {
  const [r, setR] = useState(initial);
  const [features, setFeatures] = useState(initial.features.join('\n'));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const set = <K extends keyof EquipmentRecord>(k: K, v: EquipmentRecord[K]) => setR((prev) => ({ ...prev, [k]: v }));

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    const { id, ...rest } = r;
    const row = {
      ...rest,
      slug: r.slug || slugify(r.title),
      features: features
        .split('\n')
        .map((x) => x.trim())
        .filter(Boolean),
    };
    const q = isNew ? supabase.from('equipment').insert(row) : supabase.from('equipment').update(row).eq('id', id);
    const { data, error: err } = await q.select().single();
    setBusy(false);
    if (err) return setError(err.message.includes('equipment_slug_uniq') ? 'Another item already uses this URL slug.' : err.message);
    onSaved(data as EquipmentRecord);
  };

  const money = (k: 'daily_rate' | 'monthly_rate' | 'deposit_amount', label: string) => (
    <label className="catalog-field">
      <span>{label}</span>
      <input type="number" min={0} required value={r[k]} onChange={(e) => set(k, Number(e.target.value) || 0)} />
    </label>
  );

  return (
    <div className="catalog-modal-backdrop" onClick={onClose}>
      <form className="catalog-modal" onClick={(e) => e.stopPropagation()} onSubmit={save}>
        <div className="catalog-modal-head">
          <h2>{isNew ? 'Add equipment' : `Edit ${initial.title}`}</h2>
          <button type="button" className="catalog-icon-btn" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>
        <div className="catalog-form-grid">
          <ImageField
            label="Photo"
            hint="Landscape JPG/WebP, under 1 MB."
            folder="equipment"
            name={r.slug || slugify(r.title)}
            bucket="equipment-images"
            maxKb={1024}
            value={r.photo_url}
            onChange={(url) => set('photo_url', url)}
            onBusy={setBusy}
          />
          <label className="catalog-field">
            <span>Title</span>
            <input required value={r.title} onChange={(e) => set('title', e.target.value)} />
            <small>
              URL: /equipment/{r.slug || slugify(r.title) || '…'}/rent
            </small>
          </label>
          <label className="catalog-field">
            <span>Category</span>
            <input list="eq-categories" value={r.category} onChange={(e) => set('category', e.target.value)} />
            <datalist id="eq-categories">
              {CATEGORIES.map((c) => (
                <option key={c} value={c} />
              ))}
            </datalist>
          </label>
          <label className="catalog-field">
            <span>Condition</span>
            <input list="eq-conditions" value={r.condition} onChange={(e) => set('condition', e.target.value)} />
            <datalist id="eq-conditions">
              {CONDITIONS.map((c) => (
                <option key={c} value={c} />
              ))}
            </datalist>
          </label>
          <label className="catalog-field is-wide">
            <span>Description</span>
            <textarea rows={2} value={r.description} onChange={(e) => set('description', e.target.value)} />
          </label>
          <label className="catalog-field is-wide">
            <span>Features (one per line)</span>
            <textarea rows={3} value={features} onChange={(e) => setFeatures(e.target.value)} />
          </label>
          {money('daily_rate', 'Daily rate (₹)')}
          {money('monthly_rate', 'Monthly rate (₹)')}
          {money('deposit_amount', 'Refundable deposit (₹)')}
          <label className="catalog-field">
            <span>Discount %</span>
            <input
              type="number"
              min={0}
              max={100}
              step="0.5"
              value={r.discount_percent}
              onChange={(e) => set('discount_percent', Math.min(100, Math.max(0, Number(e.target.value) || 0)))}
            />
            <small>
              Families pay {inr(afterDiscount(r.daily_rate, r.discount_percent))}/day · {inr(afterDiscount(r.monthly_rate, r.discount_percent))}
              /month
            </small>
          </label>
          <label className="catalog-field">
            <span>Stock</span>
            <input type="number" min={0} value={r.stock_quantity} onChange={(e) => set('stock_quantity', Number(e.target.value) || 0)} />
          </label>
          <label className="catalog-field">
            <span>Delivers to pincodes</span>
            <input value={r.available_pincodes} placeholder="560076, 560038" onChange={(e) => set('available_pincodes', e.target.value)} />
          </label>
          <label className="catalog-field">
            <span>Sort order</span>
            <input type="number" value={r.sort_order} onChange={(e) => set('sort_order', Number(e.target.value))} />
          </label>
          <label className="catalog-check">
            <input type="checkbox" checked={r.is_available} onChange={(e) => set('is_available', e.target.checked)} />
            In stock / rentable
          </label>
          <label className="catalog-check">
            <input type="checkbox" checked={r.is_active} onChange={(e) => set('is_active', e.target.checked)} />
            Live on the website and app
          </label>
        </div>
        {error && <div className="catalog-notice is-error">{error}</div>}
        <div className="catalog-modal-actions">
          <button type="button" className="btn-sm-outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn-sm-primary" disabled={busy || !r.title.trim()}>
            {busy ? 'Saving…' : 'Save equipment'}
          </button>
        </div>
      </form>
    </div>
  );
};
