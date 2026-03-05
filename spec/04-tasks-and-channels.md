# Section 4 — Tasks and Channels

**This section is normative.**

This section specifies Safe's concurrency model. Safe provides concurrency through static tasks and typed channels as first-class language constructs. Tasks are declared at package level and create exactly one task each. Channels are typed, bounded-capacity, blocking FIFO queues. Tasks communicate exclusively through channels — no shared mutable state between tasks.

---

## 4.1 Task Declarations

### Syntax

1. A task is declared at the top level of a package:

```
task_declaration ::=
    'task' defining_identifier
        [ 'with' 'Priority' '=' static_expression ] 'is'
    [ declarative_part ]
    'begin'
        handled_sequence_of_statements
    'end' defining_identifier ';'
```

### Legality Rules

2. A task declaration shall appear only at the top level of a package (as a `package_item`). A conforming implementation shall reject any task declaration appearing within a subprogram body, block statement, or nested scope.

3. Each task declaration creates exactly one task. There are no task types, no dynamic task creation, no task arrays.

4. The `defining_identifier` after `end` shall match the `defining_identifier` after `task`. A conforming implementation shall reject any task where the end identifier does not match.

5. If a `Priority` aspect is specified, the static expression shall evaluate to a value in the range `System.Any_Priority`. A conforming implementation shall reject a priority value outside this range.

6. A task declaration shall not bear the `public` keyword. Tasks are execution entities internal to the package.

7. Task declarations shall not be nested. A task body shall not contain another task declaration. A conforming implementation shall reject any task declaration appearing within a task body.

### Static Semantics

8. The `defining_identifier` of a task declaration introduces a name in the enclosing package's declarative region. This name is not a type name and cannot be used as a type mark.

9. If no `Priority` is specified, the task has the default priority defined by the implementation. The default priority shall be documented by the implementation.

### Dynamic Semantics

10. Each task declaration creates a single task that begins execution after all package-level initialisation completes (see §4.7).

11. The task executes its `handled_sequence_of_statements` as an independent thread of control. Scheduling among tasks is preemptive priority-based. Tasks of equal priority are scheduled in implementation-defined order.

---

## 4.2 Channel Declarations

### Syntax

12. A channel is a typed, bounded FIFO queue declared at the top level of a package:

```
channel_declaration ::=
    [ 'public' ] 'channel' defining_identifier ':' subtype_mark
        'capacity' static_expression ';'
```

### Legality Rules

13. A channel declaration shall appear only at the top level of a package. A conforming implementation shall reject any channel declaration appearing within a subprogram body, task body, or nested scope.

14. The element type (`subtype_mark`) shall be a definite type (not an unconstrained array or unconstrained discriminated type). A conforming implementation shall reject a channel whose element type is indefinite.

15. The capacity (`static_expression`) shall evaluate to a positive integer. A conforming implementation shall reject a channel with a capacity less than 1.

16. A channel may bear the `public` keyword to make it visible to client packages for cross-package communication.

### Static Semantics

17. A channel declaration introduces a name in the enclosing package's declarative region. This name denotes a channel object, not a type.

18. The storage required for a channel is bounded: element size multiplied by capacity, plus implementation-defined overhead for the queue structure. The allocation strategy (static, pre-allocated, or other) is implementation-defined.

### Dynamic Semantics

19. A channel is initially empty. Its lifetime is the lifetime of the enclosing package (i.e., the lifetime of the program, since packages are not deallocated).

20. A channel is a FIFO queue: elements are dequeued in the order they were enqueued.

21. **Ceiling priority.** When the implementation maps channels to underlying synchronisation mechanisms, it shall assign a ceiling priority to each channel. The ceiling priority of a channel shall be at least the maximum of the priorities of all tasks that access that channel (directly or transitively through subprogram calls). This is required to prevent priority inversion.

21a. **Ceiling computation across packages.** A conforming implementation shall compute each channel's ceiling priority from the priorities of all tasks that access the channel, using channel-access summaries from dependency interface information (Section 3, §3.3.1(i)) for cross-package calls. Specifically:

   (a) For each public subprogram in a provider package, the dependency interface information includes a conservative summary of which channels the subprogram accesses (directly or transitively).

   (b) When a task in a client package calls such a subprogram, the implementation adds the task's priority to the set of priorities considered for each channel listed in the summary.

   (c) The ceiling priority computation shall be completable from the compilation unit's source plus its direct and transitive dependency interface information, without access to dependency source code. This mirrors the requirement for task-variable ownership checking (Section 4, §4.5, paragraph 47).

   (d) A conservative over-approximation of channel access (listing channels that may not actually be accessed on every path) is permitted — it may raise ceilings above the necessary minimum but does not compromise priority inversion prevention.

---

## 4.3 Channel Operations

### Syntax

22.

```
send_statement ::=
    'send' channel_name ',' expression ';'

receive_statement ::=
    'receive' channel_name ',' name ';'

try_send_statement ::=
    'try_send' channel_name ',' expression ',' name ';'

try_receive_statement ::=
    'try_receive' channel_name ',' name ',' name ';'
```

### Legality Rules

23. The expression in a `send` or `try_send` shall be of the channel's element type or a subtype thereof.

24. The `name` in a `receive` or `try_receive` shall denote a variable of the channel's element type or a subtype thereof.

25. The final `name` in `try_send` and `try_receive` shall denote a variable of type `Boolean`.

26. Channel operations may appear in subprogram bodies, task bodies, and other statement contexts. They shall not appear at the package level (no package-level statements, §3.2.4).

### Dynamic Semantics

27. **`send Ch, Value;`** — Enqueue `Value` into channel `Ch`. If `Ch` is full (number of elements equals capacity), the current task blocks until space becomes available. The blocking is on the current task only, not the entire program. The expression `Value` is evaluated before the enqueue (and before blocking, if the channel is full). Once space becomes available, the evaluated value is enqueued.

27a. **Ownership transfer on `send`.** If the element type is an owning access type (pool-specific access-to-variable or a composite type containing such a component), `send` performs a **move**: the source object becomes `null` after the send completes. A conforming implementation shall reject any subsequent dereference of the source object unless it has been reassigned or verified as non-null. The move occurs at the point of the send statement — it is not deferred to the actual enqueue. Rationale: the sender must not access the designated object after committing to send it, even while blocked waiting for channel space.

28. **`receive Ch, Variable;`** — Dequeue the front element of channel `Ch` into `Variable`. If `Ch` is empty, the current task blocks until an element becomes available.

28a. **Ownership transfer on `receive`.** If the element type is an owning access type, `receive` performs a **move** from the channel into `Variable`. The receiving task becomes the owner of the designated object. No two tasks can simultaneously hold an owning access to the same designated object through channel transfer. The null-before-move legality rule (Section 2, §2.3.2, paragraph 97a) applies: `Variable` shall be provably null at the point of the `receive`.

29. **`try_send Ch, Value, Success;`** — Attempt to enqueue `Value` into channel `Ch` without blocking. The operation is performed atomically: the implementation acquires the channel, evaluates the channel's fullness, and if not full, enqueues `Value` and sets `Success` to `True`. If `Ch` is full, no element is enqueued and `Success` is set to `False`.

29a. **Move-only-on-success.** If the element type is an owning access type, the move of `Value` occurs only when the enqueue succeeds (`Success` is `True`). When `Success` is `False`, the source object retains its value — no move occurs and the source variable remains valid. The implementation shall ensure that the evaluation of `Value` and the fullness check are performed atomically with respect to the channel, so that the move decision is consistent with the actual enqueue outcome.

29b. **Evaluation order for `try_send`.** The expression `Value` is evaluated before the atomic fullness check. If the channel is not full, the already-evaluated value is enqueued and the move (if applicable) is committed. If the channel is full, the evaluated value is discarded (for non-owning types) or not moved (for owning types — the source retains its original value). For owning access types, the implementation shall not null the source variable until the enqueue is confirmed to succeed.

30. **`try_receive Ch, Variable, Success;`** — Attempt to dequeue the front element of channel `Ch` without blocking. If `Ch` is not empty, the element is dequeued into `Variable` and `Success` is set to `True`. If `Ch` is empty, `Variable` is unchanged and `Success` is set to `False`. Ownership transfer semantics for `receive` (paragraph 28a) apply when `Success` is `True`. For owning access types, the null-before-move legality rule (Section 2, §2.3.2, paragraph 97a) applies: `Variable` shall be provably null at the point of the `try_receive`. Since `try_receive` may or may not move a value into `Variable`, the implementation shall treat `Variable` as non-null after a `try_receive` regardless of the `Success` outcome, unless subsequent control flow re-establishes the null state.

31. Channel operations are atomic with respect to other channel operations on the same channel. The implementation shall ensure that concurrent `send` and `receive` operations on the same channel do not corrupt the channel state.

31a. **Channel ownership invariant.** At any point during program execution, each designated object reachable through an owning access value in a channel element is owned by exactly one entity: either the channel (if the element is queued) or the task that sent or received it. No designated object is simultaneously reachable from a task variable and a channel queue. This invariant is maintained by the move semantics of `send` and `receive`.

---

## 4.4 Select Statement

### Syntax

32.

```
select_statement ::=
    'select'
        select_arm
    { 'or' select_arm }
    'end' 'select' ';'

select_arm ::=
    channel_arm | delay_arm

channel_arm ::=
    'when' defining_identifier ':' subtype_mark 'from' channel_name 'then'
        sequence_of_statements

delay_arm ::=
    'delay' expression 'then'
        sequence_of_statements
```

### Legality Rules

33. A `select` statement shall contain at least one `channel_arm`.

34. At most one `delay_arm` may appear in a `select` statement. A conforming implementation shall reject a `select` with more than one `delay_arm`.

35. Only receive operations appear in `select` arms, not send. A conforming implementation shall reject any `select` arm that attempts a send operation.

36. The `subtype_mark` in a `channel_arm` shall match the element type of the named channel.

37. The `defining_identifier` in a `channel_arm` introduces a new variable, scoped to the statements of that arm.

38. The `expression` in a `delay_arm` shall be of type `Duration` or a type convertible to `Duration`.

### Dynamic Semantics

39. **Arm selection semantics.** When the `select` statement is evaluated, the implementation tests each arm in declaration order (top to bottom). The first arm whose channel has data available is selected. If no channel arm is ready and a delay arm is present, the implementation waits until either a channel arm becomes ready or the delay expires, whichever occurs first.

40. If the delay expires before any channel arm becomes ready, the delay arm is selected.

41. If multiple channels become ready simultaneously (e.g., data arrives on two channels between scheduling quanta), the first listed channel arm is selected. This is deterministic — arm ordering in source code determines priority. There is no random selection.

42. If no channel arm is ready and no delay arm is present, the `select` blocks until one channel arm becomes ready.

43. Once an arm is selected, its `sequence_of_statements` is executed. For a channel arm, the received value is bound to the `defining_identifier` before the statements execute. The ownership transfer semantics of `receive` (paragraph 28a) apply: if the element type is an owning access type, the receiving task becomes the owner.

44. **Starvation.** A channel whose arm is listed later in a `select` may be starved if earlier arms are always ready. This is by design — it gives the programmer explicit priority control via declaration order.

---

## 4.5 Task-Variable Ownership

### Legality Rules

45. **No shared mutable state between tasks.** Each package-level variable shall be accessed by at most one task. The implementation shall verify this at compile time. A conforming implementation shall reject any program where a package-level variable is accessed by more than one task.

46. **Access determination.** A task accesses a package-level variable if:

   (a) The variable appears directly in the task body.

   (b) The variable appears in a subprogram called (directly or transitively) from the task body.

47. **Cross-package transitivity.** For subprograms in `with`'d packages, the implementation shall use the effect summaries from dependency interface information (Section 3, §3.3.1(d)) to determine which package-level variables are accessed. The ownership check shall be completable from the compilation unit's source plus its direct and transitive dependency interface information, without access to dependency source code.

48. **Variables not accessed by any task** remain accessible to non-task subprograms (package-level initialisation expressions and subprograms not called from any task body).

49. **Subprograms callable from multiple tasks.** A subprogram shall not access any package-level variable if it is callable from more than one task. A conforming implementation shall reject any subprogram that accesses a package-level variable and is callable from multiple task bodies.

50. **Channels are not variables.** Channel operations do not constitute "access to a package-level variable" for the purposes of this ownership rule. Channels are the designated mechanism for inter-task communication.

### Static Semantics

51. The task-variable ownership analysis produces a mapping from each package-level variable to at most one task. This mapping is a static property of the program.

52. For mutually recursive subprograms, the implementation may use a fixed-point computation to determine the complete set of variables accessed.

---

## 4.6 Non-Termination Legality Rule

### Legality Rules

53. Tasks shall not terminate. A conforming implementation shall enforce the following constraints on every task body:

   (a) The outermost statement of the task body's `handled_sequence_of_statements` shall be an unconditional `loop` statement (`loop ... end loop;`). Declarations may precede the loop.

   (b) A `return` statement shall not appear anywhere within a task body. A conforming implementation shall reject any `return` statement within a task body.

   (c) No `exit` statement within the task body shall name or otherwise target the outermost loop. `exit` statements targeting inner loops within the task body are permitted.

54. These constraints are syntactic restrictions checkable without control-flow analysis or whole-program analysis.

55. Some theoretically non-terminating forms (e.g., `while True loop ... end loop;`) are not accepted. The unconditional `loop` form is trivially verifiable by any implementation.

---

## 4.7 Task Startup

### Dynamic Semantics

56. All package-level declarations and initialisations across all compilation units complete before any task begins executing. This is a language-level sequencing guarantee.

57. The order of package initialisation across compilation units is a topological sort of the `with` dependency graph (Section 3, §3.4.2).

58. Once all initialisation is complete, all tasks begin execution. The order in which tasks are activated relative to each other is implementation-defined.

59. **Informative note.** When targeting Ada/SPARK tasking under Ravenscar or Jorvik profile restrictions, `pragma Partition_Elaboration_Policy(Sequential)` is the standard mechanism for ensuring library-level task activation is deferred until all library units are elaborated. The normative requirement is the language-level guarantee stated in paragraph 56; the mechanism for achieving it is implementation-defined.

---

## 4.8 Examples

### 4.8.1 Example: Producer/Consumer

**Conforming Example.**

```ada
-- pipeline.safe

package Pipeline is

    public type Measurement is range 0 .. 65535;

    channel Raw_Data : Measurement capacity 16;
    channel Processed : Measurement capacity 8;

    task Producer with Priority = 10 is
    begin
        loop
            Sample : Measurement = Read_Sensor;
            send Raw_Data, Sample;
            delay 0.01;
        end loop;
    end Producer;

    task Consumer with Priority = 5 is
    begin
        loop
            M : Measurement;
            receive Raw_Data, M;
            Result : Measurement = Process(M);
            send Processed, Result;
            -- D27 proof: all types match; no runtime errors
        end loop;
    end Consumer;

    function Read_Sensor return Measurement is separate;

    function Process (M : Measurement) return Measurement is
    begin
        return (M + 1) / 2;
        -- D27 Rule 1: wide intermediate, max (65535+1)/2 = 32768
        -- D27 Rule 3(b): literal 2 is static nonzero
        -- D27 proof: result in 0..65535
    end Process;

    public function Get_Result return Measurement is
    begin
        R : Measurement;
        receive Processed, R;
        return R;
    end Get_Result;

end Pipeline;
```

### 4.8.2 Example: Router/Worker

**Conforming Example.**

```ada
-- router.safe

package Router is

    public type Job_Id is range 1 .. 1000;
    public type Job is record
        Id   : Job_Id;
        Data : Integer;
    end record;

    public type Result is record
        Id    : Job_Id;
        Value : Integer;
    end record;

    channel Jobs_A : Job capacity 4;
    channel Jobs_B : Job capacity 4;
    public channel Results : Result capacity 8;

    task Dispatcher with Priority = 8 is
        Count : Job_Id = 1;
    begin
        loop
            J : Job = (Id = Count, Data = Integer(Count) * 10);
            -- D27 proof: Count * 10 fits in Integer (wide intermediate)
            Ok : Boolean;
            try_send Jobs_A, J, Ok;
            if not Ok then
                send Jobs_B, J;
            end if;
            Count = (if Count == Job_Id.Last then Job_Id.First else Count + 1);
        end loop;
    end Dispatcher;

    task Worker_A with Priority = 5 is
    begin
        loop
            J : Job;
            receive Jobs_A, J;
            send Results, (Id = J.Id, Value = J.Data + 1);
            -- D27 proof: J.Data + 1 may overflow Integer; wide intermediate handles it
        end loop;
    end Worker_A;

    task Worker_B with Priority = 5 is
    begin
        loop
            J : Job;
            receive Jobs_B, J;
            send Results, (Id = J.Id, Value = J.Data + 2);
        end loop;
    end Worker_B;

end Router;
```

### 4.8.3 Example: Command/Response with Select

**Conforming Example.**

```ada
-- controller.safe

package Controller is

    public type Command is (Start, Stop, Reset);
    public type Status  is (Running, Stopped, Error);

    public channel Commands : Command capacity 4;
    public channel Responses : Status capacity 4;
    channel Heartbeats : Boolean capacity 1;

    Current_State : Status = Stopped;  -- owned by Control_Loop

    task Control_Loop with Priority = 10 is
    begin
        loop
            select
                when Cmd : Command from Commands then
                    case Cmd is
                        when Start then
                            Current_State = Running;
                            send Responses, Running;
                        when Stop then
                            Current_State = Stopped;
                            send Responses, Stopped;
                        when Reset then
                            Current_State = Stopped;
                            send Responses, Stopped;
                    end case;
                or delay 5.0 then
                    send Heartbeats, True;
            end select;
        end loop;
    end Control_Loop;

    public function Get_Status return Status
    is (Current_State);
    -- Note: this is callable only from the task that owns Current_State
    -- or from non-task context during initialisation.
    -- D27 proof: Status is an enumeration; no runtime error possible.

end Controller;
```

---

## 4.9 Relationship to 8652:2023

60. The following table summarises how Safe's concurrency model relates to 8652:2023 Section 9:

| 8652:2023 Feature | Safe Status |
|-------------------|-------------|
| Task types (§9.1) | Excluded — static task declarations instead |
| Task activation (§9.2) | Modified — all init completes first |
| Task dependence/termination (§9.3) | Modified — tasks shall not terminate |
| Protected types (§9.4) | Excluded as user-visible; may be used internally |
| Entries and accept (§9.5.2) | Excluded — channels instead |
| Entry calls (§9.5.3) | Excluded |
| Requeue (§9.5.4) | Excluded |
| Delay statements (§9.6) | Retained |
| Select statements (§9.7) | Replaced by Safe's channel-based select |
| Abort (§9.8) | Excluded |
| Task/entry attributes (§9.9) | Excluded |
| Shared variables (§9.10) | Superseded by task-variable ownership |
