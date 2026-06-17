//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 07 example -- lighting & control.
//
//  A PCX-textured cube with per-face normals; A toggles lighting, L/R zoom,
//  the D-pad changes the spin speed.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}

var light = false
var xrot: Float = 0, yrot: Float = 0
var xspeed: Float = 0, yspeed: Float = 0
var z: Float = -5.0
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
	glTranslatef(0, 0, z)
	glRotatef(xrot, 1, 0, 0)
	glRotatef(yrot, 0, 1, 0)
	glBindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	glBegin(GL_QUADS)
		glNormal3f(0, 0, 1)
		glTexCoord2f(0, 0); glVertex3f(-1, -1, 1)
		glTexCoord2f(1, 0); glVertex3f(1, -1, 1)
		glTexCoord2f(1, 1); glVertex3f(1, 1, 1)
		glTexCoord2f(0, 1); glVertex3f(-1, 1, 1)
		glNormal3f(0, 0, -1)
		glTexCoord2f(1, 0); glVertex3f(-1, -1, -1)
		glTexCoord2f(1, 1); glVertex3f(-1, 1, -1)
		glTexCoord2f(0, 1); glVertex3f(1, 1, -1)
		glTexCoord2f(0, 0); glVertex3f(1, -1, -1)
		glNormal3f(0, 1, 0)
		glTexCoord2f(0, 1); glVertex3f(-1, 1, -1)
		glTexCoord2f(0, 0); glVertex3f(-1, 1, 1)
		glTexCoord2f(1, 0); glVertex3f(1, 1, 1)
		glTexCoord2f(1, 1); glVertex3f(1, 1, -1)
		glNormal3f(0, -1, 0)
		glTexCoord2f(1, 1); glVertex3f(-1, -1, -1)
		glTexCoord2f(0, 1); glVertex3f(1, -1, -1)
		glTexCoord2f(0, 0); glVertex3f(1, -1, 1)
		glTexCoord2f(1, 0); glVertex3f(-1, -1, 1)
		glNormal3f(1, 0, 0)
		glTexCoord2f(1, 0); glVertex3f(1, -1, -1)
		glTexCoord2f(1, 1); glVertex3f(1, 1, -1)
		glTexCoord2f(0, 1); glVertex3f(1, 1, 1)
		glTexCoord2f(0, 0); glVertex3f(1, -1, 1)
		glNormal3f(-1, 0, 0)
		glTexCoord2f(0, 0); glVertex3f(-1, -1, -1)
		glTexCoord2f(1, 0); glVertex3f(-1, -1, 1)
		glTexCoord2f(1, 1); glVertex3f(-1, 1, 1)
		glTexCoord2f(0, 1); glVertex3f(-1, 1, -1)
	glEnd()
	xrot += xspeed
	yrot += yspeed
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

glLight(0, rgb15(31, 31, 31), 0, floattov10(-1.0), 0)
glMaterialf(GL_AMBIENT, rgb15(8, 8, 8))
glMaterialf(GL_DIFFUSE, rgb15(8, 8, 8))
glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | rgb15(8, 8, 8))
glMaterialf(GL_EMISSION, rgb15(16, 16, 16))
glMaterialShinyness()
glMatrixMode(GL_MODELVIEW)

while pmMainLoop() {
	scanKeys()
	let pressed = keysDown()
	if pressed & KEY_A != 0 { light.toggle() }
	let held = keysHeld()
	if held & KEY_R != 0 { z -= 0.02 }
	if held & KEY_L != 0 { z += 0.02 }
	if held & KEY_LEFT != 0 { xspeed -= 0.01 }
	if held & KEY_RIGHT != 0 { xspeed += 0.01 }
	if held & KEY_UP != 0 { yspeed += 0.01 }
	if held & KEY_DOWN != 0 { yspeed -= 0.01 }

	glColor3f(1, 1, 1)
	if light {
		glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue) | UInt32(POLY_FORMAT_LIGHT0.rawValue))
	} else {
		glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue))
	}

	drawGLScene()
	glFlush(0)
	threadWaitForVBlank()
	if pressed & KEY_START != 0 { break }
}
