//---------------------------------------------------------------------------------
//
//  Swift port of the libnds sprite_rotate example.
//
//  One sprite drawn twice: once with size-doubling (rotates without clipping) and
//  once without (clips at 32x32). L/R rotate.
//
//---------------------------------------------------------------------------------

import NDS

@inline(__always) func intToFixed(_ n: Int32, _ bits: Int32) -> Int32 { n << bits }
@inline(__always) func degreesToAngle(_ d: Int32) -> Int32 { d * (1 << 15) / 360 }

var angle: Int32 = 0

Video.setMode(.mode0_2D)
Video.setBankA(VRAM_A_MAIN_SPRITE)

let main = OAM.main
main.initialize(mapping: SpriteMapping_1D_32)

let gfx = main.allocateGfx(size: SpriteSize_32x32, format: .color256)!
for i in 0 ..< (32 * 32 / 2) { gfx[i] = 1 | (1 << 8) }

OAM.mainPalette![1] = Color(r: 31, g: 0, b: 0).rawValue

while System.mainLoop {
	Keys.scan()
	let held = Keys.held

	if held.contains(.start) { break }
	if held.contains(.left)  { angle += degreesToAngle(2) }
	if held.contains(.right) { angle -= degreesToAngle(2) }

	main.rotateScale(rotId: 0, angle: angle, sx: intToFixed(1, 8), sy: intToFixed(1, 8))

	// size-doubled sprite: offset by half so it rotates about its centre
	main.set(id: 0, x: 20 - 16, y: 20 - 16, priority: 0, paletteAlpha: 0,
	         size: SpriteSize_32x32, format: .color256, gfx: gfx,
	         affineIndex: 0, sizeDouble: true)

	// non-doubled sprite: clips at 32x32 as it spins
	main.set(id: 1, x: 204, y: 20, priority: 0, paletteAlpha: 0,
	         size: SpriteSize_32x32, format: .color256, gfx: gfx,
	         affineIndex: 0)

	System.waitForVBlank()
	main.update()
}
