"""Hard rule 2: the AI service never connects to any database.

No database driver may appear in the project's dependencies — declared in pyproject.toml, or pulled
in indirectly, which only uv.lock shows.
"""

import re
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DATABASE_DRIVERS = {
    # PostgreSQL
    "psycopg", "psycopg-binary", "psycopg-c", "psycopg-pool",
    "psycopg2", "psycopg2-binary", "asyncpg", "pg8000", "aiopg",
    # MySQL / MariaDB
    "pymysql", "mysqlclient", "mysql-connector-python", "aiomysql", "asyncmy", "mariadb",
    # SQLite
    "aiosqlite", "pysqlite3", "pysqlite3-binary", "sqlite-utils", "apsw",
    # SQL Server, Oracle, ODBC
    "pyodbc", "pymssql", "aioodbc", "oracledb", "cx-oracle",
    # ORMs and database toolkits
    "sqlalchemy", "sqlmodel", "databases", "peewee", "tortoise-orm", "pony", "ormar",
    # Other stores
    "duckdb", "pymongo", "motor", "redis", "cassandra-driver", "elasticsearch",
}


def normalize(name: str) -> str:
    return re.sub(r"[-_.]+", "-", name).lower()


def requirement_name(requirement: str) -> str:
    match = re.match(r"[A-Za-z0-9][A-Za-z0-9._-]*", requirement.strip())
    assert match, f"cannot read requirement {requirement!r}"
    return normalize(match.group(0))


def declared_dependencies() -> set[str]:
    project = tomllib.loads((ROOT / "pyproject.toml").read_text(encoding="utf-8"))["project"]
    requirements = list(project.get("dependencies", []))
    for extra in project.get("optional-dependencies", {}).values():
        requirements.extend(extra)
    return {requirement_name(r) for r in requirements}


def locked_packages() -> set[str]:
    lock = tomllib.loads((ROOT / "uv.lock").read_text(encoding="utf-8"))
    return {normalize(package["name"]) for package in lock["package"]}


def test_no_database_driver_declared_in_pyproject() -> None:
    declared = declared_dependencies()

    assert "fastapi" in declared  # the parse found the real list
    assert declared.isdisjoint(DATABASE_DRIVERS), declared & DATABASE_DRIVERS


def test_no_database_driver_in_lock_file() -> None:
    locked = locked_packages()

    assert "fastapi" in locked  # the parse found the real list
    assert locked.isdisjoint(DATABASE_DRIVERS), locked & DATABASE_DRIVERS
