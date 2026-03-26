# Safe Language Reference Manual

**Working Draft — Version 0.1**

**This section is normative** (except where explicitly marked informative).

---

## 0.1 Title and Language Name

1. This document specifies the **Safe** programming language. Safe is a systems programming language defined subtractively from ISO/IEC 8652:2023 (Ada 2022).

2. The file extension for Safe source files is `.safe`.

3. Safe is not a new grammar. It is Ada 2022 with features removed and a small number of structural changes. This specification references 8652:2023 normatively and states only the delta.

---

## 0.2 Scope

4. This specification defines the Safe programming language by reference to ISO/IEC 8652:2023, stating:

   (a) Which features of 8652:2023 are excluded (Section 2).

   (b) Which features are modified and how (Sections 2–4).

   (c) What new constructs are added: static tasks, typed channels, channel operations, and the `select` statement (Section 4).

   (d) The language-level assurance guarantees: Bronze (complete flow information) and Silver (absence of runtime errors) without developer-supplied annotations (Section 5).

   (e) Conformance requirements for implementations and programs (Section 6).

   (f) The retained predefined library (Annex A).

   (g) Implementation advice (Annex B, informative).

   (h) The authoritative BNF grammar (Section 8).

5. This specification does not define:

   (a) Foreign language interfaces (reserved for a future system sublanguage specification).

   (b) A specific compiler or toolchain.

   (c) Gold or Platinum verification levels (which require developer-authored specifications).

---

## 0.3 Normative References

6. The following document is referenced normatively:

   - **ISO/IEC 8652:2023** — *Information technology — Programming languages — Ada*. All references to "8652:2023" in this specification refer to this document.

7. The following documents are referenced informatively:

   - **SPARK Reference Manual** (AdaCore, version 27.x) — informative design precedent for the ownership and borrowing model and for language restrictions.

   - **SPARK User's Guide** (AdaCore, version 27.x) — informative context for the assurance levels (Stone through Platinum) and for access type ownership patterns.

---

## 0.4 Terms and Definitions

8. For the purposes of this specification, the terms and definitions given in 8652:2023 §1.3 apply, with the following additions and modifications:

9. **Channel.** A typed, bounded-capacity, first-in first-out queue used for inter-task communication. See Section 4.

10. **Ownership.** The property that exactly one access variable designates a given dynamically allocated object at any point in program execution. See Section 2, §2.3.

11. **Move.** The transfer of ownership of a designated object from one access variable to another. After a move, the source variable becomes null. See Section 2, §2.3.2.

12. **Borrow.** The creation of a temporary mutable alias to a designated object. The lender is frozen while the borrow is active. See Section 2, §2.3.3.

13. **Observe.** The creation of a temporary read-only alias to a designated object. The observed object is frozen for writes while the observe is active. See Section 2, §2.3.4.

14. **Dependency interface information.** The information about a package's public declarations, types, subprogram signatures, effect summaries, and channel-access summaries that a conforming implementation makes available for separate compilation. See Section 3, §3.3.

15. **64-bit integer arithmetic.** The evaluation model for integer arithmetic in Safe, where all intermediate results must be statically provable within the single predefined signed 64-bit `integer` range. See Section 2, §2.8.1.

16. **Conforming implementation.** A processor that satisfies all requirements of Section 6. See Section 6, §6.1.

17. **Conforming program.** A program that satisfies all requirements of Section 6. See Section 6, §6.2.

18. **Effect summary.** A conservative interprocedural summary of the package-level variables read and written by a subprogram, including transitive callees. See Section 3, §3.3.1(d).

18a. **Channel-access summary.** A conservative interprocedural summary of the channels accessed (by send, receive, try_send, or try_receive) by a subprogram, including transitive callees. See Section 3, §3.3.1(i).

---

## 0.5 Method of Description

19. This specification uses the BNF notation of 8652:2023 §1.1.4:

   (a) `::=` introduces a production.

   (b) `[ ]` encloses optional elements.

   (c) `{ }` encloses elements that may appear zero or more times.

   (d) `|` separates alternatives.

   (e) Keywords appear as quoted literals in productions.

   (f) Nonterminals appear in `snake_case`.

20. Each normative section is organised using the 8652:2023 section template where applicable:

   (a) **Syntax** — BNF productions for new or modified constructs.

   (b) **Legality Rules** — rules that a conforming implementation shall enforce at compile time.

   (c) **Static Semantics** — properties determined at compile time.

   (d) **Dynamic Semantics** — runtime behaviour.

   (e) **Implementation Requirements** — requirements on the implementation.

   (f) **Examples** — non-normative illustrations.

21. **Normative voice.** This specification uses "shall" for requirements, "may" for permissions, and "should" for recommendations (in informative text only).

22. **Paragraph numbering.** Normative paragraphs are numbered sequentially within each section.

23. **Cross-references.** References to 8652:2023 use the form "8652:2023 §X.Y(Z)" where X.Y is the section number and Z is the paragraph number.

24. **Code examples.** All code examples are non-normative illustrations unless explicitly stated otherwise. The normative content is the prose rules, not the examples. Conforming examples are valid Safe programs. Nonconforming examples are explicitly labelled and accompanied by identification of the violated rule.

---

## 0.6 Document Structure

25. This specification comprises the following sections:

| Section | Title | Status |
|---------|-------|--------|
| §00 | Front Matter | Normative |
| §01 | Base Definition | Normative |
| §02 | Restrictions and Modifications | Normative |
| §03 | Single-File Packages | Normative |
| §04 | Tasks and Channels | Normative |
| §05 | Assurance | Normative |
| §06 | Conformance | Normative |
| §08 | Syntax Summary | Normative |
| Annex A | Retained Library | Normative |
| Annex B | Implementation Advice | Informative |

---

## 0.7 Design Decision Summary

26. The following table summarises the design decisions that shaped Safe. Each decision is described in detail in the drafter prompt (SPEC-PROMPT.md) and is reflected in the normative sections of this specification. Decision numbers D3, D4, D5, D25, and D29 are not listed; they were reclassified as implementation-profile decisions during design and moved to DEFERRED-IMPL-CONTENT.md. The numbering gaps are intentional and preserved for traceability.

| ID | Decision | Specification Section |
|----|----------|----------------------|
| D1 | Subtractive language definition | §01, §02 |
| D2 | SPARK 2022 as restriction baseline | §02 |
| D6 | Single-file packages | §03 |
| D7 | Flat package structure — purely declarative | §03 |
| D8 | Default-private visibility with `public` | §03 |
| D9 | Opaque types via `private record` | §03 |
| D10 | Subprogram bodies at point of declaration | §03 |
| D11 | Interleaved declarations and statements | §02, §03 |
| D12 | No overloading | §02 |
| D13 | No general use clauses, use type retained | §02 |
| D14 | No exceptions | §02 |
| D15 | Restricted tasking — static tasks and channels | §04 |
| D16 | No generics | §02 |
| D17 | Access types with SPARK ownership | §02 |
| D18 | No tagged types or dynamic dispatch | §02 |
| D19 | No contracts — pragma Assert instead | §02 |
| D20 | Dot notation for attributes | §02, §03 |
| D21 | Type annotation syntax | §02, §03 |
| D22 | Eliminated SPARK verification-only aspects | §02 |
| D23 | Retained Ada features | §01, §02 |
| D24 | System sublanguage — not specified | §02, Annex A |
| D26 | Guaranteed Bronze and Silver assurance | §05, §06 |
| D27 | Silver-by-construction rules | §02, §05 |
| D28 | Static tasks and typed channels | §04 |

---

## 0.8 TBD Register

27. The following items are acknowledged as unresolved and reserved for future specification revisions. Each item shall be resolved before baselining.

| ID | Item | Owner | Resolution Plan | Target Milestone |
|----|------|-------|----------------|-----------------|
| TBD-01 | Target platform constraints beyond "Ada compiler exists" | Language committee | Survey implementer capabilities; define minimum target requirements | v0.2 |
| TBD-02 | Performance targets (compile time, proof time, code size) | Implementation lead | Benchmark reference implementation; set normative bounds if warranted | v0.3 |
| TBD-03 | Memory model constraints (stack bounds, heap bounds, static allocation bounding) | Language committee | Allocation failure semantics defined (paragraph 103a, abort); evaluate static allocation bounding to bring resource exhaustion into Silver scope; evaluate stack-bounding rules | v0.2 |
| TBD-04 | Floating-point semantics beyond inheriting Ada's | Numerics reviewer | Partially resolved: IEEE 754 non-trapping mode required (`Machine_Overflows = False`) and integrated into Silver as D27 Rule 5 (Section 2, §2.8.5). Remaining items: evaluate whether to mandate a specific IEEE 754 standard revision (e.g., IEEE 754-2019); define static range analysis precision requirements for floating-point narrowing; evaluate strict reproducibility mode (deterministic rounding, extended-precision prohibition) | v0.3 |
| TBD-05 | Diagnostic catalogue and localisation | Implementation lead | Define structured diagnostic identifiers; evaluate i18n approach | v0.3 |
| TBD-06 | `Constant_After_Elaboration` aspect — determine whether required for concurrency analysis | Concurrency reviewer | Evaluate whether package-level constants need this aspect for sound analysis | v0.2 |
| TBD-07 | Abort handler behaviour (language-defined or implementation-defined) | Language committee | Define minimum abort handler guarantees; evaluate diagnostic requirements | v0.2 |
| TBD-08 | AST/IR interchange format (if any) | Tooling lead | Evaluate whether a standard intermediate format benefits the ecosystem | v0.4 |
| TBD-09 | Deadlock freedom | Concurrency reviewer | Evaluate static communication topology analysis, channel-dependency ordering, or prohibition of blocking send as potential language-level guarantees | v0.3 |
| TBD-10 | Numeric model: required ranges for predefined integer types | Numerics reviewer | Define minimum ranges for `Integer`, `Long_Integer` given the 64-bit signed bound in D27 Rule 1 | v0.2 |
| TBD-11 | Automatic deallocation semantics | Ownership reviewer | Specify ordering at scope exit, interaction with early return/goto, multiple owned objects exiting scope simultaneously | v0.2 |
| TBD-13 | Limited/private type views across packages | Language committee | Evaluate whether SPARK 26's `with type` mechanism fits Safe's single-file package model to relax the circular-dependency prohibition surgically | v0.3 |
| TBD-14 | Partial initialisation facility | Ownership reviewer | Evaluate whether a Safe-level uninitialised facility can preserve Silver without proof annotations. SPARK 21–24's `Relaxed_Initialization` and `Initialized` aspects provide design precedent. May require proof mechanisms Safe currently lacks. | v0.4 |

---

## 0.9 Normative/Informative Status

28. All sections of this specification are normative except:

   (a) Annex B (Implementation Advice) — informative.

   (b) All code examples — non-normative illustrations unless explicitly labelled otherwise.

   (c) Paragraphs explicitly marked as "Informative note" — non-normative.

   (d) Text within this specification that describes design rationale — non-normative context.

---

## 0.10 UK English Convention

29. This specification uses UK English spelling and conventions throughout (e.g., "behaviour", "colour", "generalisation", "licence" as noun), consistent with ECMA submission requirements.
