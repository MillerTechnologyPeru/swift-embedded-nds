//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 01 example (author: Dovoto).
//
//  The minimal 3D setup: initialise the geometry engine and clear the screen.
//
//---------------------------------------------------------------------------------

import CNDS

func drawGLScene() {
	// this is where the magic happens
	glLoadIdentity()
}

// Setup the main screen for 3D
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

	glColor3f(1, 1, 1)   // DS GL default colour is black, so set white

	glPushMatrix()
	drawGLScene()
	glPopMatrix(1)

	threadWaitForVBlank()
	glFlush(0)

	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
