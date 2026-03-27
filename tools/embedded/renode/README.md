# Embedded Renode Assets

This directory contains the vendored Renode platform descriptions used by
`scripts/run_embedded_smoke.py`.

Files:

- `stm32f4_discovery.repl`
- `stm32f4.repl`

Source provenance:

- `stm32f4_discovery.repl` copied from the local Renode install:
  `~/.local/opt/renode-1.16.1/platforms/boards/stm32f4_discovery.repl`
- `stm32f4.repl` copied from the local Renode install:
  `~/.local/opt/renode-1.16.1/platforms/cpus/stm32f4.repl`

The smoke harness targets the STM32F4 Discovery / STM32F407 class board model.

The smoke harness generates a tiny wrapper `.resc` per case and loads these
vendored platform descriptions directly so the lane does not depend on Renode's
installed demo-script layout.
