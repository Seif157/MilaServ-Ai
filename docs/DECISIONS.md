# Decisions

Every decision — what, who, when. Newest last. The design follows from these:
`plan/HR_ASSISTANT_ARCHITECTURE.md`.

---

### 001 — v1 requirements

What:  Employees ask about themselves only; managers about themselves and their direct team.
       Eight question types. Arabic (Egyptian and MSA) and English, answered in the language of the
       question. Excel/CSV downloads for every table. Managers see their team's salary and penalties,
       switchable off. Full list: architecture §1
Who:   Seif Eleslam
When:  2026-09-21

### 002 — The AI team builds only AI parts

What:  - The **AI service** is an understanding service only. It receives question text and returns
         structured meaning. It holds no employee data, no user identity, and has no database access
         of any kind
       - **Laravel** owns everything else: the chat endpoint, who is asking, who may see whom, the
         fixed queries, finding a team member by name, filling templates, downloads, the turn log,
         the kill switch for the feature, and the chat screen
       - The AI team also writes **specs** Laravel implements: the question-type catalogue with draft
         SQL, name-matching rules, the access rules, the answer templates in Arabic and English,
         refusal texts, download rules, and the turn-log fields
       - Database and backend work goes to `docs/needs/`
       - The AI understands all 8 question types. Laravel implements them in priority order —
         P1: leave_balance, leave_requests, attendance_month, salary ·
         P2: contract, documents_expiring, penalties, my_team
Who:   Seif Eleslam
When:  2026-09-21
Replaces: the signed token, the read-only `erp_hr` login, the local `erp_hr` copy and fake seed
       data, and the `hr_assistant` database in the AI service

### 003 — Folder layout

What:  `plan/` holds the architecture, `schema/erp_hr_schema.sql` the schema reference (never loaded
       into any database), `docs/specs/` the specs for the backend, `docs/needs/` and
       `docs/response/` the needs, `docs/DECISIONS.md` and `docs/STATUS.md` the shared state.
       Full layout: `CLAUDE.md`
Who:   Seif Eleslam
When:  2026-09-21

### 004 — The understanding contract, dates and the SQL's home

What:  1. Invalid model output → intent `unknown`, `subject` `null`, `details` `{}`; `language` set by
          code from the script (any Arabic letter → `ar`). `subject` may be `null` **only** when
          intent is `unknown` — never a default of `self`, a misleading value Laravel could act on
       2. Provider unreachable after retries → `503`. Invalid output → `200` with intent `unknown`.
          Kept distinct
       3. The AI service never resolves dates. `details` carries the absolute `year`/`month` the user
          stated, or a `period` token — `this_month`, `last_month`, `this_year`, `last_year`.
          Laravel resolves it with its own Africa/Cairo clock (L12)
       4. The AI service's kill switch is an environment variable; a restart is acceptable. The
          primary kill switch is Laravel's — within 10 s, no deploy
       5. SQL is written in Laravel/PDO dialect — `:name` bindings, `CAST(:x AS type)`, each
          placeholder once per statement (`:x_a`, `:x_b` for reuse), arrays as
          `= ANY(CAST(:x AS text[]))` bound to a Postgres array literal. **It lives only in
          `docs/specs/`**; the architecture says what each query means and points there
       6. New business need U7: an export of question text + understanding result for evaluation —
          never answer values. Not assumed until U7 is answered; subject to U5
       7. The `/v1/understand` response adds `meta`: `request_id`, `prompt_version`, `model_id`.
          Laravel stores `prompt_version` and `model_id` in its turn log
       Also kept: L11 (checks never degrade) and B5 (network access)
Who:   Seif Eleslam
When:  2026-09-21
