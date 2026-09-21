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

Why:      the penalties query shows only visible statuses — default applied and appealed. The
          schema also has draft, investigating and waived (architecture §7.7)
Blocks:   `penalties`
Owner:    business
Phase:    1
How to verify:
    Read HR's answer in the response file
Expected:
    For employees and for managers: which of draft, investigating, applied, waived, appealed are
    visible — from a named person in HR, with the date
