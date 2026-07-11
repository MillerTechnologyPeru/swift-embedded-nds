//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Textured_Quad example.
//
//  Maps a 128x128 16-bit texture (texture.bin, a raw blob) onto a rotating quad.
//
//---------------------------------------------------------------------------------

import NDS

var textureID: Int32 = 0
var rotateX: Float = 0.0
var rotateY: Float = 0.0

Video.setMode(.mode0_3D)
GL.initialize()

GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)

GL.viewport(0, 0, 255, 191)

Video.setBankA(VRAM_A_TEXTURE)

_ = GL.genTextures(1, &textureID)
GL.bindTexture(0, textureID)
_ = GL.texImage2D(target: 0, type: GL_RGB,
                  sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: nds_asset_texture_bin())

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 40)

GL.lookAt(eye: (0.0, 0.0, 1.0), center: (0.0, 0.0, 0.0), up: (0.0, 1.0, 0.0))

while System.mainLoop {
	GL.matrixMode(.modelview)
	GL.pushMatrix()

	GL.translatef32(0, 0, floattof32(-1))

	GL.rotateX(rotateX)
	GL.rotateY(rotateY)

	GL.material(GL_AMBIENT, Color(r: 16, g: 16, b: 16))
	GL.material(GL_DIFFUSE, Color(r: 16, g: 16, b: 16))
	GL.material(GL_SPECULAR, Color(rawValue: (UInt16(1) << 15) | Color(r: 8, g: 8, b: 8).rawValue))
	GL.material(GL_EMISSION, Color(r: 16, g: 16, b: 16))

	// the DS uses a table for shininess; this generates a rough one
	GL.materialShininess()

	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue))

	Keys.scan()
	let keys = Keys.held

	if keys.contains(.up)    { rotateX += 3 }
	if keys.contains(.down)  { rotateX -= 3 }
	if keys.contains(.left)  { rotateY += 3 }
	if keys.contains(.right) { rotateY -= 3 }

	GL.bindTexture(0, textureID)

	GL.begin(.quads)
		GL.normal(NORMAL_PACK(0, -512, 0))   // inttov10(-1) == -1 << 9

		GL.texCoord16(0, inttot16(128))
		GL.vertex16(floattov16(-0.5), floattov16(-0.5), 0)

		GL.texCoord16(inttot16(128), inttot16(128))
		GL.vertex16(floattov16(0.5), floattov16(-0.5), 0)

		GL.texCoord16(inttot16(128), 0)
		GL.vertex16(floattov16(0.5), floattov16(0.5), 0)

		GL.texCoord16(0, 0)
		GL.vertex16(floattov16(-0.5), floattov16(0.5), 0)
	GL.end()

	GL.popMatrix()

	GL.flush()

	System.waitForVBlank()

	if keys.contains(.start) { break }
}
