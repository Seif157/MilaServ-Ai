# Phase 1 — Pre-implementation · Exit

The tests that prove Phase 1 is finished. Source: CLAUDE.md §6 (Phase 1), §1.1, §5.2.
**The phase ends only when every item passes.** Each exit item becomes part of Phase 2's needs.

| # | Test | How to check | Pass when |
|---|---|---|---|
| E1 | Findings marked with evidence | `docs/response/ai/phase1/` · `docs/response/backend/phase1/` B2 | Findings 13, 14, 15 each `CONFIRMED` or `CORRECTED`, with the Gate A output pasted, taken at the recorded migration head |
| E2 | Migration head recorded | `docs/shared/STATUS.md` | "Migration head" names one migration, equal to backend B3 |
| E3 | `DECISIONS.md` started | `docs/shared/DECISIONS.md` | Exists with every §4 item; #1 `DECIDED`; others `PENDING` unless decided with name and date |
| E4 | ScopeToken v1 frozen | `docs/shared/contracts/scope_token_v1.md` | Marked `FROZEN — v1`, signing algorithm per decision #8, no `conversation_access` claim, `as_of` UTC |
| E5 | Persistence v1 frozen | `docs/shared/contracts/persistence_v1.md` | Marked `FROZEN — v1`, written against the `asst_*` tables at migration head, agreed by backend |
| E6 | Shared token fixture committed in both repositories | `docs/shared/contracts/fixtures/scope_token_v1.jwt` here + Laravel's copy | Laravel's test asserts its copy's hash equals the canonical file |
| E7 | Fixture passing in both test suites | Python suite · Laravel suite | Both validate the same signed token — green in both |
| E8 | Business owner named | `docs/shared/STATUS.md` | "Business owner" holds a name (business U1 `VERIFIED`) |
| E9 | Business update route agreed | `docs/shared/DECISIONS.md` | Web editor or via Seif, with name and date (business U4 `VERIFIED`) |

## Carried into Phase 2 — "Before starting"

Phase 1 exit · decision #3 `DECIDED` · ScopeToken v1 + key pair (decision #8).
