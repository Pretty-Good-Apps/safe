# Embedded Deploy

The repo-local wrapper now includes a first embedded deploy command for the
STM32F4 Discovery board:

```bash
python3 scripts/safe_cli.py deploy --board stm32f4-discovery --simulate myfile.safe
python3 scripts/safe_cli.py deploy --board stm32f4-discovery myfile.safe
```

For simulator-only observability, the wrapper can also watch a scalar ELF symbol
after startup completes:

```bash
python3 scripts/safe_cli.py deploy \
  --board stm32f4-discovery \
  --simulate \
  --watch-symbol entry_integer_result__result \
  --expect-value 42 \
  tests/embedded/entry_integer_result.safe
```

`--simulate` runs the image under Renode. Omitting `--simulate` uses OpenOCD
plus ST-LINK to flash a physically attached board.

## Scope

- single-file roots only
- the root file must not begin with `with`
- supported board in this milestone: `stm32f4-discovery`
- optional `--target stm32f4` is accepted, but the board already implies it

If the root begins with `with`, the wrapper rejects it and points you to
`safec emit` plus manual `gprbuild` for the current multi-file flow.

## Success Contract

This first deploy milestone checks **startup**, not application-specific output.
The wrapper emits a small embedded driver that exports a status word in SRAM:

- `0` = program has not reached the driver body yet
- `1` = elaboration completed and startup succeeded

On success the wrapper prints:

```text
safe deploy: OK (simulated on stm32f4-discovery; <elf-path>)
```

or:

```text
safe deploy: OK (flashed stm32f4-discovery; <elf-path>)
```

When `--watch-symbol` and `--expect-value` are present, simulator deploy keeps
using the same startup-status word, but only reports success once startup has
completed **and** the watched symbol reaches the expected value.

## Artifact Layout

Deploy artifacts are written under:

```text
obj/<stem>/deploy/stm32f4-discovery/
```

That directory contains the emitted JSON/Ada artifacts, the generated embedded
driver, the generated `build.gpr`, the built ELF, and deploy logs.

## Prerequisites

Simulation requires:

- `renode`
- `gprbuild`
- `arm-elf-gnatls` or `arm-eabi-gnatls`
- `arm-elf-nm` or `arm-eabi-nm`
- the built-in `light-tasking-stm32f4` runtime in the ARM toolchain

Hardware deploy additionally requires:

- `openocd`
- `arm-elf-readelf` or `arm-eabi-readelf` or host `readelf`
- an STM32F4 Discovery board connected through ST-LINK

The wrapper probes `arm-elf` first, then `arm-eabi`, and uses the first
working triplet consistently for the cross-build and ELF inspection steps.

## Symbol Watching

`--watch-symbol` is currently supported only with `--simulate`.

Current rules:

- `--watch-symbol` and `--expect-value` must be provided together
- the symbol name is the exact ELF symbol name, not a Safe source-level name
- supported symbol sizes are `1`, `2`, `4`, and `8` bytes
- expected values may be decimal or `0x`-prefixed
- non-negative expectations compare against the raw unsigned value
- negative expectations compare against the symbol value interpreted as two's-complement signed

You can inspect candidate symbols with the ARM toolchain directly, for example:

```bash
arm-eabi-readelf -sW tests/embedded/obj/entry_integer_result/deploy/stm32f4-discovery/embedded_main
```

## Notes

- The hardware path polls the exported status word through a non-intrusive
  OpenOCD `mem_ap` target rather than halting the Cortex-M4.
- This command is independent of the fixed embedded smoke corpus in
  [`embedded_simulation.md`](embedded_simulation.md).
- Richer observability such as result watching, UART capture, or `print`-based
  deploy assertions is future work.
