"""The specs we hand to Laravel, checked against themselves and against schema/erp_hr_schema.sql.

The schema file is read as text only — never loaded into a database (CLAUDE.md §2, rule 7).
"""

import re
from pathlib import Path
from typing import Any

import pytest
import sqlglot
import yaml
from jsonschema import Draft202012Validator
from openapi_spec_validator import validate as validate_openapi
from sqlglot import exp

ROOT = Path(__file__).resolve().parent.parent
SPECS = ROOT / "docs" / "specs"
SCHEMA_FILE = ROOT / "schema" / "erp_hr_schema.sql"

QUESTION_TYPES = [
    "leave_balance", "leave_requests", "attendance_month", "salary",
    "contract", "documents_expiring", "penalties", "my_team",
]
TEAM_SEARCH = "team_search"
SUBJECT_PARAMS = {"target_id", "principal_id"}
EMPLOYEE_COLUMNS = {"employee_id", "manager_id"}
NEVER_SELECTED = {
    "bank_name", "bank_account", "bank_iban", "national_id", "passport_number",
    "document_number", "file_path", "reason", "review_notes", "note", "special_conditions",
}
NEVER_SELECTED_SUFFIXES = ("_notes", "_reason")
REFUSAL_REASONS = {
    "own_records_only", "not_found", "not_understood", "no_data",
    "not_available_yet", "manager_access_off", "data_problem", "unavailable",
}
ARCHITECTURE = ROOT / "plan" / "HR_ASSISTANT_ARCHITECTURE.md"
PLACEHOLDER = re.compile(r"(?<![:\w]):([a-z_][a-z0-9_]*)")


# ── loading ──────────────────────────────────────────────────────────────────────────────────────


def load_catalogue() -> dict[str, str]:
    """Question type (or team_search) → its SQL, from the ```sql blocks in catalogue.md."""
    queries: dict[str, str] = {}
    heading = ""
    lines = (SPECS / "catalogue.md").read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("### "):
            heading = line[4:].split()[0]
        elif line.startswith("## Team search"):
            heading = TEAM_SEARCH
        elif line.strip() == "```sql":
            end = lines.index("```", i + 1)
            assert heading not in queries, f"two queries under {heading}"
            queries[heading] = "\n".join(lines[i + 1 : end])
            i = end
        i += 1
    return queries


def load_schema() -> dict[str, dict[str, str]]:
    """Table → column → the column's line, from the CREATE TABLE statements in the dump."""
    text = SCHEMA_FILE.read_text(encoding="utf-8")
    tables: dict[str, dict[str, str]] = {}
    for match in re.finditer(r"^CREATE TABLE public\.(\w+) \((.*?)^\);", text, re.M | re.S):
        body = match.group(2)
        columns = {
            line.split()[0].strip('"'): line
            for line in (raw.strip() for raw in body.splitlines())
            if line and not line.startswith("CONSTRAINT")
        }
        tables[match.group(1)] = columns | {"__body__": body}
    return tables


def allowed_values(schema: dict[str, dict[str, str]], table: str, column: str) -> set[str]:
    """The values a CHECK constraint allows for a column; empty if it has none."""
    body = schema[table]["__body__"]
    match = re.search(rf"\(\({column}\)::text = ANY \(\(ARRAY\[(.*?)\]\)", body)
    return set(re.findall(r"'(\w+)'::character varying", match.group(1))) if match else set()


CATALOGUE = load_catalogue()
SCHEMA = load_schema()
TREES = {name: sqlglot.parse_one(sql, read="postgres") for name, sql in CATALOGUE.items()}
TEMPLATES: dict[str, Any] = yaml.safe_load((SPECS / "templates.yaml").read_text(encoding="utf-8"))
REFUSALS: dict[str, Any] = yaml.safe_load((SPECS / "refusals.yaml").read_text(encoding="utf-8"))
OPENAPI: dict[str, Any] = yaml.safe_load(
    (SPECS / "understand.openapi.yaml").read_text(encoding="utf-8")
)


# ── resolving columns ────────────────────────────────────────────────────────────────────────────


def output_names(tree: exp.Expression) -> list[str]:
    assert isinstance(tree, exp.Select)
    return [e.alias_or_name for e in tree.expressions]


def resolve(tree: exp.Expression) -> list[tuple[str, str, exp.Column]]:
    """Every column reference in the statement → (table, column, node), with aliases resolved."""
    aliases = {t.alias_or_name: t.name for t in tree.find_all(exp.Table)}
    select_aliases = {
        e.alias
        for select in tree.find_all(exp.Select)
        for e in select.expressions
        if isinstance(e, exp.Alias)
    }
    resolved = []
    for column in tree.find_all(exp.Column):
        if column.table:
            assert column.table in aliases, f"unknown alias {column.table!r} in {column.sql()}"
            resolved.append((aliases[column.table], column.name, column))
        elif column.name in select_aliases and isinstance(column.parent, exp.Ordered):
            continue  # ORDER BY an output alias, not a table column
        else:
            owners = [t for t in set(aliases.values()) if column.name in SCHEMA.get(t, {})]
            assert len(owners) == 1, f"cannot resolve unqualified column {column.name!r}"
            resolved.append((owners[0], column.name, column))
    return resolved


def source_table(tree: exp.Expression, output: str) -> str | None:
    """The table an output column is selected from, if it is a plain column."""
    assert isinstance(tree, exp.Select)
    for expression in tree.expressions:
        if expression.alias_or_name == output:
            inner = expression.this if isinstance(expression, exp.Alias) else expression
            if isinstance(inner, exp.Column):
                return next(t for t, c, node in resolve(tree) if node is inner)
    return None


# ── the catalogue ────────────────────────────────────────────────────────────────────────────────


def test_catalogue_has_every_question_type_and_the_team_search() -> None:
    assert list(CATALOGUE) == [*QUESTION_TYPES, TEAM_SEARCH]


@pytest.mark.parametrize("name", CATALOGUE)
def test_a_every_table_and_column_exists_in_the_schema(name: str) -> None:
    tree = TREES[name]
    for table in tree.find_all(exp.Table):
        assert table.name in SCHEMA, f"{name}: table {table.name!r} is not in the schema"
    for table, column, _ in resolve(tree):
        assert column in SCHEMA[table], f"{name}: {table}.{column} is not in the schema"


@pytest.mark.parametrize("name", CATALOGUE)
def test_b_filters_by_the_subject_on_an_employee_column(name: str) -> None:
    tree = TREES[name]
    where = tree.args.get("where")
    assert isinstance(where, exp.Where), f"{name}: no WHERE clause"
    from_table = tree.find(exp.From).this.name  # type: ignore[union-attr]
    tables = {id(node): table for table, _, node in resolve(tree)}
    conjuncts = where.this.flatten() if isinstance(where.this, exp.And) else [where.this]

    def is_subject_filter(condition: exp.Expression) -> bool:
        if not isinstance(condition, exp.EQ):
            return False
        sides = [condition.left, condition.right]
        params = [s for s in sides if isinstance(s, exp.Placeholder)]
        columns = [s for s in sides if isinstance(s, exp.Column)]
        return (
            len(params) == 1 and params[0].name in SUBJECT_PARAMS
            and len(columns) == 1 and columns[0].name in EMPLOYEE_COLUMNS
            and tables.get(id(columns[0])) == from_table
        )

    assert any(is_subject_filter(c) for c in conjuncts), (
        f"{name}: the top-level WHERE has no AND-ed `<table>.employee_id|manager_id = "
        f":target_id|:principal_id`"
    )


@pytest.mark.parametrize("name", CATALOGUE)
def test_c_never_selects_a_forbidden_column(name: str) -> None:
    for select in TREES[name].find_all(exp.Select):
        for expression in select.expressions:
            for column in expression.find_all(exp.Column):
                assert column.name not in NEVER_SELECTED, f"{name} selects {column.name}"
                assert not column.name.endswith(NEVER_SELECTED_SUFFIXES), (
                    f"{name} selects {column.name}"
                )


@pytest.mark.parametrize("name", CATALOGUE)
def test_d_no_select_star(name: str) -> None:
    for select in TREES[name].find_all(exp.Select):
        for expression in select.expressions:
            is_star = isinstance(expression, exp.Star) or (
                isinstance(expression, exp.Column) and isinstance(expression.this, exp.Star)
            )
            assert not is_star, f"{name} has SELECT *"


@pytest.mark.parametrize("name", CATALOGUE)
def test_e_each_named_placeholder_appears_once(name: str) -> None:
    names = PLACEHOLDER.findall(CATALOGUE[name])
    repeated = sorted({n for n in names if names.count(n) > 1})
    assert not repeated, f"{name} repeats {repeated} — PDO native prepares reject that"


# ── templates ────────────────────────────────────────────────────────────────────────────────────


def template_strings(variant: dict[str, Any]) -> list[str]:
    return [text for language in ("ar", "en") for text in variant[language].values()]


def test_templates_cover_every_question_type_and_shape() -> None:
    assert list(TEMPLATES) == QUESTION_TYPES
    for question_type, spec in TEMPLATES.items():
        variants = ["self"] if question_type == "my_team" else ["self", "team_member"]
        keys = {"one": {"text"}, "many": {"intro", "row"}}[spec["rows"]]
        for variant in variants:
            for language in ("ar", "en"):
                assert set(spec[variant][language]) == keys, f"{question_type}.{variant}.{language}"
        assert set(spec["labels"]) == {"ar", "en"}, question_type


@pytest.mark.parametrize("question_type", QUESTION_TYPES)
def test_f_every_placeholder_is_a_selected_column_or_subject_name(question_type: str) -> None:
    columns = set(output_names(TREES[question_type]))
    spec = TEMPLATES[question_type]
    for variant in ("self", "team_member"):
        if variant not in spec:
            continue
        allowed = columns | ({"subject_name"} if variant == "team_member" else set())
        for text in template_strings(spec[variant]):
            for placeholder in re.findall(r"\{(\w+)\}", text):
                assert placeholder in allowed, (
                    f"{question_type}.{variant}: {{{placeholder}}} is not a selected column"
                )


@pytest.mark.parametrize("question_type", QUESTION_TYPES)
def test_labels_and_value_codes_match_the_catalogue_and_schema(question_type: str) -> None:
    tree = TREES[question_type]
    columns = set(output_names(tree))
    spec = TEMPLATES[question_type]
    for language, labels in spec["labels"].items():
        unknown = set(labels) - columns
        assert not unknown, f"{question_type} labels.{language}: {unknown} not selected"
    for column, codes in spec.get("values", {}).items():
        assert column in columns, f"{question_type} values: {column} not selected"
        table = source_table(tree, column)
        assert table, f"{question_type} values: {column} is not a plain column"
        allowed = allowed_values(SCHEMA, table, column)
        assert allowed, f"{table}.{column} has no CHECK constraint to take values from"
        assert set(codes) <= allowed, f"{table}.{column}: {set(codes) - allowed} not allowed"
        for code, label in codes.items():
            assert set(label) == {"ar", "en"}, f"{question_type} values.{column}.{code}"


# ── refusals ─────────────────────────────────────────────────────────────────────────────────────


def test_refusals_cover_every_reason_in_both_languages() -> None:
    assert set(REFUSALS) == REFUSAL_REASONS
    for reason, spec in REFUSALS.items():
        if reason == "no_data":
            assert set(spec) == {"when", *QUESTION_TYPES}
            for question_type in QUESTION_TYPES:
                assert set(spec[question_type]) == {"ar", "en"}
        else:
            assert set(spec) == {"when", "ar", "en"}, reason


def test_refusals_match_the_architecture_table() -> None:
    text = ARCHITECTURE.read_text(encoding="utf-8")
    section = text[text.index("### 9.2 Refusals") : text.index("### 9.3")]
    in_architecture = set(re.findall(r"^\| `(\w+)` \|", section, re.M))
    assert in_architecture == set(REFUSALS) == REFUSAL_REASONS


def test_g_exactly_one_not_found_text_per_language() -> None:
    not_found = REFUSALS["not_found"]
    assert set(not_found) == {"when", "ar", "en"}
    for language in ("ar", "en"):
        assert isinstance(not_found[language], str) and not_found[language].strip()


# ── the /v1/understand contract ──────────────────────────────────────────────────────────────────


def test_h_openapi_is_valid() -> None:
    validate_openapi(OPENAPI)


def response_validator() -> Draft202012Validator:
    schema = {
        "$ref": "#/components/schemas/UnderstandResponse",
        "components": OPENAPI["components"],
    }
    return Draft202012Validator(schema)


META = {
    "request_id": "5b0e3c7a-2f1d-4c6e-9a8b-1d2e3f4a5b6c",
    "prompt_version": "v1",
    "model_id": "x",
}
SELF = {"kind": "self", "name": None, "employee_number": None}


def test_openapi_examples_match_the_response_schema() -> None:
    examples = OPENAPI["paths"]["/v1/understand"]["post"]["responses"]["200"]["content"][
        "application/json"
    ]["examples"]
    for name, example in examples.items():
        errors = list(response_validator().iter_errors(example["value"]))
        assert not errors, f"example {name}: {errors[0].message}"


@pytest.mark.parametrize(
    "body",
    [
        pytest.param(
            {"intent": "salary", "subject": None, "details": {}}, id="null subject, real intent"
        ),
        pytest.param(
            {"intent": "unknown", "subject": SELF, "details": {}}, id="unknown with a subject"
        ),
        pytest.param(
            {"intent": "unknown", "subject": None, "details": {"month": 1}},
            id="unknown with details",
        ),
        pytest.param(
            {"intent": "salary", "subject": {**SELF, "name": "أحمد"}, "details": {}},
            id="self with a name",
        ),
        pytest.param(
            {"intent": "salary", "subject": {**SELF, "kind": "person"}, "details": {}},
            id="person with no name or number",
        ),
        pytest.param(
            {"intent": "attendance_month", "subject": SELF,
             "details": {"period": "last_month", "month": 8}},
            id="period and month together",
        ),
        pytest.param(
            {"intent": "salary", "subject": SELF, "details": {"period": "yesterday"}},
            id="unknown period token",
        ),
        pytest.param(
            {"intent": "salary", "subject": SELF, "details": {"employee_id": "x"}},
            id="extra detail field",
        ),
    ],
)
def test_openapi_rejects_what_section_6_1_forbids(body: dict[str, Any]) -> None:
    response = {**body, "language": "ar", "meta": META}
    assert not response_validator().is_valid(response)
