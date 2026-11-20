// Client for the public "Check NUID Status" lookup on the Indian Nursing Council NRTS portal.
// The portal exposes a JSON endpoint used by its own "Fetch Details" button; it only needs a
// session cookie obtained by loading the login page first.

const BASE = 'https://nrts.indiannursingcouncil.gov.in';
const LOGIN_URL = `${BASE}/login.nic`;
const LOOKUP_URL = `${BASE}/getvalidusername.nic?method=getvalidnuid_nuid`;
const USER_AGENT =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36';
const TIMEOUT_MS = 20000;
const SESSION_TTL_MS = 10 * 60 * 1000;
const REVOKED_STAGE_CODE = '19';

let session = null; // { cookie, csrf, createdAt }
let sessionPromise = null;

class NrtsError extends Error {}

function isValidNuid(nuid) {
  return typeof nuid === 'string' && /^[A-Za-z0-9]{3,12}$/.test(nuid);
}

async function createSession() {
  const res = await fetch(LOGIN_URL, {
    headers: { 'User-Agent': USER_AGENT },
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) throw new NrtsError(`NRTS login page returned HTTP ${res.status}`);
  const cookie = res.headers
    .getSetCookie()
    .map((c) => c.split(';')[0])
    .join('; ');
  if (!cookie) throw new NrtsError('NRTS did not issue a session cookie');
  const html = await res.text();
  const csrf = html.match(/<meta name="_csrf" content="([^"]*)"/)?.[1] ?? '';
  return { cookie, csrf, createdAt: Date.now() };
}

async function getSession(forceNew = false) {
  if (!forceNew && session && Date.now() - session.createdAt < SESSION_TTL_MS) return session;
  // Share one in-flight session request between concurrent lookups.
  if (!sessionPromise) {
    sessionPromise = createSession()
      .then((s) => (session = s))
      .finally(() => (sessionPromise = null));
  }
  return sessionPromise;
}

async function rawLookup(nuid, s) {
  const res = await fetch(LOOKUP_URL, {
    method: 'POST',
    headers: {
      'User-Agent': USER_AGENT,
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-TOKEN': s.csrf,
      Referer: LOGIN_URL,
      Cookie: s.cookie,
    },
    body: new URLSearchParams({ nuid }),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) throw new NrtsError(`NRTS lookup returned HTTP ${res.status}`);
  const text = await res.text();
  try {
    return JSON.parse(text);
  } catch {
    return null; // HTML instead of JSON means the session expired.
  }
}

function normalize(nuid, data) {
  if (data.error !== undefined) {
    return { nuid, found: false, message: data.error };
  }
  return {
    nuid: data.nuid ?? nuid,
    found: true,
    status: data.currentstage_code === REVOKED_STAGE_CODE ? 'Revoked' : 'Active',
    name: data.appl_name ?? null,
    council: data.councilname ?? null,
    registeredAs: data.registeredas ?? null,
    registrationNumber: data.regnum ?? null,
    designation: data.designation ?? null,
    currentEmployment: data.currentemp ?? null,
    country: data.country ?? null,
    institute: data.nameofinst ?? null,
    instituteAddress: data.instaddress ?? null,
    sector: data.sector ?? null,
    verifyUrl: data.usercode ? `${BASE}/verifySign.jsp?refno=${encodeURIComponent(data.usercode)}` : null,
    raw: data,
  };
}

async function lookupNuid(nuid) {
  let data = await rawLookup(nuid, await getSession());
  if (data === null) data = await rawLookup(nuid, await getSession(true));
  if (data === null) throw new NrtsError('NRTS returned an unexpected (non-JSON) response');
  return normalize(nuid, data);
}

module.exports = { lookupNuid, isValidNuid, NrtsError };
