//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 03 example -- per-vertex colour.
//
//---------------------------------------------------------------------------------

import CNDS

func drawGLScene() {
	glLoadIdentity()
	glTranslatef(-1.5, 0.0, -6.0)
	glBegin(GL_TRIANGLES)
		glColor3f(1.0, 0.0, 0.0)   // red
		glVertex3f(0.0, 1.0, 0.0)
		glColor3f(0.0, 1.0, 0.0)   // green
		glVertex3f(-1.0, -1.0, 0.0)
		glColor3f(0.0, 0.0, 1.0)   // blue
		glVertex3f(1.0, -1.0, 0.0)
	glEnd()
	glTranslatef(3.0, 0.0, 0.0)
	glColor3f(0.5, 0.5, 1.0)
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

glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
glMatrixMode(GL_MODELVIEW)

while pmMainLoop() {
	drawGLScene()
	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
