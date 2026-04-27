"""Baseline-gated checks for the Phase 1D GNATprove trust-boundary scanner."""

from __future__ import annotations

import json
import subprocess
import sys

import audit_gnatprove_trust
from _lib import baseline_audit_gate
from _lib.test_harness import REPO_ROOT, RunCounts, first_message, record_result


AUDIT_SCRIPT = REPO_ROOT / "scripts" / "audit_gnatprove_trust.py"
BASELINE_PATH = REPO_ROOT / "audit" / "phase1d_gnatprove_trust_baseline.json"
PHASE_LABEL = "Phase 1D GNATprove trust"
ACCEPTED = baseline_audit_gate.ACCEPTED
REQUIRED_FIELDS = (
    "fingerprint",
    "category",
    "pattern",
    "path",
    "line",
    "line_numbers",
    "first_line_text",
    "line_text",
    "classification",
    "rationale",
    "follow_up",
)


def validate_entries(payload: object, label: str) -> tuple[bool, str]:
    return baseline_audit_gate.validate_entries(
        payload,
        label,
        required_fields=REQUIRED_FIELDS,
    )


def read_baseline_payload() -> tuple[dict[str, object] | None, str]:
    return baseline_audit_gate.read_baseline_payload(BASELINE_PATH, repo_root=REPO_ROOT)


def validate_closed_baseline(payload: dict[str, object]) -> tuple[bool, str]:
    return baseline_audit_gate.validate_closed_baseline(
        payload,
        phase_label=PHASE_LABEL,
        required_fields=REQUIRED_FIELDS,
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
    # Match Phase 1C audit behavior: run_tests.py emits audit summaries visibly.
    audit_gnatprove_trust.print_summary(
        payload,
        baseline_entries=audit_gnatprove_trust.existing_classifications(),
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


def run_statement_scanner_case() -> tuple[bool, str]:
    source = (
        'pragma Annotate (GNATprove, Intentional, "overflow (see A-05); safe");\n'
        "Afterward;"
    )
    end = audit_gnatprove_trust.statement_end(source, 0)
    if end is None:
        return False, "statement scanner did not find pragma terminator"
    matched = source[:end]
    if '"overflow (see A-05); safe"' not in matched:
        return False, "statement scanner truncated string-literal punctuation"
    if matched.endswith("Afterward;"):
        return False, "statement scanner consumed the following statement"
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
    rationale: str = "Accepted: synthetic trust-boundary test entry.",
) -> dict[str, object]:
    return {
        "fingerprint": fingerprint,
        "category": "synthetic",
        "pattern": "synthetic-pattern",
        "path": "compiler_impl/src/synthetic.adb",
        "line": 1,
        "line_numbers": [1],
        "first_line_text": "pragma Synthetic;",
        "line_text": "pragma Synthetic;",
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
    )


def run_gnatprove_trust_audit_checks() -> RunCounts:
    passed = 0
    failures = []
    passed += record_result(failures, "phase1d-gnatprove-trust-audit:scan", run_live_scan_case())
    passed += record_result(
        failures,
        "phase1d-gnatprove-trust-audit:statement-scanner",
        run_statement_scanner_case(),
    )
    passed += record_result(
        failures,
        "phase1d-gnatprove-trust-audit:baseline",
        run_baseline_case(),
    )
    passed += record_result(
        failures,
        "phase1d-gnatprove-trust-audit:gate-self-check",
        run_gate_self_check_case(),
    )
    return passed, 0, failures
