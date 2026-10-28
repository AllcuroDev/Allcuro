import React, { useState } from 'react';
import { X } from 'lucide-react';
import { supabase, type ServiceCategoryRecord } from '../../lib/supabase';
import { removeCatalogImage, slugify } from '../../lib/catalog';
import { ImageField } from './ImageField';

interface CategoryEditorProps {
  initial: ServiceCategoryRecord;
  isNew: boolean;
  takenIds: string[];
  takenSlugs: string[];
  onClose: () => void;
  onSaved: (c: ServiceCategoryRecord) => void;
}

export const CategoryEditor: React.FC<CategoryEditorProps> = ({
  initial,
  isNew,
  takenIds,
  takenSlugs,
  onClose,
  onSaved,
}) => {
  const [c, setC] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const set = <K extends keyof ServiceCategoryRecord>(key: K, value: ServiceCategoryRecord[K]) =>
    setC((prev) => ({ ...prev, [key]: value }));

  // New categories take their ID from the label; existing IDs stay fixed
  // because services point at them.
  const id = isNew ? c.label.trim() : c.id;
  const idTaken = isNew && takenIds.includes(id);
  const slugTaken = c.slug !== initial.slug && takenSlugs.includes(c.slug);

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id || idTaken || slugTaken) return;
    setBusy(true);
    const { data, error: err } = await supabase
      .from('service_categories')
      .upsert({ ...c, id })
      .select()
      .single();
    setBusy(false);
    if (err) return setError(err.message);
    if (initial.image_url !== c.image_url) void removeCatalogImage(initial.image_url);
    onSaved(data as ServiceCategoryRecord);
  };

  const text = (key: 'label' | 'icon' | 'art', label: string, placeholder = '') => (
    <label className="catalog-field">
      <span>{label}</span>
      <input
        required={key === 'label'}
        value={c[key]}
        placeholder={placeholder}
        onChange={(e) => {
          set(key, e.target.value);
          if (key === 'label' && isNew) set('slug', slugify(e.target.value));
        }}
      />
      {key === 'label' && (
        <small className={idTaken ? 'is-error' : ''}>
          ID: <code>{id || '—'}</code>
          {idTaken ? ' is already used' : !isNew && ' (fixed — services link to it)'}
        </small>
      )}
    </label>
  );

  const colour = (key: 'ink' | 'wash', label: string) => (
    <label className="catalog-field">
      <span>{label}</span>
      <div className="catalog-colour">
        <input type="color" value={c[key]} onChange={(e) => set(key, e.target.value.toUpperCase())} />
        <input value={c[key]} onChange={(e) => set(key, e.target.value)} pattern="#[0-9A-Fa-f]{6}" />
      </div>
    </label>
  );

  return (
    <div className="catalog-modal-backdrop" onClick={onClose}>
      <form className="catalog-modal" onClick={(e) => e.stopPropagation()} onSubmit={save}>
        <div className="catalog-modal-head">
          <h2>{isNew ? 'Add category' : `Edit ${initial.label}`}</h2>
          <button type="button" className="catalog-icon-btn" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>

        <div className="catalog-form-grid">
          <ImageField
            label="Logo"
            hint="Square PNG/WebP, 256×256, under 512 KB. Overrides the illustration key."
            folder="categories"
            name={slugify(id)}
            value={c.image_url}
            onChange={(url) => set('image_url', url)}
            onBusy={setBusy}
          />
          {text('label', 'Name', 'Nursing Care')}
          <label className="catalog-field">
            <span>URL slug</span>
            <input
              required
              value={c.slug}
              onChange={(e) => set('slug', slugify(e.target.value))}
            />
            <small className={slugTaken ? 'is-error' : ''}>
              {slugTaken ? 'Another category uses this slug' : `/services/${c.slug || '…'}`}
            </small>
          </label>
          <label className="catalog-field is-wide">
            <span>Short description</span>
            <textarea rows={2} value={c.blurb} onChange={(e) => set('blurb', e.target.value)} />
          </label>
          <label className="catalog-field is-wide">
            <span>Opens a page instead (optional)</span>
            <input
              value={c.href ?? ''}
              placeholder="/centres"
              onChange={(e) => set('href', e.target.value.trim() || null)}
            />
            <small>Leave empty to show this category&rsquo;s services. Care Centres uses /centres.</small>
          </label>
          {text('icon', 'Icon key', 'nursing, elder_care…')}
          {text('art', 'Illustration key', 'nursing, caregiver…')}
          {colour('ink', 'Icon colour')}
          {colour('wash', 'Tile background')}
          <label className="catalog-field">
            <span>Sort order</span>
            <input
              type="number"
              value={c.sort_order}
              onChange={(e) => set('sort_order', Number(e.target.value))}
            />
          </label>
          <div className="catalog-field">
            <span>Preview</span>
            <div className="catalog-tile-preview" style={{ background: c.wash, color: c.ink }}>
              {c.image_url ? <img src={c.image_url} alt="" /> : c.label.slice(0, 2)}
            </div>
          </div>
          <label className="catalog-check is-wide">
            <input
              type="checkbox"
              checked={c.is_active}
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
          <button className="btn-sm-primary" disabled={busy || !id || idTaken || slugTaken}>
            {busy ? 'Saving…' : 'Save category'}
          </button>
        </div>
      </form>
    </div>
  );
};
