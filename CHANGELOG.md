# CHANGELOG — Safe Language Specification Revision

This changelog documents all changes applied to `SPEC-PROMPT.md` based on the combined findings of the SPARK 2022 Faithfulness Review and the Standards Readiness Review.

---

## P0 — Must Fix (contradictions and missing requirements)

### P0-1. Task Termination vs. Jorvik Profile

**Problem:** D28 claimed "Tasks may terminate via `return`" and that this "stays within Jorvik's capabilities." This is false — Jorvik retains `No_Task_Termination` from Ravenscar.

**Before:**
> Tasks begin executing when the program starts, after all package-level initialization is complete. Each task declaration creates exactly one task — no dynamic spawning, no task types, no task arrays. Tasks may terminate via `return`; a terminated task cannot be restarted.

**After:**
> Tasks begin executing when the program starts, after all package-level initialization is complete. Each task declaration creates exactly one task — no dynamic spawning, no task types, no task arrays. Tasks shall not terminate — every task body must contain a non-terminating control structure (e.g., an unconditional `loop`). A conforming implementation shall reject any task body that is not syntactically non-terminating. This is required by the Jorvik profile, which retains the `No_Task_Termination` restriction from Ravenscar.

**Before (Task termination subsection):**
> Tasks may terminate via `return`. This goes beyond Ravenscar (which requires tasks to run forever) but stays within Jorvik's capabilities. A terminated task's owned package variables become inaccessible. Channel endpoints remain valid — a send to a channel whose only receiver has terminated will block indefinitely (detectable by static analysis as a potential deadlock).

**After (Non-termination requirement subsection):**
> Tasks shall not terminate. The Jorvik profile retains the `No_Task_Termination` restriction from Ravenscar — both profiles require tasks to run forever once started. Every task body must contain a non-terminating control structure (typically an unconditional `loop`). A conforming implementation shall reject any task body whose outermost statement sequence is not syntactically non-terminating. `return` statements are not permitted in task bodies.

**Additional locations patched:**
- Rationale renamed from "static tasks" to "static, non-terminating tasks" with added explanation of `No_Task_Termination`
- §04 drafting instructions: "Task termination" bullet replaced with "Non-termination requirement" bullet

### P0-2. `access all` in Grammar but Not in Ownership Rules

**Problem:** Grammar instructions included `access_type_definition` which would include `access all`, but D17's ownership rules only covered pool-specific access types. No legality rule addressed `access all` types.

**Changes:**
- D17 "Restrictions vs. full SPARK ownership" — added `access all` exclusion as first bullet: "General access types (`access all T`) are excluded. A conforming implementation shall reject access type definitions that include the reserved word `all`."
- §02 drafting instructions (Access types and ownership) — added explicit `access all` exclusion, `anonymous access` exclusion, and `access constant` exclusion bullets
- §08 grammar instructions — updated access type line to specify "pool-specific only — `access all` excluded" and added exclusion list

### P0-3. Silver Guarantee Not Closed as a Conformance Rule

**Problem:** D26/D27 asserted Silver-by-construction but no hard rejection rule prevented a program from being accepted in a non-Silver state. The "trivially discharged" claim for `Wide_Integer` intermediates was not universally true.

**Before (D26 Silver section):**
> These rules ensure that every runtime check in a conforming Safe program is provably safe from type information alone. No developer annotations are needed.

**After:**
> These rules ensure that every runtime check in a conforming Safe program is provably safe from type information alone. No developer annotations are needed.
>
> **Hard rejection rule:** If a conforming implementation cannot establish, from the specification's type rules and D27 legality rules, that a required runtime check will not fail, the program is nonconforming and the implementation shall reject it with a diagnostic. There is no "developer must restructure" advisory — failure to satisfy any Silver-level proof obligation is a compilation error, not a warning.

**Before (D27 Rule 1, Wide_Integer claim):**
> GNATprove discharges intermediate arithmetic trivially because `Wide_Integer` cannot overflow for any operation on narrower types, and discharges narrowing checks via interval analysis on the wide result.

**After:**
> For types whose range fits within 32 bits, intermediate `Wide_Integer` arithmetic cannot overflow for single operations. For chained operations or types with larger ranges (e.g., products of two values near the 32-bit boundary), intermediate `Wide_Integer` subexpressions may approach the 64-bit bounds. If the implementation's analysis determines that any intermediate `Wide_Integer` subexpression could overflow, the expression shall be rejected with a diagnostic.

**Additional locations patched:**
- §05 drafting instructions — added hard rejection rule bullet
- §06 drafting instructions — added conforming program definition with rejection rule

### P0-4. Try_Send / Try_Receive Signature Mismatch

**Problem:** D28 defined `try_send`/`try_receive` as statements with Boolean out-parameter, but implementation advice described them as functions returning Boolean. SPARK prohibits functions with out parameters.

**Change:** Added explicit procedure signatures to §07-annex-b drafting instructions:
```ada
procedure Try_Send (Item : in Element_Type; Success : out Boolean);
procedure Try_Receive (Item : out Element_Type; Success : out Boolean);
```

### P0-5. Symbol File Format Contradiction

**Problem:** D6 said "binary symbol file" while §07-annex-b said "text-based (UTF-8, line-oriented, versioned header)".

**Before (D6):**
> The compiler extracts the public interface into a binary symbol file for incremental compilation

**After (D6):**
> The compiler extracts the public interface into a symbol file for incremental compilation [...] The symbol file format is implementation-defined.

**Additional locations patched:**
- §06 drafting instructions — added: "symbol files are one permitted mechanism and their format is implementation-defined"
- §07-annex-b — reframed symbol file format as "recommended practice" and declared this section the single normative home for format guidance

---

## P1 — Should Fix (standards editorial structure and missing requirements)

### P1-1. Normative/Informative Split — Remove Toolchain Coupling from Conformance

**Problem:** §06 defined conformance in terms of GNAT/GNATprove. ISO Ada explicitly does not specify translation means. An ECMA-track standard should define conformance using language properties.

**Changes:**
- Added new "Conformance Note" section to front matter: "Language conformance in this specification is defined in terms of language properties and legality rules, not specific tools or compilers."
- D29 reframed from "Compiler Written in Silver-Level SPARK" to "Reference Implementation in Silver-Level SPARK (Project Requirement)" with explicit statement that this is not a language conformance requirement
- §06 drafting instructions restructured into:
  - **Normative conformance requirements** — expressed in terms of language properties (accept conforming, reject nonconforming, implement dynamic semantics correctly)
  - **Conformance levels** (Safe/Core, Safe/Assured) — see P2-3
  - **Informative implementation guidance** — relocated GNAT/GNATprove material with explicit "informative" labels
  - D29 reframed as "Reference implementation profile (project requirement)"
- §05 drafting instructions: Bronze guarantee statement reframed from "submitted to GNATprove" to language property with informative GNATprove validation

### P1-2. Partition_Elaboration_Policy(Sequential) Requirement

**Problem:** D28 promises tasks start after elaboration completes, but the spec didn't mention `Partition_Elaboration_Policy(Sequential)`, which SPARK requires for task/protected usage under Jorvik.

**Changes:**
- D28 SPARK emission subsection — added `pragma Partition_Elaboration_Policy(Sequential)` as first emitted configuration item
- §04 drafting instructions — Task startup bullet expanded with elaboration policy language-level requirement and emitted pragma
- §07-annex-b — added "Elaboration and tasking configuration" bullet with rationale

### P1-3. `Wide_Integer` Intermediate Overflow Qualification

**Problem:** D27 Rule 1 claimed "`Wide_Integer` cannot overflow for any operation on narrower types" — misleading for multiplication of large-range types.

**Before:**
> GNATprove discharges intermediate arithmetic trivially because `Wide_Integer` cannot overflow for any operation on narrower types

**After:**
> For types whose range fits within 32 bits, intermediate `Wide_Integer` arithmetic cannot overflow for single operations. For chained operations or types with larger ranges [...] the expression shall be rejected with a diagnostic.

**Additional change:** Added explicit "Intermediate overflow legality rule" paragraph to D27 Rule 1.

### P1-4. Deallocation Emission Implementation Note

**Problem:** D17 specifies automatic deallocation but doesn't mention that emitted Ada must use `Ada.Unchecked_Deallocation` (a generic instantiation) or that deallocation must be emitted at every scope exit point.

**Changes:**
- D17 — added "Implementation note (deallocation emission)" paragraph covering: `Ada.Unchecked_Deallocation` usage in emitted code, D16 exclusion applies to Safe source only, deallocation at every scope exit point, GNATprove leak checking as independent verification
- §07-annex-b — added "Deallocation emission" bullet with same content

---

## P2 — Nice to Have (additional clarifications)

### P2-1. TBD Register

**Change:** Added TBD Register to §00 front matter drafting instructions listing 8 unresolved items:
- Target platform constraints
- Performance targets
- Memory model constraints
- Floating-point semantics
- Diagnostic catalog and localization
- `Constant_After_Elaboration` aspect
- Abort handler behavior
- AST/IR interchange format

### P2-2. `Depends` Over-Approximation Note

**Change:** Added note to §05 drafting instructions: compiler-generated `Depends` contracts may be conservatively over-approximate. GNATprove accepts supersets of actual dependencies for Bronze. Implementations may refine precision over time.

### P2-3. Conformance Levels

**Change:** Added conformance levels to §06 drafting instructions:
- **Safe/Core:** Language rules and legality checking only
- **Safe/Assured:** Language rules plus verification that every conforming program is free of runtime errors (the Silver guarantee as a language property)

### P2-4. `select` Emission Pattern Latency Note

**Change:** Added latency note to D28 `select` emission bullet: the polling-with-sleep pattern introduces latency equal to the sleep interval. Implementations may use more efficient patterns provided observable semantics are preserved.

---

## Consistency Pass

After all patches, the following consistency checks were performed:

1. **Task termination references:** All removed or updated. No remaining references to task `return`, terminated tasks, or post-termination semantics.
2. **GNATprove in normative requirements:** §06 conformance section now defines conformance via language properties. All remaining GNATprove references are in design decisions (informative rationale), §05 (informative validation), or §07-annex-b (implementation advice).
3. **"binary symbol file":** Does not appear anywhere in the spec.
4. **§08 grammar instructions:** Updated to reflect `access all` exclusion and full exclusion list.
5. **D28 examples:** Both task examples (Sensor_Reader, Sampler, Evaluator) use unconditional `loop` — no task termination shown.
6. **D17 ownership table:** Consistent with `access all` exclusion — only pool-specific access types shown.
7. **D26/D27 Silver guarantee:** Hard rejection rule added. `Wide_Integer` overflow claim qualified. "Three legality rules" corrected to "four" (Rule 4: not-null dereference was already present but not counted in the heading).

---

## Round 2

Changes applied based on an independent ECMA-track readiness review and deferred items from the Round 1 consistency pass.

### P0-R2-1. Toolchain Baseline Contradicts Conformance Note

**Problem:** Toolchain Baseline used normative "shall" voice binding conformance to GNATprove invocation, contradicting the Conformance Note and ECMA policy.

**Before (section introduction):**
> All compiler and proof requirements in this specification are defined relative to the following baseline:

**After:**
> This section defines the reference toolchain profile used by the project to validate the language guarantees. It is informative and does not define language conformance. Language conformance is defined solely in §06.

**Before (proof acceptance policy introduction):**
> For the purposes of this specification, "passes Bronze" and "passes Silver" mean:

**After:**
> For the purposes of the reference toolchain profile, "passes Bronze" and "passes Silver" mean:

**Before (proof acceptance policy closing):**
> These are the acceptance criteria for D26's guarantees. Every conforming Safe program, when compiled and emitted as Ada/SPARK, shall meet both criteria without any developer-supplied SPARK annotations in the emitted code.

**After:**
> These are the acceptance criteria used to validate D26's guarantees for the reference implementation. The language conformance rules in §06 are stated without mandating any specific tool invocation. A conforming Safe program is one that satisfies the language's legality rules (including D27 Rules 1–4); the reference toolchain profile provides one method of validating that the language guarantees hold.

**Additional fix:** "the implementation shall document" softened to "the reference implementation should document" in the Jorvik-unavailable paragraph.

### P0-R2-2. "Syntactically Non-Terminating" Is Ambiguous

**Problem:** D28 required implementations to "reject any task body that is not syntactically non-terminating" without defining what syntactic forms qualify.

**Before (D28 task declarations):**
> Tasks shall not terminate — every task body must contain a non-terminating control structure (e.g., an unconditional `loop`). A conforming implementation shall reject any task body that is not syntactically non-terminating.

**After:**
> Tasks shall not terminate. [...]
>
> **Non-termination legality rule:** The outermost statement of a task body's `handled_sequence_of_statements` shall be an unconditional `loop` statement (`loop ... end loop;`). Declarations may precede the loop. A `return` statement shall not appear anywhere within a task body. No `exit` statement within the task body shall name or otherwise target the outermost loop. A conforming implementation shall reject any task body that violates these constraints. This is a syntactic restriction checkable without control-flow or whole-program analysis.

**Before (D28 non-termination requirement subsection):**
> Tasks shall not terminate. [...] A conforming implementation shall reject any task body whose outermost statement sequence is not syntactically non-terminating. `return` statements are not permitted in task bodies.

**After:**
> The non-termination legality rule (stated in the task declarations section above) requires that: (a) the outermost statement of the task body is an unconditional `loop ... end loop;`, (b) no `return` statement appears anywhere in the task body, and (c) no `exit` statement names or targets the outermost loop. [...] This is a conservative syntactic restriction. Some theoretically non-terminating forms (e.g., `while True loop ... end loop;`) are excluded because "non-terminating" is not decidable in general; the unconditional `loop` form is trivially checkable by any implementation.

**§04 drafting instructions:** "Non-termination requirement" bullet replaced with "Non-termination legality rule" bullet specifying the precise syntactic constraints.

### P0-R2-3. Quick Reference Example Nonconforming Under D27

**Problem:** `Get_Reading` assigned `Raw + Cal_Table(Channel).Offset` to `Adjusted : Reading` where the intermediate could reach 8190 (exceeds `Reading`'s 0..4095 range), making the program nonconforming under D27 Rule 1.

**Before:**
```ada
public function Get_Reading (Channel : Channel_Id) return Reading is
begin
    pragma Assert (Initialized);
    Raw : Reading := Read_ADC (Channel);
    Adjusted : Reading := Raw + Cal_Table (Channel).Offset;
    return Adjusted;
end Get_Reading;
```

**After:**
```ada
public function Get_Reading (Channel : Channel_Id) return Reading is
begin
    pragma Assert (Initialized);
    Raw : Reading := Read_ADC (Channel);
    return Raw;  -- D27: no narrowing needed, already Reading type
end Get_Reading;
```

**Additional changes:**
- `Calibration` record simplified: `Offset : Reading` removed, replaced with `Bias : Integer`
- `Cal_Table` aggregate updated to match
- `Initialize` default updated to match
- Emitted Ada `Get_Reading` signature updated (no longer depends on `Cal_Table`)
- D27 note updated to focus on `Average_Reading`'s wide intermediate division
- Editorial Convention item 6 added: all examples must be conforming; nonconforming examples must be labeled

### P1-R2-1. Cross-Unit Effect Analysis Requires Symbol-File Specification

**Problem:** D3 prohibits whole-program analysis, but task-variable ownership (D28) and Bronze assurance (D26) require cross-package effect analysis. The spec did not specify what symbol files must carry to enable this.

**Changes:**
- §03 Static Semantics bullet — added: symbol files shall include `Global` effect summaries (read-set/write-set) for all exported subprograms; rejection if effect summary unavailable
- §04 Task-variable ownership bullet — added: cross-package transitivity uses `Global` effect summaries from dependency symbol files; ownership check completable without dependency source code

### P1-R2-2. D27 Rule 1 Redundant Paragraphs

**Problem:** The example paragraph after the "Intermediate overflow legality rule" still contained residual overlap from Round 1.

**Before:**
> This means `A + B` where `A, B : Reading` (0..4095) computes in `Wide_Integer` — the intermediate result 8190 does not overflow. A range check fires only if the result is stored back into a `Reading`.

**After:**
> For example, `A + B` where `A, B : Reading` (0..4095) computes in `Wide_Integer` — the intermediate result 8190 does not overflow, and a range check fires only when the result is narrowed to `Reading` at an assignment, return, or parameter point. GNATprove discharges narrowing checks via interval analysis on the wide result.

### P1-R2-3. D17 Deallocation Scope Exits Wording

**Problem:** Improved `goto` wording to specify "transfer control out of the owning scope" instead of "leave the scope" for precision.

**Before (D17):**
> `goto` statements that leave the scope

**After (D17):**
> `goto` statements that transfer control out of the owning scope

**Same change applied in §07-annex-b deallocation emission bullet.**

### P2-R2-1. ECMA Editorial Constraint

**Change:** Added Editorial Conventions item 7: "No normative paragraph shall mandate invocation of a specific tool, compiler, or prover by name."

### P2-R2-2. Design Decisions Heading

**Change:** Section heading changed from `## Design Decisions and Rationale` to `## Design Decisions` to match ECMA-style section naming conventions.

---

## Round 2 Consistency Pass

1. **Toolchain Baseline voice:** No "shall" in the Toolchain Baseline section binds conformance to tool invocation. The remaining "shall" instances in §06 and elsewhere are normative language-property requirements. ✓
2. **Task non-termination:** Zero occurrences of "syntactically non-terminating". All references use the precise legality rule (outermost unconditional `loop`, no `return`, no `exit` targeting outermost loop). ✓
3. **Quick Reference examples:** `Get_Reading` no longer performs arithmetic that would be rejected under D27. All examples conforming. ✓
4. **Scope exit completeness:** Both D17 and §07-annex-b include `goto` alongside `return` and `exit` with "transfer control out of the owning scope" wording. ✓
5. **D27 Rule 1:** Example paragraph is short and focused, no duplication of legality rule text. ✓
6. **Editorial Conventions:** Items 6 (example conformance) and 7 (tool independence) present. ✓
7. **Design Decisions heading:** `## Design Decisions` heading present before D1. ✓
8. **§03 and §04 drafting instructions:** Symbol-file `Global` effect summaries and cross-package ownership checking requirements present. ✓
