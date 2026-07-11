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

import NDS
import _Volatile

//---------------------------------------------------------------------------------
// Hardware registers used for direct scrolling (to contrast with bg.setScroll).
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
@inline(__always) func bgPal() -> UnsafeMutablePointer<UInt16> { Background.palette! }

//---------------------------------------------------------------------------------
// Shared explore loop: scroll a background with the D-pad until B is pressed.
//---------------------------------------------------------------------------------
func scroll(_ bg: Background, _ width: Int, _ height: Int) {
	var sx = 0, sy = 0
	while System.mainLoop {
		Keys.scan()
		let keys = Keys.held
		if keys.contains(.b) { break }
		if keys.contains(.up)    { sy -= 1 }
		if keys.contains(.down)  { sy += 1 }
		if keys.contains(.left)  { sx -= 1 }
		if keys.contains(.right) { sx += 1 }
		if sx < 0 { sx = 0 }
		if sx >= width - 256  { sx = width - 1 - 256 }
		if sy < 0 { sy = 0 }
		if sy >= height - 192 { sy = height - 1 - 192 }

		System.waitForVBlank()
		bg.setScroll(x: Int32(sx), y: Int32(sy))
		Background.update()

		Console.clear()
		Console.printf("Scroll x: %d Scroll y: %d\n", Int32(sx), Int32(sy))
		Console.print("Press 'B' to exit")
	}
}

//---------------------------------------------------------------------------------
// Basic: text backgrounds
//---------------------------------------------------------------------------------
func loadTextBg(_ size: BgSize, _ mapAccessor: UnsafeRawPointer, _ mapLen: Int32) -> Background {
	Video.setMode(.mode0_2D)
	Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 0, kind: .text8bpp, size: size, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: mapAccessor, to: bg.mapPointer!, size: UInt32(mapLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	return bg
}

func Text256x256() { scroll(loadTextBg(BgSize_T_256x256, nds_asset_Layer256x256Map(), Layer256x256MapLen), 256, 256) }
func Text256x512() { scroll(loadTextBg(BgSize_T_256x512, nds_asset_Layer256x512Map(), Layer256x512MapLen), 256, 512) }

// 512-wide text maps are stored in two 32-column halves laid out side by side.
func loadWideTextBg(_ size: BgSize, _ srcMap: UnsafePointer<UInt16>, _ rows: Int) -> Background {
	Video.setMode(.mode0_2D)
	Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 0, kind: .text8bpp, size: size, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	let map = bg.mapPointer!
	for iy in 0 ..< 32 {
		DMA.copy(from: srcMap + iy * 64,      to: map + iy * 32,              size: 32 * 2)        // left half
		DMA.copy(from: srcMap + iy * 64 + 32, to: map + (32 * 32) + iy * 32,  size: 32 * 2)        // right half
	}
	if rows > 32 {                                                                // 512x512: second screen block
		let map2 = map + 32 * 32 * 2
		for iy in 0 ..< 32 {
			DMA.copy(from: srcMap + (iy + 32) * 64,      to: map2 + iy * 32,             size: 32 * 2)
			DMA.copy(from: srcMap + (iy + 32) * 64 + 32, to: map2 + (32 * 32) + iy * 32, size: 32 * 2)
		}
	}
	return bg
}

func Text512x256() { scroll(loadWideTextBg(BgSize_T_512x256, u16(nds_asset_Layer512x256Map()), 32), 512, 256) }
func Text512x512() { scroll(loadWideTextBg(BgSize_T_512x512, u16(nds_asset_Layer512x512Map()), 64), 512, 512) }

// Extended rotation backgrounds (share the text tiles/palette)
func loadExRotBg(_ size: BgSize, _ mapAccessor: UnsafeRawPointer, _ mapLen: Int32, _ tileBase: Int32) -> Background {
	Video.setMode(.mode5_2D)
	Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .exRotation, size: size, mapBase: 0, tileBase: tileBase)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	DMA.copy(from: mapAccessor, to: bg.mapPointer!, size: UInt32(mapLen))
	return bg
}

func ExRot128x128()   { scroll(loadExRotBg(BgSize_ER_128x128,   nds_asset_Layer128x128Map(),   Layer128x128MapLen,   1), 128, 128) }
func ExRot256x256()   { scroll(loadExRotBg(BgSize_ER_256x256,   nds_asset_Layer256x256Map(),   Layer256x256MapLen,   1), 256, 256) }
func ExRot512x512()   { scroll(loadExRotBg(BgSize_ER_512x512,   nds_asset_Layer512x512Map(),   Layer512x512MapLen,   1), 512, 512) }
func ExRot1024x1024() { scroll(loadExRotBg(BgSize_ER_1024x1024, nds_asset_Layer1024x1024Map(), Layer1024x1024MapLen, 2), 1024, 1024) }

// Rotation backgrounds (own tiles/palette, 8-bit affine maps)
func loadRotBg(_ size: BgSize, _ mapAccessor: UnsafeRawPointer, _ mapLen: Int32, _ tileBase: Int32) -> Background {
	Video.setMode(.mode2_2D)
	Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .rotation, size: size, mapBase: 0, tileBase: tileBase)
	DMA.copy(from: nds_asset_RotBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(RotBackgroundsTilesLen))
	DMA.copy(from: nds_asset_RotBackgroundsPal(), to: bgPal(), size: UInt32(RotBackgroundsPalLen))
	DMA.copy(from: mapAccessor, to: bg.mapPointer!, size: UInt32(mapLen))
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
@inline(__always) func fillNoise(_ bg: Background, _ wordsPerRow: Int, _ rows: Int) {
	let buffer = bg.gfxPointer!
	for iy in 0 ..< rows {
		for ix in 0 ..< wordsPerRow { buffer[ix + iy * wordsPerRow] = UInt16(truncatingIfNeeded: rand()) }
	}
}

func Bmp8_128x128() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .bmp8, size: BgSize_B8_128x128, mapBase: 0, tileBase: 0)
	randPalette(); fillNoise(bg, 64, 128); scroll(bg, 128, 128)
}
func Bmp8_256x256() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .bmp8, size: BgSize_B8_256x256, mapBase: 0, tileBase: 0)
	randPalette(); fillNoise(bg, 128, 256); scroll(bg, 256, 256)
}
func Bmp8_512x256() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .bmp8, size: BgSize_B8_512x256, mapBase: 0, tileBase: 0)
	randPalette(); fillNoise(bg, 256, 256); scroll(bg, 512, 256)
}
func Bmp8_512x512() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG); Video.setBankB(VRAM_B_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .bmp8, size: BgSize_B8_512x512, mapBase: 0, tileBase: 0)
	randPalette(); fillNoise(bg, 256, 512); scroll(bg, 512, 512)
}
func Bmp8_512x1024() {
	Video.setMode(.mode6_2D)
	Video.setBankA(VRAM_A_MAIN_BG); Video.setBankB(VRAM_B_MAIN_BG)
	Video.setBankC(VRAM_C_MAIN_BG); Video.setBankD(VRAM_D_MAIN_BG)
	let bg = Background.main(layer: 2, kind: .bmp8, size: BgSize_B8_512x1024, mapBase: 0, tileBase: 0)
	randPalette(); fillNoise(bg, 256, 1024); scroll(bg, 512, 1024)
}
func Bmp8_1024x512() {
	Video.setMode(.mode6_2D)
	Video.setBankA(VRAM_A_MAIN_BG); Video.setBankB(VRAM_B_MAIN_BG)
	Video.setBankC(VRAM_C_MAIN_BG); Video.setBankD(VRAM_D_MAIN_BG)
	let bg = Background.main(layer: 2, kind: .bmp8, size: BgSize_B8_1024x512, mapBase: 0, tileBase: 0)
	randPalette(); fillNoise(bg, 512, 512); scroll(bg, 1024, 512)
}
func Bmp16_128x128() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 2, kind: .bmp16, size: BgSize_B16_128x128, mapBase: 0, tileBase: 0)
	fillNoise(bg, 128, 128); scroll(bg, 128, 128)
}
func Bmp16_256x256() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 2, kind: .bmp16, size: BgSize_B16_256x256, mapBase: 0, tileBase: 0)
	fillNoise(bg, 256, 256); scroll(bg, 256, 256)
}
func Bmp16_512x256() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG); Video.setBankB(VRAM_B_MAIN_BG)
	let bg = Background.main(layer: 2, kind: .bmp16, size: BgSize_B16_512x256, mapBase: 0, tileBase: 0)
	fillNoise(bg, 512, 256); scroll(bg, 512, 256)
}
func Bmp16_512x512() {
	Video.setMode(.mode5_2D)
	Video.setBankA(VRAM_A_MAIN_BG); Video.setBankB(VRAM_B_MAIN_BG)
	Video.setBankC(VRAM_C_MAIN_BG); Video.setBankD(VRAM_D_MAIN_BG)
	let bg = Background.main(layer: 2, kind: .bmp16, size: BgSize_B16_512x512, mapBase: 0, tileBase: 0)
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
	Video.setMode(.mode0_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 0, kind: .text8bpp, size: BgSize_T_256x512, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: u16(nds_asset_Layer256x512Map()), to: bg.mapPointer!, size: UInt32(Layer256x512MapLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	var sx = 0, sy = 0
	while System.mainLoop {
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		if keys.contains(.up) { sy -= 1 }; if keys.contains(.down) { sy += 1 }
		if keys.contains(.left) { sx -= 1 }; if keys.contains(.right) { sx += 1 }
		clampScroll(&sx, 256, 256); clampScroll(&sy, 512, 192)
		System.waitForVBlank()
		REG_BG0HOFS.store(UInt16(truncatingIfNeeded: sx))   // direct register access (text BG)
		REG_BG0VOFS.store(UInt16(truncatingIfNeeded: sy))
		Console.clear()
		Console.printf("Scroll x: %d Scroll y: %d\n", Int32(sx), Int32(sy))
		Console.print("Press 'B' to exit")
	}
}

func scrollRotation() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .exRotation, size: BgSize_ER_512x512, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	DMA.copy(from: nds_asset_Layer512x512Map(), to: bg.mapPointer!, size: UInt32(Layer512x512MapLen))
	var sx = 0, sy = 0
	while System.mainLoop {
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		if keys.contains(.up) { sy -= 1 }; if keys.contains(.down) { sy += 1 }
		if keys.contains(.left) { sx -= 1 }; if keys.contains(.right) { sx += 1 }
		clampScroll(&sx, 512, 256); clampScroll(&sy, 512, 192)
		System.waitForVBlank()
		REG_BG3X.store(UInt32(bitPattern: Int32(sx << 8)))   // affine reference point (rotation BG)
		REG_BG3Y.store(UInt32(bitPattern: Int32(sy << 8)))
		Console.clear()
		Console.printf("Scroll x: %d Scroll y: %d\n", Int32(sx), Int32(sy))
		Console.print("Press 'B' to exit")
	}
}

func scrollVertical() {
	Video.setMode(.mode0_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 0, kind: .text8bpp, size: BgSize_T_256x256, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	let map = bg.mapPointer!
	let layer = u16(nds_asset_Layer256x512Map())
	DMA.copy(from: layer, to: map, size: 32 * 32 * 2)
	var scrollY = 0
	while System.mainLoop {
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		System.waitForVBlank()
		if keys.contains(.up) {
			let offset = scrollY / 8 - 1
			DMA.copy(from: layer + (offset & 63) * 32, to: map + (offset & 31) * 32, size: 32 * 2)
			scrollY -= 1
		}
		if keys.contains(.down) {
			let offset = scrollY / 8 + 24
			DMA.copy(from: layer + (offset & 63) * 32, to: map + (offset & 31) * 32, size: 32 * 2)
			scrollY += 1
		}
		bg.setScroll(x: 0, y: Int32(scrollY)); Background.update()
	}
}

func scrollHorizontalText() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 0, kind: .text8bpp, size: BgSize_T_512x256, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	let map = bg.mapPointer!
	let layer = u16(nds_asset_Layer512x256Map())
	for iy in 0 ..< 24 { DMA.copy(from: layer + iy * 64, to: map + iy * 32, size: 32 * 2) }
	var scrollX = 0
	while System.mainLoop {
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		System.waitForVBlank()
		if keys.contains(.left) || keys.contains(.right) {
			let mapOffset = keys.contains(.left) ? scrollX / 8 - 1 : scrollX / 8 + 32
			var layerOffset = mapOffset & 63
			if layerOffset >= 32 { layerOffset += 32 * 32 - 32 }
			for iy in 0 ..< 24 { map[layerOffset + iy * 32] = layer[(mapOffset & 63) + iy * 64] }
			scrollX += keys.contains(.left) ? -1 : 1
		}
		bg.setScroll(x: Int32(scrollX), y: 0); Background.update()
	}
}

func scrollHorizontalExRotation() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .exRotation, size: BgSize_ER_512x512, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	let map = bg.mapPointer!
	let layer = u16(nds_asset_Layer512x256Map())
	_ = bgSetControlBits(bg.id, BG_WRAP_ON)
	for iy in 0 ..< 24 { DMA.copy(from: layer + iy * 64, to: map + iy * 64, size: 32 * 2) }
	var scrollX = 0
	while System.mainLoop {
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		System.waitForVBlank()
		if keys.contains(.left) || keys.contains(.right) {
			let offset = keys.contains(.left) ? scrollX / 8 - 1 : scrollX / 8 + 32
			for iy in 0 ..< 24 { map[(offset & 63) + iy * 64] = layer[(offset & 63) + iy * 64] }
			scrollX += keys.contains(.left) ? -1 : 1
		}
		bg.setScroll(x: Int32(scrollX), y: 0); Background.update()
	}
}

// 4-way streaming of a 1024x1024 map onto a smaller hardware layer.
func scroll4way(_ exrot: Bool) {
	Video.setMode(exrot ? .mode5_2D : .mode0_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let tileWidth = 8
	let mapWidth = 1024 / 8, mapHeight = 1024 / 8
	let bgW = (exrot ? 512 : 256) / 8, bgH = (exrot ? 512 : 256) / 8
	let screenW = 256 / 8, screenH = 192 / 8

	let bg = exrot ? Background.main(layer: 3, kind: .exRotation, size: BgSize_ER_512x512, mapBase: 0, tileBase: 1)
	               : Background.main(layer: 3, kind: .text8bpp,   size: BgSize_T_512x256,  mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	let tileMap = bg.mapPointer!
	let leftHalf = tileMap, rightHalf = tileMap + 32 * 32
	let layer = u16(nds_asset_Layer1024x1024Map())
	if exrot { _ = bgSetControlBits(bg.id, BG_WRAP_ON) }

	let rowStride = exrot ? bgW : bgW   // text: dest stride per visible row = bgW
	for iy in 0 ..< screenH { DMA.copy(from: layer + iy * mapWidth, to: tileMap + iy * rowStride, size: UInt32(screenW * 2)) }

	var scrollX = 0, scrollY = 0
	while System.mainLoop {
		var movingH = false, movingV = false
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		System.waitForVBlank()

		var offsetX = 0, offsetY = 0
		if keys.contains(.left) {
			offsetX = scrollX / 8 - 1; scrollX -= 1
			if scrollX < 0 { scrollX = 0 } else { movingH = true }
		} else if keys.contains(.right) {
			offsetX = scrollX / 8 + screenW; scrollX += 1
			if scrollX >= (mapWidth - screenW) * tileWidth { scrollX = (mapWidth - screenW) * tileWidth - 1 } else { movingH = true }
		}
		if keys.contains(.up) {
			offsetY = scrollY / 8 - 1; scrollY -= 1
			if scrollY < 0 { scrollY = 0 } else { movingV = true }
		} else if keys.contains(.down) {
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
		bg.setScroll(x: Int32(scrollX), y: Int32(scrollY)); Background.update()
	}
}
func scroll4wayText()       { scroll4way(false) }
func scroll4wayExRotation() { scroll4way(true) }

//---------------------------------------------------------------------------------
// Advanced demos
//---------------------------------------------------------------------------------
func advMosaic() {
	let bg = loadTextBg(BgSize_T_256x256, nds_asset_Layer256x256Map(), Layer256x256MapLen)
	bg.mosaic(true)
	var mx = 0, my = 0
	while System.mainLoop {
		Keys.scan(); let keys = Keys.down
		if keys.contains(.b) { break }
		if keys.contains(.up) { my -= 1 }; if keys.contains(.down) { my += 1 }
		if keys.contains(.left) { mx -= 1 }; if keys.contains(.right) { mx += 1 }
		mx = max(0, min(15, mx)); my = max(0, min(15, my))
		System.waitForVBlank()
		Background.setMosaic(dx: UInt32(mx), dy: UInt32(my))
		Console.clear()
		Console.print("Press B to exit\n")
		Console.printf("DX: %d  DY: %d", Int32(mx), Int32(my))
	}
}

func advRotating() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .exRotation, size: BgSize_ER_256x256, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	DMA.copy(from: nds_asset_Layer256x256Map(), to: bg.mapPointer!, size: UInt32(Layer256x256MapLen))
	bg.mosaic(true)
	var angle = 0, cx = 0, cy = 0
	while System.mainLoop {
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		if keys.contains(.up) { cy -= 1 }; if keys.contains(.down) { cy += 1 }
		if keys.contains(.left) { cx -= 1 }; if keys.contains(.right) { cx += 1 }
		if keys.contains(.l) { angle -= 40 }; if keys.contains(.r) { angle += 40 }
		cx = max(0, min(256, cx)); cy = max(0, min(192, cy))
		System.waitForVBlank()
		bg.setRotate(angle: Int32(angle))
		bg.setScroll(x: Int32(cx), y: Int32(cy))
		bg.setCenter(x: Int32(cx), y: Int32(cy))
		Background.update()
		Console.clear()
		Console.printf("Angle: %d \n", Int32(angle * 360 / 32768))
		Console.printf("center X: %d  center Y: %d", Int32(cx), Int32(cy))
	}
}

func advScaling() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 3, kind: .exRotation, size: BgSize_ER_256x256, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: bgPal(), size: UInt32(TextBackgroundsPalLen))
	DMA.copy(from: nds_asset_Layer256x256Map(), to: bg.mapPointer!, size: UInt32(Layer256x256MapLen))
	bg.mosaic(true)
	var scaleX: Int32 = 1 << 8, scaleY: Int32 = 1 << 8
	while System.mainLoop {
		Keys.scan(); let keys = Keys.held
		if keys.contains(.b) { break }
		if keys.contains(.up) { scaleY += 1 }; if keys.contains(.down) { scaleY -= 1 }
		if keys.contains(.left) { scaleX += 1 }; if keys.contains(.right) { scaleX -= 1 }
		System.waitForVBlank()
		bg.setScale(sx: scaleX, sy: scaleY); Background.update()
		Console.clear()
		Console.print("Press B to exit.\n")
		Console.printf("scale X: %d  scale Y: %d", scaleX, scaleY)
	}
}

func advExtendedPalette() {
	Video.setMode(.mode0_2D); Video.setBankA(VRAM_A_MAIN_BG)
	Background.enableExtPalette()
	let bg = Background.main(layer: 0, kind: .text8bpp, size: BgSize_T_256x256, mapBase: 0, tileBase: 1)
	DMA.copy(from: nds_asset_TextBackgroundsTiles(), to: bg.gfxPointer!, size: UInt32(TextBackgroundsTilesLen))
	DMA.copy(from: nds_asset_Layer256x256Map(), to: bg.mapPointer!, size: UInt32(Layer256x256MapLen))
	// lock VRAM E for CPU access, fill slot 0, then map it as the BG ext palette
	Video.setBankE(VRAM_E_LCD)
	DMA.copy(from: nds_asset_TextBackgroundsPal(), to: vramE, size: UInt32(TextBackgroundsPalLen))
	Video.setBankE(VRAM_E_BG_EXT_PALETTE)
	scroll(bg, 256, 256)
}

func advMultipleLayers() {
	Video.setMode(.mode5_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg1 = Background.main(layer: 0, kind: .text8bpp,   size: BgSize_ER_256x256, mapBase: 0, tileBase: 1)
	let bg2 = Background.main(layer: 1, kind: .text8bpp,   size: BgSize_ER_256x256, mapBase: 1, tileBase: 1)
	let bg3 = Background.main(layer: 2, kind: .exRotation, size: BgSize_ER_256x256, mapBase: 2, tileBase: 1)
	bg1.priority = 3; bg2.priority = 2; bg3.priority = 1
	DMA.copy(from: nds_asset_MultilayerTiles(), to: bg1.gfxPointer!, size: UInt32(MultilayerTilesLen))
	DMA.copy(from: nds_asset_MultilayerPal(), to: bgPal(), size: UInt32(MultilayerPalLen))
	DMA.copy(from: nds_asset_Layer_1Map(), to: bg1.mapPointer!, size: UInt32(Layer_1MapLen))
	DMA.copy(from: nds_asset_Layer_2Map(), to: bg2.mapPointer!, size: UInt32(Layer_2MapLen))
	DMA.copy(from: nds_asset_Layer_3Map(), to: bg3.mapPointer!, size: UInt32(Layer_3MapLen))
	var h1 = false, h2 = false, h3 = false
	while System.mainLoop {
		Keys.scan(); let keys = Keys.down
		if keys.contains(.b) { break }
		if keys.contains(.up) { h1.toggle() }
		if keys.contains(.down) { h2.toggle() }
		if keys.contains(.left) { h3.toggle() }
		System.waitForVBlank()
		h1 ? bg1.hide() : bg1.show()
		h2 ? bg2.hide() : bg2.show()
		h3 ? bg3.hide() : bg3.show()
		Console.clear()
		Console.print("Press UP DOWN LEFT to toggle the layers\n\n")
		Console.printf("Floor (UP): %s\n", h1 ? "hidden" : "displayed")
		Console.printf("Walls (DOWN): %s\n", h2 ? "hidden" : "displayed")
		Console.printf("Decorations (LEFT): %s\n", h3 ? "hidden" : "displayed")
	}
}

func handMadeTiles() {
	Video.setMode(.mode0_2D); Video.setBankA(VRAM_A_MAIN_BG)
	let bg = Background.main(layer: 0, kind: .text8bpp, size: BgSize_T_256x256, mapBase: 0, tileBase: 1)

	// 4 hand-built 8x8 tiles (transparent, colour 1, colour 2, smiley)
	var tiles = [UInt8](repeating: 0, count: 4 * 64)
	for i in 0 ..< 64 { tiles[64 + i] = 1; tiles[128 + i] = 2 }
	let smiley: [UInt8] = [
		0,0,1,1,1,1,0,0,  0,1,1,1,1,1,1,0,  1,1,2,1,1,2,1,1,  1,1,1,1,1,1,1,1,
		1,1,1,1,1,1,1,1,  1,2,1,1,1,1,2,1,  0,1,2,2,2,2,1,0,  0,0,1,1,1,1,0,0,
	]
	for i in 0 ..< 64 { tiles[192 + i] = smiley[i] }
	tiles.withUnsafeBytes { DMA.copy(from: $0.baseAddress!, to: bg.gfxPointer!, size: UInt32(tiles.count)) }

	// 32x32 map (border of 1s, a few rows/decorations of 2s and 3s)
	var map = [UInt16](repeating: 1, count: 32 * 32)
	for x in 1 ..< 31 {
		map[1 * 32 + x] = 0; map[2 * 32 + x] = 3; map[3 * 32 + x] = 2
		map[4 * 32 + x] = 3; map[5 * 32 + x] = 0; map[6 * 32 + x] = 0; map[7 * 32 + x] = 0
	}
	map.withUnsafeBytes { DMA.copy(from: $0.baseAddress!, to: bg.mapPointer!, size: UInt32(map.count * 2)) }

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
	Console.print(marker ? "*" : " ")
	Console.printf("%d: ", Int32(index + 1))
	Console.print(name)
	Console.print("\n")
}

while System.mainLoop {
	var selectedCategory = 0
	var selectedDemo = 0
	let catCount = categories.count

	Video.setModeSub(.mode0_2D)
	Console.demoInit()

	// category selection
	var chosen = false
	while !chosen {
		if !System.mainLoop { break }
		Keys.scan()
		let keys = Keys.down
		if keys.contains(.up) { selectedCategory -= 1 }
		if keys.contains(.down) { selectedCategory += 1 }
		if keys.contains(.a) { chosen = true }
		if selectedCategory < 0 { selectedCategory = catCount - 1 }
		if selectedCategory >= catCount { selectedCategory = 0 }
		System.waitForVBlank()
		Console.clear()
		for ci in 0 ..< catCount { printMenu(ci == selectedCategory, ci, categories[ci].name) }
	}

	let demos = categories[selectedCategory].demos
	if demos.isEmpty { break }   // "Exit"

	// demo selection
	chosen = false
	var back = false
	while !chosen {
		if !System.mainLoop { break }
		Keys.scan()
		let keys = Keys.down
		if keys.contains(.up) { selectedDemo -= 1 }
		if keys.contains(.down) { selectedDemo += 1 }
		if keys.contains(.a) { chosen = true }
		if keys.contains(.b) { back = true; break }
		if selectedDemo < 0 { selectedDemo = demos.count - 1 }
		if selectedDemo >= demos.count { selectedDemo = 0 }
		System.waitForVBlank()
		Console.clear()
		for di in 0 ..< demos.count { printMenu(di == selectedDemo, di, demos[di].name) }
	}

	if back { continue }

	if chosen {
		Console.clear()
		Console.print("Use arrow keys to scroll\nPress 'B' to exit")
		demos[selectedDemo].go()
	}
}
