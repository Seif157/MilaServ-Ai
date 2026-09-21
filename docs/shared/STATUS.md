# STATUS

> One screen. If this needs scrolling, cut it.

```
Current phase     Phase 1 — Pre-implementation
State             NOT STARTED
Waiting on        the current schema at migration head (CLAUDE.md §5)
Migration head    not yet recorded
Deadline          fixed, but not yet stated — decides what gets cut in phases 9 and 10
Business owner    a person at ASBC — name not yet recorded
Plan maturity     10/10
System readiness  0/10 — no code exists yet
Last updated      2026-09-21
```

## Open requests — Phase 1

| # | Request | Owner | State |
|---|---|---|---|
| B1 | Current schema at migration head | backend | REQUESTED |
| B2 | Gate A query results (5) | backend | REQUESTED |
| B3 | Migration head — `migrate:status` last row | backend | REQUESTED |
| B4 | Agreement on decision #3 — read/write plane split | backend | REQUESTED |
| B5 | Agreement on decision #8 — EdDSA key pair | backend | REQUESTED |
| U1 | Business owner's name | business | REQUESTED |
| U2 | The deadline | business | REQUESTED |
| U3 | D1 tenancy — per client or shared | business → client | REQUESTED |
| U4 | How business writes its responses | business | REQUESTED |

Needs:      `docs/needs/<ai|backend|business|exit>/phase1/phase1needs.md`
Responses:  `docs/response/<ai|backend|business|exit>/phase1/phase1response.md`

## Red / green

```
RED    Gate A findings 13 · 14 · 15      not yet marked
RED    Contracts                          ScopeToken v1 · Persistence v1 not frozen
RED    Shared token fixture               not committed
GREEN  DECISIONS.md                       started
```
