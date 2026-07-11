//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 256_color_bmp example.
//
//  Shows an 8bpp (256-colour) bitmap on a main-screen bitmap background.
//
//---------------------------------------------------------------------------------

import NDS

Video.setMode(.mode5_2D)
Video.setBankA(VRAM_A_MAIN_BG_0x06000000)

Console.demoInit()
Console.print("\n\n\tHello DS devers\n")
Console.print("\twww.drunkencoders.com\n")
Console.print("\t256 color bitmap demo")

let bg3 = Background.main(layer: 3, kind: .bmp8, size: BgSize_B8_256x256, mapBase: 0, tileBase: 0)

DMA.copy(from: nds_asset_drunkenlogoBitmap(), to: bg3.gfxPointer!, size: 256 * 256)
DMA.copy(from: nds_asset_drunkenlogoPal(), to: Background.palette!, size: 256 * 2)

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
