// Supabase Edge Function: NUID verification against the Indian Nursing Council NRTS portal.
//
// Routes (relative to https://<project-ref>.supabase.co/functions/v1):
//   GET /nuid/health        -> { ok: true }
//   GET /nuid/<NUID>        -> lookup result
//   GET /nuid?nuid=<NUID>   -> same, via query string

import { isValidNuid, lookupNuid, NrtsError, type LookupResult } from '../_shared/nrts.ts';

const API_KEY = Deno.env.get('API_KEY') ?? ''; // optional; if set, clients must send x-api-key
const CACHE_TTL_MS = Number(Deno.env.get('CACHE_TTL_MS')) || 60 * 60 * 1000;
const MIN_GAP_MS = 500; // space out calls to the government portal
// Comma-separated list of web origins allowed to call the API from a browser, or "*" for any.
const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

// Cache and throttle are per isolate: Supabase may run several isolates and recycle them,
// so these reduce load on NRTS on a best-effort basis only.
const cache = new Map<string, { result: LookupResult; expiresAt: number }>();
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

async function verify(nuid: string) {
  const key = nuid.toUpperCase();
  const hit = cache.get(key);
  if (hit && hit.expiresAt > Date.now()) return { ...hit.result, cached: true };
  const result = await throttled(() => lookupNuid(key));
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
  // Path arrives as /nuid/... on Supabase; take whatever follows the function name.
  const rest = url.pathname.replace(/^.*?\/nuid\/?/, '');

  if (req.method === 'GET' && rest === 'health') return json(req, 200, { ok: true });
  if (req.method !== 'GET' || rest.includes('/')) return json(req, 404, { error: 'Not found' });

  if (API_KEY && req.headers.get('x-api-key') !== API_KEY) {
    return json(req, 401, { error: 'Invalid API key' });
  }

  let nuid: string;
  try {
    nuid = (rest ? decodeURIComponent(rest) : url.searchParams.get('nuid') ?? '').trim();
  } catch {
    return json(req, 400, { error: 'NUID must be 3-12 letters/digits' });
  }
  if (!isValidNuid(nuid)) return json(req, 400, { error: 'NUID must be 3-12 letters/digits' });

  try {
    const result = await verify(nuid);
    return json(req, result.found ? 200 : 404, result);
  } catch (err) {
    console.error(`Lookup failed for ${nuid}:`, err);
    const e = err as Error;
    const upstream = err instanceof NrtsError || e.name === 'TimeoutError' || e.name === 'TypeError';
    return json(req, upstream ? 502 : 500, {
      error: upstream ? 'NRTS portal unavailable' : 'Internal error',
      detail: e.message,
    });
  }
});
