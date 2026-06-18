//---------------------------------------------------------------------------------
//
//  Swift port of the libnds sprite_extended_palettes example.
//
//  Two identical sprites (both filled with colour index 1) that pick up different
//  colours from separate extended sprite palettes. Touch to move them.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
let KEY_TOUCH: UInt32 = 1 << 14

var touch = touchPosition()

videoSetMode(MODE_0_2D.rawValue)
vramSetBankA(VRAM_A_MAIN_SPRITE)

oamInit(&oamMain, SpriteMapping_1D_32, true)   // true = use extended palettes

let gfx1 = oamAllocateGfx(&oamMain, SpriteSize_16x16, SpriteColorFormat_256Color)!
let gfx2 = oamAllocateGfx(&oamMain, SpriteSize_16x16, SpriteColorFormat_256Color)!

// both sprites are filled with colour index 1
for i in 0 ..< (16 * 16 / 2) {
	gfx1[i] = 1 | (1 << 8)
	gfx2[i] = 1 | (1 << 8)
}

// unlock VRAM F (can't write to it while mapped as palette memory), write the
// two extended palettes, then map it back as the sprite ext-palette.
vramSetBankF(VRAM_F_LCD)
nds_set_ext_spr_palette_f(0, 1, rgb15(31, 0, 0))
nds_set_ext_spr_palette_f(1, 1, rgb15(0, 31, 0))
vramSetBankF(VRAM_F_SPRITE_EXT_PALETTE)

while pmMainLoop() {
	scanKeys()
	let held = keysHeld()
	if held & KEY_TOUCH != 0 { touchRead(&touch) }
	if held & KEY_START != 0 { break }

	oamSet(&oamMain, 0, Int32(touch.px), Int32(touch.py), 0,
	       0,   // palette 0
	       SpriteSize_16x16, SpriteColorFormat_256Color, gfx1,
	       -1, false, false, false, false, false)

	oamSet(&oamMain, 1, 256 - Int32(touch.px), 192 - Int32(touch.py), 0,
	       1,   // palette 1
	       SpriteSize_16x16, SpriteColorFormat_256Color, gfx2,
	       -1, false, false, false, false, false)

	threadWaitForVBlank()
	oamUpdate(&oamMain)
}
