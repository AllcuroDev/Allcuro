// Simulated nurse route (Domlur → Indiranagar 12th Main), from
// allcuro/lib/features/nurses/presentation/tracker/nurse_live_map.dart.
// Replace with partner-app GPS pings once they exist.

export const ROUTE: [number, number][] = [
  [12.9582, 77.6348],
  [12.9596, 77.6364],
  [12.9613, 77.6372],
  [12.9629, 77.6379],
  [12.9642, 77.6396],
  [12.9658, 77.6401],
  [12.9676, 77.6405],
  [12.9691, 77.6413],
  [12.9703, 77.6429],
  [12.9718, 77.6433],
]

/** Great-circle distance in metres (haversine). */
function metres([lat1, lon1]: [number, number], [lat2, lon2]: [number, number]) {
  const rad = Math.PI / 180
  const h =
    Math.sin(((lat2 - lat1) * rad) / 2) ** 2 +
    Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(((lon2 - lon1) * rad) / 2) ** 2
  return 2 * 6_371_000 * Math.asin(Math.sqrt(h))
}

const CUMULATIVE = ROUTE.reduce<number[]>((acc, p, i) => [...acc, i ? acc[i - 1] + metres(ROUTE[i - 1], p) : 0], [])
export const ROUTE_METRES = CUMULATIVE[CUMULATIVE.length - 1]

/** Nurse position after travelling `t` (0..1) of the route, plus the index of the next route point. */
export function positionAt(t: number): { at: [number, number]; next: number } {
  const target = ROUTE_METRES * Math.min(1, Math.max(0, t))
  for (let i = 1; i < CUMULATIVE.length; i++) {
    if (CUMULATIVE[i] >= target) {
      const seg = CUMULATIVE[i] - CUMULATIVE[i - 1]
      const f = seg ? (target - CUMULATIVE[i - 1]) / seg : 0
      const [a, b] = [ROUTE[i - 1], ROUTE[i]]
      return { at: [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f], next: i }
    }
  }
  return { at: ROUTE[ROUTE.length - 1], next: ROUTE.length - 1 }
}
