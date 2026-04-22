"""Policy drift checks for the tracked hook and CI proof split."""

from __future__ import annotations

from pathlib import Path

from _lib.test_harness import REPO_ROOT, RunCounts, record_result


HOOK_PATH = REPO_ROOT / ".githooks" / "pre-push"
INSTALLER_PATH = REPO_ROOT / "scripts" / "install_git_hooks.py"
CI_WORKFLOW_PATH = REPO_ROOT / ".github" / "workflows" / "ci.yml"
CLAUDE_MD_PATH = REPO_ROOT / "CLAUDE.md"

HOOK_COMMANDS = [
    "python3 scripts/run_tests.py",
    "python3 scripts/run_samples.py",
    "python3 scripts/run_proofs.py --level=1",
    "python3 scripts/snapshot_emitted_ada.py --check",
]

INSTALLER_SNIPPETS = [
    "core.hooksPath",
    ".githooks",
    ".git/hooks/pre-push",
]

CLAUDE_CI_STRUCTURE_SNIPPETS = [
    "python3 scripts/install_git_hooks.py",
    "pre-push hook",
    "scripts/run_proofs.py --mode=check",
    "scripts/run_proofs.py --level=1",
    "scripts/run_proofs.py --level=2",
    "scripts/snapshot_emitted_ada.py --check",
]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_ci_job_block(text: str, *, job_name: str) -> str | None:
    lines = text.splitlines()
    header = f"  {job_name}:"
    start_index: int | None = None
    for index, line in enumerate(lines):
        if line == header:
            start_index = index + 1
            break
    if start_index is None:
        return None

    end_index = len(lines)
    for index in range(start_index, len(lines)):
        line = lines[index]
        if line.startswith("  ") and not line.startswith("    ") and line.rstrip().endswith(":"):
            end_index = index
            break
    return "\n".join(lines[start_index:end_index])


def extract_markdown_section(text: str, *, heading: str) -> str | None:
    start_marker = f"## {heading}\n"
    start = text.find(start_marker)
    if start == -1:
        return None
    start += len(start_marker)
    end = text.find("\n## ", start)
    if end == -1:
        end = len(text)
    return text[start:end]


def run_tracked_hook_policy_case() -> tuple[bool, str]:
    if not HOOK_PATH.exists():
        return False, f"missing tracked hook at {HOOK_PATH}"
    if (HOOK_PATH.stat().st_mode & 0o111) == 0:
        return False, f"tracked pre-push hook at {HOOK_PATH} is not executable"
    hook_text = read_text(HOOK_PATH)
    for expected in HOOK_COMMANDS:
        if expected not in hook_text:
            return False, f"tracked pre-push hook missing {expected!r}"
    if "SAFE_PRE_PUSH_SKIP=1" not in hook_text:
        return False, "tracked pre-push hook missing SAFE_PRE_PUSH_SKIP support"
    return True, ""


def run_hook_installer_policy_case() -> tuple[bool, str]:
    if not INSTALLER_PATH.exists():
        return False, f"missing hook installer at {INSTALLER_PATH}"
    installer_text = read_text(INSTALLER_PATH)
    for expected in INSTALLER_SNIPPETS:
        if expected not in installer_text:
            return False, f"hook installer missing {expected!r}"
    return True, ""


def run_ci_prove_policy_case() -> tuple[bool, str]:
    workflow_text = read_text(CI_WORKFLOW_PATH)
    prove_block = extract_ci_job_block(workflow_text, job_name="prove")
    if prove_block is None:
        return False, "missing prove job block in ci.yml"
    # This intentionally uses block text matching rather than a YAML parser to
    # keep the repo-local policy check dependency-free. Comments can fool it if
    # the workflow grows substantially more complex.
    for expected in (
        "run: python3 scripts/run_proofs.py --mode=check",
        "run: python3 scripts/run_proofs.py --level=2",
    ):
        if expected not in prove_block:
            return False, f"prove job block missing {expected!r}"
    return True, ""


def run_claude_ci_structure_policy_case() -> tuple[bool, str]:
    claude_text = read_text(CLAUDE_MD_PATH)
    ci_structure = extract_markdown_section(claude_text, heading="CI Structure")
    if ci_structure is None:
        return False, "missing CI Structure section in CLAUDE.md"
    for expected in CLAUDE_CI_STRUCTURE_SNIPPETS:
        if expected not in ci_structure:
            return False, f"CI Structure section missing {expected!r}"
    return True, ""


def run_policy_drift_checks() -> RunCounts:
    passed = 0
    failures: list[tuple[str, str]] = []
    passed += record_result(failures, "policy-drift tracked hook", run_tracked_hook_policy_case())
    passed += record_result(failures, "policy-drift hook installer", run_hook_installer_policy_case())
    passed += record_result(failures, "policy-drift ci prove", run_ci_prove_policy_case())
    passed += record_result(
        failures,
        "policy-drift CLAUDE CI structure",
        run_claude_ci_structure_policy_case(),
    )
    return passed, 0, failures
