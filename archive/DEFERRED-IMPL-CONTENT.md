# Deferred Implementation-Profile Content

This file preserves all implementation-profile content removed from `SPEC-PROMPT.md` during the Round 4 structural revision. Every item below was part of the prompt prior to Round 4 and is retained here for use in implementation-guidance documents, informative annexes, or companion specifications.

Organisation: content is grouped by its source location in the pre-Round 4 `SPEC-PROMPT.md`.

---

## From: Compatibility Note

> Earlier design drafts included a C99 emission backend and OpenBSD as a primary deployment target. Those requirements are removed. Safe has exactly one backend: Ada 2022 / SPARK 2022 emission (D4, D25). Safe imposes no OS-specific targeting requirements; portability is delegated to GNAT (D5). C foreign function interface is excluded from the safe language and reserved for a future system sublanguage.

---

## From: Toolchain Baseline (entire section)

> This section defines the reference toolchain profile used by the project to validate the language guarantees. It is informative and does not define language conformance. Language conformance is defined solely in §06.
>
> - **GNAT:** GNAT Pro or GNAT Community, version 14.x or later (Ada 2022 capable)
> - **GNATprove:** Same release series as GNAT
> - **Proof level:** `gnatprove --mode=prove --level=2` (or higher if needed to discharge all checks)
> - **Runtime profile for concurrency:** `pragma Profile (Jorvik)` on hosted GNAT targets
>
> If Jorvik is not available for a particular target runtime, the reference implementation should document: (a) the chosen alternative profile (e.g., Ravenscar), (b) any restricted channel or select features, and (c) any impact on proof obligations.
>
> ### Proof acceptance policy
>
> For the purposes of the reference toolchain profile, "passes Bronze" and "passes Silver" mean:
>
> - **Bronze:** `gnatprove --mode=flow` reports zero errors and zero high-severity warnings on the emitted Ada.
> - **Silver:** `gnatprove --mode=prove` reports: no unproved runtime checks, no unproved assertions, and no tool errors. Proof timeouts are treated as failures unless explicitly documented with a mitigation plan.
>
> These are the acceptance criteria used to validate D26's guarantees for the reference implementation. The language conformance rules in §06 are stated without mandating any specific tool invocation. A conforming Safe program is one that satisfies the language's legality rules (including D27 Rules 1-4); the reference toolchain profile provides one method of validating that the language guarantees hold.

---

## From: Reserved Words — emission mapping paragraph

> The emitted Ada maps these to Ada-legal identifiers (e.g., `channel Readings` emits as a protected object named `Readings`). The identifier mapping shall be deterministic and documented.

---

## From: D3. Single-Pass Recursive Descent Compiler (entire decision)

> **Decision:** The language must be compilable in a single pass by a recursive descent parser, similar to Wirth's Oberon compiler.
>
> **Operational definition of "single pass":** The compiler reads the token stream once, left to right. During this pass it builds an in-memory AST, resolves names, checks types, enforces legality rules, and accumulates analysis data (Global/Depends sets, ownership state, task-variable ownership). After the token stream is consumed, the compiler walks the completed AST to emit Ada/SPARK output. This post-parse AST walk is not a "second pass" -- it does not re-read source tokens. What is prohibited is any design that requires re-parsing source text, multi-pass name resolution, or whole-program analysis across compilation units. Each compilation unit is compiled independently using only its source and the symbol files of its dependencies.
>
> **Rationale:** Single-pass compilation constrains the language to be simple. If a feature cannot be compiled in one pass, it is too complex. Wirth's Oberon-07 compiler is approximately 4,000 lines and compiles a useful language. Safe's compiler targets roughly 10,000-14,000 lines of Silver-level SPARK (including ownership checking for access types, interval arithmetic for D27 rules, task/channel compilation for D28, and the Ada/SPARK emitter) -- small enough for a single person to understand, audit, and formally verify. This also means fast compilation, which matters for developer experience.

---

## From: D4. Ada/SPARK as Sole Code Generation Target (entire decision)

> **Decision:** The compiler emits Ada 2022 / SPARK 2022 source code. GNAT compiles the emitted Ada to object code. GNATprove verifies the emitted Ada at Bronze and Silver levels. There is no other backend.
>
> **Rationale:** A single emission target eliminates an entire backend from the compiler (~1,500-2,500 LOC saved), halves the testing surface, and produces output that is directly verifiable by GNATprove. The emitted Ada is the canonical representation of the Safe program -- it is what gets proven, what gets compiled, and what gets certified. GNAT handles all platform-specific code generation, optimization, and ABI details. The compiler remains architecture-independent. Every Safe program is an Ada/SPARK program; emitting Ada is the natural and most direct representation.

---

## From: D5. Platform-Independent via GNAT (entire decision)

> **Decision:** Safe targets any platform supported by GNAT. The compiler emits Ada/SPARK source; GNAT handles all platform-specific code generation, linking, and runtime support. No platform-specific requirements are imposed by the Safe language definition.
>
> **Rationale:** Since the compiler emits Ada source code (not machine code or C), platform targeting is entirely GNAT's responsibility. GNAT supports Linux, macOS, Windows, and various embedded targets including bare-metal ARM and RISC-V. The Safe compiler itself runs wherever GNAT runs. This makes Safe immediately portable to every GNAT-supported platform without any work in the Safe compiler. Platform-specific concerns (ABI, calling conventions, memory layout) are handled by GNAT and by the Ada language's representation clauses.

---

## From: D6 — emission-related sentences

> The compiler extracts the public interface into a symbol file for incremental compilation, and emits `.ads`/`.adb` pairs as its output.

> The compiler reconstructs the `.ads`/`.adb` split mechanically from the single Safe source file, giving full Ada ecosystem compatibility (GNAT compilation, GNATprove verification, DO-178C certification).

---

## From: D7 — emitted Ada elaboration detail

> The emitted Ada uses `pragma Preelaborate` or `pragma Pure` where possible, falling back to GNAT's static elaboration model for packages with non-static initializers.

> *Tasks vs. initialization:* All package-level initialization across all compilation units completes before any task begins executing (D28). This is a sequencing guarantee enforced by the emitted Ada's elaboration model.

---

## From: D12 — single-pass compiler references

> The compiler determines which case applies from the type/kind of `X`, which is always known in a single-pass compiler at the point of use. No overload resolution is needed.

> **Rationale (excerpt):** Overloading is the single biggest obstacle to single-pass compilation in Ada.

---

## From: D15 — emitted Ada and runtime details

> Safe replaces it with a channel-based model (D28) that compiles to Jorvik-profile SPARK -- static tasks, compiler-generated protected objects backing channels, and the ceiling priority protocol for deadlock freedom. The emitted Ada uses GNAT's Jorvik-profile runtime, which is small and well-tested. The programmer sees tasks and channels; the prover sees Jorvik-profile SPARK.

---

## From: D17 — emitted Ada ownership table and deallocation emission

**Ownership mapping table (emitted Ada column):**

| Safe construct                     | Ada access kind in emitted code   | Ownership semantics                                                  |
| ---------------------------------- | --------------------------------- | -------------------------------------------------------------------- |
| `type T_Ptr is access T;`          | Named access-to-variable type     | Owner -- can be moved, borrowed, or observed                         |
| `subtype T_Ref is not null T_Ptr;` | `not null` subtype of above       | Non-null owner -- legal for dereference                              |
| `X := new T'(...)`                 | Allocator                         | Creates a new owned value; X becomes the owner                       |
| `Y := X` (access assignment)       | Assignment                        | **Move**: X becomes null, Y becomes owner                            |
| `procedure P (A : in T_Ptr)`       | `in` mode access parameter        | **Observe**: read-only borrow; caller's ownership frozen during call |
| `procedure P (A : in out T_Ptr)`   | `in out` mode access parameter    | **Borrow**: mutable borrow; caller's ownership frozen during call    |
| Scope exit of owning variable      | (compiler-generated deallocation) | Automatic deallocation when owner goes out of scope                  |

**Implementation note (deallocation emission):**

> The emitted Ada uses `Ada.Unchecked_Deallocation` generic instantiations to implement automatic deallocation when the owning object goes out of scope. The exclusion of generics (D16) applies to Safe source, not emitted Ada. Deallocation calls must be emitted at every scope exit point, including early `return` statements, loop `exit` statements, and `goto` statements that transfer control out of the owning scope, not just the textual end of the scope. GNATprove's leak checking on the emitted Ada provides independent verification that the compiler's deallocation logic is complete.

---

## From: D22 — emitted SPARK annotation generation detail

> However, they are not simply discarded -- the compiler automatically generates `Global`, `Depends`, and `Initializes` in the emitted Ada from the compiler's name resolution and data flow analysis (see D26). This means the developer writes zero verification annotations in Safe source, but gets Bronze-level SPARK assurance in the emitted Ada for free.

---

## From: D25. Ada/SPARK Emission Backend (entire decision)

> **Decision:** The compiler emits valid ISO/IEC 8652:2023 `.ads`/`.adb` file pairs that are guaranteed to pass GNATprove at SPARK Bronze and Silver levels. This is the sole backend.
>
> **Rationale:** Ada emission gives access to the entire Ada ecosystem -- GNAT's optimizing compiler for any supported platform, GNATprove for formal verification, DO-178C certification toolchains, and interoperability with existing Ada libraries. Every restriction in Safe is a restriction of Ada, so every Safe program is expressible as valid Ada/SPARK. The single-file package model is split mechanically: public declarations become the `.ads`, everything else becomes the `.adb`, with full signatures reconstituted from the symbol table. Having a single backend simplifies the compiler (no C emitter to maintain), simplifies testing (one output format to verify), and simplifies the trust chain (GNATprove verifies the same code that GNAT compiles).

---

## From: D26 — implementation-specific assurance details

**Stone level detail:**

> **Stone (guaranteed, trivially):** The emitted Ada compiles with `SPARK_Mode`. This is true by construction -- every Safe construct maps to a SPARK-legal Ada construct.

**Bronze implementation mechanism:**

> **Bronze (guaranteed, mechanically generated):** Bronze requires GNATprove to pass flow analysis. This requires three annotation families:
>
> - `Global` -- which package-level variables does a subprogram read or write. The Safe compiler already resolves every variable reference during its single pass. It accumulates a read-set and write-set per subprogram as a natural byproduct of name resolution. The emitter formats these as `Global` aspects.
>
> - `Depends` -- which outputs are influenced by which inputs. The Safe compiler tracks data flow through assignments and expressions during compilation. In a language with no uncontrolled aliasing (ownership rules prevent it), no dispatching, and no exceptions, dependency analysis is straightforward. The emitter formats these as `Depends` aspects.
>
> - `Initializes` -- which package variables are initialized at elaboration. Since Safe packages are purely declarative with mandatory initialization expressions, every package-level variable is initialized. The emitter lists all package variables in the `Initializes` aspect.
>
> Estimated compiler cost: 500-800 lines (300-500 for analysis during the existing single pass, 200-300 in the emitter for formatting).

**Concurrency verification by GNATprove:**

> **Concurrency safety (guaranteed, by language design):** The channel-based tasking model (D28) provides additional safety guarantees verifiable by GNATprove on the emitted Jorvik-profile SPARK:
>
> - **Data race freedom:** No shared mutable state between tasks. All inter-task communication is through channels (compiler-generated protected objects). GNATprove verifies this via `Global` aspects on task bodies.
> - **Deadlock freedom:** The ceiling priority protocol is enforced by the Jorvik profile. The compiler assigns ceiling priorities to channel-backing protected objects based on the static priorities of tasks that access them. GNATprove verifies the protocol is respected.

**Gold/Platinum detail:**

> **Gold and Platinum (out of scope):** Functional correctness and full formal verification require developer-authored specifications (postconditions stating functional intent, ghost code, lemmas). These are inherently non-automatable and are out of scope for the Safe compiler. A developer seeking Gold or Platinum works with the emitted Ada directly, adding specifications to the generated code.

---

## From: D27 Rule 1 — emitted Ada idiom

> **Emitted Ada idiom:** The compiler emits intermediate arithmetic using a 64-bit type: `type Wide_Integer is range -(2**63) .. (2**63 - 1);`. All subexpressions are lifted to `Wide_Integer` before evaluation. At narrowing points (assignment, return, parameter), the compiler emits an explicit type conversion to the target type, which generates a range check that GNATprove discharges via interval analysis.

> GNATprove discharges narrowing checks via interval analysis on the wide result.

---

## From: D27 — combined effect table GNATprove reference

> **Combined effect:** These four rules ensure that the six categories of runtime check -- overflow, range, index, division-by-zero, null dereference, and discriminant -- are all dischargeable by GNATprove from type information alone:

---

## From: D28 — SPARK emission subsection (entire block)

> **SPARK emission:**
>
> The compiler generates Jorvik-profile SPARK in the emitted Ada:
>
> - `pragma Partition_Elaboration_Policy(Sequential)` is emitted in the configuration file, ensuring all package-level declarations and initializations complete before any task begins execution. This is required by SPARK for programs using tasks or protected objects.
> - Each `task` becomes an Ada task type with a single instance and a `Priority` aspect.
> - Each `channel` becomes a protected object with ceiling priority, `Send` and `Receive` entries, and an internal bounded buffer.
> - `send`/`receive` become entry calls on the generated protected object.
> - `select` on channels becomes a conditional entry call pattern. **Latency note:** The polling-with-sleep emission pattern for `select` is pragmatically correct but not zero-overhead -- it introduces latency equal to the sleep interval. Implementations may use more efficient patterns (e.g., POSIX `select`-style multiplexing) where the target runtime supports them. The implementation may use alternative emission patterns provided the observable semantics (arm selection order, deterministic priority) are preserved.
> - Task-variable ownership becomes `Global` aspects on task bodies, referencing only owned variables and channel operations.
>
> GNATprove can then verify: data race freedom (no unprotected shared state), deadlock freedom (ceiling priority protocol), and all Silver-level AoRTE checks within task bodies.

---

## From: D28 — Runtime subsection

> **Runtime:** The emitted Ada uses GNAT's Jorvik-profile runtime. No custom runtime is needed -- GNAT provides task scheduling, protected object implementation, and delay support. The Safe compiler's responsibility ends at emitting correct Jorvik-profile Ada.

---

## From: D28 — Compiler cost table

> **Compiler cost:**
>
> | Component                                                    | LOC     |
> | ------------------------------------------------------------ | ------- |
> | Channel declarations and type checking                       | 200-300 |
> | Task declarations and body compilation                       | 200-300 |
> | Send/receive/try\_send/try\_receive statements               | 150-200 |
> | Select statement compilation                                 | 300-400 |
> | Task-variable ownership checking                             | 200-300 |
> | Ada emission (task types, protected objects, Jorvik aspects)  | 300-500 |
>
> Approximately 1,350-2,000 LOC additional compiler code.

---

## From: D29. Reference Implementation in Silver-Level SPARK (entire decision)

> **Decision:** The reference implementation of the Safe compiler shall be written in Ada 2022 / SPARK 2022, with all compiler source code at SPARK Silver level (Absence of Runtime Errors proven by GNATprove). This is a project requirement for the reference implementation, not a language conformance requirement -- a conforming implementation may be written in any language, provided it satisfies the conformance requirements of §06.
>
> **Rationale:** A safety-oriented language should have a verifiable reference implementation. If the compiler itself can crash due to a buffer overrun, null dereference, or integer overflow when processing adversarial input, the safety guarantees it provides to user programs are undermined. Writing the reference compiler in Silver-level SPARK means:
>
> 1. **No runtime errors in the compiler.** Every array access, integer operation, pointer dereference, and type conversion in the compiler is proven safe by GNATprove. A malformed Safe source file may produce a compilation error, but it cannot crash the compiler.
>
> 2. **The trust chain is coherent.** Safe programs are Silver-proven when emitted as Ada. The compiler that performs this emission is itself Silver-proven. The verification tools (GNATprove, GNAT) are existing, independently audited infrastructure. There is no unverified link in the chain from Safe source to proven object code.
>
> 3. **The compiler eats its own cooking.** The compiler uses Ada's type system the same way Safe's D27 rules require: tight range types for buffer indices, `not null` access subtypes for AST node pointers, nonzero subtypes for divisors. The compiler's source code serves as a large-scale demonstration that Silver-level programming is practical and ergonomic.
>
> 4. **Bootstrapping path.** The compiler is built by GNAT on any GNAT-supported host. It does not need to self-host -- it is an Ada program that compiles Safe programs, not a Safe program that compiles Safe programs. The compiled Safe compiler binary, together with GNAT and GNATprove, forms the complete Safe toolchain.
>
> **What Silver requires for the compiler:**
>
> The compiler source will use the same patterns that Safe encourages in user code:
>
> - **AST nodes:** Access types with SPARK ownership for tree structures. `not null` subtypes at every dereference. Ownership moves during tree construction, borrows during tree walks.
> - **Symbol tables:** Array-based or access-based, with index types matching array bounds.
> - **Lexer/parser buffers:** Bounded arrays with range types for positions. No unchecked indexing.
> - **Numeric computations:** Wide intermediates for line/column arithmetic, interval analysis for source positions.
> - **Error handling:** Discriminated records for parse results (success/failure), no exceptions.
>
> **Estimated compiler structure:**
>
> | Component            | Approximate LOC  | Silver challenge                                  |
> | -------------------- | ---------------- | ------------------------------------------------- |
> | Lexer                | 800-1,200        | Low -- character-level, bounded buffers            |
> | Parser               | 2,500-3,500      | Low -- recursive descent, predictable control flow |
> | Semantic analysis    | 2,000-3,000      | Medium -- symbol table lookups, type checking      |
> | Ownership checker    | 800-1,200        | Medium -- access type tracking                     |
> | D27 rule enforcement | 500-800          | Low -- interval arithmetic, type range queries     |
> | Ada/SPARK emitter    | 1,500-2,500      | Low -- string building, annotation generation      |
> | Driver and I/O       | 500-800          | Low -- file handling, command line                 |
> | **Total**            | **9,000-13,000** |                                                   |
>
> GNATprove at Silver level on a codebase of this size is well within demonstrated capability -- AdaCore has verified larger SPARK codebases (e.g., the SPARK runtime itself, the CubeOS operating system components).
>
> **What this does NOT mean:**
>
> - The compiler is not written in Safe. It is written in Ada/SPARK. Safe is the language being compiled, not the language the compiler is written in. Self-hosting is a possible future goal but is not required or planned.
> - The compiler does not need to be Gold-level (functional correctness). Silver proves the compiler won't crash. Proving it compiles correctly (semantic preservation) would require Gold or Platinum and is orders of magnitude harder.

---

## From: §06 — informative implementation guidance block

> **Informative implementation guidance** (relocated to §07-annex-b for toolchain-specific details):
>
> - Emitted Ada requirements (informative -- describes the reference implementation's emission strategy):
>   - Produces valid 8652:2023 `.ads`/`.adb` pairs
>   - Emitted code compiles with `SPARK_Mode`
>   - Compiler generates `Global`, `Depends`, and `Initializes` aspects automatically
>   - Tasks emitted as Jorvik-profile Ada task types with single instances and `Priority` aspects
>   - Channels emitted as protected objects with ceiling priority, `Send`/`Receive` entries, and bounded internal buffers
>   - Task-variable ownership emitted as `Global` aspects on task bodies
>   - `select` on channels emitted as conditional entry call patterns
>   - Access type ownership tracked; deallocation calls emitted at owner scope exit
>   - Wide intermediate arithmetic emitted using `Wide_Integer` (64-bit signed) per D27 Rule 1
>   - Array index checks and null dereference checks guaranteed to be provably safe by D27 Rules 2-4
> - Runtime: for the reference implementation, GNAT's Jorvik-profile runtime; no custom runtime required
> - **Reference implementation profile (D29, project requirement -- not a language conformance requirement):** The reference implementation is written in Ada 2022 / SPARK 2022 at Silver level. This is a project goal for the reference compiler; other conforming implementations may be written in any language.

---

## From: §05 — emitted Ada and GNATprove drafting instructions

> - **Bronze Guarantee** -- specify precisely what the compiler generates in the emitted Ada:
>   - `Global` aspects on every subprogram: specify the algorithm (accumulate read-set and write-set during name resolution)
>   - `Depends` aspects on every subprogram: specify the algorithm (track data flow through assignments and expressions)
>   - `Initializes` aspect on every package: specify the rule (all package-level variables with initializers)
>   - `SPARK_Mode` on every unit
>   - As informative validation: when the emitted Ada is submitted to GNATprove, it shall pass flow analysis with no errors

> - **Silver Guarantee** excerpts:
>   - Wide intermediate arithmetic: ...how it maps to the emitted Ada (intermediate expressions use a wide type; GNATprove discharges overflow checks trivially)
>   - State that every conforming Safe program, when emitted and submitted to GNATprove, shall pass AoRTE proof with no errors and no user-supplied annotations

> - **`Depends` over-approximation note:** The compiler-generated `Depends` contracts may be conservatively over-approximate (listing more dependencies than actually exist). This is acceptable for Bronze -- GNATprove accepts `Depends` contracts that are supersets of actual dependencies. An implementation may refine precision over time without affecting conformance.

> - **Examples** -- show a Safe source file, the emitted Ada with generated annotations, and the expected GNATprove output at Bronze and Silver levels. Include examples of:
>   - A concurrent program with tasks and channels, the emitted Jorvik-profile Ada, and GNATprove's data race freedom and deadlock freedom analysis

---

## From: §04 — emitted Ada task startup detail

> The emitted Ada shall include `pragma Partition_Elaboration_Policy(Sequential)` to enforce this guarantee.

---

## From: §03 — emitted Ada implementation requirements

> - **Implementation Requirements** -- emitted Ada structure (`.ads`/`.adb` split), symbol file emission, incremental recompilation rules

---

## From: §07-annex-b — full section (retained as-is for reference)

> **Drafting note:** This annex is informative. All requirements stated here apply to the reference implementation and are recommendations for other implementations. Use "should" rather than "shall" throughout this annex. If a requirement is genuinely normative (i.e., a conforming implementation MUST do it), it belongs in §02, §03, §04, or §06 -- not here.
>
> Implementation advice covering:
>
> - **Emitted Ada conventions (informative):** The emitted `.ads`/`.adb` files should be deterministic -- the same Safe source, compiled with the same compiler version, should always produce byte-identical Ada output. Specify naming conventions for generated entities (e.g., channel-backing protected objects, task types, wide integer intermediates). Specify formatting conventions (indentation, line width, declaration ordering) to ensure stable golden tests. The emitted channel-backing protected objects should use **procedures** (not functions) for non-blocking operations, since SPARK does not permit functions with `out` parameters:
>   ```ada
>   procedure Try_Send (Item : in Element_Type; Success : out Boolean);
>   procedure Try_Receive (Item : out Element_Type; Success : out Boolean);
>   ```
> - **Symbol file format (recommended practice):** The symbol file format is implementation-defined (see §06). As a recommended practice for the reference implementation, the per-package symbol file should be text-based (UTF-8, line-oriented, versioned header) for debuggability and diffability. Specify: exported names, types (including size/alignment for opaque types), subprogram signatures, and dependency fingerprints. Deterministic ordering for stable diffs. This is the single normative home for symbol file format guidance; §06 states only that the format is implementation-defined.
> - **Diagnostic messages:** Format, severity levels, and source location conventions. Error messages should include the Safe source file, line, and column. Compiler diagnostics should be stable (same input produces same diagnostics) to support automated testing.
> - **Incremental recompilation:** Rules for when a symbol file change triggers recompilation of dependent units. Specify the fingerprinting strategy.
> - **Emitted Ada quality:** The emitted Ada should be human-readable and suitable for manual inspection, Gold/Platinum annotation, and DO-178C certification review.
> - **Elaboration and tasking configuration (informative):** The emitted Ada should include `pragma Partition_Elaboration_Policy(Sequential)` in the configuration file. This defers library-level task activation until all library units are elaborated, preventing elaboration-time data races. SPARK requires this pragma for programs using tasks or protected objects under Ravenscar/Jorvik profiles.
> - **Deallocation emission:** The emitted Ada uses `Ada.Unchecked_Deallocation` generic instantiations for automatic deallocation of owned access objects at scope exit. The exclusion of generics (D16) applies to Safe source only, not emitted Ada. The compiler should emit deallocation at every scope exit point: normal scope end, early `return`, loop `exit`, and `goto` that transfers control out of the owning scope. GNATprove's leak checking on the emitted Ada independently verifies completeness of the compiler's deallocation logic.

---

## From: Quick Reference — emitted Ada example block

```ada
-- sensors.ads (generated)
pragma SPARK_Mode;

package Sensors
    with Initializes => (Cal_Table, Initialized)
is
    type Reading is range 0 .. 4095;
    type Channel_Id is range 0 .. 7;
    subtype Channel_Count is Integer range 1 .. 8;

    function Is_Initialized return Boolean
        with Global => (Input => Initialized);

    procedure Initialize
        with Global => (In_Out => (Cal_Table, Initialized));

    function Get_Reading (Channel : Channel_Id) return Reading
        with Global => (Input => Initialized),
             Depends => (Get_Reading'Result => (Channel, Initialized));

    function Average (A, B : Reading) return Reading
        with Global => null,
             Depends => (Average'Result => (A, B));

    function Scale (R : Reading; Divisor : Channel_Count) return Integer
        with Global => null,
             Depends => (Scale'Result => (R, Divisor));

private
    type Calibration is record
        Scale  : Float := 1.0;
        Bias   : Integer := 0;
    end record;
end Sensors;
```

> The developer wrote zero annotations. The compiler generated `Global`, `Depends`, and `Initializes` automatically. This output passes GNATprove at both Bronze level (flow analysis) and Silver level (AoRTE -- absence of runtime errors). Division by `Count` is provably safe because `Channel_Count` excludes zero. Array indexing by `Channel_Id` is provably safe because the index type matches the array index type. Arithmetic uses wide intermediates, so no overflow is possible in expressions.

---

## From: ECMA Submission Shaping Constraints — GNATprove reference

> 3. **Code examples are non-normative:** All code examples (Safe source, emitted Ada, GNATprove output) are non-normative illustrations unless explicitly stated otherwise.

---

## From: Workflow — emitted Ada references

> 7. Draft `05-spark-assurance.md` -- Bronze and Silver guarantee specification, concurrency assurance, examples of emitted Ada with annotations.

---

## From: D28 — Jorvik mapping in decision statement

> The model maps to the Jorvik tasking profile in the emitted SPARK Ada.

---

## From: D28 — channel rationale emission detail

> Under the hood, the compiler generates protected objects in the emitted Ada, preserving the Jorvik ceiling priority protocol for deadlock freedom analysis. The programmer never sees the protected object; they see channels.

---

## From: D28 — no-shared-state rationale compiler detail

> The ownership check is straightforward in a single-pass compiler -- the `Global` analysis already tracks which variables each subprogram accesses. Extending this to task boundaries adds approximately 200-300 lines of compiler code.

---

## From: D19 — emitted Ada annotation generation detail

> The compiler automatically generates `Global`, `Depends`, and `Initializes` in the emitted Ada for Bronze-level SPARK assurance, and D27's language rules guarantee Silver-level AoRTE (see D26). Developer-authored `Pre` and `Post` are not needed for either level. A developer seeking Gold or Platinum assurance adds contracts to the emitted Ada directly.

---

## From: TBD Register — GNATprove-specific item

> - `Constant_After_Elaboration` aspect -- verify whether GNATprove requires it for concurrency analysis of emitted Ada; generate if needed
