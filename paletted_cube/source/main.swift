//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Paletted_Cube example.
//
//  A texture-format showcase: the same cube is shown with every DS texture format
//  (paletted I2/I4/I8, direct colour, A3I5/A5I3, and a 4x4 compressed texture),
//  plus a palette-swap demo. L/R cycle formats, D-pad rotates, A/B zoom.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattov16(_ n: Float) -> Int16 { Int16(n * Float(1 << 12)) }
@inline(__always) func inttot16(_ n: Int32) -> Int32 { n << 4 }
@inline(__always) func texturePack(_ u: Int32, _ v: Int32) -> UInt32 {
	UInt32(bitPattern: (u & 0xFFFF) | (v << 16))
}

let cubeVectors: [Int16] = [
	floattov16(-0.5), floattov16(-0.5), floattov16(0.5),
	floattov16(0.5),  floattov16(-0.5), floattov16(0.5),
	floattov16(0.5),  floattov16(-0.5), floattov16(-0.5),
	floattov16(-0.5), floattov16(-0.5), floattov16(-0.5),
	floattov16(-0.5), floattov16(0.5),  floattov16(0.5),
	floattov16(0.5),  floattov16(0.5),  floattov16(0.5),
	floattov16(0.5),  floattov16(0.5),  floattov16(-0.5),
	floattov16(-0.5), floattov16(0.5),  floattov16(-0.5),
]
let cubeFaces: [Int] = [
	3, 2, 1, 0,  0, 1, 5, 4,  1, 2, 6, 5,
	2, 3, 7, 6,  3, 0, 4, 7,  5, 6, 7, 4,
]
let uv: [UInt32] = [
	texturePack(inttot16(128), 0),
	texturePack(inttot16(128), inttot16(128)),
	texturePack(0, inttot16(128)),
	texturePack(0, 0),
]

func drawQuad(_ poly: Int) {
	let f1 = cubeFaces[poly * 4], f2 = cubeFaces[poly * 4 + 1]
	let f3 = cubeFaces[poly * 4 + 2], f4 = cubeFaces[poly * 4 + 3]
	nds_set_tex_coord(uv[0])
	glVertex3v16(cubeVectors[f1 * 3], cubeVectors[f1 * 3 + 1], cubeVectors[f1 * 3 + 2])
	nds_set_tex_coord(uv[1])
	glVertex3v16(cubeVectors[f2 * 3], cubeVectors[f2 * 3 + 1], cubeVectors[f2 * 3 + 2])
	nds_set_tex_coord(uv[2])
	glVertex3v16(cubeVectors[f3 * 3], cubeVectors[f3 * 3 + 1], cubeVectors[f3 * 3 + 2])
	nds_set_tex_coord(uv[3])
	glVertex3v16(cubeVectors[f4 * 3], cubeVectors[f4 * 3 + 1], cubeVectors[f4 * 3 + 2])
}

func testName(_ i: Int) -> String {
	switch i {
	case 0: return "i2 (GL_RGB4)"
	case 1: return "i2 (GL_RGB4) palette-swapped"
	case 2: return "i4 (GL_RGB16)"
	case 3: return "i8 (GL_RGB256)"
	case 4: return "direct color (GL_RGB)"
	case 5: return "a3i5 (GL_RGB32_A3)"
	case 6: return "a5i3 (GL_RGB8_A5)"
	default: return "4x4 compressed (GL_COMPRESSED)"
	}
}

// helper: bind a paletted texture + its colour table from grit symbols
func loadPaletted(_ texid: Int32, _ type: GL_TEXTURE_TYPE_ENUM,
                  _ bitmap: UnsafeRawPointer, _ pal: UnsafeRawPointer, _ count: UInt16) {
	glBindTexture(0, texid)
	glTexImage2D(0, 0, type, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
	             0, Int32(TEXGEN_TEXCOORD.rawValue), bitmap)
	glColorTableEXT(0, 0, count, 0, 0, pal.assumingMemoryBound(to: UInt16.self))
}

var textureIDS = [Int32](repeating: 0, count: 8)
var paletteIDS = [Int32](repeating: 0, count: 6)
var rotateX: Float = 0.0
var rotateY: Float = 0.0

lcdMainOnTop()
videoSetMode(MODE_0_3D.rawValue)
consoleInit(nil, 0, BgType_Text4bpp, BgSize_T_256x256, 23, 2, false, true)
consoleDemoInit()

glInit()
glEnable(Int32(GL_TEXTURE_2D.rawValue))
glEnable(Int32(GL_ANTIALIAS.rawValue))
glEnable(Int32(GL_BLEND.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glViewport(0, 0, 255, 191)

// at least one main bank for textures, sub banks F/G for the palettes
vramSetBankA(VRAM_A_TEXTURE)
vramSetBankB(VRAM_B_TEXTURE)
vramSetBankF(VRAM_F_TEX_PALETTE_SLOT0)
vramSetBankG(VRAM_G_TEX_PALETTE_SLOT5)

glGenTextures(8, &textureIDS)

// I2
glBindTexture(0, textureIDS[0])
glTexImage2D(0, 0, GL_RGB4, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
             0, Int32(TEXGEN_TEXCOORD.rawValue), nds_asset_i2Bitmap())

// a second copy of the I2 texture used for the palette-swap demo
glBindTexture(0, textureIDS[1])
glTexImage2D(0, 0, GL_RGB4, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
             0, Int32(TEXGEN_TEXCOORD.rawValue), nds_asset_i2Bitmap())

glGenTextures(6, &paletteIDS)

let tintColors: [(UInt16, UInt16, UInt16)] = [
	(0, 31, 0), (0, 0, 31), (31, 0, 0), (31, 0, 31), (31, 31, 0), (0, 31, 31),
]
let i2Pal = nds_asset_i2Pal()!.assumingMemoryBound(to: UInt16.self)
for i in 0 ..< 6 {
	var tempPalette = [UInt16](repeating: 0, count: 4)
	for c in 0 ..< 4 {
		tempPalette[c] = i2Pal[c] | rgb15(tintColors[i].0, tintColors[i].1, tintColors[i].2)
	}
	glBindTexture(0, paletteIDS[i])
	tempPalette.withUnsafeBufferPointer { glColorTableEXT(0, 0, 4, 0, 0, $0.baseAddress) }
}

// delete and recreate texture 0 just to show resource management works
glDeleteTextures(1, &textureIDS)

glBindTexture(0, textureIDS[1])
glTexImage2D(0, 0, GL_RGB4, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
             0, Int32(TEXGEN_TEXCOORD.rawValue), nds_asset_i2Bitmap())
glColorTableEXT(0, 0, 4, 0, 0, i2Pal)

loadPaletted(textureIDS[2], GL_RGB16, nds_asset_i4Bitmap(), nds_asset_i4Pal(), 16)
loadPaletted(textureIDS[3], GL_RGB256, nds_asset_i8Bitmap(), nds_asset_i8Pal(), 256)

glGenTextures(1, &textureIDS)   // re-generate texture 0

// 16bpp direct colour (grit named it _6bppBitmap because the name starts with 1)
glBindTexture(0, textureIDS[4])
glTexImage2D(0, 0, GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
             0, Int32(TEXGEN_TEXCOORD.rawValue), nds_asset__6bppBitmap())

loadPaletted(textureIDS[5], GL_RGB32_A3, nds_asset_a3i5Bitmap(), nds_asset_a3i5Pal(), 32)
loadPaletted(textureIDS[6], GL_RGB8_A5, nds_asset_a5i3Bitmap(), nds_asset_a5i3Pal(), 8)

// 4x4 compressed: tiles and the extra header must be combined contiguously
let texSize = Int(texture10_COMP_tex_bin_size)
let extSize = Int(texture10_COMP_texExt_bin_size)
var comp = [UInt8](repeating: 0, count: texSize + extSize)
comp.withUnsafeMutableBytes { buf in
	buf.copyMemory(from: UnsafeRawBufferPointer(start: nds_asset_texture10_COMP_tex_bin(), count: texSize))
	UnsafeMutableRawBufferPointer(rebasing: buf[texSize...])
		.copyMemory(from: UnsafeRawBufferPointer(start: nds_asset_texture10_COMP_texExt_bin(), count: extSize))
	glBindTexture(0, textureIDS[7])
	glTexImage2D(0, 0, GL_COMPRESSED, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
	             0, Int32(TEXGEN_TEXCOORD.rawValue), buf.baseAddress)
}
glColorTableEXT(0, 0, UInt16(texture10_COMP_pal_bin_size >> 1), 0, 0,
                nds_asset_texture10_COMP_pal_bin()!.assumingMemoryBound(to: UInt16.self))

// I2 again (recreated after the delete)
glBindTexture(0, textureIDS[0])
glTexImage2D(0, 0, GL_RGB4, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
             0, Int32(TEXGEN_TEXCOORD.rawValue), nds_asset_i2Bitmap())
glColorTableEXT(0, 0, 4, 0, 0, i2Pal)

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 40)

var fCamera: Float = 1.25
var nTexture = 0

while pmMainLoop() {
	glMatrixMode(GL_MODELVIEW)
	glPushMatrix()

	gluLookAt(0.0, 0.0, fCamera, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)

	glRotateX(rotateX)
	glRotateY(rotateY)

	scanKeys()
	let keys = keysHeld()
	if keys & KEY_UP != 0    { rotateX += 3 }
	if keys & KEY_DOWN != 0  { rotateX -= 3 }
	if keys & KEY_LEFT != 0  { rotateY += 3 }
	if keys & KEY_RIGHT != 0 { rotateY -= 3 }
	if keys & KEY_A != 0     { fCamera -= 0.05 }
	if keys & KEY_B != 0     { fCamera += 0.05 }
	if fCamera <= 0.58 { fCamera = 0.58 }

	let pressed = keysDown()
	if pressed & KEY_R != 0 { nTexture += 1; if nTexture == 8 { nTexture = 0 } }
	if pressed & KEY_L != 0 { nTexture -= 1; if nTexture == -1 { nTexture = 7 } }

	glBindTexture(0, textureIDS[nTexture])

	glColor3b(255, 255, 255)
	glScalef(0.4, 0.4, 0.4)
	var polyid: UInt32 = 1
	for _ in 0 ..< 2 {
		for i in 0 ..< 6 {
			if nTexture == 1 {
				glAssignColorTable(0, paletteIDS[i])   // palette-swap demo
			}
			glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
			          | UInt32(POLY_MODULATION.rawValue) | POLY_ID(polyid))
			glBegin(GL_QUAD)
			drawQuad(i)
			glEnd()
			polyid += 1
		}
		glScalef(1.0 / 0.4, 1.0 / 0.4, 1.0 / 0.4)
	}

	glPopMatrix(1)

	glFlush(UInt32(GL_TRANS_MANUALSORT.rawValue))

	consoleClear()
	nds_printf_1i("test %d:\n", Int32(nTexture))
	nds_puts(" ")
	nds_puts(testName(nTexture))
	nds_printf_2f("\nrot: %f, %f\n", Double(rotateX), Double(rotateY))
	nds_printf_1f("cam: %f\n", Double(fCamera))
	nds_puts("\nuse d-pad to rotate\n")
	nds_puts("use L/R to change test\n")
	nds_puts("use A/B to zoom\n")

	threadWaitForVBlank()

	if pressed & KEY_START != 0 { break }
}
