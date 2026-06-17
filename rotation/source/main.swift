//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Backgrounds/rotation example.
//
//  An 8bpp bitmap background (drunkenlogo.bin + palette.bin, raw blobs) shown on
//  a rotation/scale background. L/R rotate, D-pad scrolls, A/B and X/Y scale.
//
//---------------------------------------------------------------------------------

import CNDS

videoSetMode(MODE_5_2D.rawValue)

vramSetBankA(VRAM_A_MAIN_BG)

consoleDemoInit()

let bg3 = bgInit(3, BgType_Bmp8, BgSize_B8_256x256, 0, 0)

dmaCopy(nds_asset_drunkenlogo_bin(), bgGetGfxPtr(bg3), 256 * 256)
dmaCopy(nds_asset_palette_bin(), nds_bg_palette(), 256 * 2)

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

while pmMainLoop() {
	nds_puts("\n\n\tHello DS devers\n")
	nds_puts("\twww.drunkencoders.com\n")
	nds_puts("\tBG Rotation demo\n")

	nds_printf_2i("Angle %3d(actual) %3d(degrees)\n", Int32(angle), (Int32(angle) * 360) / (1 << 15))
	nds_printf_2i("Scroll  X: %4d Y: %4d\n", Int32(scrollX), Int32(scrollY))
	nds_printf_2i("Rot center X: %4d Y: %4d\n", Int32(rcX), Int32(rcY))
	nds_printf_2i("Scale X: %4d Y: %4d\n", Int32(scaleX), Int32(scaleY))

	scanKeys()
	let keys = keysHeld()

	if keys & KEY_L != 0 { angle &+= 20 }
	if keys & KEY_R != 0 { angle &-= 20 }
	if keys & KEY_LEFT != 0 { scrollX += 1 }
	if keys & KEY_RIGHT != 0 { scrollX -= 1 }
	if keys & KEY_UP != 0 { scrollY += 1 }
	if keys & KEY_DOWN != 0 { scrollY -= 1 }
	if keys & KEY_A != 0 { scaleX += 1 }
	if keys & KEY_B != 0 { scaleX -= 1 }
	if keys & KEY_START != 0 { rcX += 1 }
	if keys & KEY_SELECT != 0 { rcY += 1 }
	if keys & KEY_X != 0 { scaleY += 1 }
	if keys & KEY_Y != 0 { scaleY -= 1 }

	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	bgSetCenter(bg3, Int32(rcX), Int32(rcY))
	bgSetRotateScale(bg3, Int32(angle), Int32(scaleX), Int32(scaleY))
	bgSetScroll(bg3, Int32(scrollX), Int32(scrollY))
	bgUpdate()

	// clear the console screen (ansi escape sequence)
	nds_puts("\u{1b}[2J")
}
