//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Ext_Palettes/backgrounds example.
//
//  Two grit-converted 8bpp tiled backgrounds per screen, each drawing colours
//  from a different slot of the extended BG palette, scrolling at varied speeds.
//
//---------------------------------------------------------------------------------

import NDS

var frames: Int32 = 0

Video.setMode(.mode0_2D)
Video.setModeSub(.mode0_2D)
Video.setBankA(VRAM_A_MAIN_BG)
Video.setBankC(VRAM_C_SUB_BG)

Background.enableExtPalette()
Background.enableExtPaletteSub()

// extended palettes need 8bpp tiled bgs with 16-bit map entries
let bg = [
	Background.main(layer: 0, kind: .text8bpp, size: BgSize_T_256x256, mapBase: 6, tileBase: 0),
	Background.main(layer: 1, kind: .text8bpp, size: BgSize_T_256x256, mapBase: 7, tileBase: 1),
	Background.sub(layer: 0, kind: .text8bpp, size: BgSize_T_256x256, mapBase: 6, tileBase: 0),
	Background.sub(layer: 1, kind: .text8bpp, size: BgSize_T_256x256, mapBase: 7, tileBase: 1),
]

// tiles
DMA.copy(from: nds_asset_devkitlogoTiles(), to: bg[0].gfxPointer!, size: UInt32(devkitlogoTilesLen))
DMA.copy(from: nds_asset_drunkenlogoTiles(), to: bg[1].gfxPointer!, size: UInt32(drunkenlogoTilesLen))
DMA.copy(from: nds_asset_devkitlogoTiles(), to: bg[2].gfxPointer!, size: UInt32(devkitlogoTilesLen))
DMA.copy(from: nds_asset_drunkenlogoTiles(), to: bg[3].gfxPointer!, size: UInt32(drunkenlogoTilesLen))

// maps
DMA.copy(from: nds_asset_devkitlogoMap(), to: bg[0].mapPointer!, size: UInt32(devkitlogoMapLen))
DMA.copy(from: nds_asset_drunkenlogoMap(), to: bg[1].mapPointer!, size: UInt32(drunkenlogoMapLen))
DMA.copy(from: nds_asset_devkitlogoMap(), to: bg[2].mapPointer!, size: UInt32(devkitlogoMapLen))
DMA.copy(from: nds_asset_drunkenlogoMap(), to: bg[3].mapPointer!, size: UInt32(drunkenlogoMapLen))

// ext palettes are only writable in LCD mode
Video.setBankE(VRAM_E_LCD)
Video.setBankH(VRAM_H_LCD)

// drunkenlogo was grit'd into slot 12 (-mp 12) for demonstration
DMA.copy(from: nds_asset_devkitlogoPal(), to: Background.vramEExtPalette(bg: 0, slot: 0)!, size: UInt32(devkitlogoPalLen))
DMA.copy(from: nds_asset_drunkenlogoPal(), to: Background.vramEExtPalette(bg: 1, slot: 12)!, size: UInt32(drunkenlogoPalLen))
DMA.copy(from: nds_asset_devkitlogoPal(), to: Background.vramHExtPalette(bg: 0, slot: 0)!, size: UInt32(devkitlogoPalLen))
DMA.copy(from: nds_asset_drunkenlogoPal(), to: Background.vramHExtPalette(bg: 1, slot: 12)!, size: UInt32(drunkenlogoPalLen))

Video.setBankE(VRAM_E_BG_EXT_PALETTE)
Video.setBankH(VRAM_H_SUB_BG_EXT_PALETTE)

while System.mainLoop {
	System.waitForVBlank()
	frames += 1
	Background.update()
	Keys.scan()
	if Keys.down.contains(.start) { break }

	// scroll each background at a different rate
	for i in Int32(0) ..< 8 {
		Background(id: i).setScroll(x: frames / ((i & 3) + 1), y: frames / ((i & 3) + 1))
	}
}
