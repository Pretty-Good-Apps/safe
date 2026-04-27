"""Baseline-gated checks for the Phase 1E SPARK_Mode Off scanner."""

from __future__ import annotations

import json
import subprocess
import sys

import audit_spark_mode_off
from _lib import baseline_audit_gate
from _lib.test_harness import REPO_ROOT, RunCounts, first_message, record_result


AUDIT_SCRIPT = REPO_ROOT / "scripts" / "audit_spark_mode_off.py"
BASELINE_PATH = audit_spark_mode_off.BASELINE_PATH
PHASE_LABEL = "Phase 1E SPARK Mode Off"
ACCEPTED = baseline_audit_gate.ACCEPTED
REQUIRED_FIELDS = (
    "fingerprint",
    "category",
    "pattern",
    "path",
    "line",
    "line_numbers",
    "first_line_text",
    "multiplicity",
    "classification",
    "rationale",
    "follow_up",
)


def validate_entries(payload: object, label: str) -> tuple[bool, str]:
    return baseline_audit_gate.validate_entries(
        payload,
        label,
        required_fields=REQUIRED_FIELDS,
        valid_categories=audit_spark_mode_off.CATEGORIES,
    )


def read_baseline_payload() -> tuple[dict[str, object] | None, str]:
    return baseline_audit_gate.read_baseline_payload(BASELINE_PATH, repo_root=REPO_ROOT)


def validate_closed_baseline(payload: dict[str, object]) -> tuple[bool, str]:
    return baseline_audit_gate.validate_closed_baseline(
        payload,
        phase_label=PHASE_LABEL,
        required_fields=REQUIRED_FIELDS,
        valid_categories=audit_spark_mode_off.CATEGORIES,
    )


def compare_live_scan_to_baseline(
    live_payload: dict[str, object],
    baseline_payload: dict[str, object],
) -> tuple[bool, str]:
    return baseline_audit_gate.compare_live_scan_to_baseline(
        live_payload,
        baseline_payload,
        phase_label=PHASE_LABEL,
        required_fields=REQUIRED_FIELDS,
        valid_categories=audit_spark_mode_off.CATEGORIES,
    )


def run_live_scan_case() -> tuple[bool, str]:
    completed = subprocess.run(
        [sys.executable, str(AUDIT_SCRIPT), "--json"],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        return False, first_message(completed)
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        return False, f"invalid scanner JSON: {exc}"
    ok, message = validate_entries(payload, "scanner JSON")
    if not ok:
        return False, message
    # Match Phase 1C/1D audit behavior: run_tests.py emits audit summaries visibly.
    audit_spark_mode_off.print_summary(
        payload,
        baseline_entries=audit_spark_mode_off.existing_classifications(),
    )
    baseline, message = read_baseline_payload()
    if baseline is None:
        return False, message
    ok, message = validate_closed_baseline(baseline)
    if not ok:
        return False, message
    ok, message = compare_live_scan_to_baseline(payload, baseline)
    if not ok:
        return False, message
    if message:
        print(message)
    return True, ""


def run_baseline_case() -> tuple[bool, str]:
    payload, message = read_baseline_payload()
    if payload is None:
        return False, message
    return validate_closed_baseline(payload)


def synthetic_entry(
    fingerprint: str,
    *,
    classification: str = ACCEPTED,
    rationale: str = "Accepted: synthetic SPARK Mode Off test entry.",
) -> dict[str, object]:
    return {
        "fingerprint": fingerprint,
        "category": "emitted-spark-off-pragma",
        "pattern": "spark-mode-off-pragma",
        "path": "compiler_impl/src/synthetic.adb",
        "line": 1,
        "line_numbers": [1],
        "first_line_text": 'Append_Line (Buffer, "pragma SPARK_Mode (Off);", 2);',
        "multiplicity": 1,
        "classification": classification,
        "rationale": rationale,
        "follow_up": "",
    }


def run_gate_self_check_case() -> tuple[bool, str]:
    return baseline_audit_gate.run_gate_self_check(
        phase_label=PHASE_LABEL,
        synthetic_entry=synthetic_entry,
        required_fields=REQUIRED_FIELDS,
        valid_categories=audit_spark_mode_off.CATEGORIES,
    )


def run_comment_scanner_case() -> tuple[bool, str]:
    line = 'Append_Line (Buffer, "pragma SPARK_Mode (Off);", 2); -- SPARK_Mode (Off)'
    stripped = audit_spark_mode_off.strip_comments_keep_strings(line)
    if "--" in stripped:
        return False, "comment scanner retained Ada comment text"
    if '"pragma SPARK_Mode (Off);"' not in stripped:
        return False, "comment scanner removed string-literal target text"
    if not audit_spark_mode_off.PATTERNS[0].regex.search(stripped):
        return False, "pragma pattern did not match generated string literal"
    return True, ""


def run_category_assignment_case() -> tuple[bool, str]:
    emitted = REPO_ROOT / "compiler_impl" / "src" / "safe_frontend-ada_emit.adb"
    compiler = REPO_ROOT / "compiler_impl" / "src" / "safe_frontend-mir_analyze.adb"
    runtime = REPO_ROOT / "compiler_impl" / "stdlib" / "ada" / "io.adb"
    pragma_pattern = audit_spark_mode_off.PATTERNS[0]
    aspect_pattern = audit_spark_mode_off.PATTERNS[1]
    cases = {
        "compiler-spark-off-pragma": audit_spark_mode_off.category_for(compiler, pragma_pattern),
        "compiler-spark-off-aspect": audit_spark_mode_off.category_for(compiler, aspect_pattern),
        "emitted-spark-off-pragma": audit_spark_mode_off.category_for(emitted, pragma_pattern),
        "emitted-spark-off-aspect": audit_spark_mode_off.category_for(emitted, aspect_pattern),
        "runtime-spark-off-pragma": audit_spark_mode_off.category_for(runtime, pragma_pattern),
        "runtime-spark-off-aspect": audit_spark_mode_off.category_for(runtime, aspect_pattern),
    }
    for expected, actual in cases.items():
        if actual != expected:
            return False, f"expected {expected}, got {actual}"
    unsupported = REPO_ROOT / "README.md"
    try:
        audit_spark_mode_off.category_for(unsupported, pragma_pattern)
    except ValueError:
        pass
    else:
        return False, "unsupported non-scan path did not fail loud"
    return True, ""


def run_spark_mode_off_audit_checks() -> RunCounts:
    passed = 0
    failures = []
    passed += record_result(failures, "phase1e-spark-mode-off-audit:scan", run_live_scan_case())
    passed += record_result(
        failures,
        "phase1e-spark-mode-off-audit:baseline",
        run_baseline_case(),
    )
    passed += record_result(
        failures,
        "phase1e-spark-mode-off-audit:comment-scanner",
        run_comment_scanner_case(),
    )
    passed += record_result(
        failures,
        "phase1e-spark-mode-off-audit:category-assignment",
        run_category_assignment_case(),
    )
    passed += record_result(
        failures,
        "phase1e-spark-mode-off-audit:gate-self-check",
        run_gate_self_check_case(),
    )
    return passed, 0, failures
