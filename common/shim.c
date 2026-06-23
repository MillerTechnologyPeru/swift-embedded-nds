//---------------------------------------------------------------------------------
// shim.c -- shared C support for the Swift NDS examples (see shim.h).
//---------------------------------------------------------------------------------
#include <nds.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdint.h>
#include <stddef.h>

#include <calico/arm/common.h>
#include <fat.h>
#include <wfc.h>           // WlanBssDesc / WlanAuthData -- must precede shim.h
#include <string.h>
#include <time.h>          // time() / gmtime() (RealTimeClock)

#include "shim.h"

int nds_read_line(char *buf, int size) {
	if (!fgets(buf, size, stdin)) return -1;
	buf[strcspn(buf, "\n")] = 0;
	return (int)strlen(buf);
}

// --- WlanBssDesc field access (struct-only, no wlan/wfc symbols referenced) ---
unsigned nds_ap_ssid_len(const WlanBssDesc *ap) { return ap->ssid_len; }

void nds_ap_get_ssid(const WlanBssDesc *ap, char *out) {
	unsigned n = ap->ssid_len;
	if (n > WLAN_MAX_SSID_LEN) n = WLAN_MAX_SSID_LEN;
	memcpy(out, ap->ssid, n);
	out[n] = 0;
}

void nds_ap_set_ssid(WlanBssDesc *ap, const char *s, unsigned n) {
	if (n > WLAN_MAX_SSID_LEN) n = WLAN_MAX_SSID_LEN;
	memcpy(ap->ssid, s, n);
	ap->ssid_len = n;
}

unsigned nds_ap_auth_mask(const WlanBssDesc *ap) { return ap->auth_mask; }
unsigned nds_ap_rssi(const WlanBssDesc *ap)      { return ap->rssi; }
void nds_ap_set_auth_type(WlanBssDesc *ap, int t) { ap->auth_type = (WlanBssAuthType)t; }

void nds_auth_clear(WlanAuthData *a) { memset(a, 0, sizeof(*a)); }
void nds_auth_set_wep(WlanAuthData *a, const char *k, unsigned n) {
	if (n > WLAN_WEP_128_LEN) n = WLAN_WEP_128_LEN;
	memcpy(a->wep_key, k, n);
}

int nds_fat_init(void) {
	return fatInitDefault() ? 1 : 0;
}

int nds_write_file(const char *name, const void *data, unsigned len) {
	FILE *f = fopen(name, "wb");
	if (!f) return 0;
	size_t n = fwrite(data, 1, len, f);
	fclose(f);
	return n == len ? 1 : 0;
}

void nds_puts(const char *s) {
	iprintf("%s", s);
}

void nds_printf_1i(const char *fmt, int a) {
	iprintf(fmt, a);
}

void nds_printf_2i(const char *fmt, int a, int b) {
	iprintf(fmt, a, b);
}

void nds_printf_3i(const char *fmt, int a, int b, int c) {
	iprintf(fmt, a, b, c);
}

void nds_printf_4i(const char *fmt, int a, int b, int c, int d) {
	iprintf(fmt, a, b, c, d);
}

void nds_rtc_read(int *year, int *month, int *day, int *hour, int *minute, int *second) {
	time_t now = time(NULL);
	struct tm *t = gmtime(&now);
	*year   = t->tm_year + 1900;
	*month  = t->tm_mon + 1;
	*day    = t->tm_mday;
	*hour   = t->tm_hour;
	*minute = t->tm_min;
	*second = t->tm_sec;
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

void nds_printf_str(const char *fmt, const char *s) {
	iprintf(fmt, s);
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

int nds_dispcap_busy(void) {
	return (REG_DISPCAPCNT & DCAP_ENABLE) ? 1 : 0;
}

void nds_dispcap_to_bank(int bank) {
	REG_DISPCAPCNT = DCAP_BANK(bank) | DCAP_ENABLE | DCAP_SIZE(3);
}

// Cearn (coranac.com)'s fast fixed-point atan2 -- LUT + linear interpolation,
// using the NDS hardware divider. Returns [0,2pi) where pi ~ 0x4000.
static const unsigned short s_atanLUT[130] = {
	0x0000,0x0146,0x028C,0x03D2,0x0517,0x065D,0x07A2,0x08E7,
	0x0A2C,0x0B71,0x0CB5,0x0DF9,0x0F3C,0x107F,0x11C1,0x1303,
	0x1444,0x1585,0x16C5,0x1804,0x1943,0x1A80,0x1BBD,0x1CFA,
	0x1E35,0x1F6F,0x20A9,0x21E1,0x2319,0x2450,0x2585,0x26BA,
	0x27ED,0x291F,0x2A50,0x2B80,0x2CAF,0x2DDC,0x2F08,0x3033,
	0x315D,0x3285,0x33AC,0x34D2,0x35F6,0x3719,0x383A,0x395A,
	0x3A78,0x3B95,0x3CB1,0x3DCB,0x3EE4,0x3FFB,0x4110,0x4224,
	0x4336,0x4447,0x4556,0x4664,0x4770,0x487A,0x4983,0x4A8B,
	0x4B90,0x4C94,0x4D96,0x4E97,0x4F96,0x5093,0x518F,0x5289,
	0x5382,0x5478,0x556E,0x5661,0x5753,0x5843,0x5932,0x5A1E,
	0x5B0A,0x5BF3,0x5CDB,0x5DC1,0x5EA6,0x5F89,0x606A,0x614A,
	0x6228,0x6305,0x63E0,0x64B9,0x6591,0x6667,0x673B,0x680E,
	0x68E0,0x69B0,0x6A7E,0x6B4B,0x6C16,0x6CDF,0x6DA8,0x6E6E,
	0x6F33,0x6FF7,0x70B9,0x717A,0x7239,0x72F6,0x73B3,0x746D,
	0x7527,0x75DF,0x7695,0x774A,0x77FE,0x78B0,0x7961,0x7A10,
	0x7ABF,0x7B6B,0x7C17,0x7CC1,0x7D6A,0x7E11,0x7EB7,0x7F5C,
	0x8000,0x80A2,
};

#define NDS_OCTANTIFY(_x, _y, _o) do {                          \
	int _t; _o = 0;                                             \
	if (_y <  0) {           _x = -_x;   _y = -_y; _o += 4; }   \
	if (_x <= 0) { _t = _x;  _x =  _y;   _y = -_t; _o += 2; }   \
	if (_x <= _y){ _t = _y-_x; _x = _x+_y; _y = _t; _o += 1; }  \
} while (0)

unsigned nds_atan2_lerp(int x, int y) {
	enum { BRAD_PI = 1 << 14, ATAN_FP = 12, ATANLUT_STRIDE = 0x1000 / 0x80, ATANLUT_STRIDE_SHIFT = 5 };
	if (y == 0) return (x >= 0) ? 0 : BRAD_PI;

	int phi;
	NDS_OCTANTIFY(x, y, phi);
	phi *= BRAD_PI / 4;

	// fixed-point divide y/x via the hardware divider
	while (REG_DIVCNT & DIV_BUSY);
	REG_DIVCNT = DIV_64_32;
	REG_DIV_NUMER = ((int64_t)y) << ATAN_FP;
	REG_DIV_DENOM_L = x;
	while (REG_DIVCNT & DIV_BUSY);
	unsigned t = REG_DIV_RESULT_L;

	unsigned h = t % ATANLUT_STRIDE;
	unsigned fa = s_atanLUT[t / ATANLUT_STRIDE];
	unsigned fb = s_atanLUT[t / ATANLUT_STRIDE + 1];
	return phi + (fa + ((fb - fa) * h >> ATANLUT_STRIDE_SHIFT)) / 8;
}

void nds_set_ext_spr_palette_f(int palette, int index, unsigned short color) {
	VRAM_F_EXT_SPR_PALETTE[palette][index] = color;
}

void *nds_vram_e_ext_palette(int bg, int slot) {
	return &VRAM_E_EXT_PALETTE[bg][slot];
}

void *nds_vram_h_ext_palette(int bg, int slot) {
	return &VRAM_H_EXT_PALETTE[bg][slot];
}

void *nds_oam_main(void) { return &oamMain; }
void *nds_oam_sub(void)  { return &oamSub; }

void nds_init_sub_sprites_grid(void) {
	oamInit(&oamSub, SpriteMapping_Bmp_2D_256, false);

	int id = 0;
	// a 4x3 grid of 64x64 bitmap sprites that tiles the whole screen
	for (int y = 0; y < 3; y++) {
		for (int x = 0; x < 4; x++) {
			oamSub.oamMemory[id].attribute[0] = ATTR0_BMP | ATTR0_SQUARE | (64 * y);
			oamSub.oamMemory[id].attribute[1] = ATTR1_SIZE_64 | (64 * x);
			oamSub.oamMemory[id].attribute[2] = ATTR2_ALPHA(1) | (8 * 32 * y) | (8 * x);
			id++;
		}
	}

	swiWaitForVBlank();
	oamUpdate(&oamSub);
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

// 16-bit variants — needed by VolatileMappedRegister<UInt16> (hardware registers).
uint16_t __atomic_load_2(const volatile void *ptr, int memorder) {
	(void)memorder;
	ArmIrqState st = armIrqLockByPsr();
	uint16_t v = *(const volatile uint16_t *)ptr;
	armIrqUnlockByPsr(st);
	return v;
}

void __atomic_store_2(volatile void *ptr, uint16_t val, int memorder) {
	(void)memorder;
	ArmIrqState st = armIrqLockByPsr();
	*(volatile uint16_t *)ptr = val;
	armIrqUnlockByPsr(st);
}

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
