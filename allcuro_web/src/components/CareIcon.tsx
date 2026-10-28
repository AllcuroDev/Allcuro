import { artUrl, serviceArtUrl } from './art'

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

interface TileProps {
  name: string
  ink: string
  wash: string
  size?: number
}

export function IconTile({ name, ink, wash, size = 56 }: TileProps) {
  const art = serviceArtUrl(name)
  if (art) {
    const imgSize = Math.round(size * 0.88)
    return (
      <span className="icon-tile" style={{ width: size, height: size, background: wash }}>
        <img
          src={art}
          alt=""
          width={imgSize}
          height={imgSize}
          style={{ width: imgSize, height: imgSize, objectFit: 'contain', display: 'block' }}
          loading="lazy"
        />
      </span>
    )
  }
  return (
    <span className="icon-tile" style={{ width: size, height: size, background: wash }}>
      <CareIcon name={name} size={Math.round(size * 0.52)} color={ink} />
    </span>
  )
}


/** Neutral tile holding a 3D-style category illustration (same artwork as the app's home grid). */
export function ArtTile({ name, size = 56 }: { name: string; size?: number }) {
  const img = Math.round(size * 0.86)
  return (
    <span className="art-tile" style={{ width: size, height: size }}>
      <img src={artUrl(name)} alt="" width={img} height={img} />
    </span>
  )
}
