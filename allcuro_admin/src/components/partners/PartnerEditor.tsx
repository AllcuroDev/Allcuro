import React, { useEffect, useMemo, useState } from 'react';
import { Ban, CalendarClock, CheckCircle2, MessageSquareWarning, Plus, Trash2, X } from 'lucide-react';
import {
  supabase,
  type OfferingRecord,
  type PartnerRecord,
  type ServiceRecord,
} from '../../lib/supabase';
import { afterDiscount, inr } from '../../lib/catalog';
import { KIND_LABEL, STATUS_LABEL, fmtDate, statusClass } from '../../lib/partners';
import { ImageField } from '../catalog/ImageField';

// One partner: review what they submitted, approve / request changes /
// suspend, edit anything on their public profile, and set their prices and
// discounts. Admin edits pass RLS and the partners_guard trigger because
// is_admin() is true.

type Tab = 'review' | 'profile' | 'pricing';

const UNITS = ['per visit', 'per hour', 'per shift', 'per day', 'per month', 'per session'];

const list = (s: string) =>
  s
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean);
const lines = (s: string) =>
  s
    .split('\n')
    .map((x) => x.trim())
    .filter(Boolean);

/** Columns the admin edits on the Profile and Pricing tabs. */
const EDITABLE = [
  'display_name',
  'photo_url',
  'headline',
  'bio',
  'city',
  'locality',
  'languages',
  'skills',
  'highlights',
  'qualification',
  'specialisations',
  'experience_years',
  'employment_type',
  'is_available',
  'kind',
  'centre_type',
  'year_established',
  'staff_ratio',
  'total_beds',
  'beds_available',
  'services_included',
  'room_types',
  'photos',
  'food_menu',
  'licence_no',
  'public_phone',
  'price_per_day',
  'price_per_month',
  'discount_percent',
  'rating',
  'review_count',
] as const satisfies readonly (keyof PartnerRecord)[];

type DraftOffering = Omit<OfferingRecord, 'id'> & { id: string; isNew?: boolean };

interface Props {
  initial: PartnerRecord;
  onClose: () => void;
  onSaved: (p: PartnerRecord) => void;
  onDeleted: (id: string) => void;
}

export const PartnerEditor: React.FC<Props> = ({ initial, onClose, onSaved, onDeleted }) => {
  const [p, setP] = useState(initial);
  const [tab, setTab] = useState<Tab>(
    initial.status === 'under_review' || initial.status === 'site_visit_scheduled' ? 'review' : 'profile',
  );
  const [services, setServices] = useState<ServiceRecord[]>([]);
  const [offerings, setOfferings] = useState<DraftOffering[]>([]);
  const [removed, setRemoved] = useState<string[]>([]);
  const [note, setNote] = useState(initial.admin_note);
  const [visitAt, setVisitAt] = useState(initial.site_visit_at?.slice(0, 16) ?? '');
  const [addService, setAddService] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState<string | null>(null);

  // Comma / line lists are edited as text and parsed on save.
  const [text, setText] = useState({
    languages: initial.languages.join(', '),
    skills: initial.skills.join(', '),
    specialisations: initial.specialisations.join(', '),
    highlights: initial.highlights.join('\n'),
    services_included: initial.services_included.join(', '),
    room_types: initial.room_types.join(', '),
  });

  const isCentre = p.kind === 'centre';

  useEffect(() => {
    void (async () => {
      const [svc, off] = await Promise.all([
        supabase.from('services').select('*').order('sort_order'),
        supabase.from('partner_offerings').select('*').eq('partner_id', initial.id).order('sort_order'),
      ]);
      setServices((svc.data as ServiceRecord[]) ?? []);
      setOfferings(((off.data as OfferingRecord[]) ?? []).map((o) => ({ ...o })));
    })();
  }, [initial.id]);

  const serviceById = useMemo(() => Object.fromEntries(services.map((s) => [s.id, s])), [services]);

  const set = <K extends keyof PartnerRecord>(k: K, v: PartnerRecord[K]) => setP((prev) => ({ ...prev, [k]: v }));
  const setOff = (id: string, patch: Partial<DraftOffering>) =>
    setOfferings((prev) => prev.map((o) => (o.id === id ? { ...o, ...patch } : o)));

  /** Saves profile + pricing; `extra` carries a status change. */
  const save = async (extra: Partial<PartnerRecord> = {}, message = 'Saved') => {
    setBusy(true);
    setError(null);
    setSaved(null);
    const patch: Record<string, unknown> = Object.fromEntries(EDITABLE.map((k) => [k, p[k]]));
    Object.assign(patch, {
      languages: list(text.languages),
      skills: list(text.skills),
      specialisations: list(text.specialisations),
      highlights: lines(text.highlights),
      services_included: list(text.services_included),
      room_types: list(text.room_types),
      admin_note: note.trim(),
      ...extra,
    });
    const { data, error: err } = await supabase.from('partners').update(patch).eq('id', p.id).select().single();
    if (err) {
      setBusy(false);
      return setError(err.message);
    }

    // Offerings: delete removed, upsert the rest.
    if (removed.length) {
      const { error: delErr } = await supabase.from('partner_offerings').delete().in('id', removed);
      if (delErr) {
        setBusy(false);
        return setError(delErr.message);
      }
    }
    if (offerings.length) {
      const rows = offerings.map((o, i) => ({
        ...(o.isNew ? {} : { id: o.id }),
        partner_id: p.id,
        service_id: o.service_id,
        label: o.label,
        unit: o.unit,
        price: o.price,
        discount_percent: o.discount_percent,
        is_active: o.is_active,
        sort_order: i,
      }));
      const existing = rows.filter((r) => 'id' in r);
      const fresh = rows.filter((r) => !('id' in r));
      const results = await Promise.all([
        existing.length ? supabase.from('partner_offerings').upsert(existing) : null,
        fresh.length ? supabase.from('partner_offerings').insert(fresh) : null,
      ]);
      const offErr = results.find((r) => r?.error)?.error;
      if (offErr) {
        setBusy(false);
        return setError(offErr.message);
      }
      const { data: reload } = await supabase
        .from('partner_offerings')
        .select('*')
        .eq('partner_id', p.id)
        .order('sort_order');
      setOfferings(((reload as OfferingRecord[]) ?? []).map((o) => ({ ...o })));
    }
    setRemoved([]);
    setBusy(false);
    setP(data as PartnerRecord);
    setSaved(message);
    onSaved(data as PartnerRecord);
  };

  const approve = () => {
    const unpriced = isCentre
      ? p.price_per_day == null
      : offerings.length === 0 || offerings.some((o) => o.price == null && (!o.service_id || serviceById[o.service_id]?.price_from == null));
    if (unpriced && !window.confirm('Some prices are not set yet. Families will see "price on request" until you add them. Approve anyway?'))
      return;
    void save({ status: 'approved' }, 'Approved — now visible on the website and app');
  };

  const requestChanges = () => {
    if (!note.trim()) return setError('Write a note telling the partner what to fix — they see it in their portal.');
    void save({ status: 'rejected' }, 'Sent back to the partner with your note');
  };

  const suspend = () => {
    if (!window.confirm(`Suspend ${p.display_name}? They disappear from the website and app immediately.`)) return;
    void save({ status: 'suspended' }, 'Suspended');
  };

  const scheduleVisit = () => {
    if (!visitAt) return setError('Pick the site-visit date and time.');
    void save({ status: 'site_visit_scheduled', site_visit_at: new Date(visitAt).toISOString() }, 'Site visit scheduled');
  };

  const remove = async () => {
    if (!window.confirm(`Delete ${p.display_name}'s partner profile permanently? Their login stays; they can sign up again.`)) return;
    const { error: err } = await supabase.from('partners').delete().eq('id', p.id);
    if (err) return setError(err.message);
    onDeleted(p.id);
  };

  const addOffering = (serviceId: string | null) => {
    const svc = serviceId ? serviceById[serviceId] : null;
    setOfferings((prev) => [
      ...prev,
      {
        id: `new-${Date.now()}`,
        isNew: true,
        partner_id: p.id,
        service_id: serviceId,
        label: svc ? '' : 'New rate',
        unit: isCentre ? 'per day' : 'per visit',
        price: null,
        discount_percent: null,
        is_active: true,
        sort_order: prev.length,
      },
    ]);
    setAddService('');
  };

  const field = (label: string, el: React.ReactNode, wide = false, hint?: string) => (
    <label className={`catalog-field ${wide ? 'is-wide' : ''}`}>
      <span>{label}</span>
      {el}
      {hint && <small>{hint}</small>}
    </label>
  );

  const str = (k: keyof PartnerRecord) => (
    <input value={String(p[k] ?? '')} onChange={(e) => set(k, e.target.value as never)} />
  );
  const num = (k: keyof PartnerRecord, allowNull = false) => (
    <input
      type="number"
      min={0}
      value={p[k] == null ? '' : String(p[k])}
      onChange={(e) => set(k, (e.target.value === '' && allowNull ? null : Number(e.target.value) || 0) as never)}
    />
  );
  const listField = (k: keyof typeof text, label: string, area = false) =>
    field(
      label,
      area ? (
        <textarea rows={3} value={text[k]} onChange={(e) => setText({ ...text, [k]: e.target.value })} />
      ) : (
        <input value={text[k]} onChange={(e) => setText({ ...text, [k]: e.target.value })} />
      ),
      true,
      area ? 'One per line' : 'Separate with commas',
    );

  const identity = p.identity ?? {};
  const bank = p.bank ?? null;

  return (
    <div className="catalog-modal-backdrop" onClick={onClose}>
      <div className="catalog-modal is-xl" onClick={(e) => e.stopPropagation()}>
        <div className="catalog-modal-head">
          <div>
            <h2>{p.display_name || 'Unnamed partner'}</h2>
            <div className="date-sub">
              {KIND_LABEL[p.kind]} · {[p.locality, p.city].filter(Boolean).join(', ') || 'No city'} ·{' '}
              <span className={`catalog-status ${statusClass(p.status)}`}>{STATUS_LABEL[p.status]}</span>
              {p.allcuro_code && (
                <>
                  {' '}
                  · <span className="code-subaccount">{p.allcuro_code}</span>
                </>
              )}
            </div>
          </div>
          <button type="button" className="catalog-icon-btn" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>

        <div className="catalog-tabs" role="tablist">
          {(['review', 'profile', 'pricing'] as Tab[]).map((t) => (
            <button
              key={t}
              role="tab"
              aria-selected={tab === t}
              className={`catalog-tab ${tab === t ? 'active' : ''}`}
              onClick={() => setTab(t)}
            >
              {t === 'review' ? 'Review & approval' : t === 'profile' ? 'Public profile' : 'Prices & discounts'}
            </button>
          ))}
        </div>

        {tab === 'review' && (
          <div className="partner-review">
            <div className="partner-review-grid">
              <section>
                <h3>Contact</h3>
                <dl className="partner-dl">
                  <dt>Phone</dt>
                  <dd>{p.phone || '—'}</dd>
                  <dt>Email</dt>
                  <dd>{p.email || '—'}</dd>
                  <dt>Address</dt>
                  <dd>{p.address || '—'}</dd>
                  <dt>Signed up</dt>
                  <dd>{fmtDate(p.created_at)}</dd>
                  <dt>Submitted</dt>
                  <dd>{fmtDate(p.submitted_at)}</dd>
                </dl>
              </section>
              <section>
                <h3>{isCentre ? 'Centre' : 'Registration'}</h3>
                <dl className="partner-dl">
                  {isCentre ? (
                    <>
                      <dt>Type</dt>
                      <dd>{p.centre_type || '—'}</dd>
                      <dt>Licence</dt>
                      <dd>{p.licence_no || '—'}</dd>
                      <dt>Established</dt>
                      <dd>{p.year_established ?? '—'}</dd>
                      <dt>Beds</dt>
                      <dd>
                        {p.beds_available} free of {p.total_beds}
                      </dd>
                    </>
                  ) : (
                    <>
                      <dt>Qualification</dt>
                      <dd>{p.qualification || '—'}</dd>
                      <dt>Reg. no.</dt>
                      <dd>{p.registration_number || '—'}</dd>
                      <dt>Council</dt>
                      <dd>{p.council || '—'}</dd>
                      <dt>Experience</dt>
                      <dd>{p.experience_years} yrs</dd>
                      <dt>Previous</dt>
                      <dd>{p.previous_employer || '—'}</dd>
                    </>
                  )}
                </dl>
              </section>
              {!isCentre && (
                <section>
                  <h3>Identity (Aadhaar)</h3>
                  <dl className="partner-dl">
                    <dt>Name</dt>
                    <dd>{String(identity.fullName ?? '—')}</dd>
                    <dt>DOB</dt>
                    <dd>{String(identity.dob ?? '—')}</dd>
                    <dt>Gender</dt>
                    <dd>{String(identity.gender ?? '—')}</dd>
                    <dt>Aadhaar</dt>
                    <dd>{identity.aadhaarLast4 ? `XXXX XXXX ${String(identity.aadhaarLast4)}` : '—'}</dd>
                  </dl>
                </section>
              )}
              <section>
                <h3>Payout account</h3>
                <dl className="partner-dl">
                  {bank ? (
                    <>
                      <dt>Holder</dt>
                      <dd>{String(bank.holder ?? '—')}</dd>
                      <dt>Account</dt>
                      <dd>{bank.account ? `••••${String(bank.account).slice(-4)}` : '—'}</dd>
                      <dt>IFSC</dt>
                      <dd>{String(bank.ifsc ?? '—')}</dd>
                    </>
                  ) : (
                    <dd>Not added yet</dd>
                  )}
                </dl>
              </section>
            </div>

            <label className="catalog-field is-wide">
              <span>Note to the partner</span>
              <textarea
                rows={3}
                value={note}
                placeholder="Required when requesting changes — e.g. 'Please upload a clearer photo and add your registration number.'"
                onChange={(e) => setNote(e.target.value)}
              />
              <small>Shown in their partner portal when you request changes or suspend.</small>
            </label>

            {isCentre && (
              <div className="partner-visit-row">
                {field('Site visit', <input type="datetime-local" value={visitAt} onChange={(e) => setVisitAt(e.target.value)} />)}
                <button type="button" className="btn-sm-outline" disabled={busy} onClick={scheduleVisit}>
                  <CalendarClock size={13} /> Schedule site visit
                </button>
              </div>
            )}

            <div className="partner-actions">
              {p.status !== 'approved' && (
                <button type="button" className="btn-sm-primary" disabled={busy} onClick={approve}>
                  <CheckCircle2 size={14} /> {p.status === 'suspended' ? 'Reinstate' : 'Approve & go live'}
                </button>
              )}
              {p.status !== 'rejected' && (
                <button type="button" className="btn-sm-outline" disabled={busy} onClick={requestChanges}>
                  <MessageSquareWarning size={14} /> Request changes
                </button>
              )}
              {p.status === 'approved' && (
                <button type="button" className="btn-sm-outline is-danger" disabled={busy} onClick={suspend}>
                  <Ban size={14} /> Suspend
                </button>
              )}
              <button type="button" className="btn-sm-outline is-danger" disabled={busy} onClick={() => void remove()}>
                <Trash2 size={14} /> Delete
              </button>
            </div>
          </div>
        )}

        {tab === 'profile' && (
          <div className="catalog-form-grid">
            {!isCentre && (
              <ImageField
                label="Photo"
                hint="Square photo, under 2 MB."
                folder={`partners/${p.id}`}
                name="photo"
                bucket="avatars"
                maxKb={2048}
                value={p.photo_url}
                onChange={(url) => set('photo_url', url)}
                onBusy={setBusy}
              />
            )}
            {field('Name shown to families', str('display_name'))}
            {field(
              'Type',
              <select value={p.kind} onChange={(e) => set('kind', e.target.value as PartnerRecord['kind'])}>
                {Object.entries(KIND_LABEL).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>,
            )}
            {field(isCentre ? 'Centre type' : 'Title / qualification', isCentre ? str('centre_type') : str('headline'))}
            {!isCentre && field('Qualification', str('qualification'))}
            {field('Locality', str('locality'))}
            {field('City', str('city'))}
            {field('Bio', <textarea rows={3} value={p.bio} onChange={(e) => set('bio', e.target.value)} />, true)}
            {!isCentre && (
              <>
                {field('Experience (years)', num('experience_years'))}
                {field(
                  'Employment',
                  <select value={p.employment_type} onChange={(e) => set('employment_type', e.target.value)}>
                    {['Full-time', 'Part-time', 'Live-in'].map((x) => (
                      <option key={x}>{x}</option>
                    ))}
                  </select>,
                )}
                {listField('languages', 'Languages')}
                {listField('skills', 'Skills (shown as tags)')}
                {listField('specialisations', 'Specialisations')}
                {listField('highlights', 'Highlights', true)}
              </>
            )}
            {isCentre && (
              <>
                {field('Year established', num('year_established', true))}
                {field('Staff ratio', str('staff_ratio'))}
                {field('Total beds', num('total_beds'))}
                {field('Beds available', num('beds_available'))}
                {field('Licence no.', str('licence_no'))}
                {field('Front-desk phone', str('public_phone'))}
                {listField('room_types', 'Room types')}
                {listField('services_included', 'Services included')}
                {field('Food menu', <textarea rows={2} value={p.food_menu} onChange={(e) => set('food_menu', e.target.value)} />, true)}
                <div className="catalog-field is-wide">
                  <span>Photos</span>
                  <div className="partner-photos">
                    {p.photos.map((url) => (
                      <figure key={url}>
                        <img src={url} alt="" />
                        <button type="button" className="btn-sm-outline" onClick={() => set('photos', p.photos.filter((x) => x !== url))}>
                          Remove
                        </button>
                      </figure>
                    ))}
                  </div>
                  <ImageField
                    label="Add a photo"
                    hint="Under 2 MB."
                    folder={`partners/${p.id}`}
                    name="photo"
                    bucket="centre-photos"
                    maxKb={2048}
                    value={null}
                    onChange={(url) => url && set('photos', [...p.photos, url])}
                    onBusy={setBusy}
                  />
                </div>
              </>
            )}
            {field('Rating (0–5)', <input type="number" step="0.1" min={0} max={5} value={p.rating ?? ''} onChange={(e) => set('rating', e.target.value === '' ? null : Number(e.target.value))} />, false, 'Leave empty to show "New"')}
            {field('Review count', num('review_count'))}
            <label className="catalog-check is-wide">
              <input type="checkbox" checked={p.is_available} onChange={(e) => set('is_available', e.target.checked)} />
              {isCentre ? 'Accepting admissions' : 'Available for bookings'}
            </label>
          </div>
        )}

        {tab === 'pricing' && (
          <div className="partner-pricing">
            {isCentre ? (
              <div className="catalog-form-grid">
                {field('Price per day (₹)', num('price_per_day', true))}
                {field('Price per month (₹)', num('price_per_month', true))}
                {field(
                  'Discount %',
                  <input
                    type="number"
                    min={0}
                    max={100}
                    step="0.5"
                    value={p.discount_percent}
                    onChange={(e) => set('discount_percent', Math.min(100, Math.max(0, Number(e.target.value) || 0)))}
                  />,
                  false,
                  `Families pay ${inr(afterDiscount(p.price_per_day, p.discount_percent))}/day`,
                )}
              </div>
            ) : (
              <>
                <p className="date-sub">
                  Services the partner offers and any shift rates. Leave price empty to use the catalog price; leave discount empty
                  to use the service’s discount.
                </p>
                <table className="custom-data-table">
                  <thead>
                    <tr>
                      <th>Service / rate</th>
                      <th>Unit</th>
                      <th>Price (₹)</th>
                      <th>Discount %</th>
                      <th>Families pay</th>
                      <th>Live</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {offerings.length === 0 && (
                      <tr>
                        <td colSpan={7} className="catalog-empty">
                          No services yet — add the ones this partner can do.
                        </td>
                      </tr>
                    )}
                    {offerings.map((o) => {
                      const svc = o.service_id ? serviceById[o.service_id] : null;
                      const basePrice = o.price ?? svc?.price_from ?? null;
                      const pct = o.discount_percent ?? svc?.discount_percent ?? 0;
                      return (
                        <tr key={o.id}>
                          <td>
                            {svc ? (
                              <>
                                <div className="partner-name-bold">{svc.name}</div>
                                <input
                                  className="catalog-inline-input"
                                  placeholder="Custom label (optional)"
                                  value={o.label}
                                  onChange={(e) => setOff(o.id, { label: e.target.value })}
                                />
                              </>
                            ) : (
                              <input
                                className="catalog-inline-input"
                                value={o.label}
                                onChange={(e) => setOff(o.id, { label: e.target.value })}
                              />
                            )}
                          </td>
                          <td>
                            <select value={o.unit} onChange={(e) => setOff(o.id, { unit: e.target.value })}>
                              {[...new Set([...UNITS, o.unit])].map((u) => (
                                <option key={u}>{u}</option>
                              ))}
                            </select>
                          </td>
                          <td>
                            <input
                              className="catalog-inline-input is-num"
                              type="number"
                              min={0}
                              placeholder={svc?.price_from != null ? String(svc.price_from) : 'Required'}
                              value={o.price ?? ''}
                              onChange={(e) => setOff(o.id, { price: e.target.value === '' ? null : Number(e.target.value) })}
                            />
                          </td>
                          <td>
                            <input
                              className="catalog-inline-input is-num"
                              type="number"
                              min={0}
                              max={100}
                              step="0.5"
                              placeholder={svc ? String(svc.discount_percent ?? 0) : '0'}
                              value={o.discount_percent ?? ''}
                              onChange={(e) =>
                                setOff(o.id, {
                                  discount_percent: e.target.value === '' ? null : Math.min(100, Math.max(0, Number(e.target.value))),
                                })
                              }
                            />
                          </td>
                          <td className="txn-id-bold">{basePrice == null ? 'Not priced' : inr(afterDiscount(basePrice, pct))}</td>
                          <td>
                            <input type="checkbox" checked={o.is_active} onChange={(e) => setOff(o.id, { is_active: e.target.checked })} />
                          </td>
                          <td>
                            <button
                              type="button"
                              className="btn-sm-outline"
                              title="Remove"
                              onClick={() => {
                                if (!o.isNew) setRemoved((r) => [...r, o.id]);
                                setOfferings((prev) => prev.filter((x) => x.id !== o.id));
                              }}
                            >
                              <Trash2 size={13} />
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
                <div className="partner-add-row">
                  <select value={addService} onChange={(e) => setAddService(e.target.value)}>
                    <option value="">Add a catalog service…</option>
                    {services
                      .filter((s) => !offerings.some((o) => o.service_id === s.id))
                      .map((s) => (
                        <option key={s.id} value={s.id}>
                          {s.name} ({s.category_id})
                        </option>
                      ))}
                  </select>
                  <button type="button" className="btn-sm-outline" disabled={!addService} onClick={() => addOffering(addService)}>
                    <Plus size={13} /> Add service
                  </button>
                  <button type="button" className="btn-sm-outline" onClick={() => addOffering(null)}>
                    <Plus size={13} /> Add custom rate (e.g. 12-hr shift)
                  </button>
                </div>
              </>
            )}
          </div>
        )}

        {error && <div className="catalog-notice is-error">{error}</div>}
        {saved && <div className="catalog-notice">{saved}</div>}

        <div className="catalog-modal-actions">
          <button type="button" className="btn-sm-outline" onClick={onClose}>
            Close
          </button>
          <button type="button" className="btn-sm-primary" disabled={busy} onClick={() => void save()}>
            {busy ? 'Saving…' : 'Save changes'}
          </button>
        </div>
      </div>
    </div>
  );
};
