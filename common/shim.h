//---------------------------------------------------------------------------------
// shim.h -- shared C support for the Swift NDS examples.
//
// Two jobs:
//   1. Fixed-arity wrappers around libnds' variadic iprintf, which Embedded
//      Swift can import but not call directly.
//   2. Wrappers for libnds macros (e.g. TIMER_FREQ_1024) that the Swift/C
//      importer cannot surface.
//
// (Runtime support such as posix_memalign and the __atomic_* outline helpers
//  lives in shim.c; it is referenced only by the linker, not by Swift.)
//---------------------------------------------------------------------------------
#ifndef SWIFT_NDS_SHIM_H
#define SWIFT_NDS_SHIM_H

// Print an already-formatted string (no varargs).
void nds_puts(const char *s);

// iprintf(fmt, a)        -- one 32-bit argument (use for %d, %u, %x, %lX, ...).
void nds_printf_1i(const char *fmt, int a);

// iprintf(fmt, a, b)     -- two 32-bit arguments.
void nds_printf_2i(const char *fmt, int a, int b);

// TIMER_FREQ_1024(n) macro: reload value for a /1024-prescaled timer at n Hz.
unsigned short nds_timer_freq_1024(int hz);

// BUS_CLOCK macro: the timer base frequency in Hz.
unsigned nds_bus_clock(void);

// iscanf(fmt, buf): read a whitespace-delimited string from stdin.
void nds_scanf_str(char *buf);

// SPRITE_PALETTE / SPRITE_PALETTE_SUB pointer macros.
unsigned short *nds_sprite_palette(void);
unsigned short *nds_sprite_palette_sub(void);

// SPRITE_GFX / SPRITE_GFX_SUB pointer macros.
unsigned short *nds_sprite_gfx(void);
unsigned short *nds_sprite_gfx_sub(void);

#endif // SWIFT_NDS_SHIM_H
