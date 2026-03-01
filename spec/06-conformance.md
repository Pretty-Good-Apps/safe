# Section 6 — Conformance

**This section is normative.**

This section defines what constitutes a conforming implementation and a conforming program. All requirements are expressed in terms of language properties, legality rules, and semantic guarantees. No normative paragraph mandates invocation of a specific tool, compiler, or prover.

---

## 6.1 Conforming Implementation

1. A **conforming implementation** is a processor that meets all of the following requirements:

   (a) It shall accept every conforming program (as defined in §6.2) and produce an executable representation or a functionally equivalent intermediary.

   (b) It shall reject every non-conforming program with a diagnostic that identifies the violated rule.

   (c) It shall implement the dynamic semantics of 8652:2023 correctly for all conforming programs, as modified by this specification.

   (d) It shall enforce all legality rules defined in this specification, including the D27 Rules 1–4 (Section 2, §2.8).

   (e) It shall enforce the task-variable ownership rule (Section 4, §4.5) as a legality rule.

   (f) It shall derive flow analysis information (Section 5, §5.2) without requiring user-supplied annotations.

   (g) It shall provide a mechanism for separate compilation of units and combination of separately compiled units into a program. The mechanism is implementation-defined.

2. A conforming implementation may provide additional capabilities beyond those required by this specification, provided that these do not alter the semantics of conforming programs.

---

## 6.2 Conforming Program

3. A **conforming program** is a program that meets all of the following requirements:

   (a) It uses only constructs defined by ISO/IEC 8652:2023 as restricted and modified by this specification.

   (b) It satisfies all legality rules defined in this specification, including:
   - D27 Rule 1: wide intermediate arithmetic bounds
   - D27 Rule 2: strict index typing
   - D27 Rule 3: division by provably nonzero divisor
   - D27 Rule 4: not-null dereference

   (c) It satisfies the task-variable ownership rule (Section 4, §4.5): each package-level variable is accessed by at most one task.

   (d) It has no circular `with` dependencies (Section 3, §3.2.9).

4. A program for which a conforming implementation cannot establish that all required runtime checks are dischargeable (from the specification's type rules and D27 legality rules) is non-conforming and shall be rejected.

5. **Clarification.** A program that is accepted by a conforming implementation is guaranteed to be free of the runtime errors enumerated in Section 5, §5.3.8. This is a consequence of the language rules, not a separate requirement — the D27 rules ensure that only Silver-provable programs are conforming.

---

## 6.3 Language-Level Assurance Guarantees

6. The following assurance properties are guaranteed for every conforming Safe program. These are expressed as language properties, not as tool invocations.

### 6.3.1 Representability (Stone)

7. Every conforming Safe program uses only constructs defined by ISO/IEC 8652:2023 as restricted and modified by this specification.

8. **Informative note.** This means every conforming Safe program has a natural mapping to valid Ada 2022 / SPARK 2022 source. The mapping is an implementation concern, not a conformance requirement. A conforming implementation is not required to produce Ada/SPARK output.

### 6.3.2 Flow Analysis (Bronze)

9. Every conforming Safe program has sufficient flow analysis information (`Global`, `Depends`, `Initializes` equivalents) derivable from its source without user-supplied annotations. This is guaranteed by the language restrictions enumerated in Section 5, §5.2.

### 6.3.3 Absence of Runtime Errors (Silver)

10. Every conforming Safe program is free of runtime errors — all runtime checks (overflow, range, index, division-by-zero, null dereference, discriminant) are dischargeable from static type and range information derivable from the program text, combined with D27 legality rules. This is guaranteed by the four rules enumerated in Section 5, §5.3.

---

## 6.4 Conformance Levels

11. To preserve the safety story through potential future standards refactoring, two conformance levels are defined:

### 6.4.1 Safe/Core

12. **Safe/Core** conformance requires that a conforming implementation:

   (a) Accepts all conforming programs as defined in §6.2.

   (b) Rejects all non-conforming programs with a diagnostic.

   (c) Implements the dynamic semantics correctly.

   (d) Enforces all legality rules, including D27 Rules 1–4.

13. Safe/Core does not require the implementation to verify that the Silver guarantee holds for accepted programs — it requires only that the legality rules are enforced. Since the legality rules are sufficient to guarantee Silver, this is a distinction without practical difference, but it separates the "compile correctly" concern from the "verify absence of runtime errors" concern.

### 6.4.2 Safe/Assured

14. **Safe/Assured** conformance requires everything in Safe/Core, plus:

   (a) The implementation shall verify that every conforming program accepted under Safe/Core is free of runtime errors (the Silver guarantee expressed as a verifiable property).

   (b) The verification method is implementation-defined. It may use static analysis, formal verification, abstract interpretation, or any other sound technique.

   (c) If the implementation cannot verify absence of runtime errors for a program that passes Safe/Core legality checking, the program shall be rejected with a diagnostic.

15. **Relationship between levels.** Safe/Core requires that the legality rules are enforced. Safe/Assured additionally requires that the implementation confirms the Silver property. In practice, the D27 legality rules are designed to make Silver verification straightforward — a correct implementation of the legality rules should be sufficient. Safe/Assured exists to provide formal certification evidence when required.

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

   (h) The runtime abort handler behaviour on `pragma Assert` failure.

   (i) The storage allocation strategy for access type allocators.

---

## 6.8 Runtime Requirements

23. A conforming implementation shall provide a runtime system sufficient to support:

   (a) Task creation and scheduling according to the priority rules.

   (b) Channel operations with blocking semantics.

   (c) The relative `delay` statement.

   (d) Automatic deallocation of owned access objects at scope exit.

   (e) The `pragma Assert` abort handler with source location diagnostic.

24. The size and implementation language of the runtime system are implementation-defined. The specification does not mandate a maximum runtime size.

---

## 6.9 Conformance Summary

25. The following table summarises the conformance requirements:

| Requirement | Safe/Core | Safe/Assured |
|-------------|-----------|--------------|
| Accept all conforming programs | Required | Required |
| Reject all non-conforming programs | Required | Required |
| Correct dynamic semantics | Required | Required |
| D27 legality rules enforced | Required | Required |
| Task-variable ownership enforced | Required | Required |
| Flow information derivable | Required | Required |
| Silver verification confirmed | Not required | Required |
| Separate compilation | Required | Required |
| Diagnostics on rejection | Required | Required |
