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
| [print_both_screens](print_both_screens) | `Graphics/Printing/print_both_screens` | A text console on each screen (main + sub) |
| [console_windows](console_windows) | `Graphics/Printing/console_windows` | Multiple windowed consoles over one map |
| [stopwatch](stopwatch)           | `time/stopwatch`            | Hardware timer elapsed/pause, formatted output |
| [timercallback](timercallback)   | `time/timercallback`        | Timer IRQ callback (C function pointer), PSG sound |
| [keyboard_stdin](keyboard_stdin) | `input/keyboard/keyboard_stdin` | On-screen keyboard, callback field, `iscanf` stdin |
| [keyboard_async](keyboard_async) | `input/keyboard/keyboard_async` | Polled keyboard via `keyboardUpdate` |
| [sprites_simple](sprites_simple) | `Graphics/Sprites/simple`   | OAM sprites on both engines, VRAM banks, palettes |
| [touch_test](touch_test)         | `input/Touch_Pad/touch_test` | **grit-converted sprite**, OAM, touch min/max tracking |
| [custom_font](custom_font)       | `Graphics/Printing/custom_font` | **grit bitmap font** loaded into a console |
| [simple_tri](simple_tri)         | `Graphics/3D/Simple_Tri`    | 3D engine, GL pipeline, fixed-point + float GL calls |
| [simple_quad](simple_quad)       | `Graphics/3D/Simple_Quad`   | 3D `GL_QUAD`, D-pad rotation |
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
`include`s [common/common.mk](common/common.mk). Examples with graphics set
`GRAPHICS := gfx` to point at a directory of `.png`/`.bmp` + `.grit` pairs.

### Graphics assets (grit)

For examples that set `GRAPHICS`, [common.mk](common/common.mk) runs **grit** on
each image, compiles the generated data, and gathers the generated headers into
a single bridging header handed to Swift — so the grit symbols (`ballTiles`,
`fontPal`, …) are visible alongside `import CNDS`.

A C global array imports into Swift as a **tuple** (a *copy*), not a pointer.
Two ways to use the data:

- **Copying it yourself** (e.g. into sprite VRAM): `withUnsafeBytes(of: ballTiles) { … }`
  and loop — the temporary is valid for the closure body, which is all a
  synchronous copy needs.
- **Handing a pointer to libnds** (e.g. `ConsoleFont.gfx` for `consoleSetFont`):
  use the generated `nds_asset_<symbol>()` accessor, which returns the address
  of the *real linked symbol*. Passing a `withUnsafeBytes` temporary here is a
  bug — the pointer dangles once the closure returns and libnds renders garbage
  (a black screen, in the custom_font case).

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

- **Variadic stdio.** Swift imports C variadic functions but cannot call them,
  so `nds_puts` / `nds_printf_1i` / `nds_printf_2i` forward into `iprintf`, and
  `nds_scanf_str` forwards into `iscanf` — all formatting stays inside libnds.
- **Macro-only APIs.** Preprocessor macros the Swift importer can't surface are
  re-exported as real functions: `nds_timer_freq_1024` (`TIMER_FREQ_1024`),
  `nds_bus_clock` (`BUS_CLOCK`), and `nds_sprite_palette` /
  `nds_sprite_palette_sub` (the `SPRITE_PALETTE*` pointer macros).
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
- A non-capturing top-level Swift function bridges automatically to the C
  function-pointer types used by `irqSet` / `timerStart`, and can be assigned
  to a callback *field* on a struct too (e.g. `kbd.pointee.OnKeyPressed = …`).
- libnds C enums (`VideoMode`, …) import as Swift types — pass `.rawValue`
  where a function wants the underlying `u32` (e.g. `videoSetMode(MODE_0_2D.rawValue)`).
- `touchRead` returns `Bool`; some libnds calls return distinct enum types, so
  match Swift's stricter typing rather than the C "everything is an int" style.
- A few constants use the function-like `BIT(n)` macro (e.g. `KEY_TOUCH`),
  which the importer drops — spell the bit out in Swift (`1 << 14`).
- **3D / GL:** the float GL entry points (`glRotateX`, `gluPerspective`,
  `gluLookAt`, …) are real inline functions and import fine — Embedded Swift's
  soft-float calls them directly. `POLY_ALPHA(n)` is also an inline function, but
  `inttov16` / `floattof32` are function-like macros, so they're reimplemented as
  tiny Swift helpers. Functions typed to take a GL enum (`glMatrixMode`,
  `glBegin`) accept the enum value directly; where one wants a raw `int`/`u32`
  (`glEnable`, an OR with `POLY_CULL_NONE`), pass `.rawValue`.
- In a file named `main.swift`, top-level code **is** the entry point — no
  `@main`.
- `swiWaitForVBlank` is a macro alias; call the underlying `threadWaitForVBlank()`.
- `KEY_*` are `#define`d as plain integers, so `keysDown() & KEY_START` works
  directly (no `.rawValue`). `DutyCycle_50` is a macro alias for the importable
  enum `SoundDuty_50`.

## Remaining

The ported set above covers every major interop pattern: console, timers, IRQ
callbacks, PSG sound, input/keyboard, sprites/OAM, 3D/GL, and grit graphics.
What's left in the upstream example tree still needs its *own* toolchain or
runtime work, not just more of the same translation:

- **Audio** (`audio/maxmod/*`) — needs the `mmutil` soundbank pipeline.
- **Binary blobs** (`bin2o`) — 3D display lists, some backgrounds.
- **Filesystem** (`filesystem/*`) — libfat + DLDI / NitroFS.
- **Wi-Fi** (`dswifi/*`) — the dswifi stack.
- **Dual-CPU** (`pxi/*`, combined templates) — a separate ARM7 binary.
- **Large GL2D demos** (`Graphics/gl2d/*`) — big, asset-heavy.

The `common/` scaffolding (and the grit pipeline) applies to the asset-heavy
graphics ones unchanged; the others are each a distinct piece of plumbing.
