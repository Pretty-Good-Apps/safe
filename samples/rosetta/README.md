# PR11.x Rosetta Corpus

This directory started as the PR11.1 language-evaluation corpus and now carries
the PR11.2 text/control-flow additions plus the first PR11.3 structured-return
examples.

The milestone boundary is compile-only:

- `safec check`
- `safec emit --ada-out-dir`
- `gprbuild -c`

PR11.1, PR11.2, and PR11.3 do not treat this corpus as a proof-bearing
milestone. Proof coverage re-enters later through `PR11.3a`, `PR11.8a`, and
`PR11.8b`.

## Status of Current Candidates

Starter corpus:

- `arithmetic/fibonacci.safe`
- `arithmetic/gcd.safe`
- `arithmetic/factorial.safe`
- `arithmetic/collatz_bounded.safe`
- `sorting/bubble_sort.safe`
- `sorting/binary_search.safe`
- `data_structures/bounded_stack.safe`
- `concurrency/producer_consumer.safe`

Candidate expansion:

- `linked_list_reverse.safe`
- `prime_sieve_pipeline.safe`

Deferred:

- `trapezoidal_rule.safe`
- `newton_sqrt_bounded.safe`

PR11.2 text/control-flow additions:

- `text/grade_message.safe`
- `text/opcode_dispatch.safe`

PR11.3 structured-return additions:

- `data_structures/parse_result.safe`
- `text/lookup_pair.safe`
- `text/lookup_result.safe`

## Running the Corpus Gate

Use:

```bash
python3 scripts/run_rosetta_corpus.py
```

That gate validates the eight starter programs through the PR11.1 compile-only
chain. The separate `safe build` smoke in `scripts/run_pr111_language_evaluation_harness.py`
covers executable production on one sequential and one concurrency starter.

For the PR11.2 text/control-flow slice, use:

```bash
python3 scripts/run_pr112_parser_completeness_phase1.py
```

That gate keeps the new string/character literal and strict `case` samples in
the same `safec check` -> `safec emit --ada-out-dir` -> `gprbuild -c` compile-only chain.

For the PR11.3 discriminant/tuple/result slice, use:

```bash
python3 scripts/run_pr113_discriminated_types_tuples_structured_returns.py
```

That gate keeps the new discriminant constraints, tuples, tuple channels,
destructuring, and builtin `result` samples in the same compile-only chain.
