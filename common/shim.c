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
