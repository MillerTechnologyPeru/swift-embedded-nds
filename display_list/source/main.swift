//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Display_List example.
//
//  Draws a triangle from a hand-built GPU display list (packed FIFO commands),
//  rather than immediate-mode glBegin/glVertex calls.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt32, _ g: UInt32, _ b: UInt32) -> UInt32 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func inttov16(_ n: Int32) -> Int32 { n << 12 }
@inline(__always) func vertexPack(_ x: Int32, _ y: Int32) -> UInt32 {
	UInt32(bitPattern: (x & 0xFFFF) | (y << 16))
}
@inline(__always) func fifoPack(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) -> UInt32 {
	(d << 24) | (c << 16) | (b << 8) | a
}

let fBegin = UInt32(nds_fifo_begin())
let fColor = UInt32(nds_fifo_color())
let fVtx16 = UInt32(nds_fifo_vertex16())
let fEnd = UInt32(nds_fifo_end())

// the display list: a length followed by packed commands + their parameters
let triangle: [UInt32] = [
	12,
	fifoPack(fBegin, fColor, fVtx16, fColor),
	UInt32(GL_TRIANGLE.rawValue),
	rgb15(31, 0, 0),
	vertexPack(inttov16(-1), inttov16(-1)), vertexPack(0, 0),
	rgb15(0, 31, 0),
	fifoPack(fVtx16, fColor, fVtx16, fEnd),
	vertexPack(inttov16(1), inttov16(-1)), vertexPack(0, 0),
	rgb15(0, 0, 31),
	vertexPack(inttov16(0), inttov16(1)), vertexPack(0, 0),
]

var rotateX: Float = 0.0
var rotateY: Float = 0.0

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
gluLookAt(0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	let keys = keysHeld()

	if keys & KEY_START != 0 { break }
	if keys & KEY_UP != 0    { rotateX += 3 }
	if keys & KEY_DOWN != 0  { rotateX -= 3 }
	if keys & KEY_LEFT != 0  { rotateY += 3 }
	if keys & KEY_RIGHT != 0 { rotateY -= 3 }

	glPushMatrix()

	glTranslatef32(0, 0, -(1 << 12))   // floattof32(-1)
	glRotateX(rotateX)
	glRotateY(rotateY)

	glMatrixMode(GL_TEXTURE)
	glLoadIdentity()
	glMatrixMode(GL_MODELVIEW)

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

	triangle.withUnsafeBufferPointer { glCallList($0.baseAddress) }

	glPopMatrix(1)
	glFlush(0)
}
