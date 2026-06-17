# swift-nds

Nintendo DS homebrew written in **Embedded Swift**, ported from the official
[libnds examples](https://github.com/devkitPro/nds-examples). Each example is a
faithful translation of its C/C++ original that compiles with an Embedded Swift
toolchain and runs on real hardware / emulators (melonDS, DeSmuME).

## Examples

| Directory | Ported from | Demonstrates |
|-----------|-------------|--------------|
| [hello_world](hello_world)       | `hello_world`               | Console output, VBlank IRQ handler, touch read |
| [ansi_console](ansi_console)     | `Graphics/Printing/ansi_console` | ANSI cursor escape sequences |
| [stopwatch](stopwatch)           | `time/stopwatch`            | Hardware timer elapsed/pause, formatted output |
| [timercallback](timercallback)   | `time/timercallback`        | Timer IRQ callback (C function pointer), PSG sound |
| [exception_test](exception_test) | `debugging/exceptionTest`   | Default exception handler, raw memory access |

## Building

Requirements:

- **devkitPro** with `devkitARM`, `libnds`, `calico`, and `ndstool`
  (`dkp-pacman -S nds-dev`).
- An **Embedded-Swift-capable** Swift toolchain (a recent `DEVELOPMENT-SNAPSHOT`).

```sh
export DEVKITPRO=/opt/devkitpro
export DEVKITARM=$DEVKITPRO/devkitARM

cd hello_world && make          # or any other example dir
# -> hello_world.nds

make SWIFTC=/path/to/swiftc      # if swiftc isn't the Embedded toolchain on PATH
```

## How it works

Everything shared lives in [common/](common); each example is just a
`source/main.swift` plus a three-line Makefile that sets `TARGET` and
`include`s [common/common.mk](common/common.mk).

### The build pipeline ([common.mk](common/common.mk))

1. **Embedded Swift → object.** Targets `armv4t-none-none-eabi` — the prebuilt
   Embedded stdlib ships an armv4t slice but no armv5te slice, and armv4t code
   runs on the DS's ARM946E-S (armv5te is backwards compatible). Embedded clang
   is pointed at newlib's headers, libnds, calico, and our module map.
2. **C shim → object** with devkitARM.
3. **Link** against the modern calico-based libnds (`-specs=…/ds9.specs`,
   `-lnds9 -lcalico_ds9`).
4. **Package** the `.nds` with `ndstool` (calico's prebuilt ARM7 + default icon).

### The C shim ([common/shim.c](common/shim.c), [shim.h](common/shim.h))

Bridges the gaps between Embedded Swift and libnds:

- **Variadic `iprintf`.** Swift imports C variadic functions but cannot call
  them, so `nds_puts` / `nds_printf_1i` / `nds_printf_2i` forward into `iprintf`
  with fixed arity — all formatting still happens inside libnds.
- **Macro-only APIs.** `TIMER_FREQ_1024(n)` and `BUS_CLOCK` are preprocessor
  macros the Swift importer can't surface, so `nds_timer_freq_1024` /
  `nds_bus_clock` expose them as real functions.
- **Runtime support devkitARM doesn't provide for this target:**
  - `posix_memalign` (Swift's allocator wants it; newlib only has `memalign`).
  - `__atomic_*` outline helpers — armv4t has no atomic instructions, so LLVM
    emits libcalls; implemented with a short interrupt lock (safe on the single
    ARM9 core).
  - `arc4random_buf` — referenced by Swift's runtime; the NDS has no entropy
    source, so a small non-cryptographic xorshift fills the buffer.

### Swift ↔ libnds interop notes

- `import CNDS` ([common/module.modulemap](common/module.modulemap)) exposes
  `<nds.h>` + the shim.
- A non-capturing top-level Swift function bridges automatically to the
  `void (*)(void)` callback pointers used by `irqSet` / `timerStart`.
- In a file named `main.swift`, top-level code **is** the entry point — no
  `@main`.
- `swiWaitForVBlank` is a macro alias; call the underlying `threadWaitForVBlank()`.
- `KEY_*` are `#define`d as plain integers, so `keysDown() & KEY_START` works
  directly (no `.rawValue`). `DutyCycle_50` is a macro alias for the importable
  enum `SoundDuty_50`.

## Not ported

Examples that depend on an **asset pipeline** (grit-converted graphics,
`mmutil` soundbanks, NitroFS filesystems) are out of scope here — that tooling
is orthogonal to writing the program in Swift. The scaffolding in `common/`
applies to them unchanged once their assets are built.
