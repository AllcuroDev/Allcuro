// Client for the public "Indian Medical Register" advanced search on the National Medical Commission
// site (https://nmc.org.in/information-desk/indian-medical-register). The page calls a JSON endpoint
// with plain GET requests; no session or token is needed. The "View" button on the site only shows
// fields that are already in the search response, so one search call returns all the details.

const BASE = 'https://nmc.org.in/indian-medical-register';
const USER_AGENT =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36';
const TIMEOUT_MS = 20000;
const PER_PAGE = 100; // the NMC endpoint caps per_page at 100
const MAX_PAGES = 5;

class NmcError extends Error {}

async function getJson(path, params) {
  const url = `${BASE}/${path}${params ? `?${new URLSearchParams(params)}` : ''}`;
  const res = await fetch(url, {
    headers: {
      'User-Agent': USER_AGENT,
      Accept: 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      Referer: 'https://nmc.org.in/information-desk/indian-medical-register',
    },
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) throw new NmcError(`NMC ${path} returned HTTP ${res.status}`);
  let data;
  try {
    data = JSON.parse(await res.text());
  } catch {
    throw new NmcError(`NMC ${path} returned a non-JSON response`);
  }
  if (!data || data.success !== true) throw new NmcError(`NMC ${path} reported failure`);
  return data;
}

// --- input handling ---------------------------------------------------------------------------

const TITLES = new Set(['DR', 'DOCTOR', 'MR', 'MRS', 'MS', 'MISS', 'PROF']);

// "Dr. Yukti Sharma" and "SHARMA, YUKTI" both become ["YUKTI", "SHARMA"] / ["SHARMA", "YUKTI"].
function nameTokens(name) {
  return String(name ?? '')
    .toUpperCase()
    .replace(/[^A-Z]+/g, ' ')
    .split(' ')
    .filter((t) => t && !TITLES.has(t));
}

function normalizeRegNo(regNo) {
  return String(regNo ?? '').toUpperCase().replace(/\s+/g, '');
}

function sameRegNo(a, b) {
  const x = normalizeRegNo(a);
  const y = normalizeRegNo(b);
  if (!x || !y) return false;
  return x === y || x.replace(/^0+/, '') === y.replace(/^0+/, '');
}

// Every word the user typed must appear in the register's name, in any order.
// A single letter counts as an initial and matches any word starting with it.
function nameMatches(input, recordName) {
  const want = nameTokens(input);
  const have = nameTokens(recordName);
  if (!want.length) return false;
  return want.every((w) => (w.length === 1 ? have.some((h) => h.startsWith(w)) : have.includes(w)));
}

function validateQuery({ name, regNo, year, state }) {
  const errors = [];
  if (nameTokens(name).length === 0) errors.push('name is required');
  if (!normalizeRegNo(regNo)) errors.push('regNo is required');
  else if (!/^[A-Za-z0-9\/\-\s.]{1,30}$/.test(String(regNo).trim())) errors.push('regNo has invalid characters');
  if (year && !/^\d{4}$/.test(String(year).trim())) errors.push('year must be a 4-digit year');
  if (state && !/^[A-Za-z]{1,10}$/.test(String(state).trim())) errors.push('state must be a council code such as UP, DEL or MAH (see /states)');
  return errors;
}

// --- upstream calls ---------------------------------------------------------------------------

async function getStates() {
  const data = await getJson('states');
  return data.states ?? [];
}

async function getYears() {
  const data = await getJson('years');
  return data.years ?? [];
}

// One "advance" search, the same request the site's Advance Search button makes, following pages.
async function advanceSearch({ name, regNo, year, state }) {
  const rows = [];
  for (let page = 1; page <= MAX_PAGES; page++) {
    const data = await getJson('search', {
      search_type: 'advance',
      name,
      reg_no: regNo,
      year: year ?? '',
      state: state ?? '',
      page,
      per_page: PER_PAGE,
    });
    rows.push(...(data.data ?? []));
    const total = data.pagination?.total ?? rows.length;
    if (rows.length >= total || !(data.data ?? []).length) break;
  }
  return rows;
}

function isRemoved(status) {
  return status !== null && status !== undefined && String(status).trim() !== '' && String(status).trim() !== '0';
}

function normalizeDoctor(r) {
  return {
    id: r.id ?? null,
    name: r.name ?? null,
    fatherOrHusbandName: r.father_name || null,
    dateOfBirth: r.dob || null,
    registrationNumber: r.registration_no ?? null,
    registrationDate: r.registration_date || null,
    yearOfInfo: r.year_of_info ?? null,
    uprnNumber: r.uprn_no || null,
    stateMedicalCouncil: r.state_medical_council ?? null,
    stateCode: r.state_code ?? null,
    qualification: r.qualification || null,
    qualificationYear: r.qualification_year || null,
    university: r.university || null,
    additionalQualifications: (Array.isArray(r.additional_qualifications) ? r.additional_qualifications : [])
      .map((q) => ({ qualification: q.qualification || null, year: q.year || null, university: q.university || null }))
      .filter((q) => q.qualification || q.year || q.university),
    permanentAddress: r.permanent_address || null,
    removed: isRemoved(r.removed_status),
    raw: r,
  };
}

// Verify a doctor against the Indian Medical Register.
// Returns { verified, reason, doctor?, otherMatches? }.
async function verifyDoctor({ name, regNo, year, state }) {
  const regNoClean = String(regNo).trim();
  const yearClean = year ? String(year).trim() : '';
  let stateClean = state ? String(state).trim().toUpperCase() : '';
  if (stateClean === 'ALL') stateClean = '';

  // NMC matches the name as a plain substring ("YUKTI SHARMA" will not find "SHARMA, YUKTI"),
  // so search by the longest word only and check the full name ourselves.
  const tokens = nameTokens(name);
  const searchWord = [...tokens].sort((a, b) => b.length - a.length)[0];

  const rows = await advanceSearch({ name: searchWord, regNo: regNoClean, year: yearClean, state: stateClean });
  const sameReg = rows.filter((r) => sameRegNo(r.registration_no, regNoClean));
  const matches = sameReg.filter((r) => nameMatches(name, r.name)).map(normalizeDoctor);

  const query = { name, regNo: regNoClean, year: yearClean || null, state: stateClean || null };

  if (!matches.length) {
    return {
      verified: false,
      reason: sameReg.length ? 'name_mismatch' : 'not_found',
      message: sameReg.length
        ? 'A doctor with this registration number exists, but the name does not match'
        : 'No doctor found in the Indian Medical Register for these details',
      query,
    };
  }

  // Prefer an active record if several councils list the same registration number and name.
  matches.sort((a, b) => Number(a.removed) - Number(b.removed));
  const [doctor, ...otherMatches] = matches;
  return {
    verified: !doctor.removed,
    reason: doctor.removed ? 'removed' : 'found',
    message: doctor.removed
      ? 'Doctor is in the Indian Medical Register but marked as removed'
      : 'Doctor found in the Indian Medical Register',
    query,
    doctor,
    ...(otherMatches.length ? { otherMatches } : {}),
  };
}

module.exports = { verifyDoctor, validateQuery, getStates, getYears, NmcError };
