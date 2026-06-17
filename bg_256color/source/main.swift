//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 256_color_bmp example.
//
//  Shows an 8bpp (256-colour) bitmap on a main-screen bitmap background.
//
//---------------------------------------------------------------------------------

import CNDS

videoSetMode(MODE_5_2D.rawValue)
vramSetBankA(VRAM_A_MAIN_BG_0x06000000)

consoleDemoInit()
nds_puts("\n\n\tHello DS devers\n")
nds_puts("\twww.drunkencoders.com\n")
nds_puts("\t256 color bitmap demo")

let bg3 = bgInit(3, BgType_Bmp8, BgSize_B8_256x256, 0, 0)

dmaCopy(nds_asset_drunkenlogoBitmap(), bgGetGfxPtr(bg3), 256 * 256)
dmaCopy(nds_asset_drunkenlogoPal(), nds_bg_palette(), 256 * 2)

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
