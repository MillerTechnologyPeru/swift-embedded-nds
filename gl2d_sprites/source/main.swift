//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "sprites" example (Relminator).
//
//  Shows GL2D sprite capabilities: rotation, scaling, flipping, stretching,
//  palette-swap tinting and a tiled background, with text on both screens.
//
//---------------------------------------------------------------------------------

import NDS

let BRAD_PI: Int32 = 1 << 14
let FLIP_NONE = Int32(GL_FLIP_NONE.rawValue)
let FLIP_H = Int32(GL_FLIP_H.rawValue)
let FLIP_V = Int32(GL_FLIP_V.rawValue)

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> Color {
	Color(rawValue: UInt16(truncatingIfNeeded: r | (g << 5) | (b << 10)))
}
@inline(__always) func slerp(_ a: Int32) -> Int32 { Int32(Math.sin(Int16(truncatingIfNeeded: a))) }
@inline(__always) func clerp(_ a: Int32) -> Int32 { Int32(Math.cos(Int16(truncatingIfNeeded: a))) }

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
				GL2D.sprite(x: x * 16, y: y * 16, flip: FLIP_NONE, buf.baseAddress! + i)
			}
		}
	}
}

var topScreen = PrintConsole()
var bottomScreen = PrintConsole()

Video.setMode(.mode5_3D)
Video.setModeSub(.mode0_2D)
GL2D.screen2D()

Video.setBankA(VRAM_A_TEXTURE)
Video.setBankB(VRAM_B_TEXTURE)
Video.setBankF(VRAM_F_TEX_PALETTE)
Video.setBankE(VRAM_E_MAIN_BG)
Console.initialize(&topScreen, layer: 1, kind: .text4bpp, size: BgSize_T_256x256, mapBase: 31, tileBase: 0, mainDisplay: true, loadGraphics: false)
Background(id: 0).priority = 1
Video.setBankI(VRAM_I_SUB_BG_0x06208000)
Console.initialize(&bottomScreen, layer: 0, kind: .text4bpp, size: BgSize_T_256x256, mapBase: 20, tileBase: 0, mainDisplay: false, loadGraphics: false)

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

Console.setFont(&bottomScreen, &font)
Console.setFont(&topScreen, &fontbubble)

// an all-white palette used to flash a sprite, plus the original
var hitPal = [UInt16](repeating: 0xFFFF, count: 256)
var paletteID: Int32 = 0
var originalPaletteID: Int32 = 0
_ = GL.genTextures(1, &paletteID)
GL.bindTexture(0, paletteID)
hitPal.withUnsafeBufferPointer { GL.colorTable($0.baseAddress, width: 256) }
_ = GL.genTextures(1, &originalPaletteID)
GL.bindTexture(0, originalPaletteID)
GL.colorTable(nds_asset_enemiesPal()!.assumingMemoryBound(to: UInt16.self), width: 256)

let enemiesPalPtr = nds_asset_enemiesPal()!.assumingMemoryBound(to: UInt16.self)
enemies.withUnsafeMutableBufferPointer { buf in
	GL2D.loadSpriteSet(buf.baseAddress!, frames: UInt32(ENEMIES_NUM_IMAGES),
	                   texcoords: nds_asset_enemies_texcoords()!.assumingMemoryBound(to: UInt32.self),
	                   type: GL_RGB256, sizeX: Int32(TEXTURE_SIZE_256.rawValue), sizeY: Int32(TEXTURE_SIZE_256.rawValue),
	                   param: texParam, paletteWidth: 256, palette: enemiesPalPtr,
	                   texture: nds_asset_enemiesBitmap()!.assumingMemoryBound(to: UInt8.self))
}
var zeroTextureID: Int32 = 0
zero.withUnsafeMutableBufferPointer { buf in
	zeroTextureID = GL2D.loadSpriteSet(buf.baseAddress!, frames: UInt32(ZERO_NUM_IMAGES),
	                   texcoords: nds_asset_zero_texcoords()!.assumingMemoryBound(to: UInt32.self),
	                   type: GL_RGB256, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_256.rawValue),
	                   param: texParam, paletteWidth: 256, palette: enemiesPalPtr,   // zero shares the enemies palette
	                   texture: nds_asset_zeroBitmap()!.assumingMemoryBound(to: UInt8.self))
}
tiles.withUnsafeMutableBufferPointer { buf in
	GL2D.loadTileSet(buf.baseAddress!, tileWidth: 16, tileHeight: 16, bmpWidth: 256, bmpHeight: 256,
	                 type: GL_RGB256, sizeX: Int32(TEXTURE_SIZE_256.rawValue), sizeY: Int32(TEXTURE_SIZE_256.rawValue),
	                 param: texParam, paletteWidth: 256, palette: nds_asset_tilesPal()!.assumingMemoryBound(to: UInt16.self),
	                 texture: nds_asset_tilesBitmap()!.assumingMemoryBound(to: UInt8.self))
}
shuttle.withUnsafeMutableBufferPointer { buf in
	GL2D.loadTileSet(buf.baseAddress!, tileWidth: 64, tileHeight: 64, bmpWidth: 64, bmpHeight: 64,
	                 type: GL_RGB16, sizeX: Int32(TEXTURE_SIZE_64.rawValue), sizeY: Int32(TEXTURE_SIZE_64.rawValue),
	                 param: texParam, paletteWidth: 16, palette: nds_asset_shuttlePal()!.assumingMemoryBound(to: UInt16.self),
	                 texture: nds_asset_shuttleBitmap()!.assumingMemoryBound(to: UInt8.self))
}
anya.withUnsafeMutableBufferPointer { buf in
	GL2D.loadTileSet(buf.baseAddress!, tileWidth: 128, tileHeight: 128, bmpWidth: 128, bmpHeight: 128,
	                 type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                 param: texParamNoMask, paletteWidth: 0, palette: nil,        // 16-bit image, no palette
	                 texture: nds_asset_anyaBitmap()!.assumingMemoryBound(to: UInt8.self))
}

Console.select(&topScreen)
Console.print("\n\n\n\n\tWOOT!\n")
Console.print("\tTOPSCREEN 3D+TEXT\n")
Console.select(&bottomScreen)
Console.print("\u{1b}[1;1HEasy GL2D Sprites Demo")
Console.print("\u{1b}[2;1HRelminator")
Console.print("\u{1b}[4;1HHttp://Rel.Phatcode.Net")
Console.print("\u{1b}[6;1HSprites by Adigun A. Polack,")
Console.print("\u{1b}[7;1HPatater, Capcom, Anya Lope")

var frame: Int32 = 0
var phoenixFrame = 0
var beeFrame: Int32 = 0
var zeroFrame = 0

while System.mainLoop {
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

	GL2D.begin2D()
	drawBG()

	GL.polyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
	anya.withUnsafeBufferPointer {
		GL2D.spriteRotateScaleXY(x: 128, y: 96, angle: frame &* 140, scaleX: slerp(frame &* 120) &* 3, scaleY: slerp(frame &* 210) &* 2,
		                         flip: FLIP_NONE, $0.baseAddress!)
	}

	GL.polyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(2))
	enemies.withUnsafeBufferPointer { e in
		GL2D.spriteRotate(x: x, y: y, angle: rotation, flip: FLIP_NONE, e.baseAddress! + 30 + Int(beeFrame))
		GL2D.spriteRotate(x: 255 - x, y: 191 - y, angle: rotation &* 4, flip: FLIP_H, e.baseAddress! + 84)
		GL2D.spriteRotate(x: 255 - x, y: y, angle: -rotation, flip: FLIP_V, e.baseAddress! + 32)
		GL2D.spriteRotate(x: x, y: 191 - y, angle: -rotation &* 3, flip: FLIP_H | FLIP_V, e.baseAddress! + 81)

		GL.polyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(3))
		GL2D.sprite(x: 200, y: 0, flip: FLIP_NONE, e.baseAddress! + 87 + phoenixFrame)
		GL.color(rgb15(31, 0, 0))
		GL2D.sprite(x: 200, y: 30, flip: FLIP_H, e.baseAddress! + 87 + phoenixFrame)
		GL.polyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(4))
		GL.color(rgb15(0, 31, 20))
		GL2D.sprite(x: 200, y: 60, flip: FLIP_V, e.baseAddress! + 87 + phoenixFrame)
		GL.color(rgb15(0, 0, 0))
		GL2D.sprite(x: 200, y: 90, flip: FLIP_V | FLIP_H, e.baseAddress! + 87 + phoenixFrame)
	}
	GL.color(rgb15(31, 31, 31))

	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(5))
	shuttle.withUnsafeBufferPointer {
		GL2D.spriteStretchHorizontal(x: 0, y: 135, lengthX: 64 + (abs(slerp(frame &* 100) &* 200) >> 12), $0.baseAddress!)
	}

	GL2D.setActiveTexture(zeroTextureID)
	zero.withUnsafeBufferPointer { z in
		GL.assignColorTable(name: paletteID)
		GL2D.sprite(x: 0, y: 42 * 0, flip: FLIP_NONE, z.baseAddress! + zeroFrame)
		let color = (frame &* 4) & 31
		GL.color(rgb15(color, 31 - color, 16 + color &* 2))
		GL2D.sprite(x: 0, y: 42 * 1, flip: FLIP_H, z.baseAddress! + zeroFrame)
		GL.assignColorTable(name: originalPaletteID)
		GL.color(rgb15(31 - color, 16 + color &* 2, color))
		GL2D.sprite(x: 0, y: 42 * 2, flip: FLIP_V, z.baseAddress! + zeroFrame)
		GL.color(rgb15(31, 31, 31))
		GL2D.sprite(x: 0, y: 42 * 3, flip: FLIP_V | FLIP_H, z.baseAddress! + zeroFrame)
	}
	GL2D.end2D()

	GL.flush()
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
