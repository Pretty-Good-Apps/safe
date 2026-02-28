# Safe Spec — Follow-up Comparison (Spec vs. Prior Analysis Output)

## Baseline and Scope

This report compares the current spec documents in `spec/` against the prior session’s analysis output in `spec-analysis.md` (a duplicate copy also exists at `references/spec-analysis.md`).

Additionally, the upstream reference documents named in `SPEC-PROMPT.md` have been fetched and saved under `references/upstream/` for offline review; see `references/upstream/README.md`.

## Summary

- The spec in `spec/` still matches the overall assessment in `spec-analysis.md`: high conformance to `SPEC-PROMPT.md`, with a small number of cleanup items.
- Several “Issues Found” items in `spec-analysis.md` are confirmed as still present.
- A few items in `spec-analysis.md` were either already addressed in the spec text or were “not visible in the portion read”; those are corrected below.

## File-by-File Verification Against `spec-analysis.md`

### `spec/00-front-matter.md`

- **Prior analysis:** “STRONG — fully conformant with minor notes.”
- **Verified:** No material drift. Title, `.safe`, scope, normative reference to ISO/IEC 8652:2023, conventions, structure table, and D1–D29 summary table are present.
- **No corrections** to the prior analysis found.

### `spec/01-base-definition.md`

- **Prior analysis:** “STRONG — matches spec exactly.”
- **Verified:** Still brief and correctly defines Safe as 8652:2023 restricted/modified by Sections 2–4 with a compact “modified sections” table.
- **No corrections** to the prior analysis found.

### `spec/02-restrictions.md`

- **Prior analysis:** “STRONG — comprehensive,” with table inconsistencies and “conditional retentions not resolved.”
- **Verified (still-open issues from prior analysis):**
  - `Normalize_Scalars` is presented in the retained pragmas table but annotated as excluded (“Excluded — see note”), which is confusing.
  - `No_Return` appears in both the retained and excluded pragma tables with notes implying retention.
  - Conditional language remains in a few places (e.g., “retained if part of the SPARK 2022 subset”) for constructs like declare expressions and `for E of Array_Name`.
- **Additional note:** These are editorial/consistency cleanups rather than structural gaps; the underlying restriction coverage remains extensive.

### `spec/03-single-file-packages.md`

- **Prior analysis:** “STRONG — complete coverage,” with notes on child visibility and type-annotation parenthesization.
- **Verified:**
  - The child-package visibility change is explicitly documented (Safe has no private part and no private children; child sees only parent `public` plus what it `with`s).
  - The spec deliberately requires parentheses for annotated expressions (`(expr : Type)`), which is stricter than the prompt’s “`:` binds loosest” guidance but is internally consistent.
- **No corrections** to the prior analysis found.

### `spec/04-tasks-and-channels.md`

- **Prior analysis:** flagged “task termination detail” and claimed Section 4 didn’t explicitly discuss `delay until`.
- **Verified (correction to prior analysis):**
  - Section 4 *does* explicitly discuss `delay until` in §4.9 (paragraph 139), stating both `delay duration` and `delay until time` forms are available.
- **Verified (still-open issue from prior analysis):**
  - Task termination behavior for owned package variables is specified, but enforcement remains primarily “by construction” (static ownership + compile-time rejection). If a stronger runtime model is intended (e.g., poisoning/guards), that isn’t specified.
- **New issue / clarification request:**
  - §4.9(139) mentions `Ada.Real_Time.Time` “if retained per Annex A”, but `Ada.Real_Time` is excluded in `spec/07-annex-a-retained-library.md` (Annex D real-time). This creates an internal inconsistency: `delay until` should be defined in terms of retained time types (likely `Ada.Calendar.Time`) or explicitly constrained.

### `spec/05-spark-assurance.md`

- **Prior analysis:** noted division example labeling and lack of a concrete GNATprove command for concurrency assurance.
- **Verified (still-open issues from prior analysis):**
  - §5.6.3 presents a `Speed` example under “Safe source” and then immediately labels it ILLEGAL under Rule 3, followed by the corrected form. It’s understandable, but could be made more explicit as “incorrect attempt” vs “correct form”.
  - §5.4.4 is normative but does not give a concrete `gnatprove ...` invocation analogous to Bronze and Silver requirement statements.

### `spec/06-conformance.md`

- **Prior analysis:** noted runtime LOC estimate mismatch and a library-unit restriction not explicitly demanded by the prompt.
- **Verified (still-open issues from prior analysis):**
  - The runtime LOC breakdown totals lower than the SPEC-PROMPT estimates; likely harmless, but the document currently mixes “approximately 900” (prompt) vs a smaller explicit total.
  - The “library units are packages only” restriction is a plausible consequence of the design, but it is an extra constraint beyond the prompt’s explicit text (still may be desirable).

### `spec/07-annex-a-retained-library.md`

- **Prior analysis:** praised exhaustive enumeration; flagged Ada.Strings wording confusion; and stated System/Ada.Calendar weren’t visible.
- **Verified:**
  - `System` *is* explicitly covered (see “C — The Package System”).
  - `Ada.Calendar` *is* explicitly covered and retained with modifications (exceptions removed; formatting/time zones excluded).
- **Verified (still-open issue from prior analysis):**
  - The `Ada.Strings` section mixes terminology: it refers to “type declarations and constants (`Space`, `Length_Error`, …)” and then separately says exception declarations are excluded. In Ada, the `*_Error` identifiers are exceptions, not constants. The intent is clear (remove exceptions), but the text should be corrected for precision.

### `spec/07-annex-b-c-interface.md`

- **Prior analysis:** “EXCELLENT,” with a note about de-overloading Interfaces.C conversions.
- **Verified:** No contradictions with the prior analysis found in a spot check (retained pragmas, Interfaces coverage, platform notes).

### `spec/07-annex-c-impl-advice.md`

- **Prior analysis:** “EXCELLENT — exceeds requirements.”
- **Verified:** No contradictions with the prior analysis found in a spot check.

### `spec/08-syntax-summary.md`

- **Prior analysis:** “EXCELLENT” overall, but flagged `abstract` appearing in productions despite D18.
- **Verified (still-open issue from prior analysis):**
  - `abstract` still appears in `record_type_definition` and `derived_type_definition` productions even though abstract/tagged types are excluded.
- **Verified:** Reserved-words retention (keeping excluded-feature keywords reserved) remains consistent with the prior analysis.

## Reference Material Retrieval (from `SPEC-PROMPT.md`)

The “Reference Documents” URLs listed in `SPEC-PROMPT.md` have been fetched and saved locally:

- Directory: `references/upstream/`
- Index: `references/upstream/README.md`
- Integrity hashes: `references/upstream/SHA256SUMS.txt`

## Updated Shortlist of Action Items

If you want the spec tightened based on the findings above, the highest-impact edits are:

1. Fix the `Normalize_Scalars` / `No_Return` pragma table inconsistencies in `spec/02-restrictions.md`.
2. Resolve “retained if part of SPARK 2022 subset” conditionals into definitive retained/excluded statements where possible.
3. Clarify `delay until`’s time type(s) in `spec/04-tasks-and-channels.md` to match Annex A decisions (Calendar vs. Real_Time).
4. Remove `abstract` from the relevant grammar productions in `spec/08-syntax-summary.md`.
5. Clean up the `Ada.Strings` wording in `spec/07-annex-a-retained-library.md` to avoid treating exceptions as constants.
