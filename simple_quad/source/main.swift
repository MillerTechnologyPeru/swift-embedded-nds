//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Simple_Quad 3D example.
//
//  Draws a Gouraud-shaded quad on the 3D engine; the D-pad rotates it.
//
//---------------------------------------------------------------------------------

import CNDS

// libnds fixed-point conversion macros, reimplemented in Swift.
@inline(__always) func inttov16(_ n: Int32) -> Int16 { Int16(n << 12) }     // int -> v16
@inline(__always) func floattof32(_ n: Float) -> Int32 { Int32(n * Float(1 << 12)) } // float -> f32

var rotateX: Float = 0.0
var rotateY: Float = 0.0

// set mode 0, enable BG0 and set it to 3D
videoSetMode(MODE_0_3D.rawValue)

glInit()
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)

glViewport(0, 0, 255, 191)

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 40)

gluLookAt(0.0, 0.0, 1.0,
          0.0, 0.0, 0.0,
          0.0, 1.0, 0.0)

while pmMainLoop() {
	glPushMatrix()

	glTranslatef32(0, 0, floattof32(-1))

	glRotateX(rotateX)
	glRotateY(rotateY)

	glMatrixMode(GL_MODELVIEW)

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

	scanKeys()

	let keys = keysHeld()

	if keys & KEY_UP != 0    { rotateX += 3 }
	if keys & KEY_DOWN != 0  { rotateX -= 3 }
	if keys & KEY_LEFT != 0  { rotateY += 3 }
	if keys & KEY_RIGHT != 0 { rotateY -= 3 }

	// draw the quad
	glBegin(GL_QUAD)

		glColor3b(255, 0, 0)
		glVertex3v16(inttov16(-1), inttov16(-1), 0)

		glColor3b(0, 255, 0)
		glVertex3v16(inttov16(1), inttov16(-1), 0)

		glColor3b(0, 0, 255)
		glVertex3v16(inttov16(1), inttov16(1), 0)

		glColor3b(255, 0, 255)
		glVertex3v16(inttov16(-1), inttov16(1), 0)

	glEnd()

	glPopMatrix(1)

	glFlush(0)

	threadWaitForVBlank()

	if keys & KEY_START != 0 { break }
}
