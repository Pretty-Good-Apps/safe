#!/usr/bin/env python3
"""Run the PR09a emitter surface gate."""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
from pathlib import Path

from _lib.harness_common import (
    display_path,
    ensure_sdkroot,
    finalize_deterministic_report,
    require,
    write_report,
)
from _lib.pr09_emit import (
    REPO_ROOT,
    compile_emitted_ada,
    emit_with_determinism,
    emitted_ada_files,
    emitted_body_file,
    ensure_emit_failure_is_atomic,
    ensure_emit_success,
    file_hashes,
    repo_arg,
    require_safec,
    run_emit,
    structural_assertions,
)


DEFAULT_REPORT = REPO_ROOT / "execution" / "reports" / "pr09a-emitter-surface-report.json"
SURFACE_FIXTURES = [
    REPO_ROOT / "tests" / "positive" / "emitter_surface_record.safe",
    REPO_ROOT / "tests" / "positive" / "emitter_surface_proc.safe",
]
NEGATIVE_FIXTURE = REPO_ROOT / "tests" / "negative" / "neg_pr09_emitter_discriminant.safe"
NEGATIVE_ADA_STEM = "pr09_emitter_discriminant"


def seed_file(path: Path, contents: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents, encoding="utf-8")


def generate_report(*, safec: Path, env: dict[str, str]) -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix="pr09a-surface-") as temp_root_str:
        temp_root = Path(temp_root_str)
        positives: list[dict[str, object]] = []

        for fixture in SURFACE_FIXTURES:
            root_a = temp_root / f"{fixture.stem}-a"
            root_b = temp_root / f"{fixture.stem}-b"
            determinism = emit_with_determinism(
                safec=safec,
                source=fixture,
                root_a=root_a,
                root_b=root_b,
                env=env,
                temp_root=temp_root,
            )
            ensure_emit_success(source=fixture, root=root_a)
            compile_result = compile_emitted_ada(
                ada_dir=root_a / "ada",
                env=env,
                temp_root=temp_root,
            )
            ada_files = emitted_ada_files(root_a / "ada")
            require("safe_runtime.ads" not in ada_files, f"{fixture}: slice-1 fixture should not need safe_runtime.ads")
            require("gnat.adc" not in ada_files, f"{fixture}: slice-1 fixture should not need gnat.adc")

            body_path = emitted_body_file(root_a / "ada")
            spec_path = body_path.with_suffix(".ads")
            positives.append(
                {
                    "fixture": repo_arg(fixture),
                    "ada_files": ada_files,
                    "determinism": determinism,
                    "compile": compile_result,
                    "structural_assertions": {
                        spec_path.name: structural_assertions(
                            spec_path,
                            ["pragma SPARK_Mode (On);", "with SPARK_Mode => On", "package "],
                        ),
                        body_path.name: structural_assertions(
                            body_path,
                            ["package body "],
                        ),
                    },
                }
            )

        negative_root = temp_root / "negative"
        for name in ("out", "iface", "ada"):
            (negative_root / name).mkdir(parents=True, exist_ok=True)
        negative_result = run_emit(
            safec=safec,
            source=NEGATIVE_FIXTURE,
            out_dir=negative_root / "out",
            iface_dir=negative_root / "iface",
            ada_dir=negative_root / "ada",
            env=env,
            temp_root=temp_root,
            expected_returncode=1,
        )
        require(
            "PR09 emitter does not yet support discriminated or variant record emission"
            in negative_result["stderr"],
            f"{NEGATIVE_FIXTURE}: expected emitter-only unsupported stderr",
        )

        seeded_negative_root = temp_root / "negative-seeded"
        seed_file(
            seeded_negative_root / "out" / f"{NEGATIVE_FIXTURE.stem.lower()}.ast.json",
            '{"sentinel":"ast"}\n',
        )
        seed_file(
            seeded_negative_root / "out" / f"{NEGATIVE_FIXTURE.stem.lower()}.typed.json",
            '{"sentinel":"typed"}\n',
        )
        seed_file(
            seeded_negative_root / "out" / f"{NEGATIVE_FIXTURE.stem.lower()}.mir.json",
            '{"sentinel":"mir"}\n',
        )
        seed_file(
            seeded_negative_root / "iface" / f"{NEGATIVE_FIXTURE.stem.lower()}.safei.json",
            '{"sentinel":"safei"}\n',
        )
        seed_file(
            seeded_negative_root / "ada" / f"{NEGATIVE_ADA_STEM}.ads",
            "-- sentinel spec\n",
        )
        seed_file(
            seeded_negative_root / "ada" / f"{NEGATIVE_ADA_STEM}.adb",
            "-- sentinel body\n",
        )
        seed_file(
            seeded_negative_root / "ada" / "safe_runtime.ads",
            "-- stale runtime\n",
        )
        seed_file(
            seeded_negative_root / "ada" / "gnat.adc",
            "-- stale adc\n",
        )
        seeded_before = {
            "out": file_hashes(seeded_negative_root / "out"),
            "iface": file_hashes(seeded_negative_root / "iface"),
            "ada": file_hashes(seeded_negative_root / "ada"),
        }
        seeded_negative_result = run_emit(
            safec=safec,
            source=NEGATIVE_FIXTURE,
            out_dir=seeded_negative_root / "out",
            iface_dir=seeded_negative_root / "iface",
            ada_dir=seeded_negative_root / "ada",
            env=env,
            temp_root=temp_root,
            expected_returncode=1,
        )
        require(
            seeded_before["out"] == file_hashes(seeded_negative_root / "out"),
            f"{NEGATIVE_FIXTURE}: seeded JSON outputs changed on failed emit",
        )
        require(
            seeded_before["iface"] == file_hashes(seeded_negative_root / "iface"),
            f"{NEGATIVE_FIXTURE}: seeded interface outputs changed on failed emit",
        )
        require(
            seeded_before["ada"] == file_hashes(seeded_negative_root / "ada"),
            f"{NEGATIVE_FIXTURE}: seeded Ada outputs changed on failed emit",
        )

        stale_root = temp_root / "stale-cleanup"
        for name in ("out", "iface", "ada"):
            (stale_root / name).mkdir(parents=True, exist_ok=True)
        seed_file(stale_root / "ada" / "safe_runtime.ads", "-- stale runtime\n")
        seed_file(stale_root / "ada" / "gnat.adc", "-- stale adc\n")
        stale_before = file_hashes(stale_root / "ada")
        run_emit(
            safec=safec,
            source=SURFACE_FIXTURES[0],
            out_dir=stale_root / "out",
            iface_dir=stale_root / "iface",
            ada_dir=stale_root / "ada",
            env=env,
            temp_root=temp_root,
        )
        ensure_emit_success(source=SURFACE_FIXTURES[0], root=stale_root)
        stale_after = emitted_ada_files(stale_root / "ada")
        require(
            "safe_runtime.ads" not in stale_after,
            f"{SURFACE_FIXTURES[0]}: stale safe_runtime.ads should be removed",
        )
        require(
            "gnat.adc" not in stale_after,
            f"{SURFACE_FIXTURES[0]}: stale gnat.adc should be removed",
        )

        return {
            "positive_fixtures": positives,
            "negative_fixture": {
                "fixture": repo_arg(NEGATIVE_FIXTURE),
                "result": negative_result,
                "stderr_first_line": negative_result["stderr"].splitlines()[0],
                "atomic_outputs": ensure_emit_failure_is_atomic(root=negative_root),
            },
            "negative_fixture_seeded_outputs_preserved": {
                "fixture": repo_arg(NEGATIVE_FIXTURE),
                "result": seeded_negative_result,
                "before": seeded_before,
                "after": {
                    "out": file_hashes(seeded_negative_root / "out"),
                    "iface": file_hashes(seeded_negative_root / "iface"),
                    "ada": file_hashes(seeded_negative_root / "ada"),
                },
            },
            "stale_optional_cleanup": {
                "fixture": repo_arg(SURFACE_FIXTURES[0]),
                "before": stale_before,
                "after_files": stale_after,
            },
        }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()

    safec = require_safec()
    env = ensure_sdkroot(os.environ.copy())
    report = finalize_deterministic_report(
        lambda: generate_report(safec=safec, env=env),
        label="PR09a surface",
    )
    write_report(args.report, report)
    print(f"pr09a emitter surface: OK ({display_path(args.report, repo_root=REPO_ROOT)})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, FileNotFoundError) as exc:
        print(f"pr09a emitter surface: ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
