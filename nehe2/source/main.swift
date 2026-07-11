//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 02 example -- first polygons.
//
//  Draws a triangle and a quad with immediate-mode float GL calls.
//
//---------------------------------------------------------------------------------

import NDS

func drawGLScene() {
	GL.loadIdentity()
	GL.translate(-1.5, 0.0, -6.0)
	GL.begin(.triangles)
		GL.vertex(0.0, 1.0, 0.0)
		GL.vertex(-1.0, -1.0, 0.0)
		GL.vertex(1.0, -1.0, 0.0)
	GL.end()
	GL.translate(3.0, 0.0, 0.0)
	GL.begin(.quads)
		GL.vertex(-1.0, 1.0, 0.0)
		GL.vertex(1.0, 1.0, 0.0)
		GL.vertex(1.0, -1.0, 0.0)
		GL.vertex(-1.0, -1.0, 0.0)
	GL.end()
}

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

GL.color(1, 1, 1)

while System.mainLoop {
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	GL.matrixMode(.modelview)

	GL.pushMatrix()
	drawGLScene()
	GL.popMatrix()

	System.waitForVBlank()
	GL.flush()

	Keys.scan()
	if Keys.down.contains(.start) { break }
}
