//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 09 example -- blended star field.
//
//  50 additively-blended, colour-cycling "star" quads (a transparent PCX) spiral
//  in and out toward the camera.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}

let NUM = 50

struct Star {
	var r: Int32 = 0, g: Int32 = 0, b: Int32 = 0
	var dist: Float = 0
	var angle: Float = 0
}

var stars = [Star](repeating: Star(), count: NUM)
let twinkle = false
var zoom: Float = -15.0
var tilt: Float = 90.0
var spin: Float = 0
var texture0: Int32 = 0

func loadGLTextures() {
	var pcx = sImage()
	loadPCX(nds_asset_Star_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16trans(&pcx, 0)
	glGenTextures(1, &texture0)
	glBindTexture(0, texture0)
	glTexImage2D(0, 0, GL_RGBA, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
	             0, Int32(TEXGEN_TEXCOORD.rawValue), pcx.image.data8)
	imageDestroy(&pcx)
}

func quad() {
	glBegin(GL_QUADS)
		glTexCoord2f(0, 0); glVertex3f(-1, -1, 0)
		glTexCoord2f(1, 0); glVertex3f(1, -1, 0)
		glTexCoord2f(1, 1); glVertex3f(1, 1, 0)
		glTexCoord2f(0, 1); glVertex3f(-1, 1, 0)
	glEnd()
}

func drawGLScene() {
	glBindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	for loop in 0 ..< NUM {
		glLoadIdentity()
		glTranslatef(0, 0, zoom)
		glRotatef(tilt, 1, 0, 0)
		glRotatef(stars[loop].angle, 0, 1, 0)
		glTranslatef(stars[loop].dist, 0, 0)
		glRotatef(-stars[loop].angle, 0, 1, 0)
		glRotatef(-tilt, 1, 0, 0)
		if twinkle {
			let t = stars[NUM - loop - 1]
			glColor3b(UInt8(truncatingIfNeeded: t.r), UInt8(truncatingIfNeeded: t.g), UInt8(truncatingIfNeeded: t.b))
			quad()
		}
		glRotatef(spin, 0, 0, 1)
		glColor3b(UInt8(truncatingIfNeeded: stars[loop].r),
		          UInt8(truncatingIfNeeded: stars[loop].g),
		          UInt8(truncatingIfNeeded: stars[loop].b))
		quad()

		spin += 0.01
		stars[loop].angle += Float(loop) / Float(NUM)
		stars[loop].dist -= 0.01
		if stars[loop].dist < 0 {
			stars[loop].dist += 5.0
			stars[loop].r = rand() % 256
            stars[loop].g = rand() % 256
            stars[loop].b = rand() % 256
		}
	}
}

videoSetMode(MODE_0_3D.rawValue)
vramSetBankA(VRAM_A_TEXTURE)
glInit()
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glEnable(Int32(GL_TEXTURE_2D.rawValue))
glEnable(Int32(GL_BLEND.rawValue))
glViewport(0, 0, 255, 191)

loadGLTextures()

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 100)
glColor3f(1, 1, 1)

glLight(0, rgb15(31, 31, 31), 0, 0, floattov10(-1.0))
glMaterialf(GL_AMBIENT, rgb15(16, 16, 16))
glMaterialf(GL_DIFFUSE, rgb15(16, 16, 16))
glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | rgb15(8, 8, 8))
glMaterialf(GL_EMISSION, rgb15(16, 16, 16))
glMaterialShinyness()
glPolyFmt(POLY_ALPHA(15) | UInt32(POLY_CULL_BACK.rawValue) | UInt32(POLY_FORMAT_LIGHT0.rawValue))
glMatrixMode(GL_MODELVIEW)

while pmMainLoop() {
	drawGLScene()
	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
