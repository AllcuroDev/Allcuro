import React, { useCallback, useEffect, useState } from 'react';
import { ArrowDown, ArrowUp, Plus, RefreshCw, Save, Trash2 } from 'lucide-react';
import { supabase, type FaqRecord } from '../lib/supabase';

// Copy and contact details shown across the website and app: the care-desk
// phone/WhatsApp/email, home headline, and the FAQ list
// (public.site_settings and public.faqs).

interface Contact {
  phoneDisplay: string;
  phone: string;
  whatsapp: string;
  email: string;
  cities: string;
}

interface Home {
  headline: string;
  highlight: string;
  tilesTitle: string;
}

const emptyContact: Contact = { phoneDisplay: '', phone: '', whatsapp: '', email: '', cities: '' };
const emptyHome: Home = { headline: '', highlight: '', tilesTitle: '' };

type DraftFaq = FaqRecord & { isNew?: boolean };

export const SiteContentView: React.FC = () => {
  const [contact, setContact] = useState<Contact>(emptyContact);
  const [home, setHome] = useState<Home>(emptyHome);
  const [faqs, setFaqs] = useState<DraftFaq[]>([]);
  const [removed, setRemoved] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const [s, f] = await Promise.all([
      supabase.from('site_settings').select('key, value'),
      supabase.from('faqs').select('*').order('sort_order'),
    ]);
    setError(s.error?.message ?? f.error?.message ?? null);
    const by = Object.fromEntries(((s.data ?? []) as { key: string; value: Record<string, string> }[]).map((r) => [r.key, r.value]));
    setContact({ ...emptyContact, ...(by.contact ?? {}) });
    setHome({ ...emptyHome, ...(by.home ?? {}) });
    setFaqs((f.data as FaqRecord[]) ?? []);
    setRemoved([]);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const save = async () => {
    setBusy(true);
    setError(null);
    setSaved(null);
    const settings = await supabase.from('site_settings').upsert([
      { key: 'contact', value: contact },
      { key: 'home', value: home },
    ]);
    if (settings.error) {
      setBusy(false);
      return setError(settings.error.message);
    }
    if (removed.length) {
      const del = await supabase.from('faqs').delete().in('id', removed);
      if (del.error) {
        setBusy(false);
        return setError(del.error.message);
      }
    }
    const rows = faqs
      .filter((f) => f.question.trim() && f.answer.trim())
      .map((f, i) => ({
        ...(f.isNew ? {} : { id: f.id }),
        question: f.question.trim(),
        answer: f.answer.trim(),
        is_active: f.is_active,
        sort_order: i + 1,
      }));
    const existing = rows.filter((r) => 'id' in r);
    const fresh = rows.filter((r) => !('id' in r));
    const results = await Promise.all([
      existing.length ? supabase.from('faqs').upsert(existing) : null,
      fresh.length ? supabase.from('faqs').insert(fresh) : null,
    ]);
    const err = results.find((r) => r?.error)?.error;
    setBusy(false);
    if (err) return setError(err.message);
    setSaved('Saved — the website shows the new content on next load.');
    void load();
  };

  const move = (i: number, d: -1 | 1) =>
    setFaqs((prev) => {
      const next = [...prev];
      const j = i + d;
      if (j < 0 || j >= next.length) return prev;
      [next[i], next[j]] = [next[j], next[i]];
      return next;
    });

  const setFaq = (id: string, patch: Partial<DraftFaq>) => setFaqs((prev) => prev.map((f) => (f.id === id ? { ...f, ...patch } : f)));

  const input = <T extends object>(obj: T, setObj: (v: T) => void, k: keyof T, label: string, hint?: string) => (
    <label className="catalog-field">
      <span>{label}</span>
      <input value={String(obj[k] ?? '')} onChange={(e) => setObj({ ...obj, [k]: e.target.value })} />
      {hint && <small>{hint}</small>}
    </label>
  );

  if (loading) return <div className="payouts-table-box catalog-empty">Loading site content…</div>;

  return (
    <div className="services-catalog-layout">
      <div className="view-header-row">
        <div>
          <h1 className="view-title">Site Content</h1>
          <p className="view-subtitle">Contact details, home-page headline and FAQs on the website and app</p>
        </div>
        <div className="catalog-header-actions">
          <button className="btn-sm-outline" onClick={() => void load()}>
            <RefreshCw size={13} /> Reload
          </button>
          <button className="btn-sm-primary" disabled={busy} onClick={() => void save()}>
            <Save size={14} /> {busy ? 'Saving…' : 'Save all'}
          </button>
        </div>
      </div>

      {error && <div className="catalog-notice is-error">{error}</div>}
      {saved && <div className="catalog-notice">{saved}</div>}

      <div className="payouts-table-box content-section">
        <h3>Care desk contact</h3>
        <div className="catalog-form-grid">
          {input(contact, setContact, 'phoneDisplay', 'Phone (as shown)', 'e.g. +91 80 4120 5500')}
          {input(contact, setContact, 'phone', 'Phone (for calling)', 'Digits with country code, e.g. +918041205500')}
          {input(contact, setContact, 'whatsapp', 'WhatsApp number', 'Digits only, e.g. 918041205500')}
          {input(contact, setContact, 'email', 'Support email')}
          {input(contact, setContact, 'cities', 'Cities served', 'Comma separated — shown in the footer')}
        </div>
      </div>

      <div className="payouts-table-box content-section">
        <h3>Home page</h3>
        <div className="catalog-form-grid">
          {input(home, setHome, 'headline', 'Headline', 'e.g. Healthcare')}
          {input(home, setHome, 'highlight', 'Highlighted words', 'e.g. at your doorstep')}
          {input(home, setHome, 'tilesTitle', 'Service tiles title', 'e.g. What are you looking for?')}
        </div>
      </div>

      <div className="payouts-table-box content-section">
        <div className="content-section-head">
          <h3>FAQs</h3>
          <button
            className="btn-sm-outline"
            onClick={() =>
              setFaqs((prev) => [...prev, { id: `new-${Date.now()}`, isNew: true, question: '', answer: '', sort_order: prev.length + 1, is_active: true }])
            }
          >
            <Plus size={13} /> Add FAQ
          </button>
        </div>
        {faqs.length === 0 && <div className="catalog-empty">No FAQs yet.</div>}
        <ol className="faq-editor">
          {faqs.map((f, i) => (
            <li key={f.id}>
              <div className="catalog-form-grid">
                <label className="catalog-field is-wide">
                  <span>Question</span>
                  <input value={f.question} onChange={(e) => setFaq(f.id, { question: e.target.value })} />
                </label>
                <label className="catalog-field is-wide">
                  <span>Answer</span>
                  <textarea rows={2} value={f.answer} onChange={(e) => setFaq(f.id, { answer: e.target.value })} />
                </label>
              </div>
              <div className="catalog-row-actions">
                <label className="catalog-check">
                  <input type="checkbox" checked={f.is_active} onChange={(e) => setFaq(f.id, { is_active: e.target.checked })} /> Live
                </label>
                <button className="btn-sm-outline" onClick={() => move(i, -1)} disabled={i === 0} title="Move up">
                  <ArrowUp size={13} />
                </button>
                <button className="btn-sm-outline" onClick={() => move(i, 1)} disabled={i === faqs.length - 1} title="Move down">
                  <ArrowDown size={13} />
                </button>
                <button
                  className="btn-sm-outline"
                  title="Delete"
                  onClick={() => {
                    if (!f.isNew) setRemoved((r) => [...r, f.id]);
                    setFaqs((prev) => prev.filter((x) => x.id !== f.id));
                  }}
                >
                  <Trash2 size={13} />
                </button>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </div>
  );
};
