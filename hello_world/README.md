# hello_world (Swift)

A Swift port of the libnds `hello_world` example — a simple console print demo.
It prints a greeting, runs a VBlank-driven frame counter, reads the touch
screen, and exits on START.

This is the smallest example: a single [source/main.swift](source/main.swift)
plus a Makefile that pulls in the shared scaffolding in
[../common](../common). See the [top-level README](../README.md) for how the
build and the C shim work.

## Build

```sh
export DEVKITPRO=/opt/devkitpro
export DEVKITARM=$DEVKITPRO/devkitARM
make            # -> hello_world.nds
```
