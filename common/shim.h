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

// iprintf(fmt, a) / iprintf(fmt, a, b) with floating-point arguments.
void nds_printf_1f(const char *fmt, double a);
void nds_printf_2f(const char *fmt, double a, double b);

// iscanf(fmt, buf): read a whitespace-delimited string from stdin.
void nds_scanf_str(char *buf);

// iprintf(fmt, s): one string argument (%s).
void nds_printf_str(const char *fmt, const char *s);

// SPRITE_PALETTE / SPRITE_PALETTE_SUB pointer macros.
unsigned short *nds_sprite_palette(void);
unsigned short *nds_sprite_palette_sub(void);

// SPRITE_GFX / SPRITE_GFX_SUB pointer macros.
unsigned short *nds_sprite_gfx(void);
unsigned short *nds_sprite_gfx_sub(void);

// BG_PALETTE / BG_GFX pointer macros.
unsigned short *nds_bg_palette(void);
unsigned short *nds_bg_gfx(void);

// CHAR_BASE_BLOCK / SCREEN_BASE_BLOCK address macros, and a BGCTRL[] register
// setter (used by the tilemap example).
void *nds_char_base_block(int n);
void *nds_screen_base_block(int n);
void nds_set_bgctrl(int layer, unsigned value);

// BGCTRL value for a 256-colour 32x32 text background at the given bases.
unsigned nds_bgctrl_value_256(int tileBase, int mapBase);

// FIFO packed-command ids (REG2ID macros) for hand-built display lists.
unsigned char nds_fifo_begin(void);
unsigned char nds_fifo_color(void);
unsigned char nds_fifo_vertex16(void);
unsigned char nds_fifo_end(void);

// GFX_TEX_COORD register: submit a pre-packed (TEXTURE_PACK) texcoord.
void nds_set_tex_coord(unsigned packed);

// 3D geometry-engine status registers (used by the picking example).
int nds_gfx_busy(void);               // GFX_BUSY: nonzero while the GE is busy
unsigned nds_gfx_polygon_ram_usage(void); // GFX_POLYGON_RAM_USAGE

// Motion-blur via the display-capture unit (REG_DISPCAPCNT + DCAP_* macros).
void nds_motion_blur_setup(void);    // configure the capture blend (once)
void nds_motion_blur_enable(void);   // display composited-from-VRAM (blurred)
void nds_motion_blur_disable(void);  // display the normal layer composition
void nds_motion_blur_continue(void); // re-arm capture (call each frame)

// Display capture used to mirror the 3D scene to the other screen (dual_screen).
int  nds_dispcap_busy(void);          // nonzero while a capture is in progress
void nds_dispcap_to_bank(int bank);   // capture this frame to VRAM bank (full screen)
void nds_init_sub_sprites_grid(void); // 4x3 grid of 64x64 bitmap sprites on the sub OAM

// Cearn's fixed-point atan2 (LUT + hardware divider). Returns [0,2pi), pi~0x4000.
unsigned nds_atan2_lerp(int x, int y);

// Write an entry of VRAM bank F's extended sprite palette (VRAM_F_EXT_SPR_PALETTE).
void nds_set_ext_spr_palette_f(int palette, int index, unsigned short color);

// Address of a [bg][slot] entry in the VRAM E / H extended BG palettes.
void *nds_vram_e_ext_palette(int bg, int slot);
void *nds_vram_h_ext_palette(int bg, int slot);

// Stable pointers to the global OAM states (cast to OamState* on the Swift side).
void *nds_oam_main(void);
void *nds_oam_sub(void);

#endif // SWIFT_NDS_SHIM_H
