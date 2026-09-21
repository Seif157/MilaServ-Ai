# CLAUDE.md — HR Assistant (AI Service)

> **Read this at the start of every session.** It is the working agreement for this repository.
> **Project** A plain-language HR assistant (Egyptian Arabic, MSA, English) for ElManara ERP.
> Read-only. Answers from the HR database and, later, the لائحة. Results ready to download.
> **Scope now** HR module only. Accounting, CRM and Sales come later.
> **Architecture** `docs/plan/HR_ASSISTANT_AI_SERVICE_PLAN.md` — v3.2 or later.

## Sources of truth — in this order

```
1  the live PostgreSQL catalogue, at the current migration head
2  docs/plan/HR_ASSISTANT_AI_SERVICE_PLAN.md
3  this file
4  docs/shared/QUESTIONS.md — answers given by the backend developer
```

- This file conflicts with the plan → **the plan wins.** Read the plan section before changing code.
- **Exception:** a section here marked `SUPERSEDES PLAN` wins. That marker means a defect was found
  after the plan was written. Implement it and report that the plan needs updating. **No section
  currently carries this marker.**
- Either conflicts with the live catalogue on RLS, grants, roles, policies or schema → **the live
  catalogue wins**, the task is `BLOCKED`, and the plan is corrected before any code is written.
- `HR_DATABASE_SCHEMA.md` is **reconstructed from migration source**, not dumped from a database.
  It has already produced one wrong diagnosis in this project. Never treat it as proof.

---

# 0. Status

```
Current phase     Phase 1 — Pre-implementation
State             NOT STARTED
Waiting on        the current schema at migration head (see §5)
Deadline          fixed, but not yet stated — decides what gets cut in phases 9 and 10
Business owner    a person at ASBC — name not yet recorded
Plan maturity     10/10
System readiness  0/10 — no code exists yet
```

Update `docs/shared/STATUS.md`, not this block, as work progresses.

---

# 1. How we work

## 1.1 Roles

| Role | Who | Does |
|---|---|---|
| **AI — drives the project** | Seif Eleslam + Mohamed Metwaly | Builds the FastAPI service, intents, prompts, evals. Writes every request. Verifies every delivery |
| **Backend — support** | The Laravel developer | Answers questions about the schema. Delivers requested database items. Reviews every intent's SQL |
| **Business — support** | A named person at ASBC | Answers decisions. Chases provider approval, retention, the لائحة, HR's eval questions |

**There is one track: AI.** Backend and business respond to requests. They do not run their own
phases.

**The business person needs two things:** a **name** in `STATUS.md` — business items don't block
anyone's code on day one, so without a named owner they drift — and **a way to update without Git
Bash**: either the GitHub/GitLab web editor on `business.md`, or they send updates to Seif, who
commits them. Agree which before Phase 1 closes.

**"Support" includes real work, not only answers.** This repository cannot create database roles,
policies or tables — so some requests can only be delivered on the Laravel side. See §12. If those
are treated as optional, the project stops at Phase 2.

## 1.2 One repository

- **This repository is the project's home.** Plan, needs, contracts, decisions, questions — all here
- **The Laravel ERP code stays in its own repository.** It is shared with Project Management, Sales
  and Finance
- The backend developer works in the Laravel repo and reads this one alongside it:
  ```bash
  claude --add-dir ../hr-assistant
  ```
- If the Laravel repo already has a `CLAUDE.md`, the backend developer **adds a section** for this
  project. Never replace it — other ERP teams depend on it
- **There is only one project `CLAUDE.md` — this one.** The backend role does not need its own

## 1.3 Environment

- Claude Code runs in **Git Bash on Windows**
- **Fake data only.** Claude Code never connects to a database holding real employee data. Query
  results return to the model as tool output — real salaries would leave the machine
- **Never connect as `postgres` or any superuser.** Superusers bypass RLS entirely, so every scope
  test passes whether the policy works or not. A green suite over a broken security model

---

# 2. Repository layout

```
hr-assistant/
├── CLAUDE.md                          ← this file — must stay at the root
├── .gitattributes                     ← * text=auto eol=lf   (see §13)
├── pyproject.toml
├── docs/
│   ├── plan/
│   │   └── HR_ASSISTANT_AI_SERVICE_PLAN.md
│   ├── shared/
│   │   ├── STATUS.md                  ← one screen: current phase, requests, red/green
│   │   ├── DECISIONS.md               ← every decision: what, who, when
│   │   ├── QUESTIONS.md               ← questions to backend and business, with answers
│   │   ├── BLOCKED.md                 ← open blockers, each with an owner
│   │   └── contracts/
│   │       ├── scope_token_v1.md
│   │       ├── persistence_v1.md
│   │       └── fixtures/scope_token_v1.jwt   ← shared test fixture (see §4.3)
│   └── needs/
│       ├── phase-01-pre-implementation/
│       │   ├── ai.md                  ← what the AI team does in this phase
│       │   ├── backend.md             ← requests TO backend
│       │   ├── business.md            ← requests TO business
│       │   └── exit.md                ← tests that prove the phase is finished
│       ├── phase-02-security/
│       ├── phase-03-platform/
│       ├── phase-04-first-answer/
│       ├── phase-05-core-catalogue/
│       ├── phase-06-conversation/
│       ├── phase-07-scale/
│       ├── phase-08-go-live/
│       ├── phase-09-policy/
│       └── phase-10-flexible/
├── app/
│   ├── main.py
│   ├── api/                  routes · answer envelope · error mapping
│   ├── config/               settings · release · flags · sensitivity registry
│   ├── security/
│   │   ├── token.py          signature · TTL · jti replay · claims
│   │   ├── scope.py          frozen ScopeContext
│   │   ├── planes.py         scoped_read() · assistant_write()
│   │   └── egress.py         AI data egress gate
│   ├── model/
│   │   ├── gateway.py        the ONLY way to reach any AI provider
│   │   ├── fake.py           FakeModelGateway — used first, can lie on purpose
│   │   └── providers/
│   ├── catalog/
│   │   ├── intents/*.yaml    hr.* namespaced
│   │   ├── loader.py         parse · validate · hash · derive sensitivity
│   │   └── validator.py
│   ├── entities/             employee resolution
│   ├── conversation/         Phase 6 only
│   ├── agent/                router · bounded controller
│   ├── tools/                hr_query · schema_help   (policy_search in Phase 9)
│   ├── compose/              narrator · grounding · refusal
│   ├── persistence/          asst_* repositories — write plane only
│   └── observability/        trace · metrics · release identity
├── prompts/                  versioned and hashed
├── evals/
│   ├── datasets/regression/  grows freely, versioned, never edited in place
│   ├── datasets/acceptance/  locked holdout — not iterated against
│   ├── contract/             deterministic tests, no LLM
│   ├── adversarial/
│   └── runner.py
└── tests/
```

**This repository writes no SQL migrations.** Ever. When blocked on a database capability, write a
request (§3) and report `BACKEND REQUIRED`. Never compensate for a missing database control with
application-side filtering — that moves the boundary to the wrong layer and hides the gap.

**Phase folders are phase-first on purpose.** Before a phase the question is *"can we start?"* —
one folder answers it. *"What does the backend owe right now?"* is answered by `STATUS.md`.

---

# 3. The workflow

## 3.1 Needs — entry and exit for every phase

Each phase folder has four files:

| File | Written by | Contains |
|---|---|---|
| `ai.md` | AI | What the AI team builds in this phase |
| `backend.md` | AI → answered by backend | Requests the phase depends on |
| `business.md` | AI → answered by business | Decisions the phase depends on |
| `exit.md` | AI | The tests that prove the phase is finished |

**A phase starts only when every request it depends on is `VERIFIED`.**
**A phase ends only when every test in `exit.md` passes.**
The exit of one phase becomes part of the needs of the next.

## 3.2 Request states

```
REQUESTED   →   DONE              →   VERIFIED
AI writes       Backend/business      AI runs the check,
the need        claims it, and        gets the expected
                gives the check       output → it counts
```

**"Done" is a claim. "Verified" is a fact.** The person who *needs* the item runs the check — never
the person who delivered it. Only `VERIFIED` counts toward starting a phase.

## 3.3 Request format

```markdown
### assistant_app login role

Status: REQUESTED | DONE | VERIFIED

Why:      the AI's database connection is built on it
Blocks:   Phase 2 — the database planes
Owner:    backend
Due:      <date>

Done by:  <name> — <date>
How to verify:
    SELECT rolname, rolinherit, rolcanlogin, rolbypassrls
    FROM pg_roles WHERE rolname = 'assistant_app';
Expected:
    assistant_app | f | t | f

Verified by: <name> — <date>
Actual output: <pasted> — matched
```

The **Expected** line is the point. It makes verification mechanical — run it, compare, done. No
"looks fine to me." It also means a request works as a prompt: the backend developer's Claude Code
reads the item, knows what to build, and knows exactly what result proves it right.

Every item needs **proof**. "Done" without evidence does not count.

## 3.4 Questions — `docs/shared/QUESTIONS.md`

Most backend support will be answers, not code. *"Is this column the current salary or the approved
one?"* *"Which role sees disciplinary data?"*

- **Check `QUESTIONS.md` before asking.** The answer may already exist
- Each answer is written **once**, dated, with who answered
- An answer from the person who built the schema is a **documented fact** — use it, cite it
- If an answer contradicts the plan, raise it — do not silently pick one

```markdown
### Q-014 — Is salary.gross_salary stored or computed?
Asked:    Seif — 2026-09-24
Answer:   Stored. Recomputed by trigger on allowance change.   — <backend>, 2026-09-24
Affects:  hr.salary_current — can select it directly
```

## 3.5 Decisions — `docs/shared/DECISIONS.md`

Replaces the old "Gate B". Decisions are made **when they are needed**, not all up front — but every
one is **written down**: what, who agreed, when.

Why it matters: code makes every decision whether or not anyone chooses. If nobody decides, whatever
the code happens to do *becomes* the decision. The conversation-privacy defect is the proof — nobody
chose to let managers read their team's AI chats; it fell out of reusing an existing rule.

**Never treat a `PENDING` decision as decided.** If a task needs one → `BLOCKED`.

## 3.6 Blockers — `docs/shared/BLOCKED.md` · Status — `docs/shared/STATUS.md`

`BLOCKED.md` holds every open blocker, each with an owner. `STATUS.md` fits on **one screen** — if it
needs scrolling, nobody reads it.

---

# 4. Decisions — current state

| # | Decision | State | Needed before |
|---|---|---|---|
| **1** | Chat privacy | ✅ **DECIDED — owner-only.** Managers never read their team's AI chats | — |
| **2** | Investigation access to others' chats | PENDING — recommended: **never** in v1 | Nothing, if "never" |
| **3** | Read / write plane split | PENDING — recommended: **yes**. Agree with backend | **Phase 2** |
| **4** | What data may reach the AI provider | PENDING — recommended: **code-filled values** for compensation and disciplinary | Egress gate · salary intents |
| **5** | AI provider and data region | PENDING — **client's decision** | Phase 8 |
| **6** | Engineering retention | PENDING — proposed: query results **7 days**, raw prompts **not stored** | Phase 8 |
| **7** | Legal retention | PENDING — **legal**: conversations, access logs, security events, feedback | Phase 8 |
| **8** | Token signing | PENDING — recommended: **EdDSA key pair** | Phase 1 contract freeze |
| **9** | Minimum group size for sensitive averages | **DECISION REQUIRED** — until then, refuse | Any sensitive aggregate |
| **10** | Document metadata access (plan §5.3) | PENDING — **backend owner's call** | `hr.documents_expiring` |
| **D1** | Tenancy — database per client, or shared? | **OPEN — ask the client** | Everything, if "shared" |
| — | Python version and driver | **DEFAULT: Python 3.12 + psycopg 3 — confirm** | Phase 2 |

## 4.1 What the recommendations mean

**#4 — code-filled values.** For compensation and disciplinary answers the model writes the *shape*:
*"Your basic salary is `{salary}`"*. Code inserts the real figure after the model is done. **The AI
provider never sees the number**, and grounding becomes trivial because the value comes straight from
the database.

**#8 — key pair, not shared secret.** Laravel holds the private key, Python holds only the public
key. With a shared secret the AI service could **mint any token, including HR-admin scope** — a
breach of this service would become a breach of every employee's data. With a key pair, Python can
only verify.

**D1 — tenancy.** Zero `company_id` / `tenant_id` columns exist, yet `settings_billing_*` tables do.
If the answer is "shared tenant", the entire RLS model is invalid. Still unanswered after six rounds.

---

# 5. The database — what exists and what doesn't

## 5.1 What we know from the local copy (dumped 2026-09-21)

PostgreSQL 15.17 · owner `erp_user` · 148 tables · 5 views · 2 functions · 273 indexes ·
206 foreign keys · 219 CHECK constraints · 61 column comments · `pg_trgm` · schema `app`.

**Present and matching the plan ✅**

- `users.employee_id` — the identity link. **Resolve principal → employee through this**
- Foreign keys: 52 of 54 `employee_id` columns. The two without — `employee_history`,
  `employee_purge_logs` — are the intended exceptions
- `app.ar_normalize()` · `app.normalize_digits()`
- `idx_employees_name_ar_trgm` · `idx_employees_name_en_trgm` · `idx_employees_number_normalised`
- Column comments on `salary` (12), `attendance_summaries` (10), `employees` (8),
  `leave_balances` (5), `pay_periods` (5), and others
- All HR domain modules: Article 69, penalties, grievances, merit raises, raw punches, pay periods

**Missing from that copy ❌**

- **Any RLS** — zero policies, zero `ENABLE`, zero `FORCE`
- `app.can_see_employee()` and the scope helpers
- `assistant_reader` · `assistant_reader_comp`
- **All five `asst_*` tables**
- `user_role_departments` · `approval_routing_settings`

**Unknown:** zero GRANT lines in the dump. Either none exist, or the Privileges box was ticked during
export. Gate A queries 2 and 3 decide it.

## 5.2 What this means

**That copy predates the security layer. Do not build or test against it.** Use the database at the
**current migration head** — the one with RLS and the `asst_*` tables. Record the head
(`php artisan migrate:status`, last row) in `STATUS.md`.

A view `v_document_expiry_alerts` exists over `employee_documents`. **It includes `document_number`**
— a field the plan keeps away from the assistant. Do not use it for assistant intents.

## 5.3 Connection rules

```
connect as          assistant_app  (LOGIN, NOINHERIT)
never as            postgres, erp_user, any superuser, the table owner
data                fake seeded data only
until the role      exists → no database connection at all
```

---

# 6. The ten phases

| # | Phase | What it does | Plan name |
|---|---|---|---|
| **1** | Pre-implementation | Check the real database, write down decisions, fix the shared formats | Pre-Implementation Gate |
| **2** | Security | Build the walls — token checking, safe DB access, sensitivity, off switch | 0A |
| **3** | Platform | Build the control room — know what's running, refuse to start if wrong, record everything | 0B |
| **4** | First answer | One question through every layer — correct, safe, recorded | 1 |
| **5** | Core catalogue | Everyday HR questions — leave, attendance, contracts, salary | 2 |
| **6** | Conversation | Follow-ups like *"وأحمد؟"*, re-checking access for every new person | 3 |
| **7** | Scale | 40–60 intents, full eval set, load testing, schema-drift guards | 4 |
| **8** | Go live | HR pilot → one branch → all staff, with rollback and incident drills | 5 |
| **9** | Policy questions | Answers about the لائحة with exact article citations | 6 — *cuttable* |
| **10** | Flexible questions | Questions no intent covers, through a controlled query language | 7 — *cuttable, cut first* |

**Minimum shippable: phases 1–8.**

## Phase 1 — Pre-implementation

Three parts. The only step where being wrong costs nothing.

**Gate A — check the real database.** Run against the **current** database, in pgAdmin or `psql`:

```sql
-- 1 · conversation policies — decides the privacy defect
SELECT tablename, policyname, cmd, roles, qual
FROM pg_policies WHERE schemaname='public' AND tablename LIKE 'asst\_%' ORDER BY tablename;

-- 2 · grants on the contested tables
SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema='public'
  AND table_name IN ('employee_documents','asst_resultsets','asst_access_log',
                     'asst_conversations','asst_turns','asst_feedback')
  AND grantee LIKE 'assistant%'
ORDER BY table_name, grantee;

-- 3 · role attributes and memberships
SELECT r.rolname, r.rolinherit, r.rolbypassrls, r.rolcanlogin,
       ARRAY(SELECT b.rolname FROM pg_auth_members m
             JOIN pg_roles b ON b.oid = m.roleid WHERE m.member = r.oid) AS member_of
FROM pg_roles r WHERE r.rolname LIKE 'assistant%';

-- 4 · SECURITY DEFINER functions and pinned search_path
SELECT p.proname, p.prosecdef, p.proconfig
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'app' ORDER BY p.proname;

-- 5 · RLS enabled AND forced
SELECT relname, relrowsecurity, relforcerowsecurity
FROM pg_class
WHERE relnamespace = 'public'::regnamespace
  AND relname IN ('asst_conversations','asst_turns','asst_resultsets',
                  'asst_access_log','asst_feedback','employee_documents');
```

Each of the three migration-driving findings is marked `CONFIRMED` or `CORRECTED`, with output
pasted as evidence:

```
Finding 13   employee_documents granted to neither reader role
Finding 14   asst_resultsets / asst_access_log granted to neither reader role
Finding 15   asst_conversations scoped by can_see_employee() — managers can read team chats
```

A corrected finding is the gate working, not a problem.

**Decisions log.** Start `DECISIONS.md` with §4. Only #3 and #8 are needed before Phase 2.

**Gate C — freeze the contracts.** Only two cross between roles:
- **ScopeToken v1** — Laravel creates, Python verifies
- **Persistence v1** — backend creates the tables and writer role, AI writes into them

The others (ScopeContext, Resultset, ColumnSensitivity, EvidenceRef, Claim, ReleaseManifest, refusal
contract) are AI-internal: versioned, but they don't block backend. **QueryPlan is not frozen** — it
isn't being built.

**"Frozen" means no silent change.** v1 → v2 is fine. Changing v1 without saying so is not.

**Exit:** findings marked with evidence · `DECISIONS.md` started · both contracts frozen · the shared
token fixture committed in both repositories and **passing in both test suites**.

## Phase 2 — Security

Build the walls before the house. **No AI, no questions, no answers.** At the end, "can it answer
anything yet?" — **no, on purpose.**

Six pieces:
1. **Token checking** → frozen `ScopeContext` *(no database needed — start day one)*
2. **The two planes** — `scoped_read()` and `assistant_write()` *(needs backend roles)*
3. **Sensitivity registry** — fail-closed *(no database needed — start day one)*
4. **Egress gate** *(general parts day one; code-filled values wait for decision #4)*
5. **Kill switch** *(needs the flag location from backend)*
6. **Tests** — more work than the code

**Before starting:** Phase 1 exit · decision #3 · ScopeToken v1 + key pair · repo, driver,
`CLAUDE.md` · a dev key pair and test-token maker · the fake dataset (§12.2).

**Exit:** forged / expired / replayed token rejected · each scope level sees only its own ·
no scope → zero rows · general reader can't see salary · nobody sees `national_id` · **manager cannot
read team chats — on the real database** · read plane cannot write · write plane cannot read HR ·
no DB call outside the planes · unknown column blocked · `salary × 12` still treated as salary ·
no file path reaches the AI · kill switch on → AI never called.

## Phase 3 — Platform

The control room — the plane's black box. Still answers nothing.

Six pieces: release manifest · startup integrity check · `ModelGateway` + `FakeModelGateway` ·
per-turn tracing · rate limits and query timeouts · secrets and locked dependencies.

**Overlaps Phase 2.** The repo, CI and test runner are needed on **day one of Phase 2**. What waits
for Phase 3 is release engineering: manifest, registry, startup checks.

**Before starting:** the `asst_releases` table from backend · where secrets live.

**Exit:** manifest validates · same release ID can't register different contents · changed catalogue →
`/readiness` red, `/liveness` green · schema mismatch → not ready · no provider call outside the
gateway · every request traced with a release ID · trace holds **no** HR data · too many requests →
clean "try again" · slow query killed at the limit · no keys in the repo.

## Phase 4 — First answer

The golden vertical slice. **Two intents, not six** — if a layer's design is wrong you rewrite one
thing, not six.

| Intent | Tests |
|---|---|
| `hr.employee_lookup` | Names, spelling variants, ambiguity, not leaking who exists, scope |
| `hr.leave_balance_current` | A figure computed in SQL, grounding, the "my" case |

Salary is deliberately excluded.

**Fake AI first, then a real one.** `FakeModelGateway` proves the pipeline — and can **lie on
purpose**, which is how you test that grounding blocks an invented number. Then switch to a real model
**with fake data** to judge whether the Arabic sounds natural. Real employee data waits for provider
approval (decision #5).

**Before starting:** phases 2–3 · leave balances in the fake data · HR's first 30–50 questions ·
a provider for development only.

**Exit:** *"كام رصيد أجازاتي؟"* correct, natural, saved with a release ID, traced · bad token
rejected · out-of-scope = same text as not-found · two أحمد محمد → asks · general user asking salary
refused · unknown column blocked · **fake AI invents a number → grounding blocks it** · too many rows →
no invented total · kill switch → AI never called · 30–50 questions passing, per slice.

## Phase 5 — Core catalogue

Safest first, most sensitive last:

| # | Intent | Sensitivity | The trap |
|---|---|---|---|
| 1 | `hr.leave_requests_by_status` | General | Zero is a legitimate answer |
| 2 | `hr.contract_terms_current` | General | Answered from columns, not the PDF |
| 3 | `hr.attendance_summary_month` | General | Calendar month only — pay periods fenced |
| 4 | `hr.salary_current` | **Compensation** | First sensitive data to flow |
| 5 | `hr.salary_as_of` | **Compensation** | History — easiest place to be confidently wrong |
| 6 | `hr.documents_expiring` | General | **Blocked** on decision #10 |

- Salary is **per-person only**. *"Average salary in my department"* → refused (decision #9)
- `hr.salary_current` and `hr.salary_as_of` are **separate intents.** Merging them is the most likely
  wrong compensation answer — history must use `effective_date`/`end_date`, never `is_current`
- *"This month"* works; *"this pay period"* → refused. `pay_period_id` is not authoritative yet

**Before starting:** Phase 4 · **decision #4** (blocks 4 and 5) · fake data with **a salary raise**,
two months of attendance, contracts, leave in several statuses.

**Exit:** each intent correct and **SQL-reviewed by backend** · raise in June: *"salary in March"* =
old, *"current"* = new · `is_current` in a history intent → service refuses to start · **the fake AI
records its inputs — no salary figure ever in them** · no salary in any trace or log · average salary
refused · pay-period question refused · documents shipped or explicitly deferred · 100–150 questions.

## Phase 6 — Conversation

Makes *"وأحمد؟"* work. Four pieces: read this user's recent turns · classify standalone /
continuation / topic shift · rewrite continuations to full questions **before** answering · bounded
agent (≤ 4 steps, ≤ 20 s) · plus `schema_help` for everyday HR words.

**Every newly named person gets a fresh scope check.** *"كام مرتبي؟" → "وبتاع مديري؟"* must refuse.

**Blocked on the owner-only conversation policy being live.** Do not work around it with Redis or a
session store — that creates a second copy of every conversation outside RLS.

**Exit:** follow-ups rewritten correctly · topic shift drops old names · after asking about Ahmed,
*"كام رصيدي؟"* answers about **you** · out-of-scope follow-up refused · user A never reads user B's
chat · chains stop at 4 steps / 20 s · 25 conversation sequences, scored as sequences.

## Phase 7 — Scale

40–60 intents · schema-drift CI · SQL review of every intent · 300+ eval questions · full language
slices · load testing · degradation paths.

## Phase 8 — Go live

HR team (≈10) → one branch → all staff. Incident drill · rollback drill · SLO monitoring · the
feedback loop running: **production failure → eval case → fix → release.**

**Before starting:** decisions #5, #6, #7 · real Laravel tokens · provider approval.

## Phases 9 and 10 — cuttable

**9 · Policy** — only when the لائحة exists in clean digital form. Chunk by **article**, never by
token window. pgvector inside `erp_hr` so scoped documents filter through RLS.

**10 · Flexible** — a typed QueryPlan referencing reviewed **semantic metrics**, never tables and
columns. Generated SQL only if real usage proves it's needed. Cut first.

---

# 7. Security invariants — non-negotiable

## 7.1 The model never authorizes

Scope lives in a frozen dataclass and database session variables. Tools are a fixed registry. Queries
are a reviewed catalogue. The model cannot reach any of them — **by construction, not by
instruction.** "The prompt tells it not to" is never a control.

## 7.2 ScopeToken v1

```json
{
  "principal_employee_id": "uuid",
  "row_scope": "self|reports|department|branch|all",
  "branch_ids": ["uuid"],
  "dept_ids": ["uuid"],
  "db_role": "assistant_reader|assistant_reader_comp",
  "locale_hint": "ar|en",
  "as_of": "ISO-8601, UTC",
  "iat": 1757760000,
  "exp": 1757760090,
  "jti": "uuid"
}
```

- Signed by Laravel · **90-second TTL** · opaque to the browser · `jti` logged for replay detection
- **`as_of` is always UTC.** Cairo local time on one side and UTC on the other makes "today" mean
  yesterday for hours every night — silently wrong answers, no error
- **No `conversation_access` claim.** Deliberately removed. Conversation access is a database
  invariant (§7.5), not a token field. **Do not add it back**
- Verification **fails closed**: bad signature, expired, replayed, unknown role, malformed → 401

## 7.3 ScopeContext is immutable

```python
@dataclass(frozen=True)
class ScopeContext:
    principal_employee_id: UUID
    row_scope: Literal["self","reports","department","branch","all"]
    branch_ids: tuple[UUID, ...]
    dept_ids: tuple[UUID, ...]
    db_role: str
    as_of: datetime
    jti: UUID
```

Built **only** from a verified token. Never widened, recomputed, merged across turns, or defaulted.

## 7.4 RLS is the authorization boundary

**The database decides which rows each person sees.** The same query returns different rows for
different people:

```
SELECT * FROM salary;
  Ahmed (self)          → 1 row
  Ahmed's manager       → his reports' rows
  HR admin (all)        → every row
```

```python
@contextmanager
def scoped_read(ctx: ScopeContext):
    with pool.connection() as conn, conn.transaction(read_only=True):
        conn.execute(f"SET LOCAL ROLE {validate_role(ctx.db_role)}")
        conn.execute("SET LOCAL statement_timeout = '8s'")
        conn.execute("SET LOCAL lock_timeout = '2s'")
        conn.execute("SET LOCAL idle_in_transaction_session_timeout = '10s'")
        for k, v in scope_vars(ctx):
            conn.execute("SELECT set_config(%s, %s, true)", (k, v))
        yield conn
```

- **Read-only at transaction open.** `SET LOCAL default_transaction_read_only` does **not** make an
  already-open transaction read-only. Prove it: a test that expects `ReadOnlySqlTransaction` on a write
- `set_config(..., true)` — transaction-scoped. Session-scoped leaks across the connection pool
- Default `row_scope` is `none` = **zero rows.** Never add a permissive fallback
- **`SELECT *` breaks** under column grants. Enumerate columns; CI rejects `*`
- `validate_role()` allowlists. **Never interpolate a token value into SQL**
- **Column grants** hide fields (`national_id`, salary figures); **RLS** hides rows. Together: which
  people, which fields

## 7.5 The two planes

```
READ PLANE                            WRITE PLANE
assistant_app (LOGIN, NOINHERIT)      assistant_app (LOGIN, NOINHERIT)
  SET LOCAL ROLE assistant_reader       SET LOCAL ROLE assistant_audit_writer
  or assistant_reader_comp              INSERT-only on asst_* and asst_releases
  SELECT on HR tables                   no HR read privileges
```

`NOINHERIT` means a pooled connection holds **no privileges** until `SET LOCAL ROLE`. A bug defaults
to no access, not full access. The reader never mutates. The writer never broadly reads HR.
`asst_access_log` and `asst_releases` are **append-only**, enforced as grants.

**Static test:** no database call exists anywhere outside `scoped_read()` or `assistant_write()`.
That one assertion is the security model.

## 7.6 Conversation history — owner-only

```
HR record visibility  ≠  assistant conversation visibility
```

```sql
USING (employee_id = app.principal_employee_id())
```

**No `OR`. No session variable. No token claim.** Owner-only must be provable from the policy text
alone. A manager with any scope never reads a team member's AI chats.

Cross-user access — for investigations or support — is **unsupported** (decision #2). If ever
approved, it is a separate short-lived `ConversationAccessGrant` naming one subject, with a reason and
an audit row. **Do not build it speculatively.**

## 7.7 Sensitivity fails closed

```python
class Sensitivity(IntEnum):
    GENERAL = 0; IDENTITY = 1; COMPENSATION = 2; DISCIPLINARY = 3
    RESTRICTED_UNKNOWN = 99
```

- **Unknown is never `GENERAL`.** CI: unknown classification → catalogue fails, service won't boot.
  Runtime: unexpected gap → result blocked, refuse, incident metric
- Propagates through expressions: `salary × 12`, `AVG(salary)`, `CASE WHEN penalty…` keep their source
  sensitivity. **Aggregation does not declassify**
- Declared sensitivity must equal derived, or the service refuses to boot

## 7.8 Egress gate — before anything reaches a provider

1. Strip file paths → `attachments`, never text
2. Keep only the fields this intent needs
3. **Row cap 200.** Over it: reviewed aggregate intent, or mark truncated, or refuse.
   **Never auto-aggregate** — a gate-computed aggregate has no definition, no cohort check, no grounding
4. Character cap
5. Sensitivity policy — identity never leaves without explicit allowance; compensation only under
   `assistant_reader_comp`
6. Provider allowlist
7. Redaction — national ID patterns redacted even if a bug selected them

## 7.9 Inference and small groups

RLS can be perfect and an average can still leak one person's salary.

```
Q1  How many in department X earn above 30k?    → 4
Q2  How many of those are managers?             → 2
Q3  How many are male?                          → 1
Q4  Is it Ahmed?                                → salary disclosed
```

Until decision #9 sets a minimum group size: **sensitive aggregates are refused outright.**
Refusal reason `cohort_too_small`, phrased so it doesn't confirm the group size.

## 7.10 Never degrade these

```
ScopeToken validation · RLS · column privileges · conversation privacy
egress gate · sensitivity derivation · grounding of critical HR claims
```

May degrade: policy search · flexible questions · rich narration. **If a security gate can't run,
stop serving.**

---

# 8. Data and what's fenced off

## 8.1 Three tiers

| Tier | What | Behaviour |
|---|---|---|
| **Structured** | The vast majority — pay, leave, attendance, performance, discipline | Answer |
| **Document metadata** | Type, number, issue/expiry dates, mandatory, verified · contract notice period, probation end, renewal | Answer — **no file is opened** |
| **Document content** | `file_path`, `pdf_path`, `cv_path`, `attachment_path`, `medical_certificate_path`, `receipt_path` | **Refuse, then attach the file** |

*"Your contract runs to 30 June 2027 with three months' notice. I can't read the document itself —
here it is."* **File paths never reach the model as text.**

## 8.2 Fenced off in v1

| Question type | Why |
|---|---|
| Pay-period questions | `pay_period_id` is nullable and **not authoritative**; boundary day is `1`; the 22→21 cycle is pending |
| Payslip line detail | P11 unbuilt — `ps_payslip_documents` is a PDF path. *"ليه راتبي قل الشهر ده؟"* is unanswerable — **tell the client before the demo** |
| Document contents | No extracted text exists anywhere |
| Policy questions | Until Phase 9 — the لائحة is not in the database |
| Document expiry | Until decision #10 |

---

# 9. Behaviour rules

## 9.1 Entity resolution

```
1  self-reference ("أنا", "my", "me")  → principal from the token
2  employee_number                     → app.normalize_digits()
3  Arabic name                         → app.ar_normalize() trigram
4  Latin name                          → lower() trigram
5  work email, if the intent allows
```

All inside `scoped_read()` — RLS filters **before** disclosure, never a post-filter in Python.

```
0 matches  → entity_not_found
1          → continue
2+         → return candidates and ASK. Never pick
>10        → ask for a narrower reference
```

**Existence must not leak.** Out-of-scope and not-found return **byte-identical text.** A contract
test asserts it. Never *"أحمد موجود بس مش من صلاحيتك"*.

**The LLM does not transliterate names to match Latin columns.** محمد has half a dozen Latin
spellings; the database holds one. Matching needs both sides normalised — that's the database's job.
The model extracts the name and picks among candidates; the database finds them.

## 9.2 Intents are reviewed capability contracts

Not SQL templates. Every field required:

```yaml
intent · purpose · required_role · required_capabilities · slots
semantic_definition · temporal_semantics · sensitivity · selected_fields
allowed_aggregations · zero_row_behavior · multi_row_behavior · truncation_behavior
grounding_contract · citation_contract · expected_indexes · schema_dependencies
owner · reviewed_by · version · max_rows · sql
```

- `hr.*` namespaced from the first intent
- **Every derived figure computed in SQL**, never by the model
- `temporal_semantics: point_in_time` → must declare and filter on `effective_from`/`effective_to`;
  referencing `is_current` is a **validation error**
- `reviewed_by` is the backend developer. **The eval author and the SQL author must not be the same
  person** — otherwise the eval can't catch a wrong join

## 9.3 Grounding

Severity is **predefined in configuration.** The model never decides which claims are critical.

```
CRITICAL   amount · salary · disciplinary state · leave balance · approval state
           employment status · identity · policy obligation · statutory deadline
           → no verified evidence = NEVER displayed
IMPORTANT  department · manager · job title · attendance summary · document expiry
           → removed, or partial answer with the gap stated
NARRATIVE  framing and hedging
           → allowed, must not contradict the evidence
```

Unclassified claim → **critical.** Deterministic checks first; an LLM judge only for general facts.

## 9.4 Truncation

`truncated = true` → the answer **must** say it's partial. Counts, averages, totals and distributions
are computed **in SQL** by a reviewed intent — never from returned sample rows.

## 9.5 Zero rows

Zero is not one condition. Each intent declares its own:

```
hr.leave_requests_by_status  → legitimate zero, say so plainly
hr.employee_lookup           → entity_not_found, identical in or out of scope
hr.salary_current            → unavailable — never "no salary record exists"
```

## 9.6 Refusals — nine reasons

A refusal is a correct outcome, not a failure.

```
out_of_scope · no_data_source · document_content_unavailable · entity_not_found
ambiguous_entity · period_unsupported · unsupported_question · budget_exhausted
cohort_too_small
```

`out_of_scope` must never confirm existence — phrase it as a scope statement, not a data statement.

---

# 10. Evaluation — from day one

**Four layers**

```
A  Deterministic contract suite   every commit · no LLM · binary
B  Stochastic evals               N=3 CI · N=5 acceptance · N=10 safety slices · report worst case
C  Regression set                 grows freely · versioned · never edited in place
D  Locked acceptance holdout      NOT iterated against — stops overfitting
```

**Slices — reported separately, never one global number**

```
Language      Egyptian colloquial · MSA · English · mixed · Latin-script Arabic ("3ayez a3raf")
              Arabic-Indic digits · Western digits
Scope         self · reports · department · branch · all · none · comp · non-comp
Data          zero · one · many · historical · ambiguous · terminated · null · truncated
Security      injection (direct, indirect, via names/titles/chunks) · SQL injection
              scope probing · existence probing · forged/expired/replayed token
Inference     small-group aggregates · sequential narrowing
Conversation  standalone · continuation · topic shift · scope-widening follow-up
Documents     metadata questions MUST answer · content questions MUST refuse + attach
```

> **Production will be colloquial.** Staff type **عايز أعرف فاضل لي كام يوم**, not
> *أرغب في معرفة رصيد إجازاتي المتبقي*. An eval set in MSA passes and then fails in production.
> Tell HR explicitly.

**Zero tolerance — no error budget:** scope violations · critical ungrounded claims · file-path
leakage · existence leaks. All must be **0**.

---

# 11. Release engineering and observability

```
release_id → exactly one immutable manifest, forever
```

Any change that affects answers → **new `release_id`**: model · parameters · prompts · catalogue ·
glossary · query semantics · retrieval · flags · gateway · grounding rules · build.

- **Never pin a model to a floating alias** like "latest"
- Startup: load manifest → check schema, RLS and privilege fingerprints → catalogue hash → prompt
  hashes → model pin → glossary → security contracts → verify `release_id` → **READY**.
  Any mismatch → **not ready**
- `/liveness` — the process is running. `/readiness` — it's safe to send it questions.
  Conflating them means a failed integrity check gets restarted forever instead of surfacing

**Trace every turn:** turn ID · release ID · model and provider request IDs · route · intent · tier ·
locale · scope **type** · tools and latency · row **counts** · resultset IDs · refusal reason ·
grounding result · retries · tokens · cost · degradation mode.

**Never log:** raw rows · prompts containing HR data · file paths · credentials · salary values ·
disciplinary content · employee names · national IDs. **The trace must not become a way around RLS.**

**Rate limits** at five levels: per person · per company · per endpoint · per provider · a global
ceiling. The assistant shares `erp_hr` with the ERP everyone uses to work — without limits, one
script slows payroll and attendance for the whole company.

**Model gateway:** retry transport failures, timeouts and 5xx. **Never retry because the answer
wasn't liked** — that's sampling until satisfied, and it defeats grounding. Replay protection (`jti`),
request idempotency, model retry and tool retry are four different things.

---

# 12. Backend support — what we need from them

## 12.1 The deliverables — only the Laravel side can do these

| # | Deliverable | Blocks |
|---|---|---|
| 1 | `assistant_app` login role — `LOGIN NOINHERIT` | Every database connection |
| 2 | `assistant_audit_writer` role — INSERT-only on `asst_*` and `asst_releases` | Saving turns and the audit log |
| 3 | Owner-only conversation policy — **if Gate A confirms finding 15** | Phase 6 |
| 4 | ScopeToken minting in Laravel | Real users — test tokens until then |
| 5 | Fake-data seeder (§12.2) | Every security test |
| 6 | Kill-switch flag, readable without a deploy | Phase 2 |
| 7 | **SQL review of every intent** | Every intent shipped |
| 8 | `asst_releases` table, append-only | Phase 3 |
| 9 | `refusal_reason` CHECK += `document_content_unavailable`, `policy_unavailable`, `cohort_too_small` | Phase 4 |
| 10 | Decision on document metadata access (plan §5.3) | `hr.documents_expiring` |
| 11 | The current schema at migration head, plus Gate A results | **Phase 1** |
| 12 | `HR_ROLE_AUTHORITY_MATRIX.md` | Mapping roles to scopes, mid-Phase 2 |

Each one is a request in the relevant phase's `backend.md`, with an **Expected** output.

## 12.2 The fake dataset — shape matters

The security tests are meaningless without the right structure. Minimum:

- 2+ branches, 3+ departments
- a manager with direct reports, **and** an employee outside that team
- a team leader over two departments via `user_role_departments`
- users linked through `users.employee_id`
- salary rows, **including one employee with a raise** (for now-vs-then)
- a penalty · a document with a file path · contracts
- leave balances · leave requests in several statuses · two months of attendance
- Arabic names with spelling variants — أحمد / احمد, فاطمة / فاطمه, يحيى / يحيي

Built with Laravel seeders on the backend side.

## 12.3 The shared token fixture

The canonical file lives in `docs/shared/contracts/fixtures/`. Laravel commits a copy, and **its test
checks the copy's hash matches.** Both test suites validate the same signed token. If either side
changes the format, its own test fails first — the mismatch is caught the day it's introduced, not in
integration week.

Why a test, not observation: the no-existence-leak rule means a contract bug that empties someone's
scope just shows *"I couldn't find that employee."* It looks like correct security. **Our own design
hides contract bugs** — only a test finds them.

---

# 13. Environment — Git Bash on Windows

```bash
# create and activate the venv
python -m venv .venv
source .venv/Scripts/activate       # NOT .venv/bin/activate — that's Linux/macOS

# always run tools through the venv's python
python -m pip install -e ".[dev]"
python -m pytest
```

**`.gitattributes` — must exist from the first commit:**

```
* text=auto eol=lf
```

Windows saves CRLF, CI uses LF. The release manifest hashes every prompt and intent file. Same file,
different line endings, **different hash** — the startup check would fail on one machine and pass on
another, and look like a genuine integrity problem.

**Other habits**
- Use forward slashes in paths inside code and config
- `psql` must be on the Git Bash `PATH` for database checks
- Don't use PowerShell-only commands in scripts

**Stack:** Python **3.12** · **psycopg 3** · FastAPI. *(Default — confirm or change in
`DECISIONS.md`. If the driver changes, §7.4's read-only line changes with it.)*

---

# 14. Working rules

For every task:

1. Read this file
2. Read the relevant plan section and the current phase's `needs/` folder
3. **Check `QUESTIONS.md` before asking the backend anything**
4. Inspect existing code before creating new abstractions
5. Don't guess schema, policies, grants or enum values — ask, or mark `BLOCKED`
6. Implement the smallest complete safe slice
7. **Tests ship with the code, not after**
8. Run lint, type-check and tests before declaring done
9. Update `STATUS.md` if a phase or request changed state
10. Report: files changed · tests added · commands run · results · open dependencies · next safest step

**Do only the task asked.** Don't create files, folders or scaffolding beyond it.

## Prefer

```
explicit · typed · immutable security context · small pure validators
deterministic checks · reviewed SQL · fail-closed · structured output · small vertical slices
```

## Avoid

```
magic · global mutable state · model-controlled security · regex SQL validation
SELECT * · implicit defaults for security fields · swallowing exceptions
silent sensitive→general fallback · silently guessing an employee · hidden retries
provider SDK calls outside ModelGateway · DB calls outside the planes
provider keys in source or committed env files
treating a PENDING decision as decided
treating HR_DATABASE_SCHEMA.md as proof
```

---

# 15. When to STOP instead of coding

```
the task needs an unverified schema, RLS, grant or role assumption
the live catalogue differs from the plan
a sensitivity classification is unknown
a PENDING or DECISION REQUIRED item would have to be guessed
the task needs real employee data, or a superuser connection
a provider privacy assumption is missing for real data
an intent's business meaning is ambiguous
current-vs-historical meaning is unclear
the task would widen database permissions for convenience
the task needs a migration — this repository writes none
```

Report exactly this, and add it to `docs/shared/BLOCKED.md`:

```
BLOCKED

Reason:

Evidence:

Required owner:   Backend | Business | Legal | HR | Client

Request or decision needed:

Safe work that can continue:
```

---

# 16. First milestone

Not "the foundation is ready" until this works end to end:

```
"كام رصيد أجازاتي؟"
→ valid token → frozen ScopeContext → hr.leave_balance_current
→ self resolution → scoped read → RLS → typed Resultset
→ derived sensitivity → egress gate → composition → grounding
→ natural Arabic answer → saved with release_id → traced
```

**And these failures are proven:**

```
bad token                           → rejected
out-of-scope employee               → same text as not-found
ambiguous employee                  → asks, never guesses
general reader wants a salary       → denied
unknown sensitive column            → blocked
the model invents a leave number    → grounding blocks it
truncated result                    → no invented total
row cap exceeded                    → no auto-aggregate
write attempted on the read plane   → raises
kill switch on                      → AI never called
```

---

# 17. Reminder

The target is not:

> "Make the chatbot answer."

The target is:

> **Every displayed HR fact is authorized, grounded, privacy-safe, reproducible, and attributable to
> an immutable release.**

If a change makes the assistant smarter but weakens any of those, don't ship it.
