//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Backgrounds/rotation example.
//
//  An 8bpp bitmap background (drunkenlogo.bin + palette.bin, raw blobs) shown on
//  a rotation/scale background. L/R rotate, D-pad scrolls, A/B and X/Y scale.
//
//---------------------------------------------------------------------------------

import NDS

Video.setMode(.mode5_2D)

Video.setBankA(VRAM_A_MAIN_BG)

Console.demoInit()

let bg3 = Background.main(layer: 3, kind: .bmp8, size: BgSize_B8_256x256, mapBase: 0, tileBase: 0)

DMA.copy(from: nds_asset_drunkenlogo_bin(), to: bg3.gfxPointer!, size: 256 * 256)
DMA.copy(from: nds_asset_palette_bin(), to: Background.palette!, size: 256 * 2)

var angle: Int16 = 0

// the screen origin is the rotation center; offset so the image is centred
var scrollX: Int16 = 128
var scrollY: Int16 = 128

// scale is fixed point
var scaleX: Int16 = 1 << 8
var scaleY: Int16 = 1 << 8

// the screen pixel the image rotates about
var rcX: Int16 = 128
var rcY: Int16 = 96

while System.mainLoop {
	Console.print("\n\n\tHello DS devers\n")
	Console.print("\twww.drunkencoders.com\n")
	Console.print("\tBG Rotation demo\n")

	Console.printf("Angle %3d(actual) %3d(degrees)\n", Int32(angle), (Int32(angle) * 360) / (1 << 15))
	Console.printf("Scroll  X: %4d Y: %4d\n", Int32(scrollX), Int32(scrollY))
	Console.printf("Rot center X: %4d Y: %4d\n", Int32(rcX), Int32(rcY))
	Console.printf("Scale X: %4d Y: %4d\n", Int32(scaleX), Int32(scaleY))

	Keys.scan()
	let keys = Keys.held

	if keys.contains(.l) { angle &+= 20 }
	if keys.contains(.r) { angle &-= 20 }
	if keys.contains(.left) { scrollX += 1 }
	if keys.contains(.right) { scrollX -= 1 }
	if keys.contains(.up) { scrollY += 1 }
	if keys.contains(.down) { scrollY -= 1 }
	if keys.contains(.a) { scaleX += 1 }
	if keys.contains(.b) { scaleX -= 1 }
	if keys.contains(.start) { rcX += 1 }
	if keys.contains(.select) { rcY += 1 }
	if keys.contains(.x) { scaleY += 1 }
	if keys.contains(.y) { scaleY -= 1 }

	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }

	bg3.setCenter(x: Int32(rcX), y: Int32(rcY))
	bg3.setRotateScale(angle: Int32(angle), sx: Int32(scaleX), sy: Int32(scaleY))
	bg3.setScroll(x: Int32(scrollX), y: Int32(scrollY))
	Background.update()

	// clear the console screen (ansi escape sequence)
	Console.print("\u{1b}[2J")
}
