// Supabase Edge Function: doctor verification against the NMC Indian Medical Register.
//
// Routes (relative to https://<project-ref>.supabase.co/functions/v1):
//   GET /doctor/health                                -> { ok: true }
//   GET /doctor?name=<name>&regNo=<reg>&year=&state=  -> verification result
//   GET /doctor/states                                -> State Medical Council list (code + name)
//   GET /doctor/years                                 -> Year of Registration list

import { getStates, getYears, NmcError, validateQuery, verifyDoctor } from '../_shared/nmc.ts';

const API_KEY = Deno.env.get('API_KEY') ?? ''; // optional; if set, clients must send x-api-key
const CACHE_TTL_MS = Number(Deno.env.get('CACHE_TTL_MS')) || 60 * 60 * 1000;
const MIN_GAP_MS = 500; // space out calls to the government portal
// Comma-separated list of web origins allowed to call the API from a browser, or "*" for any.
const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

// Cache and throttle are per isolate: Supabase may run several isolates and recycle them,
// so these reduce load on NMC on a best-effort basis only.
const cache = new Map<string, { result: Record<string, unknown>; expiresAt: number }>();
let queue: Promise<unknown> = Promise.resolve();
let lastCallAt = 0;

function throttled<T>(fn: () => Promise<T>): Promise<T> {
  const run = queue.then(async () => {
    const wait = lastCallAt + MIN_GAP_MS - Date.now();
    if (wait > 0) await new Promise((r) => setTimeout(r, wait));
    lastCallAt = Date.now();
    return fn();
  });
  queue = run.catch(() => {});
  return run;
}

async function cached<T extends Record<string, unknown>>(key: string, fn: () => Promise<T>) {
  const hit = cache.get(key);
  if (hit && hit.expiresAt > Date.now()) return { ...(hit.result as T), cached: true };
  const result = await throttled(fn);
  cache.set(key, { result, expiresAt: Date.now() + CACHE_TTL_MS });
  return { ...result, cached: false };
}

function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('origin');
  if (!origin) return {};
  let allow: string;
  if (ALLOWED_ORIGINS.includes('*')) allow = '*';
  else if (ALLOWED_ORIGINS.includes(origin)) allow = origin;
  else return {};
  return {
    'Access-Control-Allow-Origin': allow,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    // authorization/apikey are needed when the Supabase gateway enforces JWT verification.
    'Access-Control-Allow-Headers': 'authorization, apikey, x-client-info, x-api-key, content-type',
    ...(allow === '*' ? {} : { Vary: 'Origin' }),
  };
}

function json(req: Request, status: number, body: unknown): Response {
  return new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(req) },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders(req) });

  const url = new URL(req.url);
  // Path arrives as /doctor/... on Supabase; take whatever follows the function name.
  const rest = url.pathname.replace(/^.*?\/doctor\/?/, '');

  if (req.method === 'GET' && rest === 'health') return json(req, 200, { ok: true });
  if (req.method !== 'GET' || !['', 'states', 'years'].includes(rest)) {
    return json(req, 404, { error: 'Not found' });
  }

  if (API_KEY && req.headers.get('x-api-key') !== API_KEY) {
    return json(req, 401, { error: 'Invalid API key' });
  }

  try {
    if (rest === 'states') return json(req, 200, await cached('states', async () => ({ states: await getStates() })));
    if (rest === 'years') return json(req, 200, await cached('years', async () => ({ years: await getYears() })));

    const p = url.searchParams;
    const q = {
      name: (p.get('name') ?? '').trim(),
      regNo: (p.get('regNo') ?? p.get('reg_no') ?? '').trim(),
      year: (p.get('year') ?? '').trim(),
      state: (p.get('state') ?? '').trim(),
    };
    const errors = validateQuery(q);
    if (errors.length) return json(req, 400, { error: errors.join('; ') });

    const key = ['doctor', q.name, q.regNo, q.year, q.state].map((v) => v.toUpperCase()).join('|');
    const result = await cached(key, () => verifyDoctor(q));
    return json(req, result.verified ? 200 : 404, result);
  } catch (err) {
    console.error(`Doctor lookup failed for ${url.search}:`, err);
    const e = err as Error;
    const upstream = err instanceof NmcError || e.name === 'TimeoutError' || e.name === 'TypeError';
    return json(req, upstream ? 502 : 500, {
      error: upstream ? 'NMC portal unavailable' : 'Internal error',
      detail: e.message,
    });
  }
});
