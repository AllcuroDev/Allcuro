// Renders the app's duotone care icons inline so `currentColor` picks up the tone.
const svgs = import.meta.glob<string>('../assets/icons/care/*.svg', {
  query: '?raw',
  import: 'default',
  eager: true,
})

const byName = Object.fromEntries(
  Object.entries(svgs).map(([path, svg]) => [path.split('/').pop()!.replace('.svg', ''), svg]),
)

interface Props {
  name: string
  size?: number
  color?: string
}

export function CareIcon({ name, size = 28, color }: Props) {
  return (
    <span
      className="care-icon"
      aria-hidden="true"
      style={{ width: size, height: size, color }}
      dangerouslySetInnerHTML={{ __html: byName[name] ?? byName.nursing }}
    />
  )
}

/**
 * A logo from Supabase Storage (services.image_url / service_categories.image_url),
 * or the bundled care icon [icon] while it loads or when there is none.
 */
export function Artwork({ image, icon, size, color }: { image?: string; icon: string; size: number; color?: string }) {
  if (!image) return <CareIcon name={icon} size={Math.round(size * 0.6)} color={color} />
  return (
    <img
      src={image}
      alt=""
      width={size}
      height={size}
      style={{ width: size, height: size, objectFit: 'contain', display: 'block' }}
      loading="lazy"
    />
  )
}

interface TileProps {
  name: string
  image?: string
  ink: string
  wash: string
  size?: number
}

/** Soft-washed tile holding a service's logo (falls back to its tinted care icon). */
export function IconTile({ name, image, ink, wash, size = 56 }: TileProps) {
  return (
    <span className="icon-tile" style={{ width: size, height: size, background: wash }}>
      {image ? (
        <Artwork image={image} icon={name} size={Math.round(size * 0.88)} />
      ) : (
        <CareIcon name={name} size={Math.round(size * 0.52)} color={ink} />
      )}
    </span>
  )
}

/** Neutral tile holding a category logo (same artwork as the app's home grid). */
export function ArtTile({ image, icon, size = 56 }: { image?: string; icon: string; size?: number }) {
  return (
    <span className="art-tile" style={{ width: size, height: size }}>
      <Artwork image={image} icon={icon} size={Math.round(size * 0.86)} />
    </span>
  )
}
