DRAFT — under review. Do not act on this yet.

# Business needs — Phase 1

> Written by the AI team only. Answer in `docs/response/business/phase1/phase1response.md`.
> The design is `plan/HR_ASSISTANT_ARCHITECTURE.md`.

---

### U2 — Managers may see their team's salary and penalties

Why:      Seif decided managers see their direct team's salary and penalties; HR has not confirmed
          (architecture §1, §7.9)
Blocks:   nothing — the switches default on. If HR says no, the switch goes off with no deploy
Owner:    business
Phase:    1
How to verify:
    Read HR's answer in the response file
Expected:
    A written yes or no, for salary and for penalties separately, from a named person in HR, with
    the date

### U4 — The exact deadline date

Why:      the plan is one week, approx. 2026-09-28, not confirmed (architecture header)
Blocks:   planning
Owner:    business
Phase:    1
How to verify:
    Read the answer in the response file
Expected:
    A date, from a named person, with what must be live on that date

### U6 — Which penalty statuses may be seen

Why:      the penalties query shows only visible statuses, from two settings —
          penalty_visible_statuses_self (someone viewing their own record) and
          penalty_visible_statuses_manager (a manager viewing a team member's). Both default to
          applied and appealed. The schema also has draft, investigating and waived
          (architecture §7.7)
Blocks:   `penalties`
Owner:    business
Phase:    1
How to verify:
    Read HR's answer in the response file
Expected:
    For employees and for managers: which of draft, investigating, applied, waived, appealed are
    visible — from a named person in HR, with the date

### U8 — HR approves the Arabic wording

Why:      every answer and refusal the user reads comes from docs/specs/templates.yaml and
          docs/specs/refusals.yaml. The Arabic was drafted by the AI team — including the column
          labels and the labels for coded values such as leave, contract and penalty statuses
Blocks:   release
Owner:    business
Phase:    1
How to verify:
    Read HR's answer in the response file
Expected:
    Approval of templates.yaml and refusals.yaml as they stand, or the changed wording — from a
    named person in HR, with the date and the git commit of the files reviewed
