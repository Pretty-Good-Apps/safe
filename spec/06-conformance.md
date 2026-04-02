# Section 6 — Conformance

**This section is normative.**

This section defines what constitutes a conforming implementation and a conforming program. All requirements are expressed in terms of language properties, legality rules, and semantic guarantees. No normative paragraph mandates invocation of a specific tool, compiler, or prover.

---

## 6.1 Conforming Implementation

1. A **conforming implementation** is a processor that meets all of the following requirements:

   (a) It shall accept every conforming program (as defined in §6.2) and produce an executable representation or a functionally equivalent intermediary.

   (b) It shall reject every non-conforming program with a diagnostic that identifies the violated rule.

   (c) It shall implement the dynamic semantics of 8652:2023 correctly for all conforming programs, as modified by this specification.

   (d) It shall enforce all legality rules defined in this specification, including the D27 Rules 1–5 (Section 2, §2.8).

   (e) It shall enforce the task-variable ownership rule (Section 4, §4.5) as a legality rule.

   (f) It shall derive flow analysis information (Section 5, §5.2) without requiring user-supplied annotations.

   (g) It shall provide a mechanism for separate compilation of units and combination of separately compiled units into a program. The mechanism is implementation-defined.

2. A conforming implementation may provide additional capabilities beyond those required by this specification, provided that these do not alter the semantics of conforming programs.

---

## 6.2 Conforming Program

3. A **conforming program** is a program that meets all of the following requirements:

   (a) It uses only constructs defined by ISO/IEC 8652:2023 as restricted and modified by this specification.

   (b) It satisfies all legality rules defined in this specification, including:
   - D27 Rule 1: 64-bit integer arithmetic bounds
   - D27 Rule 2: provable index safety
   - D27 Rule 3: division by provably nonzero divisor
   - D27 Rule 4: not-null dereference
   - D27 Rule 5: floating-point non-trapping semantics and range safety

   (c) It satisfies the task-variable ownership rule (Section 4, §4.5): each package-level variable is accessed by at most one task.

   (d) It has no circular `with` dependencies (Section 3, §3.2.9).

4. A program for which a conforming implementation cannot establish that all required runtime checks are dischargeable (from the specification's type rules and D27 legality rules) is non-conforming and shall be rejected.

5. **Clarification.** A program that is accepted by a conforming implementation is guaranteed to be free of the runtime errors enumerated in Section 5, §5.3.8. This is a consequence of the language rules, not a separate requirement — the D27 Rules 1–5 ensure that only Silver-provable programs are conforming.

---

## 6.3 Language-Level Assurance Guarantees

6. The following assurance properties are guaranteed for every conforming Safe program. These are expressed as language properties, not as tool invocations.

### 6.3.1 Representability (Stone)

7. Every conforming Safe program uses only constructs defined by ISO/IEC 8652:2023 as restricted and modified by this specification.

8. **Informative note.** This means every conforming Safe program has a natural mapping to valid Ada 2022 / SPARK 2022 source. The mapping is an implementation concern, not a conformance requirement. A conforming implementation is not required to produce Ada/SPARK output.

### 6.3.2 Flow Analysis (Bronze)

9. Every conforming Safe program has sufficient flow analysis information (`Global`, `Depends`, `Initializes` equivalents) derivable from its source without user-supplied annotations. This is guaranteed by the language restrictions enumerated in Section 5, §5.2.

### 6.3.3 Absence of Runtime Errors (Silver)

10. Every conforming Safe program is free of runtime errors within the scope defined by Section 5, §5.3.1, paragraph 12a — all runtime checks (integer overflow, floating-point overflow, range, index, division-by-zero, null dereference, discriminant) are dischargeable from static type and range information derivable from the program text, combined with D27 legality rules. Floating-point exceptional conditions (overflow, division by zero, invalid operation) are eliminated by requiring IEEE 754 non-trapping arithmetic (Rule 5); NaN and ±infinity are caught at narrowing points. Resource exhaustion (allocation failure, stack overflow) is outside Silver scope; behaviour is defined (runtime abort) but not statically preventable. This is guaranteed by the five rules enumerated in Section 5, §5.3.

---

## 6.4 Soundness

11. All static analyses performed by a conforming implementation to enforce the D27 rules shall be **sound**: they may conservatively reject programs that are actually safe (over-approximation), but they shall never accept programs that contain potential runtime errors (under-approximation). Specifically:

   (a) If a conforming implementation accepts a program, every runtime check enumerated in Section 5, §5.3.8 is guaranteed to be dischargeable from the program text and the D27 legality rules.

   (b) If a conforming implementation cannot establish that a runtime check is dischargeable, it shall reject the program — even if the check would in fact never fail at runtime.

12. **Rationale.** The D27 rules are designed so that correctly enforcing them is both necessary and sufficient for the Silver guarantee (absence of runtime errors within the scope of §5.3.1 paragraph 12a). There is no gap between "enforcing the legality rules" and "guaranteeing Silver" — the latter is a logical consequence of the former. A single conformance level therefore suffices: a conforming implementation enforces D27 Rules 1–5 soundly, and Silver follows by construction.

---

## 6.5 Compilation Model

### 6.5.1 Separate Compilation

16. A conforming implementation shall support separate compilation of Safe packages. Each package shall be compilable independently using only its source and the dependency interface information of its `with`'d packages (Section 3, §3.3).

### 6.5.2 Dependency Interface

17. A conforming implementation shall provide a mechanism for conveying dependency interface information between separately compiled units (Section 3, §3.5). The mechanism is implementation-defined.

18. The dependency interface shall include at minimum:

   (a) Public declarations and their types.

   (b) Subprogram signatures for public subprograms.

   (c) Effect summaries for public subprograms (Section 3, §3.3.1(d)).

   (d) Size and alignment for public opaque types.

   (e) Channel-access summaries for public subprograms (Section 3, §3.3.1(i)).

### 6.5.3 Linking

19. A conforming implementation shall provide a mechanism for combining separately compiled units into an executable program. The mechanism is implementation-defined.

---

## 6.6 Diagnostics

20. When a conforming implementation rejects a non-conforming program, the diagnostic shall:

   (a) Identify the source file, line number, and column (or character position) of the violation.

   (b) Identify which rule is violated (referencing this specification's paragraph numbers or rule identifiers where practical).

21. The specific wording of diagnostic messages is implementation-defined. This specification does not mandate diagnostic text.

---

## 6.7 Implementation-Defined Behaviour

22. The following aspects of Safe are implementation-defined. A conforming implementation shall document its choices for each:

   (a) The mechanism for separate compilation and dependency interface information (§6.5).

   (b) The default priority of tasks without an explicit `Priority` aspect (Section 4, §4.1).

   (c) The scheduling order among tasks of equal priority (Section 4, §4.1).

   (d) The order of task activation when multiple tasks begin execution (Section 4, §4.7).

   (e) The allocation strategy for channels (Section 4, §4.2).

   (f) The initialisation order among packages with no direct or transitive dependency relationship (Section 3, §3.4.2).

   (g) The runtime abort handler behaviour on `pragma Assert` failure and allocation failure.

   (h) The storage allocation strategy for access type allocators.

   (i) The specific IEEE 754 standard revision and rounding mode used for floating-point arithmetic (Rule 5 requires `Machine_Overflows = False` but does not mandate a specific IEEE 754 revision or rounding mode beyond the default non-trapping requirement).

---

## 6.8 Runtime Requirements

23. A conforming implementation shall provide a runtime system sufficient to support:

   (a) Task creation and scheduling according to the priority rules.

   (b) Channel operations with nonblocking send semantics plus blocking receive/select semantics.

   (c) The relative `delay` statement.

   (d) Automatic deallocation of pool-specific access objects (both owning and named access-to-constant) at scope exit.

   (e) The runtime abort handler with source location diagnostic (for `pragma Assert` failure and allocation failure).

24. The size and implementation language of the runtime system are implementation-defined. The specification does not mandate a maximum runtime size.

---

## 6.9 Conformance Summary

25. The following table summarises the conformance requirements for a conforming implementation:

| Requirement | Status |
|-------------|--------|
| Accept all conforming programs | Required |
| Reject all non-conforming programs | Required |
| Correct dynamic semantics | Required |
| D27 legality rules (Rules 1–5) enforced soundly | Required |
| Task-variable ownership enforced | Required |
| Flow information derivable | Required |
| Silver guarantee (consequence of sound D27 enforcement) | Guaranteed |
| Separate compilation | Required |
| Diagnostics on rejection | Required |
