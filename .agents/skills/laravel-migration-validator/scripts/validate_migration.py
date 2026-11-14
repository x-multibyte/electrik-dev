#!/usr/bin/env python3
"""Validate Laravel migration files for rollback safety and Electrik core table protection."""

from __future__ import annotations

import pathlib
import re
import sys

CORE_TABLES = ("users", "teams", "subscriptions")
DOWN_FN_RE = re.compile(r"function\s+down\s*\(", re.IGNORECASE)
UP_FN_RE = re.compile(r"function\s+up\s*\(", re.IGNORECASE)
DESTRUCTIVE_SQL_RE = re.compile(
    r"\b(?:DROP\s+TABLE|TRUNCATE\s+TABLE|TRUNCATE\s+`?[a-zA-Z0-9_]+`?)\b",
    re.IGNORECASE,
)
CORE_DROP_RE = re.compile(
    r"Schema::drop(?:IfExists)?\(\s*['\"](users|teams|subscriptions)['\"]\s*\)",
    re.IGNORECASE,
)


def extract_up_section(content: str) -> str:
    """Return the portion of the migration file corresponding to up() before down()."""
    up_match = UP_FN_RE.search(content)
    down_match = DOWN_FN_RE.search(content)

    start = up_match.start() if up_match else 0
    end = down_match.start() if down_match and down_match.start() > start else len(content)
    return content[start:end]


def validate_file(path: pathlib.Path) -> list[str]:
    """Return a list of validation error strings for a single migration file."""
    errors: list[str] = []
    content = path.read_text(encoding="utf-8")

    if not DOWN_FN_RE.search(content):
        errors.append(
            f"[MIGRATION_ERROR] {path}: Missing down() method for safe rollback."
        )

    if DESTRUCTIVE_SQL_RE.search(content):
        errors.append(
            f"[MIGRATION_ERROR] {path}: Destructive SQL statement (DROP TABLE / TRUNCATE) detected."
        )

    up_section = extract_up_section(content)
    down_match = DOWN_FN_RE.search(content)
    down_section = content[down_match.start() :] if down_match else ""

    for match in CORE_DROP_RE.finditer(up_section):
        table = match.group(1)
        errors.append(
            f"[MIGRATION_ERROR] {path}: Dropping core table '{table}' inside up() is forbidden."
        )

    for match in CORE_DROP_RE.finditer(down_section):
        table = match.group(1)
        create_re = re.compile(
            rf"Schema::create\(\s*['\"]{re.escape(table)}['\"]",
            re.IGNORECASE,
        )
        if not create_re.search(up_section):
            errors.append(
                f"[MIGRATION_ERROR] {path}: Standalone drop of core table '{table}' without Schema::create('{table}') in up() is forbidden."
            )

    return errors


def collect_targets(target: pathlib.Path) -> list[pathlib.Path]:
    """Collect PHP migration files from a file path or directory."""
    if target.is_file():
        return [target]
    if target.is_dir():
        return sorted(target.rglob("*.php"))
    return []


def main(argv: list[str]) -> int:
    """CLI entry point accepting a migration file or directory."""
    target = pathlib.Path(argv[1]) if len(argv) > 1 else pathlib.Path("database/migrations")
    files = collect_targets(target)

    if not files:
        print(f"[MIGRATION_ERROR] No migration files found at {target}", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    for file_path in files:
        all_errors.extend(validate_file(file_path))

    if all_errors:
        for err in all_errors:
            print(err)
        return 1

    print(f"[OK] Validated {len(files)} migration file(s) at {target}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
