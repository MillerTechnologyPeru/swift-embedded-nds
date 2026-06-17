//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Touch_Pad/touch_test example.
//
//  Shows raw + calibrated touch coordinates, tracks the min/max seen, and moves
//  a ball sprite (a grit-converted PNG) to the stylus. R toggles continuous vs.
//  single-shot sampling.
//
//---------------------------------------------------------------------------------

import CNDS

// KEY_TOUCH is BIT(14) -- the function-like BIT macro isn't imported.
let KEY_TOUCH: UInt32 = 1 << 14

// Touch sampling mode (the original's anonymous enum CONTINUOUS=0 / SINGLE=1).
let CONTINUOUS: UInt32 = 0
let SINGLE: UInt32 = 1
var touchType = CONTINUOUS

var minX = 4096, minY = 4096, maxX = 0, maxY = 0
var minPX = 4096, minPY = 4096, maxPX = 0, maxPY = 0
var touch = touchPosition()

// put the main screen on the bottom lcd
lcdMainOnBottom()

videoSetMode(MODE_0_2D.rawValue)

// Sprite initialisation
oamInit(&oamMain, SpriteMapping_1D_32, false)

// enable vram and map it to the right places
vramSetPrimaryBanks(VRAM_A_MAIN_BG,     // map A to background memory
                    VRAM_B_MAIN_SPRITE, // map B to sprite memory
                    VRAM_C_LCD,         // not using C
                    VRAM_D_LCD)         // not using D

// load sprite palette and graphics from the grit-generated arrays
let palette = nds_sprite_palette()!
withUnsafeBytes(of: ballPal) { raw in
	let src = raw.bindMemory(to: UInt16.self)
	for i in 0 ..< 256 { palette[i] = src[i] }
}

let gfx = nds_sprite_gfx()!
withUnsafeBytes(of: ballTiles) { raw in
	let src = raw.bindMemory(to: UInt16.self)
	for i in 0 ..< (32 * 16) { gfx[i] = src[i] }
}

// initialise console background
consoleInit(nil, 0, BgType_Text4bpp, BgSize_T_256x256, 31, 0, true, true)

nds_puts("\u{1b}[4;8HTouch Screen Test")
nds_puts("\u{1b}[15;4HRight Shoulder toggles")

while pmMainLoop() {
	threadWaitForVBlank()
	oamUpdate(&oamMain)

	scanKeys()
	touchRead(&touch)

	let pressed = keysDown()
	let held = keysHeld()

	// Right shoulder toggles the mode; START exits.
	if pressed & KEY_R != 0 { touchType ^= SINGLE }
	if pressed & KEY_START != 0 { break }

	nds_puts("\u{1b}[14;4HTouch mode: ")
	nds_puts(touchType == CONTINUOUS ? "CONTINUOUS " : "SINGLE SHOT")

	nds_printf_2i("\u{1b}[6;5HTouch x = %04X, %04X\n", Int32(touch.rawx), Int32(touch.px))
	nds_printf_2i("\u{1b}[7;5HTouch y = %04X, %04X\n", Int32(touch.rawy), Int32(touch.py))
	nds_printf_1i("\u{1b}[0;18Hkeys: %08lX\n", Int32(bitPattern: held))

	if touchType == SINGLE && pressed & KEY_TOUCH == 0 { continue }
	if held & KEY_TOUCH == 0 || touch.rawx == 0 || touch.rawy == 0 { continue }

	nds_printf_2i("\u{1b}[12;12H(%d,%d)      ", Int32(touch.px), Int32(touch.py))

	if Int(touch.rawx) > maxX { maxX = Int(touch.rawx) }
	if Int(touch.rawy) > maxY { maxY = Int(touch.rawy) }
	if Int(touch.px) > maxPX { maxPX = Int(touch.px) }
	if Int(touch.py) > maxPY { maxPY = Int(touch.py) }

	if Int(touch.rawx) < minX { minX = Int(touch.rawx) }
	if Int(touch.rawy) < minY { minY = Int(touch.rawy) }
	if Int(touch.px) < minPX { minPX = Int(touch.px) }
	if Int(touch.py) < minPY { minPY = Int(touch.py) }

	nds_printf_2i("\u{1b}[0;0H(%d,%d)      ", Int32(minPX), Int32(minPY))
	nds_printf_2i("\u{1b}[1;0H(%d,%d)      ", Int32(minX), Int32(minY))
	nds_printf_2i("\u{1b}[22;21H(%d,%d)", Int32(maxX), Int32(maxY))
	nds_printf_2i("\u{1b}[23;23H(%d,%d)", Int32(maxPX), Int32(maxPY))

	// Move and display the sprite
	oamSet(&oamMain, 0,
	       Int32((Int(touch.px) - 16) & 0x01FF), // X position
	       Int32((Int(touch.py) - 16) & 0x00FF), // Y position
	       0, 0,
	       SpriteSize_32x32, SpriteColorFormat_256Color,
	       gfx,
	       -1,
	       false, false, false, false, false)
}
