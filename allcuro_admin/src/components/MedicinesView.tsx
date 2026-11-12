import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Eye, EyeOff, Pencil, Plus, RefreshCw, Search, Trash2, X } from 'lucide-react';
import { supabase, type MedicineRecord } from '../lib/supabase';
import { inr, slugify } from '../lib/catalog';

// Order Medicines catalog (public.medicines): name, pack, MRP, selling price
// (the discount), prescription flag and category.

const blank = (sort: number): MedicineRecord => ({
  id: '',
  name: '',
  pack: '',
  category: '',
  mrp: 0,
  price: 0,
  rx: false,
  image_url: null,
  sort_order: sort,
  is_active: true,
});

const pctOff = (m: Pick<MedicineRecord, 'mrp' | 'price'>) => (m.mrp > 0 ? Math.round(((m.mrp - m.price) / m.mrp) * 100) : 0);

export const MedicinesView: React.FC = () => {
  const [rows, setRows] = useState<MedicineRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [editing, setEditing] = useState<{ row: MedicineRecord; isNew: boolean } | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const { data, error: err } = await supabase.from('medicines').select('*').order('sort_order');
    setError(err?.message ?? null);
    setRows((data as MedicineRecord[]) ?? []);
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  const categories = useMemo(() => [...new Set(rows.map((r) => r.category).filter(Boolean))], [rows]);
  const visible = rows.filter((r) => `${r.name} ${r.category} ${r.pack}`.toLowerCase().includes(query.trim().toLowerCase()));

  const toggle = async (r: MedicineRecord) => {
    const { error: err } = await supabase.from('medicines').update({ is_active: !r.is_active }).eq('id', r.id);
    if (err) return setError(err.message);
    setRows((prev) => prev.map((x) => (x.id === r.id ? { ...x, is_active: !r.is_active } : x)));
  };

  const remove = async (r: MedicineRecord) => {
    if (!window.confirm(`Delete "${r.name}"?`)) return;
    const { error: err } = await supabase.from('medicines').delete().eq('id', r.id);
    if (err) return setError(err.message);
    setRows((prev) => prev.filter((x) => x.id !== r.id));
  };

  return (
    <div className="services-catalog-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Medicines</h1>
          <p className="view-subtitle">Order Medicines catalog — MRP, selling price (discount) and prescription rules</p>
        </div>
        <div className="catalog-header-actions">
          <button className="btn-sm-outline" onClick={() => void load()}>
            <RefreshCw size={13} /> Refresh
          </button>
          <button
            className="btn-sm-primary"
            onClick={() => setEditing({ row: blank(rows.reduce((m, r) => Math.max(m, r.sort_order), 0) + 1), isNew: true })}
          >
            <Plus size={14} /> Add medicine
          </button>
        </div>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      <div className="payouts-table-box">
        <div className="catalog-toolbar">
          <span className="date-sub">{rows.length} medicines</span>
          <label className="catalog-search">
            <Search size={14} />
            <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search medicines" />
          </label>
        </div>
        {loading ? (
          <div className="catalog-empty">Loading medicines…</div>
        ) : visible.length === 0 ? (
          <div className="catalog-empty">No medicines found.</div>
        ) : (
          <table className="custom-data-table">
            <thead>
              <tr>
                <th>Medicine</th>
                <th>Category</th>
                <th>MRP</th>
                <th>Price</th>
                <th>Rx</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {visible.map((r) => (
                <tr key={r.id} className={r.is_active ? '' : 'catalog-row-hidden'}>
                  <td>
                    <div className="partner-name-bold">{r.name}</div>
                    <div className="date-sub">{r.pack}</div>
                  </td>
                  <td>{r.category}</td>
                  <td>{inr(r.mrp)}</td>
                  <td>
                    <div className="txn-id-bold">{inr(r.price)}</div>
                    {pctOff(r) > 0 && <div className="date-sub">{pctOff(r)}% off</div>}
                  </td>
                  <td>{r.rx ? 'Rx' : '—'}</td>
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
        <MedicineEditor
          initial={editing.row}
          isNew={editing.isNew}
          categories={categories}
          takenIds={rows.map((r) => r.id)}
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

const MedicineEditor: React.FC<{
  initial: MedicineRecord;
  isNew: boolean;
  categories: string[];
  takenIds: string[];
  onClose: () => void;
  onSaved: (r: MedicineRecord) => void;
}> = ({ initial, isNew, categories, takenIds, onClose, onSaved }) => {
  const [m, setM] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const set = <K extends keyof MedicineRecord>(k: K, v: MedicineRecord[K]) => setM((prev) => ({ ...prev, [k]: v }));
  const id = isNew ? slugify(m.name) : m.id;
  const taken = isNew && takenIds.includes(id);
  const priceError = m.price > m.mrp ? 'Selling price can’t be above MRP' : null;

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id || taken || priceError) return;
    setBusy(true);
    const { data, error: err } = await supabase
      .from('medicines')
      .upsert({ ...m, id })
      .select()
      .single();
    setBusy(false);
    if (err) return setError(err.message);
    onSaved(data as MedicineRecord);
  };

  return (
    <div className="catalog-modal-backdrop" onClick={onClose}>
      <form className="catalog-modal" onClick={(e) => e.stopPropagation()} onSubmit={save}>
        <div className="catalog-modal-head">
          <h2>{isNew ? 'Add medicine' : `Edit ${initial.name}`}</h2>
          <button type="button" className="catalog-icon-btn" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>
        <div className="catalog-form-grid">
          <label className="catalog-field">
            <span>Name</span>
            <input required value={m.name} onChange={(e) => set('name', e.target.value)} />
            <small className={taken ? 'is-error' : ''}>
              ID: <code>{id || '—'}</code>
              {taken && ' is already used'}
            </small>
          </label>
          <label className="catalog-field">
            <span>Pack</span>
            <input value={m.pack} placeholder="Strip of 15 tablets" onChange={(e) => set('pack', e.target.value)} />
          </label>
          <label className="catalog-field">
            <span>Category</span>
            <input list="med-categories" value={m.category} onChange={(e) => set('category', e.target.value)} />
            <datalist id="med-categories">
              {categories.map((c) => (
                <option key={c} value={c} />
              ))}
            </datalist>
          </label>
          <label className="catalog-field">
            <span>MRP (₹)</span>
            <input type="number" min={0} step="0.01" required value={m.mrp} onChange={(e) => set('mrp', Number(e.target.value) || 0)} />
          </label>
          <label className="catalog-field">
            <span>Selling price (₹)</span>
            <input type="number" min={0} step="0.01" required value={m.price} onChange={(e) => set('price', Number(e.target.value) || 0)} />
            <small className={priceError ? 'is-error' : ''}>{priceError ?? `${pctOff(m)}% off MRP`}</small>
          </label>
          <label className="catalog-field">
            <span>Sort order</span>
            <input type="number" value={m.sort_order} onChange={(e) => set('sort_order', Number(e.target.value))} />
          </label>
          <label className="catalog-check">
            <input type="checkbox" checked={m.rx} onChange={(e) => set('rx', e.target.checked)} />
            Prescription required
          </label>
          <label className="catalog-check">
            <input type="checkbox" checked={m.is_active} onChange={(e) => set('is_active', e.target.checked)} />
            Live on the website and app
          </label>
        </div>
        {error && <div className="catalog-notice is-error">{error}</div>}
        <div className="catalog-modal-actions">
          <button type="button" className="btn-sm-outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn-sm-primary" disabled={busy || !id || taken || !!priceError}>
            {busy ? 'Saving…' : 'Save medicine'}
          </button>
        </div>
      </form>
    </div>
  );
};
