//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 16bit_color_bmp example.
//
//  Shows a 16bpp direct-colour bitmap (LZ77-compressed by grit) on a main-screen
//  bitmap background, decompressed straight into VRAM.
//
//---------------------------------------------------------------------------------

import NDS

Video.setMode(.mode5_2D)
Video.setModeSub(.mode0_2D)   // sub bg 0 for the text console

Video.setBankA(VRAM_A_MAIN_BG)

Console.demoInit()
Console.print("\n\n\tHello DS devers\n")
Console.print("\twww.drunkencoders.com\n")
Console.print("\t16 bit bitmap demo")

_ = Background.main(layer: 3, kind: .bmp16, size: BgSize_B16_256x256, mapBase: 0, tileBase: 0)

Decompress.run(nds_asset_drunkenlogoBitmap(), into: Background.gfx!, kind: .lz77Vram)

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
