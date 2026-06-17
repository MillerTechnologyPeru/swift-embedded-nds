//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Double_Buffer example.
//
//  Draws random noise into an off-screen back buffer, then flips it on-screen by
//  changing the background's map base -- classic double buffering.
//
//---------------------------------------------------------------------------------

import CNDS

videoSetMode(MODE_5_2D.rawValue)

vramSetPrimaryBanks(VRAM_A_MAIN_BG_0x06000000, VRAM_B_MAIN_BG_0x06020000,
                    VRAM_C_SUB_BG, VRAM_D_LCD)

consoleDemoInit()
nds_puts("\n\n\tHello DS devers\n")
nds_puts("\twww.drunkencoders.com\n")
nds_puts("\tdouble buffer demo")

let bg = bgInit(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0)

var colorMask: Int32 = 0x1F
var backBuffer = bgGetGfxPtr(bg)! + 256 * 256

while pmMainLoop() {
	// draw a box of noise into the back buffer
	for iy in 60 ..< (196 - 60) {
		for ix in 60 ..< (256 - 60) {
			backBuffer[iy * 256 + ix] = UInt16(truncatingIfNeeded: (rand() & colorMask) | (1 << 15))
		}
	}

	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	// the visible buffer becomes the next back buffer
	backBuffer = bgGetGfxPtr(bg)!

	// flip by swapping the map base (each base = 16KB; a screen is 128KB = 8 bases)
	if bgGetMapBase(bg) == 8 {
		bgSetMapBase(bg, 0)
	} else {
		bgSetMapBase(bg, 8)
	}

	colorMask ^= 0x3FF
}
