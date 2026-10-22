import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { motionOn } from '../motion'

// Background illustration for the home page below the trust band: a DNA double
// helix winding down the page that forms as the visitor scrolls and twists with
// the scroll, with small line-art motifs that bloom as it reaches them and
// drift in parallax. Fills its nearest positioned parent; purely decorative.

type Size = { w: number; h: number }

// Where the thread swings to at each bend, as a share of the width.
const BENDS = [0.5, 0.12, 0.88, 0.18, 0.84, 0.1, 0.9]
const BEND_EVERY = 560
// The helix's growing tip sits this far down the viewport.
const READ_LINE = 0.62
// Helix geometry, in px along the spine.
const TWIST = 210 // one full turn
const STEP = 4 // sampling resolution
const RUNG_EVERY = 18
const FADE = 110 // soft edge at the growing tip
const SCROLL_TWIST = 0.006 // radians of twist per px scrolled

// Base-pair rung colours: each rung is two halves, like A–T and G–C.
const BASE_COLORS = ['#3A8357', '#ED6C00', '#BE185D', '#1D4ED8']
const PAIRS = [[0, 1], [1, 0], [2, 3], [3, 2]]

type Sample = { x: number; y: number; nx: number; ny: number; s: number }

/** Points along the spine with their unit normals, every STEP px. */
function sampleSpine(path: SVGPathElement): Sample[] {
  const len = path.getTotalLength()
  const n = Math.ceil(len / STEP)
  const pts = Array.from({ length: n + 1 }, (_, i) => path.getPointAtLength((len * i) / n))
  return pts.map((p, i) => {
    const a = pts[Math.max(0, i - 1)]
    const b = pts[Math.min(n, i + 1)]
    const l = Math.hypot(b.x - a.x, b.y - a.y) || 1
    return { x: p.x, y: p.y, nx: -(b.y - a.y) / l, ny: (b.x - a.x) / l, s: (len * i) / n }
  })
}

/**
 * The helix around the spine at a given twist. Each strand is split into the
 * stretches facing the viewer and those turned away, so the front can be drawn
 * over the back; rungs are bucketed by colour so each colour is one path.
 */
function helixPaths(spine: Sample[], phase: number, amp: number) {
  const k = (2 * Math.PI) / TWIST
  const out = { front: '', back: '', nodes: '', rungs: BASE_COLORS.map(() => '') }
  const pt = (p: Sample, off: number) => `${(p.x + p.nx * off).toFixed(1)},${(p.y + p.ny * off).toFixed(1)}`

  for (const side of [1, -1]) {
    let wasFront: boolean | null = null
    for (const p of spine) {
      const t = p.s * k + phase
      const xy = pt(p, amp * Math.sin(t) * side)
      const isFront = Math.cos(t) * side > 0
      if (isFront === wasFront) {
        out[isFront ? 'front' : 'back'] += `L${xy}`
        continue
      }
      // Close the previous stretch here so the strand stays continuous.
      if (wasFront !== null) out[wasFront ? 'front' : 'back'] += `L${xy}`
      out[isFront ? 'front' : 'back'] += `M${xy}`
      wasFront = isFront
    }
  }

  const every = Math.round(RUNG_EVERY / STEP)
  for (let i = 0, j = 0; i < spine.length; i += every, j++) {
    const p = spine[i]
    const t = p.s * k + phase
    const sin = Math.sin(t)
    const [c1, c2] = PAIRS[(j * 7 + ((j * j) % 5)) % PAIRS.length]
    const mid = pt(p, 0)
    out.rungs[c1] += `M${pt(p, amp * sin * 0.88)}L${mid}`
    out.rungs[c2] += `M${mid}L${pt(p, -amp * sin * 0.88)}`
    // A bead where the rung meets the strand nearest the viewer.
    const [x, y] = pt(p, amp * sin * (Math.cos(t) > 0 ? 1 : -1)).split(',').map(Number)
    out.nodes += `M${x - 2.4},${y}a2.4,2.4 0 1,0 4.8,0a2.4,2.4 0 1,0 -4.8,0`
  }
  return out
}

function threadPath({ w, h }: Size) {
  const n = Math.max(2, Math.round(h / BEND_EVERY))
  const pts = Array.from({ length: n + 1 }, (_, i) => [
    w * (i === n ? 0.5 : BENDS[i % BENDS.length]),
    (h * i) / n,
  ])
  return pts.reduce((d, [x, y], i) => {
    if (i === 0) return `M${x},${y}`
    const [px, py] = pts[i - 1]
    const dy = y - py
    return `${d} C${px},${py + dy * 0.55} ${x},${y - dy * 0.55} ${x},${y}`
  }, '')
}

const glyphs: Record<string, ReactNode> = {
  plus: <path d="M12 4.5v15M4.5 12h15" />,
  heart: <path d="M12 20s-7.5-4.6-7.5-10.2A4.2 4.2 0 0 1 12 7.3a4.2 4.2 0 0 1 7.5 2.5C19.5 15.4 12 20 12 20z" />,
  leaf: <path d="M5 19C5 10.5 10.5 5 19 5c0 8.5-5.5 14-14 14zm0 0 7.5-7.5" />,
  sparkle: <path d="M12 3c.9 4.8 2.6 6.6 8 9-5.4 2.4-7.1 4.2-8 9-.9-4.8-2.6-6.6-8-9 5.4-2.4 7.1-4.2 8-9z" />,
  pill: (
    <>
      <rect x="2.5" y="8.25" width="19" height="7.5" rx="3.75" transform="rotate(-40 12 12)" />
      <path d="m9.6 9.2 4.8 5.6" />
    </>
  ),
  ring: <circle cx="12" cy="12" r="7.5" />,
  pulse: <path d="M2.5 12.5h4.5l2-4.5 3.5 9 2.5-6 1.5 1.5h5" />,
}

// x/y are shares of the area; k is parallax speed, r is rotation per px scrolled.
const motifs = [
  { g: 'plus', x: 0.05, y: 0.04, s: 30, k: -0.08, r: 0.02, tone: '#26593B' },
  { g: 'sparkle', x: 0.93, y: 0.08, s: 22, k: 0.06, r: -0.03, tone: '#B45309', wide: true },
  { g: 'heart', x: 0.9, y: 0.17, s: 30, k: -0.1, r: 0.015, tone: '#BE185D' },
  { g: 'leaf', x: 0.04, y: 0.24, s: 34, k: 0.07, r: -0.02, tone: '#0F766E', wide: true },
  { g: 'pulse', x: 0.07, y: 0.33, s: 40, k: -0.05, r: 0, tone: '#26593B' },
  { g: 'ring', x: 0.94, y: 0.36, s: 20, k: 0.12, r: 0, tone: '#1D4ED8', wide: true },
  { g: 'pill', x: 0.91, y: 0.46, s: 32, k: -0.07, r: 0.025, tone: '#6D28D9' },
  { g: 'sparkle', x: 0.06, y: 0.52, s: 18, k: 0.1, r: 0.04, tone: '#ED6C00', wide: true },
  { g: 'plus', x: 0.95, y: 0.6, s: 22, k: 0.05, r: -0.02, tone: '#0E7490', wide: true },
  { g: 'heart', x: 0.05, y: 0.66, s: 26, k: -0.09, r: -0.015, tone: '#BE185D' },
  { g: 'leaf', x: 0.92, y: 0.75, s: 30, k: 0.08, r: 0.02, tone: '#3A8357' },
  { g: 'ring', x: 0.08, y: 0.8, s: 16, k: -0.12, r: 0, tone: '#B45309', wide: true },
  { g: 'plus', x: 0.06, y: 0.9, s: 26, k: 0.06, r: 0.02, tone: '#26593B' },
  { g: 'sparkle', x: 0.93, y: 0.93, s: 24, k: -0.06, r: -0.03, tone: '#3A8357' },
]

const blobs = [
  { x: 0.02, y: 0.08, s: 420, k: -0.14, tone: 'rgb(120 200 150 / 0.22)' },
  { x: 0.98, y: 0.38, s: 380, k: 0.1, tone: 'rgb(250 200 140 / 0.18)' },
  { x: 0.0, y: 0.62, s: 360, k: -0.1, tone: 'rgb(240 170 200 / 0.14)' },
  { x: 1.0, y: 0.88, s: 400, k: 0.12, tone: 'rgb(140 190 240 / 0.16)' },
]

export function FlowBackground() {
  const root = useRef<HTMLDivElement>(null)
  const spineRef = useRef<SVGPathElement>(null)
  const front = useRef<SVGPathElement>(null)
  const back = useRef<SVGPathElement>(null)
  const nodes = useRef<SVGPathElement>(null)
  const rungs = useRef<(SVGPathElement | null)[]>([])
  const solid = useRef<SVGRectElement>(null)
  const fade = useRef<SVGRectElement>(null)
  const head = useRef<SVGGElement>(null)
  const [size, setSize] = useState<Size | null>(null)

  useEffect(() => {
    const area = root.current?.parentElement
    if (!area) return
    const ro = new ResizeObserver(() => {
      const w = area.clientWidth
      const h = area.clientHeight
      setSize((s) => (s && s.w === w && s.h === h ? s : { w, h }))
    })
    ro.observe(area)
    return () => ro.disconnect()
  }, [])

  useEffect(() => {
    const el = root.current
    const path = spineRef.current
    if (!el || !path || !size) return
    const spine = sampleSpine(path)
    const amp = size.w < 700 ? 20 : 34
    const lit = Array.from(el.querySelectorAll<HTMLElement>('.flow-motif'))

    const drawHelix = (phase: number) => {
      const h = helixPaths(spine, phase, amp)
      front.current?.setAttribute('d', h.front)
      back.current?.setAttribute('d', h.back)
      nodes.current?.setAttribute('d', h.nodes)
      h.rungs.forEach((d, i) => rungs.current[i]?.setAttribute('d', d))
    }
    const reveal = (y: number) => {
      solid.current?.setAttribute('height', String(Math.max(0, y - FADE)))
      fade.current?.setAttribute('y', String(y - FADE))
    }

    if (!motionOn()) {
      drawHelix(0)
      reveal(size.h + FADE)
      lit.forEach((m) => m.classList.add('is-lit'))
      return
    }

    let frame = 0
    const update = () => {
      frame = 0
      const top = el.getBoundingClientRect().top
      const y = window.innerHeight * READ_LINE - top
      drawHelix(-top * SCROLL_TWIST)
      reveal(y)
      // The glowing tip rides the spine at the reading line.
      const tip = spine.find((p) => p.y >= y)
      head.current?.classList.toggle('is-on', !!tip && y > 0)
      if (tip) head.current?.setAttribute('transform', `translate(${tip.x} ${tip.y})`)
      el.style.setProperty('--sy', String(-top))
      lit.forEach((m, i) => m.classList.toggle('is-lit', y > motifs[i].y * size.h - 60))
    }
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(update)
    }
    update()
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll)
    return () => {
      cancelAnimationFrame(frame)
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }, [size])

  return (
    <div className="flow-bg" ref={root} aria-hidden="true">
      {blobs.map((b, i) => (
        <span
          key={i}
          className="flow-blob"
          style={
            {
              left: `${b.x * 100}%`,
              top: `${b.y * 100}%`,
              width: b.s,
              height: b.s,
              background: `radial-gradient(circle, ${b.tone}, transparent 70%)`,
              '--k': b.k,
            } as CSSProperties
          }
        />
      ))}

      {size && (
        <svg className="flow-thread" width={size.w} height={size.h} viewBox={`0 0 ${size.w} ${size.h}`}>
          <defs>
            <linearGradient id="dna-ink" x1="0" y1="0" x2="0" y2={size.h} gradientUnits="userSpaceOnUse">
              <stop offset="0" stopColor="#43845b" />
              <stop offset="0.45" stopColor="#26593b" />
              <stop offset="0.75" stopColor="#3a8357" />
              <stop offset="1" stopColor="#5fae7e" />
            </linearGradient>
            <linearGradient id="dna-fade" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#fff" />
              <stop offset="1" stopColor="#000" />
            </linearGradient>
            <mask id="dna-reveal" maskUnits="userSpaceOnUse" x="0" y="0" width={size.w} height={size.h}>
              <rect ref={solid} x="0" y="0" width={size.w} height="0" fill="#fff" />
              <rect ref={fade} x="0" y={-FADE} width={size.w} height={FADE} fill="url(#dna-fade)" />
            </mask>
            {/* Paint is set as attributes: CSS selectors don't reach the <use> copies. */}
            <g id="dna" fill="none" strokeLinecap="round">
              <path ref={back} stroke="#a9d3b7" strokeWidth="1.8" />
              {BASE_COLORS.map((c, i) => (
                <path
                  key={c}
                  stroke={c}
                  strokeWidth="2"
                  strokeOpacity="0.5"
                  ref={(node) => {
                    rungs.current[i] = node
                  }}
                />
              ))}
              <path ref={front} stroke="url(#dna-ink)" strokeWidth="2.8" />
              <path ref={nodes} fill="#fff" stroke="#26593b" strokeWidth="1.4" />
            </g>
          </defs>
          <path d={threadPath(size)} ref={spineRef} fill="none" stroke="none" />
          <use href="#dna" className="dna-ghost" />
          <use href="#dna" mask="url(#dna-reveal)" />
          <g className="flow-head" ref={head}>
            <circle className="flow-halo" r="22" />
            <circle className="flow-dot" r="5" />
          </g>
        </svg>
      )}

      {motifs.map((m, i) => (
        <span
          key={i}
          className={`flow-motif ${m.wide ? 'is-wide' : ''}`}
          style={
            {
              left: `${m.x * 100}%`,
              top: `${m.y * 100}%`,
              width: m.s,
              height: m.s,
              color: m.tone,
              '--k': m.k,
              '--r': m.r,
              '--bob': `${5 + (i % 4)}s`,
            } as CSSProperties
          }
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
            {glyphs[m.g]}
          </svg>
        </span>
      ))}
    </div>
  )
}
