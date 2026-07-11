//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 06 example -- texture mapping.
//
//  A PCX image (embedded as a bin2s blob) is decoded at runtime with loadPCX,
//  converted to 16-bit, and mapped onto a rotating lit cube.
//
//---------------------------------------------------------------------------------

import NDS

var xrot: Float = 0, yrot: Float = 0, zrot: Float = 0
var texture0: Int32 = 0

func loadGLTextures() {
	var pcx = sImage()
	loadPCX(nds_asset_drunkenlogo_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	_ = GL.genTextures(1, &texture0)
	GL.bindTexture(0, texture0)
	_ = GL.texImage2D(target: 0, type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: pcx.image.data8)
	imageDestroy(&pcx)
}

func drawGLScene() {
	GL.loadIdentity()
	GL.translate(0, 0, -5.0)
	GL.rotate(xrot, 1, 0, 0)
	GL.rotate(yrot, 0, 1, 0)
	GL.rotate(zrot, 0, 0, 1)
	GL.bindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	GL.begin(.quads)
		GL.texCoord(0, 0); GL.vertex(-1, -1, 1)
		GL.texCoord(1, 0); GL.vertex(1, -1, 1)
		GL.texCoord(1, 1); GL.vertex(1, 1, 1)
		GL.texCoord(0, 1); GL.vertex(-1, 1, 1)
		GL.texCoord(1, 0); GL.vertex(-1, -1, -1)
		GL.texCoord(1, 1); GL.vertex(-1, 1, -1)
		GL.texCoord(0, 1); GL.vertex(1, 1, -1)
		GL.texCoord(0, 0); GL.vertex(1, -1, -1)
		GL.texCoord(0, 1); GL.vertex(-1, 1, -1)
		GL.texCoord(0, 0); GL.vertex(-1, 1, 1)
		GL.texCoord(1, 0); GL.vertex(1, 1, 1)
		GL.texCoord(1, 1); GL.vertex(1, 1, -1)
		GL.texCoord(1, 1); GL.vertex(-1, -1, -1)
		GL.texCoord(0, 1); GL.vertex(1, -1, -1)
		GL.texCoord(0, 0); GL.vertex(1, -1, 1)
		GL.texCoord(1, 0); GL.vertex(-1, -1, 1)
		GL.texCoord(1, 0); GL.vertex(1, -1, -1)
		GL.texCoord(1, 1); GL.vertex(1, 1, -1)
		GL.texCoord(0, 1); GL.vertex(1, 1, 1)
		GL.texCoord(0, 0); GL.vertex(1, -1, 1)
		GL.texCoord(0, 0); GL.vertex(-1, -1, -1)
		GL.texCoord(1, 0); GL.vertex(-1, -1, 1)
		GL.texCoord(1, 1); GL.vertex(-1, 1, 1)
		GL.texCoord(0, 1); GL.vertex(-1, 1, -1)
	GL.end()
	xrot += 0.3
	yrot += 0.2
	zrot += 0.4
}

Video.setMode(.mode0_3D)
Video.setBankA(VRAM_A_TEXTURE)
GL.initialize()
GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)

loadGLTextures()

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)
GL.matrixMode(.modelview)

GL.material(GL_AMBIENT, Color(r: 16, g: 16, b: 16))
GL.material(GL_DIFFUSE, Color(r: 16, g: 16, b: 16))
GL.material(GL_SPECULAR, Color(rawValue: (UInt16(1) << 15) | Color(r: 8, g: 8, b: 8).rawValue))
GL.material(GL_EMISSION, Color(r: 16, g: 16, b: 16))
GL.materialShininess()

GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue)
           | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
           | UInt32(POLY_FORMAT_LIGHT2.rawValue))

GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0, y: floattov10(-1.0), z: 0)
GL.light(1, color: Color(r: 31, g: 31, b: 31), x: 0, y: 0, z: floattov10(-1.0))
GL.light(2, color: Color(r: 31, g: 31, b: 31), x: 0, y: 0, z: floattov10(1.0))

while System.mainLoop {
	GL.color(1, 1, 1)
	drawGLScene()
	GL.flush()
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
