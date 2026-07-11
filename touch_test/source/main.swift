//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Touch_Pad/touch_test example.
//
//  Shows raw + calibrated touch coordinates, tracks the min/max seen, and moves
//  a ball sprite (a grit-converted PNG) to the stylus. R toggles continuous vs.
//  single-shot sampling.
//
//---------------------------------------------------------------------------------

import NDS

// Touch sampling mode (the original's anonymous enum CONTINUOUS=0 / SINGLE=1).
let CONTINUOUS: UInt32 = 0
let SINGLE: UInt32 = 1
var touchType = CONTINUOUS

var minX = 4096, minY = 4096, maxX = 0, maxY = 0
var minPX = 4096, minPY = 4096, maxPX = 0, maxPY = 0
var touch = touchPosition()

// put the main screen on the bottom lcd
System.lcdMainOnBottom()

Video.setMode(.mode0_2D)

// Sprite initialisation
let main = OAM.main
main.initialize(mapping: SpriteMapping_1D_32)

// enable vram and map it to the right places
Video.setPrimaryBanks(VRAM_A_MAIN_BG,     // map A to background memory
                      VRAM_B_MAIN_SPRITE, // map B to sprite memory
                      VRAM_C_LCD,         // not using C
                      VRAM_D_LCD)         // not using D

// load sprite palette and graphics from the grit-generated arrays
let palette = OAM.mainPalette!
withUnsafeBytes(of: ballPal) { raw in
	let src = raw.bindMemory(to: UInt16.self)
	for i in 0 ..< 256 { palette[i] = src[i] }
}

let gfx = OAM.mainGfx!
withUnsafeBytes(of: ballTiles) { raw in
	let src = raw.bindMemory(to: UInt16.self)
	for i in 0 ..< (32 * 16) { gfx[i] = src[i] }
}

// initialise console background
Console.initialize(nil, layer: 0, kind: .text4bpp, size: BgSize_T_256x256, mapBase: 31, tileBase: 0, mainDisplay: true)

Console.print("\u{1b}[4;8HTouch Screen Test")
Console.print("\u{1b}[15;4HRight Shoulder toggles")

while System.mainLoop {
	System.waitForVBlank()
	main.update()

	Keys.scan()
	_ = Touch.read(into: &touch)

	let pressed = Keys.down
	let held = Keys.held

	// Right shoulder toggles the mode; START exits.
	if pressed.contains(.r) { touchType ^= SINGLE }
	if pressed.contains(.start) { break }

	Console.print("\u{1b}[14;4HTouch mode: ")
	Console.print(touchType == CONTINUOUS ? "CONTINUOUS " : "SINGLE SHOT")

	Console.printf("\u{1b}[6;5HTouch x = %04X, %04X\n", Int32(touch.rawx), Int32(touch.px))
	Console.printf("\u{1b}[7;5HTouch y = %04X, %04X\n", Int32(touch.rawy), Int32(touch.py))
	Console.printf("\u{1b}[0;18Hkeys: %08lX\n", Int32(bitPattern: held.rawValue))

	if touchType == SINGLE && !pressed.contains(.touch) { continue }
	if !held.contains(.touch) || touch.rawx == 0 || touch.rawy == 0 { continue }

	Console.printf("\u{1b}[12;12H(%d,%d)      ", Int32(touch.px), Int32(touch.py))

	if Int(touch.rawx) > maxX { maxX = Int(touch.rawx) }
	if Int(touch.rawy) > maxY { maxY = Int(touch.rawy) }
	if Int(touch.px) > maxPX { maxPX = Int(touch.px) }
	if Int(touch.py) > maxPY { maxPY = Int(touch.py) }

	if Int(touch.rawx) < minX { minX = Int(touch.rawx) }
	if Int(touch.rawy) < minY { minY = Int(touch.rawy) }
	if Int(touch.px) < minPX { minPX = Int(touch.px) }
	if Int(touch.py) < minPY { minPY = Int(touch.py) }

	Console.printf("\u{1b}[0;0H(%d,%d)      ", Int32(minPX), Int32(minPY))
	Console.printf("\u{1b}[1;0H(%d,%d)      ", Int32(minX), Int32(minY))
	Console.printf("\u{1b}[22;21H(%d,%d)", Int32(maxX), Int32(maxY))
	Console.printf("\u{1b}[23;23H(%d,%d)", Int32(maxPX), Int32(maxPY))

	// Move and display the sprite
	main.set(id: 0,
	         x: Int32((Int(touch.px) - 16) & 0x01FF), // X position
	         y: Int32((Int(touch.py) - 16) & 0x00FF), // Y position
	         priority: 0, paletteAlpha: 0,
	         size: SpriteSize_32x32, format: .color256,
	         gfx: gfx)
}
