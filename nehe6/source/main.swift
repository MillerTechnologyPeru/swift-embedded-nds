//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 06 example -- texture mapping.
//
//  A PCX image (embedded as a bin2s blob) is decoded at runtime with loadPCX,
//  converted to 16-bit, and mapped onto a rotating lit cube.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}

var xrot: Float = 0, yrot: Float = 0, zrot: Float = 0
var texture0: Int32 = 0

func loadGLTextures() {
	var pcx = sImage()
	loadPCX(nds_asset_drunkenlogo_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	glGenTextures(1, &texture0)
	glBindTexture(0, texture0)
	glTexImage2D(0, 0, GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
	             0, Int32(TEXGEN_TEXCOORD.rawValue), pcx.image.data8)
	imageDestroy(&pcx)
}

func drawGLScene() {
	glLoadIdentity()
	glTranslatef(0, 0, -5.0)
	glRotatef(xrot, 1, 0, 0)
	glRotatef(yrot, 0, 1, 0)
	glRotatef(zrot, 0, 0, 1)
	glBindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	glBegin(GL_QUADS)
		glTexCoord2f(0, 0); glVertex3f(-1, -1, 1)
		glTexCoord2f(1, 0); glVertex3f(1, -1, 1)
		glTexCoord2f(1, 1); glVertex3f(1, 1, 1)
		glTexCoord2f(0, 1); glVertex3f(-1, 1, 1)
		glTexCoord2f(1, 0); glVertex3f(-1, -1, -1)
		glTexCoord2f(1, 1); glVertex3f(-1, 1, -1)
		glTexCoord2f(0, 1); glVertex3f(1, 1, -1)
		glTexCoord2f(0, 0); glVertex3f(1, -1, -1)
		glTexCoord2f(0, 1); glVertex3f(-1, 1, -1)
		glTexCoord2f(0, 0); glVertex3f(-1, 1, 1)
		glTexCoord2f(1, 0); glVertex3f(1, 1, 1)
		glTexCoord2f(1, 1); glVertex3f(1, 1, -1)
		glTexCoord2f(1, 1); glVertex3f(-1, -1, -1)
		glTexCoord2f(0, 1); glVertex3f(1, -1, -1)
		glTexCoord2f(0, 0); glVertex3f(1, -1, 1)
		glTexCoord2f(1, 0); glVertex3f(-1, -1, 1)
		glTexCoord2f(1, 0); glVertex3f(1, -1, -1)
		glTexCoord2f(1, 1); glVertex3f(1, 1, -1)
		glTexCoord2f(0, 1); glVertex3f(1, 1, 1)
		glTexCoord2f(0, 0); glVertex3f(1, -1, 1)
		glTexCoord2f(0, 0); glVertex3f(-1, -1, -1)
		glTexCoord2f(1, 0); glVertex3f(-1, -1, 1)
		glTexCoord2f(1, 1); glVertex3f(-1, 1, 1)
		glTexCoord2f(0, 1); glVertex3f(-1, 1, -1)
	glEnd()
	xrot += 0.3
	yrot += 0.2
	zrot += 0.4
}

videoSetMode(MODE_0_3D.rawValue)
vramSetBankA(VRAM_A_TEXTURE)
glInit()
glEnable(Int32(GL_TEXTURE_2D.rawValue))
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glViewport(0, 0, 255, 191)

loadGLTextures()

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 100)
glMatrixMode(GL_MODELVIEW)

glMaterialf(GL_AMBIENT, 16 | (16 << 5) | (16 << 10))
glMaterialf(GL_DIFFUSE, 16 | (16 << 5) | (16 << 10))
glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | (8 | (8 << 5) | (8 << 10)))
glMaterialf(GL_EMISSION, 16 | (16 << 5) | (16 << 10))
glMaterialShinyness()

glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue)
          | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
          | UInt32(POLY_FORMAT_LIGHT2.rawValue))

glLight(0, 31 | (31 << 5) | (31 << 10), 0, floattov10(-1.0), 0)
glLight(1, 31 | (31 << 5) | (31 << 10), 0, 0, floattov10(-1.0))
glLight(2, 31 | (31 << 5) | (31 << 10), 0, 0, floattov10(1.0))

while pmMainLoop() {
	glColor3f(1, 1, 1)
	drawGLScene()
	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
