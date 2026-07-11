//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Display_List example.
//
//  Draws a triangle from a hand-built GPU display list (packed FIFO commands),
//  rather than immediate-mode glBegin/glVertex calls.
//
//---------------------------------------------------------------------------------

import NDS

@inline(__always) func fifoPack(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) -> UInt32 {
	(d << 24) | (c << 16) | (b << 8) | a
}

let fBegin = UInt32(FIFOCommand.begin)
let fColor = UInt32(FIFOCommand.color)
let fVtx16 = UInt32(FIFOCommand.vertex16)
let fEnd = UInt32(FIFOCommand.end)

// the display list: a length followed by packed commands + their parameters
let triangle: [UInt32] = [
	12,
	fifoPack(fBegin, fColor, fVtx16, fColor),
	UInt32(GL_TRIANGLE.rawValue),
	UInt32(Color(r: 31, g: 0, b: 0).rawValue),
	VERTEX_PACK(inttov16(-1), inttov16(-1)), VERTEX_PACK(0, 0),
	UInt32(Color(r: 0, g: 31, b: 0).rawValue),
	fifoPack(fVtx16, fColor, fVtx16, fEnd),
	VERTEX_PACK(inttov16(1), inttov16(-1)), VERTEX_PACK(0, 0),
	UInt32(Color(r: 0, g: 0, b: 31).rawValue),
	VERTEX_PACK(inttov16(0), inttov16(1)), VERTEX_PACK(0, 0),
]

var rotateX: Float = 0.0
var rotateY: Float = 0.0

Video.setMode(.mode0_3D)
GL.initialize()
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)

GL.viewport(0, 0, 255, 191)

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 40)
GL.lookAt(eye: (0.0, 0.0, 1.0), center: (0.0, 0.0, 0.0), up: (0.0, 1.0, 0.0))

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	let keys = Keys.held

	if keys.contains(.start) { break }
	if keys.contains(.up)    { rotateX += 3 }
	if keys.contains(.down)  { rotateX -= 3 }
	if keys.contains(.left)  { rotateY += 3 }
	if keys.contains(.right) { rotateY -= 3 }

	GL.pushMatrix()

	GL.translatef32(0, 0, -(1 << 12))   // floattof32(-1)
	GL.rotateX(rotateX)
	GL.rotateY(rotateY)

	GL.matrixMode(.texture)
	GL.loadIdentity()
	GL.matrixMode(.modelview)

	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

	triangle.withUnsafeBufferPointer { GL.callList($0.baseAddress!) }

	GL.popMatrix()
	GL.flush()
}
