# Phase 1 — Pre-implementation · Requests to backend

Answer in `docs/response/backend/phase1/phase1response.md`, same request ID.
Format: CLAUDE.md §3.3. States: `REQUESTED → DONE → VERIFIED`.
**"Done" is a claim. "Verified" is a fact.** The AI team runs every check — never the deliverer.

All five items below come from the **same database, at the same migration head.** Fake or schema-only
— no real employee data leaves the Laravel side.

---

### B1 — Current schema at migration head

Status: REQUESTED

Why:      the 2026-09-21 local copy predates the security layer — zero RLS, no `asst_*` tables, no
          reader roles. It also has zero GRANT lines, so it cannot tell us whether grants exist.
          Every contract and every Gate A finding is read against this export
Blocks:   Phase 1 — Gate A, Persistence v1
Owner:    backend
Due:      not set — project deadline not yet stated

What to deliver:
    A schema-only export (no data) of the database at the migration head recorded in B3.
    pgAdmin → Backup → Data options → Do not save:
        Privileges   NOT ticked     (so GRANT statements are included)
        Comments     NOT ticked     (so COMMENT ON statements are included)
    Equivalent with pg_dump:
        pg_dump --schema-only --no-owner -f schema_at_head.sql <database>
        (do NOT pass --no-privileges or --no-comments)

Done by:  <name> — <date>
How to verify:
    grep -c '^GRANT '                          schema_at_head.sql
    grep -c '^COMMENT ON '                     schema_at_head.sql
    grep -c 'ENABLE ROW LEVEL SECURITY'        schema_at_head.sql
    grep -c '^CREATE POLICY '                  schema_at_head.sql
    grep -cE '^CREATE TABLE public\.asst_'     schema_at_head.sql
    grep -c '^INSERT INTO\|^COPY '             schema_at_head.sql
Expected:
    GRANT              > 0
    COMMENT ON         >= 61       (the old copy already had 61 column comments)
    ENABLE RLS         > 0
    CREATE POLICY      > 0
    asst_* tables      5
    INSERT / COPY      0           (schema only — no data)
    Any zero where "> 0" is expected → wrong export options, or not the head. Do not proceed.

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match

---

### B2 — The five Gate A query results

Status: REQUESTED

Why:      decides findings 13, 14 and 15 — whether `employee_documents`, `asst_resultsets` and
          `asst_access_log` are granted to the reader roles, and whether managers can read their
          team's AI chats (the privacy defect). A corrected finding is the gate working
Blocks:   Phase 1 — Gate A; Phase 2 — the database planes
Owner:    backend
Due:      not set — project deadline not yet stated

What to deliver:
    Run the five queries in CLAUDE.md §6 (Phase 1 · Gate A), unchanged, in pgAdmin or psql,
    against the database at the migration head in B3. Paste every output verbatim — including
    column headers and "(0 rows)" where a query returns nothing.

    1  pg_policies on asst_*                         → finding 15
    2  table_privileges for assistant% roles         → findings 13, 14
    3  assistant% role attributes and memberships
    4  app.* functions: prosecdef, proconfig
    5  relrowsecurity / relforcerowsecurity

Done by:  <name> — <date>
How to verify:
    Each of the five pastes is present, labelled 1–5, and states the database name and the
    migration head it was run at. AI reads them and marks findings 13, 14, 15 CONFIRMED or
    CORRECTED with the relevant rows quoted.
Expected:
    5 labelled outputs · each names the database and a migration head equal to B3 ·
    findings 13, 14, 15 each marked CONFIRMED or CORRECTED with evidence

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match

---

### B3 — The migration head

Status: REQUESTED

Why:      "current" has to mean one exact migration. B1 and B2 are only comparable if they were
          taken at the same head, and STATUS.md records it (CLAUDE.md §5.2)
Blocks:   Phase 1 — B1, B2, Gate A
Owner:    backend
Due:      not set — project deadline not yet stated

What to deliver:
    php artisan migrate:status      → the last row
    The same database's migrations table, as a cross-check:
        SELECT migration, batch FROM migrations ORDER BY id DESC LIMIT 1;

Done by:  <name> — <date>
How to verify:
    Compare the last row of `migrate:status` with the SQL result.
Expected:
    The same migration name in both · status "Ran" · the same head named in B1 and B2

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match

---

### B4 — Agreement on decision #3 (read / write plane split)

Status: REQUESTED

Why:      the AI's database access is built on it. Recommended: yes — `assistant_app`
          (LOGIN, NOINHERIT) switches to `assistant_reader` / `assistant_reader_comp` for reads,
          and to `assistant_audit_writer` (INSERT-only on `asst_*` and `asst_releases`, no HR read)
          for writes. See CLAUDE.md §7.5 and DECISIONS.md #3
Blocks:   Phase 2 — the database planes
Owner:    backend
Due:      not set — project deadline not yet stated

Done by:  <name> — <date>
How to verify:
    Open docs/shared/DECISIONS.md, entry #3.
Expected:
    State: DECIDED · Agreed by: <backend name> · Date: <YYYY-MM-DD>

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match

---

### B5 — Agreement on decision #8 (EdDSA key pair for the ScopeToken)

Status: REQUESTED

Why:      ScopeToken v1 cannot be frozen without its signing algorithm. Recommended: EdDSA key
          pair — Laravel holds the private key, Python only the public key, so a breach of the AI
          service cannot mint HR-admin tokens. See CLAUDE.md §4.1 and DECISIONS.md #8
Blocks:   Phase 1 — ScopeToken v1 freeze and the shared token fixture; Phase 2 — token checking
Owner:    backend
Due:      not set — project deadline not yet stated

Done by:  <name> — <date>
How to verify:
    Open docs/shared/DECISIONS.md, entry #8.
Expected:
    State: DECIDED · Agreed by: <backend name> · Date: <YYYY-MM-DD>

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match
