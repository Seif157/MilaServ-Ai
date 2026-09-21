# Phase 1 — Pre-implementation · Requests to business

Answer in `docs/response/business/phase1/phase1response.md`, same request ID.
Format: CLAUDE.md §3.3. States: `REQUESTED → DONE → VERIFIED`.
**"Done" is a claim. "Verified" is a fact.** The AI team runs every check — never the deliverer.

---

### U1 — The business owner's name

Status: REQUESTED

Why:      business items don't block anyone's code on day one, so without a named owner they
          drift (CLAUDE.md §1.1). Every business request needs a person to chase it
Blocks:   Phase 1 exit
Owner:    business — ASBC
Due:      not set — project deadline not yet stated

Done by:  <name> — <date>
How to verify:
    Open docs/shared/STATUS.md, line "Business owner".
Expected:
    Business owner    <full name> — ASBC

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match

---

### U2 — The deadline

Status: REQUESTED

Why:      the deadline is fixed but not stated. It decides what gets cut in phases 9 (policy
          questions) and 10 (flexible questions). Minimum shippable is phases 1–8
Blocks:   planning of phases 9 and 10
Owner:    business — ASBC
Due:      not set — this item sets it

Done by:  <name> — <date>
How to verify:
    Open docs/shared/STATUS.md, line "Deadline".
Expected:
    Deadline          <YYYY-MM-DD> — agreed by <name>, <YYYY-MM-DD>

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match

---

### U3 — D1 tenancy: database per client, or shared? (ask the client)

Status: REQUESTED

Why:      zero `company_id` / `tenant_id` columns exist, yet `settings_billing_*` tables do. If
          the answer is "shared tenant", the entire RLS model is invalid. Unanswered after six
          rounds. This is the client's answer, not ASBC's guess
Blocks:   everything, if the answer is "shared"
Owner:    business → client
Due:      not set — project deadline not yet stated

Done by:  <name> — <date>
How to verify:
    Open docs/shared/DECISIONS.md, entry D1.
Expected:
    State: DECIDED — "database per client" or "shared"
    Agreed by: <client contact name> · Date: <YYYY-MM-DD>
    If "shared": a D1 entry exists in docs/shared/BLOCKED.md

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match

---

### U4 — How the business owner writes their responses

Status: REQUESTED

Why:      the business owner does not use Git Bash. They need one agreed way to update
          docs/response/business/phase1/phase1response.md: either the GitHub/GitLab web editor, or they send updates to Seif, who commits them.
          Must be agreed before Phase 1 closes (CLAUDE.md §1.1)
Blocks:   Phase 1 exit
Owner:    business — ASBC
Due:      not set — project deadline not yet stated

Done by:  <name> — <date>
How to verify:
    1  Open docs/shared/DECISIONS.md — the chosen route is recorded with name and date
    2  git log --format='%an %ad %s' -- docs/response/business/phase1/phase1response.md
Expected:
    1  Route: "web editor" or "via Seif" — agreed by <name>, <YYYY-MM-DD>
    2  At least one commit to that file made through that route
       (web editor → authored by the business owner; via Seif → message names the business owner)

Verified by: <name> — <date>
Actual output: <pasted> — matched | did not match
