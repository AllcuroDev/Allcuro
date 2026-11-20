# Nurse & Doctor Verification API

Wraps two public government lookups as a JSON API. No dependencies; Node 20+.

- **Nurses**: the **Check NUID Status** lookup on the Indian Nursing Council NRTS portal
  (https://nrts.indiannursingcouncil.gov.in/login.nic)
- **Doctors**: the **Advance Search** of the NMC Indian Medical Register
  (https://nmc.org.in/information-desk/indian-medical-register)

## Run

```bash
npm start                      # http://localhost:3000
PORT=8080 API_KEY=secret npm start
```

| Env var        | Default   | Purpose                                           |
| -------------- | --------- | ------------------------------------------------- |
| `PORT`         | `3000`    | Port to listen on                                 |
| `API_KEY`      | (none)    | If set, clients must send `x-api-key: <value>`    |
| `CACHE_TTL_MS` | `3600000` | How long to cache a lookup result (1 hour)        |
| `ALLOWED_ORIGINS` | (none) | Comma-separated web origins allowed to call from a browser (CORS), or `*` |

## Endpoints

`GET /api/nuid/:nuid`

- `200` – found: `{ nuid, found: true, status: "Active" | "Revoked", name, council, registeredAs, registrationNumber, designation, ..., verifyUrl, raw }`
- `404` – `{ nuid, found: false, message: "No details found" }`
- `400` – invalid NUID (must be 3–12 letters/digits)
- `502` – the NRTS portal is down or changed its response

`GET /api/doctor?name=<name>&regNo=<registration no>&year=<year>&state=<council code>`

The same fields as the NMC Advance Search form. `name` and `regNo` are required; `year`
(Year of Registration) and `state` (State Medical Council code, e.g. `UP`, `DEL`, `MAH`) are optional.

```bash
curl 'http://localhost:3000/api/doctor?name=Yukti%20Sharma&regNo=112345&year=2024&state=UP'
```

- `200` – verified: `{ verified: true, reason: "found", doctor: { name, fatherOrHusbandName, dateOfBirth,
  registrationNumber, registrationDate, yearOfInfo, uprnNumber, stateMedicalCouncil, stateCode,
  qualification, qualificationYear, university, additionalQualifications[], permanentAddress, removed, raw } }`.
  These are all the fields the site's **View** button shows. If more than one record matches, the rest are in `otherMatches`.
- `404` – not verified, with `reason`:
  - `not_found`: no record with this registration number (and year/state, if given)
  - `name_mismatch`: the registration number exists but the name does not match
  - `removed`: the record matches but NMC marks it as removed (the record is still returned in `doctor`)
- `400` – missing or invalid fields
- `502` – the NMC site is down or changed its response

A doctor counts as **verified** when the registration number matches exactly and every word of the
given name appears in the register's name, in any order. Titles such as "Dr." are ignored, and a
single letter matches as an initial. NMC itself only does substring matching, so a search for
`12345` would also return `112345`, and `Yukti Sharma` would not find `SHARMA, YUKTI`. This API corrects for both.

`GET /api/doctor/states` – State Medical Council list `[{ code, name }]` for the form dropdown.
`GET /api/doctor/years` – Year of Registration list for the form dropdown.

`GET /health` – liveness check.

## How it works

### Doctors (NMC)

The NMC page calls `https://nmc.org.in/indian-medical-register/search?search_type=advance&name=&reg_no=&year=&state=`
with plain GET requests; no session is needed. The response already holds every detail the
**View** popup shows. We send the registration number, year, state and the longest word of the
name, then check the exact registration number and the full name ourselves.

### Nurses (NRTS)

1. Loads `login.nic` to get a session cookie (reused for 10 minutes).
2. POSTs `nuid=<value>` to `getvalidusername.nic?method=getvalidnuid_nuid`, the same call the
   site's "Fetch Details" button makes.
3. If the portal answers with HTML instead of JSON (expired session), gets a new session and retries once.

Upstream calls are run one at a time per portal with a 500 ms gap, and results are cached, to keep load on
the government portals low. Neither portal is an official API, so either can change without notice.

## Deploy as a Supabase Edge Function

The same API is available as a Deno edge function in `supabase/functions/nuid/`
(the NRTS client is in `supabase/functions/_shared/nrts.ts`), and the doctor API in
`supabase/functions/doctor/` (NMC client in `supabase/functions/_shared/nmc.ts`).

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase secrets set API_KEY=secret ALLOWED_ORIGINS=https://your-app.example   # optional
supabase functions deploy nuid
supabase functions deploy doctor
```

Endpoints (base `https://<project-ref>.supabase.co/functions/v1`):

- `GET /nuid/<NUID>` or `GET /nuid?nuid=<NUID>`: same responses as `/api/nuid/:nuid` above
- `GET /nuid/health`: liveness check
- `GET /doctor?name=<name>&regNo=<reg>&year=<year>&state=<code>`: same responses as `/api/doctor` above
- `GET /doctor/states`, `GET /doctor/years`: dropdown lists
- `GET /doctor/health`: liveness check

By default Supabase requires a JWT, so callers must send `Authorization: Bearer <anon key>`.
To make it callable with only `x-api-key`, deploy with `supabase functions deploy nuid --no-verify-jwt`
and set the `API_KEY` secret.

Local run: `supabase functions serve nuid` (needs Docker), then call
`http://localhost:54321/functions/v1/nuid/<NUID>`.

The cache and the 500 ms throttle live in memory, one copy per edge isolate. Supabase may start
several isolates and recycle them, so they only reduce load on the portal on a best-effort basis.
