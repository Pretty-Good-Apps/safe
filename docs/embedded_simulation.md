# Embedded Simulation

The repository now includes a local embedded smoke harness:

```bash
python3 scripts/run_embedded_smoke.py
```

This lane is intentionally separate from `scripts/run_tests.py`,
`scripts/run_samples.py`, and `scripts/run_proofs.py`. It is local tooling, not
blocking CI.

If you want to deploy an arbitrary single-file Safe program instead of running
the fixed smoke corpus, see [`embedded_deploy.md`](embedded_deploy.md).

## Current Scope

- Linux host only
- Renode only
- local/manual execution only
- current emitted `pragma Profile (Jorvik)` must work unchanged
- built-in STM32F4 runtime only:
  - `light-tasking-stm32f4`
- target board model is STM32F4 Discovery / STM32F407-class
- pass/fail is based on an exported RAM status word, not on `print` output

## Prerequisites

The harness expects these tools on `PATH`:

- `alr`
- `gprbuild`
- `renode`
- `arm-elf-gnatls` or `arm-eabi-gnatls`

The first matching ARM triplet is used for the whole run:

- `arm-elf`
- `arm-eabi`

The selected toolchain must also provide the built-in Ada runtime:

- `light-tasking-stm32f4`

The harness checks that runtime with `<triplet>-gnatls --RTS=light-tasking-stm32f4 -v`
before it starts the Jorvik probe or any real case.

## Usage

List the available cases:

```bash
python3 scripts/run_embedded_smoke.py --list-cases
```

Run the STM32F4 target:

```bash
python3 scripts/run_embedded_smoke.py --target stm32f4
```

Run the STM32F4 target and one case:

```bash
python3 scripts/run_embedded_smoke.py --target stm32f4 --case binary_shift_result
```

Keep generated build and simulator artifacts:

```bash
python3 scripts/run_embedded_smoke.py --target stm32f4 --keep-temp
```

## Current Corpus

The harness uses the dedicated `tests/embedded/` corpus instead of the
print-heavy Rosetta samples:

- `entry_integer_result.safe`
- `package_integer_result.safe`
- `binary_shift_result.safe`
- `scoped_receive_result.safe`
- `producer_consumer_result.safe`
- `delay_scope_result.safe`

Before running the corpus for a target, the harness also builds and runs a tiny
generated Jorvik startup probe under Renode. That probe proves both:

- the selected built-in `light-tasking-stm32f4` runtime accepts the emitted `gnat.adc`
- the runtime's startup/elaboration path completes under Renode

## How Verdicts Work

Each case is emitted to Ada and rebuilt with a generated embedded driver. That
driver exports a stable symbol named `safe_embedded_status`:

- `0` = still running
- `1` = pass
- `2` = fail

The harness launches Renode headlessly and polls the exported status word
through the Renode monitor with `sysbus ReadDoubleWord`. It does not rely on
`Ada.Text_IO`, semihosting, or UART capture.

## Limits

- No timing or cycle-accuracy claims
- No peripheral validation beyond runtime startup/elaboration
- No CI workflow yet
- No GNATemulator backend in this first lane
- No `print`-based embedded assertions
- No F0/G0 crate-based runtime path anymore; the harness is currently F4-only
