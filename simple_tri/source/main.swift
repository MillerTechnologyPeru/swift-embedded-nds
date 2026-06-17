//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Simple_Tri 3D example.
//
//  Draws a Gouraud-shaded triangle on the 3D engine; the D-pad rotates it.
//
//---------------------------------------------------------------------------------

import CNDS

// libnds fixed-point conversion macros, reimplemented in Swift (function-like
// macros are not imported by the C importer).
@inline(__always) func inttov16(_ n: Int32) -> Int16 { Int16(n << 12) }     // int -> v16
@inline(__always) func floattof32(_ n: Float) -> Int32 { Int32(n * Float(1 << 12)) } // float -> f32

var rotateX: Float = 0.0
var rotateY: Float = 0.0

// set mode 0, enable BG0 and set it to 3D
videoSetMode(MODE_0_3D.rawValue)

// initialize gl
glInit()

// enable antialiasing
glEnable(Int32(GL_ANTIALIAS.rawValue))

// setup the rear plane
glClearColor(0, 0, 0, 31) // BG must be opaque for AA to work
glClearPolyID(63)         // BG must have a unique polygon ID for AA to work
glClearDepth(0x7FFF)

glViewport(0, 0, 255, 191)

// any floating point gl call is converted to fixed prior to being implemented
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 40)

gluLookAt(0.0, 0.0, 1.0,   // camera position
          0.0, 0.0, 0.0,   // look at
          0.0, 1.0, 0.0)   // up

while pmMainLoop() {
	glPushMatrix()

	// move it away from the camera
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

	// draw the triangle
	glBegin(GL_TRIANGLE)

		glColor3b(255, 0, 0)
		glVertex3v16(inttov16(-1), inttov16(-1), 0)

		glColor3b(0, 255, 0)
		glVertex3v16(inttov16(1), inttov16(-1), 0)

		glColor3b(0, 0, 255)
		glVertex3v16(inttov16(0), inttov16(1), 0)

	glEnd()

	glPopMatrix(1)

	glFlush(0)

	threadWaitForVBlank()

	if keys & KEY_START != 0 { break }
}
