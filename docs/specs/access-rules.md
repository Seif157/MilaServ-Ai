# Access rules — requirements for Laravel

> **Implements** architecture §4.2. Laravel holds every check that protects employee data. Breaking
> one of L1–L11 is a security bug; L12 is a correctness rule, kept here so it isn't missed.
> **Status** Draft · 2026-09-21 · tracked as need B8

| # | Rule | Why |
|---|---|---|
| **L1** | **Identity comes only from the Laravel session.** Nothing in the question, the request body or the AI service's output can change who is asking | Anything else can be typed or forged by the user |
| **L2** | **The allowed set is computed, never supplied.** An employee: themselves. A manager: themselves plus active employees whose `manager_id` is theirs — and only if Laravel marks the user as a manager (B2) | A set the client or the AI can influence is no boundary at all |
| **L3** | **The AI service's output is an untrusted suggestion.** Check it against `understand.openapi.yaml` again and validate every detail. Intent `unknown`, a `null` subject, or anything off → `not_understood`. Never act on a missing subject | The model can be fooled by the question it reads (architecture §4.3) |
| **L4** | **A subject name is searched only inside the allowed set** — the team search in `catalogue.md` | Searching wider would reveal who exists and let a name reach other people's data |
| **L5** | **An employee asking about another person is refused with no lookup at all** — no query runs | A lookup that runs can leak through timing, errors or logs, even when the answer is refused |
| **L6** | **A manager asking about someone outside their team gets exactly the same response as for a name that doesn't exist.** Byte-identical — same status, reason, text and shape | Any difference tells the manager that the person exists |
| **L7** | **Fixed, parameterised SQL only** — the queries in `catalogue.md`. The employee comes only from the resolver as `:target_id`, or the session as `:principal_id`. No generated SQL, no string building, no `SELECT *` | A query built from input can be steered to anyone's rows |
| **L8** | **Laravel never sends employee data to the AI service.** The request carries the question text and a `request_id`, nothing else | The AI service and its provider must never hold employee data (architecture §4.1) |
| **L9** | **The browser never sends an employee ID.** Ambiguous names get turn-scoped choice codes (`c1`, `c2`) held on the server (`name-matching.md`) | An ID from the browser can be edited to point at anyone |
| **L10** | **Every value in an answer comes from a query row**, placed by a template (`templates.yaml`) | Values the AI writes can be invented; values from rows can't |
| **L11** | **Checks never degrade.** If the AI service, a check or the database can't run, the answer is `unavailable` — never an answer without the check | A fallback that skips a check becomes the easiest way around it |
| **L12** | **Laravel resolves every date.** A `period` token becomes dates with Laravel's own **Africa/Cairo** clock; "today" in every query comes from the same clock, never from the AI service or the database. A stated `year` and `month` are validated as plausible | One clock, in the company's time zone, gives the same month to every question |

## Manager switches

Before answering a manager about a team member, Laravel checks the switch for the question type's
sensitivity (architecture §7.9):

| Sensitivity | Question types | Switch | Default |
|---|---|---|---|
| compensation | `salary` | `manager_sees_compensation` | on |
| disciplinary | `penalties` | `manager_sees_disciplinary` | on |
| general | all others | — | always on |

Switch off → `manager_access_off`. A manager asking about **themselves** is never affected.

## Visible penalty statuses

Which penalty statuses can be seen depends on whose record it is:

| Viewing | Setting | Default |
|---|---|---|
| Their own record — employee or manager | `penalty_visible_statuses_self` | `{applied, appealed}` |
| A team member's record — manager only | `penalty_visible_statuses_manager` | `{applied, appealed}` |

Laravel binds the chosen setting to `:visible_statuses` (`catalogue.md`). Business U6 decides both.
