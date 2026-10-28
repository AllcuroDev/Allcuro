import React, { useState } from 'react';
import { X } from 'lucide-react';
import { supabase, type ServiceCategoryRecord, type ServiceRecord } from '../../lib/supabase';
import { priceFrom, removeCatalogImage, slugify } from '../../lib/catalog';
import { ImageField } from './ImageField';

const BADGES = ['', 'Popular', 'Value', 'Advanced', 'High Skill'];

interface ServiceEditorProps {
  initial: ServiceRecord;
  isNew: boolean;
  categories: ServiceCategoryRecord[];
  takenIds: string[];
  onClose: () => void;
  onSaved: (s: ServiceRecord) => void;
}

export const ServiceEditor: React.FC<ServiceEditorProps> = ({
  initial,
  isNew,
  categories,
  takenIds,
  onClose,
  onSaved,
}) => {
  const [s, setS] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const set = <K extends keyof ServiceRecord>(key: K, value: ServiceRecord[K]) =>
    setS((prev) => ({ ...prev, [key]: value }));

  // Existing IDs stay fixed: the website, apps and bookings link to them.
  const id = isNew ? slugify(s.name) : s.id;
  const idTaken = isNew && takenIds.includes(id);

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id || idTaken) return;
    setBusy(true);
    const row: ServiceRecord = {
      ...s,
      id,
      price_from: priceFrom(s.price),
      extra_category_ids: s.extra_category_ids.filter((c) => c !== s.category_id),
    };
    const { data, error: err } = await supabase.from('services').upsert(row).select().single();
    setBusy(false);
    if (err) return setError(err.message);
    if (initial.image_url !== s.image_url) void removeCatalogImage(initial.image_url);
    onSaved(data as ServiceRecord);
  };

  type TextKey = Exclude<
    keyof ServiceRecord,
    'price_from' | 'image_url' | 'sort_order' | 'is_active' | 'extra_category_ids'
  >;

  const text = (key: TextKey, label: string, placeholder = '') => (
    <label className="catalog-field">
      <span>{label}</span>
      <input value={s[key]} placeholder={placeholder} onChange={(e) => set(key, e.target.value)} />
    </label>
  );

  const area = (key: TextKey, label: string, placeholder = '') => (
    <label className="catalog-field is-wide">
      <span>{label}</span>
      <textarea
        rows={2}
        value={s[key]}
        placeholder={placeholder}
        onChange={(e) => set(key, e.target.value)}
      />
    </label>
  );

  return (
    <div className="catalog-modal-backdrop" onClick={onClose}>
      <form className="catalog-modal" onClick={(e) => e.stopPropagation()} onSubmit={save}>
        <div className="catalog-modal-head">
          <h2>{isNew ? 'Add service' : `Edit ${initial.name}`}</h2>
          <button type="button" className="catalog-icon-btn" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>

        <div className="catalog-form-grid">
          <ImageField
            label="Logo"
            hint="Square PNG/WebP, 256×256, under 512 KB. Overrides the icon key."
            folder="services"
            name={id}
            value={s.image_url}
            onChange={(url) => set('image_url', url)}
            onBusy={setBusy}
          />
          <label className="catalog-field">
            <span>Name</span>
            <input required value={s.name} onChange={(e) => set('name', e.target.value)} />
            <small className={idTaken ? 'is-error' : ''}>
              ID: <code>{id || '—'}</code>
              {idTaken ? ' is already used' : !isNew && ' (fixed — bookings link to it)'}
            </small>
          </label>
          <label className="catalog-field">
            <span>Category</span>
            <select value={s.category_id} onChange={(e) => set('category_id', e.target.value)}>
              {categories.filter((c) => !c.href).map((c) => (
                <option key={c.id} value={c.id}>
                  {c.label}
                </option>
              ))}
            </select>
          </label>
          <div className="catalog-field is-wide">
            <span>Also show in</span>
            <div className="catalog-chips">
              {categories
                .filter((c) => c.id !== s.category_id && !c.href)
                .map((c) => {
                  const on = s.extra_category_ids.includes(c.id);
                  return (
                    <button
                      key={c.id}
                      type="button"
                      className={`catalog-chip ${on ? 'active' : ''}`}
                      aria-pressed={on}
                      onClick={() =>
                        set(
                          'extra_category_ids',
                          on ? s.extra_category_ids.filter((x) => x !== c.id) : [...s.extra_category_ids, c.id],
                        )
                      }
                    >
                      {c.label}
                    </button>
                  );
                })}
            </div>
            <small>The service stays in its main category and is also listed in these.</small>
          </div>
          {text('subcategory', 'Subcategory', 'Personal Care')}
          {text('professional', 'Professional', 'Nurse')}
          <label className="catalog-field">
            <span>Price (as shown)</span>
            <input
              required
              value={s.price}
              placeholder="₹699 or ₹699–999 or ₹999+"
              onChange={(e) => set('price', e.target.value)}
            />
            <small>Sorts as ₹{priceFrom(s.price) ?? '—'}</small>
          </label>
          {text('duration', 'Duration', '30–45 min')}
          {area('description', 'Description')}
          {area('includes', 'Includes', 'Separate items with ;')}
          {area('not_included', 'Not included', 'Separate items with ;')}
          {text('notes', 'Notes', 'Materials extra')}
          <label className="catalog-field">
            <span>Badge</span>
            <select value={s.badge} onChange={(e) => set('badge', e.target.value)}>
              {BADGES.map((b) => (
                <option key={b} value={b}>
                  {b || 'None'}
                </option>
              ))}
            </select>
          </label>
          {text('icon', 'Icon key', 'bath, injection, vitals…')}
          <label className="catalog-field">
            <span>Sort order</span>
            <input
              type="number"
              value={s.sort_order}
              onChange={(e) => set('sort_order', Number(e.target.value))}
            />
          </label>
          <label className="catalog-check is-wide">
            <input
              type="checkbox"
              checked={s.is_active}
              onChange={(e) => set('is_active', e.target.checked)}
            />
            Live on the website and apps
          </label>
        </div>

        {error && <div className="catalog-notice is-error">{error}</div>}

        <div className="catalog-modal-actions">
          <button type="button" className="btn-sm-outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn-sm-primary" disabled={busy || !id || idTaken}>
            {busy ? 'Saving…' : 'Save service'}
          </button>
        </div>
      </form>
    </div>
  );
};
