import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { useEffect, useRef, useState } from 'react'
import { positionAt, ROUTE } from '../data/route'
import { CloseIcon, ExpandIcon } from './Icons'

// Live map of the nurse travelling to the patient, ported from
// allcuro/lib/features/nurses/presentation/tracker/nurse_live_map.dart.

const icon = (className: string, html: string) =>
  L.divIcon({ className: '', html: `<span class="${className}">${html}</span>`, iconSize: [40, 40], iconAnchor: [20, 20] })

const nurseIcon = icon('map-pin map-pin-nurse', '🛵')
const homeIcon = icon('map-pin map-pin-home', '🏠')

export function LiveMap({ progress, nurseName }: { progress: number; nurseName: string }) {
  const el = useRef<HTMLDivElement>(null)
  const map = useRef<L.Map | null>(null)
  const layers = useRef<{ nurse: L.Marker; done: L.Polyline; left: L.Polyline } | null>(null)
  const [full, setFull] = useState(false)

  // Create the map once.
  useEffect(() => {
    if (!el.current) return
    const m = L.map(el.current, { zoomControl: false, attributionControl: true, scrollWheelZoom: false })
    // The app's CARTO voyager tiles now answer "API key required"; OSM's
    // tiles are fine for this volume. Move to a keyed provider before scaling up.
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap contributors',
    }).addTo(m)
    L.control.zoom({ position: 'bottomright' }).addTo(m)
    m.fitBounds(L.latLngBounds(ROUTE), { padding: [40, 40] })
    L.marker(ROUTE[ROUTE.length - 1], { icon: homeIcon, title: 'Patient address' }).addTo(m)
    layers.current = {
      left: L.polyline(ROUTE, { color: '#26593b', weight: 5, opacity: 0.35, dashArray: '2 10', lineCap: 'round' }).addTo(m),
      done: L.polyline([], { color: '#26593b', weight: 5, opacity: 0.9, lineCap: 'round' }).addTo(m),
      nurse: L.marker(ROUTE[0], { icon: nurseIcon, title: nurseName, zIndexOffset: 500 }).addTo(m),
    }
    map.current = m
    return () => {
      m.remove()
      map.current = null
      layers.current = null
    }
  }, [nurseName])

  // Move the nurse along the route.
  useEffect(() => {
    const l = layers.current
    if (!l) return
    const { at, next } = positionAt(progress)
    l.nurse.setLatLng(at)
    l.done.setLatLngs([...ROUTE.slice(0, next), at])
    l.left.setLatLngs([at, ...ROUTE.slice(next)])
  }, [progress])

  // Resize when entering / leaving full screen.
  useEffect(() => {
    map.current?.invalidateSize()
    if (map.current) map.current.fitBounds(L.latLngBounds(ROUTE), { padding: [60, 60] })
    if (!full) return
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setFull(false)
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [full])

  return (
    <div className={`live-map ${full ? 'is-full' : ''}`}>
      <div ref={el} className="live-map-canvas" role="img" aria-label={`Map showing ${nurseName} travelling to your address`} />
      <span className="live-tag">● LIVE</span>
      <button
        type="button"
        className="map-fab"
        onClick={() => setFull((f) => !f)}
        aria-label={full ? 'Close full-screen map' : 'Expand map'}
      >
        {full ? <CloseIcon size={18} /> : <ExpandIcon />}
      </button>
    </div>
  )
}
