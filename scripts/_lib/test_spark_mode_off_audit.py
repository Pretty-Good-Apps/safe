"""Baseline-gated checks for the Phase 1E SPARK_Mode Off scanner."""

from __future__ import annotations

import json
import subprocess
import sys

import audit_spark_mode_off
from _lib.test_harness import REPO_ROOT, RunCounts, first_message, record_result


AUDIT_SCRIPT = REPO_ROOT / "scripts" / "audit_spark_mode_off.py"
BASELINE_PATH = audit_spark_mode_off.BASELINE_PATH
ACCEPTED = "accepted-with-rationale"
VALID_CLASSIFICATIONS = {
    "candidate",
    "needs-repro",
    "confirmed-defect",
    ACCEPTED,
}


def validate_entries(payload: object, label: str) -> tuple[bool, str]:
    if not isinstance(payload, dict):
        return False, f"{label} top-level value is not an object"
    entries = payload.get("entries")
    if not isinstance(entries, list):
        return False, f"{label} missing entries list"
    fingerprints: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict):
            return False, f"{label} entry is not an object"
        for field in (
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
        ):
            if field not in entry:
                return False, f"{label} entry missing {field}"
        fingerprint = entry.get("fingerprint")
        if not isinstance(fingerprint, str) or not fingerprint:
            return False, f"{label} entry missing fingerprint"
        if fingerprint in fingerprints:
            return False, f"duplicate {label} fingerprint {fingerprint}"
        fingerprints.add(fingerprint)
        category = entry.get("category")
        if category not in audit_spark_mode_off.CATEGORIES:
            return False, f"invalid {label} category {category!r}"
        classification = entry.get("classification")
        if classification not in VALID_CLASSIFICATIONS:
            return False, f"invalid {label} classification {classification!r}"
    return True, ""


def entries_for(payload: dict[str, object]) -> list[dict[str, object]]:
    entries = payload["entries"]
    if not isinstance(entries, list):
        raise ValueError(f"entries field is not a list: {type(entries)!r}")
    return [entry for entry in entries if isinstance(entry, dict)]


def fingerprint_map(payload: dict[str, object]) -> dict[str, dict[str, object]]:
    return {str(entry["fingerprint"]): entry for entry in entries_for(payload)}


def describe_entry(entry: dict[str, object]) -> str:
    return (
        f"{entry.get('fingerprint')} "
        f"{entry.get('category')} "
        f"{entry.get('path')}:{entry.get('line')} "
        f"{entry.get('pattern')}"
    )


def read_baseline_payload() -> tuple[dict[str, object] | None, str]:
    if not BASELINE_PATH.exists():
        return None, f"missing baseline {BASELINE_PATH.relative_to(REPO_ROOT)}"
    try:
        payload = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return None, f"invalid baseline JSON: {exc}"
    if not isinstance(payload, dict):
        return None, "baseline top-level value is not an object"
    return payload, ""


def validate_closed_baseline(payload: dict[str, object]) -> tuple[bool, str]:
    ok, message = validate_entries(payload, "baseline")
    if not ok:
        return False, message
    for entry in entries_for(payload):
        classification = entry.get("classification")
        if classification != ACCEPTED:
            return (
                False,
                "closed Phase 1E baseline may only contain "
                f"{ACCEPTED!r}; found {classification!r} at {describe_entry(entry)}",
            )
        rationale = entry.get("rationale")
        if not isinstance(rationale, str) or not rationale.strip():
            return False, f"accepted baseline entry missing rationale: {describe_entry(entry)}"
    return True, ""


def compare_live_scan_to_baseline(
    live_payload: dict[str, object],
    baseline_payload: dict[str, object],
) -> tuple[bool, str]:
    ok, message = validate_entries(live_payload, "live scan")
    if not ok:
        return False, message
    ok, message = validate_entries(baseline_payload, "baseline")
    if not ok:
        return False, message
    live = fingerprint_map(live_payload)
    baseline = fingerprint_map(baseline_payload)
    new_fingerprints = sorted(set(live) - set(baseline))
    missing_fingerprints = sorted(set(baseline) - set(live))
    if new_fingerprints:
        examples = "; ".join(
            describe_entry(live[fingerprint]) for fingerprint in new_fingerprints[:5]
        )
        suffix = "" if len(new_fingerprints) <= 5 else f"; ... {len(new_fingerprints) - 5} more"
        message = (
            "Phase 1E SPARK Mode Off audit found "
            f"{len(new_fingerprints)} new fingerprint(s) outside the baseline: "
            f"{examples}{suffix}"
        )
        if missing_fingerprints:
            missing_examples = "; ".join(
                describe_entry(baseline[fingerprint]) for fingerprint in missing_fingerprints[:5]
            )
            missing_suffix = (
                ""
                if len(missing_fingerprints) <= 5
                else f"; ... {len(missing_fingerprints) - 5} more"
            )
            message += (
                ". Baseline drift also found "
                f"{len(missing_fingerprints)} fingerprint(s) no longer in live scan "
                f"(report-only): {missing_examples}{missing_suffix}"
            )
        return False, message
    if missing_fingerprints:
        examples = "; ".join(
            describe_entry(baseline[fingerprint]) for fingerprint in missing_fingerprints[:5]
        )
        suffix = (
            ""
            if len(missing_fingerprints) <= 5
            else f"; ... {len(missing_fingerprints) - 5} more"
        )
        return (
            True,
            "Phase 1E SPARK Mode Off audit baseline drift: "
            f"{len(missing_fingerprints)} fingerprint(s) no longer in live scan "
            f"(report-only): {examples}{suffix}",
        )
    return True, ""


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
    known_entry = synthetic_entry("known")
    baseline = {"entries": [known_entry]}
    new_entry = synthetic_entry("new")
    live_with_new = {"entries": [synthetic_entry("known"), new_entry]}
    ok, message = compare_live_scan_to_baseline(live_with_new, baseline)
    if ok or describe_entry(new_entry) not in message:
        return False, "new live fingerprint outside baseline did not fail gate"

    live_missing = {"entries": []}
    ok, message = compare_live_scan_to_baseline(live_missing, baseline)
    if not ok or describe_entry(known_entry) not in message:
        return False, f"missing live fingerprint should be reported only, got: {message}"

    gone_entry = synthetic_entry("gone")
    mixed_baseline = {"entries": [known_entry, gone_entry]}
    mixed_live = {"entries": [synthetic_entry("known"), new_entry]}
    ok, message = compare_live_scan_to_baseline(mixed_live, mixed_baseline)
    if ok or describe_entry(new_entry) not in message or describe_entry(gone_entry) not in message:
        return False, f"mixed new/missing fingerprints should both be reported, got: {message}"

    open_baseline = {"entries": [synthetic_entry("known", classification="candidate")]}
    ok, message = validate_closed_baseline(open_baseline)
    if ok or "candidate" not in message:
        return False, "open baseline classification did not fail closed-baseline validation"

    empty_rationale = {"entries": [synthetic_entry("known", rationale="")]}
    ok, message = validate_closed_baseline(empty_rationale)
    if ok or "rationale" not in message:
        return False, "accepted baseline entry with empty rationale did not fail validation"

    return True, ""


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
