//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 02 example -- first polygons.
//
//  Draws a triangle and a quad with immediate-mode float GL calls.
//
//---------------------------------------------------------------------------------

import CNDS

func drawGLScene() {
	glLoadIdentity()
	glTranslatef(-1.5, 0.0, -6.0)
	glBegin(GL_TRIANGLES)
		glVertex3f(0.0, 1.0, 0.0)
		glVertex3f(-1.0, -1.0, 0.0)
		glVertex3f(1.0, -1.0, 0.0)
	glEnd()
	glTranslatef(3.0, 0.0, 0.0)
	glBegin(GL_QUADS)
		glVertex3f(-1.0, 1.0, 0.0)
		glVertex3f(1.0, 1.0, 0.0)
		glVertex3f(1.0, -1.0, 0.0)
		glVertex3f(-1.0, -1.0, 0.0)
	glEnd()
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

glColor3f(1, 1, 1)

while pmMainLoop() {
	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	glMatrixMode(GL_MODELVIEW)

	glPushMatrix()
	drawGLScene()
	glPopMatrix(1)

	threadWaitForVBlank()
	glFlush(0)

	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
