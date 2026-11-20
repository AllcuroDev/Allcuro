# Verification API: how to use it

Two endpoints check medical professionals against public Indian government registers:

| What | Endpoint | Source |
| --- | --- | --- |
| Doctor | `GET /doctor` | NMC Indian Medical Register (Advance Search) |
| Nurse | `GET /nuid/<NUID>` | Indian Nursing Council NRTS (Check NUID Status) |

**Base URL**

```
https://pxjyfgoirspcpguzeqet.supabase.co/functions/v1
```

## Authentication

Every request needs the Allcuro project's **anon key** (Supabase dashboard → Project Settings → API):

```
Authorization: Bearer <ANON_KEY>
```

A request without it gets `401`.

**Browser calls:** calls from a web page only work after the page's origin is allowed:

```bash
supabase secrets set ALLOWED_ORIGINS=https://your-app.example --project-ref pxjyfgoirspcpguzeqet
```

Server-to-server calls need no extra setup.

---

## Doctor verification

```
GET /doctor?name=<name>&regNo=<registration no>&year=<year>&state=<council code>
```

| Parameter | Required | Description |
| --- | --- | --- |
| `name` | Yes | Doctor's name, in any word order. "Dr." and other titles are ignored. |
| `regNo` | Yes | Registration number. Must match exactly. |
| `year` | No | Year of registration, e.g. `2024`. Values come from `/doctor/years`. |
| `state` | No | State Medical Council **code**, e.g. `UP`, `DEL`, `MAH`. Values come from `/doctor/states`. |

A doctor is **verified** when all three hold:

- The registration number matches exactly. `12345` does not match `112345`.
- Every word of `name` appears in the register's name, in any order. `Yukti Sharma` matches `SHARMA, YUKTI`, and a single letter counts as an initial.
- NMC does not mark the record as removed.

### Example

```bash
curl -H "Authorization: Bearer $ANON_KEY" \
  "https://pxjyfgoirspcpguzeqet.supabase.co/functions/v1/doctor?name=Yukti%20Sharma&regNo=112345&year=2024&state=UP"
```

### Response: verified (HTTP 200)

```json
{
  "verified": true,
  "reason": "found",
  "message": "Doctor found in the Indian Medical Register",
  "query": { "name": "Yukti Sharma", "regNo": "112345", "year": "2024", "state": "UP" },
  "doctor": {
    "id": 14239128,
    "name": "SHARMA, YUKTI",
    "fatherOrHusbandName": "SRI KAPIL KUMAR SHARMA",
    "dateOfBirth": "21-08-1999 00:00",
    "registrationNumber": "112345",
    "registrationDate": "19-04-2024",
    "yearOfInfo": 2024,
    "uprnNumber": null,
    "stateMedicalCouncil": "Uttar Pradesh Medical Council",
    "stateCode": "UP",
    "qualification": "M.B.B.S.",
    "qualificationYear": "2023",
    "university": "U.RAMA UNIVERSITY, KANPUR (EARLIER- DR. B.R. AMBEDKAR UNIVERSITY, AGRA)",
    "additionalQualifications": [],
    "permanentAddress": "186 PATTI HAZARI SINGH VIJAY HOSPITAL SIYANA, BULANDSHAHR-203412, UTTAR PRADESH",
    "removed": false,
    "raw": { "...": "the original NMC record" }
  },
  "cached": false
}
```

- `additionalQualifications` is a list of `{ qualification, year, university }`.
- If more than one record matches (for example, the same doctor registered with two councils), the extra records are in `otherMatches`, which has the same shape as `doctor`.
- `cached: true` means the result was served from the API's cache. Results are cached for up to 1 hour.

### Response: not verified (HTTP 404)

```json
{
  "verified": false,
  "reason": "name_mismatch",
  "message": "A doctor with this registration number exists, but the name does not match",
  "query": { "name": "Rahul Sharma", "regNo": "112345", "year": null, "state": null }
}
```

| `reason` | Meaning |
| --- | --- |
| `not_found` | No record with this registration number. If `year` or `state` was given, none within those filters. |
| `name_mismatch` | The registration number exists, but under a different name. |
| `removed` | The record matches, but NMC marks it as removed. The record is still returned in `doctor`. |

### Dropdown data for the form

```
GET /doctor/states   →  { "states": [ { "code": "UP", "name": "Uttar Pradesh Medical Council" }, ... ] }
GET /doctor/years    →  { "years": [ 1906, 1908, ..., 2026 ] }
```

Show `name` to the user and send `code` as the `state` parameter.

---

## Nurse verification

```
GET /nuid/<NUID>        or        GET /nuid?nuid=<NUID>
```

The NUID must be 3–12 letters or digits.

```bash
curl -H "Authorization: Bearer $ANON_KEY" \
  "https://pxjyfgoirspcpguzeqet.supabase.co/functions/v1/nuid/ABC123456"
```

**Found (HTTP 200)**

```json
{
  "nuid": "ABC123456",
  "found": true,
  "status": "Active",
  "name": "...",
  "council": "...",
  "registeredAs": "...",
  "registrationNumber": "...",
  "designation": "...",
  "currentEmployment": "...",
  "country": "...",
  "institute": "...",
  "instituteAddress": "...",
  "sector": "...",
  "verifyUrl": "https://nrts.indiannursingcouncil.gov.in/verifySign.jsp?refno=...",
  "raw": { "...": "the original NRTS record" },
  "cached": false
}
```

`status` is `"Active"` or `"Revoked"`. Treat a nurse as verified only when `found` is `true` and `status` is `"Active"`.

**Not found (HTTP 404)**

```json
{ "nuid": "ABC123456", "found": false, "message": "No details found" }
```

---

## Errors (both endpoints)

| HTTP | Body | Meaning |
| --- | --- | --- |
| `400` | `{ "error": "name is required; regNo is required" }` | Missing or invalid input |
| `401` | | Missing or wrong `Authorization` header |
| `404` | | Not verified (see above), or an unknown path |
| `502` | `{ "error": "NMC portal unavailable", "detail": "..." }` | The government site is down or changed. Retry later. |
| `500` | `{ "error": "Internal error", "detail": "..." }` | Unexpected error in the API |

---

## JavaScript example

```js
const BASE = 'https://pxjyfgoirspcpguzeqet.supabase.co/functions/v1';
const ANON_KEY = '<your anon key>';

async function verifyDoctor({ name, regNo, year, state }) {
  const params = new URLSearchParams({ name, regNo });
  if (year) params.set('year', year);
  if (state) params.set('state', state);

  const res = await fetch(`${BASE}/doctor?${params}`, {
    headers: { Authorization: `Bearer ${ANON_KEY}` },
  });
  const body = await res.json();

  if (res.status === 200) return { verified: true, doctor: body.doctor };
  if (res.status === 404) return { verified: false, reason: body.reason, message: body.message };
  throw new Error(body.error || `Request failed with HTTP ${res.status}`);
}

// Fill the State Medical Council dropdown
async function loadStates(selectEl) {
  const res = await fetch(`${BASE}/doctor/states`, { headers: { Authorization: `Bearer ${ANON_KEY}` } });
  const { states } = await res.json();
  selectEl.innerHTML =
    '<option value="">Select State Medical Council</option>' +
    states.map((s) => `<option value="${s.code}">${s.name}</option>`).join('');
}
```

---

## Things to know

- **Not an official API.** It reads the public NMC and INC websites. If either site changes, this API can return `502` until it is updated.
- **Be gentle.** Requests to each government site go out one at a time, and results are cached for an hour. Avoid bulk checks or tight loops.
- **Don't block on outages.** A `502` means the government site could not be reached. It does not mean the doctor or nurse failed verification.
