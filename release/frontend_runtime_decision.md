# Frontend Runtime Decision

## Decision

Python is transitional only. The Safe reference compiler must remove the Python execution dependency and converge back to an Ada/SPARK frontend in staged replacement slices.

PR06.5 is the first concrete replacement slice: MIR validation is now Ada-native through `safec validate-mir`, and the PR05 / PR06 harnesses and CI jobs no longer depend on the Python MIR validator.

## Current Runtime Split

- Ada-native:
  - `safec lex`
  - `safec validate-mir`
- Python-backed reference frontend:
  - `safec ast`
  - `safec check`
  - `safec emit`

## Locked Replacement Order

1. MIR model and validator
2. MIR analyzer
3. D27 and ownership diagnostics renderer
4. Parser, resolver, typed model, and emit pipeline

## Rule for Later Milestones

Each later milestone must remove a concrete Python-owned slice. Parity scaffolding without a runtime cutover is not enough to close the Python dependency.

## Immediate Follow-On

The next runtime-focused work after PR06.5 is to move MIR analysis and semantic checking off the Python backend so `safec check` no longer depends on Python.
