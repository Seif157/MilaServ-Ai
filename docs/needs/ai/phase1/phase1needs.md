# Phase 1 — Pre-implementation · AI

What the AI team does in this phase. Source: CLAUDE.md §6 (Phase 1), §1.1, §5.2, §12.3.

The only step where being wrong costs nothing. **No application code, no database connection.**

## 1 · Gate A — check the real database

Depends on: backend B1, B2, B3.

- Receive the five Gate A results, run by backend against the database **at the current migration
  head** — never against the 2026-09-21 local copy (it predates the security layer, CLAUDE.md §5.2)
- Mark each migration-driving finding `CONFIRMED` or `CORRECTED`, with the output pasted as evidence:

  ```
  Finding 13   employee_documents granted to neither reader role
  Finding 14   asst_resultsets / asst_access_log granted to neither reader role
  Finding 15   asst_conversations scoped by can_see_employee() — managers can read team chats
  ```

  A corrected finding is the gate working, not a problem
- Any difference between the live catalogue and the plan on RLS, grants, roles, policies or schema →
  the live catalogue wins, the item goes to `BLOCKED.md`, and the plan is corrected before any code
- If finding 15 is confirmed → raise backend deliverable #3 (owner-only conversation policy,
  CLAUDE.md §12.1) as a request for Phase 6
- Record the migration head in `STATUS.md`

## 2 · Decisions log

- `DECISIONS.md` started from CLAUDE.md §4 — done with this commit
- Get **#3** (read/write plane split) and **#8** (token signing) agreed with backend — the only two
  needed before Phase 2. Record name and date
- Every other decision stays `PENDING` until it is needed

## 3 · Gate C — freeze the contracts

Only two cross between roles:

| Contract | File | Created by | Consumed by |
|---|---|---|---|
| ScopeToken v1 | `docs/shared/contracts/scope_token_v1.md` | Laravel mints | Python verifies |
| Persistence v1 | `docs/shared/contracts/persistence_v1.md` | backend creates tables + writer role | AI writes into them |

- ScopeToken v1 follows CLAUDE.md §7.2 — 90 s TTL, `as_of` in UTC, **no `conversation_access`
  claim**. Signing algorithm waits on decision #8
- Persistence v1 is written against the `asst_*` tables **as they exist at migration head** (B1),
  not against `HR_DATABASE_SCHEMA.md`
- AI-internal contracts (ScopeContext, Resultset, ColumnSensitivity, EvidenceRef, Claim,
  ReleaseManifest, refusal contract) are versioned but do not block backend. **QueryPlan is not
  frozen** — it isn't being built
- "Frozen" means no silent change. v1 → v2 is fine; changing v1 without saying so is not

## 4 · The shared token fixture

- `docs/shared/contracts/fixtures/scope_token_v1.jwt` — one signed ScopeToken v1
- Laravel commits a copy; its test checks the copy's hash matches the canonical file
- Both test suites validate the same signed token (CLAUDE.md §12.3)
- Depends on decision #8 and a dev key pair

## 5 · Business owner

- Get the business owner's **name** into `STATUS.md` and agree **how they update**
  `docs/response/business/phase1/phase1response.md` (web editor, or via Seif) — before Phase 1 closes (CLAUDE.md §1.1)

## Not in this phase

Application code · `pyproject.toml` · tests · other phase folders · any SQL migration.
