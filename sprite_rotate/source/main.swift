//---------------------------------------------------------------------------------
//
//  Swift port of the libnds sprite_rotate example.
//
//  One sprite drawn twice: once with size-doubling (rotates without clipping) and
//  once without (clips at 32x32). L/R rotate.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func intToFixed(_ n: Int32, _ bits: Int32) -> Int32 { n << bits }
@inline(__always) func degreesToAngle(_ d: Int32) -> Int32 { d * (1 << 15) / 360 }

var angle: Int32 = 0

videoSetMode(MODE_0_2D.rawValue)
vramSetBankA(VRAM_A_MAIN_SPRITE)

oamInit(&oamMain, SpriteMapping_1D_32, false)

let gfx = oamAllocateGfx(&oamMain, SpriteSize_32x32, SpriteColorFormat_256Color)!
for i in 0 ..< (32 * 32 / 2) { gfx[i] = 1 | (1 << 8) }

nds_sprite_palette()![1] = rgb15(31, 0, 0)

while pmMainLoop() {
	scanKeys()
	let held = keysHeld()

	if held & KEY_START != 0 { break }
	if held & KEY_LEFT != 0  { angle += degreesToAngle(2) }
	if held & KEY_RIGHT != 0 { angle -= degreesToAngle(2) }

	oamRotateScale(&oamMain, 0, angle, intToFixed(1, 8), intToFixed(1, 8))

	// size-doubled sprite: offset by half so it rotates about its centre
	oamSet(&oamMain, 0, 20 - 16, 20 - 16, 0, 0,
	       SpriteSize_32x32, SpriteColorFormat_256Color, gfx,
	       0, true, false, false, false, false)

	// non-doubled sprite: clips at 32x32 as it spins
	oamSet(&oamMain, 1, 204, 20, 0, 0,
	       SpriteSize_32x32, SpriteColorFormat_256Color, gfx,
	       0, false, false, false, false, false)

	threadWaitForVBlank()
	oamUpdate(&oamMain)
}
