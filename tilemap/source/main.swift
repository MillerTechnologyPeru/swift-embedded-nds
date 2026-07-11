//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 256colorTilemap example (author: WinterMute).
//
//  Loads a grit-converted tiled background (tiles + map + palette) onto BG0.
//
//---------------------------------------------------------------------------------

import NDS

// enable the main screen with background 0 active
Video.setMode(.mode0_2D)
Video.enableBg(0)

Video.setBankA(VRAM_A_MAIN_BG)

// BG0: 256-colour, 32x32 map, tile base 1, map base 0
Background.setControl(layer: 0, value: Background.control256(tileBase: 1, mapBase: 0))

// copy tile, map and palette data to VRAM at the matching bases
DMA.copy(from: nds_asset_tilemapTiles(), to: Background.charBaseBlock(1)!, size: UInt32(tilemapTilesLen))
DMA.copy(from: nds_asset_tilemapMap(), to: Background.screenBaseBlock(0)!, size: UInt32(tilemapMapLen))
DMA.copy(from: nds_asset_tilemapPal(), to: Background.palette!, size: UInt32(tilemapPalLen))

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
