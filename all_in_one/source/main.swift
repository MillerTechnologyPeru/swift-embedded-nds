//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Backgrounds/all_in_one example (dovoto).
//
//  A category/demo menu (console on the sub screen) driving ~40 background demos
//  on the main screen: every text/rotation/ext-rotation/bitmap size, hardware and
//  software scrolling of large maps, mosaic, rotation, scaling, extended palettes,
//  and multi-layer compositing. Asset tile/map/palette data comes from the three
//  pre-assembled grit `.s` files (exposed via nds_asset_* accessors).
//
//  Menu: Up/Down select, A enter, B back. Each demo: arrow keys, B to exit.
//
//---------------------------------------------------------------------------------

import CNDS
import _Volatile

//---------------------------------------------------------------------------------
// Hardware registers used for direct scrolling (to contrast with bgSetScroll).
//---------------------------------------------------------------------------------
let REG_BG0HOFS = VolatileMappedRegister<UInt16>(unsafeBitPattern: 0x04000010)
let REG_BG0VOFS = VolatileMappedRegister<UInt16>(unsafeBitPattern: 0x04000012)
let REG_BG3X    = VolatileMappedRegister<UInt32>(unsafeBitPattern: 0x04000038)
let REG_BG3Y    = VolatileMappedRegister<UInt32>(unsafeBitPattern: 0x0400003C)

let BG_WRAP_ON: UInt16 = 1 << 13
let vramE = UnsafeMutablePointer<UInt16>(bitPattern: 0x06880000)!   // VRAM_E base

@inline(__always) func RGB15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func u16(_ p: UnsafeRawPointer) -> UnsafePointer<UInt16> {
	p.assumingMemoryBound(to: UInt16.self)
}
@inline(__always) func bgPal() -> UnsafeMutablePointer<UInt16> { nds_bg_palette()! }

//---------------------------------------------------------------------------------
// Shared explore loop: scroll a background with the D-pad until B is pressed.
//---------------------------------------------------------------------------------
func scroll(_ id: Int32, _ width: Int, _ height: Int) {
	var sx = 0, sy = 0
	while pmMainLoop() {
		scanKeys()
		let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		if keys & KEY_UP    != 0 { sy -= 1 }
		if keys & KEY_DOWN  != 0 { sy += 1 }
		if keys & KEY_LEFT  != 0 { sx -= 1 }
		if keys & KEY_RIGHT != 0 { sx += 1 }
		if sx < 0 { sx = 0 }
		if sx >= width - 256  { sx = width - 1 - 256 }
		if sy < 0 { sy = 0 }
		if sy >= height - 192 { sy = height - 1 - 192 }

		threadWaitForVBlank()
		bgSetScroll(id, Int32(sx), Int32(sy))
		bgUpdate()

		consoleClear()
		nds_printf_2i("Scroll x: %d Scroll y: %d\n", Int32(sx), Int32(sy))
		nds_puts("Press 'B' to exit")
	}
}

//---------------------------------------------------------------------------------
// Basic: text backgrounds
//---------------------------------------------------------------------------------
func loadTextBg(_ size: BgSize, _ mapAccessor: UnsafeRawPointer, _ mapLen: Int32) -> Int32 {
	videoSetMode(MODE_0_2D.rawValue)
	vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(0, BgType_Text8bpp, size, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(mapAccessor, bgGetMapPtr(bg), UInt32(mapLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	return bg
}

func Text256x256() { scroll(loadTextBg(BgSize_T_256x256, nds_asset_Layer256x256Map(), Layer256x256MapLen), 256, 256) }
func Text256x512() { scroll(loadTextBg(BgSize_T_256x512, nds_asset_Layer256x512Map(), Layer256x512MapLen), 256, 512) }

// 512-wide text maps are stored in two 32-column halves laid out side by side.
func loadWideTextBg(_ size: BgSize, _ srcMap: UnsafePointer<UInt16>, _ rows: Int) -> Int32 {
	videoSetMode(MODE_0_2D.rawValue)
	vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(0, BgType_Text8bpp, size, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	let map = bgGetMapPtr(bg)!
	for iy in 0 ..< 32 {
		dmaCopy(srcMap + iy * 64,      map + iy * 32,              32 * 2)        // left half
		dmaCopy(srcMap + iy * 64 + 32, map + (32 * 32) + iy * 32,  32 * 2)        // right half
	}
	if rows > 32 {                                                                // 512x512: second screen block
		let map2 = map + 32 * 32 * 2
		for iy in 0 ..< 32 {
			dmaCopy(srcMap + (iy + 32) * 64,      map2 + iy * 32,             32 * 2)
			dmaCopy(srcMap + (iy + 32) * 64 + 32, map2 + (32 * 32) + iy * 32, 32 * 2)
		}
	}
	return bg
}

func Text512x256() { scroll(loadWideTextBg(BgSize_T_512x256, u16(nds_asset_Layer512x256Map()), 32), 512, 256) }
func Text512x512() { scroll(loadWideTextBg(BgSize_T_512x512, u16(nds_asset_Layer512x512Map()), 64), 512, 512) }

// Extended rotation backgrounds (share the text tiles/palette)
func loadExRotBg(_ size: BgSize, _ mapAccessor: UnsafeRawPointer, _ mapLen: Int32, _ tileBase: Int32) -> Int32 {
	videoSetMode(MODE_5_2D.rawValue)
	vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_ExRotation, size, 0, tileBase)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	dmaCopy(mapAccessor, bgGetMapPtr(bg), UInt32(mapLen))
	return bg
}

func ExRot128x128()   { scroll(loadExRotBg(BgSize_ER_128x128,   nds_asset_Layer128x128Map(),   Layer128x128MapLen,   1), 128, 128) }
func ExRot256x256()   { scroll(loadExRotBg(BgSize_ER_256x256,   nds_asset_Layer256x256Map(),   Layer256x256MapLen,   1), 256, 256) }
func ExRot512x512()   { scroll(loadExRotBg(BgSize_ER_512x512,   nds_asset_Layer512x512Map(),   Layer512x512MapLen,   1), 512, 512) }
func ExRot1024x1024() { scroll(loadExRotBg(BgSize_ER_1024x1024, nds_asset_Layer1024x1024Map(), Layer1024x1024MapLen, 2), 1024, 1024) }

// Rotation backgrounds (own tiles/palette, 8-bit affine maps)
func loadRotBg(_ size: BgSize, _ mapAccessor: UnsafeRawPointer, _ mapLen: Int32, _ tileBase: Int32) -> Int32 {
	videoSetMode(MODE_2_2D.rawValue)
	vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_Rotation, size, 0, tileBase)
	dmaCopy(nds_asset_RotBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(RotBackgroundsTilesLen))
	dmaCopy(nds_asset_RotBackgroundsPal(), bgPal(), UInt32(RotBackgroundsPalLen))
	dmaCopy(mapAccessor, bgGetMapPtr(bg), UInt32(mapLen))
	return bg
}

func Rot128x128()   { scroll(loadRotBg(BgSize_R_128x128,   nds_asset_Layer128x128rMap(),   Layer128x128rMapLen,   1), 128, 128) }
func Rot256x256()   { scroll(loadRotBg(BgSize_R_256x256,   nds_asset_Layer256x256rMap(),   Layer256x256rMapLen,   2), 256, 256) }
func Rot512x512()   { scroll(loadRotBg(BgSize_R_512x512,   nds_asset_Layer512x512rMap(),   Layer512x512rMapLen,   2), 512, 512) }
func Rot1024x1024() { scroll(loadRotBg(BgSize_R_1024x1024, nds_asset_Layer1024x1024rMap(), Layer1024x1024rMapLen, 3), 1024, 1024) }

//---------------------------------------------------------------------------------
// Bitmap backgrounds (filled with random noise)
//---------------------------------------------------------------------------------
@inline(__always) func randPalette() {
	let pal = bgPal()
	for i in 0 ..< 256 { pal[i] = UInt16(truncatingIfNeeded: rand()) }
}
@inline(__always) func fillNoise(_ bg: Int32, _ wordsPerRow: Int, _ rows: Int) {
	let buffer = bgGetGfxPtr(bg)!
	for iy in 0 ..< rows {
		for ix in 0 ..< wordsPerRow { buffer[ix + iy * wordsPerRow] = UInt16(truncatingIfNeeded: rand()) }
	}
}

func Bmp8_128x128() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_Bmp8, BgSize_B8_128x128, 0, 0)
	randPalette(); fillNoise(bg, 64, 128); scroll(bg, 128, 128)
}
func Bmp8_256x256() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_Bmp8, BgSize_B8_256x256, 0, 0)
	randPalette(); fillNoise(bg, 128, 256); scroll(bg, 256, 256)
}
func Bmp8_512x256() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_Bmp8, BgSize_B8_512x256, 0, 0)
	randPalette(); fillNoise(bg, 256, 256); scroll(bg, 512, 256)
}
func Bmp8_512x512() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG); vramSetBankB(VRAM_B_MAIN_BG)
	let bg = bgInit(3, BgType_Bmp8, BgSize_B8_512x512, 0, 0)
	randPalette(); fillNoise(bg, 256, 512); scroll(bg, 512, 512)
}
func Bmp8_512x1024() {
	videoSetMode(MODE_6_2D.rawValue)
	vramSetBankA(VRAM_A_MAIN_BG); vramSetBankB(VRAM_B_MAIN_BG)
	vramSetBankC(VRAM_C_MAIN_BG); vramSetBankD(VRAM_D_MAIN_BG)
	let bg = bgInit(2, BgType_Bmp8, BgSize_B8_512x1024, 0, 0)
	randPalette(); fillNoise(bg, 256, 1024); scroll(bg, 512, 1024)
}
func Bmp8_1024x512() {
	videoSetMode(MODE_6_2D.rawValue)
	vramSetBankA(VRAM_A_MAIN_BG); vramSetBankB(VRAM_B_MAIN_BG)
	vramSetBankC(VRAM_C_MAIN_BG); vramSetBankD(VRAM_D_MAIN_BG)
	let bg = bgInit(2, BgType_Bmp8, BgSize_B8_1024x512, 0, 0)
	randPalette(); fillNoise(bg, 512, 512); scroll(bg, 1024, 512)
}
func Bmp16_128x128() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(2, BgType_Bmp16, BgSize_B16_128x128, 0, 0)
	fillNoise(bg, 128, 128); scroll(bg, 128, 128)
}
func Bmp16_256x256() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(2, BgType_Bmp16, BgSize_B16_256x256, 0, 0)
	fillNoise(bg, 256, 256); scroll(bg, 256, 256)
}
func Bmp16_512x256() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG); vramSetBankB(VRAM_B_MAIN_BG)
	let bg = bgInit(2, BgType_Bmp16, BgSize_B16_512x256, 0, 0)
	fillNoise(bg, 512, 256); scroll(bg, 512, 256)
}
func Bmp16_512x512() {
	videoSetMode(MODE_5_2D.rawValue)
	vramSetBankA(VRAM_A_MAIN_BG); vramSetBankB(VRAM_B_MAIN_BG)
	vramSetBankC(VRAM_C_MAIN_BG); vramSetBankD(VRAM_D_MAIN_BG)
	let bg = bgInit(2, BgType_Bmp16, BgSize_B16_512x512, 0, 0)
	fillNoise(bg, 512, 512); scroll(bg, 512, 512)
}

//---------------------------------------------------------------------------------
// Scrolling demos (hardware registers + streamed large maps)
//---------------------------------------------------------------------------------
func clampScroll(_ v: inout Int, _ span: Int, _ screen: Int) {
	if v < 0 { v = 0 }
	if v >= span - screen { v = span - 1 - screen }
}

func scrollText() {
	videoSetMode(MODE_0_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(0, BgType_Text8bpp, BgSize_T_256x512, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(u16(nds_asset_Layer256x512Map()), bgGetMapPtr(bg), UInt32(Layer256x512MapLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	var sx = 0, sy = 0
	while pmMainLoop() {
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		if keys & KEY_UP != 0 { sy -= 1 }; if keys & KEY_DOWN != 0 { sy += 1 }
		if keys & KEY_LEFT != 0 { sx -= 1 }; if keys & KEY_RIGHT != 0 { sx += 1 }
		clampScroll(&sx, 256, 256); clampScroll(&sy, 512, 192)
		threadWaitForVBlank()
		REG_BG0HOFS.store(UInt16(truncatingIfNeeded: sx))   // direct register access (text BG)
		REG_BG0VOFS.store(UInt16(truncatingIfNeeded: sy))
		consoleClear()
		nds_printf_2i("Scroll x: %d Scroll y: %d\n", Int32(sx), Int32(sy))
		nds_puts("Press 'B' to exit")
	}
}

func scrollRotation() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_ExRotation, BgSize_ER_512x512, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	dmaCopy(nds_asset_Layer512x512Map(), bgGetMapPtr(bg), UInt32(Layer512x512MapLen))
	var sx = 0, sy = 0
	while pmMainLoop() {
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		if keys & KEY_UP != 0 { sy -= 1 }; if keys & KEY_DOWN != 0 { sy += 1 }
		if keys & KEY_LEFT != 0 { sx -= 1 }; if keys & KEY_RIGHT != 0 { sx += 1 }
		clampScroll(&sx, 512, 256); clampScroll(&sy, 512, 192)
		threadWaitForVBlank()
		REG_BG3X.store(UInt32(bitPattern: Int32(sx << 8)))   // affine reference point (rotation BG)
		REG_BG3Y.store(UInt32(bitPattern: Int32(sy << 8)))
		consoleClear()
		nds_printf_2i("Scroll x: %d Scroll y: %d\n", Int32(sx), Int32(sy))
		nds_puts("Press 'B' to exit")
	}
}

func scrollVertical() {
	videoSetMode(MODE_0_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(0, BgType_Text8bpp, BgSize_T_256x256, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	let map = bgGetMapPtr(bg)!
	let layer = u16(nds_asset_Layer256x512Map())
	dmaCopy(layer, map, 32 * 32 * 2)
	var scrollY = 0
	while pmMainLoop() {
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		threadWaitForVBlank()
		if keys & KEY_UP != 0 {
			let offset = scrollY / 8 - 1
			dmaCopy(layer + (offset & 63) * 32, map + (offset & 31) * 32, 32 * 2)
			scrollY -= 1
		}
		if keys & KEY_DOWN != 0 {
			let offset = scrollY / 8 + 24
			dmaCopy(layer + (offset & 63) * 32, map + (offset & 31) * 32, 32 * 2)
			scrollY += 1
		}
		bgSetScroll(bg, 0, Int32(scrollY)); bgUpdate()
	}
}

func scrollHorizontalText() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(0, BgType_Text8bpp, BgSize_T_512x256, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	let map = bgGetMapPtr(bg)!
	let layer = u16(nds_asset_Layer512x256Map())
	for iy in 0 ..< 24 { dmaCopy(layer + iy * 64, map + iy * 32, 32 * 2) }
	var scrollX = 0
	while pmMainLoop() {
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		threadWaitForVBlank()
		if keys & KEY_LEFT != 0 || keys & KEY_RIGHT != 0 {
			let mapOffset = keys & KEY_LEFT != 0 ? scrollX / 8 - 1 : scrollX / 8 + 32
			var layerOffset = mapOffset & 63
			if layerOffset >= 32 { layerOffset += 32 * 32 - 32 }
			for iy in 0 ..< 24 { map[layerOffset + iy * 32] = layer[(mapOffset & 63) + iy * 64] }
			scrollX += keys & KEY_LEFT != 0 ? -1 : 1
		}
		bgSetScroll(bg, Int32(scrollX), 0); bgUpdate()
	}
}

func scrollHorizontalExRotation() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_ExRotation, BgSize_ER_512x512, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	let map = bgGetMapPtr(bg)!
	let layer = u16(nds_asset_Layer512x256Map())
	_ = bgSetControlBits(bg, BG_WRAP_ON)
	for iy in 0 ..< 24 { dmaCopy(layer + iy * 64, map + iy * 64, 32 * 2) }
	var scrollX = 0
	while pmMainLoop() {
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		threadWaitForVBlank()
		if keys & KEY_LEFT != 0 || keys & KEY_RIGHT != 0 {
			let offset = keys & KEY_LEFT != 0 ? scrollX / 8 - 1 : scrollX / 8 + 32
			for iy in 0 ..< 24 { map[(offset & 63) + iy * 64] = layer[(offset & 63) + iy * 64] }
			scrollX += keys & KEY_LEFT != 0 ? -1 : 1
		}
		bgSetScroll(bg, Int32(scrollX), 0); bgUpdate()
	}
}

// 4-way streaming of a 1024x1024 map onto a smaller hardware layer.
func scroll4way(_ exrot: Bool) {
	videoSetMode((exrot ? MODE_5_2D : MODE_0_2D).rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let tileWidth = 8
	let mapWidth = 1024 / 8, mapHeight = 1024 / 8
	let bgW = (exrot ? 512 : 256) / 8, bgH = (exrot ? 512 : 256) / 8
	let screenW = 256 / 8, screenH = 192 / 8

	let bg = exrot ? bgInit(3, BgType_ExRotation, BgSize_ER_512x512, 0, 1)
	                : bgInit(3, BgType_Text8bpp,   BgSize_T_512x256,  0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	let tileMap = bgGetMapPtr(bg)!
	let leftHalf = tileMap, rightHalf = tileMap + 32 * 32
	let layer = u16(nds_asset_Layer1024x1024Map())
	if exrot { _ = bgSetControlBits(bg, BG_WRAP_ON) }

	let rowStride = exrot ? bgW : bgW   // text: dest stride per visible row = bgW
	for iy in 0 ..< screenH { dmaCopy(layer + iy * mapWidth, tileMap + iy * rowStride, UInt32(screenW * 2)) }

	var scrollX = 0, scrollY = 0
	while pmMainLoop() {
		var movingH = false, movingV = false
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		threadWaitForVBlank()

		var offsetX = 0, offsetY = 0
		if keys & KEY_LEFT != 0 {
			offsetX = scrollX / 8 - 1; scrollX -= 1
			if scrollX < 0 { scrollX = 0 } else { movingH = true }
		} else if keys & KEY_RIGHT != 0 {
			offsetX = scrollX / 8 + screenW; scrollX += 1
			if scrollX >= (mapWidth - screenW) * tileWidth { scrollX = (mapWidth - screenW) * tileWidth - 1 } else { movingH = true }
		}
		if keys & KEY_UP != 0 {
			offsetY = scrollY / 8 - 1; scrollY -= 1
			if scrollY < 0 { scrollY = 0 } else { movingV = true }
		} else if keys & KEY_DOWN != 0 {
			offsetY = scrollY / 8 + screenH; scrollY += 1
			if scrollY >= (mapHeight - screenH) * tileWidth { scrollY = (mapHeight - screenH) * tileWidth - 1 } else { movingV = true }
		}

		if movingH {
			for iy in (scrollY / 8 - 1) ..< (scrollY / 8 + screenH + 1) {
				if exrot {
					tileMap[(offsetX & (bgW - 1)) + (iy & (bgH - 1)) * bgW] = layer[offsetX + iy * mapWidth]
				} else {
					let half = (offsetX & 63) >= bgW ? rightHalf : leftHalf
					half[(offsetX & (bgW - 1)) + (iy & (bgH - 1)) * 32] = layer[offsetX + iy * mapWidth]
				}
			}
		}
		if movingV {
			for ix in (scrollX / 8 - 1) ..< (scrollX / 8 + screenW + 1) {
				if exrot {
					tileMap[(ix & (bgW - 1)) + (offsetY & (bgH - 1)) * bgW] = layer[ix + offsetY * mapWidth]
				} else {
					let half = (ix & 63) >= bgW ? rightHalf : leftHalf
					half[(ix & (bgW - 1)) + (offsetY & (bgH - 1)) * 32] = layer[ix + offsetY * mapWidth]
				}
			}
		}
		bgSetScroll(bg, Int32(scrollX), Int32(scrollY)); bgUpdate()
	}
}
func scroll4wayText()       { scroll4way(false) }
func scroll4wayExRotation() { scroll4way(true) }

//---------------------------------------------------------------------------------
// Advanced demos
//---------------------------------------------------------------------------------
func advMosaic() {
	let bg = loadTextBg(BgSize_T_256x256, nds_asset_Layer256x256Map(), Layer256x256MapLen)
	bgMosaicEnable(bg)
	var mx = 0, my = 0
	while pmMainLoop() {
		scanKeys(); let keys = keysDown()
		if keys & KEY_B != 0 { break }
		if keys & KEY_UP != 0 { my -= 1 }; if keys & KEY_DOWN != 0 { my += 1 }
		if keys & KEY_LEFT != 0 { mx -= 1 }; if keys & KEY_RIGHT != 0 { mx += 1 }
		mx = max(0, min(15, mx)); my = max(0, min(15, my))
		threadWaitForVBlank()
		bgSetMosaic(UInt32(mx), UInt32(my))
		consoleClear()
		nds_puts("Press B to exit\n")
		nds_printf_2i("DX: %d  DY: %d", Int32(mx), Int32(my))
	}
}

func advRotating() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_ExRotation, BgSize_ER_256x256, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	dmaCopy(nds_asset_Layer256x256Map(), bgGetMapPtr(bg), UInt32(Layer256x256MapLen))
	bgMosaicEnable(bg)
	var angle = 0, cx = 0, cy = 0
	while pmMainLoop() {
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		if keys & KEY_UP != 0 { cy -= 1 }; if keys & KEY_DOWN != 0 { cy += 1 }
		if keys & KEY_LEFT != 0 { cx -= 1 }; if keys & KEY_RIGHT != 0 { cx += 1 }
		if keys & KEY_L != 0 { angle -= 40 }; if keys & KEY_R != 0 { angle += 40 }
		cx = max(0, min(256, cx)); cy = max(0, min(192, cy))
		threadWaitForVBlank()
		bgSetRotate(bg, Int32(angle))
		bgSetScroll(bg, Int32(cx), Int32(cy))
		bgSetCenter(bg, Int32(cx), Int32(cy))
		bgUpdate()
		consoleClear()
		nds_printf_1i("Angle: %d \n", Int32(angle * 360 / 32768))
		nds_printf_2i("center X: %d  center Y: %d", Int32(cx), Int32(cy))
	}
}

func advScaling() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(3, BgType_ExRotation, BgSize_ER_256x256, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_TextBackgroundsPal(), bgPal(), UInt32(TextBackgroundsPalLen))
	dmaCopy(nds_asset_Layer256x256Map(), bgGetMapPtr(bg), UInt32(Layer256x256MapLen))
	bgMosaicEnable(bg)
	var scaleX: Int32 = 1 << 8, scaleY: Int32 = 1 << 8
	while pmMainLoop() {
		scanKeys(); let keys = keysHeld()
		if keys & KEY_B != 0 { break }
		if keys & KEY_UP != 0 { scaleY += 1 }; if keys & KEY_DOWN != 0 { scaleY -= 1 }
		if keys & KEY_LEFT != 0 { scaleX += 1 }; if keys & KEY_RIGHT != 0 { scaleX -= 1 }
		threadWaitForVBlank()
		bgSetScale(bg, scaleX, scaleY); bgUpdate()
		consoleClear()
		nds_puts("Press B to exit.\n")
		nds_printf_2i("scale X: %d  scale Y: %d", scaleX, scaleY)
	}
}

func advExtendedPalette() {
	videoSetMode(MODE_0_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	bgExtPaletteEnable()
	let bg = bgInit(0, BgType_Text8bpp, BgSize_T_256x256, 0, 1)
	dmaCopy(nds_asset_TextBackgroundsTiles(), bgGetGfxPtr(bg), UInt32(TextBackgroundsTilesLen))
	dmaCopy(nds_asset_Layer256x256Map(), bgGetMapPtr(bg), UInt32(Layer256x256MapLen))
	// lock VRAM E for CPU access, fill slot 0, then map it as the BG ext palette
	vramSetBankE(VRAM_E_LCD)
	dmaCopy(nds_asset_TextBackgroundsPal(), vramE, UInt32(TextBackgroundsPalLen))
	vramSetBankE(VRAM_E_BG_EXT_PALETTE)
	scroll(bg, 256, 256)
}

func advMultipleLayers() {
	videoSetMode(MODE_5_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg1 = bgInit(0, BgType_Text8bpp,   BgSize_ER_256x256, 0, 1)
	let bg2 = bgInit(1, BgType_Text8bpp,   BgSize_ER_256x256, 1, 1)
	let bg3 = bgInit(2, BgType_ExRotation, BgSize_ER_256x256, 2, 1)
	bgSetPriority(bg1, 3); bgSetPriority(bg2, 2); bgSetPriority(bg3, 1)
	dmaCopy(nds_asset_MultilayerTiles(), bgGetGfxPtr(bg1), UInt32(MultilayerTilesLen))
	dmaCopy(nds_asset_MultilayerPal(), bgPal(), UInt32(MultilayerPalLen))
	dmaCopy(nds_asset_Layer_1Map(), bgGetMapPtr(bg1), UInt32(Layer_1MapLen))
	dmaCopy(nds_asset_Layer_2Map(), bgGetMapPtr(bg2), UInt32(Layer_2MapLen))
	dmaCopy(nds_asset_Layer_3Map(), bgGetMapPtr(bg3), UInt32(Layer_3MapLen))
	var h1 = false, h2 = false, h3 = false
	while pmMainLoop() {
		scanKeys(); let keys = keysDown()
		if keys & KEY_B != 0 { break }
		if keys & KEY_UP != 0 { h1.toggle() }
		if keys & KEY_DOWN != 0 { h2.toggle() }
		if keys & KEY_LEFT != 0 { h3.toggle() }
		threadWaitForVBlank()
		h1 ? bgHide(bg1) : bgShow(bg1)
		h2 ? bgHide(bg2) : bgShow(bg2)
		h3 ? bgHide(bg3) : bgShow(bg3)
		consoleClear()
		nds_puts("Press UP DOWN LEFT to toggle the layers\n\n")
		nds_printf_str("Floor (UP): %s\n", h1 ? "hidden" : "displayed")
		nds_printf_str("Walls (DOWN): %s\n", h2 ? "hidden" : "displayed")
		nds_printf_str("Decorations (LEFT): %s\n", h3 ? "hidden" : "displayed")
	}
}

func handMadeTiles() {
	videoSetMode(MODE_0_2D.rawValue); vramSetBankA(VRAM_A_MAIN_BG)
	let bg = bgInit(0, BgType_Text8bpp, BgSize_T_256x256, 0, 1)

	// 4 hand-built 8x8 tiles (transparent, colour 1, colour 2, smiley)
	var tiles = [UInt8](repeating: 0, count: 4 * 64)
	for i in 0 ..< 64 { tiles[64 + i] = 1; tiles[128 + i] = 2 }
	let smiley: [UInt8] = [
		0,0,1,1,1,1,0,0,  0,1,1,1,1,1,1,0,  1,1,2,1,1,2,1,1,  1,1,1,1,1,1,1,1,
		1,1,1,1,1,1,1,1,  1,2,1,1,1,1,2,1,  0,1,2,2,2,2,1,0,  0,0,1,1,1,1,0,0,
	]
	for i in 0 ..< 64 { tiles[192 + i] = smiley[i] }
	tiles.withUnsafeBytes { dmaCopy($0.baseAddress, bgGetGfxPtr(bg), UInt32(tiles.count)) }

	// 32x32 map (border of 1s, a few rows/decorations of 2s and 3s)
	var map = [UInt16](repeating: 1, count: 32 * 32)
	for x in 1 ..< 31 {
		map[1 * 32 + x] = 0; map[2 * 32 + x] = 3; map[3 * 32 + x] = 2
		map[4 * 32 + x] = 3; map[5 * 32 + x] = 0; map[6 * 32 + x] = 0; map[7 * 32 + x] = 0
	}
	map.withUnsafeBytes { dmaCopy($0.baseAddress, bgGetMapPtr(bg), UInt32(map.count * 2)) }

	let pal = bgPal()
	pal[0] = RGB15(0, 0, 0); pal[1] = RGB15(31, 31, 0); pal[2] = RGB15(0, 31, 0)
	pal[3] = RGB15(31, 31, 0)
	scroll(bg, 256, 256)
}

//---------------------------------------------------------------------------------
// Menu
//---------------------------------------------------------------------------------
struct Demo { let name: String; let go: () -> Void }
struct Category { let name: String; let demos: [Demo] }

let categories: [Category] = [
	Category(name: "Basic", demos: [
		Demo(name: "Handmade Text 256x256", go: handMadeTiles),
		Demo(name: "Text 256x256", go: Text256x256),
		Demo(name: "Text 256x512", go: Text256x512),
		Demo(name: "Text 512x256", go: Text512x256),
		Demo(name: "Text 512x512", go: Text512x512),
		Demo(name: "Extended Rotation 128x128", go: ExRot128x128),
		Demo(name: "Extended Rotation 256x256", go: ExRot256x256),
		Demo(name: "Extended Rotation 512x512", go: ExRot512x512),
		Demo(name: "Extended Rotation 1024x1024", go: ExRot1024x1024),
		Demo(name: "Rotation 128x128", go: Rot128x128),
		Demo(name: "Rotation 256x256", go: Rot256x256),
		Demo(name: "Rotation 512x512", go: Rot512x512),
		Demo(name: "Rotation 1024x1024", go: Rot1024x1024),
	]),
	Category(name: "Bitmap", demos: [
		Demo(name: "256 color 128x128", go: Bmp8_128x128),
		Demo(name: "256 color 256x256", go: Bmp8_256x256),
		Demo(name: "256 color 512x256", go: Bmp8_512x256),
		Demo(name: "256 color 512x512", go: Bmp8_512x512),
		Demo(name: "256 color 512x1024", go: Bmp8_512x1024),
		Demo(name: "256 color 1024x512", go: Bmp8_1024x512),
		Demo(name: "16-bit color 128x128", go: Bmp16_128x128),
		Demo(name: "16-bit color 256x256", go: Bmp16_256x256),
		Demo(name: "16-bit color 512x256", go: Bmp16_512x256),
		Demo(name: "16-bit color 512x512", go: Bmp16_512x512),
	]),
	Category(name: "Scrolling", demos: [
		Demo(name: "Text Backgrounds", go: scrollText),
		Demo(name: "Rot Backgrounds", go: scrollRotation),
		Demo(name: "Vertical Scrolling", go: scrollVertical),
		Demo(name: "Horizontal Scrolling (Text)", go: scrollHorizontalText),
		Demo(name: "Horizontal Scrolling (ExRot)", go: scrollHorizontalExRotation),
		Demo(name: "4 Way Scrolling (Text)", go: scroll4wayText),
		Demo(name: "4 Way Scrolling (Rotation)", go: scroll4wayExRotation),
	]),
	Category(name: "Advanced", demos: [
		Demo(name: "Mosaic", go: advMosaic),
		Demo(name: "Rotation", go: advRotating),
		Demo(name: "Scaling", go: advScaling),
		Demo(name: "Extended Palette", go: advExtendedPalette),
		Demo(name: "Multiple Text Layers", go: advMultipleLayers),
	]),
	Category(name: "Exit", demos: []),
]

func printMenu(_ marker: Bool, _ index: Int, _ name: String) {
	nds_puts(marker ? "*" : " ")
	nds_printf_1i("%d: ", Int32(index + 1))
	nds_puts(name)
	nds_puts("\n")
}

while pmMainLoop() {
	var selectedCategory = 0
	var selectedDemo = 0
	let catCount = categories.count

	videoSetModeSub(MODE_0_2D.rawValue)
	_ = consoleDemoInit()

	// category selection
	var chosen = false
	while !chosen {
		if !pmMainLoop() { break }
		scanKeys()
		let keys = keysDown()
		if keys & KEY_UP != 0 { selectedCategory -= 1 }
		if keys & KEY_DOWN != 0 { selectedCategory += 1 }
		if keys & KEY_A != 0 { chosen = true }
		if selectedCategory < 0 { selectedCategory = catCount - 1 }
		if selectedCategory >= catCount { selectedCategory = 0 }
		threadWaitForVBlank()
		consoleClear()
		for ci in 0 ..< catCount { printMenu(ci == selectedCategory, ci, categories[ci].name) }
	}

	let demos = categories[selectedCategory].demos
	if demos.isEmpty { break }   // "Exit"

	// demo selection
	chosen = false
	var back = false
	while !chosen {
		if !pmMainLoop() { break }
		scanKeys()
		let keys = keysDown()
		if keys & KEY_UP != 0 { selectedDemo -= 1 }
		if keys & KEY_DOWN != 0 { selectedDemo += 1 }
		if keys & KEY_A != 0 { chosen = true }
		if keys & KEY_B != 0 { back = true; break }
		if selectedDemo < 0 { selectedDemo = demos.count - 1 }
		if selectedDemo >= demos.count { selectedDemo = 0 }
		threadWaitForVBlank()
		consoleClear()
		for di in 0 ..< demos.count { printMenu(di == selectedDemo, di, demos[di].name) }
	}

	if back { continue }

	if chosen {
		consoleClear()
		nds_puts("Use arrow keys to scroll\nPress 'B' to exit")
		demos[selectedDemo].go()
	}
}
