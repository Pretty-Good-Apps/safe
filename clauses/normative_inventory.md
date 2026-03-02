# Normative Clause Inventory

**Source commit:** `4aecf219ffa5473bfc42b026a66c8bdea2ce5872`
**Extraction date:** 2026-03-02
**Total normative clauses extracted:** 205

---

## Summary by Classification

| Classification | Count |
|----------------|-------|
| legality_rule | 105 |
| static_semantics | 12 |
| dynamic_semantics | 27 |
| implementation_requirement | 38 |
| conformance_requirement | 23 |
| **Total** | **205** |

## Critical Coverage Targets

### 1. D27 Silver-by-Construction Rules (S2.8, S5.3)

**23 clauses** cover all 5 D27 rules:

- **Rule1**: 7 clauses
- **Rule2**: 2 clauses
- **Rule3**: 2 clauses
- **Rule4**: 1 clauses
- **Rule5**: 5 clauses

### 2. Silver Runtime Check Categories (S5.3.8 table)

| Check Category | Clauses |
|----------------|---------|
| integer-overflow | 1 |
| range-check | 4 |
| float-overflow | 1 |
| float-div-zero | 1 |
| float-nan | 2 |
| float-range-check | 3 |
| index-check | 2 |
| division-check | 2 |
| null-check | 1 |
| discriminant-check | 1 |
| accessibility-check | 2 |

All 16 check categories from the S5.3.8 table are covered by the D27 rules and associated clauses.

### 3. Conformance Summary Table (S6.9)

**19 clauses** from spec/06-conformance.md cover all conformance requirements.

### 4. TBD Items (S0.8)

**1 clause(s)** reference TBD items. The TBD register contains 14 items (TBD-01 through TBD-14),
each governed by the normative requirement that 'each item shall be resolved before baselining.'

| TBD ID | Summary | Owner | Target |
|--------|---------|-------|--------|
| TBD-01 | Target platform constraints beyond "Ada compiler exists" | Language committee | v0.2 |
| TBD-02 | Performance targets (compile time, proof time, code size) | Implementation lead | v0.3 |
| TBD-03 | Memory model constraints (stack/heap bounds, static allocation bounding) | Language committee | v0.2 |
| TBD-04 | Library subset boundary and curation policy | Library reviewer | v0.2 |
| TBD-05 | Diagnostic catalogue and localisation | Implementation lead | v0.3 |
| TBD-06 | `Constant_After_Elaboration` aspect for concurrency analysis | Concurrency reviewer | v0.2 |
| TBD-07 | Abort handler behaviour (language-defined or implementation-defined) | Language committee | v0.2 |
| TBD-08 | AST/IR interchange format (if any) | Tooling lead | v0.4 |
| TBD-09 | Deadlock freedom (static topology analysis, channel ordering) | Concurrency reviewer | v0.3 |
| TBD-10 | Numeric model: required ranges for predefined integer types | Numerics reviewer | v0.2 |
| TBD-11 | Automatic deallocation semantics (ordering, early return, multiple objects) | Ownership reviewer | v0.2 |
| TBD-12 | Modular arithmetic wrapping semantics (non-wrapping default) | Numerics reviewer | v0.2 |
| TBD-13 | Limited/private type views across packages (`with type` mechanism) | Language committee | v0.3 |
| TBD-14 | Partial initialisation facility (`Relaxed_Initialization`) | Ownership reviewer | v0.4 |

### 5. Implementation-Defined Behaviours (S6.7)

Section 6.7 enumerates 9 implementation-defined behaviours (items a through i).
A conforming implementation shall document its choices for each.

### 6. Ownership Rules (S2)

**32 clauses** cover the ownership model including:
- Move semantics (S2.3.2)
- Borrowing (S2.3.3)
- Observing (S2.3.4)
- Lifetime containment (S2.3.4a)
- Allocators and automatic deallocation (S2.3.5)
- Accessibility rules (S2.3.8)
- Task-variable ownership (S4.5)
- Channel ownership transfer (S4.3)

### 7. Channel/Task Rules (S4)

**60 clauses** cover the channel/task concurrency model.

### 8. Single-File Package Rules (S3)

**14 clauses** cover single-file package requirements.

---

## Clauses by Spec File and Section

### spec/00-front-matter.md

**4 clauses**

#### S0.1 - Title and Language Name

- **[CON]** `SAFE@4aecf21:spec/00-front-matter.md#0.1.p1:40d0d4cf`
  This document specifies the Safe programming language. Safe is a systems programming language define...

- **[IMP]** `SAFE@4aecf21:spec/00-front-matter.md#0.1.p2:9e5cd9ab`
  The file extension for Safe source files is .safe.

#### S0.5 - Method of Description

- **[CON]** `SAFE@4aecf21:spec/00-front-matter.md#0.5.p21:5eb1de72`
  This specification uses 'shall' for requirements, 'may' for permissions, and 'should' for recommenda...

#### S0.8 - TBD Register

- **[CON]** `SAFE@4aecf21:spec/00-front-matter.md#0.8.p27:5000a79a`
  Each item shall be resolved before baselining.


### spec/01-base-definition.md

**4 clauses**

#### S1 - Base Definition

- **[CON]** `SAFE@4aecf21:spec/01-base-definition.md#1.p1:e7bf1014`
  The Safe language is defined as ISO/IEC 8652:2023 (Ada 2022), as restricted by Section 2 and modifie...

- **[CON]** `SAFE@4aecf21:spec/01-base-definition.md#1.p2:b610468e`
  All syntax, legality rules, static semantics, dynamic semantics, and implementation requirements of ...

- **[STA]** `SAFE@4aecf21:spec/01-base-definition.md#1.p3:a2ff4ad4`
  A construct that appears in 8652:2023 but is not mentioned in Section 2 (Restrictions and Modificati...

- **[STA]** `SAFE@4aecf21:spec/01-base-definition.md#1.p6:b83ece40`
  Any feature of 8652:2023 not addressed by this specification or its cross-referenced sections is ret...


### spec/02-restrictions.md

**83 clauses**

#### S2.1.1 - Lexical Elements

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.1.p2:75c5cfea`
  A conforming implementation shall reject any program that uses a reserved word as an identifier.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.1.p3:f8550668`
  Safe adds the following reserved words: public, channel, send, receive, try_send, try_receive, capac...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.1.p4:b8e73758`
  A conforming implementation shall reject any use of tick for attribute references or qualified expre...

#### S2.1.2 - Declarations and Types

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.2.p5:c8832ac8`
  A conforming implementation shall reject any subtype declaration bearing a Static_Predicate or Dynam...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.2.p7:2de62408`
  A conforming implementation shall reject any tagged type declaration, type extension declaration, ab...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.2.p9:faae18b9`
  A conforming implementation shall reject any access-to-subprogram type declaration.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.2.p11:3fd55933`
  A conforming implementation shall reject any discriminant of an access type.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.2.p12:8da68138`
  A conforming implementation shall reject any type derivation from Ada.Finalization.Controlled or Ada...

#### S2.1.3 - Names and Expressions

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p14:4ab42f23`
  A conforming implementation shall reject any declaration of a type with Implicit_Dereference aspect.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p15:9092af85`
  A conforming implementation shall reject any declaration of a type with Constant_Indexing or Variabl...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p16:6436f829`
  A conforming implementation shall reject any declaration of a type with Integer_Literal, Real_Litera...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p17:be123e5f`
  A conforming implementation shall reject any extension aggregate.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p19:29c43768`
  A conforming implementation shall reject any container aggregate.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p22:58a7c04c`
  A conforming implementation shall reject any quantified expression (for all, for some).

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p23:e51d510c`
  A conforming implementation shall reject any reduction expression.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.3.p25:f55ddbee`
  A conforming implementation shall reject any qualified expression using tick notation.

#### S2.1.4 - Statements

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.4.p29:f27b01a7`
  A conforming implementation shall reject any declaration of a type with Default_Iterator or Iterator...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.4.p31:3aff42cb`
  A conforming implementation shall reject any procedural iterator.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.4.p32:d090f2f1`
  A conforming implementation shall reject any parallel block statement.

#### S2.1.5 - Subprograms

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.5.p34:70346a23`
  A conforming implementation shall reject any subprogram bearing Pre, Post, Pre'Class, or Post'Class ...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.5.p35:9db565e8`
  A conforming implementation shall reject any user-authored Global or Global'Class aspect in Safe sou...

- **[STA]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.5.p36:ba7835b4`
  Each subprogram identifier denotes exactly one subprogram within a given declarative region.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.5.p38:872f4ec6`
  A return statement shall not appear within a task body.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.5.p40:cc41753d`
  A conforming implementation shall reject any user-defined operator function (a function whose design...

#### S2.1.6 - Packages

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.6.p44:a5524a86`
  A conforming implementation shall reject any standalone package body compilation unit.

#### S2.1.7 - Visibility Rules

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.7.p51:3bd0226a`
  A conforming implementation shall reject any use Package_Name; clause.

#### S2.1.8 - Tasks and Synchronisation

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.8.p57:6fc7a14c`
  Safe tasks shall not terminate.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.8.p58:9bf4999c`
  A conforming implementation shall reject any user-declared protected type or protected object declar...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.8.p59:95c073d3`
  A conforming implementation shall reject any entry_declaration, accept_statement, entry_call_stateme...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.8.p60:75dc85e6`
  A conforming implementation shall reject any delay until statement.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.8.p61:f91fb172`
  A conforming implementation shall reject any selective_accept, timed_entry_call, conditional_entry_c...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.8.p62:9053b623`
  A conforming implementation shall reject any abort statement.

#### S2.1.9 - Program Structure

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.9.p65:a6f8ab1c`
  Library units shall be packages; library-level subprograms are not permitted as compilation units.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.9.p66:3d98f9e9`
  A conforming implementation shall reject any program with circular with dependencies among compilati...

#### S2.1.10 - Exceptions

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.10.p67:50d815f0`
  A conforming implementation shall reject any exception declaration, exception handler, raise stateme...

#### S2.1.11 - Generic Units

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.11.p69:4ced1c77`
  A conforming implementation shall reject any generic declaration, generic body, or generic instantia...

#### S2.1.12 - Representation Issues

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.12.p77:8b158e82`
  A conforming implementation shall reject any machine code insertion.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.12.p78:803e4add`
  A conforming implementation shall reject any instantiation of or reference to Ada.Unchecked_Conversi...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.12.p79:90727967`
  A conforming implementation shall reject any use of .Unchecked_Access.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.12.p80:15d3c6f7`
  A conforming implementation shall reject any Storage_Pool aspect specification, any storage pool typ...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.12.p82:453192f0`
  A conforming implementation shall reject any stream attribute reference or stream type declaration.

#### S2.1.13 - Annexes

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.13.p84:84829058`
  A conforming implementation shall reject any pragma Import, pragma Export, pragma Convention, and al...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.1.13.p91:4a433f78`
  A conforming implementation shall reject any use of Annex J features.

#### S2.2 - Excluded SPARK Verification-Only Aspects

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.2.p93:301d16b8`
  A conforming implementation shall reject any Safe source containing a user-authored instance of any ...

#### S2.7 - Contract Exclusions

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.7.p124:ef993f07`
  A conforming implementation shall reject any Safe source bearing any aspect listed in paragraph 123.

#### S2.3.2 - Move Semantics

- **[DYN]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.2.p96a:0eaf48aa`
  The source object becomes null after the assignment.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.2.p96c:0b45de01`
  A conforming implementation shall reject any subsequent dereference of the source object unless it h...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.2.p97a:8d0214d5`
  The target of any move into a pool-specific owning access variable shall be provably null at the poi...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.2.p97a-diag:dc259149`
  A conforming implementation shall reject any move into a variable that is not provably null at that ...

#### S2.3.3 - Borrowing

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.3.p99b:47108b45`
  The lender (the source of the borrow) is frozen: no read, write, or move of the lender is permitted ...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.3.p100a:ba849e66`
  An anonymous access variable shall only receive its value at its point of declaration. A conforming ...

#### S2.3.4a - Lifetime Containment

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.4a.p102a:5bc5ab8b`
  The scope of a borrower or observer shall be contained within the scope of the lender or observed ob...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.4a.p102a-a:ae729065`
  A conforming implementation shall reject any borrow or observe where the borrower/observer could out...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.4a.p102b:2ed757bd`
  No access value shall designate a deallocated object at any reachable program point.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.4a.p102b-diag:ddab22c8`
  A conforming implementation shall reject any program where it cannot establish that all access value...

#### S2.3.5 - Allocators and Automatic Deallocation

- **[DYN]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.5.p103a:520dc0d4`
  If an allocator cannot obtain sufficient storage to create the designated object, the program is abo...

- **[DYN]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.5.p104:d9f9b8d9`
  When a pool-specific access variable goes out of scope and its value is non-null, the designated obj...

- **[DYN]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.5.p104a:b70c1d15`
  Named access-to-constant types are pool-specific and allocate from a pool. Automatic deallocation at...

- **[DYN]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.5.p105:d4a9cdb4`
  When multiple pool-specific access objects exit scope simultaneously, the order of deallocation is t...

- **[STA]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.5.p106:bae12394`
  General access-to-variable types (access all T) cannot be deallocated, as they may designate stack-a...

#### S2.3.7 - Ownership Checking Scope

- **[IMP]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.7.p108:083e15a2`
  All ownership checking is local to the compilation unit. A conforming implementation shall verify ow...

#### S2.3.8 - Accessibility Rules

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.8.p111:42819528`
  A conforming implementation shall reject any use of .Access on a local aliased variable where the re...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.8.p111a:a858bdfc`
  A function shall not return the result of .Access applied to one of its local aliased variables or p...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.8.p111b:2921e9d2`
  The result of .Access on a local aliased variable shall not be assigned to a variable declared in an...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.8.p111c:819cc398`
  The result of .Access on a local aliased variable shall not be sent through a channel.

- **[IMP]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.8.p113:75fcd707`
  A conforming implementation shall discharge the accessibility check row in the runtime check table e...

- **[STA]** `SAFE@4aecf21:spec/02-restrictions.md#2.3.8.p109-end:5d18703e`
  No runtime accessibility check is ever required.

#### S2.8.1 - Rule 1: Wide Intermediate Arithmetic

- **[DYN]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.1.p126:812b54a8`
  All integer arithmetic expressions shall be evaluated in a mathematical integer type with no overflo...

- **[DYN]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.1.p127:d5d93439`
  Range checks shall be performed only at narrowing points: assigned to an object, passed as a paramet...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.1.p128:d2e83ca8`
  If the static range of any declared integer type in the program exceeds the 64-bit signed range, the...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.1.p129:9f3b1394`
  If a conforming implementation cannot establish, by sound static range analysis, that every intermed...

- **[IMP]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.1.p130:2289e5b2`
  Narrowing checks at all five categories of narrowing point shall be discharged via sound static rang...

#### S2.8.2 - Rule 2: Provable Index Safety

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.2.p131:30aba5f5`
  The index expression in an indexed_component shall be provably within the array object's index bound...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.2.p132:8613ecf4`
  If neither condition holds, the program is nonconforming and the implementation shall reject it with...

#### S2.8.3 - Rule 3: Division by Provably Nonzero Divisor

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.3.p133:0610d951`
  The right operand of the operators /, mod, and rem shall be provably nonzero at compile time.

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.3.p134:90a17a3b`
  If none of the conditions in paragraph 133 holds, the program is nonconforming and a conforming impl...

#### S2.8.4 - Rule 4: Not-Null Dereference

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.4.p136:fa5e94b7`
  Dereference of an access value shall require the access subtype to be not null. A conforming impleme...

#### S2.8.5 - Rule 5: Floating-Point Non-Trapping Semantics

- **[IMP]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.5.p139:d50bc714`
  A conforming implementation shall ensure that all predefined floating-point types have Machine_Overf...

- **[IMP]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.5.p139b:5e20032b`
  The implementation shall apply sound static range analysis to establish that the value at the narrow...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.5.p139c:7fad4f7d`
  If a conforming implementation cannot establish, by sound static range analysis, that a floating-poi...

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.8.5.p139d:56f1f36b`
  NaN and infinity shall not survive narrowing: no conforming program can assign NaN or infinity to a ...

#### S2.9 - Interleaved Declarations

- **[STA]** `SAFE@4aecf21:spec/02-restrictions.md#2.9.p140:7eeb1bb6`
  Declarations and statements may interleave freely after begin.

#### S2.10 - No Overloading

- **[LEG]** `SAFE@4aecf21:spec/02-restrictions.md#2.10.p141:9e5dc3fe`
  Each subprogram identifier shall denote exactly one subprogram within a given declarative region. A ...


### spec/03-single-file-packages.md

**24 clauses**

#### S3 - Single-File Packages

- **[IMP]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.p0:dcd1bc13`
  A conforming implementation shall make the public interface available to dependent compilation units...

#### S3.2.1 - Matching End Identifier

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.1.p8:cb47c342`
  The defining_identifier after end in a package unit shall match the defining_identifier after packag...

#### S3.2.2 - Declaration-Before-Use

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.2.p9:d7d76101`
  Every name used in a declaration or statement shall have been declared earlier in the same scope or ...

#### S3.2.3 - Forward Declarations for Mutual Recursion

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.3.p12:b76eb7bf`
  The body completing a forward declaration shall appear later in the same declarative region. The sub...

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.3.p13:8bf74e20`
  A conforming implementation shall reject a forward declaration with no completing body in the same d...

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.3.p14:c205a40a`
  If the subprogram is public, the public keyword shall appear on the forward declaration. The complet...

#### S3.2.4 - No Package-Level Statements

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.4.p15:e090edc2`
  A package shall not contain executable statements at the package level. All executable code shall ap...

#### S3.2.5 - Public Keyword Visibility Rules

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.5.p19:05cb629b`
  A conforming implementation shall reject any public annotation on a declaration kind not listed in p...

- **[STA]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.5.p20:d2c1d841`
  A declaration without the public keyword is private to the declaring package and shall not be direct...

#### S3.2.6 - Opaque Types

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.6.p23:26dc2217`
  Clients shall not access individual fields of an opaque type. A conforming implementation shall reje...

- **[IMP]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.6.p24:12e57227`
  The implementation shall export sufficient information for clients to allocate objects of the opaque...

#### S3.2.9 - Circular Dependencies Prohibited

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.9.p31:c2a3dc04`
  Circular with dependencies among compilation units are prohibited. A conforming implementation shall...

#### S3.2.10 - Library Units

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.2.10.p32:be83c6b5`
  A library unit shall be a package. Library-level subprograms are not permitted as compilation units....

#### S3.3.1 - Dependency Interface Information

- **[IMP]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.3.1.p33:b08ead48`
  A conforming implementation shall make the following information available for each package, to supp...

- **[IMP]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.3.1.p34:2a0b2728`
  The mechanism for conveying this information is implementation-defined.

- **[LEG]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.3.1.p35:0bbb4bb7`
  If required dependency interface information is unavailable for a with'd package, the program shall ...

#### S3.3.4 - Child Packages

- **[STA]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.3.4.p40:cdfbcb6b`
  A child package does not have additional visibility into the non-public declarations of its parent b...

#### S3.4.1 - Package Initialisation

- **[DYN]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.4.1.p42:b88e8ad4`
  Package-level variable initialisers are evaluated at load time in declaration order (top to bottom).

#### S3.4.2 - Cross-Package Initialisation Order

- **[DYN]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.4.2.p44:a655dde4`
  If package A withs package B, then B's initialisers complete before A's initialisers begin.

- **[DYN]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.4.2.p45:80712e1a`
  The initialisation order across all compilation units is a topological sort of the with dependency g...

#### S3.4.3 - Task Startup Sequencing

- **[DYN]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.4.3.p46:b5f92bd9`
  All package-level initialisation across all compilation units completes before any task begins execu...

#### S3.5.1 - Dependency Interface Mechanism

- **[IMP]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.5.1.p47:b7e93197`
  A conforming implementation shall provide a mechanism for conveying dependency interface information...

- **[IMP]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.5.1.p48:616dd05d`
  The mechanism shall be sufficient to support: legality checking of client code against provider inte...

#### S3.5.2 - Separate Compilation

- **[IMP]** `SAFE@4aecf21:spec/03-single-file-packages.md#3.5.2.p49:02b25de0`
  A conforming implementation shall support separate compilation of packages. Each package shall be co...


### spec/04-tasks-and-channels.md

**48 clauses**

#### S4.1 - Task Declarations

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p2:78f022f7`
  A task declaration shall appear only at the top level of a package. A conforming implementation shal...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p3:542e0dee`
  Each task declaration creates exactly one task. There are no task types, no dynamic task creation, n...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p4:016e5737`
  The defining_identifier after end shall match the defining_identifier after task. A conforming imple...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p5:4e4afebc`
  If a Priority aspect is specified, the static expression shall evaluate to a value in the range Syst...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p6:be85291b`
  A task declaration shall not bear the public keyword.

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p7:393c53c2`
  Task declarations shall not be nested. A task body shall not contain another task declaration. A con...

- **[IMP]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p9:b4640bda`
  If no Priority is specified, the task has the default priority defined by the implementation. The de...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p10:92a67777`
  Each task declaration creates a single task that begins execution after all package-level initialisa...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.1.p11:2460c5cb`
  The task executes its handled_sequence_of_statements as an independent thread of control. Scheduling...

#### S4.2 - Channel Declarations

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.2.p13:4f888b03`
  A channel declaration shall appear only at the top level of a package. A conforming implementation s...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.2.p14:a35bd0fa`
  The element type shall be a definite type. A conforming implementation shall reject a channel whose ...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.2.p15:b5b29b0e`
  The capacity shall evaluate to a positive integer. A conforming implementation shall reject a channe...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.2.p20:8aa1a21e`
  A channel is a FIFO queue: elements are dequeued in the order they were enqueued.

- **[IMP]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.2.p21:c6a92460`
  When the implementation maps channels to underlying synchronisation mechanisms, it shall assign a ce...

- **[IMP]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.2.p21a:16ec46cb`
  A conforming implementation shall compute each channel's ceiling priority from the priorities of all...

#### S4.3 - Channel Operations

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p23:197d9a49`
  The expression in a send or try_send shall be of the channel's element type or a subtype thereof.

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p24:9e47ed4c`
  The name in a receive or try_receive shall denote a variable of the channel's element type or a subt...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p25:961abe5a`
  The final name in try_send and try_receive shall denote a variable of type Boolean.

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p26:3a9449c1`
  Channel operations shall not appear at the package level.

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p27:ef0ce6bd`
  send Ch, Value: Enqueue Value into channel Ch. If Ch is full, the current task blocks until space be...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p27a:8ed3c1d4`
  If the element type is an owning access type, send performs a move: the source object becomes null a...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p28:ea6bd13c`
  receive Ch, Variable: Dequeue the front element of channel Ch into Variable. If Ch is empty, the cur...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p28a:4cb19779`
  If the element type is an owning access type, receive performs a move from the channel into Variable...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p29:f792d704`
  try_send Ch, Value, Success: Attempt to enqueue Value into channel Ch without blocking. The operatio...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p29a:8d3f2225`
  If the element type is an owning access type, the move of Value occurs only when the enqueue succeed...

- **[IMP]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p29b:7121ccd7`
  For owning access types, the implementation shall not null the source variable until the enqueue is ...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p30:62619161`
  try_receive Ch, Variable, Success: Attempt to dequeue the front element of channel Ch without blocki...

- **[IMP]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p31:a7297e97`
  Channel operations are atomic with respect to other channel operations on the same channel. The impl...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.3.p31a:a621d08c`
  At any point during program execution, each designated object reachable through an owning access val...

#### S4.4 - Select Statement

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p33:7a94ab51`
  A select statement shall contain at least one channel_arm.

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p34:f0f83b83`
  At most one delay_arm may appear in a select statement. A conforming implementation shall reject a s...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p35:2ad6e64f`
  Only receive operations appear in select arms, not send. A conforming implementation shall reject an...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p36:0bffbd47`
  The subtype_mark in a channel_arm shall match the element type of the named channel.

- **[STA]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p37:6ced8129`
  The defining_identifier in a channel_arm introduces a new variable, scoped to the statements of that...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p38:35ed84d9`
  The expression in a delay_arm shall be of type Duration or a type convertible to Duration.

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p39:1012f4db`
  When the select statement is evaluated, the implementation tests each arm in declaration order. The ...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p40:4cfdeffe`
  If the delay expires before any channel arm becomes ready, the delay arm is selected.

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p41:cdf6a558`
  If multiple channels become ready simultaneously, the first listed channel arm is selected. This is ...

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p42:dce8ac38`
  If no channel arm is ready and no delay arm is present, the select blocks until one channel arm beco...

#### S4.5 - Task-Variable Ownership

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.5.p45:8bdd0c99`
  Each package-level variable shall be accessed by at most one task. The implementation shall verify t...

- **[IMP]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.5.p47:bc08fb3b`
  For subprograms in with'd packages, the implementation shall use the effect summaries from dependenc...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.5.p49:d2001725`
  A subprogram shall not access any package-level variable if it is callable from more than one task. ...

- **[STA]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.5.p50:2882310a`
  Channel operations do not constitute access to a package-level variable for the purposes of the task...

#### S4.6 - Non-Termination Legality Rule

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.6.p53:897d5577`
  Tasks shall not terminate. The outermost statement of the task body shall be an unconditional loop s...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.6.p53b:19b7c4ae`
  A return statement shall not appear anywhere within a task body. A conforming implementation shall r...

- **[LEG]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.6.p53c:77a5f52c`
  No exit statement within the task body shall name or otherwise target the outermost loop.

#### S4.7 - Task Startup

- **[DYN]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.7.p56:55e4230e`
  All package-level declarations and initialisations across all compilation units complete before any ...

- **[IMP]** `SAFE@4aecf21:spec/04-tasks-and-channels.md#4.7.p58:d10f9cd1`
  The order in which tasks are activated relative to each other is implementation-defined.


### spec/05-assurance.md

**19 clauses**

#### S5.1 - Overview of Assurance Levels

- **[CON]** `SAFE@4aecf21:spec/05-assurance.md#5.1.p2:14a5a600`
  Every conforming Safe program achieves Stone, Bronze, and Silver without developer-supplied annotati...

#### S5.2.1 - Normative Statement (Bronze)

- **[CON]** `SAFE@4aecf21:spec/05-assurance.md#5.2.1.p3:ce5a8fe7`
  Every conforming Safe program shall have complete and correct flow information derivable from its so...

#### S5.2.2 - Global Information

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.2.2.p5:a07e15ef`
  For each subprogram, a conforming implementation shall be able to determine the set of package-level...

#### S5.2.3 - Depends Information

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.2.3.p8:dfb93f2c`
  For each subprogram, a conforming implementation shall be able to determine which outputs depend on ...

#### S5.2.4 - Initializes Information

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.2.4.p11:b89bd341`
  For each package, a conforming implementation shall be able to determine which package-level variabl...

#### S5.3.1 - Normative Statement (Silver)

- **[CON]** `SAFE@4aecf21:spec/05-assurance.md#5.3.1.p12:99a94209`
  Every conforming Safe program shall be free of runtime errors. Every runtime check that the implemen...

- **[CON]** `SAFE@4aecf21:spec/05-assurance.md#5.3.1.p12a:047a8410`
  The Silver guarantee covers the runtime checks enumerable from the program text and the language sem...

#### S5.3.2 - Wide Intermediate Arithmetic

- **[LEG]** `SAFE@4aecf21:spec/05-assurance.md#5.3.2.p15:1ab3314c`
  A conforming implementation shall reject any program where the static range of a declared integer ty...

- **[LEG]** `SAFE@4aecf21:spec/05-assurance.md#5.3.2.p16:2e323902`
  A conforming implementation shall reject any integer expression where it cannot establish that all i...

#### S5.3.6 - Range Checks at Narrowing Points

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.3.6.p25:e8253bd7`
  The implementation shall discharge range checks via sound static range analysis.

- **[LEG]** `SAFE@4aecf21:spec/05-assurance.md#5.3.6.p26:9ca2c786`
  If a conforming implementation cannot establish that a narrowing point is safe, the program is nonco...

#### S5.3.7 - Discriminant Checks

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.3.7.p27:e63b291b`
  The implementation shall verify that access to a variant component is consistent with the current di...

#### S5.3.7a - Floating-Point Non-Trapping Semantics

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.3.7a.p28a:5936dbea`
  A conforming implementation shall ensure that all predefined floating-point types use IEEE 754 defau...

#### S5.3.9 - Hard Rejection Rule

- **[CON]** `SAFE@4aecf21:spec/05-assurance.md#5.3.9.p30:c7a2cbdb`
  If a conforming implementation cannot establish that a required runtime check will not fail, the pro...

- **[CON]** `SAFE@4aecf21:spec/05-assurance.md#5.3.9.p31:f6ea7939`
  There is no 'developer must restructure' advisory - failure to satisfy any Silver-level proof obliga...

#### S5.4.1 - Data Race Freedom

- **[CON]** `SAFE@4aecf21:spec/05-assurance.md#5.4.1.p32:90d4f527`
  The channel-based tasking model guarantees data race freedom as a language property.

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.4.1.p33:0fc25399`
  The implementation shall verify data race freedom through task-variable ownership analysis: each pac...

#### S5.4.2 - Priority Inversion Avoidance

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.4.2.p34:198b1ddf`
  When mapping channels to underlying synchronisation mechanisms, the implementation shall use ceiling...

#### S5.4.4 - Task-Variable Ownership

- **[IMP]** `SAFE@4aecf21:spec/05-assurance.md#5.4.4.p40:36087a2c`
  Effect summaries on task bodies shall reference only owned variables and channel operations.


### spec/06-conformance.md

**19 clauses**

#### S6.1 - Conforming Implementation

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p1a:ba2c1d31`
  A conforming implementation shall accept every conforming program and produce an executable represen...

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p1b:3890c549`
  A conforming implementation shall reject every non-conforming program with a diagnostic that identif...

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p1c:1f8fe478`
  A conforming implementation shall implement the dynamic semantics of 8652:2023 correctly for all con...

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p1d:19219997`
  A conforming implementation shall enforce all legality rules defined in this specification, includin...

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p1e:d0e6c93b`
  A conforming implementation shall enforce the task-variable ownership rule as a legality rule.

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p1f:2410637e`
  A conforming implementation shall derive flow analysis information without requiring user-supplied a...

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p1g:80745a1e`
  A conforming implementation shall provide a mechanism for separate compilation of units and combinat...

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.1.p2:983b5f84`
  A conforming implementation may provide additional capabilities beyond those required by this specif...

#### S6.2 - Conforming Program

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.2.p4:3e238301`
  A program for which a conforming implementation cannot establish that all required runtime checks ar...

#### S6.4 - Soundness

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.4.p11:f35e2134`
  All static analyses performed by a conforming implementation to enforce the D27 rules shall be sound...

- **[CON]** `SAFE@4aecf21:spec/06-conformance.md#6.4.p11b:6e973d1d`
  If a conforming implementation cannot establish that a runtime check is dischargeable, it shall reje...

#### S6.5.1 - Separate Compilation

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.5.1.p16:b89b7765`
  A conforming implementation shall support separate compilation of Safe packages. Each package shall ...

#### S6.5.2 - Dependency Interface

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.5.2.p17:70300f7a`
  A conforming implementation shall provide a mechanism for conveying dependency interface information...

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.5.2.p18:ae5640ac`
  The dependency interface shall include at minimum: public declarations and their types, subprogram s...

#### S6.5.3 - Linking

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.5.3.p19:5d4dfb69`
  A conforming implementation shall provide a mechanism for combining separately compiled units into a...

#### S6.6 - Diagnostics

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.6.p20a:d74e6ca7`
  When a conforming implementation rejects a non-conforming program, the diagnostic shall identify the...

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.6.p20b:74ad00a2`
  The diagnostic shall identify which rule is violated.

#### S6.7 - Implementation-Defined Behaviour

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.7.p22:03afd0a4`
  A conforming implementation shall document its choices for each implementation-defined behaviour.

#### S6.8 - Runtime Requirements

- **[IMP]** `SAFE@4aecf21:spec/06-conformance.md#6.8.p23:3419a843`
  A conforming implementation shall provide a runtime system sufficient to support: task creation and ...


### spec/07-annex-a-retained-library.md

**2 clauses**

#### SA.1 - The Package Standard

- **[STA]** `SAFE@4aecf21:spec/07-annex-a-retained-library.md#A.1.p3:70deff00`
  Exception declarations in Standard (Constraint_Error, Program_Error, Storage_Error, Tasking_Error) a...

#### SA.4.1 - Ada.Strings

- **[STA]** `SAFE@4aecf21:spec/07-annex-a-retained-library.md#A.4.1.p19:891ffa81`
  The package Ada.Strings is modified: exception declarations are excluded. Enumeration types and cons...


### spec/08-syntax-summary.md

**2 clauses**

#### S8.15 - Reserved Words

- **[LEG]** `SAFE@4aecf21:spec/08-syntax-summary.md#8.15.p1:75c5cfea`
  A conforming implementation shall reject any program that uses a reserved word as an identifier.

#### S8.16 - Grammar Summary

- **[CON]** `SAFE@4aecf21:spec/08-syntax-summary.md#8.16.p2:ccb1533b`
  Any construct that appears in 8652:2023 but does not appear in this grammar is excluded from Safe.

