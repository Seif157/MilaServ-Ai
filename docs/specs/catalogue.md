# Catalogue — the SQL, for Laravel

> **Spec for the backend.** Implements architecture §7 (the question types) and §8.1 (the team
> search). What each query means, and why, is there; **the SQL lives only here.** No other copy.
> **Status** Draft · 2026-09-21 · checked against `schema/erp_hr_schema.sql`, not against data.
> The backend runs each query on the fake-data database (D4) and reviews it (BQ5) before release.

## Binding rules

- **Laravel/PDO named bindings** — `:name`. Pass them as an array to `DB::select($sql, $bindings)`
- **Each placeholder appears once per statement.** PDO native prepares reject a repeated name. Where a
  value is needed twice, it has two names — `:leave_code_a` and `:leave_code_b` — and Laravel binds
  **the same value to both**
- **Casts use `CAST(:x AS type)`**, never `:x::type` — PDO can misread `::`
- **Arrays** bind as a Postgres array literal string, e.g. `'{applied,appealed}'`, read with
  `= ANY(CAST(:visible_statuses AS text[]))`
- **The employee comes only from the resolver:** `:target_id` (the resolved subject) or
  `:principal_id` (the asker, from the session). Never from the request, never from the AI service
- **"Today"** is computed by Laravel in **Africa/Cairo** time and bound as `:today_*` or used to build
  `:from_date`, `:year`, `:month`, `:fiscal_year`. Never the database clock
- **Named columns only** — never `SELECT *`
- Run inside a **read-only transaction** with `statement_timeout = 5s` and `lock_timeout = 1s`
  (architecture §12)

---

## P1

### leave_balance

```sql
SELECT lt.leave_code, lt.leave_name, lt.leave_name_local,
       lb.fiscal_year,
       lb.opening_balance, lb.accrued_ytd, lb.used_ytd, lb.pending_ytd,
       (lb.opening_balance + lb.accrued_ytd - lb.used_ytd - lb.pending_ytd) AS remaining
FROM   leave_balances lb
JOIN   leave_types    lt ON lt.leave_type_id = lb.leave_type_id
WHERE  lb.employee_id = :target_id
  AND  lb.fiscal_year = :fiscal_year
  AND  lb.is_active
  AND  (CAST(:leave_code_a AS text) IS NULL OR lt.leave_code = :leave_code_b)
ORDER  BY lt.leave_name;
```

| Binding | Value |
|---|---|
| `:target_id` | the resolved subject |
| `:fiscal_year` | the year asked, or the current year — BQ1 |
| `:leave_code_a`, `:leave_code_b` | the same value: a `leave_types.leave_code`, or `null` for all types |

### leave_requests

```sql
SELECT lt.leave_name, lt.leave_name_local,
       lr.start_date, lr.end_date, lr.working_days, lr.is_half_day,
       lr.status, lr.reviewed_at
FROM   leave_requests lr
JOIN   leave_types    lt ON lt.leave_type_id = lr.leave_type_id
WHERE  lr.employee_id = :target_id
  AND  lr.is_active
  AND  lr.status <> 'draft'
  AND  (CAST(:status_a AS text) IS NULL OR lr.status = :status_b)
  AND  lr.start_date >= :from_date
ORDER  BY lr.start_date DESC
LIMIT  50;
```

| Binding | Value |
|---|---|
| `:target_id` | the resolved subject |
| `:status_a`, `:status_b` | the same value: `pending`, `approved`, `rejected`, `returned`, `cancelled`, or `null` for all |
| `:from_date` | the start of the period asked |

### attendance_month

```sql
SELECT s.year, s.month, s.working_days_in_month,
       s.days_present, s.days_absent, s.days_on_leave,
       s.total_late_minutes, s.total_overtime_minutes,
       (SELECT count(*)
          FROM attendance_records r
         WHERE r.employee_id = s.employee_id
           AND r.is_active
           AND r.late_minutes > 0
           AND r.attendance_date >= make_date(s.year, s.month, 1)
           AND r.attendance_date <  make_date(s.year, s.month, 1) + interval '1 month'
       ) AS late_days
FROM   attendance_summaries s
WHERE  s.employee_id = :target_id
  AND  s.year  = :year
  AND  s.month = :month
  AND  s.is_active;
```

| Binding | Value |
|---|---|
| `:target_id` | the resolved subject |
| `:year`, `:month` | the calendar month asked, resolved by Laravel — BQ3 |

### salary

```sql
SELECT basic_salary,
       housing_allowance, transport_allowance, food_allowance,
       mobile_allowance, other_allowance,
       gross_salary, net_salary,
       currency_code, pay_frequency, effective_date
FROM   salary
WHERE  employee_id = :target_id
  AND  is_current
  AND  is_active
  AND  approval_status = 'approved';
```

| Binding | Value |
|---|---|
| `:target_id` | the resolved subject |

More than one row → refused and logged as a data problem, never guessed (BQ2).

---

## P2

### contract

```sql
SELECT contract_type, contract_status,
       start_date, end_date, is_open_ended,
       probation_end_date, notice_period_days, notice_period_unit,
       renewal_type
FROM   employee_contracts
WHERE  employee_id = :target_id
  AND  is_current
  AND  is_active
  AND  contract_type <> 'remote_work_addendum';
```

| Binding | Value |
|---|---|
| `:target_id` | the resolved subject |

### documents_expiring

```sql
SELECT document_type, document_title,
       issue_date, expiry_date,
       (expiry_date - CAST(:today_a AS date)) AS days_left,
       is_mandatory, is_verified
FROM   employee_documents
WHERE  employee_id = :target_id
  AND  is_active
  AND  expiry_date IS NOT NULL
  AND  expiry_date <= CAST(:today_b AS date) + CAST(:within_days AS integer)
ORDER  BY expiry_date;
```

| Binding | Value |
|---|---|
| `:target_id` | the resolved subject |
| `:today_a`, `:today_b` | the same value: today in Africa/Cairo, `YYYY-MM-DD` |
| `:within_days` | from the question, or a default — validated as a positive integer |

### penalties

```sql
SELECT p.penalty_no, v.name_ar, v.name_en,
       p.occurred_on, p.penalty_kind, p.deduction_days,
       p.status, p.applied_at
FROM   cd_penalties       p
JOIN   cd_violation_types v ON v.violation_type_id = p.violation_type_id
WHERE  p.employee_id = :target_id
  AND  p.status = ANY(CAST(:visible_statuses AS text[]))
  AND  p.occurred_on >= :from_date
ORDER  BY p.occurred_on DESC
LIMIT  50;
```

| Binding | Value |
|---|---|
| `:target_id` | the resolved subject |
| `:visible_statuses` | from the setting `penalty_visible_statuses` — default `'{applied,appealed}'` until U6 |
| `:from_date` | the start of the period asked |

### my_team — manager only

```sql
SELECT e.employee_number,
       e.first_name, e.last_name, e.first_name_local, e.last_name_local,
       p.position_title, p.position_title_local,
       e.employment_status, e.hire_date
FROM   employees e
LEFT   JOIN positions p ON p.position_id = e.position_id
WHERE  e.manager_id = :principal_id
  AND  e.is_active
ORDER  BY e.first_name_local, e.first_name;
```

| Binding | Value |
|---|---|
| `:principal_id` | the asker, from the session |

---

## Team search — architecture §8.1

```sql
SELECT e.employee_id, e.employee_number,
       e.first_name, e.last_name, e.first_name_local, e.last_name_local,
       GREATEST(
         similarity(app.ar_normalize(coalesce(e.first_name_local,'') || ' ' ||
                                     coalesce(e.last_name_local,'')),
                    app.ar_normalize(:q_a)),
         similarity(app.ar_normalize(coalesce(e.first_name_local,'')),
                    app.ar_normalize(:q_b)),
         similarity(lower(coalesce(e.first_name,'') || ' ' || coalesce(e.last_name,'')),
                    lower(:q_c))
       ) AS score,
       (app.normalize_digits(e.employee_number) = app.normalize_digits(:q_d)) AS number_match
FROM   employees e
WHERE  e.manager_id = :principal_id
  AND  e.is_active
ORDER  BY number_match DESC, score DESC
LIMIT  10;
```

| Binding | Value |
|---|---|
| `:principal_id` | the asker, from the session |
| `:q_a`, `:q_b`, `:q_c`, `:q_d` | the same value: the name or employee number from the AI service's `subject` |
