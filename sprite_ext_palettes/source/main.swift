//---------------------------------------------------------------------------------
//
//  Swift port of the libnds sprite_extended_palettes example.
//
//  Two identical sprites (both filled with colour index 1) that pick up different
//  colours from separate extended sprite palettes. Touch to move them.
//
//---------------------------------------------------------------------------------

import NDS

var touch = touchPosition()

Video.setMode(.mode0_2D)
Video.setBankA(VRAM_A_MAIN_SPRITE)

let main = OAM.main
main.initialize(mapping: SpriteMapping_1D_32, extPalette: true)   // use extended palettes

let gfx1 = main.allocateGfx(size: SpriteSize_16x16, format: .color256)!
let gfx2 = main.allocateGfx(size: SpriteSize_16x16, format: .color256)!

// both sprites are filled with colour index 1
for i in 0 ..< (16 * 16 / 2) {
	gfx1[i] = 1 | (1 << 8)
	gfx2[i] = 1 | (1 << 8)
}

// unlock VRAM F (can't write to it while mapped as palette memory), write the
// two extended palettes, then map it back as the sprite ext-palette.
Video.setBankF(VRAM_F_LCD)
OAM.setExtPaletteF(palette: 0, index: 1, color: Color(r: 31, g: 0, b: 0))
OAM.setExtPaletteF(palette: 1, index: 1, color: Color(r: 0, g: 31, b: 0))
Video.setBankF(VRAM_F_SPRITE_EXT_PALETTE)

while System.mainLoop {
	Keys.scan()
	let held = Keys.held
	if held.contains(.touch) { _ = Touch.read(into: &touch) }
	if held.contains(.start) { break }

	main.set(id: 0, x: Int32(touch.px), y: Int32(touch.py), priority: 0,
	         paletteAlpha: 0,   // palette 0
	         size: SpriteSize_16x16, format: .color256, gfx: gfx1)

	main.set(id: 1, x: 256 - Int32(touch.px), y: 192 - Int32(touch.py), priority: 0,
	         paletteAlpha: 1,   // palette 1
	         size: SpriteSize_16x16, format: .color256, gfx: gfx2)

	System.waitForVBlank()
	main.update()
}
