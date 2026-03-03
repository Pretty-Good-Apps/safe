# Findings — Issues Discovered in SPEC-PROMPT.md

**These findings are flagged for human review. No patches have been applied to SPEC-PROMPT.md.**

---

## F1. `abstract` in Grammar Despite Being Excluded — RESOLVED

**Location:** D18 (No Tagged Types), D23 (Retained Ada Features)

**Issue:** The 8652:2023 grammar for `record_type_definition` includes `[ 'abstract' ] 'limited'` as an optional prefix. Since abstract types are excluded by D18, the `abstract` keyword should not appear in the Safe grammar's record type productions. However, removing it creates a divergence from the 8652:2023 production structure that could confuse readers comparing the two grammars.

**Resolution:** Removed `abstract` from the `record_type_definition` production in §08 (syntax summary). The production now reads `[ 'limited' ] record_definition`. The `abstract` keyword remains reserved (per the policy that all Ada 2022 reserved words stay reserved in Safe) but no longer appears in any grammar production. The §02 paragraph 7 legality rule rejecting `abstract` type declarations is unchanged — it now serves as belt-and-suspenders reinforcement rather than the sole enforcement mechanism. This is consistent with how every other excluded feature (generics, tagged types, exceptions, etc.) was handled: productions removed from §08, legality rules in §02 for completeness.

---

## F2. `delay until` Time Type Unspecified — RESOLVED

**Location:** D23 (Retained Ada Features), D28 (section on delay in select arms)

**Issue:** `delay until` is retained and appears in the grammar and in §04 select statement delay arms. However, `delay until` in 8652:2023 requires a time value (typically `Ada.Calendar.Clock` or `Ada.Real_Time.Clock`). Both `Ada.Calendar` and `Ada.Real_Time` are excluded (Annex A). SPEC-PROMPT.md retains `delay Duration_Expression` but does not explicitly address the time type for `delay until`.

**Resolution:** Excluded `delay until` entirely. Only the relative delay `delay Duration_Expression;` is retained. Changes applied: §08 grammar (removed `'delay' 'until' expression ';'` alternative), §02 paragraph 60 (exclusion with legality rule and rationale), §02 paragraph 86 (removed implementation-defined time type note), Annex A paragraph 59 (removed shall-provide-time-type requirement), §06 (removed time type from implementation-defined items list and narrowed runtime requirement to relative `delay` only). Rationale: with both `Ada.Calendar` and `Ada.Real_Time` excluded, no language-defined time type exists for absolute delays; relative delays via `Duration` cover the primary use cases (periodic task loops, select timeouts). A future revision may reintroduce `delay until` alongside a minimal monotonic time package if absolute timing proves necessary.

---

## F3. Quantified Expressions Exclusion vs. SPARK Subset — RESOLVED (no spec change)

**Location:** D23 (Retained Ada Features), implied by "All Ada 2022 features in the SPARK 2022 subset not otherwise excluded"

**Issue:** Quantified expressions (`for all`, `for some`) are part of the SPARK 2022 subset. D23 states "All Ada 2022 features in the SPARK 2022 subset not otherwise excluded" are retained. However, quantified expressions are primarily useful in contracts, which are excluded (D19). The generated spec excludes them (§02 paragraph 22), but SPEC-PROMPT.md does not explicitly list them as excluded.

**Resolution:** The generated spec correctly excludes quantified expressions in §02 paragraph 22 with appropriate rationale, and §08 contains no `quantified_expression` production. The spec is internally consistent. The gap is in SPEC-PROMPT.md only (quantified expressions should be added to D19's exclusion list for clarity). No spec changes required. While `for all`/`for some` can technically appear in ordinary boolean expressions, their primary utility is in contracts, type predicates, and loop invariants — all excluded. Their marginal value in ordinary `if` conditions does not justify the compiler complexity of implicit iteration in expression position.

---

## F4. D17 Ownership Table Column for Emitted Ada — RESOLVED (no spec change)

**Location:** D17 Ownership model summary table

**Issue:** The D17 table in SPEC-PROMPT.md has two columns: "Safe construct" and "Ownership semantics." Previous revisions (per CHANGELOG.md) removed the "Emitted Ada" column as part of the tool-independence refactoring. However, the table entry for `procedure P (A : in T_Ptr)` says "Read-only access: caller's ownership frozen" — this is described as "observing" in §2.3 but the table says "Read-only access." The terminology is inconsistent between the table summary and the detailed ownership rules.

**Resolution:** The generated spec's §02 §2.3 ownership table (paragraph 95) and detailed rules (§2.3.2–§2.3.4) use consistent terminology throughout: "Owner," "Local borrower," "Local observer," "borrow," "observe," "move." The terminology inconsistency exists only in SPEC-PROMPT.md's D17 summary table, not in the generated spec. SPEC-PROMPT.md should align its D17 table with the formal terms for clarity, but no spec changes are required.

---

## F5. `Convention` Pragma Listed in Both Retained and Excluded — RESOLVED

**Location:** §02 Pragma Inventory generation

**Issue:** SPEC-PROMPT.md §D24 excludes all foreign language interface including `pragma Convention`. However, `Convention` could be argued as retained for the `Convention(Ada, ...)` case, which is the default. The generated spec listed it as excluded (under paragraph 84, Annex B exclusion), but it also appeared in the retained pragmas table (§2.6.1 paragraph 121) with a cross-reference "Excluded — see paragraph 84," which was confusing.

**Resolution:** Removed `Convention` and `Linker_Options` from the retained pragma table (§2.6.1) and added them to the excluded pragma table (§2.6.2) with rationale "Requires foreign language interface." `Convention(Ada, ...)` is the default convention and never needs explicit statement — Ada types have Ada convention automatically. There is no use case for the pragma in Safe source. Each pragma now appears in exactly one table.

---

## F6. `Normalize_Scalars` Ambiguity — RESOLVED (no spec change)

**Location:** Pragma inventory

**Issue:** The prior spec-analysis.md noted that `Normalize_Scalars` appeared in both retained and excluded categories in a previous generation. SPEC-PROMPT.md does not explicitly classify it. Annex H is mostly excluded (§02 paragraph 90), but `Normalize_Scalars` is a standalone pragma (§H.1) that could be useful for initialisation safety.

**Resolution:** The generated spec correctly excludes `Normalize_Scalars` in §02 §2.6.2 (paragraph 122) with rationale: "Implementation concern; may mask uninitialised reads." This is the right call — `Normalize_Scalars` silently initialises variables to out-of-range trap values, which masks the uninitialised-read bugs that Safe's Silver guarantee is designed to catch statically. The pragma appears in exactly one table (excluded). SPEC-PROMPT.md should add this to its explicit exclusion list for clarity, but no spec changes are required.

---

## F7. `from` as Reserved Word — RESOLVED

**Location:** D28 grammar additions, Reserved Words section

**Issue:** SPEC-PROMPT.md's reserved words section lists `public`, `channel`, `send`, `receive`, `try_send`, `try_receive`, `capacity` as new reserved words. However, the D28 grammar for `channel_arm` uses `from` as a keyword: `'when' identifier ':' type_mark 'from' channel_name`. The reserved words section does not list `from` as a new reserved word. `from` is not an Ada 2022 reserved word either (it does not appear in 8652:2023 §2.9).

**Resolution:** Added `from` to the Safe additional reserved words list in both §02 paragraph 3 and §08 §8.15. The list now reads: `public`, `channel`, `send`, `receive`, `try_send`, `try_receive`, `capacity`, `from`. SPEC-PROMPT.md should also be updated to include `from` in its reserved words section.

---

## F8. Subprogram Forward Declaration `public` Placement — RESOLVED

**Location:** D10 (Subprogram Bodies at Point of Declaration)

**Issue:** SPEC-PROMPT.md states forward declarations are permitted for mutual recursion but does not specify whether the `public` keyword appears on the forward declaration, the completing body, or both. The generated spec resolved this in §03 paragraph 14 but the original wording was ambiguous.

**Resolution:** Clarified §03 paragraph 14 to state unambiguously: `public` appears on the forward declaration only; the completing body shall not repeat `public`; a conforming implementation shall reject a completing body bearing `public` when a forward declaration exists. This matches the principle that visibility is established at first declaration. SPEC-PROMPT.md should add this clarification to D10.

---

## F9. Task Body Declarative Part Placement — RESOLVED (no spec change)

**Location:** D28 task declaration grammar

**Issue:** SPEC-PROMPT.md's D28 grammar has no `declarative_part` before `begin` in the task declaration, but D28 prose says "Declarations may precede the loop" and the non-termination rule says "Declarations may precede the outermost loop."

**Resolution:** The generated spec grammar (§08 §8.12) includes `[ declarative_part ]` before `begin` in the task declaration, matching the pattern used for subprogram bodies. This gives task bodies the same structure as subprogram bodies: an optional pre-`begin` declarative part plus interleaved declarations after `begin` (per D11). The spec is internally consistent. SPEC-PROMPT.md's D28 grammar should be updated to include `[ declarative_part ]` for consistency with the prose, but no spec changes are required.

---

## F10. Allocation Failure Semantics — RESOLVED

**Location:** D17, D27

**Issue:** SPEC-PROMPT.md specifies automatic deallocation but does not address what happens when `new` fails to allocate memory. In 8652:2023, this raises `Storage_Error`, which is an exception — and exceptions are excluded. The Silver guarantee (D27) does not address allocation failure.

**Resolution:** Added normative paragraph 103a to §02 §2.3.5 specifying that allocation failure invokes the runtime abort handler with a source location diagnostic, consistent with the error model for `pragma Assert` failure. Both are non-recoverable conditions that terminate the program. This replaces 8652:2023's `Storage_Error` exception with a hard abort. TBD-03 remains open for future work on static allocation bounding as a potential Safe/Assured enhancement.

---

## F11. `Channel_Id.Range` Attribute — RESOLVED (false positive)

**Location:** Quick Reference example in SPEC-PROMPT.md

**Issue:** The quick reference example uses `Channel_Id.Range` as an attribute in a for loop: `for I in Channel_Id.Range loop`. The finding claimed that `Range` is an attribute of array types only (§3.6.2), not of scalar types.

**Resolution:** This finding is incorrect. 8652:2023 §3.5(14) defines the `Range` attribute for any scalar subtype S as equivalent to `S.First .. S.Last` (in Safe dot notation; Ada tick notation: `S'First .. S'Last`). The generated spec's retained attribute table (§02 §2.5) correctly lists `Range` with references to both §3.5(14) (scalar types) and §3.6.2(7) (array types). `Channel_Id.Range` in Safe dot notation is valid. No changes required.

---

## F12. Missing D3/D4/D5/D25/D29 in Specification — RESOLVED

**Location:** SPEC-PROMPT.md Design Decisions

**Issue:** SPEC-PROMPT.md defines decisions D1, D2, D6–D28 in the main Design Decisions section. D3, D4, D5, D25, and D29 were moved to DEFERRED-IMPL-CONTENT.md as implementation-profile decisions, creating numbering gaps that could confuse readers.

**Resolution:** Added an explanatory note to §00 paragraph 26 identifying the missing decision numbers (D3, D4, D5, D25, D29) as reclassified implementation-profile decisions, stating the gaps are intentional and preserved for traceability. Renumbering was not chosen because it would break cross-references in DEFERRED-IMPL-CONTENT.md, CHANGELOG.md, and any external documents referencing the original D-numbers.

---

## F13. D27 Rule 2 Unsound for Constrained and Unconstrained Arrays — RESOLVED

**Location:** §02 §2.8.2 (Rule 2), §05 §5.3.3, SPEC-PROMPT.md D27 Rule 2

**Severity:** High

**Issue:** Rule 2 as originally stated required only that the index expression's type match the array's index type. This is sufficient when the array object's bounds span the full range of the index type (e.g., `array (Channel_Id) of T` indexed by `Channel_Id`). However, it is unsound when:

   (a) The array object has a narrower constraint: `Partial : array (Channel_Id range 0 .. 3) of T;` indexed by `Ch : Channel_Id` (range 0..7) — type matches but index 5 is out of bounds.

   (b) The array is an unconstrained parameter: `procedure P (B : Buffer)` where `Buffer is array (Positive range <>) of Character` — `B(1)` passes the type check but `B` may have bounds 10..20.

In both cases, the Silver claim ("all index checks are dischargeable") is false under the original rule.

**Resolution:** Replaced Rule 2 with a provable-containment rule. A conforming implementation accepts an indexed_component if: (a) the index expression's type/subtype range is statically contained within the array object's index constraint (type containment — preserves the original rule as a fast path for the common case), or (b) the implementation can establish by sound static range analysis that the index value is within the array's bounds (e.g., after a conditional guard, or using bounds-derived expressions like `B.First`). If neither holds, the program is rejected. This uses the same static analysis machinery already required for Rule 1 (narrowing checks) and Rule 3 (division checks).

Changes applied: §02 §2.8.2 (complete rewrite of paragraphs 131–132 with new conditions and seven examples), §02 discharge table, §05 §5.3.3 (paragraphs 19–20 rewritten), §05 discharge table, §05 §5.6.2 (added unconstrained array conforming examples), §05 §5.6.6 (added unconstrained array nonconforming example). SPEC-PROMPT.md D27 Rule 2 should also be updated.

---

## F14. Narrowing-Point Definition Excludes Type Conversions and Type Annotations — RESOLVED

**Location:** §02 §2.8.1 (Rule 1, paragraphs 127, 130), §05 §5.3.2 (paragraph 14), §05 §5.3.6 (paragraph 25), SPEC-PROMPT.md D27 Rule 1

**Severity:** High

**Issue:** Rule 1 defined narrowing points as three constructs: assignment, parameter passing, and return. The word "only" made this a closed list. Two retained constructs that introduce range checks were omitted:

   (a) Type conversions — `Positive(B)` must check B against the Positive range. Rule 3 condition (c) explicitly relies on conversions being checked ("provably valid at that program point"), creating a normative contradiction with Rule 1's "only" clause.

   (b) Type annotations — `(Expr : T)` replaces Ada 2022 qualified expressions, which perform constraint checks. The spec never stated whether annotations perform checks, leaving their semantics ambiguous.

Without these two as narrowing points, `Integer(Positive(Y))` where Y = 0 would silently bypass the Positive range check (the inner conversion is not at any of the three listed narrowing points), violating the Silver guarantee.

**Resolution:** Expanded the narrowing-point enumeration to five categories. Added to §02 paragraph 127: (d) type conversion to a more restrictive type, (e) type annotation. Updated §02 paragraph 130 to reference all five categories. Updated §05 paragraphs 14, 17, and 25 to list all five narrowing points. Added "Range check (type conversion)" and "Range check (type annotation)" rows to the runtime-check enumeration tables in both §05 §5.3.8 and §02 §2.8.5. SPEC-PROMPT.md D27 Rule 1 updated: narrowing-point list expanded in the D27 decision text, the generation instruction, the example narrative, and the discharge table.

---

## F15. Channel Operations Have No Defined Move Semantics, Evaluation Order, or try_send Failure Behaviour — RESOLVED

**Location:** §04 §4.3 (paragraphs 27–31), §02 §2.3.2 (paragraph 97), §05 §5.4.1 (paragraph 32)

**Severity:** High

**Issue:** Three interrelated gaps in the channel operation specification:

   (a) **No ownership transfer semantics.** §2.3.2 paragraph 97 listed move triggers as assignment, return, and parameter passing. Channel `send` and `receive` were not listed. If a channel's element type is an owning access type, `send` copies the access value without moving — both the sender and the channel (and later the receiver) hold the same owning pointer, creating double ownership, potential double deallocation, and a data race on the designated object. The "no shared mutable state" guarantee (§4.5 paragraph 45) covers package-level variables but not heap objects reachable through access values.

   (b) **`try_send` failure leaves payload state undefined.** Paragraph 29 said "no element is enqueued" on failure but did not specify whether the payload expression had already been evaluated and, for owning access types, whether the source variable had been nulled. If the implementation moves the value into a temporary before the fullness check, a failed `try_send` leaks the designated object and leaves the source null.

   (c) **Evaluation order unspecified.** The spec did not state whether the payload expression is evaluated before or after the channel-full check, creating ambiguity for side-effecting expressions and for the move-on-failure question.

**Resolution:** Specified full move semantics for all four channel operations (Option A from analysis):

   - `send` performs a move; the source becomes null at the point of the send statement, even if the task blocks waiting for space (§04 paragraph 27a).
   - `receive` performs a move from the channel into the target variable; the receiving task becomes the owner (§04 paragraph 28a).
   - `try_send` performs a move only on success; on failure the source retains its value (§04 paragraphs 29a, 29b). The expression is evaluated before the atomic fullness check; the source is not nulled until enqueue is confirmed.
   - `try_receive` ownership transfer applies only when `Success` is `True` (§04 paragraph 30).
   - A channel ownership invariant (§04 paragraph 31a) states that each designated object is owned by exactly one entity at any time.

Additional changes: §02 §2.3.2 paragraph 97 expanded with items (d) and (e) for channel send and receive. §05 §5.4.1 paragraph 33a added to explain how channel move semantics extend data-race-freedom to heap objects transferred between tasks.

---

## F16. Overwriting Non-Null Owning Access Variable Leaks Designated Object — RESOLVED

**Location:** §02 §2.3.2 (Move Semantics), §04 §4.3 (paragraphs 28a, 30)

**Severity:** High

**Issue:** The move semantics in §2.3.2 paragraph 96 defined what happens to the source and target of a move, but not what happens to the target's *old* designated object when the target is non-null. Automatic deallocation (paragraph 104) occurs only at scope exit, and `Ada.Unchecked_Deallocation` is excluded (paragraph 107(c)). If a non-null owning access variable is overwritten — by assignment, `receive`, or any other move — the old designated object is leaked: it can never be deallocated.

This affects all ownership moves, not only channels. Example:

```ada
Ptr : Node_Ptr := new (Data : Node);  -- Ptr owns object A
Ptr := new (Data : Node);              -- object A leaked forever
```

The channel case is particularly visible in loops:

```ada
Msg : Node_Ptr;
loop
    receive Ch, Msg;   -- second iteration: old designated object leaked
end loop;
```

**Resolution:** Added the null-before-move legality rule (§02 paragraphs 97a–97c). The target of any move into a pool-specific owning access variable shall be provably null at the point of the move. The implementation verifies this by flow analysis: variables are null after declaration, after a move-out (source becomes null), or after explicit null assignment; they are non-null after allocation, receive, or move-in. Programs that overwrite a non-null owner are rejected. A conforming pattern for repeated channel receive is to declare the target inside the loop body. §04 paragraphs 28a and 30 updated with cross-references to the null-before-move rule.

---

## F17. Dangling References After Auto-Deallocation; Named Access-to-Constant Leak — RESOLVED

**Location:** §02 §2.3.3–§2.3.5 (Borrowing, Observing, Automatic Deallocation)

**Severity:** High

**Issue:** Two gaps in the ownership model could produce dangling references or memory leaks:

   (a) **No explicit lifetime-containment rule.** The spec described borrows and observes as ending when the borrower/observer goes out of scope, and relied on reverse declaration order to ensure the borrower/observer exits before the owner. But no legality rule stated this as a requirement. With interleaved declarations (paragraph 140), an anonymous access variable could be declared before the owner and then assigned later, creating a borrower/observer that outlives the owner. At scope exit, the owner would be deallocated while the borrower/observer still holds a reference.

   (b) **Named access-to-constant objects leaked.** Paragraph 104 specified automatic deallocation for "pool-specific owning access variable" only. Named access-to-constant types (`type C_Ptr is access constant T;`) are pool-specific and allocate from a pool, but the table in paragraph 95 describes them as "not subject to ownership checking" rather than "owning." If automatic deallocation did not apply to them, objects allocated through named access-to-constant would leak — `Unchecked_Deallocation` is excluded (paragraph 107(c)) and there is no other reclamation mechanism.

**Resolution:** Three additions (Option A from analysis):

   1. **Initialisation-only restriction** (§02 paragraph 100a): Anonymous access variables shall only receive their value at the point of declaration, not by later assignment. This ensures the borrower/observer's lifetime is lexically determined by its declaration position, closing the interleaved-declaration loophole. Consistent with SPARK 2022.

   2. **Lifetime-containment legality rule** (§02 paragraphs 102a–102b): The scope of a borrower or observer shall be contained within the scope of the lender/observed object. A normative "no dangling access values" statement enumerates the mechanisms that collectively guarantee this property: lifetime containment, initialisation-only restriction, Ada accessibility rules, exclusion of `Unchecked_Access`, and scope-exit-only deallocation.

   3. **Auto-deallocation extended to named access-to-constant** (§02 paragraphs 104, 104a, 105): Paragraph 104 broadened from "pool-specific owning access variable" to "pool-specific access variable — whether access-to-variable (owning) or access-to-constant (named)." New paragraph 104a explains the rationale. Paragraph 105 broadened to cover all pool-specific access objects.

---

## F18. Accessibility Rules for `.Access` and General Access Types Unspecified — RESOLVED

**Location:** §02 §2.3 (ownership model — no accessibility subsection existed), §05 §5.3.8 (runtime check table, accessibility row)

**Severity:** High

**Issue:** The spec retained `.Access`, `aliased` objects, and general access types (`access all T`) but never stated the rules governing when `.Access` is legal, whether the result can escape the declaring scope, or how accessibility checks are discharged. The §05 runtime-check table said only "Simplified by ownership model; local borrows have lexical scope" without specifying what the simplified rules are. This left open a dangling-reference scenario: `.Access` on a local aliased variable returned from a function or sent through a channel creates a general access value that outlives the stack object, producing a dangling pointer.

In Safe's simplified type landscape (no tagged types, no anonymous access return types, no access discriminants, `Unchecked_Access` excluded), all Ada accessibility checks reduce to compile-time legality rules. But the spec never stated this.

**Resolution:** Added §2.3.8 "Accessibility Rules for `.Access` and General Access Types" (paragraphs 109–113) to §02:

   - Paragraph 109: Ada's accessibility rules retained as compile-time legality rules; all checks are compile-time in Safe.
   - Paragraph 110: `.Access` on heap-designated objects — governed by existing borrow/observe rules.
   - Paragraph 111: `.Access` on local aliased objects — result cannot escape the local scope. Four specific rejection cases: return, assignment to outer-scope variable, channel send, and the permitted case (inner-scope use).
   - Paragraph 112: General access types — same accessibility rules; conforming and nonconforming examples.
   - Paragraph 113: No runtime accessibility checks — four properties that ensure compile-time discharge.

Updated §05 §5.3.8 runtime-check table: accessibility row changed from "Simplified by ownership model; local borrows have lexical scope" to "Compile-time only — Ada accessibility rules retained as legality rules; no runtime check needed (Section 2, §2.3.8, paragraph 113)."

---

## F19. Cross-Package Ceiling Priority Computation Unsupported by Dependency Interface Information — RESOLVED

**Location:** §04 §4.2 (paragraph 21), §03 §3.3.1 (paragraph 33), §05 §5.4.2 (paragraph 34)

**Severity:** Medium

**Issue:** Paragraph 21 required the ceiling priority of a channel to be "at least the maximum of the priorities of all tasks that access that channel (directly or transitively through subprogram calls)." The "transitively through subprogram calls" clause creates a cross-package information requirement: if a task in package A calls a public subprogram in package B that accesses a channel in B, then A's task priority must be considered when computing B's channel ceiling. However, §3.3.1 dependency interface information item (d) covered only "package-level variables read and written" — not channels accessed. Paragraph 50 explicitly states "Channels are not variables." With no channel-access information in the dependency interface, the implementation could not compute precise ceiling priorities across package boundaries without either whole-program analysis (breaking the separate-compilation model) or conservatively setting all ceilings to `System.Any_Priority'Last` (defeating the purpose of the ceiling protocol).

**Resolution:** Extended the dependency interface information and made ceiling computation explicit:

   - §03 §3.3.1 paragraph 33 item (i): Added channel-access summaries — for each public subprogram, a conservative interprocedural summary of which channels are accessed (send, receive, try_send, try_receive) directly or transitively. Over-approximation permitted.

   - §04 §4.2 paragraph 21a: New paragraph specifying how ceiling computation works across packages. The implementation uses channel-access summaries from §3.3.1(i) to determine which channels a cross-package call accesses, adds the calling task's priority to each channel's priority set, and computes ceilings. The computation shall be completable from interface information alone, mirroring the requirement for task-variable ownership checking (§4.5 paragraph 47).

   - §05 §5.4.2 paragraph 34: Updated to reference the cross-package mechanism.

   - §07 Annex B item (e): Updated to reference channel-access summaries and the ceiling computation requirement.

---

## F20. Authoritative Grammar Missing `access_definition` in Four Productions — RESOLVED

**Location:** §08 §8.3 (`object_declaration`), §08 §8.8 (`parameter_specification`, `function_specification`), §08 §8.7 (`extended_return_statement`)

**Severity:** High

**Issue:** The authoritative BNF grammar in §08 defined `access_definition` (for anonymous access types) and used it in `component_definition` (record components), but omitted it from four other productions where it is required:

   (a) `object_declaration` — only allowed `subtype_indication` or `array_type_definition`. The declaration `Y : access T := X;` (local borrow, §2.3.3 paragraph 98(a)) was unparseable.

   (b) `parameter_specification` — only allowed `mode subtype_mark`. Anonymous access parameters (`procedure P (A : access T)`) — the mechanism for parameter-level borrowing and observing (§2.3.3 paragraph 98(b), §2.3.4 paragraph 101(b)) — were unparseable.

   (c) `function_specification` — only allowed `return subtype_mark`. Functions returning anonymous access types (`function F return access T`) — used for traversal functions in the SPARK ownership model — were unparseable.

   (d) `extended_return_statement` — only allowed `subtype_indication` for the return object. An extended return from a function returning anonymous access was unparseable.

The prose in §02 §2.3 (ownership model), §02 §2.3.3 (borrowing), §02 §2.3.4 (observing), F17 (initialisation-only restriction), and F18 (accessibility rules) all assumed these constructs were syntactically valid. The ownership table (paragraph 95) explicitly listed `A : access T := ...` and `A : access constant T := ...` as declaration syntax. SPEC-PROMPT.md D17 listed anonymous access-to-variable and anonymous access-to-constant as retained SPARK 2022 access type kinds. The entire borrow/observe mechanism had no syntactic basis in the authoritative grammar.

**Resolution:** Added `access_definition` as an alternative to all four productions in §08, matching the Ada 2022 grammar (8652:2023 §3.3.1, §6.1, §6.5):

   - `object_declaration`: third alternative with `access_definition` in place of `subtype_indication`.
   - `parameter_specification`: second alternative with `access_definition` (no mode — `access` serves as the pseudo-mode, per Ada 2022 §6.1).
   - `function_specification`: second alternative with `return access_definition`.
   - `extended_return_statement`: second alternative with `access_definition` in place of `subtype_indication`.

---

## F21. Annex A "MODIFIED" Library Units Use Vague Wording for Non-Existent Exception Paths — RESOLVED

**Location:** §07-annex-a (paragraphs 8–9, 14–15, 16–17), summary table (paragraph 76)

**Severity:** Medium

**Issue:** Four library units carried "MODIFIED" status with vague recovery language:

   (a) `Ada.Characters.Handling` (paragraph 9): "functions that raise exceptions in 8652:2023 shall instead return a defined default value or the implementation shall ensure through type constraints that the exception-raising conditions cannot occur."

   (b) `Ada.Characters.Conversions` (paragraph 15): "conversions that would fail in 8652:2023 by raising an exception shall be handled by the implementation through constrained parameter types or shall be excluded."

   (c) `Ada.Wide_Characters.Handling` / `Ada.Wide_Wide_Characters.Handling` (paragraph 17): "Same modifications as A.3.2."

Three deficiencies: (1) "default value" was undefined — no specification of what value to return, creating non-portable behaviour. (2) The choice between alternatives ("return a default value *or* constrain parameter types *or* exclude") was left to the implementation, so a function available on one conforming implementation could be absent on another. (3) The "MODIFIED" classification was incorrect — audit against 8652:2023 found that **no function in any of these packages raises an exception**: classification functions return `Boolean` for all inputs; conversion functions are defined for all inputs or use `Substitute` parameters for non-representable characters; widening conversions cannot fail.

The fourth "MODIFIED" unit, `Ada.Strings` (paragraph 19), was already adequately specified — its modification is the exclusion of exception type declarations, which is clearly stated and correct.

**Resolution:** Reclassified three library units from "MODIFIED" to "RETAINED" with precise justification:

   - `Ada.Characters.Handling` (paragraphs 8–9): Status changed to RETAINED. All functions enumerated with justification for totality: classification returns `Boolean`, conversion defined for all inputs, cross-width functions use `Substitute` parameter.

   - `Ada.Characters.Conversions` (paragraphs 14–15): Status changed to RETAINED. All functions enumerated: `Is_*` return `Boolean`, widening cannot fail, narrowing uses `Substitute` parameter.

   - `Ada.Wide_Characters.Handling` / `Ada.Wide_Wide_Characters.Handling` (paragraphs 16–17): Status changed to RETAINED. Mirror packages with same totality properties.

   - Summary table (paragraph 76): `Ada.Characters.*` row changed from "Retained/Modified — Exception paths excluded" to "Retained — All functions are total; no exception paths."

   `Ada.Strings` (paragraph 19) unchanged — its MODIFIED status and wording are correct.

---

## F22. Silver Guarantee Overclaims: Allocation Failure Is Not Statically Dischargeable — RESOLVED

**Location:** §05 §5.3.1 (paragraph 12), §05 §5.3.8 (runtime check table, allocation row), §00 TBD register (TBD-03)

**Severity:** Medium

**Issue:** The Silver normative statement (paragraph 12) claimed "Every conforming Safe program shall be free of runtime errors" and "every runtime check … shall be dischargeable from static type and range information." However, the runtime check table listed the allocation check as "Implementation-defined (see TBD register)" — the only entry without a concrete discharge mechanism. Allocation failure (`Storage_Error` in Ada) depends on the execution environment (available heap memory), not the program text, and cannot be statically discharged by any language rule. Any program using `new` (fundamental to the ownership model) could encounter allocation failure at runtime.

The spec already defined the correct *behaviour* for allocation failure (runtime abort, §02 paragraph 103a, added by F10), but the Silver *claim* was unscoped — it promised absence of all runtime errors while acknowledging that one category (allocation) was unresolved. This is an overclaim. SPARK 2022's AoRTE explicitly excludes `Storage_Error` from its scope; Safe's Silver guarantee did not make this exclusion.

**Resolution:** Scoped the Silver guarantee to exclude resource exhaustion, with a forward path to tighten the boundary:

   - §05 §5.3.1 paragraph 12a: New scoping paragraph explicitly stating that Silver covers runtime checks enumerable from the program text and language semantics, but does not cover resource exhaustion (allocation failure, stack overflow). These depend on the execution environment, not program text. Behaviour when resource exhaustion occurs is defined (abort) but not statically preventable. Notes consistency with SPARK 2022 AoRTE scope. References TBD-03 for future static allocation bounding.

   - §05 §5.3.8 runtime check table: Allocation row changed from "Implementation-defined (see TBD register)" to "Outside Silver scope — resource exhaustion (paragraph 12a); defined behaviour is runtime abort (Section 2, §2.3.5, paragraph 103a)."

   - §02 paragraph 125: "free of runtime errors" qualified with cross-reference to the scoping paragraph.

   - §00 TBD-03: Updated to reflect that allocation failure semantics are now defined (abort); remaining open items are static allocation bounding and stack-bounding rules.

---

## F23. Floating-Point Exceptional Behaviour Not Integrated into Silver — RESOLVED

**Location:** §02 §2.8 (D27 Silver rules), §05 §5.3 (Silver guarantee), §05 §5.3.8 (runtime check table), §00 TBD-04

**Severity:** Medium–High

**Issue:** The Silver guarantee (§5.3.1) claimed every conforming program is "free of runtime errors," and the D27 rules provided discharge machinery. However, all four original rules were either explicitly integer-specific or inapplicable to floating-point:

   (a) **Rule 1** (wide intermediate arithmetic) covered only integer expressions — paragraph 126 says "All integer arithmetic expressions." No analogous model existed for floating-point.

   (b) **Rule 3** (nonzero divisor) used proof methods designed for integer semantics. No float subtype excludes `0.0`; floating-point division by zero either raises `Constraint_Error` (if `Machine_Overflows = True`) or produces ±infinity (if `Machine_Overflows = False`). Neither path was addressed.

   (c) **Range checks at narrowing points** — the discharge mechanism cited "wide intermediates (Rule 1)" which is integer-only. Float computations can produce values outside the target type's range, and no float-specific discharge mechanism existed.

   (d) **`Machine_Overflows` dependency** — Ada 2022 leaves this implementation-defined. If `True`, float overflow and division by zero raise `Constraint_Error` (a runtime error Silver must prevent). If `False`, they produce infinity/NaN. Safe inherited this ambiguity because TBD-04 was unresolved.

   The §5.3.8 table had no rows for floating-point overflow, division by zero, or invalid operations (NaN) — despite claiming to enumerate "all categories of runtime check."

**Resolution:** Added D27 Rule 5 (floating-point non-trapping semantics and range safety), requiring IEEE 754 non-trapping mode and extending static range analysis to floating-point narrowing points:

   - §02 §2.8.5 (paragraphs 139–139e): New Rule 5 subsection. Requires `Machine_Overflows = False` for all predefined floating-point types (IEEE 754 non-trapping arithmetic). Float overflow produces ±infinity, division by zero produces ±infinity, invalid operations produce NaN — all defined values, not runtime errors. Float range checks at narrowing points discharged by static range analysis; NaN and infinity cannot survive narrowing because they are outside every finite float type's range. Conforming and nonconforming examples provided.

   - §02 §2.8.6 (paragraph 139f): Combined effect table expanded from six to ten check categories, adding floating-point overflow, division by zero, invalid operation (NaN), and float range checks.

   - §02 paragraph 125: "four rules" → "five rules."

   - §05 §5.3.1 paragraph 13: "four rules" → "five rules."

   - §05 §5.3.7a (paragraphs 28a–28c): New floating-point subsection explaining the IEEE 754 non-trapping model and how it integrates with the Silver guarantee.

   - §05 §5.3.8: Runtime check table expanded with four new rows: floating-point overflow, floating-point division by zero, floating-point invalid operation (NaN), and float range checks at narrowing points. Existing integer range check rows clarified with "integer" qualifier. Division by zero row clarified with "integer" qualifier.

   - §06: All references to "Rules 1–4" updated to "Rules 1–5." Rule 5 added to conforming program requirements (paragraph 3(b)). Silver guarantee paragraph (10) updated to mention floating-point explicitly. Conformance summary table updated. Implementation-defined item (i) added for IEEE 754 revision and rounding mode.

   - §00 TBD-04: Partially resolved. IEEE 754 non-trapping mode decided; remaining items are specific IEEE 754 revision mandate, static range analysis precision for floats, and strict reproducibility mode.

---

## F24. Safe/Core vs Safe/Assured Conformance Split Conceptually Muddy — RESOLVED

**Location:** §06 §6.4 (paragraphs 11–15), §06 §6.9 (conformance summary table)

**Severity:** Low–Medium

**Issue:** The spec defined two conformance levels — Safe/Core (legality checking only) and Safe/Assured (legality checking plus Silver verification). Paragraph 13 acknowledged this was "a distinction without practical difference" since the D27 legality rules are sufficient to guarantee Silver. However, three problems made the split confusing and potentially risky:

   (a) **Paragraph 13's misleading language.** "Safe/Core does not require the implementation to verify that the Silver guarantee holds" could be read as weakening the soundness obligation, even though the D27 rules themselves require "sound" static range analysis. An implementer could misinterpret this as: "Core doesn't need sound analysis, just some analysis."

   (b) **Paragraph 14(c) contradicted paragraph 13.** Assured said "if the implementation cannot verify absence of runtime errors for a program that passes Safe/Core legality checking, the program shall be rejected" — implying programs could pass Core but fail Assured. But paragraph 13 said there was "no practical difference." If both levels accept exactly the same programs, 14(c) is vacuous. If they might accept different programs, the "no practical difference" claim is false.

   (c) **The soundness requirement was buried.** The word "sound" appeared only in the D27 rule text (§2.8), not in the conformance section. An implementer reading §06 in isolation could miss that the analyses must be conservative.

**Resolution:** Collapsed the two conformance levels into one. Replaced §6.4 (paragraphs 11–15) with a single "Soundness" section (paragraphs 11–12) that:

   - Explicitly requires all D27-related static analyses to be sound: over-approximation (rejecting safe programs) is permitted; under-approximation (accepting unsafe programs) is not.

   - States that Silver is a logical consequence of sound D27 enforcement, not a separate verification step.

   - Removes the Safe/Core and Safe/Assured terminology entirely.

   Updated §6.9 conformance summary table from a two-column (Core/Assured) format to a single-column format with "Required" or "Guaranteed" status for each requirement.

   Updated EXEC_SUMMARY.md conformance levels subsection to reflect the single-level model.
