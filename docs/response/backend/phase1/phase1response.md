# Phase 1 — Pre-implementation · Backend responses

Answers to `docs/needs/backend/phase1/phase1needs.md`. One section per request, same ID.

- **Backend** fills in *Done by* and *Evidence*, and sets the request to `DONE` in the needs file
- **AI** runs the check, fills in *Verified by* and *Result*, and sets it to `VERIFIED` only on a match
- Paste output verbatim. "Done" without evidence does not count

---

### B1 — Current schema at migration head

Done by:        —
Evidence:       —   (path of the schema-only export, and the migration head it was taken at)

Verified by:    —
Result:         —   (grep counts pasted — matched | did not match)

---

### B2 — The five Gate A query results

Done by:        —
Database:       —
Migration head: —
Evidence:
    1  pg_policies on asst_*                      —
    2  table_privileges for assistant% roles      —
    3  assistant% role attributes and memberships —
    4  app.* functions                            —
    5  relrowsecurity / relforcerowsecurity       —

Verified by:    —
Result:         —   (findings 13, 14, 15 marked in docs/response/ai/phase1/phase1response.md)

---

### B3 — The migration head

Done by:        —
Evidence:
    migrate:status last row      —
    migrations table last row    —

Verified by:    —
Result:         —

---

### B4 — Agreement on decision #3 (read / write plane split)

Done by:        —
Evidence:       —   (DECISIONS.md #3 updated with name and date)

Verified by:    —
Result:         —

---

### B5 — Agreement on decision #8 (EdDSA key pair)

Done by:        —
Evidence:       —   (DECISIONS.md #8 updated with name and date)

Verified by:    —
Result:         —
