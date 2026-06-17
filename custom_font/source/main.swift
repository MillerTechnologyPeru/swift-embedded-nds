//---------------------------------------------------------------------------------
//
//  Swift port of the libnds custom_font example.
//
//  Replaces the console font with a grit-converted bitmap font.
//
//---------------------------------------------------------------------------------

import CNDS

let tileBase: Int32 = 0
let mapBase: Int32 = 20

videoSetModeSub(MODE_0_2D.rawValue)
vramSetBankC(VRAM_C_SUB_BG)

let console = consoleInit(nil, 0, BgType_Text4bpp, BgSize_T_256x256, mapBase, tileBase, false, false)

// consoleSetFont copies the font into VRAM, so the asset pointers only need to
// be valid for the duration of that call -- which is exactly the closure scope.
var font = ConsoleFont()
withUnsafeBytes(of: fontTiles) { gfxRaw in
	withUnsafeBytes(of: fontPal) { palRaw in
		font.gfx = UnsafeMutablePointer(mutating: gfxRaw.bindMemory(to: UInt16.self).baseAddress)
		font.pal = UnsafeMutablePointer(mutating: palRaw.bindMemory(to: UInt16.self).baseAddress)
		font.numChars = 95
		font.numColors = UInt16(fontPalLen / 2)
		font.bpp = 4
		font.asciiOffset = 32
		font.convertSingleColor = false

		consoleSetFont(console, &font)
	}
}

nds_puts("Custom Font Demo\n")
nds_puts("   by Poffy\n")
nds_puts("modified by WinterMute\n")
nds_puts("for libnds examples\n")

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()

	if keysDown() & KEY_START != 0 { break }
}
