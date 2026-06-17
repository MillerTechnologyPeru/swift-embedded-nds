//---------------------------------------------------------------------------------
// shim.c -- shared C support for the Swift NDS examples (see shim.h).
//---------------------------------------------------------------------------------
#include "shim.h"

#include <nds.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdint.h>
#include <stddef.h>

#include <calico/arm/common.h>

void nds_puts(const char *s) {
	iprintf("%s", s);
}

void nds_printf_1i(const char *fmt, int a) {
	iprintf(fmt, a);
}

void nds_printf_2i(const char *fmt, int a, int b) {
	iprintf(fmt, a, b);
}

unsigned short nds_timer_freq_1024(int hz) {
	return TIMER_FREQ_1024(hz);
}

unsigned nds_bus_clock(void) {
	return BUS_CLOCK;
}

// iprintf is integer-only; use full printf for floating-point conversions.
void nds_printf_1f(const char *fmt, double a) {
	printf(fmt, a);
}

void nds_printf_2f(const char *fmt, double a, double b) {
	printf(fmt, a, b);
}

void nds_scanf_str(char *buf) {
	iscanf("%s", buf);
}

unsigned short *nds_sprite_palette(void) {
	return SPRITE_PALETTE;
}

unsigned short *nds_sprite_palette_sub(void) {
	return SPRITE_PALETTE_SUB;
}

unsigned short *nds_sprite_gfx(void) {
	return SPRITE_GFX;
}

unsigned short *nds_sprite_gfx_sub(void) {
	return SPRITE_GFX_SUB;
}

unsigned short *nds_bg_palette(void) {
	return BG_PALETTE;
}

unsigned short *nds_bg_gfx(void) {
	return BG_GFX;
}

void *nds_char_base_block(int n) {
	return (void *)CHAR_BASE_BLOCK(n);
}

void *nds_screen_base_block(int n) {
	return (void *)SCREEN_BASE_BLOCK(n);
}

void nds_set_bgctrl(int layer, unsigned value) {
	BGCTRL[layer] = value;
}

unsigned nds_bgctrl_value_256(int tileBase, int mapBase) {
	return BG_TILE_BASE(tileBase) | BG_MAP_BASE(mapBase) | BG_COLOR_256 | BG_32x32;
}

unsigned char nds_fifo_begin(void)    { return FIFO_BEGIN; }
unsigned char nds_fifo_color(void)    { return FIFO_COLOR; }
unsigned char nds_fifo_vertex16(void) { return FIFO_VERTEX16; }
unsigned char nds_fifo_end(void)      { return FIFO_END; }

void nds_set_tex_coord(unsigned packed) {
	GFX_TEX_COORD = packed;
}

int nds_gfx_busy(void) {
	return GFX_BUSY ? 1 : 0;
}

unsigned nds_gfx_polygon_ram_usage(void) {
	return GFX_POLYGON_RAM_USAGE;
}

// --- Motion blur via display capture (Textured_Cube) -----------------------------
void nds_motion_blur_setup(void) {
	vramSetBankB(VRAM_B_LCD);
	REG_DISPCAPCNT =
		  DCAP_MODE(DCAP_MODE_BLEND)
		| DCAP_SRC_B(DCAP_SRC_B_VRAM)
		| DCAP_SRC_A(DCAP_SRC_A_3DONLY)
		| DCAP_SIZE(DCAP_SIZE_256x192)
		| DCAP_OFFSET(0)
		| DCAP_BANK(DCAP_BANK_VRAM_B)
		| DCAP_B(12)   // blend mostly from B for a dramatic trail
		| DCAP_A(4);   // and only a little from the new scene
}

void nds_motion_blur_enable(void) {
	u32 dispcnt = REG_DISPCNT;
	dispcnt &= ~(0x00030000u); dispcnt |= 2u << 16; // display from VRAM
	dispcnt &= ~(0x000C0000u); dispcnt |= 1u << 18; // ... from VRAM_B
	REG_DISPCNT = dispcnt;
}

void nds_motion_blur_disable(void) {
	u32 dispcnt = REG_DISPCNT;
	dispcnt &= ~(0x00030000u); dispcnt |= 1u << 16; // normal layer composition
	REG_DISPCNT = dispcnt;
}

void nds_motion_blur_continue(void) {
	REG_DISPCAPCNT |= DCAP_ENABLE;
}

//---------------------------------------------------------------------------------
// Runtime support the Embedded Swift object needs but devkitARM's libc/libgcc
// do not provide for this target.
//---------------------------------------------------------------------------------

// Embedded Swift's runtime can reference arc4random_buf (e.g. for the system
// RNG). The NDS has no entropy source and newlib's getentropy fallback is not
// wired up here, so provide a small xorshift PRNG. NOT cryptographically secure
// -- fine for the examples, which do not rely on randomness for anything.
void arc4random_buf(void *buf, size_t n) {
	static uint32_t s = 0x2545F491u;
	uint8_t *p = (uint8_t *)buf;
	for (size_t i = 0; i < n; i++) {
		s ^= s << 13;
		s ^= s >> 17;
		s ^= s << 5;
		p[i] = (uint8_t)s;
	}
}

// Swift's allocator calls posix_memalign; newlib only ships memalign.
int posix_memalign(void **memptr, size_t alignment, size_t size) {
	void *p = memalign(alignment, size);
	if (!p) return ENOMEM;
	*memptr = p;
	return 0;
}

// ARMv4t/v5te has no atomic instructions, so LLVM emits __atomic_* libcalls.
// The Swift code runs only on the single ARM9 core, so a short interrupt lock
// makes each operation atomic with respect to IRQ handlers.
uint32_t __atomic_load_4(const volatile void *ptr, int memorder) {
	(void)memorder;
	ArmIrqState st = armIrqLockByPsr();
	uint32_t v = *(const volatile uint32_t *)ptr;
	armIrqUnlockByPsr(st);
	return v;
}

void __atomic_store_4(volatile void *ptr, uint32_t val, int memorder) {
	(void)memorder;
	ArmIrqState st = armIrqLockByPsr();
	*(volatile uint32_t *)ptr = val;
	armIrqUnlockByPsr(st);
}

uint32_t __atomic_fetch_add_4(volatile void *ptr, uint32_t val, int memorder) {
	(void)memorder;
	ArmIrqState st = armIrqLockByPsr();
	volatile uint32_t *p = ptr;
	uint32_t old = *p;
	*p = old + val;
	armIrqUnlockByPsr(st);
	return old;
}

uint32_t __atomic_fetch_sub_4(volatile void *ptr, uint32_t val, int memorder) {
	(void)memorder;
	ArmIrqState st = armIrqLockByPsr();
	volatile uint32_t *p = ptr;
	uint32_t old = *p;
	*p = old - val;
	armIrqUnlockByPsr(st);
	return old;
}

_Bool __atomic_compare_exchange_4(volatile void *ptr, void *expected,
                                  uint32_t desired, _Bool weak,
                                  int success, int failure) {
	(void)weak; (void)success; (void)failure;
	ArmIrqState st = armIrqLockByPsr();
	volatile uint32_t *p = ptr;
	uint32_t *exp = expected;
	_Bool ok = (*p == *exp);
	if (ok) {
		*p = desired;
	} else {
		*exp = *p;
	}
	armIrqUnlockByPsr(st);
	return ok;
}
