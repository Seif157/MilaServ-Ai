DRAFT — under review. Do not act on this yet.

# Database needs — Phase 1

> Written by the AI team only. Answer in `docs/response/database/phase1/phase1response.md`.
> The design is `plan/HR_ASSISTANT_ARCHITECTURE.md`.

---

### D4 — A fake-data database for the backend

Why:      the backend builds and tests the catalogue (docs/specs/catalogue.md) and the access rules
          against it. Nobody develops against real employee data (architecture §10)
Blocks:   backend testing — B8, B9, B10, B16, BQ5
Owner:    database
Phase:    1
How to verify:
    A person on the AI team — never Claude Code — runs, on the fake-data database:

    -- 1  a manager with at least 3 active direct reports
    SELECT m.employee_number, count(*) AS reports
    FROM   employees e JOIN employees m ON m.employee_id = e.manager_id
    WHERE  e.is_active
    GROUP  BY m.employee_number HAVING count(*) >= 3;

    -- 2  the two similar names, in the same team
    SELECT first_name_local, last_name_local, manager_id
    FROM   employees
    WHERE  first_name_local IN ('أحمد', 'احمد') AND last_name_local IN ('محمد', 'محمود');

    -- 3  shape of the rest
    SELECT (SELECT count(DISTINCT status) FROM leave_requests)                    AS leave_statuses,
           (SELECT count(DISTINCT (year, month)) FROM attendance_summaries)         AS summary_months,
           (SELECT count(*) FROM salary WHERE is_current AND approval_status = 'approved')
                                                                                   AS current_salaries,
           (SELECT count(*) FROM employee_contracts
             WHERE is_current AND contract_type = 'remote_work_addendum')         AS addenda,
           (SELECT count(*) FROM employee_documents WHERE expiry_date < current_date) AS expired_docs,
           (SELECT count(DISTINCT status) FROM cd_penalties)                       AS penalty_statuses;

    -- 4  no real data: the database name and the source of its rows, stated in the response
Expected:
    1  at least one row, reports ≥ 3
    2  two rows — أحمد محمد and احمد محمود — with the same manager_id
    3  leave_statuses ≥ 3 · summary_months ≥ 2 · current_salaries ≥ 1 · addenda ≥ 1 ·
       expired_docs ≥ 1 · penalty_statuses ≥ 3
    4  the response states the data is generated, with no row copied from erp_hr
    Plus: at least one active employee whose manager is someone else — the "other team" employee
    a manager must not reach
