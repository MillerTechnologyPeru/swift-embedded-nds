//---------------------------------------------------------------------------------
//
//  Swift port of the libnds custom_font example.
//
//  Replaces the console font with a grit-converted bitmap font.
//
//---------------------------------------------------------------------------------

import NDS

let tileBase: Int32 = 0
let mapBase: Int32 = 20

Video.setModeSub(.mode0_2D)
Video.setBankC(VRAM_C_SUB_BG)

let console = Console.initialize(nil, layer: 0, kind: .text4bpp, size: BgSize_T_256x256,
                                 mapBase: mapBase, tileBase: tileBase, mainDisplay: false, loadGraphics: false)

// Point the font at the real linked grit symbols via the generated stable-
// pointer accessors (a plain `fontTiles` reference would import as a tuple copy,
// leaving consoleSetFont with a dangling pointer to a stack temporary).
var font = ConsoleFont()
font.gfx = UnsafeMutablePointer(mutating: nds_asset_fontTiles()!.assumingMemoryBound(to: UInt16.self))
font.pal = UnsafeMutablePointer(mutating: nds_asset_fontPal()!.assumingMemoryBound(to: UInt16.self))
font.numChars = 95
font.numColors = UInt16(fontPalLen / 2)
font.bpp = 4
font.asciiOffset = 32
font.convertSingleColor = false

Console.setFont(console, &font)

Console.print("Custom Font Demo\n")
Console.print("   by Poffy\n")
Console.print("modified by WinterMute\n")
Console.print("for libnds examples\n")

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()

	if Keys.down.contains(.start) { break }
}
