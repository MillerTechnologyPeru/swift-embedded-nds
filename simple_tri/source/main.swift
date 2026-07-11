//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Simple_Tri 3D example.
//
//  Draws a Gouraud-shaded triangle on the 3D engine; the D-pad rotates it.
//
//---------------------------------------------------------------------------------

import NDS

var rotateX: Float = 0.0
var rotateY: Float = 0.0

// set mode 0, enable BG0 and set it to 3D
Video.setMode(.mode0_3D)

// initialize gl
GL.initialize()

// enable antialiasing
GL.enable(Int32(GL_ANTIALIAS.rawValue))

// setup the rear plane
GL.clearColor(r: 0, g: 0, b: 0, a: 31) // BG must be opaque for AA to work
GL.clearPolyID(63)                     // BG must have a unique polygon ID for AA to work
GL.clearDepth(0x7FFF)

GL.viewport(0, 0, 255, 191)

// any floating point gl call is converted to fixed prior to being implemented
GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 40)

GL.lookAt(eye:    (0.0, 0.0, 1.0),   // camera position
          center: (0.0, 0.0, 0.0),   // look at
          up:     (0.0, 1.0, 0.0))   // up

while System.mainLoop {
	GL.pushMatrix()

	// move it away from the camera
	GL.translatef32(0, 0, floattof32(-1))

	GL.rotateX(rotateX)
	GL.rotateY(rotateY)

	GL.matrixMode(.modelview)

	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

	Keys.scan()

	let keys = Keys.held

	if keys.contains(.up)    { rotateX += 3 }
	if keys.contains(.down)  { rotateX -= 3 }
	if keys.contains(.left)  { rotateY += 3 }
	if keys.contains(.right) { rotateY -= 3 }

	// draw the triangle
	GL.begin(.triangles)

		GL.color(r: 255, g: 0, b: 0)
		GL.vertex16(inttov16(-1), inttov16(-1), 0)

		GL.color(r: 0, g: 255, b: 0)
		GL.vertex16(inttov16(1), inttov16(-1), 0)

		GL.color(r: 0, g: 0, b: 255)
		GL.vertex16(inttov16(0), inttov16(1), 0)

	GL.end()

	GL.popMatrix()

	GL.flush()

	System.waitForVBlank()

	if keys.contains(.start) { break }
}
