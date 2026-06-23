//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Graphics/capture/ScreenShot example.
//
//  Three rotating sprites (direct-bitmap, 256-colour, 16-colour) sharing one
//  affine matrix. Press A to grab the screen with the display-capture unit and
//  save it as a 24-bit BMP to the SD card via libfat.
//
//  (The BMP write needs a writable filesystem — enable an SD image in melonDS's
//  DLDI/SD settings to exercise it; without one fatInitDefault simply fails and
//  the sprite demo still runs.)
//
//---------------------------------------------------------------------------------

import CNDS
import _Volatile

//---------------------------------------------------------------------------------
// Hardware registers / memory-mapped regions
//---------------------------------------------------------------------------------
let REG_DISPCNT    = VolatileMappedRegister<UInt32>(unsafeBitPattern: 0x04000000)
let REG_DISPCAPCNT = VolatileMappedRegister<UInt32>(unsafeBitPattern: 0x04000064)

let SPRITE_GFX = UnsafeMutablePointer<UInt16>(bitPattern: 0x06400000)! // MM_VRAM_OBJ_A
let OAM        = UnsafeMutableRawPointer(bitPattern: 0x07000000)!      // MM_OBJRAM
let VRAM_D     = UnsafeMutablePointer<UInt16>(bitPattern: 0x06860000)! // MM_VRAM_D (LCD)

//---------------------------------------------------------------------------------
// Constants (BIT()/function-like macros that don't import)
//---------------------------------------------------------------------------------
@inline(__always) func RGB15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}

let DISPLAY_SPR_ACTIVE: UInt32 = 1 << 12
let DISPLAY_BG0_ACTIVE: UInt32 = 1 << 8
let DISPLAY_SPR_1D:     UInt32 = 1 << 4
let DISPLAY_SPR_1D_BMP: UInt32 = 4 << 4
let MODE_FB1:           UInt32 = 0x00060000
@inline(__always) func DCAP_OFFSET(_ n: UInt32) -> UInt32 { (n & 3) << 18 }
@inline(__always) func DCAP_BANK(_ n: UInt32)   -> UInt32 { (n & 3) << 16 }
@inline(__always) func DCAP_SIZE(_ n: UInt32)   -> UInt32 { (n & 3) << 20 }
let DCAP_ENABLE: UInt32 = 1 << 31

let ATTR0_DISABLED:         UInt16 = 2 << 8
let ATTR0_ROTSCALE_DOUBLE:  UInt16 = 3 << 8
let ATTR0_BMP:              UInt16 = 3 << 10
let ATTR0_COLOR_256:        UInt16 = 1 << 13
let ATTR0_COLOR_16:         UInt16 = 0 << 13
let ATTR1_SIZE_32:          UInt16 = 2 << 14
@inline(__always) func ATTR2_ALPHA(_ n: UInt16)   -> UInt16 { n << 12 }
@inline(__always) func ATTR2_PALETTE(_ n: UInt16) -> UInt16 { n << 12 }

let videoModeBase: UInt32 = MODE_0_2D.rawValue | DISPLAY_SPR_ACTIVE | DISPLAY_BG0_ACTIVE
                          | DISPLAY_SPR_1D | DISPLAY_SPR_1D_BMP

//---------------------------------------------------------------------------------
// OAM shadow: 128 entries x 4 u16 (attr0, attr1, attr2, affine/filler).
// Sprite-rotation matrix 0 lives in the 4th u16 of sprites 0..3:
//   hdx = [3], hdy = [7], vdx = [11], vdy = [15].
//---------------------------------------------------------------------------------
var oam = [UInt16](repeating: 0, count: 128 * 4)

func initSprites() {
	for i in 0 ..< 128 {
		oam[i * 4 + 0] = ATTR0_DISABLED
		oam[i * 4 + 1] = 0
		oam[i * 4 + 2] = 0
		oam[i * 4 + 3] = 0
	}
}

func updateOAM() {
	oam.withUnsafeBytes { buf in
		DC_FlushRange(buf.baseAddress, 128 * 8)
		dmaCopy(buf.baseAddress, OAM, 128 * 8)
	}
}

//---------------------------------------------------------------------------------
// Capture the screen (to VRAM bank D) and write it out as a 24-bit BMP.
//---------------------------------------------------------------------------------
func screenshotBMP(_ filename: String) {
	// capture the live composited image into bank D, then wait for it to finish
	REG_DISPCAPCNT.store(DCAP_BANK(3) | DCAP_ENABLE | DCAP_SIZE(3))
	while REG_DISPCAPCNT.load() & DCAP_ENABLE != 0 {}

	let headerSize = 14 + 40
	let pixels = 256 * 192
	var buf = [UInt8](repeating: 0, count: pixels * 3 + headerSize)

	@inline(__always) func w16(_ off: Int, _ v: UInt16) {
		buf[off] = UInt8(v & 0xFF); buf[off + 1] = UInt8(v >> 8)
	}
	@inline(__always) func w32(_ off: Int, _ v: UInt32) {
		buf[off] = UInt8(v & 0xFF); buf[off + 1] = UInt8((v >> 8) & 0xFF)
		buf[off + 2] = UInt8((v >> 16) & 0xFF); buf[off + 3] = UInt8((v >> 24) & 0xFF)
	}

	// BITMAPFILEHEADER (14 bytes)
	w16(0, 0x4D42)                                   // "BM"
	w32(2, UInt32(pixels * 3 + headerSize))          // file size
	w16(6, 0); w16(8, 0)                             // reserved
	w32(10, UInt32(headerSize))                      // pixel-data offset
	// BITMAPINFOHEADER (40 bytes)
	w32(14, 40)                                      // header size
	w32(18, 256)                                     // width
	w32(22, 192)                                     // height
	w16(26, 1)                                       // planes
	w16(28, 24)                                      // bits per pixel
	w32(30, 0)                                       // compression
	w32(34, UInt32(pixels * 3))                      // image size
	w32(38, 0); w32(42, 0)                           // resolution
	w32(46, 0); w32(50, 0)                           // colours used / important

	// RGB15 (captured) -> RGB24, bottom-up (the C's vertical-flip index)
	for y in 0 ..< 192 {
		for x in 0 ..< 256 {
			let color = VRAM_D[pixels - y * 256 + x]
			let b = UInt8((color & 31) << 3)
			let g = UInt8(((color >> 5) & 31) << 3)
			let r = UInt8(((color >> 10) & 31) << 3)
			let o = ((y * 256) + x) * 3 + headerSize
			buf[o] = r; buf[o + 1] = g; buf[o + 2] = b
		}
	}

	DC_FlushAll()
	buf.withUnsafeBytes { _ = nds_write_file(filename, $0.baseAddress, UInt32(buf.count)) }
}

//---------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------
_ = nds_fat_init()

// A+B mapped consecutively as 256 KB of sprite memory; C to BG; D to LCD (capture).
vramSetPrimaryBanks(VRAM_A_MAIN_SPRITE, VRAM_B_MAIN_SPRITE,
                    VRAM_C_MAIN_BG_0x06000000, VRAM_D_LCD)

videoSetMode(videoModeBase)
consoleInit(nil, 0, BgType_Text4bpp, BgSize_T_256x256, 31, 0, true, true)

initSprites()

// Direct-bitmap sprite (32x32 red)
nds_puts("\u{1b}[1;1HDirect Bitmap:")
oam[0] = ATTR0_BMP | ATTR0_ROTSCALE_DOUBLE | 10
oam[1] = ATTR1_SIZE_32 | 20
oam[2] = ATTR2_ALPHA(1) | 0
for i in 0 ..< 32 * 32 { SPRITE_GFX[i] = RGB15(31, 0, 0) | (1 << 15) }

// 256-colour sprite (blue)
nds_puts("\u{1b}[9;1H256 color:")
oam[4] = ATTR0_COLOR_256 | ATTR0_ROTSCALE_DOUBLE | 75
oam[5] = ATTR1_SIZE_32 | 20
oam[6] = 64
nds_sprite_palette()![1] = RGB15(0, 0, 31)
for i in 0 ..< 32 * 16 { SPRITE_GFX[i + 64 * 16] = (1 << 8) | 1 }

// 16-colour sprite (yellow, palette 1)
nds_puts("\u{1b}[16;1H16 color:")
oam[8]  = ATTR0_COLOR_16 | ATTR0_ROTSCALE_DOUBLE | 135
oam[9]  = ATTR1_SIZE_32 | 20
oam[10] = ATTR2_PALETTE(1) | 96
nds_sprite_palette()![17] = RGB15(31, 31, 0)
for i in 0 ..< 32 * 8 { SPRITE_GFX[i + 96 * 16] = (1 << 12) | (1 << 8) | (1 << 4) | 1 }

// initial affine matrix 0 = identity (256 == 1.0 in 1.7.8)
oam[3] = 256; oam[7] = 0; oam[11] = 0; oam[15] = 256

var angle: Int32 = 0

while pmMainLoop() {
	angle += 64

	let a = Int16(truncatingIfNeeded: angle)
	let hdx = cosLerp(a) >> 4
	let hdy = sinLerp(a) >> 4
	oam[3]  = UInt16(bitPattern: hdx)   // hdx
	oam[7]  = UInt16(bitPattern: hdy)   // hdy
	oam[11] = UInt16(bitPattern: -hdy)  // vdx = -hdy
	oam[15] = UInt16(bitPattern: hdx)   // vdy =  hdx

	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	if keysDown() & KEY_A != 0 {
		screenshotBMP("shot.bmp")
		REG_DISPCNT.store(MODE_FB1)        // show the captured framebuffer
	}
	if keysUp() & KEY_A != 0 {
		videoSetMode(videoModeBase | DCAP_OFFSET(1))
	}

	updateOAM()
}
