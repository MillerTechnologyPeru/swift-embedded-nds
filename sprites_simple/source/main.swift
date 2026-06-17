//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Sprites/simple example.
//
//  A 16x16 sprite (filled procedurally, no external assets) follows the stylus
//  on both screens -- red on the main engine, green on the sub engine.
//
//---------------------------------------------------------------------------------

import CNDS

// RGB15(r,g,b) macro, computed inline.
@inline(__always)
func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}

// KEY_TOUCH is defined as BIT(14) in libnds; the function-like BIT macro isn't
// imported into Swift, so spell the bit out.
let KEY_TOUCH: UInt32 = 1 << 14

var touch = touchPosition()

videoSetMode(MODE_0_2D.rawValue)
videoSetModeSub(MODE_0_2D.rawValue)

vramSetBankA(VRAM_A_MAIN_SPRITE)
vramSetBankD(VRAM_D_SUB_SPRITE)

oamInit(&oamMain, SpriteMapping_1D_32, false)
oamInit(&oamSub, SpriteMapping_1D_32, false)

let gfx = oamAllocateGfx(&oamMain, SpriteSize_16x16, SpriteColorFormat_256Color)!
let gfxSub = oamAllocateGfx(&oamSub, SpriteSize_16x16, SpriteColorFormat_256Color)!

// fill both tiles with palette index 1 (two pixels packed per u16)
for i in 0 ..< (16 * 16 / 2) {
	gfx[i] = 1 | (1 << 8)
	gfxSub[i] = 1 | (1 << 8)
}

nds_sprite_palette()[1] = rgb15(31, 0, 0)
nds_sprite_palette_sub()[1] = rgb15(0, 31, 0)

while pmMainLoop() {
	scanKeys()

	let held = keysHeld()

	if held & KEY_TOUCH != 0 {
		touchRead(&touch)
	}

	if held & KEY_START != 0 { break }

	oamSet(&oamMain,                      // main graphics engine context
	       0,                             // oam index (0 to 127)
	       Int32(touch.px), Int32(touch.py), // x and y pixel location
	       0,                             // priority
	       0,                             // palette index
	       SpriteSize_16x16,
	       SpriteColorFormat_256Color,
	       gfx,                           // pointer to the loaded graphics
	       -1,                            // sprite rotation data
	       false,                         // double size when rotating?
	       false,                         // hide the sprite?
	       false, false,                  // hflip, vflip
	       false)                         // mosaic

	oamSet(&oamSub,
	       0,
	       Int32(touch.px), Int32(touch.py),
	       0,
	       0,
	       SpriteSize_16x16,
	       SpriteColorFormat_256Color,
	       gfxSub,
	       -1,
	       false,
	       false,
	       false, false,
	       false)

	threadWaitForVBlank()

	oamUpdate(&oamMain)
	oamUpdate(&oamSub)
}
