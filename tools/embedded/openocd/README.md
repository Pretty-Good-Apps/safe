# Embedded OpenOCD Assets

This directory contains the repo-local OpenOCD wrapper configs used by
`safe deploy`.

Files:

- `stm32f4discovery-safe.cfg`

The wrapper config layers a non-intrusive `mem_ap` monitor target on top of
OpenOCD's installed `board/stm32f4discovery.cfg` so the deploy harness can poll
the exported SRAM status word without halting the Cortex-M4 core.
