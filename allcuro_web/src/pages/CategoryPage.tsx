import { Link } from '../components/Link'
import { CallBand } from '../components/Sections'
import { ServiceGridExplorer } from '../components/ServiceGridExplorer'
import { ALL_SLUG, categories, categoryPath } from '../data/categories'
import { navigate } from '../router'

export function CategoryPage({ slug }: { slug: string }) {
  const isAll = slug === ALL_SLUG
  const category = categories.find((c) => c.slug === slug)

  if (!isAll && !category) return <NotFound />

  return (
    <>
      <div className="container cat-page-crumbs">
        <nav className="crumbs" aria-label="Breadcrumb">
          <Link to="/">Home</Link>
          <span aria-hidden="true">›</span>
          <span aria-current="page">{isAll ? 'All Services' : category!.label}</span>
        </nav>
      </div>

      <ServiceGridExplorer
        initialSlug={slug}
        onCategoryChange={(newSlug) => {
          navigate(categoryPath(newSlug))
        }}
      />

      <CallBand />
    </>
  )
}

export function NotFound() {
  return (
    <div className="container not-found">
      <h1>Page not found</h1>
      <p>This page does not exist. You can see all our services or go back home.</p>
      <div className="hero-actions">
        <Link to={categoryPath(ALL_SLUG)} className="btn btn-primary btn-lg">
          See all services
        </Link>
        <Link to="/" className="btn btn-outline btn-lg">
          Go home
        </Link>
      </div>
    </div>
  )
}
