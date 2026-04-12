# PR11.22h Shared Stdlib Contract Audit

This audit checked the shared Ada runtime packages under
`compiler_impl/stdlib/ada` for contract completeness and body drift.

## Packages Checked

- `Safe_Array_RT`
- `Safe_Array_Identity_RT`
- `Safe_Array_Identity_Ops`
- `Safe_String_RT`
- `Safe_Bounded_Strings`

## Findings

- `Safe_Array_RT` and `Safe_Array_Identity_RT` still share the same body shape
  for `From_Array`, `Clone`, `Copy`, `Free`, `Element`, `Replace_Element`,
  `Slice`, and `Concat`.
- `Safe_Array_Identity_RT` intentionally has stronger elementwise
  postconditions than `Safe_Array_RT` because its element operations preserve
  identity equality.
- `Safe_Array_RT` was missing length postconditions for `Slice` and `Concat`.
  These are representation-independent and follow directly from the body.
- `Safe_String_RT` was missing length postconditions for `Copy`, `Free`, and
  `Concat`, and an explicit semantic postcondition for `Equal`.
- `Safe_Bounded_Strings` exposed public functions without explicit `Global` and
  `Depends` aspects, even though the private expression-function completions
  are pure and depend only on their inputs.

## Deliberate Non-Changes

- No elementwise equality postconditions were added to `Safe_Array_RT`.
  `Clone_Element` is an unconstrained generic operation, so the runtime cannot
  claim that cloning preserves equality for all instantiations.
- `Safe_Array_Identity_RT` kept its existing elementwise postconditions rather
  than being weakened to match `Safe_Array_RT`.
- Runtime bodies were not refactored. The audit tightened contracts only where
  the existing behavior already supported the claim.
