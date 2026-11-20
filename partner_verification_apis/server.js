const http = require('node:http');
const { lookupNuid, isValidNuid, NrtsError } = require('./nrts');
const { verifyDoctor, validateQuery, getStates, getYears, NmcError } = require('./nmc');

const PORT = Number(process.env.PORT) || 3000;
const API_KEY = process.env.API_KEY || ''; // optional; if set, clients must send x-api-key
const CACHE_TTL_MS = Number(process.env.CACHE_TTL_MS) || 60 * 60 * 1000;
const MIN_GAP_MS = 500; // space out calls to the government portal
// Comma-separated list of web origins allowed to call the API from a browser, or "*" for any.
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '').split(',').map((o) => o.trim()).filter(Boolean);

const cache = new Map(); // key -> { result, expiresAt }

// Run upstream lookups one at a time per portal, with a small gap, so we don't hammer them.
function makeThrottle() {
  let queue = Promise.resolve();
  let lastCallAt = 0;
  return (fn) => {
    const run = queue.then(async () => {
      const wait = lastCallAt + MIN_GAP_MS - Date.now();
      if (wait > 0) await new Promise((r) => setTimeout(r, wait));
      lastCallAt = Date.now();
      return fn();
    });
    queue = run.catch(() => {});
    return run;
  };
}
const nrtsThrottled = makeThrottle();
const nmcThrottled = makeThrottle();

async function cached(key, throttled, fn) {
  const hit = cache.get(key);
  if (hit && hit.expiresAt > Date.now()) return { ...hit.result, cached: true };
  const result = await throttled(fn);
  cache.set(key, { result, expiresAt: Date.now() + CACHE_TTL_MS });
  return { ...result, cached: false };
}

function verify(nuid) {
  const key = nuid.toUpperCase();
  return cached(`nuid:${key}`, nrtsThrottled, () => lookupNuid(key));
}

function verifyDoctorCached(q) {
  const key = ['doctor', q.name, q.regNo, q.year, q.state].map((v) => String(v ?? '').trim().toUpperCase()).join('|');
  return cached(key, nmcThrottled, () => verifyDoctor(q));
}

function isUpstreamError(err) {
  return err instanceof NrtsError || err instanceof NmcError || err.name === 'TimeoutError' || err.name === 'TypeError';
}

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body, null, 2));
}

function setCors(req, res) {
  const origin = req.headers.origin;
  if (!origin) return;
  if (ALLOWED_ORIGINS.includes('*')) res.setHeader('Access-Control-Allow-Origin', '*');
  else if (ALLOWED_ORIGINS.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  } else return;
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'x-api-key');
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  setCors(req, res);
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  if (req.method === 'GET' && url.pathname === '/health') return send(res, 200, { ok: true });

  if (req.method === 'GET' && url.pathname.startsWith('/api/doctor')) return handleDoctor(req, res, url);

  const match = url.pathname.match(/^\/api\/nuid\/([^/]+)$/);
  if (req.method !== 'GET' || !match) return send(res, 404, { error: 'Not found' });

  if (API_KEY && req.headers['x-api-key'] !== API_KEY) return send(res, 401, { error: 'Invalid API key' });

  const nuid = decodeURIComponent(match[1]).trim();
  if (!isValidNuid(nuid)) return send(res, 400, { error: 'NUID must be 3-12 letters/digits' });

  try {
    const result = await verify(nuid);
    send(res, result.found ? 200 : 404, result);
  } catch (err) {
    console.error(`Lookup failed for ${nuid}:`, err);
    const upstream = isUpstreamError(err);
    send(res, upstream ? 502 : 500, { error: upstream ? 'NRTS portal unavailable' : 'Internal error', detail: err.message });
  }
});

// GET /api/doctor?name=&regNo=&year=&state=   verify a doctor (NMC Indian Medical Register)
// GET /api/doctor/states                       State Medical Council list for the form dropdown
// GET /api/doctor/years                        Year of Registration list for the form dropdown
async function handleDoctor(req, res, url) {
  if (API_KEY && req.headers['x-api-key'] !== API_KEY) return send(res, 401, { error: 'Invalid API key' });
  try {
    if (url.pathname === '/api/doctor/states') {
      return send(res, 200, await cached('doctor-states', nmcThrottled, async () => ({ states: await getStates() })));
    }
    if (url.pathname === '/api/doctor/years') {
      return send(res, 200, await cached('doctor-years', nmcThrottled, async () => ({ years: await getYears() })));
    }
    if (url.pathname !== '/api/doctor') return send(res, 404, { error: 'Not found' });

    const p = url.searchParams;
    const q = {
      name: (p.get('name') ?? '').trim(),
      regNo: (p.get('regNo') ?? p.get('reg_no') ?? '').trim(),
      year: (p.get('year') ?? '').trim(),
      state: (p.get('state') ?? '').trim(),
    };
    const errors = validateQuery(q);
    if (errors.length) return send(res, 400, { error: errors.join('; ') });

    const result = await verifyDoctorCached(q);
    send(res, result.verified ? 200 : 404, result);
  } catch (err) {
    console.error(`Doctor lookup failed for ${url.search}:`, err);
    const upstream = isUpstreamError(err);
    send(res, upstream ? 502 : 500, { error: upstream ? 'NMC portal unavailable' : 'Internal error', detail: err.message });
  }
}

server.listen(PORT, () => console.log(`Verification API listening on http://localhost:${PORT}`));
