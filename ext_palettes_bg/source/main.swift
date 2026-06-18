//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Ext_Palettes/backgrounds example.
//
//  Two grit-converted 8bpp tiled backgrounds per screen, each drawing colours
//  from a different slot of the extended BG palette, scrolling at varied speeds.
//
//---------------------------------------------------------------------------------

import CNDS

var bg = [Int32](repeating: 0, count: 4)
var frames: Int32 = 0

videoSetMode(MODE_0_2D.rawValue)
videoSetModeSub(MODE_0_2D.rawValue)
vramSetBankA(VRAM_A_MAIN_BG)
vramSetBankC(VRAM_C_SUB_BG)

bgExtPaletteEnable()
bgExtPaletteEnableSub()

// extended palettes need 8bpp tiled bgs with 16-bit map entries
bg[0] = bgInit(0, BgType_Text8bpp, BgSize_T_256x256, 6, 0)
bg[1] = bgInit(1, BgType_Text8bpp, BgSize_T_256x256, 7, 1)
bg[2] = bgInitSub(0, BgType_Text8bpp, BgSize_T_256x256, 6, 0)
bg[3] = bgInitSub(1, BgType_Text8bpp, BgSize_T_256x256, 7, 1)

// tiles
dmaCopy(nds_asset_devkitlogoTiles(), bgGetGfxPtr(bg[0]), UInt32(devkitlogoTilesLen))
dmaCopy(nds_asset_drunkenlogoTiles(), bgGetGfxPtr(bg[1]), UInt32(drunkenlogoTilesLen))
dmaCopy(nds_asset_devkitlogoTiles(), bgGetGfxPtr(bg[2]), UInt32(devkitlogoTilesLen))
dmaCopy(nds_asset_drunkenlogoTiles(), bgGetGfxPtr(bg[3]), UInt32(drunkenlogoTilesLen))

// maps
dmaCopy(nds_asset_devkitlogoMap(), bgGetMapPtr(bg[0]), UInt32(devkitlogoMapLen))
dmaCopy(nds_asset_drunkenlogoMap(), bgGetMapPtr(bg[1]), UInt32(drunkenlogoMapLen))
dmaCopy(nds_asset_devkitlogoMap(), bgGetMapPtr(bg[2]), UInt32(devkitlogoMapLen))
dmaCopy(nds_asset_drunkenlogoMap(), bgGetMapPtr(bg[3]), UInt32(drunkenlogoMapLen))

// ext palettes are only writable in LCD mode
vramSetBankE(VRAM_E_LCD)
vramSetBankH(VRAM_H_LCD)

// drunkenlogo was grit'd into slot 12 (-mp 12) for demonstration
dmaCopy(nds_asset_devkitlogoPal(), nds_vram_e_ext_palette(0, 0), UInt32(devkitlogoPalLen))
dmaCopy(nds_asset_drunkenlogoPal(), nds_vram_e_ext_palette(1, 12), UInt32(drunkenlogoPalLen))
dmaCopy(nds_asset_devkitlogoPal(), nds_vram_h_ext_palette(0, 0), UInt32(devkitlogoPalLen))
dmaCopy(nds_asset_drunkenlogoPal(), nds_vram_h_ext_palette(1, 12), UInt32(drunkenlogoPalLen))

vramSetBankE(VRAM_E_BG_EXT_PALETTE)
vramSetBankH(VRAM_H_SUB_BG_EXT_PALETTE)

while pmMainLoop() {
	threadWaitForVBlank()
	frames += 1
	bgUpdate()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	// scroll each background at a different rate
	for i in Int32(0) ..< 8 {
		bgSetScroll(i, frames / ((i & 3) + 1), frames / ((i & 3) + 1))
	}
}
