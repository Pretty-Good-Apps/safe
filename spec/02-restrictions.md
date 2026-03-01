# Section 2 — Restrictions and Modifications

**This section is normative.**

This section enumerates every feature of ISO/IEC 8652:2023 (Ada 2022) that Safe excludes or modifies. Features not mentioned here are retained with their 8652:2023 semantics. The section is organised by 8652:2023 section number to facilitate systematic cross-referencing.

---

## 2.1 Excluded Language Features

### 2.1.1 Section 2 — Lexical Elements (8652:2023 §2)

1. All lexical rules of 8652:2023 §2 are retained, with the following modifications:

2. **Reserved words (§2.9).** All reserved words defined in 8652:2023 §2.9 remain reserved in Safe, regardless of whether the corresponding language feature is excluded. A conforming implementation shall reject any program that uses a reserved word as an identifier.

3. **Additional reserved words.** Safe adds the following reserved words: `public`, `channel`, `send`, `receive`, `try_send`, `try_receive`, `capacity`. These identifiers shall not be used as user-defined names in Safe programs.

4. **Tick notation (§2.2, §4.1.4).** The tick character (`'`) is used only for character literals (`'A'`). All attribute references use dot notation (see §2.4). Qualified expressions using tick (`T'(Expr)`) are replaced by type annotation syntax (see §2.4.2). A conforming implementation shall reject any use of tick for attribute references or qualified expressions.

### 2.1.2 Section 3 — Declarations and Types (8652:2023 §3)

#### 3.2.4 Subtype Predicates

5. **Subtype predicates (§3.2.4).** `Static_Predicate` and `Dynamic_Predicate` aspects are excluded. A conforming implementation shall reject any subtype declaration bearing a `Static_Predicate` or `Dynamic_Predicate` aspect.

**Note:** Subtype predicates may be reconsidered in a future revision if they prove essential for the type system (see TBD register in §00).

#### 3.4 Derived Types and Classes

6. **Derived types (§3.4).** Non-tagged derived types are retained. Tagged derived types (type extensions) are excluded (see §2.1.2, 3.9 below).

#### 3.9 Tagged Types and Type Extensions

7. **Tagged types (§3.9).** Tagged type declarations, type extensions (§3.9.1), dispatching operations (§3.9.2), abstract types and subprograms (§3.9.3), and interface types (§3.9.4) are excluded. A conforming implementation shall reject any `tagged` type declaration, type extension declaration, `abstract` type or subprogram declaration, or interface type declaration.

8. **Related exclusions:** Extension aggregates (§4.3.2), class-wide types, class-wide operations, and all constructs requiring tagged types are excluded as a consequence.

#### 3.10 Access Types

9. **Access-to-subprogram types (§3.10).** Access-to-subprogram type declarations are excluded. A conforming implementation shall reject any access-to-subprogram type declaration. Rationale: indirect calls violate the static call resolution property (D18).

10. **Access-to-object types (§3.10).** All access-to-object type kinds supported by SPARK 2022 are retained with the SPARK 2022 ownership and borrowing model. See §2.3 for the complete ownership specification.

11. **Access discriminants.** Access discriminants (8652:2023 §3.7(8), §3.10) are excluded. A conforming implementation shall reject any discriminant of an access type.

#### 3.11 Controlled Types

12. **Controlled types (§7.6).** The types `Ada.Finalization.Controlled` and `Ada.Finalization.Limited_Controlled` and all user-defined finalization (`Initialize`, `Adjust`, `Finalize`) are excluded. A conforming implementation shall reject any type derivation from `Ada.Finalization.Controlled` or `Ada.Finalization.Limited_Controlled`. Rationale: controlled types require tagged types and introduce implicit code execution on assignment and scope exit; Safe uses ownership-based automatic deallocation instead.

### 2.1.3 Section 4 — Names and Expressions (8652:2023 §4)

#### 4.1.4 Attributes

13. **Attribute notation (§4.1.4).** All attribute references in Safe use dot notation (`X.First`) instead of tick notation (`X'First`). The resolution rules and semantics of each retained attribute are unchanged from 8652:2023; only the surface syntax changes. See §2.4.1 for the complete resolution rule and §2.5 for the attribute inventory.

#### 4.1.5 User-Defined References

14. **User-defined references (§4.1.5).** Excluded. A conforming implementation shall reject any declaration of a type with `Implicit_Dereference` aspect. Rationale: requires tagged types and introduces implicit dereferences.

#### 4.1.6 User-Defined Indexing

15. **User-defined indexing (§4.1.6).** Excluded. A conforming implementation shall reject any declaration of a type with `Constant_Indexing` or `Variable_Indexing` aspect. Rationale: requires tagged types and creates ambiguity in indexing semantics.

#### 4.2.1 User-Defined Literals

16. **User-defined literals (§4.2.1).** Excluded. A conforming implementation shall reject any declaration of a type with `Integer_Literal`, `Real_Literal`, or `String_Literal` aspect. Rationale: requires tagged types.

#### 4.3.2 Extension Aggregates

17. **Extension aggregates (§4.3.2).** Excluded. A conforming implementation shall reject any extension aggregate. Rationale: requires tagged types.

#### 4.3.4 Delta Aggregates

18. **Delta aggregates (§4.3.4).** Retained. Delta aggregates are part of the SPARK 2022 subset and are the standard replacement for the deprecated `Update` attribute.

#### 4.3.5 Container Aggregates

19. **Container aggregates (§4.3.5).** Excluded. A conforming implementation shall reject any container aggregate. Rationale: requires tagged types and generic container library.

#### 4.4 Expressions

20. **Declare expressions (§4.5.9).** Retained. Declare expressions are part of the SPARK 2022 subset (supported since SPARK 21).

#### 4.5.7 Conditional Expressions

21. **Conditional expressions (§4.5.7).** Retained (if-expressions and case-expressions).

#### 4.5.8 Quantified Expressions

22. **Quantified expressions (§4.5.8).** Excluded. A conforming implementation shall reject any quantified expression (`for all`, `for some`). Rationale: quantified expressions are primarily useful in contract specifications, which are excluded (D19).

#### 4.5.10 Reduction Expressions

23. **Reduction expressions (§4.5.10).** Excluded. A conforming implementation shall reject any reduction expression. Rationale: reduction expressions use container iteration and anonymous subprograms, both of which are excluded.

#### 4.6 Type Conversions

24. **Type conversions (§4.6).** Retained. Explicit type conversions remain available and are essential for the Silver-by-construction rules (D27), particularly for narrowing to nonzero or non-null subtypes.

#### 4.7 Qualified Expressions

25. **Qualified expressions (§4.7).** Excluded. The `T'(Expr)` syntax is replaced by type annotation syntax `(Expr : T)`. A conforming implementation shall reject any qualified expression using tick notation. See §2.4.2.

#### 4.8 Allocators

26. **Allocators (§4.8).** Retained, with modified syntax. The allocator syntax uses type annotation in place of qualified expressions: `new (Expr : T)` instead of `new T'(Expr)`. The allocator `new T` (without an initialising expression) is retained where T has default initialisation. See §2.4.2 for interaction with type annotation syntax.

#### 4.10 Image Attributes

27. **Image attributes (§4.10).** Retained in dot notation: `T.Image(X)`, `X.Image`. The semantics are unchanged from 8652:2023.

### 2.1.4 Section 5 — Statements (8652:2023 §5)

28. **Simple and compound statements (§5.1).** Retained: assignment (§5.2), target name symbols (§5.2.1), if statements (§5.3), case statements (§5.4), loop statements (§5.5), block statements (§5.6), exit statements (§5.7), goto statements (§5.8), return statements (§6.5), null statements.

#### 5.5.1–5.5.3 Iterators

29. **User-defined iterator types (§5.5.1).** Excluded. A conforming implementation shall reject any declaration of a type with `Default_Iterator` or `Iterator_Element` aspect. Rationale: requires tagged types and controlled types.

30. **Generalised loop iteration (§5.5.2).** Excluded for user-defined iterators. The `for E of Array_Name` form for iterating over arrays is retained, as it is part of the SPARK 2022 subset. Iteration over containers and user-defined iterators is excluded.

31. **Procedural iterators (§5.5.3).** Excluded. A conforming implementation shall reject any procedural iterator. Rationale: requires access-to-subprogram types.

#### 5.6.1 Parallel Block Statements

32. **Parallel block statements (§5.6.1).** Excluded. A conforming implementation shall reject any parallel block statement. Rationale: Safe provides concurrency exclusively through static tasks and channels (D28).

### 2.1.5 Section 6 — Subprograms (8652:2023 §6)

33. **Subprogram declarations and bodies (§6.1, §6.3).** Retained. Subprogram bodies appear at the point of declaration (D10). Forward declarations are permitted for mutual recursion.

#### 6.1.1 Preconditions and Postconditions

34. **Preconditions and postconditions (§6.1.1).** Excluded. The aspects `Pre`, `Post`, `Pre'Class`, `Post'Class` are excluded. A conforming implementation shall reject any subprogram bearing these aspects. Rationale: replaced by `pragma Assert` for runtime checks; Bronze and Silver assurance guaranteed by D26/D27 language rules without developer-authored contracts.

#### 6.1.2 Global and Global'Class Aspects

35. **Global and Global'Class aspects (§6.1.2).** Excluded from Safe source. A conforming implementation shall reject any user-authored `Global` or `Global'Class` aspect in Safe source. Rationale: the implementation derives flow information automatically (D22, D26).

#### 6.3.1 Conformance Rules

36. **Subtype conformance for overloading (§6.3.1).** The conformance rules are simplified by the absence of overloading (D12). Each subprogram identifier denotes exactly one subprogram within a given declarative region.

#### 6.4 Subprogram Calls

37. **Subprogram calls (§6.4).** Retained. Named and positional parameter associations (§6.4.1) are retained.

#### 6.5 Return Statements

38. **Return statements (§6.5).** Retained for subprograms. Extended return statements are retained. A `return` statement shall not appear within a task body (see Section 4, non-termination legality rule).

#### 6.5.1 Nonreturning Subprograms

39. **Nonreturning subprograms (§6.5.1).** The `No_Return` aspect is retained.

#### 6.6 Overloading of Operators

40. **Operator overloading (§6.6).** Excluded. A conforming implementation shall reject any user-defined operator function (a function whose designator is an operator symbol). Predefined operators for language-defined types are retained. Rationale: overloading is the primary source of name-resolution complexity (D12).

#### 6.7 Null Procedures

41. **Null procedures (§6.7).** Retained.

#### 6.8 Expression Functions

42. **Expression functions (§6.8).** Retained. Expression functions are part of the SPARK 2022 subset.

### 2.1.6 Section 7 — Packages (8652:2023 §7)

43. **Package specifications and declarations (§7.1).** Modified. Safe uses a single-file package model (D6). See Section 3 for the complete specification.

#### 7.2 Package Bodies

44. **Package bodies (§7.2).** Excluded as a separate construct. A Safe package is a single source file containing all declarations and subprogram bodies. There is no separate `package body`. A conforming implementation shall reject any standalone `package body` compilation unit. See Section 3.

#### 7.3 Private Types and Private Extensions

45. **Private types and private extensions (§7.3).** The Ada `private` section model is excluded. There is no `private` keyword as a section divider in package declarations. Safe uses `public` annotation for visibility (D8) and `private record` for opaque types (D9). Private type extensions (§7.3) are excluded (requires tagged types). Type invariants (§7.3.2), default initial conditions (§7.3.3), and stable properties (§7.3.4) are excluded.

#### 7.4 Deferred Constants

46. **Deferred constants (§7.4).** Excluded. Deferred constants require a separate package body for completion. In Safe's single-file package model, constants are declared and initialised at the point of declaration.

#### 7.5 Limited Types

47. **Limited types (§7.5).** Retained. Limited types without assignment are supported.

#### 7.6 Assignment and Finalization

48. **Assignment and finalization (§7.6).** User-defined finalization via controlled types is excluded (see paragraph 12). The default assignment semantics of 8652:2023 are retained. For access types with ownership, assignment performs a move (see §2.3).

### 2.1.7 Section 8 — Visibility Rules (8652:2023 §8)

49. **Declarative regions and scope (§8.1, §8.2).** Retained.

50. **Visibility (§8.3).** Modified by the `public`/default-private model. See Section 3. Overriding indicators (§8.3.1) are excluded (requires tagged types).

#### 8.4 Use Clauses

51. **General use clauses (§8.4).** Excluded. A conforming implementation shall reject any `use Package_Name;` clause. Rationale: general use clauses create name pollution (D13).

52. **Use type clauses (§8.4).** Retained. `use type T;` makes the predefined operators of type T directly visible without importing all declarations from the enclosing package.

#### 8.5 Renaming Declarations

53. **Renaming declarations (§8.5).** Retained: object renaming (§8.5.1), package renaming (§8.5.3), subprogram renaming (§8.5.4). Exception renaming (§8.5.2) is excluded (exceptions are excluded). Generic renaming (§8.5.5) is excluded (generics are excluded).

#### 8.6 Overload Resolution

54. **The context of overload resolution (§8.6).** Excluded. Overload resolution is not needed because overloading is excluded (D12). Each name resolves to exactly one entity based on declaration-before-use and qualified naming.

### 2.1.8 Section 9 — Tasks and Synchronisation (8652:2023 §9)

55. **Task units and task objects (§9.1).** Excluded. Task types, task objects declared from task types, and the Ada `task type` / `task body` model are excluded. Safe provides static task declarations as a new construct (D28, Section 4).

56. **Task execution and activation (§9.2).** Modified. Task activation semantics are replaced by the Safe task startup model (Section 4): all package-level initialisation completes before any task begins execution.

57. **Task dependence and termination (§9.3).** Modified. Safe tasks shall not terminate (D28 non-termination legality rule, Section 4).

58. **Protected units and protected objects (§9.4).** Excluded as user-declared constructs. A conforming implementation shall reject any user-declared `protected type` or `protected object` declaration. Protected objects may be used internally by an implementation to realise channel semantics; such use is not visible to Safe source.

59. **Intertask communication (§9.5).** Excluded. Entry declarations (§9.5.2), accept statements (§9.5.2), entry calls (§9.5.3), and requeue statements (§9.5.4) are excluded. A conforming implementation shall reject any entry_declaration, accept_statement, entry_call_statement, or requeue_statement. Safe provides channels for inter-task communication (Section 4).

60. **Delay statements (§9.6).** The relative delay statement `delay Duration_Expression;` is retained. `delay` is used in task bodies and in `select` statement delay arms. The type `Duration` from package `Standard` is retained. The absolute delay statement `delay until Time_Expression;` is excluded. A conforming implementation shall reject any `delay until` statement. Rationale: both `Ada.Calendar` and `Ada.Real_Time` are excluded (Annex A), leaving no language-defined time type for the absolute delay expression; relative delays via `Duration` cover periodic task loops and select timeouts.

61. **Select statements (§9.7).** The Ada select statement (selective accept §9.7.1, timed entry calls §9.7.2, conditional entry calls §9.7.3, asynchronous transfer of control §9.7.4) is excluded. Safe provides its own `select` statement for multiplexing channel receive operations (Section 4). A conforming implementation shall reject any selective_accept, timed_entry_call, conditional_entry_call, or asynchronous_select.

62. **Abort of a task (§9.8).** Excluded. A conforming implementation shall reject any `abort` statement.

63. **Task and entry attributes (§9.9).** Excluded. The attributes `Callable`, `Terminated`, `Count`, `Caller` (in dot notation) are excluded.

64. **Shared variables (§9.10).** Safe prohibits shared mutable state between tasks (D28). The shared variable rules of §9.10 are superseded by Safe's task-variable ownership rule (Section 4, §4.5). Conflict check policies (§9.10.1) are excluded.

### 2.1.9 Section 10 — Program Structure and Compilation Issues (8652:2023 §10)

65. **Separate compilation (§10.1).** Retained with modifications. Library units shall be packages (D6); library-level subprograms are not permitted as compilation units. `with` clauses (§10.1.2) are retained. Subunits (§10.1.3, `is separate`) are retained. The compilation process (§10.1.4) is implementation-defined.

66. **Elaboration control (§10.2.1).** The pragmas `Elaborate`, `Elaborate_All`, and `Elaborate_Body` are excluded. Safe's prohibition of circular `with` dependencies (D7) reduces elaboration to a topological sort of the dependency graph. A conforming implementation shall reject any program with circular `with` dependencies among compilation units.

### 2.1.10 Section 11 — Exceptions (8652:2023 §11)

67. **Exceptions (§11.1–§11.6).** Section 11 of 8652:2023 is excluded in its entirety. A conforming implementation shall reject any exception declaration (§11.1), exception handler (§11.2), raise statement or raise expression (§11.3), or `pragma Suppress`/`Unsuppress` applied to language-defined checks (§11.5). Rationale: exceptions create hidden control flow incompatible with static analysis (D14).

68. **pragma Assert (§11.4.2).** Retained. `pragma Assert` is the sole assertion mechanism in Safe. A failed assertion calls the runtime abort handler with source location diagnostic information. The `Assertion_Policy` pragma is excluded; assertions are always enabled.

### 2.1.11 Section 12 — Generic Units (8652:2023 §12)

69. **Generics (§12.1–§12.8).** Section 12 of 8652:2023 is excluded in its entirety. A conforming implementation shall reject any generic declaration, generic body, or generic instantiation. Rationale: generics require instantiation, which adds significant compiler complexity (D16).

### 2.1.12 Section 13 — Representation Issues (8652:2023 §13)

70. **Operational and representation aspects (§13.1).** Retained where applicable. Aspect specifications (§13.1.1) are retained for retained aspects.

71. **Packed types (§13.2).** Retained. `pragma Pack` is retained.

72. **Representation attributes (§13.3).** Retained in dot notation (e.g., `T.Size`, `T.Alignment`).

73. **Enumeration representation clauses (§13.4).** Retained.

74. **Record layout (§13.5).** Record representation clauses (§13.5.1), storage place attributes (§13.5.2), and bit ordering (§13.5.3) are retained.

75. **Change of representation (§13.6).** Retained where applicable (non-tagged derived types only).

76. **The package System (§13.7).** Retained. `System.Storage_Elements` (§13.7.1) is retained. `System.Address_To_Access_Conversions` (§13.7.2) is excluded (unsafe conversion).

77. **Machine code insertions (§13.8).** Excluded. A conforming implementation shall reject any machine code insertion. Rationale: unsafe capability reserved for a future system sublanguage (D24).

78. **Unchecked type conversions (§13.9).** Excluded. `Ada.Unchecked_Conversion` is excluded. A conforming implementation shall reject any instantiation of or reference to `Ada.Unchecked_Conversion`. Data validity (§13.9.1) and the `Valid` attribute (§13.9.2) are retained (dot notation: `X.Valid`).

79. **Unchecked access value creation (§13.10).** The `Unchecked_Access` attribute is excluded. A conforming implementation shall reject any use of `.Unchecked_Access`. The `Access` attribute (`.Access`) is retained for uses consistent with the ownership model (see §2.3).

80. **Storage management (§13.11).** User-defined storage pools, storage pool aspects, and `Ada.Unchecked_Deallocation` are excluded from Safe source. A conforming implementation shall reject any `Storage_Pool` aspect specification, any storage pool type declaration, and any reference to `Ada.Unchecked_Deallocation` in Safe source. Deallocation is automatic on scope exit for pool-specific owning access objects (see §2.3). Storage allocation attributes (§13.11.1) — `Storage_Size` in dot notation — are retained.

81. **Restrictions and profiles (§13.12).** `pragma Restrictions` and `pragma Profile` are excluded from Safe source. The language's restrictions are defined by this specification, not by user-declared pragmas. A conforming implementation may use restriction pragmas internally.

82. **Streams (§13.13).** Excluded. Stream-oriented attributes and the streams subsystem are excluded. A conforming implementation shall reject any stream attribute reference or stream type declaration. Rationale: streams require tagged types and controlled types.

83. **Freezing rules (§13.14).** Retained. The freezing rules of 8652:2023 §13.14 apply to Safe programs.

### 2.1.13 Annexes

#### Annex B — Interface to Other Languages

84. **Interface to other languages (Annex B).** Excluded in its entirety. `pragma Import`, `pragma Export`, `pragma Convention`, and all of Annex B are excluded from Safe source. A conforming implementation shall reject any such pragma. Rationale: foreign language interface is excluded from the safe language and reserved for a future system sublanguage (D24).

#### Annex C — Systems Programming

85. **Systems programming (Annex C).** Excluded. Interrupt handling (C.3), machine operations (C.1), and other Annex C features are excluded.

#### Annex D — Real-Time Systems

86. **Real-time systems (Annex D).** Excluded except for task priorities. Safe retains the `Priority` aspect on task declarations (Section 4). All other Annex D features (D.1–D.14) including `Ada.Real_Time`, monotonic time, timing events, execution-time clocks, and group budgets are excluded. The `delay until` statement is excluded (see paragraph 60).

#### Annex E — Distributed Systems

87. **Distributed systems (Annex E).** Excluded in its entirety.

#### Annex F — Information Systems

88. **Information systems (Annex F).** Excluded in its entirety. Rationale: requires generics (decimal types operations use generic packages).

#### Annex G — Numerics

89. **Numerics (Annex G).** The core numerics model from §3.5 is retained. Annex G extensions (complex types G.1, generic elementary functions G.2) are excluded (require generics).

#### Annex H — High Integrity Systems

90. **High integrity systems (Annex H).** The restrictions defined by Annex H that overlap with Safe's own restrictions are subsumed. `pragma Normalize_Scalars` is excluded (see §2.6).

#### Annex J — Obsolescent Features

91. **Obsolescent features (Annex J).** Excluded in their entirety. A conforming implementation shall reject any use of Annex J features. This includes `delta` constraint, `at` clause for entries, and other obsolescent forms.

---

## 2.2 Excluded SPARK Verification-Only Aspects

92. The following aspects exist solely for static verification in SPARK and have no runtime meaning. They are excluded from Safe source because Safe derives this information automatically (D22, D26):

| Aspect | 8652:2023 / SPARK RM Reference | Rationale |
|--------|-------------------------------|-----------|
| `Global` | §6.1.2, SPARK RM §6.1.4 | Derived automatically by the implementation |
| `Depends` | SPARK RM §6.1.5 | Derived automatically by the implementation |
| `Refined_Global` | SPARK RM §6.1.4 | Derived automatically by the implementation |
| `Refined_Depends` | SPARK RM §6.1.5 | Derived automatically by the implementation |
| `Refined_State` | SPARK RM §7.2.2 | No abstract state in Safe's single-file model |
| `Abstract_State` | SPARK RM §7.1.4 | No abstract state in Safe's single-file model |
| `Initializes` | SPARK RM §7.1.5 | Derived automatically by the implementation |
| `Ghost` | SPARK RM §6.9 | Ghost code for proof; out of scope for Safe |
| `SPARK_Mode` | SPARK RM §1.4 | The entire language is the mode |
| `Relaxed_Initialization` | SPARK RM §6.10 | Excluded; full initialisation required |
| `Contract_Cases` | §6.1.1, SPARK RM §6.1.3 | Excluded with all contract aspects |
| `Subprogram_Variant` | SPARK RM §6.1.6 | Excluded; proof-only aspect |

93. A conforming implementation shall reject any Safe source containing a user-authored instance of any aspect listed in paragraph 92.

---

## 2.3 Access Types and Ownership Model

94. Safe retains access-to-object types with the full SPARK 2022 ownership and borrowing model. This section specifies Safe's ownership rules directly and self-containedly. The SPARK RM §3.10 and SPARK UG §5.9 are informative design precedent; the normative rules are those stated below.

### 2.3.1 Retained Access Type Kinds

95. The following access-to-object type kinds are permitted in Safe:

| Access type kind | Safe declaration syntax | Ownership semantics |
|-----------------|----------------------|-------------------|
| Pool-specific access-to-variable | `type T_Ptr is access T;` | Owner — can be moved, borrowed, or observed |
| Non-null subtype of pool-specific | `subtype T_Ref is not null T_Ptr;` | Non-null owner — legal for dereference |
| Anonymous access-to-variable | `A : access T := ...` | Local borrower — X frozen while A in scope |
| Anonymous access-to-constant | `A : access constant T := ...` | Local observer — X frozen while A in scope |
| Named access-to-constant | `type C_Ptr is access constant T;` | Not subject to ownership checking; data is constant |
| General access-to-variable | `type G_Ptr is access all T;` | Subject to ownership checking; cannot be deallocated |

### 2.3.2 Move Semantics

96. When a named access-to-variable value is assigned to another object of the same type, a **move** occurs:

   (a) The source object becomes `null` after the assignment.

   (b) The target object becomes the new owner of the designated object.

   (c) A conforming implementation shall reject any subsequent dereference of the source object unless it has been reassigned or verified as non-null.

97. Move semantics apply to:

   (a) Direct assignment of access-to-variable values: `Y := X;`

   (b) Return of an access-to-variable value from a function.

   (c) Passing an access-to-variable value as an `out` or `in out` mode parameter (the caller's value may be moved out).

### 2.3.3 Borrowing

98. A **borrow** creates a temporary mutable alias to a designated object. Borrowing occurs when:

   (a) An anonymous access-to-variable object is initialised from an owning access value: `Y : access T := X;`

   (b) An `in out` mode access parameter receives an owning access value at a call site.

99. During a borrow:

   (a) The borrower has mutable access to the designated object.

   (b) The lender (the source of the borrow) is **frozen**: no read, write, or move of the lender is permitted while the borrow is active.

   (c) The borrow ends when the borrower goes out of scope (for local borrows) or when the subprogram returns (for parameter borrows).

   (d) Upon borrow end, the lender is unfrozen and regains full ownership.

100. **Reborrowing.** A borrower may create a further borrow from its own access value, subject to the same freezing rules. The chain of borrows forms a stack: the innermost borrow must end before the outer borrow can be accessed.

### 2.3.4 Observing

101. An **observe** creates a temporary read-only alias to a designated object. Observing occurs when:

   (a) An anonymous access-to-constant object is initialised from an owning access value using `.Access`: `Y : access constant T := X.Access;`

   (b) An `in` mode access parameter receives an owning access value at a call site.

102. During an observe:

   (a) The observer has read-only access to the designated object.

   (b) The observed object (the source) is **frozen**: no write or move of the source is permitted while the observe is active. Reads of the source are permitted.

   (c) Multiple simultaneous observers of the same object are permitted (multiple read-only aliases are safe).

   (d) The observe ends when the observer goes out of scope or the subprogram returns.

### 2.3.5 Allocators and Automatic Deallocation

103. **Allocators.** The `new` allocator creates a new designated object and returns an owning access value. The allocator syntax is:

   - `new (Expr : T)` — creates an object of type T initialised with Expr.
   - `new T` — creates an object of type T with default initialisation (when T has default initialisation).

104. **Automatic deallocation.** When a pool-specific owning access variable goes out of scope and its value is non-null, the designated object is automatically deallocated. Deallocation occurs at every scope exit point:

   (a) Normal end of scope (the textual `end` of the enclosing block, subprogram, or package).

   (b) Early `return` statements.

   (c) `exit` statements that transfer control out of the owning scope.

   (d) `goto` statements that transfer control out of the owning scope.

105. When multiple owned access objects exit scope simultaneously, the order of deallocation is the reverse of their declaration order.

106. General access-to-variable types (`access all T`) cannot be deallocated, as they may designate stack-allocated (aliased) objects.

### 2.3.6 Excluded Access Features

107. The following access-related features are excluded:

   (a) Access-to-subprogram types (paragraph 9).

   (b) `Unchecked_Access` attribute (paragraph 79).

   (c) `Ada.Unchecked_Deallocation` (paragraph 80).

   (d) Access discriminants (paragraph 11).

   (e) Storage pools and user-defined storage management (paragraph 80).

### 2.3.7 Ownership Checking Scope

108. All ownership checking is local to the compilation unit — no whole-program analysis is required. A conforming implementation shall verify ownership rules using only the current compilation unit's source and the dependency interface information of its direct and transitive dependencies. This is compatible with separate compilation.

---

## 2.4 Notation Changes

### 2.4.1 Dot Notation for Attributes

109. All 8652:2023 attribute references using tick notation (`X'Attr`) are replaced by dot notation (`X.Attr`) in Safe. The semantics of each retained attribute are unchanged; only the surface syntax changes.

110. **Resolution rule.** When `X.Name` appears in source, the implementation resolves it as follows:

   (a) If `X` denotes a record object, `Name` is resolved as a record component (field access).

   (b) If `X` denotes a type or subtype mark, `Name` is resolved as an attribute of that type. The retained attributes are listed in §2.5.

   (c) If `X` denotes a package name, `Name` is resolved as a declaration within that package.

   (d) If `X` denotes an access value, `Name` is resolved as implicit dereference followed by component selection (equivalent to `X.all.Name`).

111. This resolution is unambiguous because Safe has no overloading (D12) and no tagged types (D18). The implementation determines which case applies from the type or kind of `X`, which is known at the point of use due to declaration-before-use.

112. **Parameterised attributes.** Attributes that take parameters use function-call syntax: `T.Image(42)`, `T.Value("123")`. No special syntax is needed; the attribute is resolved as if it were a function of the type.

### 2.4.2 Type Annotation Syntax

113. Ada's qualified expression syntax `T'(Expr)` is replaced by type annotation syntax `(Expr : T)`.

114. **Grammar.**

```
annotated_expression ::= '(' expression ':' subtype_mark ')'
```

115. **Precedence.** The colon `:` binds looser than any operator. Parentheses are always required around type annotation expressions to avoid ambiguity with declaration syntax.

116. **Usage contexts.** Type annotation is used wherever Ada 2022 uses qualified expressions:

   (a) Aggregate disambiguation: `(others => 0) : Buffer_Type` becomes `((others => 0) : Buffer_Type)`.

   (b) Allocators: `new T'(Expr)` becomes `new (Expr : T)`.

   (c) Type assertion in expressions: `T'(X)` becomes `(X : T)`.

---

## 2.5 Attribute Inventory

117. The following tables list all language-defined attributes from 8652:2023 with their Safe status. All retained attributes use dot notation.

### 2.5.1 Retained Attributes

118.

| 8652:2023 Attribute | Safe Dot Notation | Reference |
|--------------------|--------------------|-----------|
| `Access` | `.Access` | §3.10.2(24) |
| `Address` | `.Address` | §13.3(11) |
| `Adjacent` | `.Adjacent` | §A.5.3(48) |
| `Aft` | `.Aft` | §3.5.10(5) |
| `Alignment` | `.Alignment` | §13.3(23) |
| `Base` | `.Base` | §3.5(15) |
| `Bit_Order` | `.Bit_Order` | §13.5.3(4) |
| `Ceiling` | `.Ceiling` | §A.5.3(33) |
| `Component_Size` | `.Component_Size` | §13.3(69) |
| `Compose` | `.Compose` | §A.5.3(24) |
| `Constrained` | `.Constrained` | §3.7.2(3) |
| `Copy_Sign` | `.Copy_Sign` | §A.5.3(51) |
| `Definite` | `.Definite` | §12.5.1(23) |
| `Delta` | `.Delta` | §3.5.10(3) |
| `Denorm` | `.Denorm` | §A.5.3(9) |
| `Digits` | `.Digits` | §3.5.8(2), §3.5.10(7) |
| `Enum_Rep` | `.Enum_Rep` | §13.4(10.3) |
| `Enum_Val` | `.Enum_Val` | §13.4(10.5) |
| `Exponent` | `.Exponent` | §A.5.3(18) |
| `First` | `.First` | §3.5(12), §3.6.2(3) |
| `First_Valid` | `.First_Valid` | §3.5.5(7.2) |
| `Floor` | `.Floor` | §A.5.3(30) |
| `Fore` | `.Fore` | §3.5.10(4) |
| `Fraction` | `.Fraction` | §A.5.3(21) |
| `Image` | `.Image` | §4.10(30), §4.10(33) |
| `Last` | `.Last` | §3.5(13), §3.6.2(5) |
| `Last_Valid` | `.Last_Valid` | §3.5.5(7.4) |
| `Leading_Part` | `.Leading_Part` | §A.5.3(54) |
| `Length` | `.Length` | §3.6.2(9) |
| `Machine` | `.Machine` | §A.5.3(60) |
| `Machine_Emax` | `.Machine_Emax` | §A.5.3(8) |
| `Machine_Emin` | `.Machine_Emin` | §A.5.3(7) |
| `Machine_Mantissa` | `.Machine_Mantissa` | §A.5.3(6) |
| `Machine_Overflows` | `.Machine_Overflows` | §A.5.3(12) |
| `Machine_Radix` | `.Machine_Radix` | §A.5.3(2) |
| `Machine_Rounds` | `.Machine_Rounds` | §A.5.3(11) |
| `Max` | `.Max` | §3.5(19) |
| `Max_Alignment_For_Allocation` | `.Max_Alignment_For_Allocation` | §13.11.1(4) |
| `Max_Size_In_Storage_Elements` | `.Max_Size_In_Storage_Elements` | §13.11.1(3) |
| `Min` | `.Min` | §3.5(16) |
| `Mod` | `.Mod` | §3.5.4(17) |
| `Model` | `.Model` | §A.5.3(68) |
| `Model_Emin` | `.Model_Emin` | §A.5.3(65) |
| `Model_Epsilon` | `.Model_Epsilon` | §A.5.3(66) |
| `Model_Mantissa` | `.Model_Mantissa` | §A.5.3(64) |
| `Model_Small` | `.Model_Small` | §A.5.3(67) |
| `Modulus` | `.Modulus` | §3.5.4(17) |
| `Object_Size` | `.Object_Size` | §13.3(58) |
| `Overlaps_Storage` | `.Overlaps_Storage` | §13.3(73.1) |
| `Pos` | `.Pos` | §3.5.5(2) |
| `Pred` | `.Pred` | §3.5(25) |
| `Range` | `.Range` | §3.5(14), §3.6.2(7) |
| `Remainder` | `.Remainder` | §A.5.3(45) |
| `Round` | `.Round` | §3.5.10(12) |
| `Rounding` | `.Rounding` | §A.5.3(36) |
| `Safe_First` | `.Safe_First` | §A.5.3(71) |
| `Safe_Last` | `.Safe_Last` | §A.5.3(72) |
| `Scale` | `.Scale` | §3.5.10(11) |
| `Scaling` | `.Scaling` | §A.5.3(27) |
| `Size` | `.Size` | §13.3(40), §13.3(45) |
| `Small` | `.Small` | §3.5.10(2) |
| `Storage_Size` | `.Storage_Size` | §13.11.1(1) |
| `Succ` | `.Succ` | §3.5(22) |
| `Truncation` | `.Truncation` | §A.5.3(42) |
| `Unbiased_Rounding` | `.Unbiased_Rounding` | §A.5.3(39) |
| `Val` | `.Val` | §3.5.5(5) |
| `Valid` | `.Valid` | §13.9.2(3) |
| `Value` | `.Value` | §3.5(52) |
| `Wide_Image` | `.Wide_Image` | §4.10(34) |
| `Wide_Value` | `.Wide_Value` | §3.5(53) |
| `Wide_Wide_Image` | `.Wide_Wide_Image` | §4.10(35) |
| `Wide_Wide_Value` | `.Wide_Wide_Value` | §3.5(54) |
| `Wide_Wide_Width` | `.Wide_Wide_Width` | §3.5.5(7.7) |
| `Wide_Width` | `.Wide_Width` | §3.5.5(7.6) |
| `Width` | `.Width` | §3.5.5(7.5) |

### 2.5.2 Excluded Attributes

119.

| 8652:2023 Attribute | Reason for Exclusion |
|--------------------|---------------------|
| `Body_Version` | Requires separate body (§7.2) |
| `Callable` | Requires Ada tasking (§9.9) |
| `Caller` | Requires entries (§9.9) |
| `Class` | Requires tagged types (§3.9) |
| `Count` | Requires entries (§9.9) |
| `External_Tag` | Requires tagged types (§13.3) |
| `Has_Same_Storage` | Implementation-internal |
| `Identity` (exception) | Requires exceptions (§11.4.1) |
| `Identity` (task) | Requires Ada tasking (§9.1) |
| `Index` | Requires iterators (§5.5.2) |
| `Input` | Requires streams (§13.13.2) |
| `Machine_Rounding` | Implementation-internal |
| `Old` | Requires postconditions (§6.1.1) |
| `Output` | Requires streams (§13.13.2) |
| `Parallel_Reduce` | Requires parallel features (§5.6.1) |
| `Partition_Id` | Requires distributed systems (Annex E) |
| `Put_Image` | Requires tagged types (§4.10) |
| `Read` | Requires streams (§13.13.2) |
| `Reduce` | Requires reduction expressions (§4.5.10) |
| `Result` | Requires postconditions (§6.1.1) |
| `Storage_Pool` | Requires user-defined pools (§13.11) |
| `Tag` | Requires tagged types (§3.9) |
| `Terminated` | Requires Ada tasking (§9.9) |
| `Unchecked_Access` | Unsafe; excluded (§13.10) |
| `Update` | Deprecated; replaced by delta aggregates (§4.3.4) |
| `Version` | Requires separate body (§7.2) |
| `Write` | Requires streams (§13.13.2) |

---

## 2.6 Pragma Inventory

120. The following tables list all language-defined pragmas from 8652:2023 with their Safe status.

### 2.6.1 Retained Pragmas

121.

| Pragma | Reference | Notes |
|--------|-----------|-------|
| `Assert` | §11.4.2 | Sole assertion mechanism; always enabled |
| `Atomic` | §C.6 | Retained for hardware register modelling |
| `Atomic_Components` | §C.6 | Retained for array components |
| `Convention` | | Excluded — see paragraph 84 |
| `Discard_Names` | §C.5 | Retained |
| `Independent` | §C.6 | Retained for memory-mapped registers |
| `Independent_Components` | §C.6 | Retained for array components |
| `Inline` | §6.3.2 | Retained |
| `Linker_Options` | §B.1 | Excluded — see paragraph 84 |
| `No_Return` | §6.5.1 | Retained (as aspect; pragma form also retained) |
| `Optimize` | §2.8 | Retained |
| `Pack` | §13.2 | Retained |
| `Preelaborable_Initialization` | §10.2.1 | Retained |
| `Preelaborate` | §10.2.1 | Retained |
| `Priority` | §D.1 | Retained for task declarations (Section 4 syntax) |
| `Pure` | §10.2.1 | Retained |
| `Reviewable` | §H.3.1 | Retained |
| `Volatile` | §C.6 | Retained for hardware registers |
| `Volatile_Components` | §C.6 | Retained for array components |

### 2.6.2 Excluded Pragmas

122.

| Pragma | Reference | Reason for Exclusion |
|--------|-----------|---------------------|
| `All_Calls_Remote` | §E.2.3 | Requires distributed systems |
| `Assertion_Policy` | §11.4.2 | Assertions always enabled |
| `Asynchronous` | §E.4.1 | Requires distributed systems |
| `Controlled` | §13.11.3 | Requires controlled types |
| `Default_Storage_Pool` | §13.11.3 | Requires storage pools |
| `Detect_Blocking` | §H.5 | Implementation concern |
| `Elaborate` | §10.2.1 | Circular dependencies prohibited |
| `Elaborate_All` | §10.2.1 | Circular dependencies prohibited |
| `Elaborate_Body` | §10.2.1 | No separate body model |
| `Export` | §B.1 | Requires foreign language interface |
| `Import` | §B.1 | Requires foreign language interface |
| `Inspection_Point` | §H.3.2 | Implementation concern |
| `Interrupt_Handler` | §C.3.1 | Requires interrupt handling |
| `Interrupt_Priority` | §D.1 | Requires interrupt handling |
| `List` | §2.8 | Compiler directive; not language semantic |
| `Locking_Policy` | §D.3 | Implementation concern |
| `Normalize_Scalars` | §H.1 | Implementation concern; may mask uninitialised reads |
| `Page` | §2.8 | Compiler directive; not language semantic |
| `Partition_Elaboration_Policy` | §D.13 | Implementation concern (informative note in §04) |
| `Profile` | §13.12.1 | Not needed; restrictions defined by this specification |
| `Queuing_Policy` | §D.4 | Requires full Ada tasking |
| `Remote_Call_Interface` | §E.2.3 | Requires distributed systems |
| `Remote_Types` | §E.2.2 | Requires distributed systems |
| `Restrictions` | §13.12 | Not needed; restrictions defined by this specification |
| `Shared_Passive` | §E.2.1 | Requires distributed systems |
| `Storage_Size` (pragma form) | §13.3 | Aspect form retained |
| `Suppress` | §11.5 | Excluded; all checks retained |
| `Task_Dispatching_Policy` | §D.2.2 | Implementation concern |
| `Unchecked_Union` | §B.3.3 | Requires unchecked features |
| `Unsuppress` | §11.5 | Excluded with Suppress |

---

## 2.7 Contract Exclusions

123. The following contract-related aspects are excluded from Safe source. Rationale: replaced by `pragma Assert` for runtime defensive checks; Bronze and Silver assurance guaranteed by D26/D27 language rules without developer-authored contracts.

| Aspect | Reference | Replacement |
|--------|-----------|-------------|
| `Pre` | §6.1.1 | `pragma Assert` |
| `Post` | §6.1.1 | `pragma Assert` |
| `Pre'Class` | §6.1.1 | Excluded (no tagged types) |
| `Post'Class` | §6.1.1 | Excluded (no tagged types) |
| `Contract_Cases` | SPARK RM §6.1.3 | `pragma Assert` |
| `Type_Invariant` | §7.3.2 | Excluded (no tagged types) |
| `Type_Invariant'Class` | §7.3.2 | Excluded (no tagged types) |
| `Dynamic_Predicate` | §3.2.4 | Excluded (see paragraph 5) |
| `Static_Predicate` | §3.2.4 | Excluded (see paragraph 5) |
| `Default_Initial_Condition` | §7.3.3 | Excluded (no tagged types) |
| `Loop_Invariant` | SPARK RM §5.5 | Excluded; proof-only aspect |
| `Loop_Variant` | SPARK RM §5.5 | Excluded; proof-only aspect |

124. A conforming implementation shall reject any Safe source bearing any aspect listed in paragraph 123.

---

## 2.8 Silver-by-Construction Rules

125. The following four legality and semantic rules are new to Safe — they have no 8652:2023 precedent. Together they guarantee that every conforming Safe program is free of runtime errors (D26, D27).

### 2.8.1 Rule 1: Wide Intermediate Arithmetic

126. All integer arithmetic expressions shall be evaluated in a mathematical integer type with no overflow. This modifies the dynamic semantics of 8652:2023 §4.5 (Operators and Expression Evaluation): intermediate integer results are not bounded by the base range of the operand types.

127. Range checks shall be performed only when the result is:

   (a) Assigned to an object.

   (b) Passed as a parameter.

   (c) Returned from a function.

128. If the static range of any declared integer type in the program exceeds the 64-bit signed range (-(2^63) .. (2^63 - 1)), the program is nonconforming and a conforming implementation shall reject it.

129. **Intermediate overflow legality rule.** If a conforming implementation cannot establish, by sound static range analysis, that every intermediate subexpression of an integer arithmetic expression stays within the 64-bit signed range, the expression shall be rejected with a diagnostic.

130. Narrowing checks at assignment, return, and parameter points shall be discharged via sound static range analysis on the wide result. Interval analysis is one permitted technique; no specific analysis algorithm is mandated.

**Example (conforming):**

```ada
public type Reading is range 0 .. 4095;

public function Average (A, B : Reading) return Reading is
begin
    return (A + B) / 2;  -- wide intermediate: max (4095+4095)/2 = 4095
                          -- range check at return: provably in 0..4095
                          -- D27 proof: Reading.First <= result <= Reading.Last
end Average;
```

### 2.8.2 Rule 2: Strict Index Typing

131. The index expression in an indexed_component (8652:2023 §4.1.1) shall be of a type or subtype that is the same as, or a subtype of, the array's index type. A conforming implementation shall reject any indexed_component where the index expression's type is wider than the array's index type.

132. This guarantees that every array index check is dischargeable — the index value is constrained by its type to be within the array bounds.

**Example (conforming):**

```ada
public type Channel_Id is range 0 .. 7;
Table : array (Channel_Id) of Integer;

public function Lookup (Ch : Channel_Id) return Integer is
begin
    return Table(Ch);  -- legal: Ch is in 0..7 by type
                       -- D27 proof: Ch in Channel_Id.First .. Channel_Id.Last
end Lookup;
```

**Nonconforming Example — Rule 2 violation at indexed_component:**

```ada
-- NONCONFORMING: index type wider than array index type
public function Bad_Lookup (N : Integer) return Integer is
begin
    return Table(N);  -- rejected: Integer is not a subtype of Channel_Id
end Bad_Lookup;
```

### 2.8.3 Rule 3: Division by Provably Nonzero Divisor

133. The right operand of the operators `/`, `mod`, and `rem` (8652:2023 §4.5.5) shall be provably nonzero at compile time. A conforming implementation shall accept a divisor expression as provably nonzero if any of the following conditions holds:

   (a) The divisor expression has a type or subtype whose range excludes zero.

   (b) The divisor expression is a static expression (8652:2023 §4.9) whose value is nonzero.

   (c) The divisor expression is an explicit conversion to a nonzero subtype where the conversion is provably valid at that program point.

134. If none of the conditions in paragraph 133 holds, the program is nonconforming and a conforming implementation shall reject the expression with a diagnostic.

135. The language provides standard subtypes that exclude zero:

```ada
subtype Positive is Integer range 1 .. Integer.Last;
subtype Negative is Integer range Integer.First .. -1;
```

**Example (conforming — condition a, nonzero type):**

```ada
public type Seconds is range 1 .. 3600;

public function Rate (Distance : Meters; Time : Seconds) return Integer is
begin
    return Distance / Time;  -- legal: Seconds excludes zero
                              -- D27 proof: Time >= 1
end Rate;
```

**Example (conforming — condition b, static nonzero literal):**

```ada
public function Average (A, B : Reading) return Reading is
begin
    return (A + B) / 2;  -- legal: 2 is a static nonzero expression
                          -- D27 proof: divisor = 2 /= 0
end Average;
```

**Nonconforming Example — Rule 3 violation at division:**

```ada
-- NONCONFORMING: divisor type includes zero
public function Bad_Divide (A, B : Integer) return Integer is
begin
    return A / B;  -- rejected: Integer range includes zero
end Bad_Divide;
```

### 2.8.4 Rule 4: Not-Null Dereference

136. Dereference of an access value — whether explicit (`.all`) or implicit (selected component through an access value) — shall require the access subtype to be `not null` (8652:2023 §3.10). A conforming implementation shall reject any dereference where the access subtype at the point of dereference does not exclude null.

137. Every access type declaration produces two usable forms: a nullable one for storage and a non-null one for dereference:

```ada
public type Node;
public type Node_Ptr is access Node;            -- nullable, for storage
public subtype Node_Ref is not null Node_Ptr;   -- non-null, for dereference
```

138. Null comparison (`= null`, `/= null`) is always legal on any access type; only dereference requires the not-null guarantee.

**Example (conforming):**

```ada
public function Value_Of (N : Node_Ref) return Integer
is (N.Value);  -- legal: Node_Ref excludes null
               -- D27 proof: N /= null by subtype
```

**Nonconforming Example — Rule 4 violation at dereference:**

```ada
-- NONCONFORMING: dereference of nullable access type
public function Bad_Value (N : Node_Ptr) return Integer
is (N.Value);  -- rejected: Node_Ptr includes null
```

### 2.8.5 Combined Effect

139. These four rules ensure that the six categories of runtime check are all dischargeable from static type and range information derivable from the program text:

| Check | How Discharged |
|-------|---------------|
| Integer overflow | Impossible — wide intermediate arithmetic (Rule 1) |
| Range on assignment/return/parameter | Sound static range analysis on wide intermediates (Rule 1) |
| Array index out of bounds | Index type matches array index type (Rule 2) |
| Division by zero | Divisor is provably nonzero (Rule 3) |
| Null dereference | Access subtype is `not null` at every dereference (Rule 4) |
| Discriminant | Discriminant type is discrete and static; variant access requires matching discriminant value |

---

## 2.9 Interleaved Declarations

140. Inside subprogram bodies, declarations and statements may interleave freely after `begin` (D11). A declaration is visible from its point of declaration to the end of the enclosing scope. The pre-`begin` declarative part is still permitted but not required. This modifies 8652:2023 §3.11, which requires all declarations before `begin`.

---

## 2.10 No Overloading

141. Subprogram name overloading is excluded (D12). Each subprogram identifier shall denote exactly one subprogram within a given declarative region. A conforming implementation shall reject any declarative region containing two subprogram declarations with the same identifier.

142. **Predefined operators** for numeric types, Boolean, and other language-defined types are retained. These are intrinsic to the type and do not participate in overload resolution.

143. **Cross-package names.** The same subprogram name may appear in different packages (qualified by the package name: `Sensors.Initialize` vs. `Motors.Initialize`). This is not overloading; it is distinct declarations in distinct namespaces.

---

## 2.11 No General Use Clauses

144. General `use` clauses (8652:2023 §8.4 first form) are excluded (D13). `use type` clauses (§8.4 second form) are retained.
