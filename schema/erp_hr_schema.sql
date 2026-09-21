--
-- PostgreSQL database dump
--

\restrict PPChaNT6Bu7gRenwqo8nbXuMK3AQVZOit4wkzW9dbbUNuOIqT7lZBSHyswdeCdx

-- Dumped from database version 15.17
-- Dumped by pg_dump version 18.6

-- Started on 2026-09-21 15:49:14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 19095)
-- Name: app; Type: SCHEMA; Schema: -; Owner: erp_user
--

CREATE SCHEMA app;


ALTER SCHEMA app OWNER TO erp_user;

--
-- TOC entry 2 (class 3079 OID 19014)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 5750 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 413 (class 1255 OID 19096)
-- Name: ar_normalize(text); Type: FUNCTION; Schema: app; Owner: erp_user
--

CREATE FUNCTION app.ar_normalize(t text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
  SELECT lower(
           regexp_replace(
             translate(
               -- Strip tashkeel (U+064B..U+0652) and tatweel (U+0640) first, so a
               -- decorated letter reaches translate() in its bare form.
               regexp_replace(t, E'[\u064B-\u0652\u0640]', '', 'g'),
               -- أ إ آ ٱ  ى  ة  ئ  ؤ
               E'\u0623\u0625\u0622\u0671\u0649\u0629\u0626\u0624',
               -- ا ا ا ا  ي  ه  ي  و
               E'\u0627\u0627\u0627\u0627\u064A\u0647\u064A\u0648'
             ),
           '\s+', ' ', 'g')
         )
$$;


ALTER FUNCTION app.ar_normalize(t text) OWNER TO erp_user;

--
-- TOC entry 414 (class 1255 OID 19097)
-- Name: normalize_digits(text); Type: FUNCTION; Schema: app; Owner: erp_user
--

CREATE FUNCTION app.normalize_digits(t text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
  SELECT translate(
           t,
           -- Arabic-Indic then Eastern Arabic-Indic digits
           E'\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669\u06F0\u06F1\u06F2\u06F3\u06F4\u06F5\u06F6\u06F7\u06F8\u06F9',
           '01234567890123456789'
         )
$$;


ALTER FUNCTION app.normalize_digits(t text) OWNER TO erp_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 237 (class 1259 OID 16594)
-- Name: accounting_salary; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.accounting_salary (
    acc_salary_id uuid DEFAULT gen_random_uuid() NOT NULL,
    cost_centre_id uuid NOT NULL,
    dept_id uuid,
    branch_id uuid,
    pay_period character(7) NOT NULL,
    fiscal_year smallint NOT NULL,
    fiscal_month smallint NOT NULL,
    currency_code character(3) NOT NULL,
    gross_salary_budget numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    gross_salary_actual numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    net_salary_actual numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    allowances_total numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    deductions_total numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    employer_contrib numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    posting_status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    gl_account_code character varying(50),
    journal_ref character varying(50),
    posted_date date,
    posted_by character varying(200),
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    pay_period_id uuid,
    posted_by_user_id bigint,
    CONSTRAINT chk_acc_fiscal_month CHECK (((fiscal_month >= 1) AND (fiscal_month <= 12))),
    CONSTRAINT chk_acc_posting_status CHECK (((posting_status)::text = ANY ((ARRAY['draft'::character varying, 'pending'::character varying, 'posted'::character varying, 'reversed'::character varying])::text[])))
);


ALTER TABLE public.accounting_salary OWNER TO erp_user;

--
-- TOC entry 5751 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN accounting_salary.pay_period; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.accounting_salary.pay_period IS 'YYYY-MM label. Currently the calendar month: the 22-to-21 cycle is NOT yet in effect. Prefer joining pay_period_id once populated.';


--
-- TOC entry 5752 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN accounting_salary.gross_salary_budget; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.accounting_salary.gross_salary_budget IS 'Budgeted cost for the cost centre in this period, not an individual salary.';


--
-- TOC entry 5753 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN accounting_salary.gross_salary_actual; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.accounting_salary.gross_salary_actual IS 'Actual cost for the cost centre in this period. This table is aggregated by cost centre and has no employee_id.';


--
-- TOC entry 5754 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN accounting_salary.posted_by; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.accounting_salary.posted_by IS 'LEGACY. A display name, free text. Superseded by posted_by_user_id; kept for the original record. Do not join on it.';


--
-- TOC entry 5755 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN accounting_salary.pay_period_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.accounting_salary.pay_period_id IS 'Foreign key to pay_periods. Nullable during the cut-over: rows written before the backfill may have it unset, so a query that must not miss rows should fall back to the label column.';


--
-- TOC entry 5756 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN accounting_salary.posted_by_user_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.accounting_salary.posted_by_user_id IS 'The user who posted this to the GL. Joinable to users.id.';


--
-- TOC entry 269 (class 1259 OID 17185)
-- Name: app_config; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.app_config (
    id bigint NOT NULL,
    min_version character varying(20) NOT NULL,
    force_update boolean DEFAULT false NOT NULL,
    maintenance_mode boolean DEFAULT false NOT NULL,
    feature_flags jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint
);


ALTER TABLE public.app_config OWNER TO erp_user;

--
-- TOC entry 268 (class 1259 OID 17184)
-- Name: app_config_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.app_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_config_id_seq OWNER TO erp_user;

--
-- TOC entry 5757 (class 0 OID 0)
-- Dependencies: 268
-- Name: app_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.app_config_id_seq OWNED BY public.app_config.id;


--
-- TOC entry 292 (class 1259 OID 17665)
-- Name: appraisal_ratings; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.appraisal_ratings (
    rating_id uuid DEFAULT gen_random_uuid() NOT NULL,
    appraisal_id uuid NOT NULL,
    item_type character varying(20) NOT NULL,
    item_id uuid NOT NULL,
    weight_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    self_rating numeric(5,2),
    manager_rating numeric(5,2),
    self_comment text,
    manager_comment text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_rating_item_type CHECK (((item_type)::text = ANY ((ARRAY['kpi'::character varying, 'goal'::character varying, 'competency'::character varying])::text[]))),
    CONSTRAINT chk_rating_weight CHECK (((weight_pct >= (0)::numeric) AND (weight_pct <= (100)::numeric)))
);


ALTER TABLE public.appraisal_ratings OWNER TO erp_user;

--
-- TOC entry 291 (class 1259 OID 17646)
-- Name: appraisals; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.appraisals (
    appraisal_id uuid DEFAULT gen_random_uuid() NOT NULL,
    cycle_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    reviewer_emp_id uuid,
    self_score numeric(5,2),
    manager_score numeric(5,2),
    final_score numeric(5,2),
    status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    self_submitted_at timestamp(0) with time zone,
    manager_submitted_at timestamp(0) with time zone,
    acknowledged_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_appraisal_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'self_in_progress'::character varying, 'self_submitted'::character varying, 'manager_in_progress'::character varying, 'manager_submitted'::character varying, 'finalised'::character varying, 'acknowledged'::character varying, 'calibrated'::character varying])::text[])))
);


ALTER TABLE public.appraisals OWNER TO erp_user;

--
-- TOC entry 254 (class 1259 OID 17003)
-- Name: approval_chain_config; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.approval_chain_config (
    chain_id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_type character varying(30) NOT NULL,
    step_number smallint NOT NULL,
    approver_role character varying(50) NOT NULL,
    conditional_threshold numeric(15,2),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    approver_resolver character varying(50),
    CONSTRAINT chk_chain_approver_resolver CHECK (((approver_resolver IS NULL) OR ((approver_resolver)::text = 'department_team_leader'::text))),
    CONSTRAINT chk_chain_request_type CHECK (((request_type)::text = ANY ((ARRAY['transfer'::character varying, 'promotion'::character varying, 'termination'::character varying, 'salary_change'::character varying, 'general'::character varying, 'leave_request'::character varying, 'overtime_request'::character varying, 'phase_gate_review'::character varying, 'project_change_request'::character varying, 'timesheet'::character varying, 'expense'::character varying, 'phase_gate_change'::character varying, 'billing_milestone'::character varying, 'gate_pass'::character varying, 'goal_signoff'::character varying, 'service_request'::character varying, 'recruitment_requisition'::character varying, 'recruitment_offer'::character varying, 'talent_promotion_case'::character varying, 'payroll_gap_request'::character varying, 'shift_change'::character varying])::text[])))
);


ALTER TABLE public.approval_chain_config OWNER TO erp_user;

--
-- TOC entry 255 (class 1259 OID 17010)
-- Name: approval_requests; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.approval_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_type character varying(30) NOT NULL,
    target_id uuid,
    current_step smallint DEFAULT '1'::smallint NOT NULL,
    total_steps smallint DEFAULT '1'::smallint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    context_data jsonb,
    requested_by bigint NOT NULL,
    requested_at timestamp(0) with time zone NOT NULL,
    completed_at timestamp(0) with time zone,
    notes text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_approval_request_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'returned'::character varying])::text[]))),
    CONSTRAINT chk_approval_request_type CHECK (((request_type)::text = ANY ((ARRAY['transfer'::character varying, 'promotion'::character varying, 'termination'::character varying, 'salary_change'::character varying, 'general'::character varying, 'leave_request'::character varying, 'overtime_request'::character varying, 'phase_gate_review'::character varying, 'project_change_request'::character varying, 'timesheet'::character varying, 'expense'::character varying, 'phase_gate_change'::character varying, 'billing_milestone'::character varying, 'gate_pass'::character varying, 'goal_signoff'::character varying, 'service_request'::character varying, 'recruitment_requisition'::character varying, 'recruitment_offer'::character varying, 'talent_promotion_case'::character varying, 'payroll_gap_request'::character varying, 'shift_change'::character varying])::text[])))
);


ALTER TABLE public.approval_requests OWNER TO erp_user;

--
-- TOC entry 256 (class 1259 OID 17021)
-- Name: approval_steps; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.approval_steps (
    step_id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_id uuid NOT NULL,
    step_number smallint NOT NULL,
    approver_role character varying(50),
    approver_emp_id uuid,
    approver_user_id bigint,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    decision_date timestamp(0) with time zone,
    decision_notes text,
    delegated_to bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_approval_step_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'returned'::character varying, 'delegated'::character varying, 'skipped'::character varying])::text[])))
);


ALTER TABLE public.approval_steps OWNER TO erp_user;

--
-- TOC entry 280 (class 1259 OID 17426)
-- Name: attendance_records; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.attendance_records (
    record_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    attendance_date date NOT NULL,
    shift_id uuid,
    clock_in_at timestamp(0) with time zone,
    clock_out_at timestamp(0) with time zone,
    clock_in_source character varying(20) DEFAULT 'web'::character varying NOT NULL,
    clock_out_source character varying(20),
    clock_in_location jsonb,
    clock_out_location jsonb,
    late_minutes smallint DEFAULT '0'::smallint NOT NULL,
    early_departure_minutes smallint DEFAULT '0'::smallint NOT NULL,
    hours_worked numeric(4,2) DEFAULT '0'::numeric NOT NULL,
    overtime_minutes smallint DEFAULT '0'::smallint NOT NULL,
    notes text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_clock_in_source CHECK (((clock_in_source)::text = ANY ((ARRAY['web'::character varying, 'mobile'::character varying, 'kiosk'::character varying, 'device'::character varying, 'manual'::character varying])::text[]))),
    CONSTRAINT chk_clock_out_source CHECK (((clock_out_source IS NULL) OR ((clock_out_source)::text = ANY ((ARRAY['web'::character varying, 'mobile'::character varying, 'kiosk'::character varying, 'device'::character varying, 'manual'::character varying])::text[]))))
);


ALTER TABLE public.attendance_records OWNER TO erp_user;

--
-- TOC entry 281 (class 1259 OID 17455)
-- Name: attendance_summaries; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.attendance_summaries (
    summary_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    year smallint NOT NULL,
    month smallint NOT NULL,
    working_days_in_month smallint DEFAULT '0'::smallint NOT NULL,
    days_present smallint DEFAULT '0'::smallint NOT NULL,
    days_absent smallint DEFAULT '0'::smallint NOT NULL,
    days_on_leave smallint DEFAULT '0'::smallint NOT NULL,
    total_hours_worked numeric(6,2) DEFAULT '0'::numeric NOT NULL,
    total_late_minutes integer DEFAULT 0 NOT NULL,
    total_overtime_minutes integer DEFAULT 0 NOT NULL,
    total_early_departure_minutes integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    pay_period_id uuid
);


ALTER TABLE public.attendance_summaries OWNER TO erp_user;

--
-- TOC entry 5758 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.year; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.year IS 'Calendar year. This table is keyed by (year, month), not by pay period - see pay_period_id.';


--
-- TOC entry 5759 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.month; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.month IS 'Calendar month 1-12.';


--
-- TOC entry 5760 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.working_days_in_month; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.working_days_in_month IS 'Scheduled working days, from the working-day calendar. The denominator for attendance rates.';


--
-- TOC entry 5761 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.days_present; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.days_present IS 'Days with an attendance record. Does not imply a full day was worked.';


--
-- TOC entry 5762 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.days_absent; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.days_absent IS 'Days with no attendance record and no approved leave. Unauthorised absence.';


--
-- TOC entry 5763 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.days_on_leave; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.days_on_leave IS 'Days covered by approved leave. Counted separately from days_absent - conflating the two overstates absence.';


--
-- TOC entry 5764 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.total_late_minutes; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.total_late_minutes IS 'Raw lateness in minutes, before any grace period or excuse is applied.';


--
-- TOC entry 5765 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.total_overtime_minutes; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.total_overtime_minutes IS 'Minutes beyond the shift, before approval.';


--
-- TOC entry 5766 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.total_early_departure_minutes; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.total_early_departure_minutes IS 'Raw early-leave minutes, before any excuse is applied.';


--
-- TOC entry 5767 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN attendance_summaries.pay_period_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.attendance_summaries.pay_period_id IS 'Foreign key to pay_periods. Nullable during the cut-over: rows written before the backfill may have it unset, so a query that must not miss rows should fall back to the label column.';


--
-- TOC entry 235 (class 1259 OID 16529)
-- Name: branch_departments; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.branch_departments (
    dept_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    parent_dept_id uuid,
    dept_code character varying(20) NOT NULL,
    dept_name character varying(200) NOT NULL,
    dept_name_local character varying(200),
    dept_type character varying(30) NOT NULL,
    manager_emp_id uuid,
    cost_centre_id uuid,
    headcount_budget integer DEFAULT 0 NOT NULL,
    headcount_filled integer DEFAULT 0 NOT NULL,
    effective_date date,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_dept_headcount_budget CHECK ((headcount_budget >= 0)),
    CONSTRAINT chk_dept_headcount_filled CHECK ((headcount_filled >= 0)),
    CONSTRAINT chk_dept_type CHECK (((dept_type)::text = ANY ((ARRAY['operational'::character varying, 'administrative'::character varying, 'support'::character varying, 'technical'::character varying, 'management'::character varying])::text[])))
);


ALTER TABLE public.branch_departments OWNER TO erp_user;

--
-- TOC entry 221 (class 1259 OID 16414)
-- Name: cache; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration bigint NOT NULL
);


ALTER TABLE public.cache OWNER TO erp_user;

--
-- TOC entry 222 (class 1259 OID 16422)
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration bigint NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO erp_user;

--
-- TOC entry 296 (class 1259 OID 17736)
-- Name: calibration_entries; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.calibration_entries (
    entry_id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    original_rating numeric(5,2),
    calibrated_rating numeric(5,2),
    performance_axis numeric(5,2),
    potential_axis numeric(5,2),
    box_position smallint,
    notes text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_box_position CHECK (((box_position IS NULL) OR ((box_position >= 1) AND (box_position <= 9))))
);


ALTER TABLE public.calibration_entries OWNER TO erp_user;

--
-- TOC entry 295 (class 1259 OID 17718)
-- Name: calibration_sessions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.calibration_sessions (
    session_id uuid DEFAULT gen_random_uuid() NOT NULL,
    cycle_id uuid NOT NULL,
    scope character varying(20) DEFAULT 'dept'::character varying NOT NULL,
    scope_id uuid,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    facilitator_emp_id uuid,
    finalised_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_calibration_scope CHECK (((scope)::text = ANY ((ARRAY['all'::character varying, 'dept'::character varying, 'grade'::character varying])::text[]))),
    CONSTRAINT chk_calibration_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'in_progress'::character varying, 'finalised'::character varying])::text[])))
);


ALTER TABLE public.calibration_sessions OWNER TO erp_user;

--
-- TOC entry 369 (class 1259 OID 19447)
-- Name: cd_grievance_evidence; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cd_grievance_evidence (
    evidence_id uuid DEFAULT gen_random_uuid() NOT NULL,
    grievance_id uuid NOT NULL,
    kind character varying(20) NOT NULL,
    description text NOT NULL,
    attachment_path character varying(500),
    witness_employee_id uuid,
    submitted_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_cd_grievance_evidence_kind CHECK (((kind)::text = ANY ((ARRAY['document'::character varying, 'witness'::character varying, 'note'::character varying])::text[])))
);


ALTER TABLE public.cd_grievance_evidence OWNER TO erp_user;

--
-- TOC entry 368 (class 1259 OID 19331)
-- Name: cd_grievances; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cd_grievances (
    grievance_id uuid DEFAULT gen_random_uuid() NOT NULL,
    grievance_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    subject_type character varying(20) NOT NULL,
    subject_id uuid,
    notified_on date NOT NULL,
    filed_on date NOT NULL,
    reason text NOT NULL,
    status character varying(20) DEFAULT 'filed'::character varying NOT NULL,
    committee jsonb,
    committee_formed_on date,
    decision_due_on date NOT NULL,
    decision character varying(20),
    decision_reasons text,
    decided_on date,
    decided_within_sla boolean,
    remedy jsonb,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_cd_grievances_decision CHECK (((decision IS NULL) OR ((decision)::text = ANY ((ARRAY['uphold'::character varying, 'amend'::character varying, 'overturn'::character varying])::text[])))),
    CONSTRAINT chk_cd_grievances_status CHECK (((status)::text = ANY ((ARRAY['filed'::character varying, 'committee_formed'::character varying, 'decided'::character varying])::text[]))),
    CONSTRAINT chk_cd_grievances_subject_id CHECK (((((subject_type)::text = 'decision'::text) AND (subject_id IS NULL)) OR (((subject_type)::text <> 'decision'::text) AND (subject_id IS NOT NULL)))),
    CONSTRAINT chk_cd_grievances_subject_type CHECK (((subject_type)::text = ANY ((ARRAY['penalty'::character varying, 'demotion'::character varying, 'decision'::character varying])::text[])))
);


ALTER TABLE public.cd_grievances OWNER TO erp_user;

--
-- TOC entry 366 (class 1259 OID 19246)
-- Name: cd_penalties; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cd_penalties (
    penalty_id uuid DEFAULT gen_random_uuid() NOT NULL,
    penalty_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    violation_type_id uuid NOT NULL,
    occurred_on date NOT NULL,
    occurrence_in_period integer DEFAULT 1 NOT NULL,
    penalty_kind character varying(30) DEFAULT 'warning'::character varying NOT NULL,
    deduction_days numeric(5,2),
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    raised_source character varying(20) DEFAULT 'engine'::character varying NOT NULL,
    period character varying(7) NOT NULL,
    pay_period_id uuid,
    note text,
    investigation_notes text,
    investigation_attachment_path character varying(500),
    waived_reason text,
    appeal_decision character varying(20),
    appeal_reason text,
    applied_at timestamp(0) with time zone,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_cd_penalties_appeal_decision CHECK (((appeal_decision IS NULL) OR ((appeal_decision)::text = ANY ((ARRAY['uphold'::character varying, 'amend'::character varying, 'overturn'::character varying])::text[])))),
    CONSTRAINT chk_cd_penalties_penalty_kind CHECK (((penalty_kind)::text = ANY ((ARRAY['warning'::character varying, 'day_deduction'::character varying, 'increment_denial'::character varying, 'increment_postponement'::character varying, 'wage_reduction'::character varying, 'grade_reduction'::character varying, 'dismissal'::character varying, 'escalates_to'::character varying])::text[]))),
    CONSTRAINT chk_cd_penalties_raised_source CHECK (((raised_source)::text = ANY ((ARRAY['engine'::character varying, 'team_leader'::character varying])::text[]))),
    CONSTRAINT chk_cd_penalties_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'investigating'::character varying, 'applied'::character varying, 'waived'::character varying, 'appealed'::character varying])::text[])))
);


ALTER TABLE public.cd_penalties OWNER TO erp_user;

--
-- TOC entry 357 (class 1259 OID 19098)
-- Name: cd_violation_types; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cd_violation_types (
    violation_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    category character varying(20) NOT NULL,
    name_ar character varying(200) NOT NULL,
    name_en character varying(200) NOT NULL,
    occurrence_rules jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_cd_violation_types_category CHECK (((category)::text = ANY ((ARRAY['timing'::character varying, 'work_system'::character varying, 'conduct'::character varying])::text[])))
);


ALTER TABLE public.cd_violation_types OWNER TO erp_user;

--
-- TOC entry 308 (class 1259 OID 17967)
-- Name: certifications; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.certifications (
    cert_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    course_id uuid NOT NULL,
    cert_name character varying(200) NOT NULL,
    cert_name_local character varying(200),
    issuing_body character varying(200),
    obtained_date date NOT NULL,
    expiry_date date,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    certificate_url character varying(500),
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_certification_status CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'expiring_soon'::character varying, 'expired'::character varying, 'revoked'::character varying])::text[])))
);


ALTER TABLE public.certifications OWNER TO erp_user;

--
-- TOC entry 226 (class 1259 OID 16449)
-- Name: company_integrations; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.company_integrations (
    id bigint NOT NULL,
    company_profile_id bigint NOT NULL,
    integration_type character varying(30) NOT NULL,
    is_connected boolean DEFAULT false NOT NULL,
    connected_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_integration_type CHECK (((integration_type)::text = ANY ((ARRAY['stripe'::character varying, 'quickbooks'::character varying, 'gusto'::character varying, 'github'::character varying, 'notion'::character varying, 'slack'::character varying])::text[])))
);


ALTER TABLE public.company_integrations OWNER TO erp_user;

--
-- TOC entry 225 (class 1259 OID 16448)
-- Name: company_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.company_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.company_integrations_id_seq OWNER TO erp_user;

--
-- TOC entry 5768 (class 0 OID 0)
-- Dependencies: 225
-- Name: company_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.company_integrations_id_seq OWNED BY public.company_integrations.id;


--
-- TOC entry 224 (class 1259 OID 16431)
-- Name: company_profiles; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.company_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    company_name character varying(200) NOT NULL,
    industry character varying(30),
    current_stage character varying(20),
    team_size character varying(20),
    onboarding_step smallint DEFAULT '1'::smallint NOT NULL,
    onboarding_completed_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    website character varying(255),
    CONSTRAINT chk_company_industry CHECK (((industry)::text = ANY ((ARRAY['saas'::character varying, 'marketplace'::character varying, 'fintech'::character varying, 'e_commerce'::character varying, 'healthtech'::character varying, 'edtech'::character varying, 'ai_ml'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT chk_company_stage CHECK (((current_stage)::text = ANY ((ARRAY['idea'::character varying, 'pre_seed'::character varying, 'seed'::character varying, 'series_a'::character varying, 'series_b'::character varying, 'growth'::character varying, 'established'::character varying])::text[]))),
    CONSTRAINT chk_company_team_size CHECK (((team_size)::text = ANY ((ARRAY['solo'::character varying, 'small'::character varying, 'growing'::character varying, 'established'::character varying, 'scaling'::character varying])::text[])))
);


ALTER TABLE public.company_profiles OWNER TO erp_user;

--
-- TOC entry 223 (class 1259 OID 16430)
-- Name: company_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.company_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.company_profiles_id_seq OWNER TO erp_user;

--
-- TOC entry 5769 (class 0 OID 0)
-- Dependencies: 223
-- Name: company_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.company_profiles_id_seq OWNED BY public.company_profiles.id;


--
-- TOC entry 290 (class 1259 OID 17635)
-- Name: competencies; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.competencies (
    competency_id uuid DEFAULT gen_random_uuid() NOT NULL,
    competency_name character varying(200) NOT NULL,
    competency_name_local character varying(200),
    grade_scope uuid,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.competencies OWNER TO erp_user;

--
-- TOC entry 347 (class 1259 OID 18742)
-- Name: compliance_frameworks; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.compliance_frameworks (
    framework_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    label character varying(120) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.compliance_frameworks OWNER TO erp_user;

--
-- TOC entry 345 (class 1259 OID 18698)
-- Name: compliance_policies; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.compliance_policies (
    policy_id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(250) NOT NULL,
    category character varying(100) NOT NULL,
    version character varying(20) DEFAULT '1.0'::character varying NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    summary text,
    owner_employee_id uuid,
    review_date date,
    required_acknowledgements integer DEFAULT 0 NOT NULL,
    created_by bigint,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_compliance_policy_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'under_review'::character varying, 'active'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE public.compliance_policies OWNER TO erp_user;

--
-- TOC entry 346 (class 1259 OID 18723)
-- Name: compliance_policy_acknowledgements; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.compliance_policy_acknowledgements (
    acknowledgement_id uuid DEFAULT gen_random_uuid() NOT NULL,
    policy_id uuid NOT NULL,
    user_id bigint NOT NULL,
    acknowledged_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address character varying(45),
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.compliance_policy_acknowledgements OWNER TO erp_user;

--
-- TOC entry 348 (class 1259 OID 18751)
-- Name: compliance_rules; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.compliance_rules (
    rule_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    title character varying(250) NOT NULL,
    description text,
    severity character varying(20) DEFAULT 'info'::character varying NOT NULL,
    framework_id uuid,
    status character varying(20) DEFAULT 'in_progress'::character varying NOT NULL,
    owner_employee_id uuid,
    due_date date,
    tags jsonb DEFAULT '[]'::jsonb NOT NULL,
    evidence text,
    created_by bigint,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_compliance_rule_severity CHECK (((severity)::text = ANY ((ARRAY['critical'::character varying, 'warning'::character varying, 'info'::character varying])::text[]))),
    CONSTRAINT chk_compliance_rule_status CHECK (((status)::text = ANY ((ARRAY['compliant'::character varying, 'in_progress'::character varying, 'non_compliant'::character varying])::text[])))
);


ALTER TABLE public.compliance_rules OWNER TO erp_user;

--
-- TOC entry 236 (class 1259 OID 16558)
-- Name: cost_centers; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cost_centers (
    cost_centre_id uuid DEFAULT gen_random_uuid() NOT NULL,
    parent_cc_id uuid,
    branch_id uuid,
    dept_id uuid,
    cc_code character varying(20) NOT NULL,
    cc_name character varying(200) NOT NULL,
    cc_name_local character varying(200),
    cc_type character varying(30) NOT NULL,
    account_code character varying(50),
    currency_code character(3) NOT NULL,
    budget_amount numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    fiscal_year smallint NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_cc_budget_amount CHECK ((budget_amount >= (0)::numeric)),
    CONSTRAINT chk_cc_fiscal_year CHECK (((fiscal_year >= 2000) AND (fiscal_year <= 2100))),
    CONSTRAINT chk_cc_type CHECK (((cc_type)::text = ANY ((ARRAY['profit_centre'::character varying, 'cost_centre'::character varying, 'investment_centre'::character varying, 'revenue_centre'::character varying])::text[])))
);


ALTER TABLE public.cost_centers OWNER TO erp_user;

--
-- TOC entry 299 (class 1259 OID 17787)
-- Name: course_modules; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.course_modules (
    module_id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    sequence_order smallint NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    material_url character varying(500),
    duration_minutes integer,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.course_modules OWNER TO erp_user;

--
-- TOC entry 300 (class 1259 OID 17802)
-- Name: course_prerequisites; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.course_prerequisites (
    prereq_id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    prerequisite_course_id uuid NOT NULL,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.course_prerequisites OWNER TO erp_user;

--
-- TOC entry 289 (class 1259 OID 17616)
-- Name: cycle_participants; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.cycle_participants (
    participant_id uuid DEFAULT gen_random_uuid() NOT NULL,
    cycle_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    reviewer_emp_id uuid,
    phase_status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    self_done_at timestamp(0) with time zone,
    manager_done_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint,
    CONSTRAINT chk_participant_phase_status CHECK (((phase_status)::text = ANY ((ARRAY['pending'::character varying, 'self_in_progress'::character varying, 'self_done'::character varying, 'manager_in_progress'::character varying, 'manager_done'::character varying, 'calibrated'::character varying, 'finalised'::character varying])::text[])))
);


ALTER TABLE public.cycle_participants OWNER TO erp_user;

--
-- TOC entry 245 (class 1259 OID 16916)
-- Name: emergency_contacts; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.emergency_contacts (
    contact_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    full_name character varying(255) NOT NULL,
    full_name_local character varying(255),
    relationship character varying(100) NOT NULL,
    phone_primary character varying(30) NOT NULL,
    phone_secondary character varying(30),
    email character varying(255),
    address text,
    national_id character varying(50),
    is_primary boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.emergency_contacts OWNER TO erp_user;

--
-- TOC entry 270 (class 1259 OID 17206)
-- Name: employee_change_requests; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_change_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    field_name character varying(255) NOT NULL,
    old_value text,
    new_value text NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    requested_at timestamp(0) with time zone NOT NULL,
    decided_by integer,
    decided_at timestamp(0) with time zone,
    decision_note text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint,
    CONSTRAINT chk_change_request_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.employee_change_requests OWNER TO erp_user;

--
-- TOC entry 242 (class 1259 OID 16791)
-- Name: employee_contracts; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_contracts (
    contract_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    contract_number character varying(20) NOT NULL,
    contract_type character varying(30) NOT NULL,
    branch_id uuid,
    dept_id uuid,
    position_id uuid,
    job_grade_id uuid,
    start_date date NOT NULL,
    end_date date,
    is_open_ended boolean DEFAULT false NOT NULL,
    work_location character varying(255),
    work_schedule character varying(30),
    weekly_hours smallint,
    probation_days smallint,
    probation_end_date date,
    notice_period_days smallint,
    notice_period_unit character varying(10),
    renewal_type character varying(30),
    renewal_count smallint DEFAULT '0'::smallint NOT NULL,
    contract_status character varying(30) DEFAULT 'active'::character varying NOT NULL,
    special_conditions text,
    file_path text,
    is_current boolean DEFAULT true NOT NULL,
    approved_by bigint,
    approved_date date,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    parent_contract_id uuid,
    remote_terms jsonb,
    CONSTRAINT chk_contract_addendum_parent CHECK (((((contract_type)::text = 'remote_work_addendum'::text) AND (parent_contract_id IS NOT NULL)) OR (((contract_type)::text <> 'remote_work_addendum'::text) AND (parent_contract_id IS NULL)))),
    CONSTRAINT chk_contract_dates CHECK (((end_date IS NULL) OR (end_date > start_date))),
    CONSTRAINT chk_contract_status CHECK (((contract_status)::text = ANY ((ARRAY['draft'::character varying, 'active'::character varying, 'expired'::character varying, 'terminated'::character varying, 'renewed'::character varying, 'suspended'::character varying])::text[]))),
    CONSTRAINT chk_contract_type CHECK (((contract_type)::text = ANY ((ARRAY['permanent'::character varying, 'fixed_term'::character varying, 'temporary'::character varying, 'internship'::character varying, 'contract'::character varying, 'seasonal'::character varying, 'secondment'::character varying, 'remote_work_addendum'::character varying])::text[]))),
    CONSTRAINT chk_notice_period_unit CHECK (((notice_period_unit IS NULL) OR ((notice_period_unit)::text = ANY ((ARRAY['day'::character varying, 'week'::character varying, 'month'::character varying])::text[])))),
    CONSTRAINT chk_open_ended CHECK (((NOT is_open_ended) OR (end_date IS NULL))),
    CONSTRAINT chk_work_schedule CHECK (((work_schedule IS NULL) OR ((work_schedule)::text = ANY ((ARRAY['standard'::character varying, 'shift'::character varying, 'flexible'::character varying, 'remote'::character varying, 'hybrid'::character varying])::text[]))))
);


ALTER TABLE public.employee_contracts OWNER TO erp_user;

--
-- TOC entry 244 (class 1259 OID 16892)
-- Name: employee_documents; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_documents (
    document_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    document_type character varying(40) NOT NULL,
    document_category character varying(20) NOT NULL,
    document_title character varying(255) NOT NULL,
    document_number character varying(100),
    issuing_authority character varying(255),
    issuing_country character varying(2),
    issue_date date,
    expiry_date date,
    alert_days_before smallint DEFAULT '30'::smallint NOT NULL,
    file_path text,
    file_type character varying(20),
    file_size_kb integer,
    is_mandatory boolean DEFAULT false NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    verified_by bigint,
    verified_date timestamp(0) with time zone,
    verification_notes text,
    is_active boolean DEFAULT true NOT NULL,
    uploaded_at timestamp(0) with time zone,
    uploaded_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_document_category CHECK (((document_category)::text = ANY ((ARRAY['identity'::character varying, 'legal'::character varying, 'educational'::character varying, 'professional'::character varying, 'medical'::character varying, 'internal'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT chk_document_dates CHECK (((expiry_date IS NULL) OR (issue_date IS NULL) OR (expiry_date > issue_date))),
    CONSTRAINT chk_document_type CHECK (((document_type)::text = ANY ((ARRAY['degree'::character varying, 'passport'::character varying, 'degree_certificate'::character varying, 'professional_cert'::character varying, 'national_id'::character varying, 'birth_certificate'::character varying, 'work_permit'::character varying, 'visa'::character varying, 'iban_letter'::character varying, 'medical_certificate'::character varying, 'insurance_card'::character varying, 'background_check'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT chk_employee_documents_file_type CHECK (((file_type IS NULL) OR ((file_type)::text = ANY ((ARRAY['pdf'::character varying, 'jpg'::character varying, 'jpeg'::character varying, 'png'::character varying, 'docx'::character varying])::text[]))))
);


ALTER TABLE public.employee_documents OWNER TO erp_user;

--
-- TOC entry 313 (class 1259 OID 18054)
-- Name: employee_export_jobs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_export_jobs (
    export_job_id uuid DEFAULT gen_random_uuid() NOT NULL,
    requested_by bigint NOT NULL,
    format character varying(10) NOT NULL,
    scope character varying(20) NOT NULL,
    filename character varying(150) NOT NULL,
    status character varying(20) DEFAULT 'queued'::character varying NOT NULL,
    file_path character varying(255),
    error_message text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_export_job_format CHECK (((format)::text = ANY ((ARRAY['xlsx'::character varying, 'csv'::character varying, 'pdf'::character varying])::text[]))),
    CONSTRAINT chk_export_job_scope CHECK (((scope)::text = ANY ((ARRAY['all'::character varying, 'filtered'::character varying, 'selected'::character varying])::text[]))),
    CONSTRAINT chk_export_job_status CHECK (((status)::text = ANY ((ARRAY['queued'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.employee_export_jobs OWNER TO erp_user;

--
-- TOC entry 247 (class 1259 OID 16934)
-- Name: employee_history; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_history (
    history_id bigint NOT NULL,
    employee_id uuid,
    module_name character varying(30) NOT NULL,
    table_name character varying(100) NOT NULL,
    action_type character varying(30) NOT NULL,
    field_changed character varying(100),
    old_value text,
    new_value text,
    change_reason character varying(255),
    ip_address character varying(45),
    user_agent text,
    changed_by bigint,
    changed_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_history_action_type CHECK (((action_type)::text = ANY ((ARRAY['insert'::character varying, 'update'::character varying, 'delete'::character varying, 'approve'::character varying, 'reject'::character varying, 'login'::character varying, 'export'::character varying, 'status_change'::character varying, 'issue'::character varying, 'waive'::character varying, 'propose'::character varying, 'open_proposal'::character varying, 'dismiss'::character varying, 'settings_change'::character varying])::text[]))),
    CONSTRAINT chk_history_module_name CHECK (((module_name)::text = ANY ((ARRAY['hr'::character varying, 'payroll'::character varying, 'recruitment'::character varying, 'performance'::character varying, 'leave'::character varying, 'attendance'::character varying, 'training'::character varying, 'benefits'::character varying, 'system'::character varying, 'finance'::character varying, 'operations'::character varying, 'compliance'::character varying, 'settings'::character varying, 'integrations'::character varying, 'sales'::character varying, 'conduct'::character varying, 'assistant'::character varying])::text[])))
);


ALTER TABLE public.employee_history OWNER TO erp_user;

--
-- TOC entry 246 (class 1259 OID 16933)
-- Name: employee_history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.employee_history_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_history_history_id_seq OWNER TO erp_user;

--
-- TOC entry 5770 (class 0 OID 0)
-- Dependencies: 246
-- Name: employee_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.employee_history_history_id_seq OWNED BY public.employee_history.history_id;


--
-- TOC entry 253 (class 1259 OID 16982)
-- Name: employee_operations; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_operations (
    operation_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    operation_type character varying(20) NOT NULL,
    operation_status character varying(20) DEFAULT 'executed'::character varying NOT NULL,
    effective_date date NOT NULL,
    reason text,
    changes_applied jsonb,
    warnings jsonb,
    next_steps jsonb,
    final_settlement jsonb,
    origin_branch_id uuid,
    origin_dept_id uuid,
    origin_position_id uuid,
    origin_job_grade_id uuid,
    origin_cost_centre_id uuid,
    origin_manager_id uuid,
    target_branch_id uuid,
    target_dept_id uuid,
    target_position_id uuid,
    target_job_grade_id uuid,
    target_cost_centre_id uuid,
    target_manager_id uuid,
    termination_type character varying(30),
    termination_reason text,
    new_basic_salary numeric(15,2),
    executed_by bigint,
    executed_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    notice_period_served boolean,
    before_state jsonb,
    reversed_by bigint,
    reversed_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_op_termination_type CHECK (((termination_type IS NULL) OR ((termination_type)::text = ANY ((ARRAY['resignation'::character varying, 'termination'::character varying, 'retirement'::character varying, 'contract_end'::character varying, 'death'::character varying, 'redundancy'::character varying])::text[])))),
    CONSTRAINT chk_operation_status CHECK (((operation_status)::text = ANY ((ARRAY['preview'::character varying, 'executed'::character varying, 'failed'::character varying, 'reversed'::character varying])::text[]))),
    CONSTRAINT chk_operation_type CHECK (((operation_type)::text = ANY ((ARRAY['transfer'::character varying, 'promotion'::character varying, 'termination'::character varying, 'demotion'::character varying])::text[])))
);


ALTER TABLE public.employee_operations OWNER TO erp_user;

--
-- TOC entry 354 (class 1259 OID 18874)
-- Name: employee_purge_logs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_purge_logs (
    purge_log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    employee_number character varying(20) NOT NULL,
    employee_full_name character varying(255) NOT NULL,
    rows_deleted_summary text NOT NULL,
    rows_nulled_summary text NOT NULL,
    files_deleted_summary text NOT NULL,
    user_account_deleted boolean DEFAULT false NOT NULL,
    purged_by bigint,
    purged_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.employee_purge_logs OWNER TO erp_user;

--
-- TOC entry 311 (class 1259 OID 18018)
-- Name: employee_skills; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employee_skills (
    emp_skill_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    current_level smallint NOT NULL,
    target_level smallint,
    assessed_by uuid,
    assessed_at timestamp(0) with time zone,
    source character varying(20) DEFAULT 'self'::character varying NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_emp_skill_current_level CHECK (((current_level >= 1) AND (current_level <= 5))),
    CONSTRAINT chk_emp_skill_source CHECK (((source)::text = ANY ((ARRAY['self'::character varying, 'manager'::character varying, 'assessment'::character varying, 'certification'::character varying, 'training'::character varying])::text[]))),
    CONSTRAINT chk_emp_skill_target_level CHECK (((target_level IS NULL) OR ((target_level >= 1) AND (target_level <= 5))))
);


ALTER TABLE public.employee_skills OWNER TO erp_user;

--
-- TOC entry 241 (class 1259 OID 16727)
-- Name: employees; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.employees (
    employee_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_number character varying(20) NOT NULL,
    branch_id uuid,
    dept_id uuid,
    position_id uuid,
    job_grade_id uuid,
    manager_id uuid,
    cost_centre_id uuid,
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    last_name character varying(100) NOT NULL,
    first_name_local character varying(100),
    last_name_local character varying(100),
    national_id character varying(50),
    national_id_type character varying(20),
    passport_number character varying(50),
    passport_expiry date,
    date_of_birth date,
    place_of_birth character varying(100),
    gender character varying(10),
    marital_status character varying(20),
    nationality character varying(3),
    religion character varying(50),
    blood_type character varying(5),
    email_work character varying(200) NOT NULL,
    email_personal character varying(200),
    phone_work character varying(30),
    phone_mobile character varying(30),
    phone_home character varying(30),
    address_line1 character varying(200),
    address_line2 character varying(200),
    city character varying(100),
    state character varying(100),
    country character varying(3),
    postal_code character varying(20),
    employment_status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    employment_type character varying(20) NOT NULL,
    hire_date date NOT NULL,
    seniority_date date,
    confirmation_date date,
    termination_date date,
    termination_reason text,
    termination_type character varying(30),
    is_active boolean DEFAULT true NOT NULL,
    photo_path character varying(500),
    created_by bigint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    locale character varying(10),
    theme character varying(20),
    eligible_for_rehire boolean,
    CONSTRAINT chk_emp_blood CHECK (((blood_type IS NULL) OR ((blood_type)::text = ANY ((ARRAY['a+'::character varying, 'a-'::character varying, 'b+'::character varying, 'b-'::character varying, 'ab+'::character varying, 'ab-'::character varying, 'o+'::character varying, 'o-'::character varying])::text[])))),
    CONSTRAINT chk_emp_gender CHECK (((gender IS NULL) OR ((gender)::text = ANY ((ARRAY['male'::character varying, 'female'::character varying])::text[])))),
    CONSTRAINT chk_emp_hire_after_dob CHECK (((date_of_birth IS NULL) OR (hire_date > date_of_birth))),
    CONSTRAINT chk_emp_marital CHECK (((marital_status IS NULL) OR ((marital_status)::text = ANY ((ARRAY['single'::character varying, 'married'::character varying, 'divorced'::character varying, 'widowed'::character varying])::text[])))),
    CONSTRAINT chk_emp_nat_id_type CHECK (((national_id_type IS NULL) OR ((national_id_type)::text = ANY ((ARRAY['national_id'::character varying, 'passport'::character varying, 'iqama'::character varying, 'work_permit'::character varying, 'other'::character varying])::text[])))),
    CONSTRAINT chk_emp_status CHECK (((employment_status)::text = ANY ((ARRAY['active'::character varying, 'probation'::character varying, 'on_leave'::character varying, 'suspended'::character varying, 'terminated'::character varying, 'resigned'::character varying, 'retired'::character varying, 'inactive'::character varying])::text[]))),
    CONSTRAINT chk_emp_term_after_hire CHECK (((termination_date IS NULL) OR (termination_date >= hire_date))),
    CONSTRAINT chk_emp_term_type CHECK (((termination_type IS NULL) OR ((termination_type)::text = ANY ((ARRAY['resignation'::character varying, 'termination'::character varying, 'retirement'::character varying, 'contract_end'::character varying, 'death'::character varying, 'redundancy'::character varying])::text[])))),
    CONSTRAINT chk_emp_type CHECK (((employment_type)::text = ANY ((ARRAY['full_time'::character varying, 'part_time'::character varying, 'contract'::character varying, 'internship'::character varying, 'temporary'::character varying])::text[])))
);


ALTER TABLE public.employees OWNER TO erp_user;

--
-- TOC entry 5771 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.manager_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.manager_id IS 'The employee this person reports to. The direct-reports scope resolves through this column.';


--
-- TOC entry 5772 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.date_of_birth; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.date_of_birth IS 'Personal data. Identity tier: not readable by the general assistant role.';


--
-- TOC entry 5773 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.employment_status; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.employment_status IS 'Current state. resigned means the employee left by choice; terminated means the company ended it. The two are not interchangeable.';


--
-- TOC entry 5774 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.employment_type; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.employment_type IS 'Contract shape (full_time, part_time, contract, internship, temporary). Unrelated to employment_status.';


--
-- TOC entry 5775 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.hire_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.hire_date IS 'Date employment began at this company. Use for tenure and service-length questions.';


--
-- TOC entry 5776 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.seniority_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.seniority_date IS 'Date from which seniority accrues. Differs from hire_date after a rehire or an acquisition, and is the one leave entitlement is based on.';


--
-- TOC entry 5777 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.confirmation_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.confirmation_date IS 'Date probation ended and employment was confirmed. NULL means still on probation or never formally confirmed.';


--
-- TOC entry 5778 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN employees.termination_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.employees.termination_date IS 'Last day of employment. NULL for active employees. Set for resigned, terminated and retired alike, so it does not by itself say why.';


--
-- TOC entry 377 (class 1259 OID 19572)
-- Name: eo_demotion_cases; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.eo_demotion_cases (
    demotion_case_id uuid DEFAULT gen_random_uuid() NOT NULL,
    case_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    ground character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'open'::character varying NOT NULL,
    evidence text,
    evidence_refs jsonb DEFAULT '[]'::jsonb NOT NULL,
    notice_issued_on date,
    notice_reason text,
    improvement_days integer,
    improvement_ends_on date,
    committee jsonb,
    decision_outcome character varying(20),
    decision_reasons text,
    decided_on date,
    new_job_grade_id uuid,
    new_position_id uuid,
    new_basic_salary numeric(12,2),
    operation_id uuid,
    review_due_on date,
    review_completed_on date,
    review_outcome character varying(20),
    review_notes text,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_eo_demotion_cases_decision_outcome CHECK (((decision_outcome IS NULL) OR ((decision_outcome)::text = ANY ((ARRAY['demote'::character varying, 'dismiss_case'::character varying])::text[])))),
    CONSTRAINT chk_eo_demotion_cases_ground CHECK (((ground)::text = ANY ((ARRAY['poor_performance'::character varying, 'negligence'::character varying, 'misconduct'::character varying, 'restructuring'::character varying, 'employee_request'::character varying])::text[]))),
    CONSTRAINT chk_eo_demotion_cases_improvement_days CHECK (((improvement_days IS NULL) OR (improvement_days >= 0))),
    CONSTRAINT chk_eo_demotion_cases_review_outcome CHECK (((review_outcome IS NULL) OR ((review_outcome)::text = ANY ((ARRAY['improved'::character varying, 'sustained'::character varying, 'further_action'::character varying])::text[])))),
    CONSTRAINT chk_eo_demotion_cases_status CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'notice_issued'::character varying, 'demoted'::character varying, 'dismissed'::character varying, 'closed'::character varying, 'overturned'::character varying])::text[])))
);


ALTER TABLE public.eo_demotion_cases OWNER TO erp_user;

--
-- TOC entry 344 (class 1259 OID 18546)
-- Name: eo_settlement_access_log; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.eo_settlement_access_log (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    settlement_id uuid NOT NULL,
    accessed_by bigint NOT NULL,
    action character varying(15) NOT NULL,
    ip character varying(45),
    accessed_at timestamp(0) with time zone NOT NULL,
    CONSTRAINT chk_eo_settlement_access_log_action CHECK (((action)::text = ANY ((ARRAY['viewed'::character varying, 'downloaded'::character varying])::text[])))
);


ALTER TABLE public.eo_settlement_access_log OWNER TO erp_user;

--
-- TOC entry 341 (class 1259 OID 18523)
-- Name: eo_settlement_documents; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.eo_settlement_documents (
    settlement_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    pdf_path character varying(255),
    gratuity numeric(12,2),
    unused_leave numeric(12,2),
    pro_rata_salary numeric(12,2),
    total numeric(12,2),
    generated_at timestamp(0) with time zone NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.eo_settlement_documents OWNER TO erp_user;

--
-- TOC entry 231 (class 1259 OID 16482)
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO erp_user;

--
-- TOC entry 230 (class 1259 OID 16481)
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO erp_user;

--
-- TOC entry 5779 (class 0 OID 0)
-- Dependencies: 230
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- TOC entry 293 (class 1259 OID 17683)
-- Name: feedback_requests; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.feedback_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL,
    cycle_id uuid NOT NULL,
    subject_emp_id uuid NOT NULL,
    rater_emp_id uuid NOT NULL,
    relationship character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'sent'::character varying NOT NULL,
    sent_at timestamp(0) with time zone,
    responded_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint,
    CONSTRAINT chk_feedback_relationship CHECK (((relationship)::text = ANY ((ARRAY['peer'::character varying, 'subordinate'::character varying, 'manager'::character varying, 'self'::character varying, 'external'::character varying])::text[]))),
    CONSTRAINT chk_feedback_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'sent'::character varying, 'responded'::character varying, 'declined'::character varying, 'expired'::character varying])::text[])))
);


ALTER TABLE public.feedback_requests OWNER TO erp_user;

--
-- TOC entry 294 (class 1259 OID 17701)
-- Name: feedback_responses; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.feedback_responses (
    response_id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_id uuid NOT NULL,
    ratings_json jsonb,
    strengths text,
    improvements text,
    is_anonymous boolean DEFAULT false NOT NULL,
    submitted_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.feedback_responses OWNER TO erp_user;

--
-- TOC entry 287 (class 1259 OID 17584)
-- Name: goal_checkins; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.goal_checkins (
    checkin_id uuid DEFAULT gen_random_uuid() NOT NULL,
    goal_id uuid NOT NULL,
    progress_pct numeric(5,2) NOT NULL,
    comment text,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_checkin_progress CHECK (((progress_pct >= (0)::numeric) AND (progress_pct <= (100)::numeric)))
);


ALTER TABLE public.goal_checkins OWNER TO erp_user;

--
-- TOC entry 285 (class 1259 OID 17537)
-- Name: goals; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.goals (
    goal_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    title_local character varying(255),
    description text,
    goal_type character varying(20) NOT NULL,
    category character varying(50),
    weight_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    parent_goal_id uuid,
    cycle_id uuid,
    start_date date NOT NULL,
    due_date date NOT NULL,
    progress_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    approval_request_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_goal_progress CHECK (((progress_pct >= (0)::numeric) AND (progress_pct <= (100)::numeric))),
    CONSTRAINT chk_goal_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'submitted'::character varying, 'approved'::character varying, 'active'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT chk_goal_type CHECK (((goal_type)::text = ANY ((ARRAY['smart'::character varying, 'okr'::character varying])::text[]))),
    CONSTRAINT chk_goal_weight CHECK (((weight_pct >= (0)::numeric) AND (weight_pct <= (100)::numeric)))
);


ALTER TABLE public.goals OWNER TO erp_user;

--
-- TOC entry 297 (class 1259 OID 17752)
-- Name: improvement_plans; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.improvement_plans (
    pip_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    cycle_id uuid,
    reason text NOT NULL,
    objectives_json jsonb,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    manager_emp_id uuid,
    hr_emp_id uuid,
    outcome text,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_pip_dates CHECK ((end_date > start_date)),
    CONSTRAINT chk_pip_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'active'::character varying, 'monitoring'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.improvement_plans OWNER TO erp_user;

--
-- TOC entry 265 (class 1259 OID 17135)
-- Name: integration_sync_log; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.integration_sync_log (
    log_id bigint NOT NULL,
    integration_name character varying(50) NOT NULL,
    event_type character varying(100) NOT NULL,
    status character varying(20) NOT NULL,
    related_module character varying(100),
    payload_summary text,
    error_message text,
    retry_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_integration_sync_log_event_type CHECK (((event_type)::text = ANY ((ARRAY['payroll_setup'::character varying, 'payroll_final'::character varying, 'it_provisioning'::character varying, 'it_revoke'::character varying, 'finance_gl_post'::character varying, 'offer_accepted'::character varying, 'employee.created'::character varying, 'employee.terminated'::character varying, 'salary.changed'::character varying, 'cost_posted'::character varying, 'sync'::character varying])::text[]))),
    CONSTRAINT chk_isl_integration_name CHECK (((integration_name)::text = ANY ((ARRAY['payroll'::character varying, 'recruitment'::character varying, 'finance'::character varying, 'notifications'::character varying, 'it_provisioning'::character varying])::text[]))),
    CONSTRAINT chk_isl_status CHECK (((status)::text = ANY ((ARRAY['success'::character varying, 'failed'::character varying, 'retrying'::character varying, 'blocked'::character varying])::text[])))
);


ALTER TABLE public.integration_sync_log OWNER TO erp_user;

--
-- TOC entry 264 (class 1259 OID 17134)
-- Name: integration_sync_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.integration_sync_log_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.integration_sync_log_log_id_seq OWNER TO erp_user;

--
-- TOC entry 5780 (class 0 OID 0)
-- Dependencies: 264
-- Name: integration_sync_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.integration_sync_log_log_id_seq OWNED BY public.integration_sync_log.log_id;


--
-- TOC entry 229 (class 1259 OID 16474)
-- Name: job_batches; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO erp_user;

--
-- TOC entry 239 (class 1259 OID 16653)
-- Name: job_catalog; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.job_catalog (
    job_id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_grade_id uuid,
    job_code character varying(30) NOT NULL,
    job_title character varying(200) NOT NULL,
    job_title_local character varying(200),
    job_family character varying(100),
    job_subfamily character varying(100),
    job_level character varying(20) NOT NULL,
    job_category character varying(20) NOT NULL,
    job_description text,
    qualifications_required text,
    skills_required text,
    min_experience_years smallint DEFAULT '0'::smallint NOT NULL,
    requires_approval boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_internal boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_job_category CHECK (((job_category)::text = ANY ((ARRAY['full_time'::character varying, 'part_time'::character varying, 'contract'::character varying, 'internship'::character varying, 'temporary'::character varying])::text[]))),
    CONSTRAINT chk_job_experience CHECK ((min_experience_years >= 0)),
    CONSTRAINT chk_job_level CHECK (((job_level)::text = ANY ((ARRAY['entry'::character varying, 'junior'::character varying, 'mid'::character varying, 'senior'::character varying, 'lead'::character varying, 'principal'::character varying, 'manager'::character varying, 'director'::character varying, 'vp'::character varying, 'c_level'::character varying])::text[])))
);


ALTER TABLE public.job_catalog OWNER TO erp_user;

--
-- TOC entry 238 (class 1259 OID 16629)
-- Name: job_grades; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.job_grades (
    job_grade_id uuid DEFAULT gen_random_uuid() NOT NULL,
    grade_code character varying(20) NOT NULL,
    grade_name character varying(200) NOT NULL,
    grade_name_local character varying(200),
    grade_level smallint NOT NULL,
    grade_category character varying(30) NOT NULL,
    min_salary numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    mid_salary numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    max_salary numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    currency_code character(3) NOT NULL,
    description text,
    overtime_eligible boolean DEFAULT false NOT NULL,
    annual_leave_days smallint DEFAULT '0'::smallint NOT NULL,
    sick_leave_days smallint DEFAULT '0'::smallint NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_grade_category CHECK (((grade_category)::text = ANY ((ARRAY['executive'::character varying, 'management'::character varying, 'professional'::character varying, 'technical'::character varying, 'administrative'::character varying, 'operational'::character varying])::text[]))),
    CONSTRAINT chk_grade_leave_days CHECK (((annual_leave_days >= 0) AND (sick_leave_days >= 0))),
    CONSTRAINT chk_grade_level CHECK ((grade_level >= 1)),
    CONSTRAINT chk_grade_salary_band CHECK (((min_salary >= (0)::numeric) AND (mid_salary >= min_salary) AND (max_salary >= mid_salary)))
);


ALTER TABLE public.job_grades OWNER TO erp_user;

--
-- TOC entry 228 (class 1259 OID 16465)
-- Name: jobs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO erp_user;

--
-- TOC entry 227 (class 1259 OID 16464)
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO erp_user;

--
-- TOC entry 5781 (class 0 OID 0)
-- Dependencies: 227
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- TOC entry 286 (class 1259 OID 17563)
-- Name: key_results; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.key_results (
    kr_id uuid DEFAULT gen_random_uuid() NOT NULL,
    goal_id uuid NOT NULL,
    description character varying(500) NOT NULL,
    metric_type character varying(20) NOT NULL,
    currency_code character(3) DEFAULT 'EGP'::bpchar NOT NULL,
    start_value numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    target_value numeric(15,2) NOT NULL,
    current_value numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    progress_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint,
    CONSTRAINT chk_kr_metric_type CHECK (((metric_type)::text = ANY ((ARRAY['number'::character varying, 'percentage'::character varying, 'currency'::character varying, 'boolean'::character varying])::text[]))),
    CONSTRAINT chk_kr_progress CHECK (((progress_pct >= (0)::numeric) AND (progress_pct <= (100)::numeric)))
);


ALTER TABLE public.key_results OWNER TO erp_user;

--
-- TOC entry 284 (class 1259 OID 17516)
-- Name: kpi_assignments; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.kpi_assignments (
    assignment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    kpi_id uuid NOT NULL,
    assignee_type character varying(20) NOT NULL,
    assignee_id uuid NOT NULL,
    cycle_id uuid,
    weight_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    target_value numeric(15,2),
    currency_code character(3) DEFAULT 'EGP'::bpchar NOT NULL,
    threshold_min numeric(15,2),
    threshold_max numeric(15,2),
    period character varying(7),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    pay_period_id uuid,
    CONSTRAINT chk_kpi_assignee_type CHECK (((assignee_type)::text = ANY ((ARRAY['employee'::character varying, 'role'::character varying, 'dept'::character varying])::text[]))),
    CONSTRAINT chk_kpi_assignment_status CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'archived'::character varying])::text[]))),
    CONSTRAINT chk_kpi_weight_pct CHECK (((weight_pct >= (0)::numeric) AND (weight_pct <= (100)::numeric)))
);


ALTER TABLE public.kpi_assignments OWNER TO erp_user;

--
-- TOC entry 5782 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN kpi_assignments.period; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.kpi_assignments.period IS 'YYYY-MM label. Currently the calendar month: the 22-to-21 pay cycle is NOT yet in effect, so period questions must not assume it. pay_period_id is the joinable equivalent and is authoritative once populated.';


--
-- TOC entry 5783 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN kpi_assignments.pay_period_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.kpi_assignments.pay_period_id IS 'Foreign key to pay_periods. Nullable during the cut-over: rows written before the backfill may have it unset, so a query that must not miss rows should fall back to the label column.';


--
-- TOC entry 283 (class 1259 OID 17501)
-- Name: kpi_library; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.kpi_library (
    kpi_id uuid DEFAULT gen_random_uuid() NOT NULL,
    kpi_code character varying(30) NOT NULL,
    kpi_name character varying(200) NOT NULL,
    kpi_name_local character varying(200) NOT NULL,
    category character varying(50) NOT NULL,
    unit character varying(50),
    direction character varying(20) NOT NULL,
    measurement_type character varying(20) NOT NULL,
    formula text,
    data_source character varying(100),
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_kpi_direction CHECK (((direction)::text = ANY ((ARRAY['higher_better'::character varying, 'lower_better'::character varying, 'exact'::character varying])::text[]))),
    CONSTRAINT chk_kpi_measurement_type CHECK (((measurement_type)::text = ANY ((ARRAY['number'::character varying, 'percentage'::character varying, 'currency'::character varying, 'ratio'::character varying, 'boolean'::character varying])::text[])))
);


ALTER TABLE public.kpi_library OWNER TO erp_user;

--
-- TOC entry 275 (class 1259 OID 17307)
-- Name: leave_accrual_logs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_accrual_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    balance_id uuid NOT NULL,
    accrual_date date NOT NULL,
    days_accrued numeric(5,2) NOT NULL,
    balance_before numeric(7,2) NOT NULL,
    balance_after numeric(7,2) NOT NULL,
    accrual_formula character varying(20) NOT NULL,
    notes text,
    run_id uuid,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_accrual_formula CHECK (((accrual_formula)::text = ANY ((ARRAY['annual_lump'::character varying, 'monthly'::character varying, 'anniversary'::character varying, 'none'::character varying])::text[])))
);


ALTER TABLE public.leave_accrual_logs OWNER TO erp_user;

--
-- TOC entry 277 (class 1259 OID 17374)
-- Name: leave_adjustments; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_adjustments (
    adjustment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    fiscal_year smallint NOT NULL,
    adjustment_days numeric(5,2) NOT NULL,
    reason text NOT NULL,
    adjusted_by bigint NOT NULL,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.leave_adjustments OWNER TO erp_user;

--
-- TOC entry 274 (class 1259 OID 17283)
-- Name: leave_balances; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_balances (
    balance_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    fiscal_year smallint NOT NULL,
    opening_balance numeric(7,2) DEFAULT '0'::numeric NOT NULL,
    accrued_ytd numeric(7,2) DEFAULT '0'::numeric NOT NULL,
    used_ytd numeric(7,2) DEFAULT '0'::numeric NOT NULL,
    pending_ytd numeric(7,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_balance_non_negative CHECK (((opening_balance >= (0)::numeric) AND (accrued_ytd >= (0)::numeric) AND (used_ytd >= (0)::numeric) AND (pending_ytd >= (0)::numeric)))
);


ALTER TABLE public.leave_balances OWNER TO erp_user;

--
-- TOC entry 5784 (class 0 OID 0)
-- Dependencies: 274
-- Name: COLUMN leave_balances.fiscal_year; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.leave_balances.fiscal_year IS 'The year this balance belongs to. Balances do not roll up across years - ask per year.';


--
-- TOC entry 5785 (class 0 OID 0)
-- Dependencies: 274
-- Name: COLUMN leave_balances.opening_balance; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.leave_balances.opening_balance IS 'Days carried into the fiscal year. Remaining = opening_balance + accrued_ytd - used_ytd - pending_ytd.';


--
-- TOC entry 5786 (class 0 OID 0)
-- Dependencies: 274
-- Name: COLUMN leave_balances.accrued_ytd; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.leave_balances.accrued_ytd IS 'Days earned so far this fiscal year.';


--
-- TOC entry 5787 (class 0 OID 0)
-- Dependencies: 274
-- Name: COLUMN leave_balances.used_ytd; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.leave_balances.used_ytd IS 'Days already taken and approved.';


--
-- TOC entry 5788 (class 0 OID 0)
-- Dependencies: 274
-- Name: COLUMN leave_balances.pending_ytd; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.leave_balances.pending_ytd IS 'Days in submitted-but-unapproved requests. Counted against the balance, because approving them will consume it.';


--
-- TOC entry 358 (class 1259 OID 19111)
-- Name: leave_holiday_calendar_connections; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_holiday_calendar_connections (
    connection_id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider character varying(20) DEFAULT 'google'::character varying NOT NULL,
    calendar_id character varying(200) NOT NULL,
    credential_ref character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    connected_by bigint,
    connected_at timestamp(0) with time zone NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.leave_holiday_calendar_connections OWNER TO erp_user;

--
-- TOC entry 359 (class 1259 OID 19119)
-- Name: leave_holiday_sync_logs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_holiday_sync_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    source character varying(20) DEFAULT 'google'::character varying NOT NULL,
    imported_count integer DEFAULT 0 NOT NULL,
    updated_count integer DEFAULT 0 NOT NULL,
    result character varying(20) DEFAULT 'success'::character varying NOT NULL,
    message text,
    synced_at timestamp(0) with time zone NOT NULL,
    next_sync_at timestamp(0) with time zone,
    synced_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_leave_holiday_sync_logs_result CHECK (((result)::text = ANY ((ARRAY['success'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.leave_holiday_sync_logs OWNER TO erp_user;

--
-- TOC entry 272 (class 1259 OID 17242)
-- Name: leave_policies; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_policies (
    policy_id uuid DEFAULT gen_random_uuid() NOT NULL,
    leave_type_id uuid NOT NULL,
    scope character varying(10) DEFAULT 'all'::character varying NOT NULL,
    scope_id uuid,
    annual_entitlement_days numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    accrual_method character varying(20) DEFAULT 'annual_lump'::character varying NOT NULL,
    accrual_rate numeric(5,2),
    max_carry_forward_days numeric(5,1),
    min_service_months smallint DEFAULT '0'::smallint NOT NULL,
    max_consecutive_days smallint,
    notice_days smallint DEFAULT '0'::smallint NOT NULL,
    allow_negative_balance boolean DEFAULT false NOT NULL,
    gender_eligibility character varying(10) DEFAULT 'all'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_accrual_method CHECK (((accrual_method)::text = ANY ((ARRAY['annual_lump'::character varying, 'monthly'::character varying, 'anniversary'::character varying, 'none'::character varying])::text[]))),
    CONSTRAINT chk_entitlement_positive CHECK ((annual_entitlement_days >= (0)::numeric)),
    CONSTRAINT chk_gender_eligibility CHECK (((gender_eligibility)::text = ANY ((ARRAY['all'::character varying, 'male'::character varying, 'female'::character varying])::text[]))),
    CONSTRAINT chk_policy_scope CHECK (((scope)::text = ANY ((ARRAY['all'::character varying, 'grade'::character varying, 'dept'::character varying])::text[]))),
    CONSTRAINT chk_scope_id_required CHECK ((((scope)::text = 'all'::text) OR (scope_id IS NOT NULL)))
);


ALTER TABLE public.leave_policies OWNER TO erp_user;

--
-- TOC entry 276 (class 1259 OID 17334)
-- Name: leave_requests; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    working_days numeric(5,2) NOT NULL,
    is_half_day boolean DEFAULT false NOT NULL,
    half_day_period character varying(15),
    reason text,
    medical_certificate_path text,
    medical_certificate_mime character varying(100),
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    approval_request_id uuid,
    reviewed_by_emp_id uuid,
    reviewed_at timestamp(0) with time zone,
    review_notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_dates CHECK ((end_date >= start_date)),
    CONSTRAINT chk_half_day_period CHECK (((half_day_period IS NULL) OR ((half_day_period)::text = ANY ((ARRAY['first_half'::character varying, 'second_half'::character varying])::text[])))),
    CONSTRAINT chk_leave_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'returned'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT chk_working_days_positive CHECK ((working_days > (0)::numeric))
);


ALTER TABLE public.leave_requests OWNER TO erp_user;

--
-- TOC entry 271 (class 1259 OID 17225)
-- Name: leave_types; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.leave_types (
    leave_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    leave_code character varying(20) NOT NULL,
    leave_name character varying(100) NOT NULL,
    leave_name_local character varying(100) NOT NULL,
    category character varying(30) NOT NULL,
    is_paid boolean DEFAULT true NOT NULL,
    requires_document boolean DEFAULT false NOT NULL,
    affects_attendance boolean DEFAULT true NOT NULL,
    color_hex character(7) DEFAULT '#6366F1'::bpchar NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_color_hex CHECK ((color_hex ~ '^#[0-9A-Fa-f]{6}$'::text)),
    CONSTRAINT chk_leave_category CHECK (((category)::text = ANY ((ARRAY['annual'::character varying, 'sick'::character varying, 'maternity'::character varying, 'paternity'::character varying, 'unpaid'::character varying, 'emergency'::character varying, 'bereavement'::character varying, 'compassionate'::character varying, 'hajj'::character varying, 'study'::character varying, 'casual'::character varying, 'other'::character varying])::text[])))
);


ALTER TABLE public.leave_types OWNER TO erp_user;

--
-- TOC entry 379 (class 1259 OID 19703)
-- Name: mfa_credentials; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.mfa_credentials (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    type character varying(20) DEFAULT 'totp'::character varying NOT NULL,
    secret text NOT NULL,
    confirmed_at timestamp(0) with time zone,
    last_used_at timestamp(0) with time zone,
    last_used_counter bigint,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.mfa_credentials OWNER TO erp_user;

--
-- TOC entry 378 (class 1259 OID 19702)
-- Name: mfa_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.mfa_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mfa_credentials_id_seq OWNER TO erp_user;

--
-- TOC entry 5789 (class 0 OID 0)
-- Dependencies: 378
-- Name: mfa_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.mfa_credentials_id_seq OWNED BY public.mfa_credentials.id;


--
-- TOC entry 381 (class 1259 OID 19721)
-- Name: mfa_recovery_codes; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.mfa_recovery_codes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    code_hash character varying(255) NOT NULL,
    used_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.mfa_recovery_codes OWNER TO erp_user;

--
-- TOC entry 380 (class 1259 OID 19720)
-- Name: mfa_recovery_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.mfa_recovery_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mfa_recovery_codes_id_seq OWNER TO erp_user;

--
-- TOC entry 5790 (class 0 OID 0)
-- Dependencies: 380
-- Name: mfa_recovery_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.mfa_recovery_codes_id_seq OWNED BY public.mfa_recovery_codes.id;


--
-- TOC entry 217 (class 1259 OID 16389)
-- Name: migrations; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO erp_user;

--
-- TOC entry 216 (class 1259 OID 16388)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO erp_user;

--
-- TOC entry 5791 (class 0 OID 0)
-- Dependencies: 216
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 266 (class 1259 OID 17150)
-- Name: mobile_devices; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.mobile_devices (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    platform character varying(10) NOT NULL,
    push_token character varying(255),
    app_version character varying(20) NOT NULL,
    os_version character varying(20),
    last_seen_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    biometric_public_key text,
    biometric_enabled boolean DEFAULT false NOT NULL,
    CONSTRAINT chk_mobile_device_platform CHECK (((platform)::text = ANY ((ARRAY['ios'::character varying, 'android'::character varying])::text[])))
);


ALTER TABLE public.mobile_devices OWNER TO erp_user;

--
-- TOC entry 334 (class 1259 OID 18422)
-- Name: mobile_saved_jobs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.mobile_saved_jobs (
    saved_job_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    requisition_id uuid NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.mobile_saved_jobs OWNER TO erp_user;

--
-- TOC entry 267 (class 1259 OID 17165)
-- Name: mobile_sessions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.mobile_sessions (
    session_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    device_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    issued_at timestamp(0) with time zone NOT NULL,
    expires_at timestamp(0) with time zone NOT NULL,
    revoked_at timestamp(0) with time zone,
    ip_address character varying(45),
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.mobile_sessions OWNER TO erp_user;

--
-- TOC entry 258 (class 1259 OID 17056)
-- Name: notification_logs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.notification_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    type character varying(50) NOT NULL,
    channel character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    related_record_type character varying(50),
    related_record_id uuid,
    retry_count smallint DEFAULT '0'::smallint NOT NULL,
    read_at timestamp(0) with time zone,
    sent_at timestamp(0) with time zone,
    delivered_at timestamp(0) with time zone,
    error_message text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_notif_log_channel CHECK (((channel)::text = ANY ((ARRAY['in_app'::character varying, 'email'::character varying])::text[]))),
    CONSTRAINT chk_notif_log_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'sent'::character varying, 'delivered'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT chk_notif_log_type CHECK (((type)::text = ANY ((ARRAY['contract_expiry'::character varying, 'document_expiry'::character varying, 'probation_reminder'::character varying, 'overdue_task'::character varying, 'headcount_discrepancy'::character varying, 'budget_overage'::character varying, 'approval_required'::character varying, 'approval_decision'::character varying, 'general'::character varying])::text[])))
);


ALTER TABLE public.notification_logs OWNER TO erp_user;

--
-- TOC entry 259 (class 1259 OID 17066)
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.notification_preferences (
    pref_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    type character varying(50) NOT NULL,
    channel character varying(20) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_notif_pref_channel CHECK (((channel)::text = ANY ((ARRAY['in_app'::character varying, 'email'::character varying])::text[]))),
    CONSTRAINT chk_notif_pref_type CHECK (((type)::text = ANY ((ARRAY['contract_expiry'::character varying, 'document_expiry'::character varying, 'probation_reminder'::character varying, 'overdue_task'::character varying, 'headcount_discrepancy'::character varying, 'budget_overage'::character varying, 'approval_required'::character varying, 'approval_decision'::character varying, 'general'::character varying])::text[])))
);


ALTER TABLE public.notification_preferences OWNER TO erp_user;

--
-- TOC entry 257 (class 1259 OID 17045)
-- Name: notification_templates; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.notification_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    type character varying(50) NOT NULL,
    channel character varying(20) NOT NULL,
    trigger_event character varying(100) NOT NULL,
    subject character varying(255),
    body_html text NOT NULL,
    body_text text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint,
    CONSTRAINT chk_notif_template_channel CHECK (((channel)::text = ANY ((ARRAY['in_app'::character varying, 'email'::character varying])::text[]))),
    CONSTRAINT chk_notif_template_type CHECK (((type)::text = ANY ((ARRAY['contract_expiry'::character varying, 'document_expiry'::character varying, 'probation_reminder'::character varying, 'overdue_task'::character varying, 'headcount_discrepancy'::character varying, 'budget_overage'::character varying, 'approval_required'::character varying, 'approval_decision'::character varying, 'general'::character varying])::text[])))
);


ALTER TABLE public.notification_templates OWNER TO erp_user;

--
-- TOC entry 337 (class 1259 OID 18457)
-- Name: onboarding_task_completions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.onboarding_task_completions (
    completion_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    template_id uuid NOT NULL,
    completed_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.onboarding_task_completions OWNER TO erp_user;

--
-- TOC entry 335 (class 1259 OID 18430)
-- Name: onboarding_task_templates; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.onboarding_task_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    day_milestone integer NOT NULL,
    title character varying(150) NOT NULL,
    description text,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint,
    CONSTRAINT chk_onboarding_task_templates_day_milestone CHECK ((day_milestone = ANY (ARRAY[1, 30, 90])))
);


ALTER TABLE public.onboarding_task_templates OWNER TO erp_user;

--
-- TOC entry 234 (class 1259 OID 16506)
-- Name: organization_branches; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.organization_branches (
    branch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_code character varying(20) NOT NULL,
    branch_name character varying(200) NOT NULL,
    branch_name_local character varying(200),
    branch_type character varying(50) NOT NULL,
    parent_branch_id uuid,
    country_code character varying(2) NOT NULL,
    city character varying(100) NOT NULL,
    address_line1 text,
    address_line2 text,
    postal_code character varying(20),
    phone character varying(50),
    email character varying(200),
    tax_id character varying(100),
    manager_emp_id uuid,
    is_head_office boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    established_date date,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_branch_type CHECK (((branch_type)::text = ANY ((ARRAY['head_office'::character varying, 'regional_office'::character varying, 'branch'::character varying, 'warehouse'::character varying, 'site'::character varying])::text[])))
);


ALTER TABLE public.organization_branches OWNER TO erp_user;

--
-- TOC entry 282 (class 1259 OID 17477)
-- Name: overtime_requests; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.overtime_requests (
    overtime_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    attendance_record_id uuid,
    overtime_date date NOT NULL,
    requested_minutes smallint NOT NULL,
    approved_minutes smallint,
    reason text,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    approval_request_id uuid,
    reviewed_by_emp_id uuid,
    reviewed_at timestamp(0) with time zone,
    review_notes text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_overtime_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT chk_requested_minutes CHECK ((requested_minutes > 0))
);


ALTER TABLE public.overtime_requests OWNER TO erp_user;

--
-- TOC entry 220 (class 1259 OID 16407)
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_reset_tokens OWNER TO erp_user;

--
-- TOC entry 355 (class 1259 OID 18891)
-- Name: pay_period_settings; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.pay_period_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL,
    boundary_day smallint NOT NULL,
    effective_from date NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_pay_period_settings_boundary_day CHECK (((boundary_day >= 1) AND (boundary_day <= 28)))
);


ALTER TABLE public.pay_period_settings OWNER TO erp_user;

--
-- TOC entry 5792 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN pay_period_settings.boundary_day; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pay_period_settings.boundary_day IS 'Day of month a payroll cycle starts on. Currently 1, which makes a period the calendar month. The 22-to-21 cycle is a future, separately dated change.';


--
-- TOC entry 5793 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN pay_period_settings.effective_from; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pay_period_settings.effective_from IS 'Date this rule starts applying. Rows are append-only: a boundary change adds a row rather than editing one, so historical periods keep their meaning.';


--
-- TOC entry 356 (class 1259 OID 18907)
-- Name: pay_periods; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.pay_periods (
    pay_period_id uuid DEFAULT gen_random_uuid() NOT NULL,
    period_code character varying(12) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    payout_date date,
    status character varying(15) DEFAULT 'open'::character varying NOT NULL,
    setting_id uuid NOT NULL,
    closed_by bigint,
    closed_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_pay_periods_closure_attributed CHECK ((((status)::text = 'open'::text) OR ((closed_by IS NOT NULL) AND (closed_at IS NOT NULL)))),
    CONSTRAINT chk_pay_periods_range CHECK ((end_date > start_date)),
    CONSTRAINT chk_pay_periods_status CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'closed'::character varying, 'paid'::character varying])::text[])))
);


ALTER TABLE public.pay_periods OWNER TO erp_user;

--
-- TOC entry 5794 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN pay_periods.period_code; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pay_periods.period_code IS 'YYYY-MM label, meaning the period whose END falls in that month. At boundary_day 1 that is exactly the calendar month.';


--
-- TOC entry 5795 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN pay_periods.start_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pay_periods.start_date IS 'First day of the period, inclusive.';


--
-- TOC entry 5796 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN pay_periods.end_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pay_periods.end_date IS 'Last day of the period, inclusive.';


--
-- TOC entry 5797 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN pay_periods.payout_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pay_periods.payout_date IS 'Date salaries were actually paid. NULL until the period is marked paid.';


--
-- TOC entry 5798 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN pay_periods.status; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pay_periods.status IS 'open accepts new postings; closed is locked for calculation; paid is final. The lifecycle is one-way - a correction goes to the next open period.';


--
-- TOC entry 361 (class 1259 OID 19142)
-- Name: perf_cycle_scores; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.perf_cycle_scores (
    cycle_score_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    cycle_id uuid NOT NULL,
    weighted_final numeric(6,2) DEFAULT '0'::numeric NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.perf_cycle_scores OWNER TO erp_user;

--
-- TOC entry 360 (class 1259 OID 19134)
-- Name: perf_kpi_scores; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.perf_kpi_scores (
    score_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    cycle_id uuid NOT NULL,
    kpi_id uuid NOT NULL,
    score numeric(6,2) NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.perf_kpi_scores OWNER TO erp_user;

--
-- TOC entry 362 (class 1259 OID 19151)
-- Name: perf_raise_brackets; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.perf_raise_brackets (
    bracket_id uuid DEFAULT gen_random_uuid() NOT NULL,
    lower_bound numeric(6,2) NOT NULL,
    upper_bound numeric(6,2),
    increase_pct numeric(5,2) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.perf_raise_brackets OWNER TO erp_user;

--
-- TOC entry 364 (class 1259 OID 19165)
-- Name: perf_raise_proposals; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.perf_raise_proposals (
    proposal_id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    score numeric(6,2) NOT NULL,
    increase_pct numeric(5,2) NOT NULL,
    current_basic numeric(15,2) NOT NULL,
    proposed_basic numeric(15,2) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    salary_change_id uuid,
    decided_by bigint,
    decided_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_perf_raise_proposals_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.perf_raise_proposals OWNER TO erp_user;

--
-- TOC entry 363 (class 1259 OID 19158)
-- Name: perf_raise_runs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.perf_raise_runs (
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    cycle_id uuid NOT NULL,
    status character varying(20) DEFAULT 'generated'::character varying NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_perf_raise_runs_status CHECK (((status)::text = ANY ((ARRAY['generated'::character varying, 'completed'::character varying])::text[])))
);


ALTER TABLE public.perf_raise_runs OWNER TO erp_user;

--
-- TOC entry 261 (class 1259 OID 17095)
-- Name: permissions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.permissions (
    permission_id uuid NOT NULL,
    resource character varying(100) NOT NULL,
    action character varying(50) NOT NULL,
    description character varying(255),
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.permissions OWNER TO erp_user;

--
-- TOC entry 233 (class 1259 OID 16494)
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name text NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.personal_access_tokens OWNER TO erp_user;

--
-- TOC entry 232 (class 1259 OID 16493)
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_id_seq OWNER TO erp_user;

--
-- TOC entry 5799 (class 0 OID 0)
-- Dependencies: 232
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- TOC entry 329 (class 1259 OID 18321)
-- Name: pg_bonuses; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.pg_bonuses (
    bonus_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    type character varying(20) NOT NULL,
    amount numeric(12,2) NOT NULL,
    period character varying(7) NOT NULL,
    status character varying(20) DEFAULT 'pending_approval'::character varying NOT NULL,
    approval_id uuid,
    note character varying(255),
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    pay_period_id uuid,
    CONSTRAINT chk_pg_bonuses_status CHECK (((status)::text = ANY ((ARRAY['pending_approval'::character varying, 'approved'::character varying, 'injected'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT chk_pg_bonuses_type CHECK (((type)::text = ANY ((ARRAY['performance'::character varying, 'spot'::character varying, 'eid'::character varying, 'other'::character varying])::text[])))
);


ALTER TABLE public.pg_bonuses OWNER TO erp_user;

--
-- TOC entry 5800 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN pg_bonuses.period; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pg_bonuses.period IS 'YYYY-MM label. Currently the calendar month: the 22-to-21 pay cycle is NOT yet in effect, so period questions must not assume it. pay_period_id is the joinable equivalent and is authoritative once populated.';


--
-- TOC entry 5801 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN pg_bonuses.pay_period_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pg_bonuses.pay_period_id IS 'Foreign key to pay_periods. Nullable during the cut-over: rows written before the backfill may have it unset, so a query that must not miss rows should fall back to the label column.';


--
-- TOC entry 326 (class 1259 OID 18272)
-- Name: pg_expense_claims; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.pg_expense_claims (
    claim_id uuid DEFAULT gen_random_uuid() NOT NULL,
    claim_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    category character varying(30) NOT NULL,
    amount numeric(12,2) NOT NULL,
    currency_code character(3) DEFAULT 'EGP'::bpchar NOT NULL,
    incurred_on date NOT NULL,
    receipt_path character varying(255),
    status character varying(20) DEFAULT 'pending_approval'::character varying NOT NULL,
    approval_id uuid,
    payout_method character varying(15) DEFAULT 'payroll'::character varying NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_pg_expense_claims_category CHECK (((category)::text = ANY ((ARRAY['travel'::character varying, 'meals'::character varying, 'medical'::character varying, 'transport'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT chk_pg_expense_claims_payout_method CHECK (((payout_method)::text = ANY ((ARRAY['payroll'::character varying, 'petty_cash'::character varying])::text[]))),
    CONSTRAINT chk_pg_expense_claims_status CHECK (((status)::text = ANY ((ARRAY['pending_approval'::character varying, 'approved'::character varying, 'rejected'::character varying, 'paid'::character varying])::text[])))
);


ALTER TABLE public.pg_expense_claims OWNER TO erp_user;

--
-- TOC entry 322 (class 1259 OID 18216)
-- Name: pg_loan_schedules; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.pg_loan_schedules (
    schedule_id uuid DEFAULT gen_random_uuid() NOT NULL,
    loan_id uuid NOT NULL,
    period character varying(7) NOT NULL,
    amount numeric(12,2) NOT NULL,
    status character varying(15) DEFAULT 'scheduled'::character varying NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    pay_period_id uuid,
    CONSTRAINT chk_pg_loan_schedules_status CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'deducted'::character varying, 'skipped'::character varying])::text[])))
);


ALTER TABLE public.pg_loan_schedules OWNER TO erp_user;

--
-- TOC entry 5802 (class 0 OID 0)
-- Dependencies: 322
-- Name: COLUMN pg_loan_schedules.period; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pg_loan_schedules.period IS 'YYYY-MM label. Currently the calendar month: the 22-to-21 pay cycle is NOT yet in effect, so period questions must not assume it. pay_period_id is the joinable equivalent and is authoritative once populated.';


--
-- TOC entry 5803 (class 0 OID 0)
-- Dependencies: 322
-- Name: COLUMN pg_loan_schedules.pay_period_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pg_loan_schedules.pay_period_id IS 'Foreign key to pay_periods. Nullable during the cut-over: rows written before the backfill may have it unset, so a query that must not miss rows should fall back to the label column.';


--
-- TOC entry 318 (class 1259 OID 18144)
-- Name: pg_loans; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.pg_loans (
    loan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    loan_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    type character varying(15) NOT NULL,
    principal_amount numeric(12,2) NOT NULL,
    installments_count integer NOT NULL,
    installment_amount numeric(12,2) NOT NULL,
    remaining_amount numeric(12,2) NOT NULL,
    reason character varying(255),
    status character varying(20) DEFAULT 'pending_approval'::character varying NOT NULL,
    approval_id uuid,
    start_period character varying(7) NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_pg_loans_status CHECK (((status)::text = ANY ((ARRAY['pending_approval'::character varying, 'approved'::character varying, 'active'::character varying, 'settled'::character varying, 'rejected'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT chk_pg_loans_type CHECK (((type)::text = ANY ((ARRAY['loan'::character varying, 'advance'::character varying])::text[])))
);


ALTER TABLE public.pg_loans OWNER TO erp_user;

--
-- TOC entry 5804 (class 0 OID 0)
-- Dependencies: 318
-- Name: COLUMN pg_loans.start_period; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pg_loans.start_period IS 'YYYY-MM label. Currently the calendar month: the 22-to-21 pay cycle is NOT yet in effect, so period questions must not assume it. pay_period_id is the joinable equivalent and is authoritative once populated.';


--
-- TOC entry 331 (class 1259 OID 18359)
-- Name: pg_payroll_injections; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.pg_payroll_injections (
    injection_id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_type character varying(20) NOT NULL,
    source_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    period character varying(7) NOT NULL,
    direction character varying(10) NOT NULL,
    amount numeric(12,2) NOT NULL,
    status character varying(15) DEFAULT 'pending'::character varying NOT NULL,
    synced_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    pay_period_id uuid,
    CONSTRAINT chk_pg_payroll_injections_direction CHECK (((direction)::text = ANY ((ARRAY['deduction'::character varying, 'addition'::character varying])::text[]))),
    CONSTRAINT chk_pg_payroll_injections_source_type CHECK (((source_type)::text = ANY ((ARRAY['loan'::character varying, 'expense'::character varying, 'bonus'::character varying, 'penalty'::character varying, 'absence'::character varying, 'short_leave_override'::character varying, 'leave_pre_service'::character varying])::text[]))),
    CONSTRAINT chk_pg_payroll_injections_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'included'::character varying, 'sent'::character varying])::text[])))
);


ALTER TABLE public.pg_payroll_injections OWNER TO erp_user;

--
-- TOC entry 5805 (class 0 OID 0)
-- Dependencies: 331
-- Name: COLUMN pg_payroll_injections.period; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pg_payroll_injections.period IS 'YYYY-MM label. Currently the calendar month: the 22-to-21 pay cycle is NOT yet in effect, so period questions must not assume it. pay_period_id is the joinable equivalent and is authoritative once populated.';


--
-- TOC entry 5806 (class 0 OID 0)
-- Dependencies: 331
-- Name: COLUMN pg_payroll_injections.pay_period_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.pg_payroll_injections.pay_period_id IS 'Foreign key to pay_periods. Nullable during the cut-over: rows written before the backfill may have it unset, so a query that must not miss rows should fall back to the label column.';


--
-- TOC entry 240 (class 1259 OID 16679)
-- Name: positions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.positions (
    position_id uuid DEFAULT gen_random_uuid() NOT NULL,
    position_code character varying(30) NOT NULL,
    position_title character varying(200) NOT NULL,
    position_title_local character varying(200),
    dept_id uuid,
    branch_id uuid,
    job_id uuid,
    cost_centre_id uuid,
    headcount_budget smallint DEFAULT '1'::smallint NOT NULL,
    headcount_filled smallint DEFAULT '0'::smallint NOT NULL,
    position_status character varying(20) DEFAULT 'open'::character varying NOT NULL,
    is_budgeted boolean DEFAULT true NOT NULL,
    effective_date date,
    expiry_date date,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    headcount_vacant smallint GENERATED ALWAYS AS ((headcount_budget - headcount_filled)) STORED,
    CONSTRAINT chk_position_dates CHECK (((expiry_date IS NULL) OR (effective_date IS NULL) OR (expiry_date >= effective_date))),
    CONSTRAINT chk_position_headcount_budget CHECK ((headcount_budget > 0)),
    CONSTRAINT chk_position_headcount_filled CHECK ((headcount_filled >= 0)),
    CONSTRAINT chk_position_status CHECK (((position_status)::text = ANY ((ARRAY['open'::character varying, 'filled'::character varying, 'frozen'::character varying, 'closed'::character varying, 'on_hold'::character varying])::text[])))
);


ALTER TABLE public.positions OWNER TO erp_user;

--
-- TOC entry 303 (class 1259 OID 17863)
-- Name: program_cohorts; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.program_cohorts (
    cohort_id uuid DEFAULT gen_random_uuid() NOT NULL,
    program_id uuid NOT NULL,
    cohort_name character varying(150) NOT NULL,
    start_date date,
    end_date date,
    capacity integer,
    enrolled_count integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'planned'::character varying NOT NULL,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_cohort_status CHECK (((status)::text = ANY ((ARRAY['planned'::character varying, 'open'::character varying, 'full'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.program_cohorts OWNER TO erp_user;

--
-- TOC entry 302 (class 1259 OID 17841)
-- Name: program_courses; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.program_courses (
    program_course_id uuid DEFAULT gen_random_uuid() NOT NULL,
    program_id uuid NOT NULL,
    course_id uuid NOT NULL,
    sequence_order smallint DEFAULT '1'::smallint NOT NULL,
    is_mandatory boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.program_courses OWNER TO erp_user;

--
-- TOC entry 304 (class 1259 OID 17881)
-- Name: program_enrollments; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.program_enrollments (
    enrollment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    program_id uuid NOT NULL,
    cohort_id uuid,
    employee_id uuid NOT NULL,
    status character varying(20) DEFAULT 'enrolled'::character varying NOT NULL,
    enrolled_at timestamp(0) with time zone,
    completion_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    completed_at timestamp(0) with time zone,
    approval_request_id uuid,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_program_completion_pct CHECK (((completion_pct >= (0)::numeric) AND (completion_pct <= (100)::numeric))),
    CONSTRAINT chk_program_enrollment_status CHECK (((status)::text = ANY ((ARRAY['enrolled'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'dropped'::character varying, 'withdrawn'::character varying])::text[])))
);


ALTER TABLE public.program_enrollments OWNER TO erp_user;

--
-- TOC entry 323 (class 1259 OID 18232)
-- Name: ps_payslip_access_log; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ps_payslip_access_log (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    payslip_id uuid NOT NULL,
    accessed_by bigint NOT NULL,
    action character varying(15) NOT NULL,
    ip character varying(45),
    accessed_at timestamp(0) with time zone NOT NULL,
    CONSTRAINT chk_ps_payslip_access_log_action CHECK (((action)::text = ANY ((ARRAY['viewed'::character varying, 'downloaded'::character varying])::text[])))
);


ALTER TABLE public.ps_payslip_access_log OWNER TO erp_user;

--
-- TOC entry 319 (class 1259 OID 18157)
-- Name: ps_payslip_documents; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ps_payslip_documents (
    payslip_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    period character varying(7) NOT NULL,
    pdf_path character varying(255),
    gross numeric(12,2),
    total_deductions numeric(12,2),
    net numeric(12,2),
    status character varying(15) DEFAULT 'draft'::character varying NOT NULL,
    published_at timestamp(0) with time zone,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    pay_period_id uuid,
    CONSTRAINT chk_ps_payslip_documents_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'generated'::character varying, 'sent'::character varying])::text[])))
);


ALTER TABLE public.ps_payslip_documents OWNER TO erp_user;

--
-- TOC entry 5807 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN ps_payslip_documents.period; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.ps_payslip_documents.period IS 'YYYY-MM label. Currently the calendar month: the 22-to-21 pay cycle is NOT yet in effect, so period questions must not assume it. pay_period_id is the joinable equivalent and is authoritative once populated.';


--
-- TOC entry 5808 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN ps_payslip_documents.pay_period_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.ps_payslip_documents.pay_period_id IS 'Foreign key to pay_periods. Nullable during the cut-over: rows written before the backfill may have it unset, so a query that must not miss rows should fall back to the label column.';


--
-- TOC entry 330 (class 1259 OID 18333)
-- Name: rec_applications; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.rec_applications (
    application_id uuid DEFAULT gen_random_uuid() NOT NULL,
    requisition_id uuid NOT NULL,
    candidate_id uuid NOT NULL,
    current_stage_id uuid NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    rejection_reason character varying(255),
    score numeric(4,1),
    applied_at timestamp(0) with time zone NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    cover_note text,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_rec_applications_status CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'rejected'::character varying, 'withdrawn'::character varying, 'hired'::character varying])::text[])))
);


ALTER TABLE public.rec_applications OWNER TO erp_user;

--
-- TOC entry 324 (class 1259 OID 18245)
-- Name: rec_candidates; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.rec_candidates (
    candidate_id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    phone character varying(30),
    source character varying(30) NOT NULL,
    applicant_employee_id uuid,
    referred_by_employee_id uuid,
    cv_path character varying(255),
    current_title character varying(120),
    total_experience_years numeric(4,1),
    gdpr_consent_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_rec_candidates_source CHECK (((source)::text = ANY ((ARRAY['internal'::character varying, 'referral'::character varying, 'portal'::character varying, 'agency'::character varying, 'linkedin'::character varying, 'walk_in'::character varying])::text[])))
);


ALTER TABLE public.rec_candidates OWNER TO erp_user;

--
-- TOC entry 332 (class 1259 OID 18374)
-- Name: rec_interviews; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.rec_interviews (
    interview_id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    stage_id uuid NOT NULL,
    interviewer_id uuid,
    scheduled_at timestamp(0) with time zone NOT NULL,
    mode character varying(15) NOT NULL,
    status character varying(15) DEFAULT 'scheduled'::character varying NOT NULL,
    feedback text,
    rating integer,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_rec_interviews_mode CHECK (((mode)::text = ANY ((ARRAY['onsite'::character varying, 'online'::character varying, 'phone'::character varying])::text[]))),
    CONSTRAINT chk_rec_interviews_rating CHECK (((rating IS NULL) OR ((rating >= 1) AND (rating <= 5)))),
    CONSTRAINT chk_rec_interviews_status CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'done'::character varying, 'no_show'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.rec_interviews OWNER TO erp_user;

--
-- TOC entry 320 (class 1259 OID 18170)
-- Name: rec_job_requisitions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.rec_job_requisitions (
    requisition_id uuid DEFAULT gen_random_uuid() NOT NULL,
    requisition_no character varying(30) NOT NULL,
    job_id uuid NOT NULL,
    dept_id uuid,
    hiring_manager_id uuid,
    headcount integer NOT NULL,
    filled_count integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    visibility character varying(15) DEFAULT 'external'::character varying NOT NULL,
    location_label character varying(120),
    employment_type character varying(20),
    approval_id uuid,
    opened_at timestamp(0) with time zone,
    closed_at timestamp(0) with time zone,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_rec_requisitions_employment_type CHECK (((employment_type IS NULL) OR ((employment_type)::text = ANY ((ARRAY['full_time'::character varying, 'part_time'::character varying, 'contract'::character varying, 'internship'::character varying, 'temporary'::character varying])::text[])))),
    CONSTRAINT chk_rec_requisitions_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending_approval'::character varying, 'open'::character varying, 'on_hold'::character varying, 'closed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT chk_rec_requisitions_visibility CHECK (((visibility)::text = ANY ((ARRAY['internal'::character varying, 'external'::character varying, 'both'::character varying])::text[])))
);


ALTER TABLE public.rec_job_requisitions OWNER TO erp_user;

--
-- TOC entry 333 (class 1259 OID 18397)
-- Name: rec_offers; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.rec_offers (
    offer_id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    offered_grade_id uuid,
    gross_salary numeric(12,2) NOT NULL,
    currency_code character(3) DEFAULT 'EGP'::bpchar NOT NULL,
    start_date date NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    approval_id uuid,
    expires_at timestamp(0) with time zone,
    accepted_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_rec_offers_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending_approval'::character varying, 'approved'::character varying, 'sent'::character varying, 'accepted'::character varying, 'declined'::character varying, 'expired'::character varying])::text[])))
);


ALTER TABLE public.rec_offers OWNER TO erp_user;

--
-- TOC entry 327 (class 1259 OID 18288)
-- Name: rec_pipeline_stages; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.rec_pipeline_stages (
    stage_id uuid DEFAULT gen_random_uuid() NOT NULL,
    requisition_id uuid,
    name_ar character varying(60) NOT NULL,
    name_en character varying(60) NOT NULL,
    sequence_order integer NOT NULL,
    stage_type character varying(20) NOT NULL,
    is_terminal boolean DEFAULT false NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_rec_pipeline_stages_type CHECK (((stage_type)::text = ANY ((ARRAY['screening'::character varying, 'interview'::character varying, 'assessment'::character varying, 'offer'::character varying, 'hired'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.rec_pipeline_stages OWNER TO erp_user;

--
-- TOC entry 288 (class 1259 OID 17599)
-- Name: review_cycles; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.review_cycles (
    cycle_id uuid DEFAULT gen_random_uuid() NOT NULL,
    cycle_name character varying(200) NOT NULL,
    cycle_name_local character varying(200),
    cycle_type character varying(30) NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    phases_json jsonb,
    rating_scale smallint DEFAULT '5'::smallint NOT NULL,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_cycle_period CHECK ((period_end > period_start)),
    CONSTRAINT chk_cycle_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'active'::character varying, 'self_review'::character varying, 'manager_review'::character varying, 'calibration'::character varying, 'completed'::character varying, 'closed'::character varying])::text[]))),
    CONSTRAINT chk_cycle_type CHECK (((cycle_type)::text = ANY ((ARRAY['annual'::character varying, 'semi_annual'::character varying, 'quarterly'::character varying, 'probation'::character varying, 'project'::character varying])::text[]))),
    CONSTRAINT chk_rating_scale CHECK (((rating_scale >= 3) AND (rating_scale <= 10)))
);


ALTER TABLE public.review_cycles OWNER TO erp_user;

--
-- TOC entry 262 (class 1259 OID 17102)
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    permission_level character varying(30) NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_role_perm_level CHECK (((permission_level)::text = ANY ((ARRAY['none'::character varying, 'read'::character varying, 'write'::character varying, 'approval_required'::character varying])::text[])))
);


ALTER TABLE public.role_permissions OWNER TO erp_user;

--
-- TOC entry 312 (class 1259 OID 18037)
-- Name: role_skill_requirements; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.role_skill_requirements (
    req_id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_grade_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    required_level smallint NOT NULL,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_role_skill_required_level CHECK (((required_level >= 1) AND (required_level <= 5)))
);


ALTER TABLE public.role_skill_requirements OWNER TO erp_user;

--
-- TOC entry 260 (class 1259 OID 17086)
-- Name: roles; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.roles (
    role_id uuid NOT NULL,
    role_name character varying(100) NOT NULL,
    description character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    is_system boolean DEFAULT false NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint
);


ALTER TABLE public.roles OWNER TO erp_user;

--
-- TOC entry 243 (class 1259 OID 16841)
-- Name: salary; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.salary (
    salary_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    job_grade_id uuid,
    cost_centre_id uuid,
    basic_salary numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    housing_allowance numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    transport_allowance numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    food_allowance numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    mobile_allowance numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    other_allowance numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    gross_salary numeric(15,2) GENERATED ALWAYS AS ((((((basic_salary + housing_allowance) + transport_allowance) + food_allowance) + mobile_allowance) + other_allowance)) STORED NOT NULL,
    income_tax_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    social_insurance_pct numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    other_deduction numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    net_salary numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    currency_code character varying(3) DEFAULT 'EGP'::character varying NOT NULL,
    pay_frequency character varying(20) DEFAULT 'monthly'::character varying NOT NULL,
    pay_method character varying(20) DEFAULT 'bank_transfer'::character varying NOT NULL,
    bank_name character varying(100),
    bank_account character varying(50),
    bank_iban character varying(50),
    effective_date date NOT NULL,
    end_date date,
    change_reason character varying(30),
    change_type character varying(20),
    approval_status character varying(20) DEFAULT 'pending_approval'::character varying NOT NULL,
    approved_by character varying(255),
    approved_date date,
    is_current boolean DEFAULT false NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    approved_by_user_id bigint,
    CONSTRAINT chk_salary_approval_status CHECK (((approval_status)::text = ANY ((ARRAY['pending_approval'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT chk_salary_basic CHECK ((basic_salary >= (0)::numeric)),
    CONSTRAINT chk_salary_change_reason CHECK (((change_reason IS NULL) OR ((change_reason)::text = ANY ((ARRAY['hire'::character varying, 'promotion'::character varying, 'annual_review'::character varying, 'correction'::character varying, 'restructure'::character varying, 'market_adjustment'::character varying, 'demotion'::character varying])::text[])))),
    CONSTRAINT chk_salary_change_type CHECK (((change_type IS NULL) OR ((change_type)::text = ANY ((ARRAY['increase'::character varying, 'decrease'::character varying, 'correction'::character varying])::text[])))),
    CONSTRAINT chk_salary_end_date CHECK (((end_date IS NULL) OR (end_date >= effective_date))),
    CONSTRAINT chk_salary_pay_frequency CHECK (((pay_frequency)::text = ANY ((ARRAY['weekly'::character varying, 'bi_weekly'::character varying, 'semi_monthly'::character varying, 'monthly'::character varying])::text[]))),
    CONSTRAINT chk_salary_pay_method CHECK (((pay_method)::text = ANY ((ARRAY['bank_transfer'::character varying, 'cash'::character varying, 'cheque'::character varying, 'wallet'::character varying])::text[])))
);


ALTER TABLE public.salary OWNER TO erp_user;

--
-- TOC entry 5809 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.basic_salary; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.basic_salary IS 'Base pay before allowances. gross_salary = basic + all allowances.';


--
-- TOC entry 5810 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.gross_salary; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.gross_salary IS 'Generated column: basic plus every allowance. Never write to it directly.';


--
-- TOC entry 5811 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.income_tax_pct; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.income_tax_pct IS 'Percentage, not an amount. 14.00 means 14%.';


--
-- TOC entry 5812 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.social_insurance_pct; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.social_insurance_pct IS 'Percentage, not an amount.';


--
-- TOC entry 5813 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.net_salary; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.net_salary IS 'After income tax and social insurance. This is what reaches the employee.';


--
-- TOC entry 5814 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.effective_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.effective_date IS 'Date this salary record takes effect. Use with end_date for point-in-time questions.';


--
-- TOC entry 5815 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.end_date; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.end_date IS 'Date this record stopped applying. NULL on the current record.';


--
-- TOC entry 5816 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.change_reason; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.change_reason IS 'Why this salary row exists (hire, promotion, annual_review, ...). The audit answer to "why did their pay change".';


--
-- TOC entry 5817 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.approval_status; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.approval_status IS 'Whether the salary change has been approved. A pending_approval row is not yet in force.';


--
-- TOC entry 5818 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.approved_by; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.approved_by IS 'LEGACY. Holds a users.id cast to text, despite the name. Superseded by approved_by_user_id; kept so the original record survives. Do not join on it.';


--
-- TOC entry 5819 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.is_current; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.is_current IS 'TRUE on the active record only. Do NOT use for historical questions - a question about last year needs effective_date and end_date, not this flag.';


--
-- TOC entry 5820 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN salary.approved_by_user_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.salary.approved_by_user_id IS 'The user who approved this salary change. Joinable to users.id.';


--
-- TOC entry 307 (class 1259 OID 17948)
-- Name: session_attendances; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.session_attendances (
    attendance_id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    attended boolean DEFAULT false NOT NULL,
    score numeric(5,2),
    result character varying(10) DEFAULT 'pending'::character varying NOT NULL,
    marked_by uuid,
    marked_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_attendance_result CHECK (((result)::text = ANY ((ARRAY['pass'::character varying, 'fail'::character varying, 'pending'::character varying])::text[]))),
    CONSTRAINT chk_attendance_score CHECK (((score IS NULL) OR ((score >= (0)::numeric) AND (score <= (100)::numeric))))
);


ALTER TABLE public.session_attendances OWNER TO erp_user;

--
-- TOC entry 306 (class 1259 OID 17932)
-- Name: session_enrollments; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.session_enrollments (
    enrollment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    status character varying(20) DEFAULT 'requested'::character varying NOT NULL,
    waitlist_position integer,
    approval_request_id uuid,
    enrolled_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_session_enrollment_status CHECK (((status)::text = ANY ((ARRAY['requested'::character varying, 'approved'::character varying, 'enrolled'::character varying, 'waitlisted'::character varying, 'attended'::character varying, 'no_show'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.session_enrollments OWNER TO erp_user;

--
-- TOC entry 351 (class 1259 OID 18822)
-- Name: settings_billing_invoices; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.settings_billing_invoices (
    billing_invoice_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL,
    invoice_number character varying(40) NOT NULL,
    amount numeric(12,2) NOT NULL,
    currency_code character(3) DEFAULT 'EGP'::bpchar NOT NULL,
    status character varying(20) DEFAULT 'paid'::character varying NOT NULL,
    issued_on date NOT NULL,
    period_start date,
    period_end date,
    document_path character varying(500),
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_settings_billing_invoice_status CHECK (((status)::text = ANY ((ARRAY['paid'::character varying, 'open'::character varying, 'void'::character varying])::text[])))
);


ALTER TABLE public.settings_billing_invoices OWNER TO erp_user;

--
-- TOC entry 349 (class 1259 OID 18787)
-- Name: settings_billing_plans; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.settings_billing_plans (
    plan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    name character varying(100) NOT NULL,
    price_amount numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    currency_code character(3) DEFAULT 'EGP'::bpchar NOT NULL,
    billing_interval character varying(20) DEFAULT 'monthly'::character varying NOT NULL,
    seat_limit integer DEFAULT 0 NOT NULL,
    storage_limit_gb integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_settings_plan_interval CHECK (((billing_interval)::text = ANY ((ARRAY['monthly'::character varying, 'yearly'::character varying])::text[])))
);


ALTER TABLE public.settings_billing_plans OWNER TO erp_user;

--
-- TOC entry 350 (class 1259 OID 18801)
-- Name: settings_billing_subscriptions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.settings_billing_subscriptions (
    subscription_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_profile_id bigint NOT NULL,
    plan_id uuid NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    next_billing_date date,
    seats_used integer DEFAULT 0 NOT NULL,
    storage_used_gb numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_settings_subscription_status CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'past_due'::character varying, 'cancelled'::character varying, 'trialing'::character varying])::text[])))
);


ALTER TABLE public.settings_billing_subscriptions OWNER TO erp_user;

--
-- TOC entry 353 (class 1259 OID 18860)
-- Name: settings_notification_preferences; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.settings_notification_preferences (
    preference_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    preference_key character varying(60) NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.settings_notification_preferences OWNER TO erp_user;

--
-- TOC entry 352 (class 1259 OID 18840)
-- Name: settings_payment_methods; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.settings_payment_methods (
    payment_method_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_profile_id bigint NOT NULL,
    provider character varying(30) DEFAULT 'stripe'::character varying NOT NULL,
    provider_token character varying(255) NOT NULL,
    brand character varying(30),
    last4 character(4),
    exp_month smallint,
    exp_year smallint,
    is_default boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_settings_payment_method_exp CHECK ((((exp_month IS NULL) OR ((exp_month >= 1) AND (exp_month <= 12))) AND ((exp_year IS NULL) OR ((exp_year >= 2000) AND (exp_year <= 2100))))),
    CONSTRAINT chk_settings_payment_method_last4 CHECK (((last4 IS NULL) OR (last4 ~ '^[0-9]{4}$'::text)))
);


ALTER TABLE public.settings_payment_methods OWNER TO erp_user;

--
-- TOC entry 279 (class 1259 OID 17408)
-- Name: shift_assignments; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.shift_assignments (
    assignment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    shift_id uuid NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    assigned_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.shift_assignments OWNER TO erp_user;

--
-- TOC entry 310 (class 1259 OID 18005)
-- Name: skills; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.skills (
    skill_id uuid DEFAULT gen_random_uuid() NOT NULL,
    skill_code character varying(30) NOT NULL,
    skill_name character varying(150) NOT NULL,
    skill_name_local character varying(150),
    category character varying(50) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.skills OWNER TO erp_user;

--
-- TOC entry 365 (class 1259 OID 19182)
-- Name: sl_permission_policies; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.sl_permission_policies (
    policy_id uuid DEFAULT gen_random_uuid() NOT NULL,
    quota_mode character varying(20) DEFAULT 'fixed_count'::character varying NOT NULL,
    per_period smallint DEFAULT '3'::smallint NOT NULL,
    standard_duration_cap_min smallint DEFAULT '30'::smallint NOT NULL,
    fourth_permission_cap_min smallint DEFAULT '120'::smallint NOT NULL,
    one_per_day boolean DEFAULT true NOT NULL,
    period_boundary smallint,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_sl_permission_policies_quota_mode CHECK (((quota_mode)::text = ANY ((ARRAY['fixed_count'::character varying, 'total_minutes'::character varying, 'tiered_short_long'::character varying])::text[])))
);


ALTER TABLE public.sl_permission_policies OWNER TO erp_user;

--
-- TOC entry 367 (class 1259 OID 19273)
-- Name: sl_permissions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.sl_permissions (
    permission_id uuid DEFAULT gen_random_uuid() NOT NULL,
    permission_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    permission_date date NOT NULL,
    minutes smallint NOT NULL,
    type character varying(10) DEFAULT 'short'::character varying NOT NULL,
    reason text,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    quota_used smallint DEFAULT '0'::smallint NOT NULL,
    quota_limit smallint DEFAULT '0'::smallint NOT NULL,
    within_quota boolean DEFAULT true NOT NULL,
    excess_minutes smallint DEFAULT '0'::smallint NOT NULL,
    approver_user_id bigint,
    decided_at timestamp(0) with time zone,
    rejection_reason text,
    period character varying(7) NOT NULL,
    pay_period_id uuid,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_sl_permissions_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'overridden'::character varying])::text[]))),
    CONSTRAINT chk_sl_permissions_type CHECK (((type)::text = ANY ((ARRAY['short'::character varying, 'long'::character varying])::text[])))
);


ALTER TABLE public.sl_permissions OWNER TO erp_user;

--
-- TOC entry 317 (class 1259 OID 18126)
-- Name: sr_generated_letters; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.sr_generated_letters (
    letter_id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_id uuid,
    template_id uuid NOT NULL,
    context_snapshot jsonb,
    pdf_path character varying(255) NOT NULL,
    reference_no character varying(40) NOT NULL,
    generated_by bigint NOT NULL,
    generated_at timestamp(0) with time zone NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.sr_generated_letters OWNER TO erp_user;

--
-- TOC entry 315 (class 1259 OID 18095)
-- Name: sr_letter_templates; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.sr_letter_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    name character varying(120) NOT NULL,
    body_ar text NOT NULL,
    body_en text NOT NULL,
    header_footer_config jsonb,
    version integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.sr_letter_templates OWNER TO erp_user;

--
-- TOC entry 314 (class 1259 OID 18079)
-- Name: sr_request_types; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.sr_request_types (
    type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    name_ar character varying(120) NOT NULL,
    name_en character varying(120) NOT NULL,
    category character varying(20) NOT NULL,
    requires_approval boolean DEFAULT true NOT NULL,
    sla_hours integer DEFAULT 48 NOT NULL,
    letter_template_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    created_by bigint,
    CONSTRAINT chk_sr_request_type_category CHECK (((category)::text = ANY ((ARRAY['letter'::character varying, 'ticket'::character varying])::text[])))
);


ALTER TABLE public.sr_request_types OWNER TO erp_user;

--
-- TOC entry 316 (class 1259 OID 18106)
-- Name: sr_requests; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.sr_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    request_type_id uuid NOT NULL,
    category character varying(20) NOT NULL,
    payload jsonb,
    status character varying(20) DEFAULT 'submitted'::character varying NOT NULL,
    approval_request_id uuid,
    assigned_to uuid,
    sla_due_at timestamp(0) with time zone NOT NULL,
    resolved_at timestamp(0) with time zone,
    output_document_id uuid,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_sr_requests_category CHECK (((category)::text = ANY ((ARRAY['letter'::character varying, 'ticket'::character varying])::text[]))),
    CONSTRAINT chk_sr_requests_status CHECK (((status)::text = ANY ((ARRAY['submitted'::character varying, 'pending_approval'::character varying, 'in_progress'::character varying, 'resolved'::character varying, 'rejected'::character varying, 'closed'::character varying])::text[])))
);


ALTER TABLE public.sr_requests OWNER TO erp_user;

--
-- TOC entry 343 (class 1259 OID 18531)
-- Name: sso_identities; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.sso_identities (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    provider character varying(40) NOT NULL,
    subject_id character varying(255) NOT NULL,
    linked_at timestamp(0) with time zone NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.sso_identities OWNER TO erp_user;

--
-- TOC entry 342 (class 1259 OID 18530)
-- Name: sso_identities_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.sso_identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sso_identities_id_seq OWNER TO erp_user;

--
-- TOC entry 5821 (class 0 OID 0)
-- Dependencies: 342
-- Name: sso_identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.sso_identities_id_seq OWNED BY public.sso_identities.id;


--
-- TOC entry 375 (class 1259 OID 19541)
-- Name: ta_absence_records; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ta_absence_records (
    absence_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    absence_date date NOT NULL,
    year smallint NOT NULL,
    source character varying(20) DEFAULT 'manual'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.ta_absence_records OWNER TO erp_user;

--
-- TOC entry 376 (class 1259 OID 19551)
-- Name: ta_article69_cases; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ta_article69_cases (
    case_id uuid DEFAULT gen_random_uuid() NOT NULL,
    case_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    year smallint NOT NULL,
    cumulative_days smallint DEFAULT '0'::smallint NOT NULL,
    longest_run smallint DEFAULT '0'::smallint NOT NULL,
    status character varying(20) DEFAULT 'open'::character varying NOT NULL,
    notice_issued_at timestamp(0) with time zone,
    notice_by bigint,
    response_window_ends_at timestamp(0) with time zone,
    decision character varying(20),
    decision_reason text,
    decided_at timestamp(0) with time zone,
    decided_by bigint,
    deduction_days numeric(6,2),
    period character varying(7),
    pay_period_id uuid,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_ta_article69_cases_decision CHECK (((decision IS NULL) OR ((decision)::text = ANY ((ARRAY['deduct'::character varying, 'terminate'::character varying, 'dismiss_case'::character varying])::text[])))),
    CONSTRAINT chk_ta_article69_cases_status CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'notice_issued'::character varying, 'decided'::character varying, 'closed'::character varying])::text[])))
);


ALTER TABLE public.ta_article69_cases OWNER TO erp_user;

--
-- TOC entry 374 (class 1259 OID 19530)
-- Name: ta_article69_settings; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ta_article69_settings (
    settings_id uuid DEFAULT gen_random_uuid() NOT NULL,
    consecutive_threshold smallint DEFAULT '10'::smallint NOT NULL,
    intermittent_threshold smallint DEFAULT '20'::smallint NOT NULL,
    response_window_days smallint DEFAULT '7'::smallint NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.ta_article69_settings OWNER TO erp_user;

--
-- TOC entry 373 (class 1259 OID 19510)
-- Name: ta_attendance_exceptions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ta_attendance_exceptions (
    exception_id uuid DEFAULT gen_random_uuid() NOT NULL,
    type character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'open'::character varying NOT NULL,
    device_id uuid,
    employee_id uuid,
    enrolment_id character varying(60),
    attendance_date date,
    suggested_resolution character varying(60),
    details jsonb,
    resolution character varying(60),
    resolved_by bigint,
    resolved_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_ta_attendance_exceptions_status CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'resolved'::character varying])::text[]))),
    CONSTRAINT chk_ta_attendance_exceptions_type CHECK (((type)::text = ANY ((ARRAY['unpaired_punch'::character varying, 'unknown_enrolment'::character varying, 'duplicate_punch'::character varying, 'absence_candidate'::character varying])::text[])))
);


ALTER TABLE public.ta_attendance_exceptions OWNER TO erp_user;

--
-- TOC entry 371 (class 1259 OID 19479)
-- Name: ta_device_enrolments; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ta_device_enrolments (
    device_enrolment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid NOT NULL,
    enrolment_id character varying(60) NOT NULL,
    employee_id uuid,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.ta_device_enrolments OWNER TO erp_user;

--
-- TOC entry 370 (class 1259 OID 19463)
-- Name: ta_devices; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ta_devices (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    branch_id uuid,
    location character varying(200),
    firmware character varying(60),
    health character varying(20) DEFAULT 'healthy'::character varying NOT NULL,
    last_sync_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_ta_devices_health CHECK (((health)::text = ANY ((ARRAY['healthy'::character varying, 'degraded'::character varying, 'offline'::character varying])::text[])))
);


ALTER TABLE public.ta_devices OWNER TO erp_user;

--
-- TOC entry 372 (class 1259 OID 19493)
-- Name: ta_raw_punches; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.ta_raw_punches (
    raw_punch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid NOT NULL,
    enrolment_id character varying(60) NOT NULL,
    employee_id uuid,
    punched_at timestamp(0) with time zone NOT NULL,
    direction character varying(10) DEFAULT 'unknown'::character varying NOT NULL,
    processed boolean DEFAULT false NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_ta_raw_punches_direction CHECK (((direction)::text = ANY ((ARRAY['in'::character varying, 'out'::character varying, 'unknown'::character varying])::text[])))
);


ALTER TABLE public.ta_raw_punches OWNER TO erp_user;

--
-- TOC entry 328 (class 1259 OID 18302)
-- Name: tal_career_paths; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.tal_career_paths (
    path_id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_grade_id uuid NOT NULL,
    to_grade_id uuid NOT NULL,
    min_tenure_months integer NOT NULL,
    required_competencies jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.tal_career_paths OWNER TO erp_user;

--
-- TOC entry 338 (class 1259 OID 18470)
-- Name: tal_employee_criterion_progress; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.tal_employee_criterion_progress (
    progress_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    criterion_id uuid NOT NULL,
    state character varying(20) NOT NULL,
    progress_percent numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    gaps_count integer DEFAULT 0 NOT NULL,
    notes text,
    updated_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_tal_employee_criterion_progress_state CHECK (((state)::text = ANY ((ARRAY['met'::character varying, 'in_progress'::character varying])::text[])))
);


ALTER TABLE public.tal_employee_criterion_progress OWNER TO erp_user;

--
-- TOC entry 321 (class 1259 OID 18195)
-- Name: tal_promotion_cases; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.tal_promotion_cases (
    case_id uuid DEFAULT gen_random_uuid() NOT NULL,
    case_no character varying(30) NOT NULL,
    employee_id uuid NOT NULL,
    current_grade_id uuid,
    proposed_grade_id uuid NOT NULL,
    target_position_id uuid,
    current_salary numeric(12,2),
    proposed_salary numeric(12,2) NOT NULL,
    effective_date date NOT NULL,
    justification text,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    approval_id uuid,
    applied_at timestamp(0) with time zone,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_tal_promotion_cases_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending_approval'::character varying, 'approved'::character varying, 'applied'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.tal_promotion_cases OWNER TO erp_user;

--
-- TOC entry 336 (class 1259 OID 18443)
-- Name: tal_promotion_criteria; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.tal_promotion_criteria (
    criterion_id uuid DEFAULT gen_random_uuid() NOT NULL,
    career_path_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    weight integer DEFAULT 1 NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.tal_promotion_criteria OWNER TO erp_user;

--
-- TOC entry 339 (class 1259 OID 18489)
-- Name: tal_promotion_nominations; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.tal_promotion_nominations (
    nomination_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    nominator_user_id bigint NOT NULL,
    role_label character varying(255),
    quote text,
    nominated_at date NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.tal_promotion_nominations OWNER TO erp_user;

--
-- TOC entry 340 (class 1259 OID 18498)
-- Name: tal_role_highlights; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.tal_role_highlights (
    highlight_id uuid DEFAULT gen_random_uuid() NOT NULL,
    operation_id uuid NOT NULL,
    highlight character varying(255) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint
);


ALTER TABLE public.tal_role_highlights OWNER TO erp_user;

--
-- TOC entry 325 (class 1259 OID 18255)
-- Name: tal_succession_candidates; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.tal_succession_candidates (
    succession_id uuid DEFAULT gen_random_uuid() NOT NULL,
    position_id uuid NOT NULL,
    candidate_employee_id uuid NOT NULL,
    readiness character varying(20) NOT NULL,
    rank integer NOT NULL,
    notes text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_tal_succession_readiness CHECK (((readiness)::text = ANY ((ARRAY['ready_now'::character varying, '1_2_years'::character varying, 'long_term'::character varying])::text[])))
);


ALTER TABLE public.tal_succession_candidates OWNER TO erp_user;

--
-- TOC entry 298 (class 1259 OID 17767)
-- Name: training_courses; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.training_courses (
    course_id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_code character varying(30) NOT NULL,
    course_name character varying(200) NOT NULL,
    course_name_local character varying(200),
    category character varying(50) NOT NULL,
    delivery_mode character varying(30) NOT NULL,
    level character varying(20) NOT NULL,
    duration_hours numeric(6,2) NOT NULL,
    provider character varying(200),
    cost_per_seat numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    currency_code character varying(3) DEFAULT 'EGP'::character varying NOT NULL,
    passing_score numeric(5,2),
    validity_months smallint,
    is_mandatory boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_course_category CHECK (((category)::text = ANY ((ARRAY['technical'::character varying, 'soft_skills'::character varying, 'compliance'::character varying, 'leadership'::character varying, 'onboarding'::character varying, 'safety'::character varying, 'product'::character varying])::text[]))),
    CONSTRAINT chk_course_cost CHECK ((cost_per_seat >= (0)::numeric)),
    CONSTRAINT chk_course_delivery_mode CHECK (((delivery_mode)::text = ANY ((ARRAY['classroom'::character varying, 'e_learning'::character varying, 'blended'::character varying, 'online'::character varying, 'hybrid'::character varying])::text[]))),
    CONSTRAINT chk_course_level CHECK (((level)::text = ANY ((ARRAY['beginner'::character varying, 'intermediate'::character varying, 'advanced'::character varying, 'expert'::character varying])::text[]))),
    CONSTRAINT chk_course_passing_score CHECK (((passing_score IS NULL) OR ((passing_score >= (0)::numeric) AND (passing_score <= (100)::numeric))))
);


ALTER TABLE public.training_courses OWNER TO erp_user;

--
-- TOC entry 309 (class 1259 OID 17984)
-- Name: training_feedbacks; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.training_feedbacks (
    feedback_id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    content_rating smallint NOT NULL,
    trainer_rating smallint NOT NULL,
    relevance_rating smallint NOT NULL,
    would_recommend boolean DEFAULT true NOT NULL,
    comments text,
    submitted_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_feedback_content_rating CHECK (((content_rating >= 1) AND (content_rating <= 5))),
    CONSTRAINT chk_feedback_relevance_rating CHECK (((relevance_rating >= 1) AND (relevance_rating <= 5))),
    CONSTRAINT chk_feedback_trainer_rating CHECK (((trainer_rating >= 1) AND (trainer_rating <= 5)))
);


ALTER TABLE public.training_feedbacks OWNER TO erp_user;

--
-- TOC entry 301 (class 1259 OID 17821)
-- Name: training_programs; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.training_programs (
    program_id uuid DEFAULT gen_random_uuid() NOT NULL,
    program_code character varying(30) NOT NULL,
    program_name character varying(200) NOT NULL,
    program_name_local character varying(200),
    category character varying(50) NOT NULL,
    description text,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    provider character varying(200),
    owner_emp_id uuid,
    target_audience character varying(300),
    total_duration_hours numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    cost_per_seat numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    currency_code character varying(3) DEFAULT 'EGP'::character varying NOT NULL,
    max_cohort_size integer,
    start_date date,
    end_date date,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT chk_program_category CHECK (((category)::text = ANY ((ARRAY['technical'::character varying, 'soft_skills'::character varying, 'compliance'::character varying, 'leadership'::character varying, 'onboarding'::character varying, 'safety'::character varying, 'product'::character varying])::text[]))),
    CONSTRAINT chk_program_cost CHECK ((cost_per_seat >= (0)::numeric)),
    CONSTRAINT chk_program_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'active'::character varying, 'paused'::character varying, 'completed'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE public.training_programs OWNER TO erp_user;

--
-- TOC entry 305 (class 1259 OID 17905)
-- Name: training_sessions; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.training_sessions (
    session_id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    cohort_id uuid,
    start_datetime timestamp(0) with time zone NOT NULL,
    end_datetime timestamp(0) with time zone NOT NULL,
    trainer_emp_id uuid,
    external_trainer character varying(200),
    venue character varying(300),
    delivery_mode character varying(30) NOT NULL,
    max_seats integer NOT NULL,
    enrolled_count integer DEFAULT 0 NOT NULL,
    waitlist_count integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'scheduled'::character varying NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_session_dates CHECK ((end_datetime > start_datetime)),
    CONSTRAINT chk_session_delivery_mode CHECK (((delivery_mode)::text = ANY ((ARRAY['classroom'::character varying, 'e_learning'::character varying, 'blended'::character varying, 'online'::character varying, 'hybrid'::character varying])::text[]))),
    CONSTRAINT chk_session_max_seats CHECK ((max_seats > 0)),
    CONSTRAINT chk_session_status CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'open'::character varying, 'full'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.training_sessions OWNER TO erp_user;

--
-- TOC entry 263 (class 1259 OID 17119)
-- Name: user_roles; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.user_roles (
    user_role_id uuid NOT NULL,
    user_id bigint NOT NULL,
    role_id uuid NOT NULL,
    branch_id uuid,
    assigned_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    assigned_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.user_roles OWNER TO erp_user;

--
-- TOC entry 219 (class 1259 OID 16396)
-- Name: users; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    remember_token character varying(100),
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    employee_id uuid,
    must_change_password boolean DEFAULT false NOT NULL
);


ALTER TABLE public.users OWNER TO erp_user;

--
-- TOC entry 5822 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN users.employee_id; Type: COMMENT; Schema: public; Owner: erp_user
--

COMMENT ON COLUMN public.users.employee_id IS 'Links a login to an employee record. This is how the assistant resolves "me". NULL for service accounts and for staff with no login.';


--
-- TOC entry 218 (class 1259 OID 16395)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: erp_user
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO erp_user;

--
-- TOC entry 5823 (class 0 OID 0)
-- Dependencies: 218
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: erp_user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 248 (class 1259 OID 16957)
-- Name: v_active_employees; Type: VIEW; Schema: public; Owner: erp_user
--

CREATE VIEW public.v_active_employees AS
 SELECT e.employee_id,
    e.employee_number,
    e.first_name,
    e.last_name,
    e.email_work,
    e.branch_id,
    e.dept_id,
    e.position_id,
    e.job_grade_id,
    e.cost_centre_id,
    e.manager_id,
    e.employment_status,
    e.employment_type,
    e.hire_date,
    e.termination_date,
    e.is_active,
    ob.branch_name,
    bd.dept_name,
    p.position_title,
    jg.grade_code,
    jg.grade_name,
    jg.grade_level,
    jg.grade_category,
    (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (e.hire_date)::timestamp with time zone)))::integer AS tenure_years,
    (EXTRACT(month FROM age((CURRENT_DATE)::timestamp with time zone, (e.hire_date)::timestamp with time zone)))::integer AS tenure_months_remainder,
    (CURRENT_DATE - e.hire_date) AS tenure_days
   FROM ((((public.employees e
     LEFT JOIN public.organization_branches ob ON ((ob.branch_id = e.branch_id)))
     LEFT JOIN public.branch_departments bd ON ((bd.dept_id = e.dept_id)))
     LEFT JOIN public.positions p ON ((p.position_id = e.position_id)))
     LEFT JOIN public.job_grades jg ON ((jg.job_grade_id = e.job_grade_id)))
  WHERE ((e.is_active = true) AND ((e.employment_status)::text <> ALL ((ARRAY['terminated'::character varying, 'resigned'::character varying, 'retired'::character varying, 'inactive'::character varying])::text[])));


ALTER VIEW public.v_active_employees OWNER TO erp_user;

--
-- TOC entry 251 (class 1259 OID 16972)
-- Name: v_contracts_expiring_soon; Type: VIEW; Schema: public; Owner: erp_user
--

CREATE VIEW public.v_contracts_expiring_soon AS
 SELECT c.contract_id,
    c.contract_number,
    c.employee_id,
    c.contract_type,
    c.start_date,
    c.end_date,
    (c.end_date - CURRENT_DATE) AS days_until_expiry,
    c.contract_status,
    e.first_name,
    e.last_name,
    e.employee_number
   FROM (public.employee_contracts c
     JOIN public.employees e ON ((e.employee_id = c.employee_id)))
  WHERE (((c.contract_status)::text = 'active'::text) AND (c.is_current = true) AND (c.end_date IS NOT NULL) AND ((c.end_date >= CURRENT_DATE) AND (c.end_date <= (CURRENT_DATE + '90 days'::interval))));


ALTER VIEW public.v_contracts_expiring_soon OWNER TO erp_user;

--
-- TOC entry 249 (class 1259 OID 16962)
-- Name: v_document_expiry_alerts; Type: VIEW; Schema: public; Owner: erp_user
--

CREATE VIEW public.v_document_expiry_alerts AS
 SELECT d.document_id,
    d.employee_id,
    d.document_type,
    d.document_category,
    d.document_title,
    d.document_number,
    d.issue_date,
    d.expiry_date,
    d.alert_days_before,
    d.is_mandatory,
    d.is_verified,
    d.is_active,
        CASE
            WHEN ((d.is_mandatory = true) AND ((d.file_path IS NULL) OR (d.is_verified = false))) THEN 'missing'::text
            WHEN ((d.expiry_date IS NOT NULL) AND (d.expiry_date < CURRENT_DATE)) THEN 'expired'::text
            WHEN ((d.expiry_date IS NOT NULL) AND (d.expiry_date <= (CURRENT_DATE + ((d.alert_days_before || ' days'::text))::interval))) THEN 'expiring'::text
            ELSE 'valid'::text
        END AS status,
    (d.expiry_date - CURRENT_DATE) AS days_until_expiry
   FROM public.employee_documents d
  WHERE (d.is_active = true);


ALTER VIEW public.v_document_expiry_alerts OWNER TO erp_user;

--
-- TOC entry 250 (class 1259 OID 16967)
-- Name: v_headcount_summary; Type: VIEW; Schema: public; Owner: erp_user
--

CREATE VIEW public.v_headcount_summary AS
 SELECT p.position_id,
    p.position_code,
    p.position_title,
    p.branch_id,
    p.dept_id,
    p.job_id,
    p.cost_centre_id,
    p.position_status,
    p.headcount_budget,
    p.headcount_filled,
    p.headcount_vacant,
        CASE
            WHEN (p.headcount_budget = 0) THEN (0)::numeric
            ELSE round((((p.headcount_filled)::numeric / (p.headcount_budget)::numeric) * (100)::numeric), 1)
        END AS fill_rate_pct,
    ob.branch_name,
    bd.dept_name
   FROM ((public.positions p
     LEFT JOIN public.organization_branches ob ON ((ob.branch_id = p.branch_id)))
     LEFT JOIN public.branch_departments bd ON ((bd.dept_id = p.dept_id)))
  WHERE (p.is_active = true);


ALTER VIEW public.v_headcount_summary OWNER TO erp_user;

--
-- TOC entry 252 (class 1259 OID 16977)
-- Name: v_salary_band_compliance; Type: VIEW; Schema: public; Owner: erp_user
--

CREATE VIEW public.v_salary_band_compliance AS
 SELECT s.salary_id,
    s.employee_id,
    s.job_grade_id,
    jg.grade_code,
    jg.grade_name,
    jg.min_salary,
    jg.mid_salary,
    jg.max_salary,
    s.basic_salary,
    s.gross_salary,
        CASE
            WHEN ((jg.min_salary = (0)::numeric) AND (jg.max_salary = (0)::numeric)) THEN 'unset'::text
            WHEN (s.basic_salary < jg.min_salary) THEN 'below_band'::text
            WHEN (s.basic_salary > jg.max_salary) THEN 'above_band'::text
            ELSE 'within_band'::text
        END AS band_status,
        CASE
            WHEN (jg.mid_salary > (0)::numeric) THEN round(((s.basic_salary / jg.mid_salary) * (100)::numeric), 1)
            ELSE NULL::numeric
        END AS compa_ratio_pct,
    e.first_name,
    e.last_name,
    e.branch_id,
    e.dept_id
   FROM ((public.salary s
     JOIN public.employees e ON ((e.employee_id = s.employee_id)))
     JOIN public.job_grades jg ON ((jg.job_grade_id = s.job_grade_id)))
  WHERE ((s.is_current = true) AND (e.is_active = true));


ALTER VIEW public.v_salary_band_compliance OWNER TO erp_user;

--
-- TOC entry 278 (class 1259 OID 17394)
-- Name: work_shifts; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.work_shifts (
    shift_id uuid DEFAULT gen_random_uuid() NOT NULL,
    shift_code character varying(20) NOT NULL,
    shift_name character varying(100) NOT NULL,
    shift_name_local character varying(100),
    start_time time(0) without time zone NOT NULL,
    end_time time(0) without time zone NOT NULL,
    grace_period_minutes smallint DEFAULT '0'::smallint NOT NULL,
    break_duration_minutes smallint DEFAULT '0'::smallint NOT NULL,
    overtime_threshold_minutes smallint DEFAULT '60'::smallint NOT NULL,
    geofence_latitude numeric(10,7),
    geofence_longitude numeric(10,7),
    geofence_radius_meters integer,
    is_night_shift boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    min_coverage smallint,
    compliance_unit character varying(10) DEFAULT 'day'::character varying NOT NULL,
    weekly_required_hours numeric(5,2),
    CONSTRAINT chk_work_shifts_compliance_unit CHECK (((compliance_unit)::text = ANY ((ARRAY['day'::character varying, 'week'::character varying])::text[])))
);


ALTER TABLE public.work_shifts OWNER TO erp_user;

--
-- TOC entry 273 (class 1259 OID 17269)
-- Name: working_day_calendars; Type: TABLE; Schema: public; Owner: erp_user
--

CREATE TABLE public.working_day_calendars (
    calendar_id uuid DEFAULT gen_random_uuid() NOT NULL,
    calendar_date date NOT NULL,
    is_working_day boolean NOT NULL,
    day_type character varying(20) NOT NULL,
    description text,
    country_code character(3) DEFAULT 'EGY'::bpchar NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    CONSTRAINT chk_day_type CHECK (((day_type)::text = ANY ((ARRAY['weekday'::character varying, 'weekend'::character varying, 'public_holiday'::character varying, 'company_holiday'::character varying])::text[])))
);


ALTER TABLE public.working_day_calendars OWNER TO erp_user;

--
-- TOC entry 4055 (class 2604 OID 17188)
-- Name: app_config id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.app_config ALTER COLUMN id SET DEFAULT nextval('public.app_config_id_seq'::regclass);


--
-- TOC entry 3939 (class 2604 OID 16452)
-- Name: company_integrations id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_integrations ALTER COLUMN id SET DEFAULT nextval('public.company_integrations_id_seq'::regclass);


--
-- TOC entry 3936 (class 2604 OID 16434)
-- Name: company_profiles id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_profiles ALTER COLUMN id SET DEFAULT nextval('public.company_profiles_id_seq'::regclass);


--
-- TOC entry 4020 (class 2604 OID 16937)
-- Name: employee_history history_id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_history ALTER COLUMN history_id SET DEFAULT nextval('public.employee_history_history_id_seq'::regclass);


--
-- TOC entry 3943 (class 2604 OID 16485)
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- TOC entry 4048 (class 2604 OID 17138)
-- Name: integration_sync_log log_id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.integration_sync_log ALTER COLUMN log_id SET DEFAULT nextval('public.integration_sync_log_log_id_seq'::regclass);


--
-- TOC entry 3942 (class 2604 OID 16468)
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- TOC entry 4431 (class 2604 OID 19706)
-- Name: mfa_credentials id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mfa_credentials ALTER COLUMN id SET DEFAULT nextval('public.mfa_credentials_id_seq'::regclass);


--
-- TOC entry 4434 (class 2604 OID 19724)
-- Name: mfa_recovery_codes id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mfa_recovery_codes ALTER COLUMN id SET DEFAULT nextval('public.mfa_recovery_codes_id_seq'::regclass);


--
-- TOC entry 3932 (class 2604 OID 16392)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 3945 (class 2604 OID 16497)
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- TOC entry 4323 (class 2604 OID 18534)
-- Name: sso_identities id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sso_identities ALTER COLUMN id SET DEFAULT nextval('public.sso_identities_id_seq'::regclass);


--
-- TOC entry 3933 (class 2604 OID 16399)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 4724 (class 2606 OID 16606)
-- Name: accounting_salary accounting_salary_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.accounting_salary
    ADD CONSTRAINT accounting_salary_pkey PRIMARY KEY (acc_salary_id);


--
-- TOC entry 4876 (class 2606 OID 17195)
-- Name: app_config app_config_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.app_config
    ADD CONSTRAINT app_config_pkey PRIMARY KEY (id);


--
-- TOC entry 4990 (class 2606 OID 17678)
-- Name: appraisal_ratings appraisal_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.appraisal_ratings
    ADD CONSTRAINT appraisal_ratings_pkey PRIMARY KEY (rating_id);


--
-- TOC entry 4983 (class 2606 OID 17653)
-- Name: appraisals appraisals_cycle_id_employee_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.appraisals
    ADD CONSTRAINT appraisals_cycle_id_employee_id_unique UNIQUE (cycle_id, employee_id);


--
-- TOC entry 4985 (class 2606 OID 17660)
-- Name: appraisals appraisals_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.appraisals
    ADD CONSTRAINT appraisals_pkey PRIMARY KEY (appraisal_id);


--
-- TOC entry 4819 (class 2606 OID 17009)
-- Name: approval_chain_config approval_chain_config_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.approval_chain_config
    ADD CONSTRAINT approval_chain_config_pkey PRIMARY KEY (chain_id);


--
-- TOC entry 4822 (class 2606 OID 17020)
-- Name: approval_requests approval_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.approval_requests
    ADD CONSTRAINT approval_requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 4827 (class 2606 OID 17034)
-- Name: approval_steps approval_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.approval_steps
    ADD CONSTRAINT approval_steps_pkey PRIMARY KEY (step_id);


--
-- TOC entry 4927 (class 2606 OID 17438)
-- Name: attendance_records attendance_records_employee_id_attendance_date_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_employee_id_attendance_date_unique UNIQUE (employee_id, attendance_date);


--
-- TOC entry 4929 (class 2606 OID 17450)
-- Name: attendance_records attendance_records_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_pkey PRIMARY KEY (record_id);


--
-- TOC entry 4933 (class 2606 OID 17468)
-- Name: attendance_summaries attendance_summaries_employee_id_year_month_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_summaries
    ADD CONSTRAINT attendance_summaries_employee_id_year_month_unique UNIQUE (employee_id, year, month);


--
-- TOC entry 4935 (class 2606 OID 17475)
-- Name: attendance_summaries attendance_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_summaries
    ADD CONSTRAINT attendance_summaries_pkey PRIMARY KEY (summary_id);


--
-- TOC entry 4705 (class 2606 OID 16539)
-- Name: branch_departments branch_departments_dept_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.branch_departments
    ADD CONSTRAINT branch_departments_dept_code_unique UNIQUE (dept_code);


--
-- TOC entry 4707 (class 2606 OID 16537)
-- Name: branch_departments branch_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.branch_departments
    ADD CONSTRAINT branch_departments_pkey PRIMARY KEY (dept_id);


--
-- TOC entry 4671 (class 2606 OID 16428)
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 4668 (class 2606 OID 16420)
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 5008 (class 2606 OID 17748)
-- Name: calibration_entries calibration_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.calibration_entries
    ADD CONSTRAINT calibration_entries_pkey PRIMARY KEY (entry_id);


--
-- TOC entry 5004 (class 2606 OID 17731)
-- Name: calibration_sessions calibration_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.calibration_sessions
    ADD CONSTRAINT calibration_sessions_pkey PRIMARY KEY (session_id);


--
-- TOC entry 5340 (class 2606 OID 19459)
-- Name: cd_grievance_evidence cd_grievance_evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_grievance_evidence
    ADD CONSTRAINT cd_grievance_evidence_pkey PRIMARY KEY (evidence_id);


--
-- TOC entry 5332 (class 2606 OID 19341)
-- Name: cd_grievances cd_grievances_grievance_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_grievances
    ADD CONSTRAINT cd_grievances_grievance_no_unique UNIQUE (grievance_no);


--
-- TOC entry 5334 (class 2606 OID 19339)
-- Name: cd_grievances cd_grievances_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_grievances
    ADD CONSTRAINT cd_grievances_pkey PRIMARY KEY (grievance_id);


--
-- TOC entry 5316 (class 2606 OID 19264)
-- Name: cd_penalties cd_penalties_penalty_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_penalties
    ADD CONSTRAINT cd_penalties_penalty_no_unique UNIQUE (penalty_no);


--
-- TOC entry 5318 (class 2606 OID 19262)
-- Name: cd_penalties cd_penalties_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_penalties
    ADD CONSTRAINT cd_penalties_pkey PRIMARY KEY (penalty_id);


--
-- TOC entry 5285 (class 2606 OID 19108)
-- Name: cd_violation_types cd_violation_types_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_violation_types
    ADD CONSTRAINT cd_violation_types_code_unique UNIQUE (code);


--
-- TOC entry 5287 (class 2606 OID 19106)
-- Name: cd_violation_types cd_violation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_violation_types
    ADD CONSTRAINT cd_violation_types_pkey PRIMARY KEY (violation_type_id);


--
-- TOC entry 5065 (class 2606 OID 17980)
-- Name: certifications certifications_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT certifications_pkey PRIMARY KEY (cert_id);


--
-- TOC entry 4677 (class 2606 OID 16455)
-- Name: company_integrations company_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_integrations
    ADD CONSTRAINT company_integrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4673 (class 2606 OID 16437)
-- Name: company_profiles company_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_profiles
    ADD CONSTRAINT company_profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 4675 (class 2606 OID 16444)
-- Name: company_profiles company_profiles_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_profiles
    ADD CONSTRAINT company_profiles_user_id_unique UNIQUE (user_id);


--
-- TOC entry 4979 (class 2606 OID 17643)
-- Name: competencies competencies_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.competencies
    ADD CONSTRAINT competencies_pkey PRIMARY KEY (competency_id);


--
-- TOC entry 5237 (class 2606 OID 18750)
-- Name: compliance_frameworks compliance_frameworks_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_frameworks
    ADD CONSTRAINT compliance_frameworks_pkey PRIMARY KEY (framework_id);


--
-- TOC entry 5229 (class 2606 OID 18721)
-- Name: compliance_policies compliance_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_policies
    ADD CONSTRAINT compliance_policies_pkey PRIMARY KEY (policy_id);


--
-- TOC entry 5233 (class 2606 OID 18741)
-- Name: compliance_policy_acknowledgements compliance_policy_acknowledgements_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_policy_acknowledgements
    ADD CONSTRAINT compliance_policy_acknowledgements_pkey PRIMARY KEY (acknowledgement_id);


--
-- TOC entry 5241 (class 2606 OID 18781)
-- Name: compliance_rules compliance_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT compliance_rules_pkey PRIMARY KEY (rule_id);


--
-- TOC entry 4714 (class 2606 OID 16569)
-- Name: cost_centers cost_centers_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cost_centers
    ADD CONSTRAINT cost_centers_pkey PRIMARY KEY (cost_centre_id);


--
-- TOC entry 5022 (class 2606 OID 17800)
-- Name: course_modules course_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.course_modules
    ADD CONSTRAINT course_modules_pkey PRIMARY KEY (module_id);


--
-- TOC entry 5025 (class 2606 OID 17820)
-- Name: course_prerequisites course_prerequisites_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_pkey PRIMARY KEY (prereq_id);


--
-- TOC entry 4972 (class 2606 OID 17623)
-- Name: cycle_participants cycle_participants_cycle_id_employee_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cycle_participants
    ADD CONSTRAINT cycle_participants_cycle_id_employee_id_unique UNIQUE (cycle_id, employee_id);


--
-- TOC entry 4974 (class 2606 OID 17630)
-- Name: cycle_participants cycle_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cycle_participants
    ADD CONSTRAINT cycle_participants_pkey PRIMARY KEY (participant_id);


--
-- TOC entry 4802 (class 2606 OID 16930)
-- Name: emergency_contacts emergency_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.emergency_contacts
    ADD CONSTRAINT emergency_contacts_pkey PRIMARY KEY (contact_id);


--
-- TOC entry 4879 (class 2606 OID 17222)
-- Name: employee_change_requests employee_change_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_change_requests
    ADD CONSTRAINT employee_change_requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 4778 (class 2606 OID 16829)
-- Name: employee_contracts employee_contracts_contract_number_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_contract_number_unique UNIQUE (contract_number);


--
-- TOC entry 4780 (class 2606 OID 16827)
-- Name: employee_contracts employee_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_pkey PRIMARY KEY (contract_id);


--
-- TOC entry 4796 (class 2606 OID 16908)
-- Name: employee_documents employee_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_documents
    ADD CONSTRAINT employee_documents_pkey PRIMARY KEY (document_id);


--
-- TOC entry 5091 (class 2606 OID 18062)
-- Name: employee_export_jobs employee_export_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_export_jobs
    ADD CONSTRAINT employee_export_jobs_pkey PRIMARY KEY (export_job_id);


--
-- TOC entry 4806 (class 2606 OID 16942)
-- Name: employee_history employee_history_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_history
    ADD CONSTRAINT employee_history_pkey PRIMARY KEY (history_id);


--
-- TOC entry 4813 (class 2606 OID 16995)
-- Name: employee_operations employee_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_operations
    ADD CONSTRAINT employee_operations_pkey PRIMARY KEY (operation_id);


--
-- TOC entry 5268 (class 2606 OID 18890)
-- Name: employee_purge_logs employee_purge_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_purge_logs
    ADD CONSTRAINT employee_purge_logs_pkey PRIMARY KEY (purge_log_id);


--
-- TOC entry 5080 (class 2606 OID 18031)
-- Name: employee_skills employee_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_skills
    ADD CONSTRAINT employee_skills_pkey PRIMARY KEY (emp_skill_id);


--
-- TOC entry 4761 (class 2606 OID 16768)
-- Name: employees employees_email_work_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_email_work_unique UNIQUE (email_work);


--
-- TOC entry 4763 (class 2606 OID 16758)
-- Name: employees employees_employee_number_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_employee_number_unique UNIQUE (employee_number);


--
-- TOC entry 4769 (class 2606 OID 16765)
-- Name: employees employees_national_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_national_id_unique UNIQUE (national_id);


--
-- TOC entry 4771 (class 2606 OID 16756)
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 5376 (class 2606 OID 19588)
-- Name: eo_demotion_cases eo_demotion_cases_case_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_demotion_cases
    ADD CONSTRAINT eo_demotion_cases_case_no_unique UNIQUE (case_no);


--
-- TOC entry 5378 (class 2606 OID 19586)
-- Name: eo_demotion_cases eo_demotion_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_demotion_cases
    ADD CONSTRAINT eo_demotion_cases_pkey PRIMARY KEY (demotion_case_id);


--
-- TOC entry 5226 (class 2606 OID 18556)
-- Name: eo_settlement_access_log eo_settlement_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_settlement_access_log
    ADD CONSTRAINT eo_settlement_access_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 5219 (class 2606 OID 18528)
-- Name: eo_settlement_documents eo_settlement_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_settlement_documents
    ADD CONSTRAINT eo_settlement_documents_pkey PRIMARY KEY (settlement_id);


--
-- TOC entry 4686 (class 2606 OID 16490)
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4688 (class 2606 OID 16492)
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 4994 (class 2606 OID 17695)
-- Name: feedback_requests feedback_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.feedback_requests
    ADD CONSTRAINT feedback_requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 4999 (class 2606 OID 17714)
-- Name: feedback_responses feedback_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.feedback_responses
    ADD CONSTRAINT feedback_responses_pkey PRIMARY KEY (response_id);


--
-- TOC entry 5001 (class 2606 OID 17716)
-- Name: feedback_responses feedback_responses_request_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.feedback_responses
    ADD CONSTRAINT feedback_responses_request_id_unique UNIQUE (request_id);


--
-- TOC entry 4965 (class 2606 OID 17596)
-- Name: goal_checkins goal_checkins_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.goal_checkins
    ADD CONSTRAINT goal_checkins_pkey PRIMARY KEY (checkin_id);


--
-- TOC entry 4955 (class 2606 OID 17548)
-- Name: goals goals_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 5015 (class 2606 OID 17761)
-- Name: improvement_plans improvement_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.improvement_plans
    ADD CONSTRAINT improvement_plans_pkey PRIMARY KEY (pip_id);


--
-- TOC entry 4865 (class 2606 OID 17144)
-- Name: integration_sync_log integration_sync_log_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.integration_sync_log
    ADD CONSTRAINT integration_sync_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4684 (class 2606 OID 16480)
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4745 (class 2606 OID 16665)
-- Name: job_catalog job_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.job_catalog
    ADD CONSTRAINT job_catalog_pkey PRIMARY KEY (job_id);


--
-- TOC entry 4736 (class 2606 OID 16645)
-- Name: job_grades job_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.job_grades
    ADD CONSTRAINT job_grades_pkey PRIMARY KEY (job_grade_id);


--
-- TOC entry 4681 (class 2606 OID 16472)
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4963 (class 2606 OID 17580)
-- Name: key_results key_results_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.key_results
    ADD CONSTRAINT key_results_pkey PRIMARY KEY (kr_id);


--
-- TOC entry 4953 (class 2606 OID 17530)
-- Name: kpi_assignments kpi_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.kpi_assignments
    ADD CONSTRAINT kpi_assignments_pkey PRIMARY KEY (assignment_id);


--
-- TOC entry 4945 (class 2606 OID 17511)
-- Name: kpi_library kpi_library_kpi_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.kpi_library
    ADD CONSTRAINT kpi_library_kpi_code_unique UNIQUE (kpi_code);


--
-- TOC entry 4947 (class 2606 OID 17509)
-- Name: kpi_library kpi_library_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.kpi_library
    ADD CONSTRAINT kpi_library_pkey PRIMARY KEY (kpi_id);


--
-- TOC entry 4906 (class 2606 OID 17330)
-- Name: leave_accrual_logs leave_accrual_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_accrual_logs
    ADD CONSTRAINT leave_accrual_logs_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4916 (class 2606 OID 17392)
-- Name: leave_adjustments leave_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_adjustments
    ADD CONSTRAINT leave_adjustments_pkey PRIMARY KEY (adjustment_id);


--
-- TOC entry 4901 (class 2606 OID 17302)
-- Name: leave_balances leave_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (balance_id);


--
-- TOC entry 5290 (class 2606 OID 19118)
-- Name: leave_holiday_calendar_connections leave_holiday_calendar_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_holiday_calendar_connections
    ADD CONSTRAINT leave_holiday_calendar_connections_pkey PRIMARY KEY (connection_id);


--
-- TOC entry 5294 (class 2606 OID 19130)
-- Name: leave_holiday_sync_logs leave_holiday_sync_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_holiday_sync_logs
    ADD CONSTRAINT leave_holiday_sync_logs_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4890 (class 2606 OID 17260)
-- Name: leave_policies leave_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_policies
    ADD CONSTRAINT leave_policies_pkey PRIMARY KEY (policy_id);


--
-- TOC entry 4912 (class 2606 OID 17364)
-- Name: leave_requests leave_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 4884 (class 2606 OID 17237)
-- Name: leave_types leave_types_leave_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_leave_code_unique UNIQUE (leave_code);


--
-- TOC entry 4886 (class 2606 OID 17235)
-- Name: leave_types leave_types_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (leave_type_id);


--
-- TOC entry 5384 (class 2606 OID 19712)
-- Name: mfa_credentials mfa_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mfa_credentials
    ADD CONSTRAINT mfa_credentials_pkey PRIMARY KEY (id);


--
-- TOC entry 5389 (class 2606 OID 19727)
-- Name: mfa_recovery_codes mfa_recovery_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mfa_recovery_codes
    ADD CONSTRAINT mfa_recovery_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 4656 (class 2606 OID 16394)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4869 (class 2606 OID 17161)
-- Name: mobile_devices mobile_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_devices
    ADD CONSTRAINT mobile_devices_pkey PRIMARY KEY (device_id);


--
-- TOC entry 5193 (class 2606 OID 18427)
-- Name: mobile_saved_jobs mobile_saved_jobs_employee_id_requisition_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_saved_jobs
    ADD CONSTRAINT mobile_saved_jobs_employee_id_requisition_id_unique UNIQUE (employee_id, requisition_id);


--
-- TOC entry 5195 (class 2606 OID 18429)
-- Name: mobile_saved_jobs mobile_saved_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_saved_jobs
    ADD CONSTRAINT mobile_saved_jobs_pkey PRIMARY KEY (saved_job_id);


--
-- TOC entry 4873 (class 2606 OID 17180)
-- Name: mobile_sessions mobile_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_sessions
    ADD CONSTRAINT mobile_sessions_pkey PRIMARY KEY (session_id);


--
-- TOC entry 4839 (class 2606 OID 17065)
-- Name: notification_logs notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4841 (class 2606 OID 17074)
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (pref_id);


--
-- TOC entry 4831 (class 2606 OID 17055)
-- Name: notification_templates notification_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (template_id);


--
-- TOC entry 5204 (class 2606 OID 18467)
-- Name: onboarding_task_completions onboarding_task_completions_employee_id_template_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.onboarding_task_completions
    ADD CONSTRAINT onboarding_task_completions_employee_id_template_id_unique UNIQUE (employee_id, template_id);


--
-- TOC entry 5206 (class 2606 OID 18469)
-- Name: onboarding_task_completions onboarding_task_completions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.onboarding_task_completions
    ADD CONSTRAINT onboarding_task_completions_pkey PRIMARY KEY (completion_id);


--
-- TOC entry 5199 (class 2606 OID 18439)
-- Name: onboarding_task_templates onboarding_task_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.onboarding_task_templates
    ADD CONSTRAINT onboarding_task_templates_pkey PRIMARY KEY (template_id);


--
-- TOC entry 4701 (class 2606 OID 16517)
-- Name: organization_branches organization_branches_branch_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.organization_branches
    ADD CONSTRAINT organization_branches_branch_code_unique UNIQUE (branch_code);


--
-- TOC entry 4703 (class 2606 OID 16515)
-- Name: organization_branches organization_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.organization_branches
    ADD CONSTRAINT organization_branches_pkey PRIMARY KEY (branch_id);


--
-- TOC entry 4941 (class 2606 OID 17495)
-- Name: overtime_requests overtime_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.overtime_requests
    ADD CONSTRAINT overtime_requests_pkey PRIMARY KEY (overtime_id);


--
-- TOC entry 4665 (class 2606 OID 16413)
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 5273 (class 2606 OID 18904)
-- Name: pay_period_settings pay_period_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_period_settings
    ADD CONSTRAINT pay_period_settings_pkey PRIMARY KEY (setting_id);


--
-- TOC entry 5279 (class 2606 OID 18933)
-- Name: pay_periods pay_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_periods
    ADD CONSTRAINT pay_periods_pkey PRIMARY KEY (pay_period_id);


--
-- TOC entry 5302 (class 2606 OID 19148)
-- Name: perf_cycle_scores perf_cycle_scores_employee_id_cycle_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_cycle_scores
    ADD CONSTRAINT perf_cycle_scores_employee_id_cycle_id_unique UNIQUE (employee_id, cycle_id);


--
-- TOC entry 5304 (class 2606 OID 19150)
-- Name: perf_cycle_scores perf_cycle_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_cycle_scores
    ADD CONSTRAINT perf_cycle_scores_pkey PRIMARY KEY (cycle_score_id);


--
-- TOC entry 5297 (class 2606 OID 19139)
-- Name: perf_kpi_scores perf_kpi_scores_employee_id_cycle_id_kpi_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_kpi_scores
    ADD CONSTRAINT perf_kpi_scores_employee_id_cycle_id_kpi_id_unique UNIQUE (employee_id, cycle_id, kpi_id);


--
-- TOC entry 5299 (class 2606 OID 19141)
-- Name: perf_kpi_scores perf_kpi_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_kpi_scores
    ADD CONSTRAINT perf_kpi_scores_pkey PRIMARY KEY (score_id);


--
-- TOC entry 5306 (class 2606 OID 19157)
-- Name: perf_raise_brackets perf_raise_brackets_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_raise_brackets
    ADD CONSTRAINT perf_raise_brackets_pkey PRIMARY KEY (bracket_id);


--
-- TOC entry 5311 (class 2606 OID 19176)
-- Name: perf_raise_proposals perf_raise_proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_raise_proposals
    ADD CONSTRAINT perf_raise_proposals_pkey PRIMARY KEY (proposal_id);


--
-- TOC entry 5308 (class 2606 OID 19164)
-- Name: perf_raise_runs perf_raise_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_raise_runs
    ADD CONSTRAINT perf_raise_runs_pkey PRIMARY KEY (run_id);


--
-- TOC entry 4849 (class 2606 OID 17101)
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (permission_id);


--
-- TOC entry 4691 (class 2606 OID 16501)
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 4693 (class 2606 OID 16504)
-- Name: personal_access_tokens personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- TOC entry 5170 (class 2606 OID 18327)
-- Name: pg_bonuses pg_bonuses_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_bonuses
    ADD CONSTRAINT pg_bonuses_pkey PRIMARY KEY (bonus_id);


--
-- TOC entry 5156 (class 2606 OID 18282)
-- Name: pg_expense_claims pg_expense_claims_claim_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_expense_claims
    ADD CONSTRAINT pg_expense_claims_claim_no_unique UNIQUE (claim_no);


--
-- TOC entry 5158 (class 2606 OID 18280)
-- Name: pg_expense_claims pg_expense_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_expense_claims
    ADD CONSTRAINT pg_expense_claims_pkey PRIMARY KEY (claim_id);


--
-- TOC entry 5143 (class 2606 OID 18227)
-- Name: pg_loan_schedules pg_loan_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_loan_schedules
    ADD CONSTRAINT pg_loan_schedules_pkey PRIMARY KEY (schedule_id);


--
-- TOC entry 5115 (class 2606 OID 18152)
-- Name: pg_loans pg_loans_loan_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_loans
    ADD CONSTRAINT pg_loans_loan_no_unique UNIQUE (loan_no);


--
-- TOC entry 5117 (class 2606 OID 18150)
-- Name: pg_loans pg_loans_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_loans
    ADD CONSTRAINT pg_loans_pkey PRIMARY KEY (loan_id);


--
-- TOC entry 5181 (class 2606 OID 18367)
-- Name: pg_payroll_injections pg_payroll_injections_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_payroll_injections
    ADD CONSTRAINT pg_payroll_injections_pkey PRIMARY KEY (injection_id);


--
-- TOC entry 5183 (class 2606 OID 18365)
-- Name: pg_payroll_injections pg_payroll_injections_source_type_source_id_period_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_payroll_injections
    ADD CONSTRAINT pg_payroll_injections_source_type_source_id_period_unique UNIQUE (source_type, source_id, period);


--
-- TOC entry 4754 (class 2606 OID 16691)
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (position_id);


--
-- TOC entry 5041 (class 2606 OID 17878)
-- Name: program_cohorts program_cohorts_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_cohorts
    ADD CONSTRAINT program_cohorts_pkey PRIMARY KEY (cohort_id);


--
-- TOC entry 5036 (class 2606 OID 17861)
-- Name: program_courses program_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_courses
    ADD CONSTRAINT program_courses_pkey PRIMARY KEY (program_course_id);


--
-- TOC entry 5047 (class 2606 OID 17900)
-- Name: program_enrollments program_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_enrollments
    ADD CONSTRAINT program_enrollments_pkey PRIMARY KEY (enrollment_id);


--
-- TOC entry 5146 (class 2606 OID 18242)
-- Name: ps_payslip_access_log ps_payslip_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ps_payslip_access_log
    ADD CONSTRAINT ps_payslip_access_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 5123 (class 2606 OID 18163)
-- Name: ps_payslip_documents ps_payslip_documents_employee_id_period_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ps_payslip_documents
    ADD CONSTRAINT ps_payslip_documents_employee_id_period_unique UNIQUE (employee_id, period);


--
-- TOC entry 5125 (class 2606 OID 18165)
-- Name: ps_payslip_documents ps_payslip_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ps_payslip_documents
    ADD CONSTRAINT ps_payslip_documents_pkey PRIMARY KEY (payslip_id);


--
-- TOC entry 5173 (class 2606 OID 18356)
-- Name: rec_applications rec_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_applications
    ADD CONSTRAINT rec_applications_pkey PRIMARY KEY (application_id);


--
-- TOC entry 5175 (class 2606 OID 18354)
-- Name: rec_applications rec_applications_requisition_id_candidate_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_applications
    ADD CONSTRAINT rec_applications_requisition_id_candidate_id_unique UNIQUE (requisition_id, candidate_id);


--
-- TOC entry 5149 (class 2606 OID 18252)
-- Name: rec_candidates rec_candidates_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_candidates
    ADD CONSTRAINT rec_candidates_pkey PRIMARY KEY (candidate_id);


--
-- TOC entry 5186 (class 2606 OID 18392)
-- Name: rec_interviews rec_interviews_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_interviews
    ADD CONSTRAINT rec_interviews_pkey PRIMARY KEY (interview_id);


--
-- TOC entry 5129 (class 2606 OID 18188)
-- Name: rec_job_requisitions rec_job_requisitions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_job_requisitions
    ADD CONSTRAINT rec_job_requisitions_pkey PRIMARY KEY (requisition_id);


--
-- TOC entry 5131 (class 2606 OID 18190)
-- Name: rec_job_requisitions rec_job_requisitions_requisition_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_job_requisitions
    ADD CONSTRAINT rec_job_requisitions_requisition_no_unique UNIQUE (requisition_no);


--
-- TOC entry 5189 (class 2606 OID 18416)
-- Name: rec_offers rec_offers_application_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_offers
    ADD CONSTRAINT rec_offers_application_id_unique UNIQUE (application_id);


--
-- TOC entry 5191 (class 2606 OID 18414)
-- Name: rec_offers rec_offers_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_offers
    ADD CONSTRAINT rec_offers_pkey PRIMARY KEY (offer_id);


--
-- TOC entry 5161 (class 2606 OID 18299)
-- Name: rec_pipeline_stages rec_pipeline_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_pipeline_stages
    ADD CONSTRAINT rec_pipeline_stages_pkey PRIMARY KEY (stage_id);


--
-- TOC entry 4970 (class 2606 OID 17609)
-- Name: review_cycles review_cycles_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.review_cycles
    ADD CONSTRAINT review_cycles_pkey PRIMARY KEY (cycle_id);


--
-- TOC entry 4855 (class 2606 OID 17106)
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- TOC entry 5087 (class 2606 OID 18050)
-- Name: role_skill_requirements role_skill_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.role_skill_requirements
    ADD CONSTRAINT role_skill_requirements_pkey PRIMARY KEY (req_id);


--
-- TOC entry 4845 (class 2606 OID 17092)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 4847 (class 2606 OID 17094)
-- Name: roles roles_role_name_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_unique UNIQUE (role_name);


--
-- TOC entry 4793 (class 2606 OID 16879)
-- Name: salary salary_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.salary
    ADD CONSTRAINT salary_pkey PRIMARY KEY (salary_id);


--
-- TOC entry 5061 (class 2606 OID 17963)
-- Name: session_attendances session_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_attendances
    ADD CONSTRAINT session_attendances_pkey PRIMARY KEY (attendance_id);


--
-- TOC entry 5056 (class 2606 OID 17945)
-- Name: session_enrollments session_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_enrollments
    ADD CONSTRAINT session_enrollments_pkey PRIMARY KEY (enrollment_id);


--
-- TOC entry 5256 (class 2606 OID 18839)
-- Name: settings_billing_invoices settings_billing_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_invoices
    ADD CONSTRAINT settings_billing_invoices_pkey PRIMARY KEY (billing_invoice_id);


--
-- TOC entry 5247 (class 2606 OID 18800)
-- Name: settings_billing_plans settings_billing_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_plans
    ADD CONSTRAINT settings_billing_plans_pkey PRIMARY KEY (plan_id);


--
-- TOC entry 5251 (class 2606 OID 18821)
-- Name: settings_billing_subscriptions settings_billing_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_subscriptions
    ADD CONSTRAINT settings_billing_subscriptions_pkey PRIMARY KEY (subscription_id);


--
-- TOC entry 5264 (class 2606 OID 18873)
-- Name: settings_notification_preferences settings_notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_notification_preferences
    ADD CONSTRAINT settings_notification_preferences_pkey PRIMARY KEY (preference_id);


--
-- TOC entry 5260 (class 2606 OID 18854)
-- Name: settings_payment_methods settings_payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_payment_methods
    ADD CONSTRAINT settings_payment_methods_pkey PRIMARY KEY (payment_method_id);


--
-- TOC entry 4925 (class 2606 OID 17423)
-- Name: shift_assignments shift_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.shift_assignments
    ADD CONSTRAINT shift_assignments_pkey PRIMARY KEY (assignment_id);


--
-- TOC entry 5076 (class 2606 OID 18013)
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (skill_id);


--
-- TOC entry 5078 (class 2606 OID 18015)
-- Name: skills skills_skill_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_skill_code_unique UNIQUE (skill_code);


--
-- TOC entry 5313 (class 2606 OID 19193)
-- Name: sl_permission_policies sl_permission_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sl_permission_policies
    ADD CONSTRAINT sl_permission_policies_pkey PRIMARY KEY (policy_id);


--
-- TOC entry 5328 (class 2606 OID 19288)
-- Name: sl_permissions sl_permissions_permission_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sl_permissions
    ADD CONSTRAINT sl_permissions_permission_no_unique UNIQUE (permission_no);


--
-- TOC entry 5330 (class 2606 OID 19286)
-- Name: sl_permissions sl_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sl_permissions
    ADD CONSTRAINT sl_permissions_pkey PRIMARY KEY (permission_id);


--
-- TOC entry 5109 (class 2606 OID 18138)
-- Name: sr_generated_letters sr_generated_letters_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_generated_letters
    ADD CONSTRAINT sr_generated_letters_pkey PRIMARY KEY (letter_id);


--
-- TOC entry 5111 (class 2606 OID 18140)
-- Name: sr_generated_letters sr_generated_letters_reference_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_generated_letters
    ADD CONSTRAINT sr_generated_letters_reference_no_unique UNIQUE (reference_no);


--
-- TOC entry 5098 (class 2606 OID 18105)
-- Name: sr_letter_templates sr_letter_templates_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_letter_templates
    ADD CONSTRAINT sr_letter_templates_code_unique UNIQUE (code);


--
-- TOC entry 5100 (class 2606 OID 18103)
-- Name: sr_letter_templates sr_letter_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_letter_templates
    ADD CONSTRAINT sr_letter_templates_pkey PRIMARY KEY (template_id);


--
-- TOC entry 5094 (class 2606 OID 18089)
-- Name: sr_request_types sr_request_types_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_request_types
    ADD CONSTRAINT sr_request_types_code_unique UNIQUE (code);


--
-- TOC entry 5096 (class 2606 OID 18087)
-- Name: sr_request_types sr_request_types_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_request_types
    ADD CONSTRAINT sr_request_types_pkey PRIMARY KEY (type_id);


--
-- TOC entry 5104 (class 2606 OID 18119)
-- Name: sr_requests sr_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_requests
    ADD CONSTRAINT sr_requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 5106 (class 2606 OID 18121)
-- Name: sr_requests sr_requests_request_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_requests
    ADD CONSTRAINT sr_requests_request_no_unique UNIQUE (request_no);


--
-- TOC entry 5222 (class 2606 OID 18536)
-- Name: sso_identities sso_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sso_identities
    ADD CONSTRAINT sso_identities_pkey PRIMARY KEY (id);


--
-- TOC entry 5224 (class 2606 OID 18543)
-- Name: sso_identities sso_identities_provider_subject_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sso_identities
    ADD CONSTRAINT sso_identities_provider_subject_id_unique UNIQUE (provider, subject_id);


--
-- TOC entry 5365 (class 2606 OID 19547)
-- Name: ta_absence_records ta_absence_records_employee_id_absence_date_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_absence_records
    ADD CONSTRAINT ta_absence_records_employee_id_absence_date_unique UNIQUE (employee_id, absence_date);


--
-- TOC entry 5367 (class 2606 OID 19549)
-- Name: ta_absence_records ta_absence_records_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_absence_records
    ADD CONSTRAINT ta_absence_records_pkey PRIMARY KEY (absence_id);


--
-- TOC entry 5370 (class 2606 OID 19565)
-- Name: ta_article69_cases ta_article69_cases_case_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_article69_cases
    ADD CONSTRAINT ta_article69_cases_case_no_unique UNIQUE (case_no);


--
-- TOC entry 5372 (class 2606 OID 19561)
-- Name: ta_article69_cases ta_article69_cases_employee_id_year_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_article69_cases
    ADD CONSTRAINT ta_article69_cases_employee_id_year_unique UNIQUE (employee_id, year);


--
-- TOC entry 5374 (class 2606 OID 19563)
-- Name: ta_article69_cases ta_article69_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_article69_cases
    ADD CONSTRAINT ta_article69_cases_pkey PRIMARY KEY (case_id);


--
-- TOC entry 5361 (class 2606 OID 19539)
-- Name: ta_article69_settings ta_article69_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_article69_settings
    ADD CONSTRAINT ta_article69_settings_pkey PRIMARY KEY (settings_id);


--
-- TOC entry 5359 (class 2606 OID 19523)
-- Name: ta_attendance_exceptions ta_attendance_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_attendance_exceptions
    ADD CONSTRAINT ta_attendance_exceptions_pkey PRIMARY KEY (exception_id);


--
-- TOC entry 5348 (class 2606 OID 19489)
-- Name: ta_device_enrolments ta_device_enrolments_device_id_enrolment_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_device_enrolments
    ADD CONSTRAINT ta_device_enrolments_device_id_enrolment_id_unique UNIQUE (device_id, enrolment_id);


--
-- TOC entry 5350 (class 2606 OID 19491)
-- Name: ta_device_enrolments ta_device_enrolments_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_device_enrolments
    ADD CONSTRAINT ta_device_enrolments_pkey PRIMARY KEY (device_enrolment_id);


--
-- TOC entry 5343 (class 2606 OID 19477)
-- Name: ta_devices ta_devices_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_devices
    ADD CONSTRAINT ta_devices_code_unique UNIQUE (code);


--
-- TOC entry 5345 (class 2606 OID 19475)
-- Name: ta_devices ta_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_devices
    ADD CONSTRAINT ta_devices_pkey PRIMARY KEY (device_id);


--
-- TOC entry 5353 (class 2606 OID 19505)
-- Name: ta_raw_punches ta_raw_punches_device_id_enrolment_id_punched_at_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_raw_punches
    ADD CONSTRAINT ta_raw_punches_device_id_enrolment_id_punched_at_unique UNIQUE (device_id, enrolment_id, punched_at);


--
-- TOC entry 5355 (class 2606 OID 19507)
-- Name: ta_raw_punches ta_raw_punches_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_raw_punches
    ADD CONSTRAINT ta_raw_punches_pkey PRIMARY KEY (raw_punch_id);


--
-- TOC entry 5164 (class 2606 OID 18319)
-- Name: tal_career_paths tal_career_paths_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_career_paths
    ADD CONSTRAINT tal_career_paths_pkey PRIMARY KEY (path_id);


--
-- TOC entry 5209 (class 2606 OID 18484)
-- Name: tal_employee_criterion_progress tal_employee_criterion_progress_employee_id_criterion_id_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_employee_criterion_progress
    ADD CONSTRAINT tal_employee_criterion_progress_employee_id_criterion_id_unique UNIQUE (employee_id, criterion_id);


--
-- TOC entry 5211 (class 2606 OID 18486)
-- Name: tal_employee_criterion_progress tal_employee_criterion_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_employee_criterion_progress
    ADD CONSTRAINT tal_employee_criterion_progress_pkey PRIMARY KEY (progress_id);


--
-- TOC entry 5135 (class 2606 OID 18210)
-- Name: tal_promotion_cases tal_promotion_cases_case_no_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_cases
    ADD CONSTRAINT tal_promotion_cases_case_no_unique UNIQUE (case_no);


--
-- TOC entry 5137 (class 2606 OID 18208)
-- Name: tal_promotion_cases tal_promotion_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_cases
    ADD CONSTRAINT tal_promotion_cases_pkey PRIMARY KEY (case_id);


--
-- TOC entry 5202 (class 2606 OID 18455)
-- Name: tal_promotion_criteria tal_promotion_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_criteria
    ADD CONSTRAINT tal_promotion_criteria_pkey PRIMARY KEY (criterion_id);


--
-- TOC entry 5214 (class 2606 OID 18496)
-- Name: tal_promotion_nominations tal_promotion_nominations_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_nominations
    ADD CONSTRAINT tal_promotion_nominations_pkey PRIMARY KEY (nomination_id);


--
-- TOC entry 5217 (class 2606 OID 18509)
-- Name: tal_role_highlights tal_role_highlights_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_role_highlights
    ADD CONSTRAINT tal_role_highlights_pkey PRIMARY KEY (highlight_id);


--
-- TOC entry 5152 (class 2606 OID 18267)
-- Name: tal_succession_candidates tal_succession_candidates_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_succession_candidates
    ADD CONSTRAINT tal_succession_candidates_pkey PRIMARY KEY (succession_id);


--
-- TOC entry 5018 (class 2606 OID 17780)
-- Name: training_courses training_courses_course_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_courses
    ADD CONSTRAINT training_courses_course_code_unique UNIQUE (course_code);


--
-- TOC entry 5020 (class 2606 OID 17778)
-- Name: training_courses training_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_courses
    ADD CONSTRAINT training_courses_pkey PRIMARY KEY (course_id);


--
-- TOC entry 5070 (class 2606 OID 18000)
-- Name: training_feedbacks training_feedbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_feedbacks
    ADD CONSTRAINT training_feedbacks_pkey PRIMARY KEY (feedback_id);


--
-- TOC entry 5031 (class 2606 OID 17833)
-- Name: training_programs training_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_programs
    ADD CONSTRAINT training_programs_pkey PRIMARY KEY (program_id);


--
-- TOC entry 5033 (class 2606 OID 17835)
-- Name: training_programs training_programs_program_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_programs
    ADD CONSTRAINT training_programs_program_code_unique UNIQUE (program_code);


--
-- TOC entry 5053 (class 2606 OID 17925)
-- Name: training_sessions training_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_sessions
    ADD CONSTRAINT training_sessions_pkey PRIMARY KEY (session_id);


--
-- TOC entry 4731 (class 2606 OID 16625)
-- Name: accounting_salary uq_accounting_salary_cc_period; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.accounting_salary
    ADD CONSTRAINT uq_accounting_salary_cc_period UNIQUE (cost_centre_id, pay_period);


--
-- TOC entry 4679 (class 2606 OID 16457)
-- Name: company_integrations uq_company_integrations; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_integrations
    ADD CONSTRAINT uq_company_integrations UNIQUE (company_profile_id, integration_type);


--
-- TOC entry 5239 (class 2606 OID 18748)
-- Name: compliance_frameworks uq_compliance_frameworks_code; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_frameworks
    ADD CONSTRAINT uq_compliance_frameworks_code UNIQUE (code);


--
-- TOC entry 5235 (class 2606 OID 18739)
-- Name: compliance_policy_acknowledgements uq_compliance_policy_ack; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_policy_acknowledgements
    ADD CONSTRAINT uq_compliance_policy_ack UNIQUE (policy_id, user_id);


--
-- TOC entry 5245 (class 2606 OID 18777)
-- Name: compliance_rules uq_compliance_rules_code; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT uq_compliance_rules_code UNIQUE (code);


--
-- TOC entry 4722 (class 2606 OID 16567)
-- Name: cost_centers uq_cost_centers_code_year; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cost_centers
    ADD CONSTRAINT uq_cost_centers_code_year UNIQUE (cc_code, fiscal_year);


--
-- TOC entry 5027 (class 2606 OID 17808)
-- Name: course_prerequisites uq_course_prerequisites; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT uq_course_prerequisites UNIQUE (course_id, prerequisite_course_id);


--
-- TOC entry 5084 (class 2606 OID 18024)
-- Name: employee_skills uq_employee_skills; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_skills
    ADD CONSTRAINT uq_employee_skills UNIQUE (employee_id, skill_id);


--
-- TOC entry 4747 (class 2606 OID 16663)
-- Name: job_catalog uq_job_catalog_code; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.job_catalog
    ADD CONSTRAINT uq_job_catalog_code UNIQUE (job_code);


--
-- TOC entry 4738 (class 2606 OID 16643)
-- Name: job_grades uq_job_grades_code; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.job_grades
    ADD CONSTRAINT uq_job_grades_code UNIQUE (grade_code);


--
-- TOC entry 5386 (class 2606 OID 19719)
-- Name: mfa_credentials uq_mfa_credential_user_type; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mfa_credentials
    ADD CONSTRAINT uq_mfa_credential_user_type UNIQUE (user_id, type);


--
-- TOC entry 4843 (class 2606 OID 17072)
-- Name: notification_preferences uq_notification_pref_user_type_channel; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT uq_notification_pref_user_type_channel UNIQUE (user_id, type, channel);


--
-- TOC entry 4833 (class 2606 OID 17053)
-- Name: notification_templates uq_notification_template_type_channel; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT uq_notification_template_type_channel UNIQUE (type, channel);


--
-- TOC entry 5275 (class 2606 OID 18897)
-- Name: pay_period_settings uq_pay_period_settings_effective_from; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_period_settings
    ADD CONSTRAINT uq_pay_period_settings_effective_from UNIQUE (effective_from);


--
-- TOC entry 5281 (class 2606 OID 18914)
-- Name: pay_periods uq_pay_periods_period_code; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_periods
    ADD CONSTRAINT uq_pay_periods_period_code UNIQUE (period_code);


--
-- TOC entry 5283 (class 2606 OID 18916)
-- Name: pay_periods uq_pay_periods_range; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_periods
    ADD CONSTRAINT uq_pay_periods_range UNIQUE (start_date, end_date);


--
-- TOC entry 4851 (class 2606 OID 17099)
-- Name: permissions uq_permission_resource_action; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT uq_permission_resource_action UNIQUE (resource, action);


--
-- TOC entry 4756 (class 2606 OID 16689)
-- Name: positions uq_positions_code; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT uq_positions_code UNIQUE (position_code);


--
-- TOC entry 5043 (class 2606 OID 17871)
-- Name: program_cohorts uq_program_cohorts_name; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_cohorts
    ADD CONSTRAINT uq_program_cohorts_name UNIQUE (program_id, cohort_name);


--
-- TOC entry 5038 (class 2606 OID 17849)
-- Name: program_courses uq_program_courses; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_courses
    ADD CONSTRAINT uq_program_courses UNIQUE (program_id, course_id);


--
-- TOC entry 5049 (class 2606 OID 17888)
-- Name: program_enrollments uq_program_enrollments; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_enrollments
    ADD CONSTRAINT uq_program_enrollments UNIQUE (program_id, employee_id);


--
-- TOC entry 5089 (class 2606 OID 18043)
-- Name: role_skill_requirements uq_role_skill_requirements; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.role_skill_requirements
    ADD CONSTRAINT uq_role_skill_requirements UNIQUE (job_grade_id, skill_id);


--
-- TOC entry 5063 (class 2606 OID 17956)
-- Name: session_attendances uq_session_attendances; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_attendances
    ADD CONSTRAINT uq_session_attendances UNIQUE (session_id, employee_id);


--
-- TOC entry 5058 (class 2606 OID 17938)
-- Name: session_enrollments uq_session_enrollments; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_enrollments
    ADD CONSTRAINT uq_session_enrollments UNIQUE (session_id, employee_id);


--
-- TOC entry 5258 (class 2606 OID 18836)
-- Name: settings_billing_invoices uq_settings_billing_invoices_number; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_invoices
    ADD CONSTRAINT uq_settings_billing_invoices_number UNIQUE (invoice_number);


--
-- TOC entry 5249 (class 2606 OID 18798)
-- Name: settings_billing_plans uq_settings_billing_plans_code; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_plans
    ADD CONSTRAINT uq_settings_billing_plans_code UNIQUE (code);


--
-- TOC entry 5253 (class 2606 OID 18819)
-- Name: settings_billing_subscriptions uq_settings_billing_subscription_company; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_subscriptions
    ADD CONSTRAINT uq_settings_billing_subscription_company UNIQUE (company_profile_id);


--
-- TOC entry 5266 (class 2606 OID 18871)
-- Name: settings_notification_preferences uq_settings_notification_preference; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_notification_preferences
    ADD CONSTRAINT uq_settings_notification_preference UNIQUE (user_id, preference_key);


--
-- TOC entry 5262 (class 2606 OID 18852)
-- Name: settings_payment_methods uq_settings_payment_method_token; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_payment_methods
    ADD CONSTRAINT uq_settings_payment_method_token UNIQUE (company_profile_id, provider_token);


--
-- TOC entry 5072 (class 2606 OID 17993)
-- Name: training_feedbacks uq_training_feedbacks; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_feedbacks
    ADD CONSTRAINT uq_training_feedbacks UNIQUE (session_id, employee_id);


--
-- TOC entry 4658 (class 2606 OID 19197)
-- Name: users uq_users_employee_id; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uq_users_employee_id UNIQUE (employee_id);


--
-- TOC entry 4860 (class 2606 OID 17131)
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_role_id);


--
-- TOC entry 4660 (class 2606 OID 16406)
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- TOC entry 4663 (class 2606 OID 16404)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4919 (class 2606 OID 17404)
-- Name: work_shifts work_shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.work_shifts
    ADD CONSTRAINT work_shifts_pkey PRIMARY KEY (shift_id);


--
-- TOC entry 4921 (class 2606 OID 17406)
-- Name: work_shifts work_shifts_shift_code_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.work_shifts
    ADD CONSTRAINT work_shifts_shift_code_unique UNIQUE (shift_code);


--
-- TOC entry 4895 (class 2606 OID 17279)
-- Name: working_day_calendars working_day_calendars_calendar_date_unique; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.working_day_calendars
    ADD CONSTRAINT working_day_calendars_calendar_date_unique UNIQUE (calendar_date);


--
-- TOC entry 4897 (class 2606 OID 17277)
-- Name: working_day_calendars working_day_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.working_day_calendars
    ADD CONSTRAINT working_day_calendars_pkey PRIMARY KEY (calendar_id);


--
-- TOC entry 4666 (class 1259 OID 16421)
-- Name: cache_expiration_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX cache_expiration_index ON public.cache USING btree (expiration);


--
-- TOC entry 4669 (class 1259 OID 16429)
-- Name: cache_locks_expiration_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX cache_locks_expiration_index ON public.cache_locks USING btree (expiration);


--
-- TOC entry 4877 (class 1259 OID 17219)
-- Name: employee_change_requests_employee_id_status_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employee_change_requests_employee_id_status_index ON public.employee_change_requests USING btree (employee_id, status);


--
-- TOC entry 4880 (class 1259 OID 17220)
-- Name: employee_change_requests_status_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employee_change_requests_status_index ON public.employee_change_requests USING btree (status);


--
-- TOC entry 4757 (class 1259 OID 16759)
-- Name: employees_branch_id_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_branch_id_index ON public.employees USING btree (branch_id);


--
-- TOC entry 4758 (class 1259 OID 16766)
-- Name: employees_date_of_birth_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_date_of_birth_index ON public.employees USING btree (date_of_birth);


--
-- TOC entry 4759 (class 1259 OID 16760)
-- Name: employees_dept_id_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_dept_id_index ON public.employees USING btree (dept_id);


--
-- TOC entry 4764 (class 1259 OID 16769)
-- Name: employees_hire_date_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_hire_date_index ON public.employees USING btree (hire_date);


--
-- TOC entry 4765 (class 1259 OID 16770)
-- Name: employees_is_active_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_is_active_index ON public.employees USING btree (is_active);


--
-- TOC entry 4766 (class 1259 OID 16762)
-- Name: employees_job_grade_id_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_job_grade_id_index ON public.employees USING btree (job_grade_id);


--
-- TOC entry 4767 (class 1259 OID 16763)
-- Name: employees_manager_id_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_manager_id_index ON public.employees USING btree (manager_id);


--
-- TOC entry 4772 (class 1259 OID 16761)
-- Name: employees_position_id_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX employees_position_id_index ON public.employees USING btree (position_id);


--
-- TOC entry 4725 (class 1259 OID 16627)
-- Name: idx_acc_salary_fiscal; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_acc_salary_fiscal ON public.accounting_salary USING btree (fiscal_year, fiscal_month);


--
-- TOC entry 4726 (class 1259 OID 16626)
-- Name: idx_acc_salary_period; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_acc_salary_period ON public.accounting_salary USING btree (pay_period, cost_centre_id);


--
-- TOC entry 4727 (class 1259 OID 16628)
-- Name: idx_acc_salary_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_acc_salary_status ON public.accounting_salary USING btree (posting_status);


--
-- TOC entry 4728 (class 1259 OID 18950)
-- Name: idx_accounting_salary_pay_period_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_accounting_salary_pay_period_id ON public.accounting_salary USING btree (pay_period_id);


--
-- TOC entry 4729 (class 1259 OID 18998)
-- Name: idx_accounting_salary_posted_by_user; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_accounting_salary_posted_by_user ON public.accounting_salary USING btree (posted_by_user_id) WHERE (posted_by_user_id IS NOT NULL);


--
-- TOC entry 4903 (class 1259 OID 17332)
-- Name: idx_accrual_logs_employee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_accrual_logs_employee ON public.leave_accrual_logs USING btree (employee_id, accrual_date);


--
-- TOC entry 4904 (class 1259 OID 17333)
-- Name: idx_accrual_logs_run; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_accrual_logs_run ON public.leave_accrual_logs USING btree (run_id) WHERE (run_id IS NOT NULL);


--
-- TOC entry 4914 (class 1259 OID 17393)
-- Name: idx_adjustments_employee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_adjustments_employee ON public.leave_adjustments USING btree (employee_id, fiscal_year);


--
-- TOC entry 4991 (class 1259 OID 17681)
-- Name: idx_appraisal_ratings_appraisal_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_appraisal_ratings_appraisal_id ON public.appraisal_ratings USING btree (appraisal_id);


--
-- TOC entry 4992 (class 1259 OID 17682)
-- Name: idx_appraisal_ratings_item; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_appraisal_ratings_item ON public.appraisal_ratings USING btree (item_type, item_id);


--
-- TOC entry 4986 (class 1259 OID 17662)
-- Name: idx_appraisals_cycle_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_appraisals_cycle_id ON public.appraisals USING btree (cycle_id);


--
-- TOC entry 4987 (class 1259 OID 17663)
-- Name: idx_appraisals_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_appraisals_employee_id ON public.appraisals USING btree (employee_id);


--
-- TOC entry 4988 (class 1259 OID 17664)
-- Name: idx_appraisals_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_appraisals_status ON public.appraisals USING btree (cycle_id, status);


--
-- TOC entry 4823 (class 1259 OID 17040)
-- Name: idx_approval_requests_requested_by; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_approval_requests_requested_by ON public.approval_requests USING btree (requested_by);


--
-- TOC entry 4824 (class 1259 OID 17039)
-- Name: idx_approval_requests_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_approval_requests_status ON public.approval_requests USING btree (status);


--
-- TOC entry 4825 (class 1259 OID 17041)
-- Name: idx_approval_requests_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_approval_requests_type ON public.approval_requests USING btree (request_type);


--
-- TOC entry 4828 (class 1259 OID 17043)
-- Name: idx_approval_steps_approver_user; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_approval_steps_approver_user ON public.approval_steps USING btree (approver_user_id, status);


--
-- TOC entry 4829 (class 1259 OID 17042)
-- Name: idx_approval_steps_request_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_approval_steps_request_id ON public.approval_steps USING btree (request_id);


--
-- TOC entry 4930 (class 1259 OID 17454)
-- Name: idx_attendance_records_date; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_attendance_records_date ON public.attendance_records USING btree (attendance_date);


--
-- TOC entry 4931 (class 1259 OID 17453)
-- Name: idx_attendance_records_employee_date; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_attendance_records_employee_date ON public.attendance_records USING btree (employee_id, attendance_date);


--
-- TOC entry 4936 (class 1259 OID 17476)
-- Name: idx_attendance_summaries_employee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_attendance_summaries_employee ON public.attendance_summaries USING btree (employee_id, year, month);


--
-- TOC entry 4937 (class 1259 OID 18944)
-- Name: idx_attendance_summaries_pay_period_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_attendance_summaries_pay_period_id ON public.attendance_summaries USING btree (pay_period_id);


--
-- TOC entry 4898 (class 1259 OID 17305)
-- Name: idx_balances_employee_year; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_balances_employee_year ON public.leave_balances USING btree (employee_id, fiscal_year);


--
-- TOC entry 4899 (class 1259 OID 17306)
-- Name: idx_balances_leave_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_balances_leave_type ON public.leave_balances USING btree (leave_type_id, fiscal_year);


--
-- TOC entry 4695 (class 1259 OID 16527)
-- Name: idx_branches_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_branches_active ON public.organization_branches USING btree (is_active);


--
-- TOC entry 4696 (class 1259 OID 16526)
-- Name: idx_branches_country; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_branches_country ON public.organization_branches USING btree (country_code);


--
-- TOC entry 4697 (class 1259 OID 16524)
-- Name: idx_branches_one_head_office; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX idx_branches_one_head_office ON public.organization_branches USING btree (is_head_office) WHERE (is_head_office = true);


--
-- TOC entry 4698 (class 1259 OID 16525)
-- Name: idx_branches_parent; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_branches_parent ON public.organization_branches USING btree (parent_branch_id);


--
-- TOC entry 4699 (class 1259 OID 16528)
-- Name: idx_branches_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_branches_type ON public.organization_branches USING btree (branch_type);


--
-- TOC entry 5009 (class 1259 OID 17751)
-- Name: idx_calibration_entries_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_calibration_entries_employee_id ON public.calibration_entries USING btree (employee_id);


--
-- TOC entry 5010 (class 1259 OID 17750)
-- Name: idx_calibration_entries_session_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_calibration_entries_session_id ON public.calibration_entries USING btree (session_id);


--
-- TOC entry 5005 (class 1259 OID 17734)
-- Name: idx_calibration_sessions_cycle_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_calibration_sessions_cycle_id ON public.calibration_sessions USING btree (cycle_id);


--
-- TOC entry 5006 (class 1259 OID 17735)
-- Name: idx_calibration_sessions_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_calibration_sessions_status ON public.calibration_sessions USING btree (status);


--
-- TOC entry 5341 (class 1259 OID 19461)
-- Name: idx_cd_grievance_evidence_grievance_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_grievance_evidence_grievance_id ON public.cd_grievance_evidence USING btree (grievance_id);


--
-- TOC entry 5335 (class 1259 OID 19349)
-- Name: idx_cd_grievances_decision_due_on; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_grievances_decision_due_on ON public.cd_grievances USING btree (decision_due_on);


--
-- TOC entry 5336 (class 1259 OID 19347)
-- Name: idx_cd_grievances_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_grievances_employee_id ON public.cd_grievances USING btree (employee_id);


--
-- TOC entry 5337 (class 1259 OID 19348)
-- Name: idx_cd_grievances_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_grievances_status ON public.cd_grievances USING btree (status);


--
-- TOC entry 5319 (class 1259 OID 19269)
-- Name: idx_cd_penalties_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_penalties_employee_id ON public.cd_penalties USING btree (employee_id);


--
-- TOC entry 5320 (class 1259 OID 19271)
-- Name: idx_cd_penalties_period; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_penalties_period ON public.cd_penalties USING btree (period);


--
-- TOC entry 5321 (class 1259 OID 19270)
-- Name: idx_cd_penalties_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_penalties_status ON public.cd_penalties USING btree (status);


--
-- TOC entry 5322 (class 1259 OID 19272)
-- Name: idx_cd_penalties_violation_type_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_penalties_violation_type_id ON public.cd_penalties USING btree (violation_type_id);


--
-- TOC entry 5288 (class 1259 OID 19110)
-- Name: idx_cd_violation_types_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cd_violation_types_category ON public.cd_violation_types USING btree (category);


--
-- TOC entry 5066 (class 1259 OID 17982)
-- Name: idx_certifications_employee_expiry; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_certifications_employee_expiry ON public.certifications USING btree (employee_id, expiry_date);


--
-- TOC entry 5067 (class 1259 OID 17983)
-- Name: idx_certifications_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_certifications_status ON public.certifications USING btree (status);


--
-- TOC entry 4820 (class 1259 OID 17044)
-- Name: idx_chain_config_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_chain_config_type ON public.approval_chain_config USING btree (request_type, is_active);


--
-- TOC entry 4980 (class 1259 OID 17644)
-- Name: idx_competencies_grade_scope; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_competencies_grade_scope ON public.competencies USING btree (grade_scope);


--
-- TOC entry 4981 (class 1259 OID 17645)
-- Name: idx_competencies_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_competencies_is_active ON public.competencies USING btree (is_active);


--
-- TOC entry 5230 (class 1259 OID 18719)
-- Name: idx_compliance_policies_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_compliance_policies_category ON public.compliance_policies USING btree (category);


--
-- TOC entry 5231 (class 1259 OID 18718)
-- Name: idx_compliance_policies_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_compliance_policies_status ON public.compliance_policies USING btree (status);


--
-- TOC entry 5242 (class 1259 OID 18779)
-- Name: idx_compliance_rules_framework; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_compliance_rules_framework ON public.compliance_rules USING btree (framework_id);


--
-- TOC entry 5243 (class 1259 OID 18778)
-- Name: idx_compliance_rules_status_severity; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_compliance_rules_status_severity ON public.compliance_rules USING btree (status, severity);


--
-- TOC entry 4781 (class 1259 OID 16837)
-- Name: idx_contracts_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_contracts_employee_id ON public.employee_contracts USING btree (employee_id);


--
-- TOC entry 4782 (class 1259 OID 16839)
-- Name: idx_contracts_end_date; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_contracts_end_date ON public.employee_contracts USING btree (end_date) WHERE (((contract_status)::text = 'active'::text) AND (is_current = true));


--
-- TOC entry 4783 (class 1259 OID 16840)
-- Name: idx_contracts_is_current; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_contracts_is_current ON public.employee_contracts USING btree (employee_id, is_current) WHERE (is_current = true);


--
-- TOC entry 4784 (class 1259 OID 16838)
-- Name: idx_contracts_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_contracts_status ON public.employee_contracts USING btree (contract_status);


--
-- TOC entry 4715 (class 1259 OID 16588)
-- Name: idx_cost_centers_branch_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cost_centers_branch_id ON public.cost_centers USING btree (branch_id);


--
-- TOC entry 4716 (class 1259 OID 16591)
-- Name: idx_cost_centers_cc_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cost_centers_cc_type ON public.cost_centers USING btree (cc_type);


--
-- TOC entry 4717 (class 1259 OID 16589)
-- Name: idx_cost_centers_dept_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cost_centers_dept_id ON public.cost_centers USING btree (dept_id);


--
-- TOC entry 4718 (class 1259 OID 16590)
-- Name: idx_cost_centers_fiscal_year; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cost_centers_fiscal_year ON public.cost_centers USING btree (fiscal_year);


--
-- TOC entry 4719 (class 1259 OID 16592)
-- Name: idx_cost_centers_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cost_centers_is_active ON public.cost_centers USING btree (is_active);


--
-- TOC entry 4720 (class 1259 OID 16593)
-- Name: idx_cost_centers_parent_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cost_centers_parent_id ON public.cost_centers USING btree (parent_cc_id);


--
-- TOC entry 5023 (class 1259 OID 17801)
-- Name: idx_course_modules_course_seq; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_course_modules_course_seq ON public.course_modules USING btree (course_id, sequence_order);


--
-- TOC entry 4975 (class 1259 OID 17632)
-- Name: idx_cycle_participants_cycle_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cycle_participants_cycle_id ON public.cycle_participants USING btree (cycle_id);


--
-- TOC entry 4976 (class 1259 OID 17633)
-- Name: idx_cycle_participants_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cycle_participants_employee_id ON public.cycle_participants USING btree (employee_id);


--
-- TOC entry 4977 (class 1259 OID 17634)
-- Name: idx_cycle_participants_phase_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_cycle_participants_phase_status ON public.cycle_participants USING btree (cycle_id, phase_status);


--
-- TOC entry 4708 (class 1259 OID 16553)
-- Name: idx_departments_branch_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_departments_branch_id ON public.branch_departments USING btree (branch_id);


--
-- TOC entry 4709 (class 1259 OID 16555)
-- Name: idx_departments_cost_centre; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_departments_cost_centre ON public.branch_departments USING btree (cost_centre_id);


--
-- TOC entry 4710 (class 1259 OID 16556)
-- Name: idx_departments_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_departments_is_active ON public.branch_departments USING btree (is_active);


--
-- TOC entry 4711 (class 1259 OID 16554)
-- Name: idx_departments_parent_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_departments_parent_id ON public.branch_departments USING btree (parent_dept_id);


--
-- TOC entry 4712 (class 1259 OID 16557)
-- Name: idx_departments_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_departments_type ON public.branch_departments USING btree (dept_type);


--
-- TOC entry 4797 (class 1259 OID 16912)
-- Name: idx_documents_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_documents_employee_id ON public.employee_documents USING btree (employee_id);


--
-- TOC entry 4798 (class 1259 OID 16914)
-- Name: idx_documents_expiry; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_documents_expiry ON public.employee_documents USING btree (expiry_date) WHERE (is_active = true);


--
-- TOC entry 4799 (class 1259 OID 16915)
-- Name: idx_documents_mandatory; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_documents_mandatory ON public.employee_documents USING btree (employee_id, expiry_date) WHERE ((is_mandatory = true) AND (is_active = true));


--
-- TOC entry 4800 (class 1259 OID 16913)
-- Name: idx_documents_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_documents_type ON public.employee_documents USING btree (document_type);


--
-- TOC entry 4803 (class 1259 OID 16931)
-- Name: idx_emergency_contacts_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_emergency_contacts_employee_id ON public.emergency_contacts USING btree (employee_id);


--
-- TOC entry 4785 (class 1259 OID 19606)
-- Name: idx_employee_contracts_parent; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_employee_contracts_parent ON public.employee_contracts USING btree (parent_contract_id);


--
-- TOC entry 5081 (class 1259 OID 18036)
-- Name: idx_employee_skills_employee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_employee_skills_employee ON public.employee_skills USING btree (employee_id);


--
-- TOC entry 5082 (class 1259 OID 18035)
-- Name: idx_employee_skills_skill_level; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_employee_skills_skill_level ON public.employee_skills USING btree (skill_id, current_level);


--
-- TOC entry 4773 (class 1259 OID 16790)
-- Name: idx_employees_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_employees_active ON public.employees USING btree (hire_date) WHERE (is_active = true);


--
-- TOC entry 4774 (class 1259 OID 19243)
-- Name: idx_employees_name_ar_trgm; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_employees_name_ar_trgm ON public.employees USING gin (app.ar_normalize((((COALESCE(first_name_local, ''::character varying))::text || ' '::text) || (COALESCE(last_name_local, ''::character varying))::text)) public.gin_trgm_ops);


--
-- TOC entry 4775 (class 1259 OID 19244)
-- Name: idx_employees_name_en_trgm; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_employees_name_en_trgm ON public.employees USING gin (lower((((COALESCE(first_name, ''::character varying))::text || ' '::text) || (COALESCE(last_name, ''::character varying))::text)) public.gin_trgm_ops);


--
-- TOC entry 4776 (class 1259 OID 19245)
-- Name: idx_employees_number_normalised; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_employees_number_normalised ON public.employees USING btree (app.normalize_digits((employee_number)::text));


--
-- TOC entry 5379 (class 1259 OID 19594)
-- Name: idx_eo_demotion_cases_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_eo_demotion_cases_employee_id ON public.eo_demotion_cases USING btree (employee_id);


--
-- TOC entry 5380 (class 1259 OID 19596)
-- Name: idx_eo_demotion_cases_ground; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_eo_demotion_cases_ground ON public.eo_demotion_cases USING btree (ground);


--
-- TOC entry 5381 (class 1259 OID 19597)
-- Name: idx_eo_demotion_cases_review_due_on; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_eo_demotion_cases_review_due_on ON public.eo_demotion_cases USING btree (review_due_on);


--
-- TOC entry 5382 (class 1259 OID 19595)
-- Name: idx_eo_demotion_cases_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_eo_demotion_cases_status ON public.eo_demotion_cases USING btree (status);


--
-- TOC entry 5227 (class 1259 OID 18558)
-- Name: idx_eo_settlement_access_log_settlement_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_eo_settlement_access_log_settlement_id ON public.eo_settlement_access_log USING btree (settlement_id);


--
-- TOC entry 5220 (class 1259 OID 18529)
-- Name: idx_eo_settlement_documents_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_eo_settlement_documents_employee_id ON public.eo_settlement_documents USING btree (employee_id);


--
-- TOC entry 5269 (class 1259 OID 18887)
-- Name: idx_epl_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_epl_employee_id ON public.employee_purge_logs USING btree (employee_id);


--
-- TOC entry 5270 (class 1259 OID 18888)
-- Name: idx_epl_purged_at; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_epl_purged_at ON public.employee_purge_logs USING btree (purged_at);


--
-- TOC entry 4995 (class 1259 OID 17698)
-- Name: idx_feedback_requests_cycle_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_feedback_requests_cycle_id ON public.feedback_requests USING btree (cycle_id);


--
-- TOC entry 4996 (class 1259 OID 17700)
-- Name: idx_feedback_requests_rater; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_feedback_requests_rater ON public.feedback_requests USING btree (rater_emp_id);


--
-- TOC entry 4997 (class 1259 OID 17699)
-- Name: idx_feedback_requests_subject; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_feedback_requests_subject ON public.feedback_requests USING btree (subject_emp_id);


--
-- TOC entry 5002 (class 1259 OID 17717)
-- Name: idx_feedback_responses_request_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_feedback_responses_request_id ON public.feedback_responses USING btree (request_id);


--
-- TOC entry 4966 (class 1259 OID 17598)
-- Name: idx_goal_checkins_goal_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_goal_checkins_goal_id ON public.goal_checkins USING btree (goal_id);


--
-- TOC entry 4956 (class 1259 OID 17559)
-- Name: idx_goals_cycle_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_goals_cycle_id ON public.goals USING btree (cycle_id);


--
-- TOC entry 4957 (class 1259 OID 17562)
-- Name: idx_goals_employee_cycle; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_goals_employee_cycle ON public.goals USING btree (employee_id, cycle_id);


--
-- TOC entry 4958 (class 1259 OID 17558)
-- Name: idx_goals_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_goals_employee_id ON public.goals USING btree (employee_id);


--
-- TOC entry 4959 (class 1259 OID 17560)
-- Name: idx_goals_parent_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_goals_parent_id ON public.goals USING btree (parent_goal_id);


--
-- TOC entry 4960 (class 1259 OID 17561)
-- Name: idx_goals_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_goals_status ON public.goals USING btree (status);


--
-- TOC entry 4807 (class 1259 OID 16953)
-- Name: idx_history_action_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_history_action_type ON public.employee_history USING btree (action_type);


--
-- TOC entry 4808 (class 1259 OID 16951)
-- Name: idx_history_changed_at_desc; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_history_changed_at_desc ON public.employee_history USING btree (changed_at DESC);


--
-- TOC entry 4809 (class 1259 OID 16954)
-- Name: idx_history_changed_by; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_history_changed_by ON public.employee_history USING btree (changed_by);


--
-- TOC entry 4810 (class 1259 OID 16950)
-- Name: idx_history_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_history_employee_id ON public.employee_history USING btree (employee_id);


--
-- TOC entry 4811 (class 1259 OID 16952)
-- Name: idx_history_module_table; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_history_module_table ON public.employee_history USING btree (module_name, table_name);


--
-- TOC entry 5011 (class 1259 OID 17766)
-- Name: idx_improvement_plans_cycle_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_improvement_plans_cycle_id ON public.improvement_plans USING btree (cycle_id);


--
-- TOC entry 5012 (class 1259 OID 17764)
-- Name: idx_improvement_plans_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_improvement_plans_employee_id ON public.improvement_plans USING btree (employee_id);


--
-- TOC entry 5013 (class 1259 OID 17765)
-- Name: idx_improvement_plans_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_improvement_plans_status ON public.improvement_plans USING btree (status);


--
-- TOC entry 4861 (class 1259 OID 17147)
-- Name: idx_isl_created_at; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_isl_created_at ON public.integration_sync_log USING btree (created_at);


--
-- TOC entry 4862 (class 1259 OID 17145)
-- Name: idx_isl_integration_name; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_isl_integration_name ON public.integration_sync_log USING btree (integration_name);


--
-- TOC entry 4863 (class 1259 OID 17146)
-- Name: idx_isl_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_isl_status ON public.integration_sync_log USING btree (status);


--
-- TOC entry 4739 (class 1259 OID 16677)
-- Name: idx_job_catalog_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_catalog_category ON public.job_catalog USING btree (job_category);


--
-- TOC entry 4740 (class 1259 OID 16675)
-- Name: idx_job_catalog_family; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_catalog_family ON public.job_catalog USING btree (job_family);


--
-- TOC entry 4741 (class 1259 OID 16674)
-- Name: idx_job_catalog_grade_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_catalog_grade_id ON public.job_catalog USING btree (job_grade_id);


--
-- TOC entry 4742 (class 1259 OID 16678)
-- Name: idx_job_catalog_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_catalog_is_active ON public.job_catalog USING btree (is_active);


--
-- TOC entry 4743 (class 1259 OID 16676)
-- Name: idx_job_catalog_level; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_catalog_level ON public.job_catalog USING btree (job_level);


--
-- TOC entry 4732 (class 1259 OID 16651)
-- Name: idx_job_grades_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_grades_category ON public.job_grades USING btree (grade_category);


--
-- TOC entry 4733 (class 1259 OID 16652)
-- Name: idx_job_grades_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_grades_is_active ON public.job_grades USING btree (is_active);


--
-- TOC entry 4734 (class 1259 OID 16650)
-- Name: idx_job_grades_level; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_job_grades_level ON public.job_grades USING btree (grade_level);


--
-- TOC entry 4961 (class 1259 OID 17583)
-- Name: idx_key_results_goal_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_key_results_goal_id ON public.key_results USING btree (goal_id);


--
-- TOC entry 4948 (class 1259 OID 17535)
-- Name: idx_kpi_assignments_assignee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_kpi_assignments_assignee ON public.kpi_assignments USING btree (assignee_type, assignee_id);


--
-- TOC entry 4949 (class 1259 OID 17536)
-- Name: idx_kpi_assignments_cycle; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_kpi_assignments_cycle ON public.kpi_assignments USING btree (cycle_id);


--
-- TOC entry 4950 (class 1259 OID 17534)
-- Name: idx_kpi_assignments_kpi_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_kpi_assignments_kpi_id ON public.kpi_assignments USING btree (kpi_id);


--
-- TOC entry 4951 (class 1259 OID 18980)
-- Name: idx_kpi_assignments_pay_period_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_kpi_assignments_pay_period_id ON public.kpi_assignments USING btree (pay_period_id);


--
-- TOC entry 4942 (class 1259 OID 17514)
-- Name: idx_kpi_library_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_kpi_library_category ON public.kpi_library USING btree (category);


--
-- TOC entry 4943 (class 1259 OID 17515)
-- Name: idx_kpi_library_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_kpi_library_is_active ON public.kpi_library USING btree (is_active);


--
-- TOC entry 5292 (class 1259 OID 19133)
-- Name: idx_leave_holiday_sync_logs_synced_at; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_leave_holiday_sync_logs_synced_at ON public.leave_holiday_sync_logs USING btree (synced_at);


--
-- TOC entry 4907 (class 1259 OID 17371)
-- Name: idx_leave_requests_dates; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_leave_requests_dates ON public.leave_requests USING btree (start_date, end_date);


--
-- TOC entry 4908 (class 1259 OID 17370)
-- Name: idx_leave_requests_employee_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_leave_requests_employee_status ON public.leave_requests USING btree (employee_id, status);


--
-- TOC entry 4909 (class 1259 OID 17372)
-- Name: idx_leave_requests_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_leave_requests_status ON public.leave_requests USING btree (status);


--
-- TOC entry 4910 (class 1259 OID 17373)
-- Name: idx_leave_requests_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_leave_requests_type ON public.leave_requests USING btree (leave_type_id);


--
-- TOC entry 4881 (class 1259 OID 17240)
-- Name: idx_leave_types_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_leave_types_category ON public.leave_types USING btree (category);


--
-- TOC entry 4882 (class 1259 OID 17241)
-- Name: idx_leave_types_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_leave_types_is_active ON public.leave_types USING btree (is_active);


--
-- TOC entry 5387 (class 1259 OID 19733)
-- Name: idx_mfa_recovery_user; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_mfa_recovery_user ON public.mfa_recovery_codes USING btree (user_id);


--
-- TOC entry 4866 (class 1259 OID 17163)
-- Name: idx_mobile_devices_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_mobile_devices_employee_id ON public.mobile_devices USING btree (employee_id);


--
-- TOC entry 4867 (class 1259 OID 17164)
-- Name: idx_mobile_devices_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_mobile_devices_is_active ON public.mobile_devices USING btree (is_active);


--
-- TOC entry 4870 (class 1259 OID 17182)
-- Name: idx_mobile_sessions_device_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_mobile_sessions_device_id ON public.mobile_sessions USING btree (device_id);


--
-- TOC entry 4871 (class 1259 OID 17181)
-- Name: idx_mobile_sessions_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_mobile_sessions_employee_id ON public.mobile_sessions USING btree (employee_id);


--
-- TOC entry 4834 (class 1259 OID 17085)
-- Name: idx_notif_logs_created; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_notif_logs_created ON public.notification_logs USING btree (created_at DESC);


--
-- TOC entry 4835 (class 1259 OID 17084)
-- Name: idx_notif_logs_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_notif_logs_status ON public.notification_logs USING btree (status);


--
-- TOC entry 4836 (class 1259 OID 17082)
-- Name: idx_notif_logs_user_channel; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_notif_logs_user_channel ON public.notification_logs USING btree (user_id, channel);


--
-- TOC entry 4837 (class 1259 OID 17083)
-- Name: idx_notif_logs_user_read; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_notif_logs_user_read ON public.notification_logs USING btree (user_id, read_at);


--
-- TOC entry 5196 (class 1259 OID 18441)
-- Name: idx_onboarding_task_templates_day_milestone; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_onboarding_task_templates_day_milestone ON public.onboarding_task_templates USING btree (day_milestone);


--
-- TOC entry 5197 (class 1259 OID 18442)
-- Name: idx_onboarding_task_templates_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_onboarding_task_templates_is_active ON public.onboarding_task_templates USING btree (is_active);


--
-- TOC entry 4814 (class 1259 OID 17001)
-- Name: idx_operations_effective_date_desc; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_operations_effective_date_desc ON public.employee_operations USING btree (effective_date DESC);


--
-- TOC entry 4815 (class 1259 OID 16999)
-- Name: idx_operations_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_operations_employee_id ON public.employee_operations USING btree (employee_id);


--
-- TOC entry 4816 (class 1259 OID 17002)
-- Name: idx_operations_executed_at_desc; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_operations_executed_at_desc ON public.employee_operations USING btree (executed_at DESC) WHERE ((operation_status)::text = 'executed'::text);


--
-- TOC entry 4817 (class 1259 OID 17000)
-- Name: idx_operations_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_operations_type ON public.employee_operations USING btree (operation_type);


--
-- TOC entry 4938 (class 1259 OID 17498)
-- Name: idx_overtime_requests_employee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_overtime_requests_employee ON public.overtime_requests USING btree (employee_id);


--
-- TOC entry 4939 (class 1259 OID 17499)
-- Name: idx_overtime_requests_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_overtime_requests_status ON public.overtime_requests USING btree (status);


--
-- TOC entry 5271 (class 1259 OID 18906)
-- Name: idx_pay_period_settings_effective_from; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pay_period_settings_effective_from ON public.pay_period_settings USING btree (effective_from DESC);


--
-- TOC entry 5276 (class 1259 OID 18938)
-- Name: idx_pay_periods_dates; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pay_periods_dates ON public.pay_periods USING btree (start_date, end_date);


--
-- TOC entry 5277 (class 1259 OID 18937)
-- Name: idx_pay_periods_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pay_periods_status ON public.pay_periods USING btree (status);


--
-- TOC entry 5300 (class 1259 OID 19180)
-- Name: idx_perf_cycle_scores_cycle; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_perf_cycle_scores_cycle ON public.perf_cycle_scores USING btree (cycle_id);


--
-- TOC entry 5295 (class 1259 OID 19179)
-- Name: idx_perf_kpi_scores_cycle; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_perf_kpi_scores_cycle ON public.perf_kpi_scores USING btree (cycle_id);


--
-- TOC entry 5309 (class 1259 OID 19181)
-- Name: idx_perf_raise_proposals_run; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_perf_raise_proposals_run ON public.perf_raise_proposals USING btree (run_id);


--
-- TOC entry 5165 (class 1259 OID 18330)
-- Name: idx_pg_bonuses_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_bonuses_employee_id ON public.pg_bonuses USING btree (employee_id);


--
-- TOC entry 5166 (class 1259 OID 18962)
-- Name: idx_pg_bonuses_pay_period_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_bonuses_pay_period_id ON public.pg_bonuses USING btree (pay_period_id);


--
-- TOC entry 5167 (class 1259 OID 18331)
-- Name: idx_pg_bonuses_period; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_bonuses_period ON public.pg_bonuses USING btree (period);


--
-- TOC entry 5168 (class 1259 OID 18332)
-- Name: idx_pg_bonuses_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_bonuses_status ON public.pg_bonuses USING btree (status);


--
-- TOC entry 5153 (class 1259 OID 18286)
-- Name: idx_pg_expense_claims_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_expense_claims_employee_id ON public.pg_expense_claims USING btree (employee_id);


--
-- TOC entry 5154 (class 1259 OID 18287)
-- Name: idx_pg_expense_claims_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_expense_claims_status ON public.pg_expense_claims USING btree (status);


--
-- TOC entry 5138 (class 1259 OID 18229)
-- Name: idx_pg_loan_schedules_loan_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_loan_schedules_loan_id ON public.pg_loan_schedules USING btree (loan_id);


--
-- TOC entry 5139 (class 1259 OID 18956)
-- Name: idx_pg_loan_schedules_pay_period_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_loan_schedules_pay_period_id ON public.pg_loan_schedules USING btree (pay_period_id);


--
-- TOC entry 5140 (class 1259 OID 18230)
-- Name: idx_pg_loan_schedules_period; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_loan_schedules_period ON public.pg_loan_schedules USING btree (period);


--
-- TOC entry 5141 (class 1259 OID 18231)
-- Name: idx_pg_loan_schedules_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_loan_schedules_status ON public.pg_loan_schedules USING btree (status);


--
-- TOC entry 5112 (class 1259 OID 18155)
-- Name: idx_pg_loans_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_loans_employee_id ON public.pg_loans USING btree (employee_id);


--
-- TOC entry 5113 (class 1259 OID 18156)
-- Name: idx_pg_loans_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_loans_status ON public.pg_loans USING btree (status);


--
-- TOC entry 5176 (class 1259 OID 18371)
-- Name: idx_pg_payroll_injections_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_payroll_injections_employee_id ON public.pg_payroll_injections USING btree (employee_id);


--
-- TOC entry 5177 (class 1259 OID 18968)
-- Name: idx_pg_payroll_injections_pay_period_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_payroll_injections_pay_period_id ON public.pg_payroll_injections USING btree (pay_period_id);


--
-- TOC entry 5178 (class 1259 OID 18372)
-- Name: idx_pg_payroll_injections_period; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_payroll_injections_period ON public.pg_payroll_injections USING btree (period);


--
-- TOC entry 5179 (class 1259 OID 18373)
-- Name: idx_pg_payroll_injections_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_pg_payroll_injections_status ON public.pg_payroll_injections USING btree (status);


--
-- TOC entry 4887 (class 1259 OID 17267)
-- Name: idx_policies_leave_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_policies_leave_type ON public.leave_policies USING btree (leave_type_id);


--
-- TOC entry 4888 (class 1259 OID 17268)
-- Name: idx_policies_scope; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_policies_scope ON public.leave_policies USING btree (scope, scope_id);


--
-- TOC entry 4748 (class 1259 OID 16723)
-- Name: idx_positions_branch_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_positions_branch_id ON public.positions USING btree (branch_id);


--
-- TOC entry 4749 (class 1259 OID 16722)
-- Name: idx_positions_dept_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_positions_dept_id ON public.positions USING btree (dept_id);


--
-- TOC entry 4750 (class 1259 OID 16725)
-- Name: idx_positions_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_positions_is_active ON public.positions USING btree (is_active);


--
-- TOC entry 4751 (class 1259 OID 16724)
-- Name: idx_positions_job_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_positions_job_id ON public.positions USING btree (job_id);


--
-- TOC entry 4752 (class 1259 OID 16726)
-- Name: idx_positions_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_positions_status ON public.positions USING btree (position_status);


--
-- TOC entry 5039 (class 1259 OID 17880)
-- Name: idx_program_cohorts_program_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_program_cohorts_program_status ON public.program_cohorts USING btree (program_id, status);


--
-- TOC entry 5034 (class 1259 OID 17862)
-- Name: idx_program_courses_program_seq; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_program_courses_program_seq ON public.program_courses USING btree (program_id, sequence_order);


--
-- TOC entry 5044 (class 1259 OID 17903)
-- Name: idx_program_enrollments_employee_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_program_enrollments_employee_status ON public.program_enrollments USING btree (employee_id, status);


--
-- TOC entry 5045 (class 1259 OID 17904)
-- Name: idx_program_enrollments_program_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_program_enrollments_program_status ON public.program_enrollments USING btree (program_id, status);


--
-- TOC entry 5144 (class 1259 OID 18244)
-- Name: idx_ps_payslip_access_log_payslip_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ps_payslip_access_log_payslip_id ON public.ps_payslip_access_log USING btree (payslip_id);


--
-- TOC entry 5118 (class 1259 OID 18167)
-- Name: idx_ps_payslip_documents_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ps_payslip_documents_employee_id ON public.ps_payslip_documents USING btree (employee_id);


--
-- TOC entry 5119 (class 1259 OID 18974)
-- Name: idx_ps_payslip_documents_pay_period_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ps_payslip_documents_pay_period_id ON public.ps_payslip_documents USING btree (pay_period_id);


--
-- TOC entry 5120 (class 1259 OID 18168)
-- Name: idx_ps_payslip_documents_period; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ps_payslip_documents_period ON public.ps_payslip_documents USING btree (period);


--
-- TOC entry 5121 (class 1259 OID 18169)
-- Name: idx_ps_payslip_documents_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ps_payslip_documents_status ON public.ps_payslip_documents USING btree (status);


--
-- TOC entry 5171 (class 1259 OID 18358)
-- Name: idx_rec_applications_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_rec_applications_status ON public.rec_applications USING btree (status);


--
-- TOC entry 5147 (class 1259 OID 18254)
-- Name: idx_rec_candidates_email; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_rec_candidates_email ON public.rec_candidates USING btree (email);


--
-- TOC entry 5184 (class 1259 OID 18396)
-- Name: idx_rec_interviews_application; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_rec_interviews_application ON public.rec_interviews USING btree (application_id);


--
-- TOC entry 5187 (class 1259 OID 18418)
-- Name: idx_rec_offers_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_rec_offers_status ON public.rec_offers USING btree (status);


--
-- TOC entry 5159 (class 1259 OID 18301)
-- Name: idx_rec_pipeline_stages_requisition; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_rec_pipeline_stages_requisition ON public.rec_pipeline_stages USING btree (requisition_id);


--
-- TOC entry 5126 (class 1259 OID 18193)
-- Name: idx_rec_requisitions_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_rec_requisitions_status ON public.rec_job_requisitions USING btree (status);


--
-- TOC entry 5127 (class 1259 OID 18194)
-- Name: idx_rec_requisitions_visibility; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_rec_requisitions_visibility ON public.rec_job_requisitions USING btree (visibility);


--
-- TOC entry 4967 (class 1259 OID 17614)
-- Name: idx_review_cycles_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_review_cycles_status ON public.review_cycles USING btree (status);


--
-- TOC entry 4968 (class 1259 OID 17615)
-- Name: idx_review_cycles_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_review_cycles_type ON public.review_cycles USING btree (cycle_type);


--
-- TOC entry 4852 (class 1259 OID 17118)
-- Name: idx_role_perm_permission; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_role_perm_permission ON public.role_permissions USING btree (permission_id);


--
-- TOC entry 4853 (class 1259 OID 17117)
-- Name: idx_role_perm_role; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_role_perm_role ON public.role_permissions USING btree (role_id);


--
-- TOC entry 5085 (class 1259 OID 18052)
-- Name: idx_role_skill_req_grade; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_role_skill_req_grade ON public.role_skill_requirements USING btree (job_grade_id);


--
-- TOC entry 4787 (class 1259 OID 18997)
-- Name: idx_salary_approved_by_user; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_salary_approved_by_user ON public.salary USING btree (approved_by_user_id) WHERE (approved_by_user_id IS NOT NULL);


--
-- TOC entry 4788 (class 1259 OID 16890)
-- Name: idx_salary_cost_centre_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_salary_cost_centre_id ON public.salary USING btree (cost_centre_id);


--
-- TOC entry 4789 (class 1259 OID 16889)
-- Name: idx_salary_effective_date; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_salary_effective_date ON public.salary USING btree (effective_date);


--
-- TOC entry 4790 (class 1259 OID 16888)
-- Name: idx_salary_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_salary_employee_id ON public.salary USING btree (employee_id);


--
-- TOC entry 4791 (class 1259 OID 16891)
-- Name: idx_salary_is_current; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_salary_is_current ON public.salary USING btree (employee_id, is_current) WHERE (is_current = true);


--
-- TOC entry 5059 (class 1259 OID 17966)
-- Name: idx_session_attendances_employee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_session_attendances_employee ON public.session_attendances USING btree (employee_id);


--
-- TOC entry 5054 (class 1259 OID 17947)
-- Name: idx_session_enrollments_employee_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_session_enrollments_employee_status ON public.session_enrollments USING btree (employee_id, status);


--
-- TOC entry 5254 (class 1259 OID 18837)
-- Name: idx_settings_billing_invoices_sub_date; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_settings_billing_invoices_sub_date ON public.settings_billing_invoices USING btree (subscription_id, issued_on);


--
-- TOC entry 4922 (class 1259 OID 17425)
-- Name: idx_shift_assignments_effective; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_shift_assignments_effective ON public.shift_assignments USING btree (employee_id, effective_from, effective_to);


--
-- TOC entry 4923 (class 1259 OID 17424)
-- Name: idx_shift_assignments_employee; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_shift_assignments_employee ON public.shift_assignments USING btree (employee_id);


--
-- TOC entry 5073 (class 1259 OID 18016)
-- Name: idx_skills_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_skills_category ON public.skills USING btree (category);


--
-- TOC entry 5074 (class 1259 OID 18017)
-- Name: idx_skills_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_skills_is_active ON public.skills USING btree (is_active);


--
-- TOC entry 5323 (class 1259 OID 19294)
-- Name: idx_sl_permissions_employee_date; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sl_permissions_employee_date ON public.sl_permissions USING btree (employee_id, permission_date);


--
-- TOC entry 5324 (class 1259 OID 19291)
-- Name: idx_sl_permissions_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sl_permissions_employee_id ON public.sl_permissions USING btree (employee_id);


--
-- TOC entry 5325 (class 1259 OID 19293)
-- Name: idx_sl_permissions_period; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sl_permissions_period ON public.sl_permissions USING btree (period);


--
-- TOC entry 5326 (class 1259 OID 19292)
-- Name: idx_sl_permissions_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sl_permissions_status ON public.sl_permissions USING btree (status);


--
-- TOC entry 5107 (class 1259 OID 18141)
-- Name: idx_sr_generated_letters_request_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sr_generated_letters_request_id ON public.sr_generated_letters USING btree (request_id);


--
-- TOC entry 5092 (class 1259 OID 18091)
-- Name: idx_sr_request_types_category; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sr_request_types_category ON public.sr_request_types USING btree (category);


--
-- TOC entry 5101 (class 1259 OID 18124)
-- Name: idx_sr_requests_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sr_requests_employee_id ON public.sr_requests USING btree (employee_id);


--
-- TOC entry 5102 (class 1259 OID 18125)
-- Name: idx_sr_requests_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_sr_requests_status ON public.sr_requests USING btree (status);


--
-- TOC entry 5363 (class 1259 OID 19550)
-- Name: idx_ta_absence_records_employee_year; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ta_absence_records_employee_year ON public.ta_absence_records USING btree (employee_id, year);


--
-- TOC entry 5368 (class 1259 OID 19568)
-- Name: idx_ta_article69_cases_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ta_article69_cases_status ON public.ta_article69_cases USING btree (status);


--
-- TOC entry 5356 (class 1259 OID 19526)
-- Name: idx_ta_attendance_exceptions_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ta_attendance_exceptions_status ON public.ta_attendance_exceptions USING btree (status);


--
-- TOC entry 5357 (class 1259 OID 19527)
-- Name: idx_ta_attendance_exceptions_type; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ta_attendance_exceptions_type ON public.ta_attendance_exceptions USING btree (type);


--
-- TOC entry 5346 (class 1259 OID 19492)
-- Name: idx_ta_device_enrolments_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ta_device_enrolments_employee_id ON public.ta_device_enrolments USING btree (employee_id);


--
-- TOC entry 5351 (class 1259 OID 19509)
-- Name: idx_ta_raw_punches_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_ta_raw_punches_employee_id ON public.ta_raw_punches USING btree (employee_id);


--
-- TOC entry 5162 (class 1259 OID 18320)
-- Name: idx_tal_career_paths_from_grade_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_career_paths_from_grade_id ON public.tal_career_paths USING btree (from_grade_id);


--
-- TOC entry 5207 (class 1259 OID 18488)
-- Name: idx_tal_employee_criterion_progress_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_employee_criterion_progress_employee_id ON public.tal_employee_criterion_progress USING btree (employee_id);


--
-- TOC entry 5132 (class 1259 OID 18212)
-- Name: idx_tal_promotion_cases_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_promotion_cases_employee_id ON public.tal_promotion_cases USING btree (employee_id);


--
-- TOC entry 5133 (class 1259 OID 18213)
-- Name: idx_tal_promotion_cases_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_promotion_cases_status ON public.tal_promotion_cases USING btree (status);


--
-- TOC entry 5200 (class 1259 OID 18456)
-- Name: idx_tal_promotion_criteria_career_path_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_promotion_criteria_career_path_id ON public.tal_promotion_criteria USING btree (career_path_id);


--
-- TOC entry 5212 (class 1259 OID 18497)
-- Name: idx_tal_promotion_nominations_employee_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_promotion_nominations_employee_id ON public.tal_promotion_nominations USING btree (employee_id);


--
-- TOC entry 5215 (class 1259 OID 18510)
-- Name: idx_tal_role_highlights_operation_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_role_highlights_operation_id ON public.tal_role_highlights USING btree (operation_id);


--
-- TOC entry 5150 (class 1259 OID 18269)
-- Name: idx_tal_succession_position_id; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_tal_succession_position_id ON public.tal_succession_candidates USING btree (position_id);


--
-- TOC entry 5016 (class 1259 OID 17786)
-- Name: idx_training_courses_category_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_training_courses_category_active ON public.training_courses USING btree (category, is_active);


--
-- TOC entry 5068 (class 1259 OID 18004)
-- Name: idx_training_feedbacks_session; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_training_feedbacks_session ON public.training_feedbacks USING btree (session_id);


--
-- TOC entry 5028 (class 1259 OID 17839)
-- Name: idx_training_programs_category_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_training_programs_category_status ON public.training_programs USING btree (category, status);


--
-- TOC entry 5029 (class 1259 OID 17840)
-- Name: idx_training_programs_owner; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_training_programs_owner ON public.training_programs USING btree (owner_emp_id);


--
-- TOC entry 5050 (class 1259 OID 17930)
-- Name: idx_training_sessions_course_start; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_training_sessions_course_start ON public.training_sessions USING btree (course_id, start_datetime);


--
-- TOC entry 5051 (class 1259 OID 17931)
-- Name: idx_training_sessions_status; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_training_sessions_status ON public.training_sessions USING btree (status);


--
-- TOC entry 4856 (class 1259 OID 17129)
-- Name: idx_user_role_role; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_user_role_role ON public.user_roles USING btree (role_id);


--
-- TOC entry 4857 (class 1259 OID 17128)
-- Name: idx_user_role_user; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_user_role_user ON public.user_roles USING btree (user_id);


--
-- TOC entry 4892 (class 1259 OID 17281)
-- Name: idx_wdc_date; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_wdc_date ON public.working_day_calendars USING btree (calendar_date);


--
-- TOC entry 4893 (class 1259 OID 17282)
-- Name: idx_wdc_working; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_wdc_working ON public.working_day_calendars USING btree (is_working_day, calendar_date);


--
-- TOC entry 4917 (class 1259 OID 17407)
-- Name: idx_work_shifts_is_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX idx_work_shifts_is_active ON public.work_shifts USING btree (is_active);


--
-- TOC entry 4682 (class 1259 OID 16473)
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- TOC entry 4689 (class 1259 OID 16505)
-- Name: personal_access_tokens_expires_at_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX personal_access_tokens_expires_at_index ON public.personal_access_tokens USING btree (expires_at);


--
-- TOC entry 4694 (class 1259 OID 16502)
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- TOC entry 4902 (class 1259 OID 17304)
-- Name: uq_balance_employee_type_year; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_balance_employee_type_year ON public.leave_balances USING btree (employee_id, leave_type_id, fiscal_year);


--
-- TOC entry 5338 (class 1259 OID 19346)
-- Name: uq_cd_grievances_open_subject; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_cd_grievances_open_subject ON public.cd_grievances USING btree (subject_type, subject_id) WHERE ((subject_id IS NOT NULL) AND ((status)::text = ANY ((ARRAY['filed'::character varying, 'committee_formed'::character varying])::text[])));


--
-- TOC entry 4786 (class 1259 OID 16836)
-- Name: uq_contract_one_current; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_contract_one_current ON public.employee_contracts USING btree (employee_id) WHERE (is_current = true);


--
-- TOC entry 4804 (class 1259 OID 16932)
-- Name: uq_emergency_contacts_one_primary; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_emergency_contacts_one_primary ON public.emergency_contacts USING btree (employee_id) WHERE ((is_primary = true) AND (is_active = true));


--
-- TOC entry 5291 (class 1259 OID 19131)
-- Name: uq_leave_holiday_connection_one_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_leave_holiday_connection_one_active ON public.leave_holiday_calendar_connections USING btree (is_active) WHERE (is_active = true);


--
-- TOC entry 4913 (class 1259 OID 17369)
-- Name: uq_leave_request_no_overlap; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_leave_request_no_overlap ON public.leave_requests USING btree (employee_id, start_date, end_date) WHERE ((status)::text <> ALL ((ARRAY['rejected'::character varying, 'cancelled'::character varying])::text[]));


--
-- TOC entry 4874 (class 1259 OID 17183)
-- Name: uq_mobile_sessions_token_hash; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_mobile_sessions_token_hash ON public.mobile_sessions USING btree (token_hash);


--
-- TOC entry 4891 (class 1259 OID 17266)
-- Name: uq_policy_scope; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_policy_scope ON public.leave_policies USING btree (leave_type_id, scope, COALESCE((scope_id)::text, ''::text)) WHERE (is_active = true);


--
-- TOC entry 4794 (class 1259 OID 16887)
-- Name: uq_salary_one_current; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_salary_one_current ON public.salary USING btree (employee_id) WHERE (is_current = true);


--
-- TOC entry 5314 (class 1259 OID 19195)
-- Name: uq_sl_permission_policies_one_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_sl_permission_policies_one_active ON public.sl_permission_policies USING btree (is_active) WHERE (is_active = true);


--
-- TOC entry 5362 (class 1259 OID 19540)
-- Name: uq_ta_article69_settings_one_active; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_ta_article69_settings_one_active ON public.ta_article69_settings USING btree (is_active) WHERE (is_active = true);


--
-- TOC entry 4858 (class 1259 OID 17133)
-- Name: uq_user_role_unique; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE UNIQUE INDEX uq_user_role_unique ON public.user_roles USING btree (user_id, role_id, COALESCE(branch_id, '00000000-0000-0000-0000-000000000000'::uuid));


--
-- TOC entry 4661 (class 1259 OID 17201)
-- Name: users_employee_id_index; Type: INDEX; Schema: public; Owner: erp_user
--

CREATE INDEX users_employee_id_index ON public.users USING btree (employee_id);


--
-- TOC entry 5739 (class 2618 OID 16956)
-- Name: employee_history history_no_delete; Type: RULE; Schema: public; Owner: erp_user
--

CREATE RULE history_no_delete AS
    ON DELETE TO public.employee_history DO INSTEAD NOTHING;


--
-- TOC entry 5738 (class 2618 OID 16955)
-- Name: employee_history history_no_update; Type: RULE; Schema: public; Owner: erp_user
--

CREATE RULE history_no_update AS
    ON UPDATE TO public.employee_history DO INSTEAD NOTHING;


--
-- TOC entry 5481 (class 2606 OID 17672)
-- Name: appraisal_ratings appraisal_ratings_appraisal_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.appraisal_ratings
    ADD CONSTRAINT appraisal_ratings_appraisal_id_foreign FOREIGN KEY (appraisal_id) REFERENCES public.appraisals(appraisal_id) ON DELETE CASCADE;


--
-- TOC entry 5479 (class 2606 OID 17654)
-- Name: appraisals appraisals_cycle_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.appraisals
    ADD CONSTRAINT appraisals_cycle_id_foreign FOREIGN KEY (cycle_id) REFERENCES public.review_cycles(cycle_id) ON DELETE RESTRICT;


--
-- TOC entry 5433 (class 2606 OID 17028)
-- Name: approval_steps approval_steps_request_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.approval_steps
    ADD CONSTRAINT approval_steps_request_id_foreign FOREIGN KEY (request_id) REFERENCES public.approval_requests(request_id) ON DELETE CASCADE;


--
-- TOC entry 5465 (class 2606 OID 17439)
-- Name: attendance_records attendance_records_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5466 (class 2606 OID 17444)
-- Name: attendance_records attendance_records_shift_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_shift_id_foreign FOREIGN KEY (shift_id) REFERENCES public.work_shifts(shift_id) ON DELETE SET NULL;


--
-- TOC entry 5467 (class 2606 OID 17469)
-- Name: attendance_summaries attendance_summaries_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_summaries
    ADD CONSTRAINT attendance_summaries_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5485 (class 2606 OID 17742)
-- Name: calibration_entries calibration_entries_session_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.calibration_entries
    ADD CONSTRAINT calibration_entries_session_id_foreign FOREIGN KEY (session_id) REFERENCES public.calibration_sessions(session_id) ON DELETE CASCADE;


--
-- TOC entry 5484 (class 2606 OID 17725)
-- Name: calibration_sessions calibration_sessions_cycle_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.calibration_sessions
    ADD CONSTRAINT calibration_sessions_cycle_id_foreign FOREIGN KEY (cycle_id) REFERENCES public.review_cycles(cycle_id) ON DELETE RESTRICT;


--
-- TOC entry 5581 (class 2606 OID 19453)
-- Name: cd_grievance_evidence cd_grievance_evidence_grievance_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_grievance_evidence
    ADD CONSTRAINT cd_grievance_evidence_grievance_id_foreign FOREIGN KEY (grievance_id) REFERENCES public.cd_grievances(grievance_id) ON DELETE CASCADE;


--
-- TOC entry 5575 (class 2606 OID 19256)
-- Name: cd_penalties cd_penalties_violation_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_penalties
    ADD CONSTRAINT cd_penalties_violation_type_id_foreign FOREIGN KEY (violation_type_id) REFERENCES public.cd_violation_types(violation_type_id) ON DELETE RESTRICT;


--
-- TOC entry 5503 (class 2606 OID 17974)
-- Name: certifications certifications_course_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT certifications_course_id_foreign FOREIGN KEY (course_id) REFERENCES public.training_courses(course_id) ON DELETE RESTRICT;


--
-- TOC entry 5392 (class 2606 OID 16458)
-- Name: company_integrations company_integrations_company_profile_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_integrations
    ADD CONSTRAINT company_integrations_company_profile_id_foreign FOREIGN KEY (company_profile_id) REFERENCES public.company_profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5391 (class 2606 OID 16438)
-- Name: company_profiles company_profiles_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.company_profiles
    ADD CONSTRAINT company_profiles_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5550 (class 2606 OID 18713)
-- Name: compliance_policies compliance_policies_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_policies
    ADD CONSTRAINT compliance_policies_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5551 (class 2606 OID 18708)
-- Name: compliance_policies compliance_policies_owner_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_policies
    ADD CONSTRAINT compliance_policies_owner_employee_id_foreign FOREIGN KEY (owner_employee_id) REFERENCES public.employees(employee_id) ON DELETE SET NULL;


--
-- TOC entry 5552 (class 2606 OID 18728)
-- Name: compliance_policy_acknowledgements compliance_policy_acknowledgements_policy_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_policy_acknowledgements
    ADD CONSTRAINT compliance_policy_acknowledgements_policy_id_foreign FOREIGN KEY (policy_id) REFERENCES public.compliance_policies(policy_id) ON DELETE CASCADE;


--
-- TOC entry 5553 (class 2606 OID 18733)
-- Name: compliance_policy_acknowledgements compliance_policy_acknowledgements_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_policy_acknowledgements
    ADD CONSTRAINT compliance_policy_acknowledgements_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5554 (class 2606 OID 18771)
-- Name: compliance_rules compliance_rules_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT compliance_rules_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5555 (class 2606 OID 18761)
-- Name: compliance_rules compliance_rules_framework_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT compliance_rules_framework_id_foreign FOREIGN KEY (framework_id) REFERENCES public.compliance_frameworks(framework_id) ON DELETE SET NULL;


--
-- TOC entry 5556 (class 2606 OID 18766)
-- Name: compliance_rules compliance_rules_owner_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT compliance_rules_owner_employee_id_foreign FOREIGN KEY (owner_employee_id) REFERENCES public.employees(employee_id) ON DELETE SET NULL;


--
-- TOC entry 5488 (class 2606 OID 17794)
-- Name: course_modules course_modules_course_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.course_modules
    ADD CONSTRAINT course_modules_course_id_foreign FOREIGN KEY (course_id) REFERENCES public.training_courses(course_id) ON DELETE CASCADE;


--
-- TOC entry 5489 (class 2606 OID 17809)
-- Name: course_prerequisites course_prerequisites_course_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_course_id_foreign FOREIGN KEY (course_id) REFERENCES public.training_courses(course_id) ON DELETE CASCADE;


--
-- TOC entry 5490 (class 2606 OID 17814)
-- Name: course_prerequisites course_prerequisites_prerequisite_course_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_prerequisite_course_id_foreign FOREIGN KEY (prerequisite_course_id) REFERENCES public.training_courses(course_id) ON DELETE CASCADE;


--
-- TOC entry 5477 (class 2606 OID 17624)
-- Name: cycle_participants cycle_participants_cycle_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cycle_participants
    ADD CONSTRAINT cycle_participants_cycle_id_foreign FOREIGN KEY (cycle_id) REFERENCES public.review_cycles(cycle_id) ON DELETE RESTRICT;


--
-- TOC entry 5429 (class 2606 OID 16924)
-- Name: emergency_contacts emergency_contacts_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.emergency_contacts
    ADD CONSTRAINT emergency_contacts_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5445 (class 2606 OID 17214)
-- Name: employee_change_requests employee_change_requests_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_change_requests
    ADD CONSTRAINT employee_change_requests_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5415 (class 2606 OID 16806)
-- Name: employee_contracts employee_contracts_branch_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_branch_id_foreign FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE SET NULL;


--
-- TOC entry 5416 (class 2606 OID 16811)
-- Name: employee_contracts employee_contracts_dept_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_dept_id_foreign FOREIGN KEY (dept_id) REFERENCES public.branch_departments(dept_id) ON DELETE SET NULL;


--
-- TOC entry 5417 (class 2606 OID 16801)
-- Name: employee_contracts employee_contracts_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5418 (class 2606 OID 16821)
-- Name: employee_contracts employee_contracts_job_grade_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_job_grade_id_foreign FOREIGN KEY (job_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE SET NULL;


--
-- TOC entry 5419 (class 2606 OID 19599)
-- Name: employee_contracts employee_contracts_parent_contract_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_parent_contract_id_foreign FOREIGN KEY (parent_contract_id) REFERENCES public.employee_contracts(contract_id) ON DELETE CASCADE;


--
-- TOC entry 5420 (class 2606 OID 16816)
-- Name: employee_contracts employee_contracts_position_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT employee_contracts_position_id_foreign FOREIGN KEY (position_id) REFERENCES public.positions(position_id) ON DELETE SET NULL;


--
-- TOC entry 5427 (class 2606 OID 16902)
-- Name: employee_documents employee_documents_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_documents
    ADD CONSTRAINT employee_documents_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5431 (class 2606 OID 16989)
-- Name: employee_operations employee_operations_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_operations
    ADD CONSTRAINT employee_operations_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5562 (class 2606 OID 18882)
-- Name: employee_purge_logs employee_purge_logs_purged_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_purge_logs
    ADD CONSTRAINT employee_purge_logs_purged_by_foreign FOREIGN KEY (purged_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5507 (class 2606 OID 18025)
-- Name: employee_skills employee_skills_skill_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_skills
    ADD CONSTRAINT employee_skills_skill_id_foreign FOREIGN KEY (skill_id) REFERENCES public.skills(skill_id) ON DELETE RESTRICT;


--
-- TOC entry 5409 (class 2606 OID 16735)
-- Name: employees employees_branch_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_branch_id_foreign FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE SET NULL;


--
-- TOC entry 5410 (class 2606 OID 16740)
-- Name: employees employees_dept_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_dept_id_foreign FOREIGN KEY (dept_id) REFERENCES public.branch_departments(dept_id) ON DELETE SET NULL;


--
-- TOC entry 5411 (class 2606 OID 16750)
-- Name: employees employees_job_grade_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_job_grade_id_foreign FOREIGN KEY (job_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE SET NULL;


--
-- TOC entry 5412 (class 2606 OID 16771)
-- Name: employees employees_manager_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_manager_id_foreign FOREIGN KEY (manager_id) REFERENCES public.employees(employee_id) ON DELETE SET NULL;


--
-- TOC entry 5413 (class 2606 OID 16745)
-- Name: employees employees_position_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_position_id_foreign FOREIGN KEY (position_id) REFERENCES public.positions(position_id) ON DELETE SET NULL;


--
-- TOC entry 5592 (class 2606 OID 19580)
-- Name: eo_demotion_cases eo_demotion_cases_operation_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_demotion_cases
    ADD CONSTRAINT eo_demotion_cases_operation_id_foreign FOREIGN KEY (operation_id) REFERENCES public.employee_operations(operation_id) ON DELETE SET NULL;


--
-- TOC entry 5549 (class 2606 OID 18550)
-- Name: eo_settlement_access_log eo_settlement_access_log_settlement_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_settlement_access_log
    ADD CONSTRAINT eo_settlement_access_log_settlement_id_foreign FOREIGN KEY (settlement_id) REFERENCES public.eo_settlement_documents(settlement_id) ON DELETE CASCADE;


--
-- TOC entry 5482 (class 2606 OID 17689)
-- Name: feedback_requests feedback_requests_cycle_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.feedback_requests
    ADD CONSTRAINT feedback_requests_cycle_id_foreign FOREIGN KEY (cycle_id) REFERENCES public.review_cycles(cycle_id) ON DELETE RESTRICT;


--
-- TOC entry 5483 (class 2606 OID 17708)
-- Name: feedback_responses feedback_responses_request_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.feedback_responses
    ADD CONSTRAINT feedback_responses_request_id_foreign FOREIGN KEY (request_id) REFERENCES public.feedback_requests(request_id) ON DELETE CASCADE;


--
-- TOC entry 5399 (class 2606 OID 16619)
-- Name: accounting_salary fk_acc_salary_branch; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.accounting_salary
    ADD CONSTRAINT fk_acc_salary_branch FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE RESTRICT;


--
-- TOC entry 5400 (class 2606 OID 16609)
-- Name: accounting_salary fk_acc_salary_cost_centre; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.accounting_salary
    ADD CONSTRAINT fk_acc_salary_cost_centre FOREIGN KEY (cost_centre_id) REFERENCES public.cost_centers(cost_centre_id) ON DELETE RESTRICT;


--
-- TOC entry 5401 (class 2606 OID 16614)
-- Name: accounting_salary fk_acc_salary_dept; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.accounting_salary
    ADD CONSTRAINT fk_acc_salary_dept FOREIGN KEY (dept_id) REFERENCES public.branch_departments(dept_id) ON DELETE RESTRICT;


--
-- TOC entry 5402 (class 2606 OID 18945)
-- Name: accounting_salary fk_accounting_salary_pay_period; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.accounting_salary
    ADD CONSTRAINT fk_accounting_salary_pay_period FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5403 (class 2606 OID 18992)
-- Name: accounting_salary fk_accounting_salary_posted_by_user; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.accounting_salary
    ADD CONSTRAINT fk_accounting_salary_posted_by_user FOREIGN KEY (posted_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5480 (class 2606 OID 19375)
-- Name: appraisals fk_appraisals_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.appraisals
    ADD CONSTRAINT fk_appraisals_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5468 (class 2606 OID 18939)
-- Name: attendance_summaries fk_attendance_summaries_pay_period; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.attendance_summaries
    ADD CONSTRAINT fk_attendance_summaries_pay_period FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5393 (class 2606 OID 16519)
-- Name: organization_branches fk_branch_parent; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.organization_branches
    ADD CONSTRAINT fk_branch_parent FOREIGN KEY (parent_branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE RESTRICT;


--
-- TOC entry 5486 (class 2606 OID 19390)
-- Name: calibration_entries fk_calibration_entries_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.calibration_entries
    ADD CONSTRAINT fk_calibration_entries_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5396 (class 2606 OID 16578)
-- Name: cost_centers fk_cc_branch; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cost_centers
    ADD CONSTRAINT fk_cc_branch FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE RESTRICT;


--
-- TOC entry 5397 (class 2606 OID 16583)
-- Name: cost_centers fk_cc_dept; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cost_centers
    ADD CONSTRAINT fk_cc_dept FOREIGN KEY (dept_id) REFERENCES public.branch_departments(dept_id) ON DELETE RESTRICT;


--
-- TOC entry 5398 (class 2606 OID 16573)
-- Name: cost_centers fk_cc_parent; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cost_centers
    ADD CONSTRAINT fk_cc_parent FOREIGN KEY (parent_cc_id) REFERENCES public.cost_centers(cost_centre_id) ON DELETE RESTRICT;


--
-- TOC entry 5580 (class 2606 OID 19612)
-- Name: cd_grievances fk_cd_grievances_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_grievances
    ADD CONSTRAINT fk_cd_grievances_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5576 (class 2606 OID 19607)
-- Name: cd_penalties fk_cd_penalties_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_penalties
    ADD CONSTRAINT fk_cd_penalties_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5577 (class 2606 OID 19667)
-- Name: cd_penalties fk_cd_penalties_pay_period_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cd_penalties
    ADD CONSTRAINT fk_cd_penalties_pay_period_id FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5504 (class 2606 OID 19385)
-- Name: certifications fk_certifications_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT fk_certifications_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5478 (class 2606 OID 19395)
-- Name: cycle_participants fk_cycle_participants_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.cycle_participants
    ADD CONSTRAINT fk_cycle_participants_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5394 (class 2606 OID 16543)
-- Name: branch_departments fk_dept_branch; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.branch_departments
    ADD CONSTRAINT fk_dept_branch FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE RESTRICT;


--
-- TOC entry 5395 (class 2606 OID 16548)
-- Name: branch_departments fk_dept_parent; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.branch_departments
    ADD CONSTRAINT fk_dept_parent FOREIGN KEY (parent_dept_id) REFERENCES public.branch_departments(dept_id) ON DELETE RESTRICT;


--
-- TOC entry 5430 (class 2606 OID 19350)
-- Name: emergency_contacts fk_emergency_contacts_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.emergency_contacts
    ADD CONSTRAINT fk_emergency_contacts_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5446 (class 2606 OID 19365)
-- Name: employee_change_requests fk_employee_change_requests_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_change_requests
    ADD CONSTRAINT fk_employee_change_requests_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5421 (class 2606 OID 19203)
-- Name: employee_contracts fk_employee_contracts_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_contracts
    ADD CONSTRAINT fk_employee_contracts_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5428 (class 2606 OID 19360)
-- Name: employee_documents fk_employee_documents_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_documents
    ADD CONSTRAINT fk_employee_documents_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5432 (class 2606 OID 19238)
-- Name: employee_operations fk_employee_operations_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_operations
    ADD CONSTRAINT fk_employee_operations_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5508 (class 2606 OID 19355)
-- Name: employee_skills fk_employee_skills_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employee_skills
    ADD CONSTRAINT fk_employee_skills_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5414 (class 2606 OID 16776)
-- Name: employees fk_employees_cost_centre; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_employees_cost_centre FOREIGN KEY (cost_centre_id) REFERENCES public.cost_centers(cost_centre_id) ON DELETE SET NULL;


--
-- TOC entry 5593 (class 2606 OID 19617)
-- Name: eo_demotion_cases fk_eo_demotion_cases_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_demotion_cases
    ADD CONSTRAINT fk_eo_demotion_cases_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5547 (class 2606 OID 19233)
-- Name: eo_settlement_documents fk_eo_settlement_documents_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.eo_settlement_documents
    ADD CONSTRAINT fk_eo_settlement_documents_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5473 (class 2606 OID 19380)
-- Name: goals fk_goals_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.goals
    ADD CONSTRAINT fk_goals_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5487 (class 2606 OID 19321)
-- Name: improvement_plans fk_improvement_plans_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.improvement_plans
    ADD CONSTRAINT fk_improvement_plans_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5404 (class 2606 OID 16669)
-- Name: job_catalog fk_job_grade; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.job_catalog
    ADD CONSTRAINT fk_job_grade FOREIGN KEY (job_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE RESTRICT;


--
-- TOC entry 5471 (class 2606 OID 18975)
-- Name: kpi_assignments fk_kpi_assignments_pay_period; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.kpi_assignments
    ADD CONSTRAINT fk_kpi_assignments_pay_period FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5451 (class 2606 OID 19311)
-- Name: leave_accrual_logs fk_leave_accrual_logs_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_accrual_logs
    ADD CONSTRAINT fk_leave_accrual_logs_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5460 (class 2606 OID 19306)
-- Name: leave_adjustments fk_leave_adjustments_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_adjustments
    ADD CONSTRAINT fk_leave_adjustments_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5448 (class 2606 OID 19296)
-- Name: leave_balances fk_leave_balances_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT fk_leave_balances_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5455 (class 2606 OID 19301)
-- Name: leave_requests fk_leave_requests_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT fk_leave_requests_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5440 (class 2606 OID 19430)
-- Name: mobile_devices fk_mobile_devices_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_devices
    ADD CONSTRAINT fk_mobile_devices_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5539 (class 2606 OID 19440)
-- Name: mobile_saved_jobs fk_mobile_saved_jobs_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_saved_jobs
    ADD CONSTRAINT fk_mobile_saved_jobs_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5442 (class 2606 OID 19435)
-- Name: mobile_sessions fk_mobile_sessions_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_sessions
    ADD CONSTRAINT fk_mobile_sessions_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5541 (class 2606 OID 19370)
-- Name: onboarding_task_completions fk_onboarding_task_completions_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.onboarding_task_completions
    ADD CONSTRAINT fk_onboarding_task_completions_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5570 (class 2606 OID 19687)
-- Name: perf_cycle_scores fk_perf_cycle_scores_cycle_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_cycle_scores
    ADD CONSTRAINT fk_perf_cycle_scores_cycle_id FOREIGN KEY (cycle_id) REFERENCES public.review_cycles(cycle_id) ON DELETE RESTRICT;


--
-- TOC entry 5571 (class 2606 OID 19662)
-- Name: perf_cycle_scores fk_perf_cycle_scores_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_cycle_scores
    ADD CONSTRAINT fk_perf_cycle_scores_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5567 (class 2606 OID 19682)
-- Name: perf_kpi_scores fk_perf_kpi_scores_cycle_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_kpi_scores
    ADD CONSTRAINT fk_perf_kpi_scores_cycle_id FOREIGN KEY (cycle_id) REFERENCES public.review_cycles(cycle_id) ON DELETE RESTRICT;


--
-- TOC entry 5568 (class 2606 OID 19657)
-- Name: perf_kpi_scores fk_perf_kpi_scores_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_kpi_scores
    ADD CONSTRAINT fk_perf_kpi_scores_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5569 (class 2606 OID 19697)
-- Name: perf_kpi_scores fk_perf_kpi_scores_kpi_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_kpi_scores
    ADD CONSTRAINT fk_perf_kpi_scores_kpi_id FOREIGN KEY (kpi_id) REFERENCES public.kpi_library(kpi_id) ON DELETE RESTRICT;


--
-- TOC entry 5573 (class 2606 OID 19637)
-- Name: perf_raise_proposals fk_perf_raise_proposals_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_raise_proposals
    ADD CONSTRAINT fk_perf_raise_proposals_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5572 (class 2606 OID 19692)
-- Name: perf_raise_runs fk_perf_raise_runs_cycle_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_raise_runs
    ADD CONSTRAINT fk_perf_raise_runs_cycle_id FOREIGN KEY (cycle_id) REFERENCES public.review_cycles(cycle_id) ON DELETE RESTRICT;


--
-- TOC entry 5528 (class 2606 OID 19208)
-- Name: pg_bonuses fk_pg_bonuses_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_bonuses
    ADD CONSTRAINT fk_pg_bonuses_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5529 (class 2606 OID 18957)
-- Name: pg_bonuses fk_pg_bonuses_pay_period; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_bonuses
    ADD CONSTRAINT fk_pg_bonuses_pay_period FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5524 (class 2606 OID 19213)
-- Name: pg_expense_claims fk_pg_expense_claims_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_expense_claims
    ADD CONSTRAINT fk_pg_expense_claims_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5520 (class 2606 OID 18951)
-- Name: pg_loan_schedules fk_pg_loan_schedules_pay_period; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_loan_schedules
    ADD CONSTRAINT fk_pg_loan_schedules_pay_period FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5513 (class 2606 OID 19218)
-- Name: pg_loans fk_pg_loans_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_loans
    ADD CONSTRAINT fk_pg_loans_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5533 (class 2606 OID 19223)
-- Name: pg_payroll_injections fk_pg_payroll_injections_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_payroll_injections
    ADD CONSTRAINT fk_pg_payroll_injections_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5534 (class 2606 OID 18963)
-- Name: pg_payroll_injections fk_pg_payroll_injections_pay_period; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_payroll_injections
    ADD CONSTRAINT fk_pg_payroll_injections_pay_period FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5405 (class 2606 OID 16707)
-- Name: positions fk_positions_branch; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_positions_branch FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE RESTRICT;


--
-- TOC entry 5406 (class 2606 OID 16717)
-- Name: positions fk_positions_cost_centre; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_positions_cost_centre FOREIGN KEY (cost_centre_id) REFERENCES public.cost_centers(cost_centre_id) ON DELETE RESTRICT;


--
-- TOC entry 5407 (class 2606 OID 16702)
-- Name: positions fk_positions_dept; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_positions_dept FOREIGN KEY (dept_id) REFERENCES public.branch_departments(dept_id) ON DELETE RESTRICT;


--
-- TOC entry 5408 (class 2606 OID 16712)
-- Name: positions fk_positions_job; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_positions_job FOREIGN KEY (job_id) REFERENCES public.job_catalog(job_id) ON DELETE RESTRICT;


--
-- TOC entry 5494 (class 2606 OID 19400)
-- Name: program_enrollments fk_program_enrollments_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_enrollments
    ADD CONSTRAINT fk_program_enrollments_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5514 (class 2606 OID 19228)
-- Name: ps_payslip_documents fk_ps_payslip_documents_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ps_payslip_documents
    ADD CONSTRAINT fk_ps_payslip_documents_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5515 (class 2606 OID 18969)
-- Name: ps_payslip_documents fk_ps_payslip_documents_pay_period; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ps_payslip_documents
    ADD CONSTRAINT fk_ps_payslip_documents_pay_period FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5422 (class 2606 OID 18987)
-- Name: salary fk_salary_approved_by_user; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.salary
    ADD CONSTRAINT fk_salary_approved_by_user FOREIGN KEY (approved_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5423 (class 2606 OID 19198)
-- Name: salary fk_salary_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.salary
    ADD CONSTRAINT fk_salary_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5501 (class 2606 OID 19410)
-- Name: session_attendances fk_session_attendances_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_attendances
    ADD CONSTRAINT fk_session_attendances_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5499 (class 2606 OID 19405)
-- Name: session_enrollments fk_session_enrollments_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_enrollments
    ADD CONSTRAINT fk_session_enrollments_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5578 (class 2606 OID 19622)
-- Name: sl_permissions fk_sl_permissions_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sl_permissions
    ADD CONSTRAINT fk_sl_permissions_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5579 (class 2606 OID 19672)
-- Name: sl_permissions fk_sl_permissions_pay_period_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sl_permissions
    ADD CONSTRAINT fk_sl_permissions_pay_period_id FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5510 (class 2606 OID 19316)
-- Name: sr_requests fk_sr_requests_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_requests
    ADD CONSTRAINT fk_sr_requests_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5589 (class 2606 OID 19627)
-- Name: ta_absence_records fk_ta_absence_records_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_absence_records
    ADD CONSTRAINT fk_ta_absence_records_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5590 (class 2606 OID 19632)
-- Name: ta_article69_cases fk_ta_article69_cases_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_article69_cases
    ADD CONSTRAINT fk_ta_article69_cases_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5591 (class 2606 OID 19677)
-- Name: ta_article69_cases fk_ta_article69_cases_pay_period_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_article69_cases
    ADD CONSTRAINT fk_ta_article69_cases_pay_period_id FOREIGN KEY (pay_period_id) REFERENCES public.pay_periods(pay_period_id) ON DELETE RESTRICT;


--
-- TOC entry 5587 (class 2606 OID 19647)
-- Name: ta_attendance_exceptions fk_ta_attendance_exceptions_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_attendance_exceptions
    ADD CONSTRAINT fk_ta_attendance_exceptions_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5583 (class 2606 OID 19652)
-- Name: ta_device_enrolments fk_ta_device_enrolments_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_device_enrolments
    ADD CONSTRAINT fk_ta_device_enrolments_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5585 (class 2606 OID 19642)
-- Name: ta_raw_punches fk_ta_raw_punches_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_raw_punches
    ADD CONSTRAINT fk_ta_raw_punches_employee_id FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5543 (class 2606 OID 19420)
-- Name: tal_employee_criterion_progress fk_tal_employee_criterion_progress_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_employee_criterion_progress
    ADD CONSTRAINT fk_tal_employee_criterion_progress_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5518 (class 2606 OID 19326)
-- Name: tal_promotion_cases fk_tal_promotion_cases_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_cases
    ADD CONSTRAINT fk_tal_promotion_cases_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5545 (class 2606 OID 19425)
-- Name: tal_promotion_nominations fk_tal_promotion_nominations_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_nominations
    ADD CONSTRAINT fk_tal_promotion_nominations_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5505 (class 2606 OID 19415)
-- Name: training_feedbacks fk_training_feedbacks_employee; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_feedbacks
    ADD CONSTRAINT fk_training_feedbacks_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5436 (class 2606 OID 19009)
-- Name: user_roles fk_user_roles_assigned_by; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_user_roles_assigned_by FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5437 (class 2606 OID 19004)
-- Name: user_roles fk_user_roles_branch; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_user_roles_branch FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE CASCADE;


--
-- TOC entry 5438 (class 2606 OID 18999)
-- Name: user_roles fk_user_roles_user; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5476 (class 2606 OID 17590)
-- Name: goal_checkins goal_checkins_goal_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.goal_checkins
    ADD CONSTRAINT goal_checkins_goal_id_foreign FOREIGN KEY (goal_id) REFERENCES public.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 5474 (class 2606 OID 17549)
-- Name: goals goals_parent_goal_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.goals
    ADD CONSTRAINT goals_parent_goal_id_foreign FOREIGN KEY (parent_goal_id) REFERENCES public.goals(goal_id) ON DELETE RESTRICT;


--
-- TOC entry 5475 (class 2606 OID 17574)
-- Name: key_results key_results_goal_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.key_results
    ADD CONSTRAINT key_results_goal_id_foreign FOREIGN KEY (goal_id) REFERENCES public.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 5472 (class 2606 OID 17524)
-- Name: kpi_assignments kpi_assignments_kpi_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.kpi_assignments
    ADD CONSTRAINT kpi_assignments_kpi_id_foreign FOREIGN KEY (kpi_id) REFERENCES public.kpi_library(kpi_id) ON DELETE RESTRICT;


--
-- TOC entry 5452 (class 2606 OID 17324)
-- Name: leave_accrual_logs leave_accrual_logs_balance_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_accrual_logs
    ADD CONSTRAINT leave_accrual_logs_balance_id_foreign FOREIGN KEY (balance_id) REFERENCES public.leave_balances(balance_id) ON DELETE RESTRICT;


--
-- TOC entry 5453 (class 2606 OID 17314)
-- Name: leave_accrual_logs leave_accrual_logs_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_accrual_logs
    ADD CONSTRAINT leave_accrual_logs_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5454 (class 2606 OID 17319)
-- Name: leave_accrual_logs leave_accrual_logs_leave_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_accrual_logs
    ADD CONSTRAINT leave_accrual_logs_leave_type_id_foreign FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(leave_type_id) ON DELETE RESTRICT;


--
-- TOC entry 5461 (class 2606 OID 17381)
-- Name: leave_adjustments leave_adjustments_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_adjustments
    ADD CONSTRAINT leave_adjustments_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5462 (class 2606 OID 17386)
-- Name: leave_adjustments leave_adjustments_leave_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_adjustments
    ADD CONSTRAINT leave_adjustments_leave_type_id_foreign FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(leave_type_id) ON DELETE RESTRICT;


--
-- TOC entry 5449 (class 2606 OID 17291)
-- Name: leave_balances leave_balances_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5450 (class 2606 OID 17296)
-- Name: leave_balances leave_balances_leave_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_leave_type_id_foreign FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(leave_type_id) ON DELETE RESTRICT;


--
-- TOC entry 5447 (class 2606 OID 17254)
-- Name: leave_policies leave_policies_leave_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_policies
    ADD CONSTRAINT leave_policies_leave_type_id_foreign FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(leave_type_id) ON DELETE RESTRICT;


--
-- TOC entry 5456 (class 2606 OID 17353)
-- Name: leave_requests leave_requests_approval_request_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_approval_request_id_foreign FOREIGN KEY (approval_request_id) REFERENCES public.approval_requests(request_id) ON DELETE SET NULL;


--
-- TOC entry 5457 (class 2606 OID 17343)
-- Name: leave_requests leave_requests_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5458 (class 2606 OID 17348)
-- Name: leave_requests leave_requests_leave_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_leave_type_id_foreign FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(leave_type_id) ON DELETE RESTRICT;


--
-- TOC entry 5459 (class 2606 OID 17358)
-- Name: leave_requests leave_requests_reviewed_by_emp_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_reviewed_by_emp_id_foreign FOREIGN KEY (reviewed_by_emp_id) REFERENCES public.employees(employee_id) ON DELETE SET NULL;


--
-- TOC entry 5594 (class 2606 OID 19713)
-- Name: mfa_credentials mfa_credentials_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mfa_credentials
    ADD CONSTRAINT mfa_credentials_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5595 (class 2606 OID 19728)
-- Name: mfa_recovery_codes mfa_recovery_codes_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mfa_recovery_codes
    ADD CONSTRAINT mfa_recovery_codes_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5441 (class 2606 OID 17155)
-- Name: mobile_devices mobile_devices_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_devices
    ADD CONSTRAINT mobile_devices_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5443 (class 2606 OID 17174)
-- Name: mobile_sessions mobile_sessions_device_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_sessions
    ADD CONSTRAINT mobile_sessions_device_id_foreign FOREIGN KEY (device_id) REFERENCES public.mobile_devices(device_id) ON DELETE CASCADE;


--
-- TOC entry 5444 (class 2606 OID 17169)
-- Name: mobile_sessions mobile_sessions_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.mobile_sessions
    ADD CONSTRAINT mobile_sessions_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5542 (class 2606 OID 18461)
-- Name: onboarding_task_completions onboarding_task_completions_template_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.onboarding_task_completions
    ADD CONSTRAINT onboarding_task_completions_template_id_foreign FOREIGN KEY (template_id) REFERENCES public.onboarding_task_templates(template_id) ON DELETE CASCADE;


--
-- TOC entry 5469 (class 2606 OID 17489)
-- Name: overtime_requests overtime_requests_attendance_record_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.overtime_requests
    ADD CONSTRAINT overtime_requests_attendance_record_id_foreign FOREIGN KEY (attendance_record_id) REFERENCES public.attendance_records(record_id) ON DELETE SET NULL;


--
-- TOC entry 5470 (class 2606 OID 17484)
-- Name: overtime_requests overtime_requests_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.overtime_requests
    ADD CONSTRAINT overtime_requests_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5563 (class 2606 OID 18898)
-- Name: pay_period_settings pay_period_settings_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_period_settings
    ADD CONSTRAINT pay_period_settings_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5564 (class 2606 OID 18922)
-- Name: pay_periods pay_periods_closed_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_periods
    ADD CONSTRAINT pay_periods_closed_by_foreign FOREIGN KEY (closed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5565 (class 2606 OID 18927)
-- Name: pay_periods pay_periods_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_periods
    ADD CONSTRAINT pay_periods_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5566 (class 2606 OID 18917)
-- Name: pay_periods pay_periods_setting_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pay_periods
    ADD CONSTRAINT pay_periods_setting_id_foreign FOREIGN KEY (setting_id) REFERENCES public.pay_period_settings(setting_id) ON DELETE RESTRICT;


--
-- TOC entry 5574 (class 2606 OID 19170)
-- Name: perf_raise_proposals perf_raise_proposals_run_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.perf_raise_proposals
    ADD CONSTRAINT perf_raise_proposals_run_id_foreign FOREIGN KEY (run_id) REFERENCES public.perf_raise_runs(run_id) ON DELETE CASCADE;


--
-- TOC entry 5521 (class 2606 OID 18221)
-- Name: pg_loan_schedules pg_loan_schedules_loan_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.pg_loan_schedules
    ADD CONSTRAINT pg_loan_schedules_loan_id_foreign FOREIGN KEY (loan_id) REFERENCES public.pg_loans(loan_id) ON DELETE RESTRICT;


--
-- TOC entry 5493 (class 2606 OID 17872)
-- Name: program_cohorts program_cohorts_program_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_cohorts
    ADD CONSTRAINT program_cohorts_program_id_foreign FOREIGN KEY (program_id) REFERENCES public.training_programs(program_id) ON DELETE CASCADE;


--
-- TOC entry 5491 (class 2606 OID 17855)
-- Name: program_courses program_courses_course_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_courses
    ADD CONSTRAINT program_courses_course_id_foreign FOREIGN KEY (course_id) REFERENCES public.training_courses(course_id) ON DELETE RESTRICT;


--
-- TOC entry 5492 (class 2606 OID 17850)
-- Name: program_courses program_courses_program_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_courses
    ADD CONSTRAINT program_courses_program_id_foreign FOREIGN KEY (program_id) REFERENCES public.training_programs(program_id) ON DELETE CASCADE;


--
-- TOC entry 5495 (class 2606 OID 17894)
-- Name: program_enrollments program_enrollments_cohort_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_enrollments
    ADD CONSTRAINT program_enrollments_cohort_id_foreign FOREIGN KEY (cohort_id) REFERENCES public.program_cohorts(cohort_id) ON DELETE SET NULL;


--
-- TOC entry 5496 (class 2606 OID 17889)
-- Name: program_enrollments program_enrollments_program_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.program_enrollments
    ADD CONSTRAINT program_enrollments_program_id_foreign FOREIGN KEY (program_id) REFERENCES public.training_programs(program_id) ON DELETE RESTRICT;


--
-- TOC entry 5522 (class 2606 OID 18236)
-- Name: ps_payslip_access_log ps_payslip_access_log_payslip_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ps_payslip_access_log
    ADD CONSTRAINT ps_payslip_access_log_payslip_id_foreign FOREIGN KEY (payslip_id) REFERENCES public.ps_payslip_documents(payslip_id) ON DELETE CASCADE;


--
-- TOC entry 5530 (class 2606 OID 18343)
-- Name: rec_applications rec_applications_candidate_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_applications
    ADD CONSTRAINT rec_applications_candidate_id_foreign FOREIGN KEY (candidate_id) REFERENCES public.rec_candidates(candidate_id) ON DELETE RESTRICT;


--
-- TOC entry 5531 (class 2606 OID 18348)
-- Name: rec_applications rec_applications_current_stage_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_applications
    ADD CONSTRAINT rec_applications_current_stage_id_foreign FOREIGN KEY (current_stage_id) REFERENCES public.rec_pipeline_stages(stage_id) ON DELETE RESTRICT;


--
-- TOC entry 5532 (class 2606 OID 18338)
-- Name: rec_applications rec_applications_requisition_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_applications
    ADD CONSTRAINT rec_applications_requisition_id_foreign FOREIGN KEY (requisition_id) REFERENCES public.rec_job_requisitions(requisition_id) ON DELETE RESTRICT;


--
-- TOC entry 5535 (class 2606 OID 18381)
-- Name: rec_interviews rec_interviews_application_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_interviews
    ADD CONSTRAINT rec_interviews_application_id_foreign FOREIGN KEY (application_id) REFERENCES public.rec_applications(application_id) ON DELETE RESTRICT;


--
-- TOC entry 5536 (class 2606 OID 18386)
-- Name: rec_interviews rec_interviews_stage_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_interviews
    ADD CONSTRAINT rec_interviews_stage_id_foreign FOREIGN KEY (stage_id) REFERENCES public.rec_pipeline_stages(stage_id) ON DELETE RESTRICT;


--
-- TOC entry 5516 (class 2606 OID 18182)
-- Name: rec_job_requisitions rec_job_requisitions_dept_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_job_requisitions
    ADD CONSTRAINT rec_job_requisitions_dept_id_foreign FOREIGN KEY (dept_id) REFERENCES public.branch_departments(dept_id) ON DELETE SET NULL;


--
-- TOC entry 5517 (class 2606 OID 18177)
-- Name: rec_job_requisitions rec_job_requisitions_job_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_job_requisitions
    ADD CONSTRAINT rec_job_requisitions_job_id_foreign FOREIGN KEY (job_id) REFERENCES public.job_catalog(job_id) ON DELETE RESTRICT;


--
-- TOC entry 5537 (class 2606 OID 18403)
-- Name: rec_offers rec_offers_application_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_offers
    ADD CONSTRAINT rec_offers_application_id_foreign FOREIGN KEY (application_id) REFERENCES public.rec_applications(application_id) ON DELETE RESTRICT;


--
-- TOC entry 5538 (class 2606 OID 18408)
-- Name: rec_offers rec_offers_offered_grade_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_offers
    ADD CONSTRAINT rec_offers_offered_grade_id_foreign FOREIGN KEY (offered_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE RESTRICT;


--
-- TOC entry 5525 (class 2606 OID 18293)
-- Name: rec_pipeline_stages rec_pipeline_stages_requisition_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.rec_pipeline_stages
    ADD CONSTRAINT rec_pipeline_stages_requisition_id_foreign FOREIGN KEY (requisition_id) REFERENCES public.rec_job_requisitions(requisition_id) ON DELETE CASCADE;


--
-- TOC entry 5434 (class 2606 OID 17112)
-- Name: role_permissions role_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES public.permissions(permission_id) ON DELETE CASCADE;


--
-- TOC entry 5435 (class 2606 OID 17107)
-- Name: role_permissions role_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- TOC entry 5509 (class 2606 OID 18044)
-- Name: role_skill_requirements role_skill_requirements_skill_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.role_skill_requirements
    ADD CONSTRAINT role_skill_requirements_skill_id_foreign FOREIGN KEY (skill_id) REFERENCES public.skills(skill_id) ON DELETE RESTRICT;


--
-- TOC entry 5424 (class 2606 OID 16873)
-- Name: salary salary_cost_centre_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.salary
    ADD CONSTRAINT salary_cost_centre_id_foreign FOREIGN KEY (cost_centre_id) REFERENCES public.cost_centers(cost_centre_id) ON DELETE SET NULL;


--
-- TOC entry 5425 (class 2606 OID 16863)
-- Name: salary salary_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.salary
    ADD CONSTRAINT salary_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- TOC entry 5426 (class 2606 OID 16868)
-- Name: salary salary_job_grade_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.salary
    ADD CONSTRAINT salary_job_grade_id_foreign FOREIGN KEY (job_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE SET NULL;


--
-- TOC entry 5502 (class 2606 OID 17957)
-- Name: session_attendances session_attendances_session_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_attendances
    ADD CONSTRAINT session_attendances_session_id_foreign FOREIGN KEY (session_id) REFERENCES public.training_sessions(session_id) ON DELETE CASCADE;


--
-- TOC entry 5500 (class 2606 OID 17939)
-- Name: session_enrollments session_enrollments_session_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.session_enrollments
    ADD CONSTRAINT session_enrollments_session_id_foreign FOREIGN KEY (session_id) REFERENCES public.training_sessions(session_id) ON DELETE CASCADE;


--
-- TOC entry 5559 (class 2606 OID 18830)
-- Name: settings_billing_invoices settings_billing_invoices_subscription_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_invoices
    ADD CONSTRAINT settings_billing_invoices_subscription_id_foreign FOREIGN KEY (subscription_id) REFERENCES public.settings_billing_subscriptions(subscription_id) ON DELETE CASCADE;


--
-- TOC entry 5557 (class 2606 OID 18808)
-- Name: settings_billing_subscriptions settings_billing_subscriptions_company_profile_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_subscriptions
    ADD CONSTRAINT settings_billing_subscriptions_company_profile_id_foreign FOREIGN KEY (company_profile_id) REFERENCES public.company_profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5558 (class 2606 OID 18813)
-- Name: settings_billing_subscriptions settings_billing_subscriptions_plan_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_billing_subscriptions
    ADD CONSTRAINT settings_billing_subscriptions_plan_id_foreign FOREIGN KEY (plan_id) REFERENCES public.settings_billing_plans(plan_id) ON DELETE RESTRICT;


--
-- TOC entry 5561 (class 2606 OID 18865)
-- Name: settings_notification_preferences settings_notification_preferences_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_notification_preferences
    ADD CONSTRAINT settings_notification_preferences_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5560 (class 2606 OID 18846)
-- Name: settings_payment_methods settings_payment_methods_company_profile_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.settings_payment_methods
    ADD CONSTRAINT settings_payment_methods_company_profile_id_foreign FOREIGN KEY (company_profile_id) REFERENCES public.company_profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5463 (class 2606 OID 17412)
-- Name: shift_assignments shift_assignments_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.shift_assignments
    ADD CONSTRAINT shift_assignments_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 5464 (class 2606 OID 17417)
-- Name: shift_assignments shift_assignments_shift_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.shift_assignments
    ADD CONSTRAINT shift_assignments_shift_id_foreign FOREIGN KEY (shift_id) REFERENCES public.work_shifts(shift_id) ON DELETE CASCADE;


--
-- TOC entry 5512 (class 2606 OID 18132)
-- Name: sr_generated_letters sr_generated_letters_template_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_generated_letters
    ADD CONSTRAINT sr_generated_letters_template_id_foreign FOREIGN KEY (template_id) REFERENCES public.sr_letter_templates(template_id) ON DELETE RESTRICT;


--
-- TOC entry 5511 (class 2606 OID 18113)
-- Name: sr_requests sr_requests_request_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sr_requests
    ADD CONSTRAINT sr_requests_request_type_id_foreign FOREIGN KEY (request_type_id) REFERENCES public.sr_request_types(type_id) ON DELETE RESTRICT;


--
-- TOC entry 5548 (class 2606 OID 18537)
-- Name: sso_identities sso_identities_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.sso_identities
    ADD CONSTRAINT sso_identities_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5588 (class 2606 OID 19517)
-- Name: ta_attendance_exceptions ta_attendance_exceptions_device_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_attendance_exceptions
    ADD CONSTRAINT ta_attendance_exceptions_device_id_foreign FOREIGN KEY (device_id) REFERENCES public.ta_devices(device_id) ON DELETE SET NULL;


--
-- TOC entry 5584 (class 2606 OID 19483)
-- Name: ta_device_enrolments ta_device_enrolments_device_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_device_enrolments
    ADD CONSTRAINT ta_device_enrolments_device_id_foreign FOREIGN KEY (device_id) REFERENCES public.ta_devices(device_id) ON DELETE CASCADE;


--
-- TOC entry 5582 (class 2606 OID 19469)
-- Name: ta_devices ta_devices_branch_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_devices
    ADD CONSTRAINT ta_devices_branch_id_foreign FOREIGN KEY (branch_id) REFERENCES public.organization_branches(branch_id) ON DELETE SET NULL;


--
-- TOC entry 5586 (class 2606 OID 19499)
-- Name: ta_raw_punches ta_raw_punches_device_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.ta_raw_punches
    ADD CONSTRAINT ta_raw_punches_device_id_foreign FOREIGN KEY (device_id) REFERENCES public.ta_devices(device_id) ON DELETE CASCADE;


--
-- TOC entry 5526 (class 2606 OID 18308)
-- Name: tal_career_paths tal_career_paths_from_grade_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_career_paths
    ADD CONSTRAINT tal_career_paths_from_grade_id_foreign FOREIGN KEY (from_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE RESTRICT;


--
-- TOC entry 5527 (class 2606 OID 18313)
-- Name: tal_career_paths tal_career_paths_to_grade_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_career_paths
    ADD CONSTRAINT tal_career_paths_to_grade_id_foreign FOREIGN KEY (to_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE RESTRICT;


--
-- TOC entry 5544 (class 2606 OID 18478)
-- Name: tal_employee_criterion_progress tal_employee_criterion_progress_criterion_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_employee_criterion_progress
    ADD CONSTRAINT tal_employee_criterion_progress_criterion_id_foreign FOREIGN KEY (criterion_id) REFERENCES public.tal_promotion_criteria(criterion_id) ON DELETE CASCADE;


--
-- TOC entry 5519 (class 2606 OID 18202)
-- Name: tal_promotion_cases tal_promotion_cases_proposed_grade_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_cases
    ADD CONSTRAINT tal_promotion_cases_proposed_grade_id_foreign FOREIGN KEY (proposed_grade_id) REFERENCES public.job_grades(job_grade_id) ON DELETE RESTRICT;


--
-- TOC entry 5540 (class 2606 OID 18449)
-- Name: tal_promotion_criteria tal_promotion_criteria_career_path_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_promotion_criteria
    ADD CONSTRAINT tal_promotion_criteria_career_path_id_foreign FOREIGN KEY (career_path_id) REFERENCES public.tal_career_paths(path_id) ON DELETE CASCADE;


--
-- TOC entry 5546 (class 2606 OID 18503)
-- Name: tal_role_highlights tal_role_highlights_operation_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_role_highlights
    ADD CONSTRAINT tal_role_highlights_operation_id_foreign FOREIGN KEY (operation_id) REFERENCES public.employee_operations(operation_id) ON DELETE CASCADE;


--
-- TOC entry 5523 (class 2606 OID 18261)
-- Name: tal_succession_candidates tal_succession_candidates_position_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.tal_succession_candidates
    ADD CONSTRAINT tal_succession_candidates_position_id_foreign FOREIGN KEY (position_id) REFERENCES public.positions(position_id) ON DELETE RESTRICT;


--
-- TOC entry 5506 (class 2606 OID 17994)
-- Name: training_feedbacks training_feedbacks_session_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_feedbacks
    ADD CONSTRAINT training_feedbacks_session_id_foreign FOREIGN KEY (session_id) REFERENCES public.training_sessions(session_id) ON DELETE CASCADE;


--
-- TOC entry 5497 (class 2606 OID 17919)
-- Name: training_sessions training_sessions_cohort_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_sessions
    ADD CONSTRAINT training_sessions_cohort_id_foreign FOREIGN KEY (cohort_id) REFERENCES public.program_cohorts(cohort_id) ON DELETE SET NULL;


--
-- TOC entry 5498 (class 2606 OID 17914)
-- Name: training_sessions training_sessions_course_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.training_sessions
    ADD CONSTRAINT training_sessions_course_id_foreign FOREIGN KEY (course_id) REFERENCES public.training_courses(course_id) ON DELETE RESTRICT;


--
-- TOC entry 5439 (class 2606 OID 17123)
-- Name: user_roles user_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- TOC entry 5390 (class 2606 OID 17196)
-- Name: users users_employee_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: erp_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_employee_id_foreign FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE SET NULL;


-- Completed on 2026-09-21 15:49:32

--
-- PostgreSQL database dump complete
--

\unrestrict PPChaNT6Bu7gRenwqo8nbXuMK3AQVZOit4wkzW9dbbUNuOIqT7lZBSHyswdeCdx

