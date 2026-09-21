# Turn log — spec for Laravel

> **Implements** architecture §11. Tracked as need B13.
> **Status** Draft · 2026-09-21

One row per question, in Laravel's own storage. The table name and storage are the backend's
choice.

## Fields

| Field | Type | Meaning |
|---|---|---|
| `turn_id` | uuid | The turn |
| `request_id` | uuid | Sent to `/v1/understand` and echoed in `meta`; joins this row to the AI service's log line |
| `asked_at` | timestamptz | When |
| `principal_employee_id` | uuid | Who asked — from the session |
| `principal_is_manager` | boolean | As Laravel decided it |
| `question_text` | text | What was asked — retention is business U5 |
| `language` | text | `ar` or `en` |
| `intent` | text | As returned by the AI service |
| `prompt_version` | text | `meta.prompt_version` from the AI service |
| `model_id` | text | `meta.model_id` from the AI service |
| `subject_kind` | text, nullable | `self` or `person`; `null` when intent is `unknown` |
| `target_employee_id` | uuid, nullable | Who the answer was about, once resolved |
| `outcome` | text | `answered`, `needs_choice`, `refused`, `unavailable` |
| `refusal_reason` | text, nullable | A reason from `refusals.yaml` — including `data_problem`, so records with more than one current row can be found and fixed |
| `sensitivity` | text | `general`, `compensation`, `disciplinary` |
| `row_count` | integer | Rows the query returned |
| `latency_ms` | integer | End to end |
| `release` | text | Laravel's build version |

A choice (`c1`…) answering a `needs_choice` turn is logged as its own row, with the same fields.

## Never stored

- **Answer values** — no salaries, balances, penalties, dates, or any other value from a query row.
  Not in the turn log, not in application logs, not in error reports
- **The answer text** — it is made of those values
- **Candidate lists** — the names and numbers offered in `needs_choice`
- **The choice-code map** — it lives only for 10 minutes, in memory (`name-matching.md`)
- **Download contents** (`downloads.md`)
- **The service key**

## Stored, with care

- **`question_text`** — kept because it's needed to improve understanding. It can contain names, so
  how long it is kept is business **U5**
- **An export to the AI team** of `question_text`, `intent`, `subject_kind`, `language` and
  `prompt_version`, for evaluation — never answer values. Only once business **U7** approves it, and
  within U5
