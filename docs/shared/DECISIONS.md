# DECISIONS

Every decision: what, who agreed, when. Source: CLAUDE.md §4.

**Never treat a `PENDING` decision as decided.** If a task needs one → `BLOCKED`.
A decision changes state only when **Agreed by** and **Date** are filled in.

## Summary

| # | Decision | State | Needed before |
|---|---|---|---|
| 1 | Chat privacy | **DECIDED — owner-only** | — |
| 2 | Investigation access to others' chats | PENDING | Nothing, if "never" |
| 3 | Read / write plane split | PENDING | **Phase 2** |
| 4 | What data may reach the AI provider | PENDING | Egress gate · salary intents |
| 5 | AI provider and data region | PENDING | Phase 8 |
| 6 | Engineering retention | PENDING | Phase 8 |
| 7 | Legal retention | PENDING | Phase 8 |
| 8 | Token signing | PENDING | **Phase 1 contract freeze** |
| 9 | Minimum group size for sensitive averages | PENDING | Any sensitive aggregate |
| 10 | Document metadata access (plan §5.3) | PENDING | `hr.documents_expiring` |
| D1 | Tenancy — database per client, or shared? | PENDING | Everything, if "shared" |
| S1 | Python version and driver | PENDING | Phase 2 |

Only **#3** and **#8** are needed before Phase 2.

---

### #1 — Chat privacy

State:          DECIDED
Decision:       Owner-only. Managers never read their team's AI chats.
Enforced by:    `USING (employee_id = app.principal_employee_id())` — no `OR`, no session
                variable, no token claim (CLAUDE.md §7.6)
Agreed by:      not recorded — to be filled
Date:           not recorded — to be filled

### #2 — Investigation access to others' chats

State:          PENDING
Recommendation: **Never** in v1. If ever approved: a separate short-lived
                `ConversationAccessGrant` naming one subject, with a reason and an audit row.
                Do not build it speculatively.
Needed before:  Nothing, if "never"
Owner:          business
Agreed by:      —
Date:           —

### #3 — Read / write plane split

State:          PENDING
Recommendation: **Yes.** `assistant_app` (LOGIN, NOINHERIT) → `SET LOCAL ROLE assistant_reader` /
                `assistant_reader_comp` for reads; `SET LOCAL ROLE assistant_audit_writer`
                (INSERT-only on `asst_*` and `asst_releases`, no HR read) for writes (CLAUDE.md §7.5)
Needed before:  **Phase 2**
Owner:          backend — agree with AI
Agreed by:      —
Date:           —

### #4 — What data may reach the AI provider

State:          PENDING
Recommendation: **Code-filled values** for compensation and disciplinary. The model writes the
                shape (*"Your basic salary is `{salary}`"*); code inserts the real figure after the
                model is done. The provider never sees the number.
Needed before:  Egress gate · salary intents
Owner:          business
Agreed by:      —
Date:           —

### #5 — AI provider and data region

State:          PENDING
Recommendation: none — **client's decision**
Needed before:  Phase 8
Owner:          client
Agreed by:      —
Date:           —

### #6 — Engineering retention

State:          PENDING
Recommendation: Query results **7 days**; raw prompts **not stored**.
Needed before:  Phase 8
Owner:          business
Agreed by:      —
Date:           —

### #7 — Legal retention

State:          PENDING
Recommendation: none — **legal** decides: conversations, access logs, security events, feedback
Needed before:  Phase 8
Owner:          legal
Agreed by:      —
Date:           —

### #8 — Token signing

State:          PENDING
Recommendation: **EdDSA key pair.** Laravel holds the private key; Python holds only the public
                key and can only verify. With a shared secret the AI service could mint any
                token, including HR-admin scope.
Needed before:  **Phase 1 contract freeze** (ScopeToken v1)
Owner:          backend — agree with AI
Agreed by:      —
Date:           —

### #9 — Minimum group size for sensitive averages

State:          PENDING — decision required
Recommendation: none yet. **Until decided: sensitive aggregates are refused outright**
                (`cohort_too_small`, phrased so it doesn't confirm the group size — CLAUDE.md §7.9)
Needed before:  Any sensitive aggregate
Owner:          business
Agreed by:      —
Date:           —

### #10 — Document metadata access (plan §5.3)

State:          PENDING
Recommendation: none — **backend owner's call**
Needed before:  `hr.documents_expiring`
Owner:          backend
Agreed by:      —
Date:           —

### D1 — Tenancy: database per client, or shared?

State:          PENDING — **ask the client**
Recommendation: none. Zero `company_id` / `tenant_id` columns exist, yet `settings_billing_*`
                tables do. If the answer is "shared tenant", the entire RLS model is invalid.
                Unanswered after six rounds.
Needed before:  Everything, if "shared"
Owner:          business → client
Agreed by:      —
Date:           —

### S1 — Python version and driver

State:          PENDING — default in use, needs confirmation
Recommendation: **Python 3.12 + psycopg 3** (+ FastAPI). If the driver changes, CLAUDE.md §7.4's
                read-only line changes with it.
Needed before:  Phase 2
Owner:          AI
Agreed by:      —
Date:           —
