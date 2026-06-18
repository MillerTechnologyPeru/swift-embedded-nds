//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Ortho example.
//
//  A PCX-textured lit cube. Hold R for an orthographic projection (vs. the
//  default perspective), hold L to make it fully transparent.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
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

glLight(0, rgb15(31, 31, 31), 0, floattov10(-1.0), 0)
glLight(1, rgb15(31, 31, 31), 0, 0, floattov10(-1.0))
glLight(2, rgb15(31, 31, 31), 0, 0, floattov10(1.0))

glMatrixMode(GL_TEXTURE)
glLoadIdentity()
glMatrixMode(GL_MODELVIEW)

glMaterialf(GL_AMBIENT, rgb15(16, 16, 16))
glMaterialf(GL_DIFFUSE, rgb15(16, 16, 16))
glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | rgb15(8, 8, 8))
glMaterialf(GL_EMISSION, rgb15(16, 16, 16))
glMaterialShinyness()

glViewport(0, 0, 255, 191)
loadGLTextures()
glColor3f(1, 1, 1)

let lights = UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue) | UInt32(POLY_FORMAT_LIGHT2.rawValue)

while pmMainLoop() {
	scanKeys()
	let held = keysHeld()

	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	if held & KEY_R == 0 {
		gluPerspective(70, 256.0 / 192.0, 0.1, 100)
	} else {
		glOrtho(-3, 3, -2, 2, 0.1, 100)
	}
	glMatrixMode(GL_MODELVIEW)

	if held & KEY_L != 0 {
		glPolyFmt(POLY_ALPHA(0) | UInt32(POLY_CULL_NONE.rawValue) | lights)
	} else {
		glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | lights)
	}

	glPushMatrix()
	drawGLScene()
	glPopMatrix(1)
	glFlush(0)

	if held & KEY_START != 0 { break }
	threadWaitForVBlank()
}
