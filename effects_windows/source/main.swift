//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Effects/windows example.
//
//  A hardware display window reveals a bitmap background inside a movable box.
//  D-pad moves it, A/B resize, X/Y flip which side the BG shows on.
//
//---------------------------------------------------------------------------------

import CNDS

videoSetMode(MODE_5_2D.rawValue)
vramSetBankA(VRAM_A_MAIN_BG)

let bg3 = bgInit(3, BgType_Bmp8, BgSize_B8_256x256, 0, 0)

dmaCopy(nds_asset_drunkenlogoBitmap(), bgGetGfxPtr(bg3), UInt32(drunkenlogoBitmapLen))
dmaCopy(nds_asset_drunkenlogoPal(), nds_bg_palette(), UInt32(drunkenlogoPalLen))

windowEnable(WINDOW_0)
bgWindowEnable(bg3, WINDOW_0)

var x: Int32 = 60
var y: Int32 = 60
var size: Int32 = 100

while pmMainLoop() {
	scanKeys()
	let keys = keysHeld()
	if keys & KEY_START != 0 { break }

	if keys & KEY_UP != 0 { y -= 1 }
	if keys & KEY_DOWN != 0 { y += 1 }
	if keys & KEY_LEFT != 0 { x -= 1 }
	if keys & KEY_RIGHT != 0 { x += 1 }
	if keys & KEY_A != 0 { size -= 1 }
	if keys & KEY_B != 0 { size += 1 }

	if keys & KEY_X != 0 {
		bgWindowDisable(bg3, WINDOW_OUT)
		bgWindowEnable(bg3, WINDOW_0)
	}
	if keys & KEY_Y != 0 {
		bgWindowDisable(bg3, WINDOW_0)
		bgWindowEnable(bg3, WINDOW_OUT)
	}

	if x < 0 { x = 0 }
	if x > 255 { x = 255 }   // SCREEN_WIDTH - 1
	if y < 0 { y = 0 }
	if y > 191 { y = 191 }   // SCREEN_HEIGHT - 1

	threadWaitForVBlank()

	windowSetBounds(WINDOW_0,
	                UInt8(x), UInt8(y),
	                UInt8(truncatingIfNeeded: x + size), UInt8(truncatingIfNeeded: y + size))
}
