//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 256colorTilemap example (author: WinterMute).
//
//  Loads a grit-converted tiled background (tiles + map + palette) onto BG0.
//
//---------------------------------------------------------------------------------

import CNDS

// enable the main screen with background 0 active
videoSetMode(MODE_0_2D.rawValue | UInt32(DISPLAY_BG0_ACTIVE))

vramSetBankA(VRAM_A_MAIN_BG)

// BG0: 256-colour, 32x32 map, tile base 1, map base 0
nds_set_bgctrl(0, nds_bgctrl_value_256(1, 0))

// copy tile, map and palette data to VRAM at the matching bases
dmaCopy(nds_asset_tilemapTiles(), nds_char_base_block(1), UInt32(tilemapTilesLen))
dmaCopy(nds_asset_tilemapMap(), nds_screen_base_block(0), UInt32(tilemapMapLen))
dmaCopy(nds_asset_tilemapPal(), nds_bg_palette(), UInt32(tilemapPalLen))

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
