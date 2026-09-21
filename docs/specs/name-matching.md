# Name matching — spec for Laravel

> **Implements** architecture §8. The query is the team search in
> [`catalogue.md`](catalogue.md#team-search--architecture-81) — it is not repeated here
> (decision 005).
> **Status** Draft · 2026-09-21

## 1. Who is the subject

The AI service returns `subject` (`understand.openapi.yaml`). Laravel decides:

| `subject` | Asker | Outcome |
|---|---|---|
| `null` (intent `unknown`) | anyone | `not_understood` — never acted on (L3) |
| `kind: self` | anyone | The asker. No search |
| `kind: person` | employee | Refuse `own_records_only` — **no query of any kind runs** (L5) |
| `kind: person` | manager | Search the direct team — §2 |

`my_team` is always about the asker's own team; its subject is ignored.

## 2. The search

- Run the team search with `:principal_id` = the asker, from the session — never from the request
  or the AI service (L1, L7)
- Bind the searched text to `:q_a`, `:q_b`, `:q_c` and `:q_d` — the same value. The searched text is
  `subject.employee_number` if the AI service returned one, otherwise `subject.name`
- The query searches **only the asker's active direct reports**. It never reaches anyone else, so
  it can't reveal whether a name exists outside the team (L4)
- Normalisation happens in the database: `app.ar_normalize()` for Arabic spelling (أحمد / احمد) and
  `app.normalize_digits()` for Arabic-Indic digits in employee numbers. Laravel sends the text as
  written

## 3. Deciding

Take the rows in the order the query returns them (number match first, then score).

| # | Result | Outcome |
|---|---|---|
| 1 | The first row has `number_match` true | That person. `employee_number` is unique in `employees` |
| 2 | The top score ≥ **0.6** and at least **0.15** above the second row's score — or there is no second row | That person |
| 3 | One or more rows score ≥ **0.3**, none clearly ahead | **Ask** — `needs_choice` with up to **5** candidates |
| 4 | No row scores ≥ 0.3 | `not_found` (refusals.yaml) |

**Never pick silently between two people.** When in doubt, ask.

The thresholds — 0.6, 0.15, 0.3 and 5 — are Laravel settings, tuned against the eval set. Changing
them needs no deploy.

## 4. Asking — choice codes

- Candidates are the rows scoring ≥ 0.3, best first, at most 5
- Each gets a code, `c1` to `c5`, in that order. The response carries the code and a label:
  `"<employee_number> — <first_name_local> <last_name_local>"` in Arabic, `"<employee_number> —
  <first_name> <last_name>"` in English. **Never the `employee_id`** (L9)
- Laravel keeps the map from code to `employee_id` **on the server**, scoped to that turn and that
  asker
- A choice is accepted only when:
  - it comes from **the same asker** as the turn
  - it names **the same turn**
  - it arrives **within 10 minutes** of the turn
  - the code is one of that turn's codes
- Anything else is refused. After a valid choice, the original question is answered for that
  person; the code map is then discarded

## 5. Not found

`not_found` has one text and one response shape. Laravel returns **exactly the same bytes** when:
- no one in the team matches, and
- the person exists, but outside the asker's team

because the search never looks outside the team, the two cases can't differ. A backend test
asserts the two responses are byte-identical (L6).
