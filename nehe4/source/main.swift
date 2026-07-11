//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 04 example -- rotation.
//
//---------------------------------------------------------------------------------

import NDS

var rtri: Float = 0     // angle for the triangle
var rquad: Float = 0    // angle for the quad

func drawGLScene() {
	GL.loadIdentity()
	GL.translate(-1.5, 0.0, -6.0)
	GL.rotate(rtri, 0.0, 1.0, 0.0)        // spin the triangle about Y
	GL.color(1, 1, 1)
	GL.begin(.triangles)
		GL.color(1.0, 0.0, 0.0)
		GL.vertex(0.0, 1.0, 0.0)
		GL.color(0.0, 1.0, 0.0)
		GL.vertex(-1.0, -1.0, 0.0)
		GL.color(0.0, 0.0, 1.0)
		GL.vertex(1.0, -1.0, 0.0)
	GL.end()
	GL.loadIdentity()
	GL.translate(1.5, 0.0, -6.0)
	GL.rotate(rquad, 1.0, 0.0, 0.0)       // spin the quad about X
	GL.color(0.5, 0.5, 1.0)
	GL.begin(.quads)
		GL.vertex(-1.0, 1.0, 0.0)
		GL.vertex(1.0, 1.0, 0.0)
		GL.vertex(1.0, -1.0, 0.0)
		GL.vertex(-1.0, -1.0, 0.0)
	GL.end()
	rtri += 0.9
	rquad -= 0.75
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
