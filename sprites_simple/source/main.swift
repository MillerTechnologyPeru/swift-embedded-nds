//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Sprites/simple example.
//
//  A 16x16 sprite (filled procedurally, no external assets) follows the stylus
//  on both screens -- red on the main engine, green on the sub engine.
//
//---------------------------------------------------------------------------------

import NDS

var touch = touchPosition()

Video.setMode(.mode0_2D)
Video.setModeSub(.mode0_2D)

Video.setBankA(VRAM_A_MAIN_SPRITE)
Video.setBankD(VRAM_D_SUB_SPRITE)

let main = OAM.main
let sub = OAM.sub
main.initialize(mapping: SpriteMapping_1D_32)
sub.initialize(mapping: SpriteMapping_1D_32)

let gfx = main.allocateGfx(size: SpriteSize_16x16, format: .color256)!
let gfxSub = sub.allocateGfx(size: SpriteSize_16x16, format: .color256)!

// fill both tiles with palette index 1 (two pixels packed per u16)
for i in 0 ..< (16 * 16 / 2) {
	gfx[i] = 1 | (1 << 8)
	gfxSub[i] = 1 | (1 << 8)
}

OAM.mainPalette![1] = Color(r: 31, g: 0, b: 0).rawValue
OAM.subPalette![1] = Color(r: 0, g: 31, b: 0).rawValue

while System.mainLoop {
	Keys.scan()

	let held = Keys.held

	if held.contains(.touch) {
		_ = Touch.read(into: &touch)
	}

	if held.contains(.start) { break }

	main.set(id: 0,                          // oam index (0 to 127)
	         x: Int32(touch.px), y: Int32(touch.py),
	         priority: 0, paletteAlpha: 0,
	         size: SpriteSize_16x16, format: .color256,
	         gfx: gfx)

	sub.set(id: 0,
	        x: Int32(touch.px), y: Int32(touch.py),
	        priority: 0, paletteAlpha: 0,
	        size: SpriteSize_16x16, format: .color256,
	        gfx: gfxSub)

	System.waitForVBlank()

	main.update()
	sub.update()
}
