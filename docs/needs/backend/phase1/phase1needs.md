DRAFT — under review. Do not act on this yet.

# Backend needs — Phase 1

> Written by the AI team only. Answer in `docs/response/backend/phase1/phase1response.md`.
> The design is `plan/HR_ASSISTANT_ARCHITECTURE.md`; the specs are in `docs/specs/`.
> Implementation needs (B6–B16) are in priority order: **P1 first, then P2.**

---

## Agreements

### B1 — Shared service key

Why:      Laravel must prove to the AI service that a call comes from Laravel (architecture §5.1)
Blocks:   integration (Phase 5)
Owner:    backend
Phase:    1
How to verify:
    Against the AI service in staging, once B5 is done:
    curl -s -o /dev/null -w '%{http_code}\n' -X POST <service>/v1/understand \
         -H 'Content-Type: application/json' \
         -d '{"question":"test","request_id":"5b0e3c7a-2f1d-4c6e-9a8b-1d2e3f4a5b6c"}'
    Then the same with  -H 'X-Service-Key: <the agreed key>'
Expected:
    401 without the key · 200 with it · the key is in neither repo — only in each side's .env

### B2 — Which roles count as a manager

Why:      manager access needs both Laravel's manager mark and `employees.manager_id` (architecture
          §1, access rule L2)
Blocks:   manager access
Owner:    backend
Phase:    1
How to verify:
    Read the answer in the response file: the role name(s), and where in Laravel the check lives
Expected:
    A list of role names, and the file and function that decide "is a manager"

### B4 — Where the chat screen lives

Why:      the screen is Laravel's (architecture §1); we need to know where it sits and who sees it
Blocks:   B15
Owner:    backend
Phase:    1
How to verify:
    Read the answer in the response file
Expected:
    The ERP page or menu it lives on, and which users see it

### B5 — Network access from Laravel to the AI service

Why:      Laravel calls /v1/understand; the AI service must not be reachable from outside
          (architecture §4.1, rule 5)
Blocks:   integration (Phase 5)
Owner:    backend
Phase:    1
How to verify:
    From the Laravel host:        curl -s -o /dev/null -w '%{http_code}\n' <service>/healthz
    From outside the internal network: the same command
Expected:
    200 from the Laravel host · no connection from outside

---

## Questions

### BQ1 — Does `leave_balances.fiscal_year` mean the calendar year?

Why:      Laravel binds `:fiscal_year` for `leave_balance` from the question or today's date
          (catalogue.md)
Blocks:   `leave_balance`
Owner:    backend
Phase:    1
How to verify:
    Read the answer, with the code or rule that fills fiscal_year
Expected:
    Yes, or the rule that maps a date to a fiscal year

### BQ2 — Can one employee have two `salary` rows with `is_current = true`?

Why:      the `salary` query expects one row; more are refused as `data_problem` (architecture §7.4)
Blocks:   `salary`
Owner:    backend
Phase:    1
How to verify:
    Read the answer, with the constraint or code that enforces it
Expected:
    No, with where it is enforced — or yes, with the rule for which row wins

### BQ3 — Is the attendance summary for the current month available?

Why:      "my attendance this month" needs the current month's `attendance_summaries` row
          (architecture §7.3)
Blocks:   `attendance_month`
Owner:    backend
Phase:    1
How to verify:
    Read the answer: when a month's summary row is created and updated
Expected:
    Updated during the month — or only after the month closes, and when

### BQ4 — Can a remote-work addendum be `is_current` alongside the main contract?

Why:      the `contract` query excludes addenda and expects one row; more are refused as
          `data_problem` (architecture §7.5)
Blocks:   `contract`
Owner:    backend
Phase:    1
How to verify:
    Read the answer
Expected:
    Yes or no, and whether more than one main contract can be current

### BQ5 — Review of every SQL in the catalogue

Why:      the queries are drafts checked against the schema, not against data (catalogue.md)
Blocks:   release
Owner:    backend
Phase:    1
How to verify:
    The response file lists every query in docs/specs/catalogue.md — the eight question types and
    the team search — each with the reviewer, the date, and the result of running it on the
    fake-data database (D4)
Expected:
    Nine queries, each "approved" or with the change asked for

---

## Implementation — P1

### B6 — The chat endpoint

Why:      the browser talks to Laravel only (architecture §5.3)
Blocks:   everything the user sees
Owner:    backend
Phase:    1
How to verify:
    On the backend's test environment, with the fake-data database (D4):
    - a question → a response in the §5.3 shape
    - a body with an extra field such as employee_id → 422
    - a question over 500 characters → 422
Expected:
    The §5.3 shape · 422 · 422

### B7 — Calling /v1/understand

Why:      Laravel sends only the question text and uses the answer as an untrusted suggestion
          (architecture §5.1, access rules L3, L8, L11, L12)
Blocks:   everything the user sees
Owner:    backend
Phase:    1
How to verify:
    - the outgoing request body, logged in a test: only question and request_id
    - AI service returns intent unknown, or 503, or times out → the user sees not_understood,
      unavailable, unavailable
    - details.period = last_month → the query gets last month, by Laravel's Africa/Cairo clock
    - the turn log row has the prompt_version and model_id from meta
Expected:
    As listed

### B8 — The access rules

Why:      Laravel holds every check that protects employee data (docs/specs/access-rules.md)
Blocks:   release
Owner:    backend
Phase:    1
How to verify:
    Backend tests on the fake-data database, one per rule L1–L12, shown in the response file.
    At least:
    - an employee asks about another person → own_records_only, and no query ran
    - a manager asks about someone in another team, and about a name that doesn't exist → the two
      responses are byte-identical
    - the manager switch off → manager_access_off for a team member; the manager's own still works
Expected:
    Every test passes

### B9 — The P1 queries

Why:      leave_balance, leave_requests, attendance_month and salary come first (architecture §7)
Blocks:   the P1 question types
Owner:    backend
Phase:    1
How to verify:
    Each of the four questions, asked on the fake-data database, returns the rows the seed data
    says it should. The SQL is exactly as in docs/specs/catalogue.md, or as changed through BQ5
Expected:
    Correct rows for all four · no SQL other than the catalogue's

### B10 — Name matching for managers

Why:      managers ask about team members by name or employee number (docs/specs/name-matching.md)
Blocks:   manager questions about a team member
Owner:    backend
Phase:    1
How to verify:
    On the fake-data database:
    - أحمد محمد vs احمد محمود → needs_choice with c1, c2 — never a silent pick
    - an employee number in Arabic-Indic digits → that person
    - a choice from another asker, or after 10 minutes → refused
Expected:
    As listed

### B11 — Templates and refusal texts for the P1 types

Why:      answers come from templates filled by code (docs/specs/templates.yaml, refusals.yaml)
Blocks:   the P1 question types
Owner:    backend
Phase:    1
How to verify:
    Each P1 type answered in Arabic and in English, about oneself and about a team member; each
    refusal reason triggered once
Expected:
    The texts match templates.yaml and refusals.yaml word for word, values filled from the rows

### B12 — Downloads

Why:      every answer with a table can be downloaded (docs/specs/downloads.md)
Blocks:   downloads
Owner:    backend
Phase:    1
How to verify:
    - download an answer as xlsx and as csv → the same rows and headers as the screen
    - the same link from another user, or after 10 minutes → refused
    - no file appears on the server's disk
Expected:
    As listed

### B13 — The turn log

Why:      one row per question, metadata only (docs/specs/turn-log.md)
Blocks:   release
Owner:    backend
Phase:    1
How to verify:
    Ask one question of each P1 type, then show the rows written
Expected:
    Every field in turn-log.md · no answer values anywhere in the rows

### B14 — Kill switch, switches and rate limit

Why:      the feature must stop in seconds without a deploy (architecture §12)
Blocks:   release
Owner:    backend
Phase:    1
How to verify:
    - assistant_enabled = false → questions get unavailable within 10 seconds, with no deploy
    - disabled_intents = [salary] → salary refused, the rest work
    - question 21 from one user within a minute → rejected
Expected:
    As listed

### B15 — The chat screen

Why:      users ask and read answers on an ERP page (B4)
Blocks:   the pilot
Owner:    backend
Phase:    1
How to verify:
    On the test environment: ask, see an answer with a table, pick from a needs_choice, download
Expected:
    All four work, in Arabic (right to left) and English

## Implementation — P2

### B16 — The P2 question types

Why:      contract, documents_expiring, penalties and my_team follow P1 (architecture §7)
Blocks:   the P2 question types — until then they are refused as not_available_yet
Owner:    backend
Phase:    1
How to verify:
    As B9 and B11, for the four P2 types
Expected:
    Correct rows, and texts that match templates.yaml and refusals.yaml
