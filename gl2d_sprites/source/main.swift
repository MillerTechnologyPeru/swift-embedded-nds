//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "sprites" example (Relminator).
//
//  Shows GL2D sprite capabilities: rotation, scaling, flipping, stretching,
//  palette-swap tinting and a tiled background, with text on both screens.
//
//---------------------------------------------------------------------------------

import CNDS

let BRAD_PI: Int32 = 1 << 14

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> UInt16 {
	UInt16(truncatingIfNeeded: r | (g << 5) | (b << 10))
}
@inline(__always) func slerp(_ a: Int32) -> Int32 { Int32(sinLerp(Int16(truncatingIfNeeded: a))) }
@inline(__always) func clerp(_ a: Int32) -> Int32 { Int32(cosLerp(Int16(truncatingIfNeeded: a))) }

let texParam = Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue
                     | TEXGEN_OFF.rawValue | GL_TEXTURE_COLOR0_TRANSPARENT.rawValue)
let texParamNoMask = Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue
                           | TEXGEN_OFF.rawValue)

var enemies = [glImage](repeating: glImage(), count: Int(ENEMIES_NUM_IMAGES))
var zero = [glImage](repeating: glImage(), count: Int(ZERO_NUM_IMAGES))
var tiles = [glImage](repeating: glImage(), count: (256 / 16) * (256 / 16))
var shuttle = [glImage](repeating: glImage(), count: 1)
var anya = [glImage](repeating: glImage(), count: 1)

func drawBG() {
	tiles.withUnsafeBufferPointer { buf in
		for y in Int32(0) ..< (256 / 16) {
			for x in Int32(0) ..< (256 / 16) {
				let i = Int((y * 16 + x) & 255)
				glSprite(x * 16, y * 16, Int32(GL_FLIP_NONE.rawValue), buf.baseAddress! + i)
			}
		}
	}
}

var topScreen = PrintConsole()
var bottomScreen = PrintConsole()

videoSetMode(MODE_5_3D.rawValue)
videoSetModeSub(MODE_0_2D.rawValue)
glScreen2D()

vramSetBankA(VRAM_A_TEXTURE)
vramSetBankB(VRAM_B_TEXTURE)
vramSetBankF(VRAM_F_TEX_PALETTE)
vramSetBankE(VRAM_E_MAIN_BG)
consoleInit(&topScreen, 1, BgType_Text4bpp, BgSize_T_256x256, 31, 0, true, false)
bgSetPriority(0, 1)
vramSetBankI(VRAM_I_SUB_BG_0x06208000)
consoleInit(&bottomScreen, 0, BgType_Text4bpp, BgSize_T_256x256, 20, 0, false, false)

// custom console fonts -- pointers must reference the real linked symbols
var font = ConsoleFont()
font.gfx = UnsafeMutablePointer(mutating: nds_asset_fontTiles()!.assumingMemoryBound(to: UInt16.self))
font.pal = UnsafeMutablePointer(mutating: nds_asset_fontPal()!.assumingMemoryBound(to: UInt16.self))
font.numChars = 95
font.numColors = UInt16(fontPalLen / 2)
font.bpp = 4
font.asciiOffset = 32
font.convertSingleColor = false

var fontbubble = ConsoleFont()
fontbubble.gfx = UnsafeMutablePointer(mutating: nds_asset_fontbubbleTiles()!.assumingMemoryBound(to: UInt16.self))
fontbubble.pal = UnsafeMutablePointer(mutating: nds_asset_fontbubblePal()!.assumingMemoryBound(to: UInt16.self))
fontbubble.numChars = 64
fontbubble.numColors = UInt16(fontbubblePalLen / 2)
fontbubble.bpp = 4
fontbubble.asciiOffset = 32
fontbubble.convertSingleColor = false

consoleSetFont(&bottomScreen, &font)
consoleSetFont(&topScreen, &fontbubble)

// an all-white palette used to flash a sprite, plus the original
var hitPal = [UInt16](repeating: 0xFFFF, count: 256)
var paletteID: Int32 = 0
var originalPaletteID: Int32 = 0
glGenTextures(1, &paletteID)
glBindTexture(0, paletteID)
hitPal.withUnsafeBufferPointer { glColorTableEXT(0, 0, 256, 0, 0, $0.baseAddress) }
glGenTextures(1, &originalPaletteID)
glBindTexture(0, originalPaletteID)
glColorTableEXT(0, 0, 256, 0, 0, nds_asset_enemiesPal()!.assumingMemoryBound(to: UInt16.self))

let enemiesPalPtr = nds_asset_enemiesPal()!.assumingMemoryBound(to: UInt16.self)
enemies.withUnsafeMutableBufferPointer { buf in
	_ = glLoadSpriteSet(buf.baseAddress, UInt32(ENEMIES_NUM_IMAGES),
	                    nds_asset_enemies_texcoords()!.assumingMemoryBound(to: UInt32.self),
	                    GL_RGB256, Int32(TEXTURE_SIZE_256.rawValue), Int32(TEXTURE_SIZE_256.rawValue),
	                    texParam, 256, enemiesPalPtr,
	                    nds_asset_enemiesBitmap()!.assumingMemoryBound(to: UInt8.self))
}
var zeroTextureID: Int32 = 0
zero.withUnsafeMutableBufferPointer { buf in
	zeroTextureID = glLoadSpriteSet(buf.baseAddress, UInt32(ZERO_NUM_IMAGES),
	                    nds_asset_zero_texcoords()!.assumingMemoryBound(to: UInt32.self),
	                    GL_RGB256, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_256.rawValue),
	                    texParam, 256, enemiesPalPtr,   // zero shares the enemies palette
	                    nds_asset_zeroBitmap()!.assumingMemoryBound(to: UInt8.self))
}
tiles.withUnsafeMutableBufferPointer { buf in
	_ = glLoadTileSet(buf.baseAddress, 16, 16, 256, 256,
	                  GL_RGB256, Int32(TEXTURE_SIZE_256.rawValue), Int32(TEXTURE_SIZE_256.rawValue),
	                  texParam, 256, nds_asset_tilesPal()!.assumingMemoryBound(to: UInt16.self),
	                  nds_asset_tilesBitmap()!.assumingMemoryBound(to: UInt8.self))
}
shuttle.withUnsafeMutableBufferPointer { buf in
	_ = glLoadTileSet(buf.baseAddress, 64, 64, 64, 64,
	                  GL_RGB16, Int32(TEXTURE_SIZE_64.rawValue), Int32(TEXTURE_SIZE_64.rawValue),
	                  texParam, 16, nds_asset_shuttlePal()!.assumingMemoryBound(to: UInt16.self),
	                  nds_asset_shuttleBitmap()!.assumingMemoryBound(to: UInt8.self))
}
anya.withUnsafeMutableBufferPointer { buf in
	_ = glLoadTileSet(buf.baseAddress, 128, 128, 128, 128,
	                  GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
	                  texParamNoMask, 0, nil,        // 16-bit image, no palette
	                  nds_asset_anyaBitmap()!.assumingMemoryBound(to: UInt8.self))
}

consoleSelect(&topScreen)
nds_puts("\n\n\n\n\tWOOT!\n")
nds_puts("\tTOPSCREEN 3D+TEXT\n")
consoleSelect(&bottomScreen)
nds_puts("\u{1b}[1;1HEasy GL2D Sprites Demo")
nds_puts("\u{1b}[2;1HRelminator")
nds_puts("\u{1b}[4;1HHttp://Rel.Phatcode.Net")
nds_puts("\u{1b}[6;1HSprites by Adigun A. Polack,")
nds_puts("\u{1b}[7;1HPatater, Capcom, Anya Lope")

var frame: Int32 = 0
var phoenixFrame = 0
var beeFrame: Int32 = 0
var zeroFrame = 0

while pmMainLoop() {
	frame += 1
	let rotation = frame &* 240

	if frame & 7 == 0 {
		beeFrame = (beeFrame + 1) & 1
		phoenixFrame += 1
		if phoenixFrame > 2 { phoenixFrame = 0 }
	}
	if frame & 3 == 0 {
		zeroFrame += 1
		if zeroFrame > 9 { zeroFrame = 0 }
	}

	let x = 128 + ((clerp(frame) + slerp(BRAD_PI &+ rotation) &* 100) >> 12)
	let y = 96 + ((clerp(frame) + clerp(-rotation) &* 80) >> 12)

	glBegin2D()
	drawBG()

	glPolyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
	anya.withUnsafeBufferPointer {
		glSpriteRotateScaleXY(128, 96, frame &* 140, slerp(frame &* 120) &* 3, slerp(frame &* 210) &* 2,
		                      Int32(GL_FLIP_NONE.rawValue), $0.baseAddress)
	}

	glPolyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(2))
	enemies.withUnsafeBufferPointer { e in
		glSpriteRotate(x, y, rotation, Int32(GL_FLIP_NONE.rawValue), e.baseAddress! + 30 + Int(beeFrame))
		glSpriteRotate(255 - x, 191 - y, rotation &* 4, Int32(GL_FLIP_H.rawValue), e.baseAddress! + 84)
		glSpriteRotate(255 - x, y, -rotation, Int32(GL_FLIP_V.rawValue), e.baseAddress! + 32)
		glSpriteRotate(x, 191 - y, -rotation &* 3, Int32(GL_FLIP_H.rawValue | GL_FLIP_V.rawValue), e.baseAddress! + 81)

		glPolyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(3))
		glSprite(200, 0, Int32(GL_FLIP_NONE.rawValue), e.baseAddress! + 87 + phoenixFrame)
		glColor(rgb15(31, 0, 0))
		glSprite(200, 30, Int32(GL_FLIP_H.rawValue), e.baseAddress! + 87 + phoenixFrame)
		glPolyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(4))
		glColor(rgb15(0, 31, 20))
		glSprite(200, 60, Int32(GL_FLIP_V.rawValue), e.baseAddress! + 87 + phoenixFrame)
		glColor(rgb15(0, 0, 0))
		glSprite(200, 90, Int32(GL_FLIP_V.rawValue | GL_FLIP_H.rawValue), e.baseAddress! + 87 + phoenixFrame)
	}
	glColor(rgb15(31, 31, 31))

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(5))
	shuttle.withUnsafeBufferPointer {
		glSpriteStretchHorizontal(0, 135, 64 + (abs(slerp(frame &* 100) &* 200) >> 12), $0.baseAddress)
	}

	glSetActiveTexture(zeroTextureID)
	zero.withUnsafeBufferPointer { z in
		glAssignColorTable(0, paletteID)
		glSprite(0, 42 * 0, Int32(GL_FLIP_NONE.rawValue), z.baseAddress! + zeroFrame)
		let color = (frame &* 4) & 31
		glColor(rgb15(color, 31 - color, 16 + color &* 2))
		glSprite(0, 42 * 1, Int32(GL_FLIP_H.rawValue), z.baseAddress! + zeroFrame)
		glAssignColorTable(0, originalPaletteID)
		glColor(rgb15(31 - color, 16 + color &* 2, color))
		glSprite(0, 42 * 2, Int32(GL_FLIP_V.rawValue), z.baseAddress! + zeroFrame)
		glColor(rgb15(31, 31, 31))
		glSprite(0, 42 * 3, Int32(GL_FLIP_V.rawValue | GL_FLIP_H.rawValue), z.baseAddress! + zeroFrame)
	}
	glEnd2D()

	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
