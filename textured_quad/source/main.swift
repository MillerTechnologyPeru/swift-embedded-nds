//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Textured_Quad example.
//
//  Maps a 128x128 16-bit texture (texture.bin, a raw blob) onto a rotating quad.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattof32(_ n: Float) -> Int32  { Int32(n * Float(1 << 12)) }
@inline(__always) func floattov16(_ n: Float) -> Int16  { Int16(n * Float(1 << 12)) }
@inline(__always) func inttot16(_ n: Int32) -> Int16    { Int16(n << 4) }
@inline(__always) func normalPack(_ x: Int32, _ y: Int32, _ z: Int32) -> UInt32 {
	UInt32(bitPattern: (x & 0x3FF) | ((y & 0x3FF) << 10) | (z << 20))
}

var textureID: Int32 = 0
var rotateX: Float = 0.0
var rotateY: Float = 0.0

videoSetMode(MODE_0_3D.rawValue)
glInit()

glEnable(Int32(GL_TEXTURE_2D.rawValue))
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)

glViewport(0, 0, 255, 191)

vramSetBankA(VRAM_A_TEXTURE)

glGenTextures(1, &textureID)
glBindTexture(0, textureID)
glTexImage2D(0, 0, GL_RGB,
             Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
             0, Int32(TEXGEN_TEXCOORD.rawValue), nds_asset_texture_bin())

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 40)

gluLookAt(0.0, 0.0, 1.0,
          0.0, 0.0, 0.0,
          0.0, 1.0, 0.0)

while pmMainLoop() {
	glMatrixMode(GL_MODELVIEW)
	glPushMatrix()

	glTranslatef32(0, 0, floattof32(-1))

	glRotateX(rotateX)
	glRotateY(rotateY)

	glMaterialf(GL_AMBIENT, rgb15(16, 16, 16))
	glMaterialf(GL_DIFFUSE, rgb15(16, 16, 16))
	glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | rgb15(8, 8, 8))
	glMaterialf(GL_EMISSION, rgb15(16, 16, 16))

	// the DS uses a table for shininess; this generates a rough one
	glMaterialShinyness()

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue))

	scanKeys()
	let keys = keysHeld()

	if keys & KEY_UP != 0    { rotateX += 3 }
	if keys & KEY_DOWN != 0  { rotateX -= 3 }
	if keys & KEY_LEFT != 0  { rotateY += 3 }
	if keys & KEY_RIGHT != 0 { rotateY -= 3 }

	glBindTexture(0, textureID)

	glBegin(GL_QUAD)
		glNormal(normalPack(0, -512, 0))   // inttov10(-1) == -1 << 9

		glTexCoord2t16(0, inttot16(128))
		glVertex3v16(floattov16(-0.5), floattov16(-0.5), 0)

		glTexCoord2t16(inttot16(128), inttot16(128))
		glVertex3v16(floattov16(0.5), floattov16(-0.5), 0)

		glTexCoord2t16(inttot16(128), 0)
		glVertex3v16(floattov16(0.5), floattov16(0.5), 0)

		glTexCoord2t16(0, 0)
		glVertex3v16(floattov16(-0.5), floattov16(0.5), 0)
	glEnd()

	glPopMatrix(1)

	glFlush(0)

	threadWaitForVBlank()

	if keys & KEY_START != 0 { break }
}
