//---------------------------------------------------------------------------------
//
//  Swift port of the libnds rotscale_text example.
//
//  A custom 8bpp font on an ExRotation text background that can be rotated,
//  scaled and scrolled with the buttons.
//
//---------------------------------------------------------------------------------

import NDS

@inline(__always) func intToFixed(_ n: Int32, _ bits: Int32) -> Int32 { n << bits }

let tileBase: Int32 = 0
let mapBase: Int32 = 20

Video.setMode(raw: 0)
Video.setModeSub(.mode5_2D)
Video.setBankC(VRAM_C_SUB_BG)

let console = Console.initialize(nil, layer: 3, kind: .exRotation, size: BgSize_ER_256x256,
                                 mapBase: mapBase, tileBase: tileBase, mainDisplay: false, loadGraphics: false)

var font = ConsoleFont()
font.gfx = UnsafeMutablePointer(mutating: nds_asset_fontTiles()!.assumingMemoryBound(to: UInt16.self))
font.pal = UnsafeMutablePointer(mutating: nds_asset_fontPal()!.assumingMemoryBound(to: UInt16.self))
font.numChars = 95
font.numColors = UInt16(fontPalLen / 2)
font.bpp = 8
font.asciiOffset = 32
font.convertSingleColor = false
Console.setFont(console, &font)

let bg3 = Background(id: console!.pointee.bgId)

Console.print("Custom Font Demo\n")
Console.print("   by Poffy\n")
Console.print("modified by WinterMute and dovoto\n")
Console.print("for libnds examples\n")

var angle: UInt32 = 0
var scrollX: Int32 = 0
var scrollY: Int32 = 0
var scaleX = intToFixed(1, 8)
var scaleY = intToFixed(1, 8)

while System.mainLoop {
	Keys.scan()
	let keys = Keys.held
	if keys.contains(.start) { break }

	if keys.contains(.l) { angle &+= 64 }
	if keys.contains(.r) { angle &-= 64 }
	if keys.contains(.left) { scrollX += 1 }
	if keys.contains(.right) { scrollX -= 1 }
	if keys.contains(.up) { scrollY += 1 }
	if keys.contains(.down) { scrollY -= 1 }
	if keys.contains(.a) { scaleX += 1 }
	if keys.contains(.b) { scaleX -= 1 }
	if keys.contains(.x) { scaleY += 1 }
	if keys.contains(.y) { scaleY -= 1 }

	System.waitForVBlank()

	bg3.setRotateScale(angle: Int32(bitPattern: angle), sx: scaleX, sy: scaleY)
	bg3.setScroll(x: scrollX, y: scrollY)
	Background.update()
}
