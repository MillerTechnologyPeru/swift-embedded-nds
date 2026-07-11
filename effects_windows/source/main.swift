//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Effects/windows example.
//
//  A hardware display window reveals a bitmap background inside a movable box.
//  D-pad moves it, A/B resize, X/Y flip which side the BG shows on.
//
//---------------------------------------------------------------------------------

import NDS

Video.setMode(.mode5_2D)
Video.setBankA(VRAM_A_MAIN_BG)

let bg3 = Background.main(layer: 3, kind: .bmp8, size: BgSize_B8_256x256, mapBase: 0, tileBase: 0)

DMA.copy(from: nds_asset_drunkenlogoBitmap(), to: bg3.gfxPointer!, size: UInt32(drunkenlogoBitmapLen))
DMA.copy(from: nds_asset_drunkenlogoPal(), to: Background.palette!, size: UInt32(drunkenlogoPalLen))

Window.enable(.window0)
Window.enableBackground(bg3, in: .window0)

var x: Int32 = 60
var y: Int32 = 60
var size: Int32 = 100

while System.mainLoop {
	Keys.scan()
	let keys = Keys.held
	if keys.contains(.start) { break }

	if keys.contains(.up) { y -= 1 }
	if keys.contains(.down) { y += 1 }
	if keys.contains(.left) { x -= 1 }
	if keys.contains(.right) { x += 1 }
	if keys.contains(.a) { size -= 1 }
	if keys.contains(.b) { size += 1 }

	if keys.contains(.x) {
		Window.disableBackground(bg3, in: .outside)
		Window.enableBackground(bg3, in: .window0)
	}
	if keys.contains(.y) {
		Window.disableBackground(bg3, in: .window0)
		Window.enableBackground(bg3, in: .outside)
	}

	if x < 0 { x = 0 }
	if x > 255 { x = 255 }   // SCREEN_WIDTH - 1
	if y < 0 { y = 0 }
	if y > 191 { y = 191 }   // SCREEN_HEIGHT - 1

	System.waitForVBlank()

	Window.setBounds(.window0,
	                 left: UInt8(x), top: UInt8(y),
	                 right: UInt8(truncatingIfNeeded: x + size), bottom: UInt8(truncatingIfNeeded: y + size))
}
