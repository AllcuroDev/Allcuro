import { useState, useMemo, useEffect } from 'react'
import { ArtTile, IconTile } from './CareIcon'
import { ArrowIcon, ClockIcon, SearchIcon, SparklesIcon, UserIcon } from './Icons'
import { ServiceDialog } from './ServiceDialog'
import { ALL_SLUG, categories, categoryById } from '../data/categories'
import { services } from '../data/services'
import type { Service } from '../data/types'

interface Props {
  initialSlug?: string
  onCategoryChange?: (slug: string) => void
  showTitle?: boolean
  id?: string
}

export function ServiceGridExplorer({
  initialSlug = 'nursing',
  onCategoryChange,
  showTitle = true,
  id = 'services-explorer',
}: Props) {
  const [activeSlug, setActiveSlug] = useState<string>(initialSlug)
  const [searchQuery, setSearchQuery] = useState('')
  const [activeSubcat, setActiveSubcat] = useState<string>('all')
  const [selectedService, setSelectedService] = useState<Service | null>(null)

  // Keep in sync if parent changes initialSlug
  useEffect(() => {
    if (initialSlug) {
      setActiveSlug(initialSlug)
      setActiveSubcat('all')
    }
  }, [initialSlug])

  const handleCategorySelect = (slug: string) => {
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
    return services.filter((s) => s.category === currentCategory.id)
  }, [isAll, currentCategory])

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

  return (
    <section className="services-explorer-section" id={id}>
      <div className="container">
        {showTitle && (
          <div className="explorer-header">
            <span className="eyebrow">
              <SparklesIcon size={14} /> Comprehensive Home Medical Care
            </span>
            <h2 className="explorer-title">
              Explore Services &amp; <span className="hl">Instant Pricing</span>
            </h2>
            <p className="explorer-subtitle">
              Click any category or procedure below for verified clinical protocols, transparent rates, and instant doorstep booking.
            </p>
          </div>
        )}

        {/* 1. 3D Category Dock / Horizontal Tabs */}
        <div className="category-dock-wrapper">
          <nav className="category-dock" aria-label="Care Categories">
            {categories.map((c) => {
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
                    <ArtTile name={c.art} size={42} />
                  </span>
                  <span className="dock-label">{c.label}</span>
                </button>
              )
            })}
            <button
              type="button"
              className={`dock-tab ${isAll ? 'is-active' : ''}`}
              onClick={() => handleCategorySelect(ALL_SLUG)}
              aria-pressed={isAll}
            >
              <span className="dock-art">
                <ArtTile name="see_all" size={42} />
              </span>
              <span className="dock-label">All Services</span>
            </button>
          </nav>
        </div>

        {/* 2. Active Category Banner & Search / Filter Controls */}
        <div className="explorer-controls">
          <div className="category-active-info">
            <div className="category-headline">
              <span className="category-icon-box">
                <ArtTile name={isAll ? 'see_all' : currentCategory?.art ?? 'nursing'} size={48} />
              </span>
              <div>
                <h3 className="category-active-title">
                  {isAll ? 'All Clinical & Home Services' : currentCategory?.label}
                </h3>
                <p className="category-active-blurb">
                  {isAll ? 'Browse all medical, nursing, elder, and rehab services.' : currentCategory?.blurb}
                </p>
              </div>
            </div>
            <div className="results-badge">
              <strong>{filteredServices.length}</strong> {filteredServices.length === 1 ? 'service' : 'services'} available
            </div>
          </div>

          <div className="explorer-search-filter-row">
            {/* Live Search Input */}
            <div className="search-input-wrap">
              <SearchIcon size={18} />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search injection, wound dressing, catheter, physiotherapy..."
                className="explorer-search-input"
                aria-label="Search services"
              />
              {searchQuery && (
                <button
                  type="button"
                  className="search-clear-btn"
                  onClick={() => setSearchQuery('')}
                  aria-label="Clear search"
                >
                  ×
                </button>
              )}
            </div>

            {/* Subcategory Pills */}
            {subcategories.length > 2 && (
              <div className="subcat-pills" role="tablist" aria-label="Subcategories">
                {subcategories.map((sub) => {
                  const isActive = activeSubcat === sub
                  return (
                    <button
                      key={sub}
                      type="button"
                      className={`subcat-pill ${isActive ? 'is-active' : ''}`}
                      onClick={() => setActiveSubcat(sub)}
                      role="tab"
                      aria-selected={isActive}
                    >
                      {sub === 'all' ? 'All' : sub}
                    </button>
                  )
                })}
              </div>
            )}
          </div>
        </div>

        {/* 3. THE SERVICES GRID (Rendered in a modern responsive card grid instead of a list) */}
        {filteredServices.length > 0 ? (
          <div className="services-grid" role="region" aria-label="Services Grid">
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
              Reset Filters
            </button>
          </div>
        )}
      </div>

      {/* 4. Interactive Detail Sheet */}
      {selectedService && (
        <ServiceDialog
          service={selectedService}
          onClose={() => setSelectedService(null)}
        />
      )}
    </section>
  )
}

function ServiceCard({
  service: s,
  index,
  onSelect,
}: {
  service: Service
  index: number
  onSelect: () => void
}) {
  const cat = categoryById[s.category] ?? categories[0]

  return (
    <div
      className="service-card"
      style={{ '--i': index % 12 } as React.CSSProperties}
      onClick={onSelect}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onSelect()
        }
      }}
    >
      <div className="card-top">
        <IconTile name={s.icon} ink={cat.ink} wash={cat.wash} size={48} />
        <div className="card-tags">
          <span className="card-cat-badge" style={{ color: cat.ink, background: cat.wash }}>
            {s.subcategory}
          </span>
          {s.badge && <span className="card-badge">{s.badge}</span>}
        </div>
      </div>

      <div className="card-content">
        <h4 className="card-title">{s.name}</h4>
        <p className="card-desc">{s.description}</p>
      </div>

      <div className="card-meta">
        <span className="meta-pill">
          <ClockIcon size={14} />
          <span>{s.duration}</span>
        </span>
        <span className="meta-pill">
          <UserIcon size={14} />
          <span>{s.professional}</span>
        </span>
      </div>

      <div className="card-footer">
        <div className="card-price-block">
          <span className="price-label">Starts at</span>
          <strong className="card-price">{s.price}</strong>
        </div>
        <button
          type="button"
          className="card-cta-btn"
          aria-label={`View details for ${s.name}`}
        >
          <span>View Details</span>
          <ArrowIcon size={14} />
        </button>
      </div>
    </div>
  )
}
