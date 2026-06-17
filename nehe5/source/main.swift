//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 05 example -- solid 3D shapes.
//
//  A colour-blended pyramid and a multi-coloured cube, both rotating.
//
//---------------------------------------------------------------------------------

import CNDS

var rtri: Float = 0
var rquad: Float = 0

func drawGLScene() {
	// --- pyramid ---
	glLoadIdentity()
	glTranslatef(-1.5, 0.0, -6.0)
	glRotatef(rtri, 0.0, 1.0, 0.0)
	glBegin(GL_TRIANGLES)
		glColor3f(1, 0, 0); glVertex3f(0, 1, 0)      // front
		glColor3f(0, 1, 0); glVertex3f(-1, -1, 1)
		glColor3f(0, 0, 1); glVertex3f(1, -1, 1)
		glColor3f(1, 0, 0); glVertex3f(0, 1, 0)      // right
		glColor3f(0, 0, 1); glVertex3f(1, -1, 1)
		glColor3f(0, 1, 0); glVertex3f(1, -1, -1)
		glColor3f(1, 0, 0); glVertex3f(0, 1, 0)      // back
		glColor3f(0, 1, 0); glVertex3f(1, -1, -1)
		glColor3f(0, 0, 1); glVertex3f(-1, -1, -1)
		glColor3f(1, 0, 0); glVertex3f(0, 1, 0)      // left
		glColor3f(0, 0, 1); glVertex3f(-1, -1, -1)
		glColor3f(0, 1, 0); glVertex3f(-1, -1, 1)
	glEnd()

	// --- cube ---
	glLoadIdentity()
	glTranslatef(1.5, 0.0, -7.0)
	glRotatef(rquad, 1.0, 1.0, 1.0)
	glBegin(GL_QUADS)
		glColor3f(0, 1, 0)                            // top
		glVertex3f(1, 1, -1); glVertex3f(-1, 1, -1); glVertex3f(-1, 1, 1); glVertex3f(1, 1, 1)
		glColor3f(1, 0.5, 0)                          // bottom
		glVertex3f(1, -1, 1); glVertex3f(-1, -1, 1); glVertex3f(-1, -1, -1); glVertex3f(1, -1, -1)
		glColor3f(1, 0, 0)                            // front
		glVertex3f(1, 1, 1); glVertex3f(-1, 1, 1); glVertex3f(-1, -1, 1); glVertex3f(1, -1, 1)
		glColor3f(1, 1, 0)                            // back
		glVertex3f(1, -1, -1); glVertex3f(-1, -1, -1); glVertex3f(-1, 1, -1); glVertex3f(1, 1, -1)
		glColor3f(0, 0, 1)                            // left
		glVertex3f(-1, 1, 1); glVertex3f(-1, 1, -1); glVertex3f(-1, -1, -1); glVertex3f(-1, -1, 1)
		glColor3f(1, 0, 1)                            // right
		glVertex3f(1, 1, -1); glVertex3f(1, 1, 1); glVertex3f(1, -1, 1); glVertex3f(1, -1, -1)
	glEnd()

	rtri += 0.2
	rquad -= 0.15
}

videoSetMode(MODE_0_3D.rawValue)
glInit()
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)

glViewport(0, 0, 255, 191)

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 100)

glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

while pmMainLoop() {
	glMatrixMode(GL_MODELVIEW)
	glPushMatrix()
	drawGLScene()
	glPopMatrix(1)
	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
