//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 08 example -- blending.
//
//  A PCX-textured cube drawn with alpha blending: the front faces are opaque and
//  one back face is translucent, so you can see through it. L/R zoom, D-pad spin.
//
//---------------------------------------------------------------------------------

import NDS

var xrot: Float = 0, yrot: Float = 0
var xspeed: Float = 0, yspeed: Float = 0
var z: Float = -5.0
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
	GL.translate(0, 0, z)
	GL.rotate(xrot, 1, 0, 0)
	GL.rotate(yrot, 0, 1, 0)
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | UInt32(POLY_FORMAT_LIGHT0.rawValue))
	GL.bindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	GL.begin(.quads)
		GL.normal(0, 0, 1)
		GL.texCoord(0, 0); GL.vertex(-1, -1, 1)
		GL.texCoord(1, 0); GL.vertex(1, -1, 1)
		GL.texCoord(1, 1); GL.vertex(1, 1, 1)
		GL.texCoord(0, 1); GL.vertex(-1, 1, 1)
		GL.normal(0, 0, -1)
		GL.texCoord(1, 0); GL.vertex(-1, -1, -1)
		GL.texCoord(1, 1); GL.vertex(-1, 1, -1)
		GL.texCoord(0, 1); GL.vertex(1, 1, -1)
		GL.texCoord(0, 0); GL.vertex(1, -1, -1)
		GL.normal(0, 1, 0)
		GL.texCoord(0, 1); GL.vertex(-1, 1, -1)
		GL.texCoord(0, 0); GL.vertex(-1, 1, 1)
		GL.texCoord(1, 0); GL.vertex(1, 1, 1)
		GL.texCoord(1, 1); GL.vertex(1, 1, -1)
		GL.normal(0, -1, 0)
		GL.texCoord(1, 1); GL.vertex(-1, -1, -1)
		GL.texCoord(0, 1); GL.vertex(1, -1, -1)
		GL.texCoord(0, 0); GL.vertex(1, -1, 1)
		GL.texCoord(1, 0); GL.vertex(-1, -1, 1)
		GL.normal(1, 0, 0)
		GL.texCoord(1, 0); GL.vertex(1, -1, -1)
		GL.texCoord(1, 1); GL.vertex(1, 1, -1)
		GL.texCoord(0, 1); GL.vertex(1, 1, 1)
		GL.texCoord(0, 0); GL.vertex(1, -1, 1)
	GL.end()
	GL.polyFmt(POLY_ALPHA(15) | UInt32(POLY_CULL_BACK.rawValue) | UInt32(POLY_FORMAT_LIGHT0.rawValue))
	GL.begin(.quads)
		GL.normal(-1, 0, 0)
		GL.texCoord(0, 0); GL.vertex(-1, -1, -1)
		GL.texCoord(1, 0); GL.vertex(-1, -1, 1)
		GL.texCoord(1, 1); GL.vertex(-1, 1, 1)
		GL.texCoord(0, 1); GL.vertex(-1, 1, -1)
	GL.end()
	xrot += xspeed
	yrot += yspeed
}

Video.setMode(.mode0_3D)
Video.setBankA(VRAM_A_TEXTURE)
GL.initialize()
GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.enable(Int32(GL_BLEND.rawValue))
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)

loadGLTextures()

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)

GL.color(1, 1, 1)
GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0, y: floattov10(-1.0), z: 0)
GL.material(GL_AMBIENT, Color(r: 8, g: 8, b: 8))
GL.material(GL_DIFFUSE, Color(r: 8, g: 8, b: 8))
GL.material(GL_SPECULAR, Color(rawValue: (UInt16(1) << 15) | Color(r: 8, g: 8, b: 8).rawValue))
GL.material(GL_EMISSION, Color(r: 16, g: 16, b: 16))
GL.materialShininess()
GL.matrixMode(.modelview)

while System.mainLoop {
	Keys.scan()
	let held = Keys.held
	let pressed = Keys.down
	if held.contains(.r) { z -= 0.02 }
	if held.contains(.l) { z += 0.02 }
	if held.contains(.left) { xspeed -= 0.01 }
	if held.contains(.right) { xspeed += 0.01 }
	if held.contains(.up) { yspeed += 0.01 }
	if held.contains(.down) { yspeed -= 0.01 }

	drawGLScene()
	GL.flush()
	System.waitForVBlank()
	if pressed.contains(.start) { break }
}
