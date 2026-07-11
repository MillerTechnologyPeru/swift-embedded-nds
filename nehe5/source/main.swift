//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 05 example -- solid 3D shapes.
//
//  A colour-blended pyramid and a multi-coloured cube, both rotating.
//
//---------------------------------------------------------------------------------

import NDS

var rtri: Float = 0
var rquad: Float = 0

func drawGLScene() {
	// --- pyramid ---
	GL.loadIdentity()
	GL.translate(-1.5, 0.0, -6.0)
	GL.rotate(rtri, 0.0, 1.0, 0.0)
	GL.begin(.triangles)
		GL.color(1, 0, 0); GL.vertex(0.0, 1.0, 0.0)      // front
		GL.color(0, 1, 0); GL.vertex(-1.0, -1.0, 1.0)
		GL.color(0, 0, 1); GL.vertex(1.0, -1.0, 1.0)
		GL.color(1, 0, 0); GL.vertex(0.0, 1.0, 0.0)      // right
		GL.color(0, 0, 1); GL.vertex(1.0, -1.0, 1.0)
		GL.color(0, 1, 0); GL.vertex(1.0, -1.0, -1.0)
		GL.color(1, 0, 0); GL.vertex(0.0, 1.0, 0.0)      // back
		GL.color(0, 1, 0); GL.vertex(1.0, -1.0, -1.0)
		GL.color(0, 0, 1); GL.vertex(-1.0, -1.0, -1.0)
		GL.color(1, 0, 0); GL.vertex(0.0, 1.0, 0.0)      // left
		GL.color(0, 0, 1); GL.vertex(-1.0, -1.0, -1.0)
		GL.color(0, 1, 0); GL.vertex(-1.0, -1.0, 1.0)
	GL.end()

	// --- cube ---
	GL.loadIdentity()
	GL.translate(1.5, 0.0, -7.0)
	GL.rotate(rquad, 1.0, 1.0, 1.0)
	GL.begin(.quads)
		GL.color(0, 1, 0)                            // top
		GL.vertex(1.0, 1.0, -1.0); GL.vertex(-1.0, 1.0, -1.0); GL.vertex(-1.0, 1.0, 1.0); GL.vertex(1.0, 1.0, 1.0)
		GL.color(1, 0.5, 0)                          // bottom
		GL.vertex(1.0, -1.0, 1.0); GL.vertex(-1.0, -1.0, 1.0); GL.vertex(-1.0, -1.0, -1.0); GL.vertex(1.0, -1.0, -1.0)
		GL.color(1, 0, 0)                            // front
		GL.vertex(1.0, 1.0, 1.0); GL.vertex(-1.0, 1.0, 1.0); GL.vertex(-1.0, -1.0, 1.0); GL.vertex(1.0, -1.0, 1.0)
		GL.color(1, 1, 0)                            // back
		GL.vertex(1.0, -1.0, -1.0); GL.vertex(-1.0, -1.0, -1.0); GL.vertex(-1.0, 1.0, -1.0); GL.vertex(1.0, 1.0, -1.0)
		GL.color(0, 0, 1)                            // left
		GL.vertex(-1.0, 1.0, 1.0); GL.vertex(-1.0, 1.0, -1.0); GL.vertex(-1.0, -1.0, -1.0); GL.vertex(-1.0, -1.0, 1.0)
		GL.color(1, 0, 1)                            // right
		GL.vertex(1.0, 1.0, -1.0); GL.vertex(1.0, 1.0, 1.0); GL.vertex(1.0, -1.0, 1.0); GL.vertex(1.0, -1.0, -1.0)
	GL.end()

	rtri += 0.2
	rquad -= 0.15
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

while System.mainLoop {
	GL.matrixMode(.modelview)
	GL.pushMatrix()
	drawGLScene()
	GL.popMatrix()
	GL.flush()
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
