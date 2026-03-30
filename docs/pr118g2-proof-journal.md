# PR11.8g.2 Proof Journal

## 2026-03-30

### Current branch state

- Branch: `codex/pr118g2-shared-runtime-io-seam`
- Draft PR: `#160`
- Green locally:
  - `alr build`
  - `python3 scripts/run_tests.py` -> `428 passed, 0 failed`
  - `python3 scripts/run_samples.py` -> `18 passed, 0 failed`
- Remaining blocker: full `python3 scripts/run_proofs.py`

### Reproduced proof blocker

- Fixture: `tests/build/pr118d_bounded_string_build.safe`
- Reproduced locally with:
  - single fixture
  - single prover: `z3`
  - single-threaded GNATprove settings
  - both pinned and unpinned CPU runs
- Result: same bad VC shape both ways
  - `pr118d_bounded_string_build-T-defqtvc.smt2`
- Conclusion: this is not primarily scheduler noise or proof-process parallel non-determinism.

### Narrowing results

- `gnatprove --limit-subp=safe_bounded_strings.adb:33` completes quickly.
  - Interpretation: the shared bounded-string `Slice` helper body itself is not the direct blocker.
- `gnatprove --limit-line=pr118d_bounded_string_build.ads:16` hangs in the same proof phase.
  - Line 16 is:
    - `prefix : Safe_Bounded_String_5_Type := Safe_Bounded_String_5.To_Bounded (Safe_Bounded_String_5.Slice (name, 1, 2));`

### Current working hypothesis

- The problematic proof surface is the composition:
  - bounded-target initialization through `To_Bounded (Slice (...))`
- The next implementation step is to avoid that composition when the source is already a bounded string of the same capacity, by emitting a direct bounded-string slice helper instead of routing through an intermediate `String`.

### Fresh narrowing after `Slice_Bounded`

- Emitted `pr118d_bounded_string_build.ads` now uses:
  - `prefix : Safe_Bounded_String_5_Type := Safe_Bounded_String_5.Slice_Bounded (name, 1, 2);`
- `gnatprove --limit-line=pr118d_bounded_string_build.adb:11` now completes and proves.
  - Interpretation: the package-body string comparisons are not the current blocker.
- `gnatprove --limit-line=pr118d_bounded_string_build.ads:16` no longer hangs; it fails with one concrete unproved contract check:
  - `precondition might fail, cannot prove High <= Length (Value)`
  - on `Safe_Bounded_String_5.Slice_Bounded (name, 1, 2)`
- Interpretation:
  - the fresh blocker is a missing visible fact about `To_Bounded`, not the `Slice_Bounded` body itself
  - GNATprove does not know that:
    - `Length (Safe_Bounded_String_5.To_Bounded ("hello")) = 5`

### Current contract fix under test

- Strengthen the shared bounded-string spec with the minimum length facts needed by callers:
  - `To_Bounded` postcondition states result length matches source string length
  - `To_String` postcondition states result string length matches bounded-string length
  - `Element` postcondition states the returned string has length `1`
- Rationale:
  - fixes the concrete `Slice_Bounded` precondition failure on package elaboration
  - should also help the `for ... of string` path, which constructs `string (1)` loop items from bounded-string indexing

### Results after contract patch

- `gnatprove --limit-line=pr118d_bounded_string_build.ads:16` now proves.
  - The earlier `High <= Length (Value)` failure is gone.
- `gnatprove --limit-line=pr118d1_for_of_string_build.adb:39` proves.
  - `Safe_Bounded_String_1.To_Bounded (Safe_For_Of_Snapshot_2 (...))` is now accepted with the shared spec surface.
- `gnatprove --limit-line=pr118d1_for_of_string_build.adb:34` proves.
  - The bounded-string `To_String (short)` snapshot itself is not the current blocker.

### Updated working hypothesis

- The bounded-string seam problem was primarily missing visible length facts in the shared `Safe_Bounded_Strings` spec, not a bad body implementation.
- Next step:
  - rerun the full emitted fixtures for:
    - `pr118d_bounded_string_build.safe`
    - `pr118d_bounded_string_field_build.safe`
    - `pr118d_bounded_string_index_build.safe`
    - `pr118d1_for_of_string_build.safe`
  - if those stay green, widen back out to the full `PR11.8g.2` checkpoint and then full `run_proofs.py`

### Full-fixture follow-up

- In isolated full-fixture `prove` runs, the hot VC moved from the old package-spec initializer to the shared helper proof surface.
- `--limit-subp=safe_bounded_strings.adb:5` (`To_Bounded`) proves quickly.
- `--limit-subp=safe_bounded_strings.adb:15` (`To_String`) also proves quickly in isolation.
- But the full emitted `pr118d_bounded_string_build` package still spends its time in `Safe_Bounded_String_*.__to_string` when proving the whole unit at once.
- Current experiment:
  - keep the `To_Bounded` and `Element` visible length facts
  - drop the `To_String` length postcondition, since the narrowed `for ... of string` checks do not appear to need it and it is the current highest-probability source of the remaining proof blow-up

### Result after dropping `To_String` post

- `gnatprove --limit-line=pr118d1_for_of_string_build.adb:34` still proves without the `To_String` length postcondition.
- Conclusion:
  - the bounded-string snapshot path does not currently need a visible `To_String` length fact
  - keeping `To_Bounded` and `Element` contracts while dropping `To_String` is the better cost/benefit point so far

### Current structural simplification

- Moved these tiny bounded-string helpers from package-body implementations to private-part expression-function completions:
  - `Length`
  - `To_String`
  - `Element`
  - `Slice`
- Rationale:
  - the remaining full-fixture cost was cycling across instantiated helper bodies even though each helper proved quickly in isolation
  - expression-function completion should let GNATprove inline these helpers instead of re-proving multiple nearly identical instantiated bodies
- `To_Bounded` and `Slice_Bounded` stay as ordinary body-defined functions for now.

### Result after helper inlining

- Full direct `z3` prove of emitted `pr118d_bounded_string_build` now completes successfully.
- The previous aggregate-cost blow-up across instantiated helper bodies is gone.
- Current status after this change:
  - package-spec initializer proof is green
  - bounded-string helper bodies still prove
  - full emitted bounded-string fixture proves end-to-end under direct `gnatprove`

### Bounded-string subset reclosed

- Emitted-fixture batch with `z3` only is now green for:
  - `pr118d_bounded_string_build.safe`
  - `pr118d_bounded_string_field_build.safe`
  - `pr118d_bounded_string_index_build.safe`
  - `pr118d1_for_of_string_build.safe`
- The same four fixtures are also green under the normal `cvc5,z3,altergo` prove switches.
- Conclusion:
  - the bounded-string shared-runtime proof regression is locally reclosed
  - this seam is no longer the frontmost `PR11.8g.2` blocker

### New front of the queue

- The next targeted `PR11.8g.2` batch stalled immediately on:
  - `tests/build/pr118d_fixed_to_growable_build.safe`
- It did not reach the heap-backed channel fixtures before being stopped.
- So after the bounded-string fix, the next proof investigation should shift to the `fixed_to_growable` path before widening again to the full checkpoint.

### `pr118d_fixed_to_growable_build.safe` reclosed

- Shared-array runtime changes that closed the fixture:
  - `Safe_Array_RT.From_Array` now exposes both:
    - result length
    - per-element preservation
  - `Safe_Array_RT.Clone` now exposes result-length preservation
  - `Safe_Array_RT.Copy` now exposes target-length preservation
  - `Safe_Array_RT.Free` now exposes zero length after cleanup
- Emitter change that mattered:
  - access-parameter length preconditions are now synthesized for parameter-root indexed/sliced growable arrays, strings, and bounded strings
- Result:
  - `tests/build/pr118d_fixed_to_growable_build.safe` proves in isolation under both:
    - `z3`
    - the normal `cvc5,z3,altergo` mix
- Cleanup folded into the same step:
  - removed the dead tautological runtime drift check from `scripts/_lib/pr09_emit.py`

### `pr118g_growable_channel_build.safe` investigation

- First heap-backed channel blocker after `fixed_to_growable`:
  - `tests/build/pr118g_growable_channel_build.safe`

- Preserved probe directories:
  - `/tmp/pr118g_grow_prove4_eJ7Pki/fixture/ada`
  - `/tmp/pr118g_grow_prove5_aVg6ij/fixture/ada`
  - `/tmp/pr118g_grow_prove6_Bmf1ki/fixture/ada`
  - `/tmp/pr118g_grow_check5_ben_k6mw/fixture/ada`
  - `/tmp/pr118g_grow_check10_mj65dfkp/fixture/ada`

#### Dead end: package-level ghost wrapper model

- Attempt:
  - add package ghost `*_Model_Length`
  - route single-slot direct growable/string channels through staged send/receive wrappers
  - carry send length through wrapper postconditions
- Result:
  - first version failed flow because:
    - the ghost state was missing from `Initializes`
    - GNATprove emitted `is set by` warnings on the receive wrapper call
  - after patching those, flow went green
  - prove still failed inside the wrapper contracts:
    - could not prove `Value_Length = *_Model_Length`
    - could not prove `Length (Value) = Value_Length`
- Conclusion:
  - the wrapper ghost model moved the problem but did not close it

#### Dead end: direct receive plus recomputed actual length

- Attempt:
  - remove the receive/send wrappers again
  - call protected `Send` / `Receive` / `Try_*` directly
  - recompute the staged value length after receive outside the protected body
- Result:
  - flow became clean after a narrow generated `is set by` suppression around the direct receive call
  - prove improved:
    - staged-length and target-length assertions both proved
    - the final `values_RT.Element (received, 1)` precondition was still unproved
- Interpretation:
  - recomputing actual length outside the protected body is useful and should likely be kept
  - but it does not by itself carry the send-side non-empty fact across the channel

#### Dead end: `Stored_Length` over `Count` and `Lengths`

- Attempt:
  - add a single-slot protected `Stored_Length` helper
  - add postconditions on protected `Send` / `Receive` using that helper
- Result:
  - compiled and flowed cleanly
  - prove still failed on the `Send` / `Receive` postconditions
  - GNATprove explicitly suggested either:
    - a postcondition on `Stored_Length`
    - or turning it into an expression function
- Follow-up attempt:
  - tried to complete `Stored_Length` as an expression function in the protected type private part
- Result:
  - Ada rejected that shape because protected components cannot be referenced there before the end of the declaration
- Conclusion:
  - the bounded-string-style expression-function trick does not transfer directly to protected components

#### Current in-tree attempt

- Current shape:
  - keep the direct protected call path
  - recompute actual received length outside the protected body
  - add a dedicated single-slot scalar `Stored_Length_Value`
  - `Stored_Length` now returns that scalar, not `Lengths (Head)`
  - protected `Send` / `Receive` still carry numeric postconditions via `Stored_Length`
- Current result:
  - flow is green for `tests/build/pr118g_growable_channel_build.safe`
  - prove still fails in the same three places:
    - final `values_RT.Element (received, 1)` precondition
    - `Send` postcondition `Stored_Length = Value_Length`
    - `Receive` postcondition `Value_Length = Stored_Length'Old`

### Current conclusion

- The first heap-backed channel blocker is narrower now, but it is not closed.
- The real unsolved issue is:
  - making the single-slot numeric send-to-receive length fact proof-visible enough for GNATprove to use it modularly
- The next step should avoid more wrapper churn unless it directly addresses that modular numeric fact.
