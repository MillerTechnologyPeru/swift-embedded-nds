//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "scrolling" example (Relminator).
//
//  A tile-scrolling engine: a GL2D tile set draws a camera-relative map while an
//  animated, sprite-set "Crono" walks around. Arrow keys move.
//
//---------------------------------------------------------------------------------

import CNDS

let MAP_WIDTH: Int32 = 32
let MAP_HEIGHT: Int32 = 32
let TILE_SIZE: Int32 = 16

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> Int32 {
	r | (g << 5) | (b << 10)
}

// player facing
let P_RIGHT: Int32 = 0, P_UP: Int32 = 1, P_DOWN: Int32 = 2, P_LEFT: Int32 = 3

struct Player {
	var x: Int32 = 0, y: Int32 = 0
	var gfxFrame: Int32 = 0
	var state: Int32 = P_RIGHT
	var animFrame: Int32 = 0
	var isWalking = false
}

struct Level {
	var width: Int32 = MAP_WIDTH, height: Int32 = MAP_HEIGHT
	var cameraX: Int32 = 0, cameraY: Int32 = 0
	var tileX: Int32 = 0, tileY: Int32 = 0
	var pixelX: Int32 = 0, pixelY: Int32 = 0
}

// map[x][y] stored row-major as flat[x * MAP_HEIGHT + y]
var levelMap = [UInt16](repeating: 0, count: Int(MAP_WIDTH * MAP_HEIGHT))

func initMap() {
	for y in 0 ..< MAP_HEIGHT {
		for x in 0 ..< MAP_WIDTH {
			levelMap[Int(x * MAP_HEIGHT + y)] = UInt16((((y & 15) * 16) + (x & 15)) & 255)
		}
	}
}

var animTick: Int32 = 0   // was a function-static counter in AnimatePlayer

func animatePlayer(_ p: inout Player) {
	let framesPerAnim: Int32 = 6
	if p.isWalking {
		animTick += 1
		if animTick & 7 == 0 {
			p.animFrame += 1
			if p.animFrame >= framesPerAnim { p.animFrame = 0 }
		}
	}
	if p.state == P_LEFT {
		p.gfxFrame = p.animFrame + P_RIGHT * framesPerAnim   // left reuses right, flipped
	} else {
		p.gfxFrame = p.animFrame + p.state * framesPerAnim
	}
}

func cameraUpdate(_ lvl: inout Level, _ p: Player) {
	lvl.cameraX = p.x - 128
	lvl.cameraY = p.y - 96
	if lvl.cameraX < 0 { lvl.cameraX = 0 }
	if lvl.cameraX > ((lvl.width - 2) * TILE_SIZE) - 256 {
		lvl.cameraX = ((lvl.width - 2) * TILE_SIZE) - 256
	}
	if lvl.cameraY < 0 { lvl.cameraY = 0 }
	if lvl.cameraY > ((lvl.height - 2) * TILE_SIZE) - 192 {
		lvl.cameraY = ((lvl.height - 2) * TILE_SIZE) - 192
	}
	lvl.tileX = lvl.cameraX / TILE_SIZE
	lvl.tileY = lvl.cameraY / TILE_SIZE
	lvl.pixelX = lvl.cameraX & (TILE_SIZE - 1)
	lvl.pixelY = lvl.cameraY & (TILE_SIZE - 1)
}

func drawMap(_ lvl: Level, _ tiles: UnsafePointer<glImage>) {
	let screenTileX = 256 / TILE_SIZE
	let screenTileY = 192 / TILE_SIZE
	for y in 0 ... screenTileY {
		for x in 0 ... screenTileX {
			let tx = lvl.tileX + x
			let ty = lvl.tileY + y
			let i = Int(levelMap[Int(tx * MAP_HEIGHT + ty)])
			let sx = (x * TILE_SIZE) - lvl.pixelX
			let sy = (y * TILE_SIZE) - lvl.pixelY
			glSprite(sx, sy, Int32(GL_FLIP_NONE.rawValue), tiles + i)
		}
	}
}

let texParam = Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue
                     | TEXGEN_OFF.rawValue | GL_TEXTURE_COLOR0_TRANSPARENT.rawValue)

var cronoImages = [glImage](repeating: glImage(), count: Int(CRONO_NUM_IMAGES))
var tilesImages = [glImage](repeating: glImage(), count: (256 / 16) * (256 / 16))

var crono = Player()
var lvl = Level()
crono.x = 16 * 5
crono.y = 16 * 5
crono.state = P_RIGHT

initMap()

videoSetMode(MODE_5_3D.rawValue)
consoleDemoInit()
glScreen2D()

vramSetBankA(VRAM_A_TEXTURE)
vramSetBankE(VRAM_E_TEX_PALETTE)

cronoImages.withUnsafeMutableBufferPointer { buf in
	_ = glLoadSpriteSet(buf.baseAddress, UInt32(CRONO_NUM_IMAGES),
	                    nds_asset_crono_texcoords()!.assumingMemoryBound(to: UInt32.self),
	                    GL_RGB256, Int32(TEXTURE_SIZE_256.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
	                    texParam, 256,
	                    nds_asset_cronoPal()!.assumingMemoryBound(to: UInt16.self),
	                    nds_asset_cronoBitmap()!.assumingMemoryBound(to: UInt8.self))
}
tilesImages.withUnsafeMutableBufferPointer { buf in
	_ = glLoadTileSet(buf.baseAddress, 16, 16, 256, 256,
	                  GL_RGB256, Int32(TEXTURE_SIZE_256.rawValue), Int32(TEXTURE_SIZE_256.rawValue),
	                  texParam, 256,
	                  nds_asset_tilesPal()!.assumingMemoryBound(to: UInt16.self),
	                  nds_asset_tilesBitmap()!.assumingMemoryBound(to: UInt8.self))
}

nds_puts("\u{1b}[1;1HSCROLLING TEST")
nds_puts("\u{1b}[3;1HArrow Keys to move")
nds_puts("\u{1b}[6;1HRelminator")
nds_puts("\u{1b}[7;1HHttp://Rel.Phatcode.Net")

while pmMainLoop() {
	crono.isWalking = false
	scanKeys()
	let key = keysHeld()
	if key & KEY_RIGHT != 0 { crono.x += 1; crono.state = P_RIGHT; crono.isWalking = true }
	if key & KEY_LEFT != 0  { crono.x -= 1; crono.state = P_LEFT; crono.isWalking = true }
	if key & KEY_UP != 0    { crono.y -= 1; crono.state = P_UP; crono.isWalking = true }
	if key & KEY_DOWN != 0  { crono.y += 1; crono.state = P_DOWN; crono.isWalking = true }

	animatePlayer(&crono)
	cameraUpdate(&lvl, crono)

	glBegin2D()
	tilesImages.withUnsafeBufferPointer { drawMap(lvl, $0.baseAddress!) }

	let flip = crono.state < P_LEFT ? GL_FLIP_NONE.rawValue : GL_FLIP_H.rawValue
	cronoImages.withUnsafeBufferPointer {
		glSpriteRotate(crono.x - lvl.cameraX, crono.y - lvl.cameraY, 0, Int32(flip),
		               $0.baseAddress! + Int(crono.gfxFrame))
	}

	glPolyFmt(POLY_ALPHA(16) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
	glBoxFilledGradient(0, 150, 255, 191,
	                    rgb15(31, 0, 0), rgb15(0, 31, 0), rgb15(31, 0, 31), rgb15(0, 31, 31))

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	for i in Int32(0) ..< 5 {
		glBox(i, 150 + i, 255 - i, 191 - i, rgb15(31 - i * 5, i * 5, 31 - i * 3))
	}
	glEnd2D()

	glFlush(0)
	threadWaitForVBlank()
	if keysDown() & KEY_START != 0 { break }
}
