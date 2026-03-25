#!/usr/bin/env python3
"""Run the PR11.7 reference-surface cutover gate."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Any

from _lib.harness_common import (
    display_path,
    ensure_sdkroot,
    finalize_deterministic_report,
    managed_scratch_root,
    normalize_text,
    read_diag_json,
    require,
    run,
    sha256_text,
    write_report,
)
from _lib.pr09_emit import (
    REPO_ROOT,
    compile_emitted_ada,
    emit_paths,
    emitted_body_file,
    emitted_spec_file,
    repo_arg,
)
from _lib.pr111_language_eval import safec_path
from _lib.pr117_surface import (
    migration_examples,
    negative_cases,
    negative_paths,
    readability_examples,
    technical_cases,
    technical_paths,
)
from migrate_pr117_reference_surface import rewrite_safe_source


DEFAULT_REPORT = REPO_ROOT / "execution" / "reports" / "pr117-reference-surface-experiments-report.json"


def safec_argv(safec: Path, command: str, source: Path, *, extra: list[str] | None = None) -> list[str]:
    argv = [str(safec), command, repo_arg(source)]
    if extra:
        argv.extend(extra)
    return argv


def normalize_variant_artifact(text: str, *, source: Path, variant: Path, temp_root: Path) -> str:
    normalized = normalize_text(text, temp_root=temp_root, repo_root=REPO_ROOT)
    return normalized.replace(f"$TMPDIR/{variant.name}", repo_arg(source))


def run_emit_case(
    *,
    safec: Path,
    source: Path,
    env: dict[str, str],
    temp_root: Path,
) -> dict[str, Any]:
    root = temp_root / source.stem
    out_dir = root / "out"
    iface_dir = root / "iface"
    ada_dir = root / "ada"
    out_dir.mkdir(parents=True, exist_ok=True)
    iface_dir.mkdir(parents=True, exist_ok=True)
    ada_dir.mkdir(parents=True, exist_ok=True)

    check_result = run(
        safec_argv(safec, "check", source),
        cwd=REPO_ROOT,
        env=env,
        temp_root=temp_root,
    )
    emit_result = run(
        safec_argv(
            safec,
            "emit",
            source,
            extra=[
                "--out-dir",
                str(out_dir),
                "--interface-dir",
                str(iface_dir),
                "--ada-out-dir",
                str(ada_dir),
            ],
        ),
        cwd=REPO_ROOT,
        env=env,
        temp_root=temp_root,
    )
    paths = emit_paths(root, source)
    for path in paths.values():
        require(path.exists(), f"{source.name}: missing emitted artifact {display_path(path, repo_root=REPO_ROOT)}")
    validate_mir = run(
        [str(safec), "validate-mir", str(paths["mir"])],
        cwd=REPO_ROOT,
        env=env,
        temp_root=temp_root,
    )
    compile_result = compile_emitted_ada(
        ada_dir=ada_dir,
        env=env,
        temp_root=temp_root,
    )

    return {
        "root": root,
        "paths": paths,
        "check": {
            "command": check_result["command"],
            "cwd": check_result["cwd"],
            "returncode": check_result["returncode"],
        },
        "emit": {
            "command": emit_result["command"],
            "cwd": emit_result["cwd"],
            "returncode": emit_result["returncode"],
        },
        "validate_mir": {
            "command": validate_mir["command"],
            "cwd": validate_mir["cwd"],
            "returncode": validate_mir["returncode"],
        },
        "compile": {
            "command": compile_result["command"],
            "cwd": compile_result["cwd"],
            "returncode": compile_result["returncode"],
        },
        "typed_text": paths["typed"].read_text(encoding="utf-8"),
        "mir_text": paths["mir"].read_text(encoding="utf-8"),
        "ada_text": emitted_spec_file(ada_dir).read_text(encoding="utf-8")
        + "\n"
        + emitted_body_file(ada_dir).read_text(encoding="utf-8"),
    }


def run_technical_case(*, safec: Path, source: Path, env: dict[str, str], temp_root: Path) -> dict[str, Any]:
    original_text = source.read_text(encoding="utf-8")
    combined_text = rewrite_safe_source(original_text, mode="combined")
    require(combined_text == original_text, f"{source.name}: source is not stable under PR11.7 combined migration")
    emitted = run_emit_case(
        safec=safec,
        source=source,
        env=env,
        temp_root=temp_root,
    )

    return {
        "source": repo_arg(source),
        "migration_stable": True,
        "cutover_surface": {
            "check": emitted["check"],
            "emit": emitted["emit"],
            "validate_mir": emitted["validate_mir"],
            "compile": emitted["compile"],
            "typed_sha256": sha256_text(
                normalize_variant_artifact(
                emitted["typed_text"],
                source=source,
                variant=source,
                temp_root=temp_root,
                )
            ),
            "mir_sha256": sha256_text(
                normalize_variant_artifact(
                emitted["mir_text"],
                source=source,
                variant=source,
                temp_root=temp_root,
                )
            ),
            "ada_sha256": sha256_text(
                normalize_variant_artifact(
                emitted["ada_text"],
                source=source,
                variant=source,
                temp_root=temp_root,
                )
            ),
        },
    }


def run_negative_case(
    *,
    safec: Path,
    source: Path,
    env: dict[str, str],
    temp_root: Path,
    expected_reason: str,
    expected_message: str,
) -> dict[str, Any]:
    result = run(
        safec_argv(safec, "check", source, extra=["--diag-json"]),
        cwd=REPO_ROOT,
        env=env,
        temp_root=temp_root,
        expected_returncode=1,
    )
    payload = read_diag_json(result["stdout"], repo_arg(source))
    diagnostics = payload.get("diagnostics", [])
    require(diagnostics, f"{source.name}: expected at least one diagnostic")
    first = diagnostics[0]
    require(first["reason"] == expected_reason, f"{source.name}: expected reason {expected_reason!r}")
    require(expected_message in first["message"], f"{source.name}: expected message containing {expected_message!r}")
    return {
        "source": repo_arg(source),
        "cutover_surface": {
            "command": result["command"],
            "cwd": result["cwd"],
            "returncode": result["returncode"],
        },
        "first_diagnostic": {
            "reason": first["reason"],
            "message": first["message"],
            "path": first["path"],
        },
    }


def run_migration_example(example: dict[str, Any]) -> dict[str, Any]:
    rewritten = rewrite_safe_source(example["source"], mode=example["mode"])
    for fragment in example.get("required_fragments", ()):
        require(fragment in rewritten, f"{example['name']}: missing fragment {fragment!r}")
    for fragment in example.get("forbidden_fragments", ()):
        require(fragment not in rewritten, f"{example['name']}: retained fragment {fragment!r}")
    return {
        "name": example["name"],
        "mode": example["mode"],
        "required_fragments": list(example.get("required_fragments", ())),
        "forbidden_fragments": list(example.get("forbidden_fragments", ())),
    }


def run_readability_example(example: dict[str, Any]) -> dict[str, Any]:
    implicit = rewrite_safe_source(example["source"], mode="implicit-deref")
    combined = rewrite_safe_source(example["source"], mode="combined")
    return {
        "name": example["name"],
        "description": example["description"],
        "legacy_baseline": example["source"],
        "implicit_deref": implicit,
        "cutover_surface": combined,
    }


def generate_report(*, env: dict[str, str], scratch_root: Path | None = None) -> dict[str, Any]:
    safec = safec_path()
    technical: list[dict[str, Any]] = []
    negatives: list[dict[str, Any]] = []
    migrations: list[dict[str, Any]] = []
    readability: list[dict[str, Any]] = []

    with managed_scratch_root(scratch_root=scratch_root, prefix="pr117-reference-") as temp_root:
        for case in technical_cases():
            technical.append(
                run_technical_case(
                    safec=safec,
                    source=case["source"],
                    env=env,
                    temp_root=temp_root,
                )
            )
        for case in negative_cases():
            negatives.append(
                run_negative_case(
                    safec=safec,
                    source=case["source"],
                    env=env,
                    temp_root=temp_root,
                    expected_reason=case["reason"],
                    expected_message=case["message"],
                )
            )
        for example in migration_examples():
            migrations.append(run_migration_example(example))
        for example in readability_examples():
            readability.append(run_readability_example(example))

    return {
        "task": "PR11.7",
        "status": "ok",
        "scope": {
            "included": [
                "capitalisation as reference signal",
                "implicit dereference",
            ],
            "excluded": [
                "capitalisation as export signal",
                "move keyword",
            ],
            "default_surface_changed": True,
            "explicit_source_dereference_admitted": False,
            "predefined_names_require_canonical_lowercase": True,
            "provisional_branch_ready": True,
        },
        "technical_corpus": {
            "sources": technical_paths(),
            "cases": technical,
        },
        "negative_boundaries": {
            "sources": negative_paths(),
            "cases": negatives,
        },
        "migration_examples": migrations,
        "readability_examples": readability,
        "decisions": {
            "reference_signal": {
                "decision": "admit",
                "rationale": [
                    "Case-significant user-name resolution is now the default compiler behavior for user-defined names, with case-fold collisions rejected in the same visible scope.",
                    "The fixed ownership/reference corpus, migrated samples, and boundary fixtures all validate the shipped naming law across access-typed and value-typed bindings plus lowercase package/function/type names.",
                    "PR11.7 therefore records Capitalisation as Reference Signal as admitted default surface behavior rather than an experiment-only path.",
                ],
            },
            "implicit_dereference": {
                "decision": "admit",
                "rationale": [
                    "Direct selector syntax is now the only admitted Safe source dereference spelling, while explicit source `.all` is rejected with a deterministic diagnostic.",
                    "The migrated fixed corpus compiles, emits Ada, validates MIR, and still lowers to emitted Ada that uses explicit `.all` only as an Ada backend detail where required.",
                    "PR11.7 therefore records Implicit Dereference as admitted default source behavior and removes explicit `.all` from the Safe source surface.",
                ],
            },
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--scratch-root", type=Path, default=None)
    args = parser.parse_args()

    report = finalize_deterministic_report(
        lambda: generate_report(
            env=ensure_sdkroot(os.environ.copy()),
            scratch_root=args.scratch_root,
        ),
        label="PR11.7 reference-surface experiments",
    )
    write_report(args.report, report)
    print(f"pr117 reference-surface experiments: OK ({display_path(args.report, repo_root=REPO_ROOT)})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, FileNotFoundError, ValueError) as exc:
        print(f"pr117 reference-surface experiments: ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
