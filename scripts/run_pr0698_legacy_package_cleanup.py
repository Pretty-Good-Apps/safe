#!/usr/bin/env python3
"""Run the PR06.9.8 dormant legacy package cleanup audit."""

from __future__ import annotations

import argparse
from pathlib import Path

from _lib.harness_common import (
    display_path,
    finalize_deterministic_report,
    find_command,
    require,
    write_report,
)
from validate_execution_state import legacy_frontend_cleanup_report


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_REPORT = REPO_ROOT / "execution" / "reports" / "pr0698-legacy-package-cleanup-report.json"


def generate_report() -> dict[str, object]:
    cleanup = legacy_frontend_cleanup_report()
    require(not cleanup["present_files"], f"legacy files still present: {cleanup['present_files']}")
    require(
        not cleanup["forbidden_references"],
        f"legacy references still present: {cleanup['forbidden_references']}",
    )
    require(
        not cleanup["live_runtime_reference_violations"],
        "live runtime roots still reference legacy frontend packages: "
        f"{cleanup['live_runtime_reference_violations']}",
    )
    require(
        not cleanup["retained_legacy_packages"],
        f"retained legacy packages must be empty: {cleanup['retained_legacy_packages']}",
    )
    return {
        "task": "PR06.9.8",
        "status": "ok",
        "legacy_frontend_cleanup": cleanup,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()

    find_command("python3")
    report = finalize_deterministic_report(
        generate_report,
        label="PR06.9.8 legacy package cleanup",
    )

    write_report(args.report, report)
    print(f"pr0698 legacy package cleanup: OK ({display_path(args.report, repo_root=REPO_ROOT)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
