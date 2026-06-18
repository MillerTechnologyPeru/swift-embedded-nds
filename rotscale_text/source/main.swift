//---------------------------------------------------------------------------------
//
//  Swift port of the libnds rotscale_text example.
//
//  A custom 8bpp font on an ExRotation text background that can be rotated,
//  scaled and scrolled with the buttons.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func intToFixed(_ n: Int32, _ bits: Int32) -> Int32 { n << bits }

let tileBase: Int32 = 0
let mapBase: Int32 = 20

videoSetMode(0)
videoSetModeSub(MODE_5_2D.rawValue)
vramSetBankC(VRAM_C_SUB_BG)

let console = consoleInit(nil, 3, BgType_ExRotation, BgSize_ER_256x256, mapBase, tileBase, false, false)

var font = ConsoleFont()
font.gfx = UnsafeMutablePointer(mutating: nds_asset_fontTiles()!.assumingMemoryBound(to: UInt16.self))
font.pal = UnsafeMutablePointer(mutating: nds_asset_fontPal()!.assumingMemoryBound(to: UInt16.self))
font.numChars = 95
font.numColors = UInt16(fontPalLen / 2)
font.bpp = 8
font.asciiOffset = 32
font.convertSingleColor = false
consoleSetFont(console, &font)

let bg3 = console!.pointee.bgId

nds_puts("Custom Font Demo\n")
nds_puts("   by Poffy\n")
nds_puts("modified by WinterMute and dovoto\n")
nds_puts("for libnds examples\n")

var angle: UInt32 = 0
var scrollX: Int32 = 0
var scrollY: Int32 = 0
var scaleX = intToFixed(1, 8)
var scaleY = intToFixed(1, 8)

while pmMainLoop() {
	scanKeys()
	let keys = keysHeld()
	if keys & KEY_START != 0 { break }

	if keys & KEY_L != 0 { angle &+= 64 }
	if keys & KEY_R != 0 { angle &-= 64 }
	if keys & KEY_LEFT != 0 { scrollX += 1 }
	if keys & KEY_RIGHT != 0 { scrollX -= 1 }
	if keys & KEY_UP != 0 { scrollY += 1 }
	if keys & KEY_DOWN != 0 { scrollY -= 1 }
	if keys & KEY_A != 0 { scaleX += 1 }
	if keys & KEY_B != 0 { scaleX -= 1 }
	if keys & KEY_X != 0 { scaleY += 1 }
	if keys & KEY_Y != 0 { scaleY -= 1 }

	threadWaitForVBlank()

	bgSetRotateScale(bg3, Int32(bitPattern: angle), scaleX, scaleY)
	bgSetScroll(bg3, scrollX, scrollY)
	bgUpdate()
}
