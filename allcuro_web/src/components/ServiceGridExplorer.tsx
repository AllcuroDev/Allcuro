import { useState, useMemo, useEffect, useRef } from 'react'
import { ArtTile, IconTile } from './CareIcon'
import { ArrowIcon, ClockIcon, SearchIcon } from './Icons'
import { ServiceDialog } from './ServiceDialog'
import { ALL_SLUG, categories, categoryById, inCategory } from '../data/categories'
import { navigate } from '../router'
import { useCategoryImages, useServices } from '../state/catalog'
import type { Service } from '../data/types'

interface Props {
  initialSlug?: string
  onCategoryChange?: (slug: string) => void
  id?: string
}

// "All Services" leads the dock, then each care type.
const dockItems = [
  { id: ALL_SLUG, slug: ALL_SLUG, label: 'All Services', icon: 'see_all' } as { id: string; slug: string; label: string; icon: string; href?: string },
  ...categories.map((c) => ({ id: c.id, slug: c.slug, label: c.label, icon: c.icon, href: c.href })),
]

export function ServiceGridExplorer({
  initialSlug = 'nursing',
  onCategoryChange,
  id = 'services-explorer',
}: Props) {
  const [activeSlug, setActiveSlug] = useState<string>(initialSlug)
  const [searchQuery, setSearchQuery] = useState('')
  const [activeSubcat, setActiveSubcat] = useState<string>('all')
  const [selectedService, setSelectedService] = useState<Service | null>(null)
  const dockRef = useRef<HTMLDivElement>(null)
  const services = useServices()
  const categoryImages = useCategoryImages()

  // On narrow screens the dock scrolls sideways; centre the active tab in it.
  useEffect(() => {
    const dock = dockRef.current
    const tab = dock?.querySelector<HTMLElement>('.dock-tab.is-active')
    if (!dock || !tab) return
    dock.scrollLeft = tab.offsetLeft - (dock.clientWidth - tab.offsetWidth) / 2
  }, [activeSlug])

  const handleCategorySelect = (slug: string) => {
    // Care Centres has no service list of its own — it opens the centres page.
    const href = dockItems.find((c) => c.slug === slug)?.href
    if (href) return navigate(href)
    setActiveSlug(slug)
    setActiveSubcat('all')
    setSearchQuery('')
    onCategoryChange?.(slug)
  }

  const isAll = activeSlug === ALL_SLUG
  const currentCategory = categories.find((c) => c.slug === activeSlug)

  // Filter services by category
  const categoryServices = useMemo(() => {
    if (isAll) return services
    if (!currentCategory) return services
    return services.filter((s) => inCategory(s, currentCategory.id))
  }, [services, isAll, currentCategory])

  // Extract unique subcategories for filter pills
  const subcategories = useMemo(() => {
    const set = new Set<string>()
    categoryServices.forEach((s) => {
      if (s.subcategory) set.add(s.subcategory)
    })
    return ['all', ...Array.from(set)]
  }, [categoryServices])

  // Filter by subcategory and search query
  const filteredServices = useMemo(() => {
    return categoryServices.filter((s) => {
      const matchesSubcat = activeSubcat === 'all' || s.subcategory === activeSubcat
      const q = searchQuery.toLowerCase().trim()
      const matchesSearch =
        !q ||
        s.name.toLowerCase().includes(q) ||
        s.description.toLowerCase().includes(q) ||
        s.subcategory.toLowerCase().includes(q) ||
        s.category.toLowerCase().includes(q) ||
        s.professional.toLowerCase().includes(q)
      return matchesSubcat && matchesSearch
    })
  }, [categoryServices, activeSubcat, searchQuery])

  const title = isAll ? 'All Services' : currentCategory?.label
  const blurb = isAll
    ? 'Every nursing, elder care, therapy and doctor service we offer, with prices.'
    : currentCategory?.blurb

  return (
    <section className="services-explorer-section" id={id}>
      <div className="container">
        <div className="category-dock-wrapper" ref={dockRef}>
          <nav className="category-dock" aria-label="Care categories">
            {dockItems.map((c) => {
              const isActive = c.slug === activeSlug
              return (
                <button
                  key={c.slug}
                  type="button"
                  className={`dock-tab ${isActive ? 'is-active' : ''}`}
                  onClick={() => handleCategorySelect(c.slug)}
                  aria-pressed={isActive}
                >
                  <span className="dock-art">
                    <ArtTile image={categoryImages[c.id]} icon={c.icon} size={34} />
                  </span>
                  <span className="dock-label">{c.label}</span>
                </button>
              )
            })}
          </nav>
        </div>

        <div className="sx-head">
          <div>
            <h1 className="sx-title">{title}</h1>
            <p className="sx-blurb">{blurb}</p>
          </div>
          <label className="search-input-wrap">
            <SearchIcon size={18} />
            <input
              type="search"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search services"
              className="explorer-search-input"
              aria-label="Search services"
            />
            {searchQuery && (
              <button type="button" className="search-clear-btn" onClick={() => setSearchQuery('')} aria-label="Clear search">
                ×
              </button>
            )}
          </label>
        </div>

        <div className="sx-bar">
          {subcategories.length > 2 ? (
            <div className="subcat-pills" role="group" aria-label="Filter by type">
              {subcategories.map((sub) => (
                <button
                  key={sub}
                  type="button"
                  className={`subcat-pill ${activeSubcat === sub ? 'is-active' : ''}`}
                  onClick={() => setActiveSubcat(sub)}
                  aria-pressed={activeSubcat === sub}
                >
                  {sub === 'all' ? 'All' : sub}
                </button>
              ))}
            </div>
          ) : (
            <span />
          )}
          <span className="sx-count">
            {filteredServices.length} {filteredServices.length === 1 ? 'service' : 'services'}
          </span>
        </div>

        {filteredServices.length > 0 ? (
          <div className="services-grid">
            {filteredServices.map((service, index) => (
              <ServiceCard
                key={service.id}
                service={service}
                index={index}
                onSelect={() => setSelectedService(service)}
              />
            ))}
          </div>
        ) : (
          <div className="no-services-found">
            <p>No services match &ldquo;{searchQuery}&rdquo;</p>
            <button
              type="button"
              className="btn btn-outline"
              onClick={() => {
                setSearchQuery('')
                setActiveSubcat('all')
              }}
            >
              Reset filters
            </button>
          </div>
        )}
      </div>

      {selectedService && <ServiceDialog service={selectedService} onClose={() => setSelectedService(null)} />}
    </section>
  )
}

function ServiceCard({ service: s, index, onSelect }: { service: Service; index: number; onSelect: () => void }) {
  const cat = categoryById[s.category] ?? categories[0]

  return (
    <button
      type="button"
      className="service-card spotlight"
      style={{ '--i': index % 12 } as React.CSSProperties}
      onClick={onSelect}
      aria-label={`${s.name}, ${s.price}. View details`}
    >
      <IconTile name={s.icon} image={s.imageUrl} ink={cat.ink} wash={cat.wash} size={44} />
      <span className="card-body">
        <span className="card-title">{s.name}</span>
        <span className="card-meta">
          {s.badge && <span className="card-badge">{s.badge}</span>}
          <ClockIcon size={13} />
          <span className="card-meta-text">
            {s.duration} · {s.professional}
          </span>
        </span>
      </span>
      <span className="card-price">
        {s.price}
        <ArrowIcon size={14} />
      </span>
    </button>
  )
}
