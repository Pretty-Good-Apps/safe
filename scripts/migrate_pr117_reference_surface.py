#!/usr/bin/env python3
"""Mechanical rewrites for the PR11.7 reference-surface cutover."""

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
BUILTIN_TYPE_NAMES = (
    "integer",
    "natural",
    "boolean",
    "character",
    "string",
    "result",
    "float",
    "long_float",
    "duration",
)
BUILTIN_FUNCTION_NAMES = (
    "ok",
    "fail",
)
ATTRIBUTE_NAMES = (
    "access",
    "first",
    "last",
    "length",
)
TYPE_ACCESS_RE = re.compile(r"^\s*type\s+([A-Za-z_]\w*)\s+is\s+(?:not\s+null\s+)?access\b", re.IGNORECASE)
TYPE_DECL_RE = re.compile(r"^\s*type\s+([A-Za-z_]\w*)\b", re.IGNORECASE)
PACKAGE_RE = re.compile(r"^\s*package\s+([A-Za-z_]\w*)\b", re.IGNORECASE)
FUNCTION_RE = re.compile(r"^\s*(?:public\s+)?function\s+([A-Za-z_]\w*)\b", re.IGNORECASE)
DECL_LINE_RE = re.compile(
    r"^\s*(?:var\s+)?([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:\s*(.+?)\s*;?\s*$",
    re.IGNORECASE,
)
PARAM_FRAGMENT_RE = re.compile(r"([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:\s*([^();]+)")
MODE_RE = re.compile(r"^(in\s+out|out|in)\s+", re.IGNORECASE)


class ReferenceSurfaceMigrationError(RuntimeError):
    """Raised when a preview rewrite would need semantic judgement."""


def visible_code(line: str) -> str:
    return "".join(text for kind, text in split_segments(line) if kind == "code")


def code_indent(line: str) -> int:
    code = visible_code(line)
    return len(code) - len(code.lstrip(" "))


def normalize_spaces(value: str) -> str:
    return " ".join(value.split())


def preferred_name(name: str, *, is_reference: bool) -> str:
    if not name:
        return name
    head = name[0].upper() if is_reference else name[0].lower()
    return head + name[1:]


def is_access_type(type_text: str, access_types: set[str]) -> bool:
    cleaned = normalize_spaces(MODE_RE.sub("", type_text.strip()))
    lowered = cleaned.lower()
    if lowered.startswith("not null access ") or lowered.startswith("access "):
        return True
    base_match = re.match(r"([A-Za-z_]\w*)", cleaned)
    return base_match is not None and base_match.group(1) in access_types


def collect_access_types(text: str) -> set[str]:
    access_types: set[str] = set()
    for line in text.splitlines():
        code = visible_code(line).strip()
        if not code:
            continue
        access_match = TYPE_ACCESS_RE.match(code)
        if access_match:
            access_types.add(access_match.group(1))
    return access_types


def lower_builtin_spelling(segment: str) -> str:
    updated = segment
    for name in BUILTIN_TYPE_NAMES + BUILTIN_FUNCTION_NAMES:
        updated = re.sub(rf"\b{re.escape(name)}\b", name, updated, flags=re.IGNORECASE)
    for name in ATTRIBUTE_NAMES:
        updated = re.sub(rf"\.{re.escape(name)}\b", "." + name, updated, flags=re.IGNORECASE)
    return updated


def collect_rename_map(text: str) -> dict[str, str]:
    access_types = collect_access_types(text)
    rename_map: dict[str, str] = {}
    inside_record = False
    record_indent = 0
    inside_signature = False
    paren_depth = 0

    def record_rename(raw_name: str, *, is_reference: bool | None) -> None:
        if raw_name.lower() in BUILTIN_TYPE_NAMES or raw_name.lower() in BUILTIN_FUNCTION_NAMES:
            return
        if is_reference is None:
            new_name = preferred_name(raw_name, is_reference=False)
        else:
            new_name = preferred_name(raw_name, is_reference=is_reference)
        if raw_name in rename_map and rename_map[raw_name] != new_name:
            raise ReferenceSurfaceMigrationError(
                f"inconsistent rewrite target for {raw_name!r}"
            )
        rename_map[raw_name] = new_name

    for line in text.splitlines():
        code = visible_code(line).strip()
        if not code:
            continue

        line_indent = code_indent(line)
        lowered = code.lower()
        if inside_record and line_indent <= record_indent and not lowered.startswith(("when ", "case ")):
            inside_record = False
        if lowered.startswith("type ") and lowered.endswith(" is record"):
            inside_record = True
            record_indent = line_indent

        package_match = PACKAGE_RE.match(code)
        if package_match:
            record_rename(package_match.group(1), is_reference=None)
            continue

        type_match = TYPE_DECL_RE.match(code)
        if type_match:
            record_rename(type_match.group(1), is_reference=None)
            continue

        function_match = FUNCTION_RE.match(code)
        if function_match:
            record_rename(function_match.group(1), is_reference=None)
            inside_signature = True
            paren_depth = code.count("(") - code.count(")")
            if "(" in code:
                param_fragment = code.split("(", 1)[1]
                if ")" in param_fragment:
                    param_fragment = param_fragment.split(")", 1)[0]
                for match in PARAM_FRAGMENT_RE.finditer(param_fragment):
                    names_text, type_text = match.groups()
                    is_reference = is_access_type(type_text, access_types)
                    for raw_name in (part.strip() for part in names_text.split(",")):
                        record_rename(raw_name, is_reference=is_reference)
            if paren_depth <= 0:
                inside_signature = False
            continue

        if inside_signature:
            for match in PARAM_FRAGMENT_RE.finditer(code):
                names_text, type_text = match.groups()
                is_reference = is_access_type(type_text, access_types)
                for raw_name in (part.strip() for part in names_text.split(",")):
                    record_rename(raw_name, is_reference=is_reference)
            paren_depth += code.count("(") - code.count(")")
            if paren_depth <= 0:
                inside_signature = False
            continue

        if lowered.startswith(
            (
                "if ",
                "else",
                "while ",
                "for ",
                "loop",
                "return",
                "case ",
                "when ",
                "select",
                "delay ",
                "send ",
                "receive ",
                "try_send ",
                "try_receive ",
                "task ",
            )
        ):
            continue

        match = DECL_LINE_RE.match(code)
        if match is None:
            continue

        names_text, type_text = match.groups()
        is_reference = is_access_type(type_text, access_types)
        for raw_name in (part.strip() for part in names_text.split(",")):
            record_rename(raw_name, is_reference=is_reference)

    inverse: dict[str, str] = {}
    for original, renamed in rename_map.items():
        prior = inverse.get(renamed)
        if prior is not None and prior != original:
            raise ReferenceSurfaceMigrationError(
                f"rewrites for {prior!r} and {original!r} both target {renamed!r}"
            )
        inverse[renamed] = original
    return {original: renamed for original, renamed in rename_map.items() if original != renamed}


def rewrite_code_segment(segment: str, rename_map: dict[str, str], *, strip_all: bool) -> str:
    updated = lower_builtin_spelling(segment)
    if rename_map:
        pattern = re.compile(
            r"\b(" + "|".join(sorted((re.escape(name) for name in rename_map), key=len, reverse=True)) + r")\b"
        )
        updated = pattern.sub(lambda match: rename_map[match.group(1)], updated)
    if strip_all:
        while True:
            rewritten = re.sub(r"\b([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.all\b", r"\1", updated)
            if rewritten == updated:
                break
            updated = rewritten
    return updated


def rewrite_safe_source(text: str, *, mode: str) -> str:
    rename_map = collect_rename_map(text) if mode in {"reference-signal", "combined"} else {}
    strip_all = mode in {"implicit-deref", "combined"}
    rewritten: list[str] = []
    for line in text.splitlines(keepends=True):
        parts: list[str] = []
        for kind, segment in split_segments(line):
            if kind == "code":
                parts.append(rewrite_code_segment(segment, rename_map, strip_all=strip_all))
            else:
                parts.append(segment)
        rewritten.append("".join(parts))
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
    parser.add_argument(
        "--mode",
        choices=("reference-signal", "implicit-deref", "combined"),
        required=True,
        help="rewrite mode to apply",
    )
    parser.add_argument("--check", action="store_true", help="report files that would change without rewriting")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    roots = [path.resolve() for path in (args.paths or list(DEFAULT_ROOTS))]
    changed: list[Path] = []

    for path in iter_safe_paths(roots):
        original = path.read_text(encoding="utf-8")
        try:
            updated = rewrite_safe_source(original, mode=args.mode)
        except ReferenceSurfaceMigrationError:
            continue
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
