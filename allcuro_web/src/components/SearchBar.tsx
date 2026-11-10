import { useEffect, useId, useMemo, useRef, useState, type ReactNode } from 'react'
import { categories, categoryById, categoryHref } from '../data/categories'
import { medicines } from '../data/medicines'
import { nurses } from '../data/providers'
import { inr } from '../lib/format'
import { navigate } from '../router'
import { useServices } from '../state/catalog'
import { CareIcon } from './CareIcon'
import { CloseIcon, NurseIcon, PillIcon, SearchIcon } from './Icons'

// The app home's top search bar ("Search injections, wound dressing, nurses,
// ICU beds..."). Matches services the same way the app does — name, category,
// subcategory or what's included — and also offers care types, medicines and
// nurses. Results open in a dropdown; Enter opens the highlighted one.

interface Result {
  key: string
  group: 'Care types' | 'Services' | 'Medicines' | 'Nurses'
  title: string
  meta: string
  to: string
  icon: ReactNode
}

const MAX_PER_GROUP = { 'Care types': 3, Services: 6, Medicines: 3, Nurses: 3 }

export function SearchBar({ className = '' }: { className?: string }) {
  const services = useServices()
  const [q, setQ] = useState('')
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)
  const boxRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const listId = useId()

  const results = useMemo<Result[]>(() => {
    const term = q.trim().toLowerCase()
    if (!term) return []
    const has = (...fields: (string | undefined)[]) => fields.some((f) => f?.toLowerCase().includes(term))
    const out: Result[] = []

    categories
      .filter((c) => has(c.label, c.blurb))
      .slice(0, MAX_PER_GROUP['Care types'])
      .forEach((c) =>
        out.push({ key: `c-${c.slug}`, group: 'Care types', title: c.label, meta: c.blurb, to: categoryHref(c), icon: <CareIcon name={c.icon} size={22} color={c.ink} /> }),
      )

    services
      .filter((s) => has(s.name, s.category, s.subcategory, s.includes))
      .slice(0, MAX_PER_GROUP.Services)
      .forEach((s) =>
        out.push({
          key: `s-${s.id}`,
          group: 'Services',
          title: s.name,
          meta: `${s.category} · ${s.price}`,
          to: `/service/${s.id}`,
          icon: <CareIcon name={s.icon} size={22} color={categoryById[s.category]?.ink} />,
        }),
      )

    medicines
      .filter((m) => has(m.name, m.category))
      .slice(0, MAX_PER_GROUP.Medicines)
      .forEach((m) =>
        out.push({ key: `m-${m.id}`, group: 'Medicines', title: m.name, meta: `${m.pack} · ${inr(m.price)}${m.rx ? ' · Rx' : ''}`, to: `/medicines?q=${encodeURIComponent(m.name)}`, icon: <PillIcon size={20} /> }),
      )

    nurses
      .filter((n) => has(n.name, n.level, n.city, ...n.tags))
      .slice(0, MAX_PER_GROUP.Nurses)
      .forEach((n) =>
        out.push({ key: `n-${n.id}`, group: 'Nurses', title: n.name, meta: `${n.level} · ${n.experience} yrs · ${n.city}`, to: `/nurses/${n.id}`, icon: <NurseIcon size={20} /> }),
      )

    return out
  }, [q, services])

  // Close when clicking anywhere outside.
  useEffect(() => {
    if (!open) return
    const onDown = (e: PointerEvent) => {
      if (!boxRef.current?.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('pointerdown', onDown)
    return () => document.removeEventListener('pointerdown', onDown)
  }, [open])

  const go = (r: Result) => {
    setOpen(false)
    setQ('')
    ;(document.activeElement as HTMLElement | null)?.blur()
    navigate(r.to)
  }

  const showList = open && q.trim().length > 0

  return (
    <div className={`search ${className}`} ref={boxRef}>
      <form
        role="search"
        className="search-field"
        onSubmit={(e) => {
          e.preventDefault()
          if (results[active]) go(results[active])
          else if (q.trim()) navigate('/services/all')
        }}
      >
        <SearchIcon size={20} />
        <input
          ref={inputRef}
          type="search"
          value={q}
          placeholder="Search injections, wound dressing, nurses, medicines…"
          aria-label="Search services, nurses and medicines"
          role="combobox"
          aria-expanded={showList}
          aria-controls={listId}
          aria-autocomplete="list"
          aria-activedescendant={showList && results[active] ? `${listId}-${active}` : undefined}
          onChange={(e) => {
            setQ(e.target.value)
            setActive(0)
            setOpen(true)
          }}
          onFocus={() => setOpen(true)}
          onKeyDown={(e) => {
            if (e.key === 'ArrowDown') {
              e.preventDefault()
              setActive((a) => Math.min(a + 1, results.length - 1))
            } else if (e.key === 'ArrowUp') {
              e.preventDefault()
              setActive((a) => Math.max(a - 1, 0))
            } else if (e.key === 'Escape') {
              setOpen(false)
            }
          }}
        />
        {q && (
          <button type="button" className="search-clear" aria-label="Clear search" onClick={() => { setQ(''); inputRef.current?.focus() }}>
            <CloseIcon size={18} />
          </button>
        )}
      </form>

      {showList && (
        <div className="search-pop" id={listId} role="listbox" aria-label="Search results">
          {results.length === 0 ? (
            <p className="search-empty">
              No matches for “{q.trim()}”. Try “injection”, “physio” or “paracetamol”, or call us and we will help.
            </p>
          ) : (
            results.map((r, i) => {
              const head = results[i - 1]?.group !== r.group ? r.group : null
              return (
                <div key={r.key}>
                  {head && <p className="search-group">{head}</p>}
                  <button
                    type="button"
                    id={`${listId}-${i}`}
                    role="option"
                    aria-selected={i === active}
                    className={`search-item ${i === active ? 'is-active' : ''}`}
                    onPointerEnter={() => setActive(i)}
                    onClick={() => go(r)}
                  >
                    <span className="search-item-icon">{r.icon}</span>
                    <span className="search-item-text">
                      <strong>{r.title}</strong>
                      <small>{r.meta}</small>
                    </span>
                  </button>
                </div>
              )
            })
          )}
        </div>
      )}
    </div>
  )
}
