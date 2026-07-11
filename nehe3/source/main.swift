//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 03 example -- per-vertex colour.
//
//---------------------------------------------------------------------------------

import NDS

func drawGLScene() {
	GL.loadIdentity()
	GL.translate(-1.5, 0.0, -6.0)
	GL.begin(.triangles)
		GL.color(1.0, 0.0, 0.0)   // red
		GL.vertex(0.0, 1.0, 0.0)
		GL.color(0.0, 1.0, 0.0)   // green
		GL.vertex(-1.0, -1.0, 0.0)
		GL.color(0.0, 0.0, 1.0)   // blue
		GL.vertex(1.0, -1.0, 0.0)
	GL.end()
	GL.translate(3.0, 0.0, 0.0)
	GL.color(0.5, 0.5, 1.0)
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

GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
GL.matrixMode(.modelview)

while System.mainLoop {
	drawGLScene()
	GL.flush()
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
