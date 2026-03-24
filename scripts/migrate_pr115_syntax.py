#!/usr/bin/env python3
"""Mechanically rewrite eligible statement-local declarations to PR11.5 `var` syntax."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from migrate_pr114_syntax import split_segments


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ROOTS = (
    REPO_ROOT / "tests",
    REPO_ROOT / "samples",
)
STATEMENT_LOCAL_DECL_RE = re.compile(
    r"^(\s*)([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:\s*(?!constant\b)(.+?)(\s*;?\s*)$"
)


def visible_code(line: str) -> str:
    return "".join(text for kind, text in split_segments(line) if kind == "code")


def strip_newline(line: str) -> tuple[str, str]:
    if line.endswith("\r\n"):
        return (line[:-2], "\r\n")
    if line.endswith("\n"):
        return (line[:-1], "\n")
    return (line, "")


def closes_statement_context(stripped: str) -> int:
    lowered = stripped.lower()
    if lowered == "or":
        return 1
    if lowered == "else":
        return 1
    if lowered.startswith("else if ") and lowered.endswith(" then"):
        return 1
    if lowered == "end" or lowered.startswith("end "):
        return 1
    return 0


def opens_statement_context(stripped: str) -> int:
    lowered = stripped.lower()
    if lowered == "begin":
        return 1
    if lowered.endswith(" loop"):
        return 1
    if lowered.endswith(" then"):
        return 1
    if lowered == "else":
        return 1
    return 0


def rewrite_statement_local_declaration(line: str) -> str:
    body, newline = strip_newline(line)
    match = STATEMENT_LOCAL_DECL_RE.match(body)
    if match is None:
        return line
    indent, names, remainder, suffix = match.groups()
    return f"{indent}var {names} : {remainder}{suffix}{newline}"


def rewrite_safe_source(text: str) -> str:
    lines = text.splitlines(keepends=True)
    rewritten: list[str] = []
    statement_depth = 0
    pending_declare_depth = 0

    for line in lines:
        code = visible_code(line)
        stripped = code.strip()
        lowered = stripped.lower()

        if stripped:
            statement_depth = max(0, statement_depth - closes_statement_context(stripped))
            if lowered == "begin" and pending_declare_depth > 0:
                pending_declare_depth -= 1

        updated = line
        if statement_depth > 0 and pending_declare_depth == 0 and stripped:
            updated = rewrite_statement_local_declaration(line)

        rewritten.append(updated)

        if stripped:
            if lowered == "declare":
                pending_declare_depth += 1
            statement_depth += opens_statement_context(stripped)

    return "".join(rewritten)


def iter_safe_paths(roots: list[Path]) -> list[Path]:
    paths: list[Path] = []
    for root in roots:
        if root.is_file():
            if root.suffix == ".safe":
                paths.append(root)
            continue
        paths.extend(sorted(root.rglob("*.safe")))
    return sorted(set(paths))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, help="optional .safe paths or directories to rewrite")
    parser.add_argument("--check", action="store_true", help="report files that would change without rewriting")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    roots = [path.resolve() for path in (args.paths or list(DEFAULT_ROOTS))]
    changed: list[Path] = []

    for path in iter_safe_paths(roots):
        original = path.read_text(encoding="utf-8")
        updated = rewrite_safe_source(original)
        if updated != original:
            changed.append(path)
            if not args.check:
                path.write_text(updated, encoding="utf-8")

    for path in changed:
        print(path.relative_to(REPO_ROOT))

    if args.check and changed:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
