//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Double_Buffer example.
//
//  Draws random noise into an off-screen back buffer, then flips it on-screen by
//  changing the background's map base -- classic double buffering.
//
//---------------------------------------------------------------------------------

import NDS

Video.setMode(.mode5_2D)

Video.setPrimaryBanks(VRAM_A_MAIN_BG_0x06000000, VRAM_B_MAIN_BG_0x06020000,
                      VRAM_C_SUB_BG, VRAM_D_LCD)

Console.demoInit()
Console.print("\n\n\tHello DS devers\n")
Console.print("\twww.drunkencoders.com\n")
Console.print("\tdouble buffer demo")

let bg = Background.main(layer: 3, kind: .bmp16, size: BgSize_B16_256x256, mapBase: 0, tileBase: 0)

var colorMask: Int32 = 0x1F
var backBuffer = bg.gfxPointer! + 256 * 256

while System.mainLoop {
	// draw a box of noise into the back buffer
	for iy in 60 ..< (196 - 60) {
		for ix in 60 ..< (256 - 60) {
			backBuffer[iy * 256 + ix] = UInt16(truncatingIfNeeded: (rand() & colorMask) | (1 << 15))
		}
	}

	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }

	// the visible buffer becomes the next back buffer
	backBuffer = bg.gfxPointer!

	// flip by swapping the map base (each base = 16KB; a screen is 128KB = 8 bases)
	if bg.mapBase == 8 {
		bg.mapBase = 0
	} else {
		bg.mapBase = 8
	}

	colorMask ^= 0x3FF
}
