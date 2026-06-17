//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 16bit_color_bmp example.
//
//  Shows a 16bpp direct-colour bitmap (LZ77-compressed by grit) on a main-screen
//  bitmap background, decompressed straight into VRAM.
//
//---------------------------------------------------------------------------------

import CNDS

videoSetMode(MODE_5_2D.rawValue)
videoSetModeSub(MODE_0_2D.rawValue)   // sub bg 0 for the text console

vramSetBankA(VRAM_A_MAIN_BG)

consoleDemoInit()
nds_puts("\n\n\tHello DS devers\n")
nds_puts("\twww.drunkencoders.com\n")
nds_puts("\t16 bit bitmap demo")

bgInit(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0)

decompress(nds_asset_drunkenlogoBitmap(), nds_bg_gfx(), LZ77Vram)

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
