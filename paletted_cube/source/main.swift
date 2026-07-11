//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Paletted_Cube example.
//
//  A texture-format showcase: the same cube is shown with every DS texture format
//  (paletted I2/I4/I8, direct colour, A3I5/A5I3, and a 4x4 compressed texture),
//  plus a palette-swap demo. L/R cycle formats, D-pad rotates, A/B zoom.
//
//---------------------------------------------------------------------------------

import NDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
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
	TEXTURE_PACK(inttot16(128), 0),
	TEXTURE_PACK(inttot16(128), inttot16(128)),
	TEXTURE_PACK(0, inttot16(128)),
	TEXTURE_PACK(0, 0),
]

func drawQuad(_ poly: Int) {
	let f1 = cubeFaces[poly * 4], f2 = cubeFaces[poly * 4 + 1]
	let f3 = cubeFaces[poly * 4 + 2], f4 = cubeFaces[poly * 4 + 3]
	GL.submitPackedTexCoord(uv[0])
	GL.vertex16(cubeVectors[f1 * 3], cubeVectors[f1 * 3 + 1], cubeVectors[f1 * 3 + 2])
	GL.submitPackedTexCoord(uv[1])
	GL.vertex16(cubeVectors[f2 * 3], cubeVectors[f2 * 3 + 1], cubeVectors[f2 * 3 + 2])
	GL.submitPackedTexCoord(uv[2])
	GL.vertex16(cubeVectors[f3 * 3], cubeVectors[f3 * 3 + 1], cubeVectors[f3 * 3 + 2])
	GL.submitPackedTexCoord(uv[3])
	GL.vertex16(cubeVectors[f4 * 3], cubeVectors[f4 * 3 + 1], cubeVectors[f4 * 3 + 2])
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
	GL.bindTexture(0, texid)
	_ = GL.texImage2D(target: 0, type: type, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: bitmap)
	glColorTableEXT(0, 0, count, 0, 0, pal.assumingMemoryBound(to: UInt16.self))
}

var textureIDS = [Int32](repeating: 0, count: 8)
var paletteIDS = [Int32](repeating: 0, count: 6)
var rotateX: Float = 0.0
var rotateY: Float = 0.0

System.lcdMainOnTop()
Video.setMode(.mode0_3D)
Console.initialize(nil, layer: 0, kind: .text4bpp, size: BgSize_T_256x256, mapBase: 23, tileBase: 2, mainDisplay: false)
Console.demoInit()

GL.initialize()
GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.enable(Int32(GL_ANTIALIAS.rawValue))
GL.enable(Int32(GL_BLEND.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)

// at least one main bank for textures, sub banks F/G for the palettes
Video.setBankA(VRAM_A_TEXTURE)
Video.setBankB(VRAM_B_TEXTURE)
Video.setBankF(VRAM_F_TEX_PALETTE_SLOT0)
Video.setBankG(VRAM_G_TEX_PALETTE_SLOT5)

_ = GL.genTextures(8, &textureIDS)

// I2
GL.bindTexture(0, textureIDS[0])
_ = GL.texImage2D(target: 0, type: GL_RGB4, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: nds_asset_i2Bitmap())

// a second copy of the I2 texture used for the palette-swap demo
GL.bindTexture(0, textureIDS[1])
_ = GL.texImage2D(target: 0, type: GL_RGB4, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: nds_asset_i2Bitmap())

_ = GL.genTextures(6, &paletteIDS)

let tintColors: [(UInt16, UInt16, UInt16)] = [
	(0, 31, 0), (0, 0, 31), (31, 0, 0), (31, 0, 31), (31, 31, 0), (0, 31, 31),
]
let i2Pal = nds_asset_i2Pal()!.assumingMemoryBound(to: UInt16.self)
for i in 0 ..< 6 {
	var tempPalette = [UInt16](repeating: 0, count: 4)
	for c in 0 ..< 4 {
		tempPalette[c] = i2Pal[c] | rgb15(tintColors[i].0, tintColors[i].1, tintColors[i].2)
	}
	GL.bindTexture(0, paletteIDS[i])
	tempPalette.withUnsafeBufferPointer { glColorTableEXT(0, 0, 4, 0, 0, $0.baseAddress) }
}

// delete and recreate texture 0 just to show resource management works
_ = GL.deleteTextures(1, &textureIDS)

GL.bindTexture(0, textureIDS[1])
_ = GL.texImage2D(target: 0, type: GL_RGB4, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: nds_asset_i2Bitmap())
glColorTableEXT(0, 0, 4, 0, 0, i2Pal)

loadPaletted(textureIDS[2], GL_RGB16, nds_asset_i4Bitmap(), nds_asset_i4Pal(), 16)
loadPaletted(textureIDS[3], GL_RGB256, nds_asset_i8Bitmap(), nds_asset_i8Pal(), 256)

_ = GL.genTextures(1, &textureIDS)   // re-generate texture 0

// 16bpp direct colour (grit named it _6bppBitmap because the name starts with 1)
GL.bindTexture(0, textureIDS[4])
_ = GL.texImage2D(target: 0, type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: nds_asset__6bppBitmap())

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
	GL.bindTexture(0, textureIDS[7])
	_ = GL.texImage2D(target: 0, type: GL_COMPRESSED, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: buf.baseAddress!)
}
glColorTableEXT(0, 0, UInt16(texture10_COMP_pal_bin_size >> 1), 0, 0,
                nds_asset_texture10_COMP_pal_bin()!.assumingMemoryBound(to: UInt16.self))

// I2 again (recreated after the delete)
GL.bindTexture(0, textureIDS[0])
_ = GL.texImage2D(target: 0, type: GL_RGB4, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: nds_asset_i2Bitmap())
glColorTableEXT(0, 0, 4, 0, 0, i2Pal)

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 40)

var fCamera: Float = 1.25
var nTexture = 0

while System.mainLoop {
	GL.matrixMode(.modelview)
	GL.pushMatrix()

	GL.lookAt(eye: (0.0, 0.0, fCamera), center: (0.0, 0.0, 0.0), up: (0.0, 1.0, 0.0))

	GL.rotateX(rotateX)
	GL.rotateY(rotateY)

	Keys.scan()
	let keys = Keys.held
	if keys.contains(.up)    { rotateX += 3 }
	if keys.contains(.down)  { rotateX -= 3 }
	if keys.contains(.left)  { rotateY += 3 }
	if keys.contains(.right) { rotateY -= 3 }
	if keys.contains(.a)     { fCamera -= 0.05 }
	if keys.contains(.b)     { fCamera += 0.05 }
	if fCamera <= 0.58 { fCamera = 0.58 }

	let pressed = Keys.down
	if pressed.contains(.r) { nTexture += 1; if nTexture == 8 { nTexture = 0 } }
	if pressed.contains(.l) { nTexture -= 1; if nTexture == -1 { nTexture = 7 } }

	GL.bindTexture(0, textureIDS[nTexture])

	GL.color(r: 255, g: 255, b: 255)
	GL.scale(0.4, 0.4, 0.4)
	var polyid: UInt32 = 1
	for _ in 0 ..< 2 {
		for i in 0 ..< 6 {
			if nTexture == 1 {
				glAssignColorTable(0, paletteIDS[i])   // palette-swap demo
			}
			GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
			           | UInt32(POLY_MODULATION.rawValue) | POLY_ID(polyid))
			GL.begin(.quads)
			drawQuad(i)
			GL.end()
			polyid += 1
		}
		GL.scale(1.0 / 0.4, 1.0 / 0.4, 1.0 / 0.4)
	}

	GL.popMatrix()

	GL.flush(UInt32(GL_TRANS_MANUALSORT.rawValue))

	Console.clear()
	Console.printf("test %d:\n", Int32(nTexture))
	Console.print(" ")
	Console.print(testName(nTexture))
	Console.printf("\nrot: %f, %f\n", Double(rotateX), Double(rotateY))
	Console.printf("cam: %f\n", Double(fCamera))
	Console.print("\nuse d-pad to rotate\n")
	Console.print("use L/R to change test\n")
	Console.print("use A/B to zoom\n")

	System.waitForVBlank()

	if pressed.contains(.start) { break }
}
