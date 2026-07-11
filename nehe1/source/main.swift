//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 01 example (author: Dovoto).
//
//  The minimal 3D setup: initialise the geometry engine and clear the screen.
//
//---------------------------------------------------------------------------------

import NDS

func drawGLScene() {
	// this is where the magic happens
	GL.loadIdentity()
}

// Setup the main screen for 3D
Video.setMode(.mode0_3D)

GL.initialize()
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)

GL.viewport(0, 0, 255, 191)

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)

GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

while System.mainLoop {
	GL.matrixMode(.modelview)

	GL.color(1, 1, 1)   // DS GL default colour is black, so set white

	GL.pushMatrix()
	drawGLScene()
	GL.popMatrix()

	System.waitForVBlank()
	GL.flush()

	Keys.scan()
	if Keys.down.contains(.start) { break }
}
