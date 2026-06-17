//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "fonts" example (Relminator).
//
//  A simple bitmap-font class built on GL2D sprite sets: a texture-packed font
//  atlas (grit) + a uvcoord table is loaded with glLoadSpriteSet, then each glyph
//  is drawn with glSprite.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> UInt16 {
	UInt16(truncatingIfNeeded: r | (g << 5) | (b << 10))
}

// A bitmap font: one glImage frame per glyph (ascii - 32).
struct GLFont {
	var images: [glImage]

	init(_ count: Int) { images = [glImage](repeating: glImage(), count: count) }

	mutating func load(numframes: UInt32, texcoords: UnsafePointer<UInt32>,
	                   type: GL_TEXTURE_TYPE_ENUM, sizeX: Int32, sizeY: Int32, param: Int32,
	                   paletteWidth: Int32, palette: UnsafePointer<UInt16>, texture: UnsafePointer<UInt8>) {
		images.withUnsafeMutableBufferPointer { buf in
			_ = glLoadSpriteSet(buf.baseAddress, numframes, texcoords, type,
			                    sizeX, sizeY, param, paletteWidth, palette, texture)
		}
	}

	func print(_ x0: Int32, _ y: Int32, _ text: String) {
		var x = x0
		images.withUnsafeBufferPointer { buf in
			for byte in text.utf8 {
				let fc = Int(byte) - 32
				glSprite(x, y, Int32(GL_FLIP_NONE.rawValue), buf.baseAddress! + fc)
				x += buf[fc].width
			}
		}
	}

	func printCentered(_ y: Int32, _ text: String) {
		var total: Int32 = 0
		for byte in text.utf8 { total += images[Int(byte) - 32].width }
		print((256 - total) / 2, y, text)
	}
}

let texParam = Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue
                     | TEXGEN_OFF.rawValue | GL_TEXTURE_COLOR0_TRANSPARENT.rawValue)

videoSetMode(MODE_5_3D.rawValue)
consoleDemoInit()
glScreen2D()

vramSetBankA(VRAM_A_TEXTURE)
vramSetBankE(VRAM_E_TEX_PALETTE)

let pal = nds_asset_font_siPal()!.assumingMemoryBound(to: UInt16.self)

var font = GLFont(Int(FONT_SI_NUM_IMAGES))
font.load(numframes: UInt32(FONT_SI_NUM_IMAGES),
          texcoords: nds_asset_font_si_texcoords()!.assumingMemoryBound(to: UInt32.self),
          type: GL_RGB256,
          sizeX: Int32(TEXTURE_SIZE_64.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
          param: texParam, paletteWidth: 256, palette: pal,
          texture: nds_asset_font_siBitmap()!.assumingMemoryBound(to: UInt8.self))

var fontBig = GLFont(Int(FONT_16X16_NUM_IMAGES))
fontBig.load(numframes: UInt32(FONT_16X16_NUM_IMAGES),
             texcoords: nds_asset_font_16x16_texcoords()!.assumingMemoryBound(to: UInt32.self),
             type: GL_RGB256,
             sizeX: Int32(TEXTURE_SIZE_64.rawValue), sizeY: Int32(TEXTURE_SIZE_512.rawValue),
             param: texParam, paletteWidth: 256, palette: pal,
             texture: nds_asset_font_16x16Bitmap()!.assumingMemoryBound(to: UInt8.self))

nds_puts("\u{1b}[1;1HEasy GL2D Font Example")
nds_puts("\u{1b}[3;1HFonts by Adigun A. Polack")
nds_puts("\u{1b}[6;1HRelminator")
nds_puts("\u{1b}[7;1HHttp://Rel.Phatcode.Net")
nds_printf_1i("\u{1b}[10;1HTotal Texture size= %i kb",
              Int32(font_siBitmapLen + font_16x16BitmapLen) / 1024)

var frame: Int32 = 0

while pmMainLoop() {
	frame += 1

	glBegin2D()

	glBoxFilledGradient(0, 0, 255, 191,
	                    Int32(rgb15(31, 0, 0)), Int32(rgb15(0, 31, 0)),
	                    Int32(rgb15(31, 0, 31)), Int32(rgb15(0, 31, 31)))

	glColor(rgb15(0, 0, 0))
	fontBig.printCentered(0, "EASY GL2D")
	glColor(rgb15((frame * 6) & 31, (-frame * 4) & 31, (frame * 2) & 31))
	fontBig.printCentered(20, "FONT EXAMPLE")

	let x = (Int32(sinLerp(Int16(truncatingIfNeeded: frame &* 400))) * 30) >> 12
	glColor(rgb15(31, 0, 0))
	fontBig.print(25 + x, 50, "hfDEVKITPROfh")
	glColor(rgb15(x, 31 - x, x * 2))
	fontBig.print(50 - x, 70, "dcLIBNDScd")

	glColor(rgb15(0, 31, 31))
	font.printCentered(100, "FONTS BY ADIGUN A. POLACK")
	font.printCentered(120, "CODE BY RELMINATOR")

	glColor(rgb15(31, 31, 31))
	let opacity = abs(Int32(sinLerp(Int16(truncatingIfNeeded: frame &* 245))) * 30) >> 12
	glPolyFmt(POLY_ALPHA(UInt32(1 + opacity)) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
	fontBig.print(35 + x, 140, "ANYA THERESE")

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(2))
	font.print(10, 170, "FRAMES = ")

	glEnd2D()
	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
