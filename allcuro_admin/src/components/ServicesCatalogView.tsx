import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { ChevronRight, Eye, EyeOff, Pencil, Plus, RefreshCw, Search, Trash2 } from 'lucide-react';
import { supabase, type ServiceCategoryRecord, type ServiceRecord } from '../lib/supabase';
import { removeCatalogImage } from '../lib/catalog';
import { CategoryEditor } from './catalog/CategoryEditor';
import { ServiceEditor } from './catalog/ServiceEditor';

// The public services catalog shown on the website and both apps. The admin
// shell only renders this for signed-in admins, so every action here is
// allowed by RLS (see supabase/services.sql).

type Tab = 'categories' | 'services';

const newCategory = (sortOrder: number): ServiceCategoryRecord => ({
  id: '',
  slug: '',
  label: '',
  blurb: '',
  href: null,
  icon: '',
  art: '',
  ink: '#26593B',
  wash: '#E7F4EB',
  image_url: null,
  sort_order: sortOrder,
  is_active: true,
});

const newService = (categoryId: string, sortOrder: number): ServiceRecord => ({
  id: '',
  name: '',
  category_id: categoryId,
  extra_category_ids: [],
  subcategory: '',
  description: '',
  includes: '',
  not_included: '',
  duration: '',
  professional: '',
  price: '',
  price_from: null,
  notes: '',
  badge: '',
  icon: '',
  image_url: null,
  sort_order: sortOrder,
  is_active: true,
});

const nextOrder = (rows: { sort_order: number }[]) =>
  rows.reduce((max, r) => Math.max(max, r.sort_order), 0) + 1;

export const ServicesCatalogView: React.FC = () => {
  const [tab, setTab] = useState<Tab>('categories');
  const [categories, setCategories] = useState<ServiceCategoryRecord[]>([]);
  const [services, setServices] = useState<ServiceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [query, setQuery] = useState('');
  const [editingCategory, setEditingCategory] = useState<{ row: ServiceCategoryRecord; isNew: boolean } | null>(null);
  const [editingService, setEditingService] = useState<{ row: ServiceRecord; isNew: boolean } | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const [cats, svcs] = await Promise.all([
      supabase.from('service_categories').select('*').order('sort_order'),
      supabase.from('services').select('*').order('sort_order'),
    ]);
    setError(cats.error?.message ?? svcs.error?.message ?? null);
    setCategories((cats.data as ServiceCategoryRecord[]) ?? []);
    setServices((svcs.data as ServiceRecord[]) ?? []);
    setLoading(false);
  }, []);

  useEffect(() => {
    // Fetch on mount; setState happens after the request resolves.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  const countByCategory = useMemo(() => {
    const counts: Record<string, number> = {};
    services.forEach((s) =>
      [s.category_id, ...(s.extra_category_ids ?? [])].forEach((id) => (counts[id] = (counts[id] ?? 0) + 1)),
    );
    return counts;
  }, [services]);

  const visibleServices = useMemo(() => {
    const q = query.trim().toLowerCase();
    return services.filter(
      (s) =>
        (categoryFilter === 'all' ||
          s.category_id === categoryFilter ||
          s.extra_category_ids?.includes(categoryFilter)) &&
        (!q || `${s.name} ${s.subcategory} ${s.id} ${s.professional}`.toLowerCase().includes(q)),
    );
  }, [services, categoryFilter, query]);

  const categoryLabel = (id: string) => categories.find((c) => c.id === id)?.label ?? id;

  const toggleCategory = async (c: ServiceCategoryRecord) => {
    const { error: err } = await supabase
      .from('service_categories')
      .update({ is_active: !c.is_active })
      .eq('id', c.id);
    if (err) return setError(err.message);
    setCategories((prev) => prev.map((x) => (x.id === c.id ? { ...x, is_active: !c.is_active } : x)));
  };

  const deleteCategory = async (c: ServiceCategoryRecord) => {
    if (!window.confirm(`Delete the category "${c.label}"? This can't be undone.`)) return;
    // Drop it from services that only list it as an extra category first.
    const shared = services.filter((s) => s.extra_category_ids?.includes(c.id));
    for (const s of shared) {
      const extra = s.extra_category_ids.filter((x) => x !== c.id);
      const { error: e } = await supabase.from('services').update({ extra_category_ids: extra }).eq('id', s.id);
      if (e) return setError(e.message);
    }
    setServices((prev) =>
      prev.map((s) => ({ ...s, extra_category_ids: (s.extra_category_ids ?? []).filter((x) => x !== c.id) })),
    );
    const { error: err } = await supabase.from('service_categories').delete().eq('id', c.id);
    if (err) return setError(err.message);
    void removeCatalogImage(c.image_url);
    setCategories((prev) => prev.filter((x) => x.id !== c.id));
  };

  const toggleService = async (s: ServiceRecord) => {
    const { error: err } = await supabase
      .from('services')
      .update({ is_active: !s.is_active })
      .eq('id', s.id);
    if (err) return setError(err.message);
    setServices((prev) => prev.map((x) => (x.id === s.id ? { ...x, is_active: !s.is_active } : x)));
  };

  const deleteService = async (s: ServiceRecord) => {
    if (!window.confirm(`Delete "${s.name}"? To take it off the site temporarily, hide it instead.`)) return;
    const { error: err } = await supabase.from('services').delete().eq('id', s.id);
    if (err) return setError(err.message);
    void removeCatalogImage(s.image_url);
    setServices((prev) => prev.filter((x) => x.id !== s.id));
  };

  const openCategoryServices = (id: string) => {
    setCategoryFilter(id);
    setQuery('');
    setTab('services');
  };

  return (
    <div className="services-catalog-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Services Catalog</h1>
          <p className="view-subtitle">
            Categories and services shown on allcuro.care and in the customer app — changes go live on
            next load
          </p>
        </div>
        <div className="catalog-header-actions">
          <button className="btn-sm-outline" onClick={() => void load()} title="Reload from Supabase">
            <RefreshCw size={13} /> Refresh
          </button>
          {tab === 'categories' ? (
            <button
              className="btn-sm-primary"
              onClick={() => setEditingCategory({ row: newCategory(nextOrder(categories)), isNew: true })}
            >
              <Plus size={14} /> Add category
            </button>
          ) : (
            <button
              className="btn-sm-primary"
              disabled={categories.length === 0}
              onClick={() =>
                setEditingService({
                  row: newService(
                    categoryFilter === 'all' || categories.find((c) => c.id === categoryFilter)?.href
                      ? (categories.find((c) => !c.href)?.id ?? '')
                      : categoryFilter,
                    nextOrder(services),
                  ),
                  isNew: true,
                })
              }
            >
              <Plus size={14} /> Add service
            </button>
          )}
        </div>
      </div>

      <div className="catalog-tabs" role="tablist">
        <button
          role="tab"
          aria-selected={tab === 'categories'}
          className={`catalog-tab ${tab === 'categories' ? 'active' : ''}`}
          onClick={() => setTab('categories')}
        >
          Categories <span className="catalog-tab-count">{categories.length}</span>
        </button>
        <button
          role="tab"
          aria-selected={tab === 'services'}
          className={`catalog-tab ${tab === 'services' ? 'active' : ''}`}
          onClick={() => setTab('services')}
        >
          Services <span className="catalog-tab-count">{services.length}</span>
        </button>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}

      {loading ? (
        <div className="payouts-table-box catalog-empty">Loading catalog…</div>
      ) : tab === 'categories' ? (
        <div className="catalog-category-grid">
          {categories.length === 0 && (
            <div className="payouts-table-box catalog-empty">
              No categories yet — run supabase/services.sql or add one.
            </div>
          )}
          {categories.map((c) => {
            const count = countByCategory[c.id] ?? 0;
            const ownCount = services.filter((s) => s.category_id === c.id).length;
            return (
              <div key={c.id} className={`catalog-category-card ${c.is_active ? '' : 'is-hidden'}`}>
                <div className="catalog-category-top">
                  <div className="catalog-tile-preview" style={{ background: c.wash, color: c.ink }}>
                    {c.image_url ? <img src={c.image_url} alt="" /> : c.label.slice(0, 2)}
                  </div>
                  <div className="catalog-category-text">
                    <div className="partner-name-bold">{c.label}</div>
                    <div className="date-sub">
                      /services/{c.slug} · <span className="code-subaccount">{c.id}</span>
                    </div>
                  </div>
                  <span className={`catalog-status ${c.is_active ? 'is-live' : 'is-hidden'}`}>
                    {c.is_active ? 'Live' : 'Hidden'}
                  </span>
                </div>
                <p className="catalog-category-blurb">{c.blurb || 'No description.'}</p>
                <div className="catalog-category-actions">
                  {c.href ? (
                    <span className="date-sub">
                      Opens <span className="code-subaccount">{c.href}</span>
                    </span>
                  ) : (
                    <button className="catalog-link-btn" onClick={() => openCategoryServices(c.id)}>
                      {count} {count === 1 ? 'service' : 'services'} <ChevronRight size={14} />
                    </button>
                  )}
                  <div className="catalog-row-actions">
                    <button
                      className="btn-sm-outline"
                      title={c.is_active ? 'Hide from website and apps' : 'Show on website and apps'}
                      onClick={() => toggleCategory(c)}
                    >
                      {c.is_active ? <EyeOff size={13} /> : <Eye size={13} />}
                    </button>
                    <button
                      className="btn-sm-outline"
                      title={ownCount ? 'Move or delete its services first' : 'Delete category'}
                      disabled={ownCount > 0}
                      onClick={() => deleteCategory(c)}
                    >
                      <Trash2 size={13} />
                    </button>
                    <button className="btn-sm-outline" onClick={() => setEditingCategory({ row: c, isNew: false })}>
                      <Pencil size={13} /> Edit
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="payouts-table-box">
          <div className="catalog-toolbar">
            <div className="catalog-chips">
              {[{ id: 'all', label: 'All' }, ...categories].map((c) => (
                <button
                  key={c.id}
                  className={`catalog-chip ${categoryFilter === c.id ? 'active' : ''}`}
                  onClick={() => setCategoryFilter(c.id)}
                >
                  {c.label}
                </button>
              ))}
            </div>
            <label className="catalog-search">
              <Search size={14} />
              <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search services" />
            </label>
          </div>

          {visibleServices.length === 0 ? (
            <div className="catalog-empty">No services found.</div>
          ) : (
            <table className="custom-data-table">
              <thead>
                <tr>
                  <th>Logo</th>
                  <th>Service</th>
                  <th>Category</th>
                  <th>Professional</th>
                  <th>Price</th>
                  <th>Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {visibleServices.map((s) => (
                  <tr key={s.id} className={s.is_active ? '' : 'catalog-row-hidden'}>
                    <td>
                      {s.image_url ? (
                        <img className="catalog-thumb" src={s.image_url} alt="" />
                      ) : (
                        <span className="code-subaccount" title="Bundled icon key">
                          {s.icon || '—'}
                        </span>
                      )}
                    </td>
                    <td>
                      <div className="partner-name-bold">{s.name}</div>
                      <div className="date-sub">
                        {s.subcategory} · <span className="code-subaccount">{s.id}</span>
                      </div>
                    </td>
                    <td>
                      {categoryLabel(s.category_id)}
                      {s.extra_category_ids?.length > 0 && (
                        <div className="date-sub">+ {s.extra_category_ids.map(categoryLabel).join(', ')}</div>
                      )}
                    </td>
                    <td>{s.professional}</td>
                    <td>
                      <div className="txn-id-bold">{s.price}</div>
                      <div className="date-sub">{s.duration}</div>
                    </td>
                    <td>
                      <span className={`catalog-status ${s.is_active ? 'is-live' : 'is-hidden'}`}>
                        {s.is_active ? 'Live' : 'Hidden'}
                      </span>
                      {s.badge && <span className="catalog-badge">{s.badge}</span>}
                    </td>
                    <td>
                      <div className="catalog-row-actions">
                        <button
                          className="btn-sm-outline"
                          title={s.is_active ? 'Hide from website and apps' : 'Show on website and apps'}
                          onClick={() => toggleService(s)}
                        >
                          {s.is_active ? <EyeOff size={13} /> : <Eye size={13} />}
                        </button>
                        <button className="btn-sm-outline" title="Delete service" onClick={() => deleteService(s)}>
                          <Trash2 size={13} />
                        </button>
                        <button className="btn-sm-outline" onClick={() => setEditingService({ row: s, isNew: false })}>
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
      )}

      {editingCategory && (
        <CategoryEditor
          initial={editingCategory.row}
          isNew={editingCategory.isNew}
          takenIds={categories.map((c) => c.id)}
          takenSlugs={categories.map((c) => c.slug)}
          onClose={() => setEditingCategory(null)}
          onSaved={(saved) => {
            setCategories((prev) =>
              (editingCategory.isNew ? [...prev, saved] : prev.map((x) => (x.id === saved.id ? saved : x))).sort(
                (a, b) => a.sort_order - b.sort_order,
              ),
            );
            setEditingCategory(null);
          }}
        />
      )}

      {editingService && (
        <ServiceEditor
          initial={editingService.row}
          isNew={editingService.isNew}
          categories={categories}
          takenIds={services.map((s) => s.id)}
          onClose={() => setEditingService(null)}
          onSaved={(saved) => {
            setServices((prev) =>
              (editingService.isNew ? [...prev, saved] : prev.map((x) => (x.id === saved.id ? saved : x))).sort(
                (a, b) => a.sort_order - b.sort_order,
              ),
            );
            setEditingService(null);
          }}
        />
      )}
    </div>
  );
};
