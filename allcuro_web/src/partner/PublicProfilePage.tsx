import { useEffect, useState, type ChangeEvent } from 'react'
import { inr } from '../lib/format'
import { supabase } from '../lib/supabase'
import { toast } from '../lib/toast'
import { PR } from './routes'
import { refreshPartner, setCentreStatus, setPractitionerStatus, usePartnerSession, usesNurseShell } from './session'
import { ChipGroup, PBadge, PBody, PCard, PField, PPageHead, Toggle } from './ui'

// What families see on the customer site and app: written here by the partner,
// stored in public.partners, and shown only after an admin approves it.
// Prices and discounts are set by the admin; partners choose which services
// they offer (public.partner_offerings) but cannot price them.

const LANGUAGES = ['English', 'Hindi', 'Kannada', 'Tamil', 'Telugu', 'Malayalam', 'Marathi', 'Bengali', 'Gujarati', 'Punjabi', 'Urdu']
const NURSE_SKILLS = [
  'Injections & IV',
  'Wound & Dressing',
  'Catheter Care',
  "Ryle's Tube",
  'Tracheostomy',
  'ICU / Critical Care',
  'Ventilator',
  'Post-Op',
  'Diabetic Care',
  'Elderly Care',
  'Palliative Care',
  'Mother & Baby',
  'Physiotherapy',
  'Bed Bath',
  'Mobility Support',
  'Companionship',
]
const CENTRE_SERVICES = ['24/7 Nursing', 'Doctor on call', 'Physiotherapy', 'Diabetic meals', 'Home-style meals', 'Ambulance tie-up', 'CCTV monitored', 'Palliative care', 'Family visiting hours', 'Day care']
const ROOM_TYPES = ['Private AC Room', 'Private Non-AC Room', 'Semi-Private Room', 'Shared Ward', 'ICU Step-Down']
const EMPLOYMENT = ['Full-time', 'Part-time', 'Live-in']

/** Catalog categories each kind usually works in (the service picker shows these first). */
const KIND_CATEGORIES: Record<string, string[]> = {
  nurse: ['Nursing Care', 'Elder Care', 'Mother & Baby Care', 'Caregivers'],
  doctor: ['Doctor Care'],
  physiotherapist: ['Physiotherapy'],
  caregiver: ['Caregivers', 'Elder Care', 'Hospital Companion'],
}

interface Row {
  id: string
  kind: string
  status: string
  display_name: string
  photo_url: string | null
  headline: string
  bio: string
  city: string
  locality: string
  languages: string[]
  skills: string[]
  highlights: string[]
  experience_years: number
  employment_type: string
  is_available: boolean
  centre_type: string
  staff_ratio: string
  total_beds: number
  beds_available: number
  services_included: string[]
  room_types: string[]
  photos: string[]
  food_menu: string
  licence_no: string
  public_phone: string
  price_per_day: number | null
  price_per_month: number | null
  discount_percent: number
  admin_note: string
}

interface CatalogService {
  id: string
  name: string
  category_id: string
  price_from: number | null
  discount_percent: number
}

interface Offering {
  id: string
  service_id: string | null
  label: string
  unit: string
  price: number | null
  discount_percent: number | null
}

const EDITABLE: (keyof Row)[] = [
  'display_name',
  'photo_url',
  'headline',
  'bio',
  'city',
  'locality',
  'languages',
  'skills',
  'highlights',
  'experience_years',
  'employment_type',
  'is_available',
  'centre_type',
  'staff_ratio',
  'total_beds',
  'beds_available',
  'services_included',
  'room_types',
  'photos',
  'food_menu',
  'licence_no',
  'public_phone',
]

async function uploadImage(bucket: 'avatars' | 'centre-photos', file: File) {
  if (!supabase) throw new Error('Uploads are unavailable.')
  const { data } = await supabase.auth.getSession()
  const uid = data.session?.user.id
  if (!uid) throw new Error('Please sign in again.')
  if (file.size > 3 * 1024 * 1024) throw new Error('Choose an image under 3 MB.')
  const ext = file.name.split('.').pop()?.toLowerCase() ?? 'jpg'
  const path = `${uid}/${Date.now()}.${ext}`
  const { error } = await supabase.storage.from(bucket).upload(path, file, { contentType: file.type, cacheControl: '31536000' })
  if (error) throw error
  return supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl
}

const lines = (s: string) =>
  s
    .split('\n')
    .map((x) => x.trim())
    .filter(Boolean)

export function PublicProfilePage() {
  const session = usePartnerSession()
  const role = session.role
  const partnerId = role ? session.partnerIds[role] : undefined
  const isCentre = role === 'centre'
  const back = usesNurseShell(role) ? PR.nurseHome : PR.centreHome

  const [row, setRow] = useState<Row | null>(null)
  const [catalog, setCatalog] = useState<CatalogService[]>([])
  const [offerings, setOfferings] = useState<Offering[]>([])
  const [picked, setPicked] = useState<string[]>([])
  const [highlights, setHighlights] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!supabase || !partnerId) return
    const db = supabase
    void (async () => {
      const [p, svc, off] = await Promise.all([
        db.from('partners').select('*').eq('id', partnerId).single<Row>(),
        db.from('services').select('id, name, category_id, price_from, discount_percent').eq('is_active', true).order('sort_order'),
        db.from('partner_offerings').select('id, service_id, label, unit, price, discount_percent').eq('partner_id', partnerId).order('sort_order'),
      ])
      if (p.error) {
        setError('Could not load your profile. Please refresh.')
        return
      }
      setRow(p.data)
      setHighlights(p.data.highlights.join('\n'))
      setCatalog((svc.data ?? []) as CatalogService[])
      const offs = (off.data ?? []) as Offering[]
      setOfferings(offs)
      setPicked(offs.flatMap((o) => (o.service_id ? [o.service_id] : [])))
    })()
  }, [partnerId])

  if (!partnerId)
    return (
      <>
        <PPageHead title="Public profile" back={back} />
        <PBody narrow>
          <PCard>
            <p className="p-muted">Finish sign-up first — your public profile is created from it.</p>
          </PCard>
        </PBody>
      </>
    )

  if (!row)
    return (
      <>
        <PPageHead title="Public profile" back={back} />
        <PBody narrow>
          <PCard>
            <p className="p-muted">{error || 'Loading your profile…'}</p>
          </PCard>
        </PBody>
      </>
    )

  const set = <K extends keyof Row>(k: K, v: Row[K]) => setRow({ ...row, [k]: v })
  const text = (k: keyof Row) => (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => set(k, e.target.value as never)
  const num = (k: keyof Row) => (e: ChangeEvent<HTMLInputElement>) => set(k, (parseInt(e.target.value.replace(/\D/g, ''), 10) || 0) as never)

  const onPhoto = async (e: ChangeEvent<HTMLInputElement>, centre: boolean) => {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return
    try {
      setBusy(true)
      const url = await uploadImage(centre ? 'centre-photos' : 'avatars', file)
      if (centre) set('photos', [...row.photos, url])
      else set('photo_url', url)
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Upload failed', 'danger')
    } finally {
      setBusy(false)
    }
  }

  const relevant = isCentre ? [] : (KIND_CATEGORIES[row.kind] ?? [])
  const services = [...catalog].sort(
    (a, b) => Number(!relevant.includes(a.category_id)) - Number(!relevant.includes(b.category_id)),
  )
  const offeringFor = (serviceId: string) => offerings.find((o) => o.service_id === serviceId)

  const save = async (submit: boolean) => {
    if (!supabase) return
    if (!row.display_name.trim()) return setError('Add the name families will see.')
    if (!row.city.trim()) return setError('Add your city.')
    setError('')
    setBusy(true)
    const patch = Object.fromEntries(EDITABLE.map((k) => [k, row[k]]))
    patch.highlights = lines(highlights)
    const { error: saveError } = await supabase.from('partners').update(patch).eq('id', row.id)
    if (saveError) {
      setBusy(false)
      return setError('Could not save. Please try again.')
    }

    // Services offered: add new picks, remove dropped ones. Prices stay the admin's.
    if (!isCentre) {
      const had = offerings.flatMap((o) => (o.service_id ? [o.service_id] : []))
      const add = picked.filter((id) => !had.includes(id))
      const drop = offerings.filter((o) => o.service_id && !picked.includes(o.service_id)).map((o) => o.id)
      if (add.length)
        await supabase.from('partner_offerings').insert(add.map((service_id, i) => ({ partner_id: row.id, service_id, sort_order: had.length + i })))
      if (drop.length) await supabase.from('partner_offerings').delete().in('id', drop)
      const { data } = await supabase
        .from('partner_offerings')
        .select('id, service_id, label, unit, price, discount_percent')
        .eq('partner_id', row.id)
        .order('sort_order')
      setOfferings((data ?? []) as Offering[])
    }

    if (submit) {
      if (isCentre) await setCentreStatus('pendingReview')
      else await setPractitionerStatus('underReview')
    }
    await refreshPartner()
    setBusy(false)
    toast(submit ? 'Submitted for approval' : 'Profile saved')
  }

  const status = row.status
  const statusText: Record<string, [string, 'ok' | 'warn' | 'info']> = {
    approved: ['Live — visible to families', 'ok'],
    under_review: ['Under review', 'info'],
    site_visit_scheduled: ['Site visit scheduled', 'info'],
    rejected: ['Changes requested', 'warn'],
    suspended: ['Suspended', 'warn'],
  }
  const [badge, tone] = statusText[status] ?? ['Not yet submitted', 'warn']
  const canSubmit = status === 'onboarding' || status === 'incomplete' || status === 'rejected'

  return (
    <>
      <PPageHead title="Public profile" subtitle="What families see once ALLCURO approves you" back={back} aside={<PBadge tone={tone}>{badge}</PBadge>} />
      <PBody narrow>
        {row.admin_note && (status === 'rejected' || status === 'suspended') && (
          <PCard className="pp-note">
            <strong>Note from ALLCURO:</strong> {row.admin_note}
          </PCard>
        )}

        <PCard as="section" className="pp-section">
          <h2 className="pa-h2">{isCentre ? 'Centre details' : 'About you'}</h2>
          {!isCentre && (
            <div className="pp-photo">
              {row.photo_url ? <img src={row.photo_url} alt="" /> : <span className="pp-photo-empty">No photo</span>}
              <label className="p-btn p-btn-outline p-btn-sm">
                {row.photo_url ? 'Change photo' : 'Upload photo'}
                <input type="file" accept="image/*" hidden onChange={(e) => void onPhoto(e, false)} disabled={busy} />
              </label>
            </div>
          )}
          <PField label={isCentre ? 'Centre name' : 'Name shown to families'}>
            <input value={row.display_name} onChange={text('display_name')} />
          </PField>
          <PField label={isCentre ? 'Centre type' : 'Qualification / title'} hint={isCentre ? 'e.g. Rehab & recovery' : 'e.g. B.Sc Nursing, GNM, BPT Physiotherapist'}>
            <input value={isCentre ? row.centre_type : row.headline} onChange={text(isCentre ? 'centre_type' : 'headline')} />
          </PField>
          <PField label={isCentre ? 'About the centre' : 'Short bio'}>
            <textarea rows={4} value={row.bio} onChange={text('bio')} />
          </PField>
          <div className="pp-row">
            <PField label="Area / locality">
              <input value={row.locality} onChange={text('locality')} placeholder="e.g. Indiranagar" />
            </PField>
            <PField label="City">
              <input value={row.city} onChange={text('city')} placeholder="e.g. Bengaluru" />
            </PField>
          </div>
          {!isCentre && (
            <div className="pp-row">
              <PField label="Years of experience">
                <input inputMode="numeric" value={String(row.experience_years)} onChange={num('experience_years')} />
              </PField>
              <PField label="Employment">
                <select value={row.employment_type} onChange={text('employment_type')}>
                  {EMPLOYMENT.map((e) => (
                    <option key={e}>{e}</option>
                  ))}
                </select>
              </PField>
            </div>
          )}
          <div className="pp-toggle">
            <span>{isCentre ? 'Accepting admissions' : 'Available for bookings'}</span>
            <Toggle checked={row.is_available} onChange={(v) => set('is_available', v)} label="Available" />
          </div>
        </PCard>

        {!isCentre && (
          <PCard as="section" className="pp-section">
            <h2 className="pa-h2">Languages</h2>
            <ChipGroup options={LANGUAGES} value={row.languages} onChange={(v) => set('languages', v)} />
            <h2 className="pa-h2">Skills</h2>
            <ChipGroup options={[...new Set([...NURSE_SKILLS, ...row.skills])]} value={row.skills} onChange={(v) => set('skills', v)} />
            <PField label="Highlights (one per line)" hint="e.g. Ex-Manipal Hospital ICU">
              <textarea rows={3} value={highlights} onChange={(e) => setHighlights(e.target.value)} />
            </PField>
          </PCard>
        )}

        {isCentre && (
          <PCard as="section" className="pp-section">
            <h2 className="pa-h2">Beds, rooms &amp; facilities</h2>
            <div className="pp-row">
              <PField label="Total beds">
                <input inputMode="numeric" value={String(row.total_beds)} onChange={num('total_beds')} />
              </PField>
              <PField label="Beds available now">
                <input inputMode="numeric" value={String(row.beds_available)} onChange={num('beds_available')} />
              </PField>
            </div>
            <div className="pp-row">
              <PField label="Staff-to-patient ratio" hint="e.g. 1:4">
                <input value={row.staff_ratio} onChange={text('staff_ratio')} />
              </PField>
              <PField label="Licence / CEA registration no.">
                <input value={row.licence_no} onChange={text('licence_no')} />
              </PField>
            </div>
            <PField label="Front-desk phone">
              <input type="tel" value={row.public_phone} onChange={text('public_phone')} />
            </PField>
            <h2 className="pa-h2">Room types</h2>
            <ChipGroup options={[...new Set([...ROOM_TYPES, ...row.room_types])]} value={row.room_types} onChange={(v) => set('room_types', v)} />
            <h2 className="pa-h2">Services included</h2>
            <ChipGroup
              options={[...new Set([...CENTRE_SERVICES, ...row.services_included])]}
              value={row.services_included}
              onChange={(v) => set('services_included', v)}
            />
            <PField label="Food menu">
              <textarea rows={2} value={row.food_menu} onChange={text('food_menu')} />
            </PField>
            <h2 className="pa-h2">Photos</h2>
            <div className="pp-gallery">
              {row.photos.map((url) => (
                <figure key={url}>
                  <img src={url} alt="" />
                  <button type="button" className="p-btn p-btn-outline p-btn-sm" onClick={() => set('photos', row.photos.filter((p) => p !== url))}>
                    Remove
                  </button>
                </figure>
              ))}
              <label className="pp-gallery-add">
                + Add photo
                <input type="file" accept="image/*" hidden onChange={(e) => void onPhoto(e, true)} disabled={busy} />
              </label>
            </div>
          </PCard>
        )}

        <PCard as="section" className="pp-section">
          <h2 className="pa-h2">{isCentre ? 'Pricing' : 'Services you offer'}</h2>
          <p className="p-muted">Prices and discounts are set by ALLCURO. You’ll see them here once added.</p>
          {isCentre ? (
            <p>
              {row.price_per_day != null ? (
                <>
                  <strong>{inr(Number(row.price_per_day))}</strong> / day
                  {row.price_per_month != null && <> · {inr(Number(row.price_per_month))} / month</>}
                  {Number(row.discount_percent) > 0 && <> · {Number(row.discount_percent)}% off</>}
                </>
              ) : (
                <span className="p-muted">Not priced yet</span>
              )}
            </p>
          ) : (
            <>
              <ul className="pp-services">
                {services.map((s) => {
                  const on = picked.includes(s.id)
                  const o = offeringFor(s.id)
                  const price = o?.price ?? s.price_from
                  const pct = o?.discount_percent ?? s.discount_percent
                  return (
                    <li key={s.id}>
                      <label>
                        <input
                          type="checkbox"
                          checked={on}
                          onChange={() => setPicked(on ? picked.filter((x) => x !== s.id) : [...picked, s.id])}
                        />
                        <span className="p-row-grow">
                          {s.name}
                          <small className="p-muted"> · {s.category_id}</small>
                        </span>
                        <span className="p-muted">
                          {price != null ? inr(Math.round(Number(price) * (1 - (Number(pct) || 0) / 100))) : '—'}
                        </span>
                      </label>
                    </li>
                  )
                })}
              </ul>
              {offerings.some((o) => !o.service_id) && (
                <>
                  <h3 className="pa-h2">Shift rates set by ALLCURO</h3>
                  <ul className="pp-services">
                    {offerings
                      .filter((o) => !o.service_id)
                      .map((o) => (
                        <li key={o.id}>
                          <span className="p-row-grow">
                            {o.label} <small className="p-muted">· {o.unit}</small>
                          </span>
                          <span>{o.price != null ? inr(Number(o.price)) : 'Not priced'}</span>
                        </li>
                      ))}
                  </ul>
                </>
              )}
            </>
          )}
        </PCard>

        {error && (
          <p className="pa-err-text" role="alert">
            {error}
          </p>
        )}
        <div className="pp-actions">
          <button type="button" className="p-btn p-btn-outline" onClick={() => void save(false)} disabled={busy}>
            {busy ? 'Saving…' : 'Save'}
          </button>
          {canSubmit && (
            <button type="button" className="p-btn p-btn-primary" onClick={() => void save(true)} disabled={busy}>
              Save &amp; submit for approval
            </button>
          )}
        </div>
      </PBody>
    </>
  )
}
