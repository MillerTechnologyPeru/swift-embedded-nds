//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Display_List_2 example.
//
//  Renders a lit teapot from a precompiled GPU display list (teapot.bin, a raw
//  binary blob embedded with bin2s). Four coloured lights surround it.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
// floattov10(n): float -> v10, clamped near 1.0 just like the libnds macro.
@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}

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

gluLookAt(0.0, 0.0, 3.5,
          0.0, 0.0, 0.0,
          0.0, 1.0, 0.0)

glLight(0, rgb15(31, 31, 31), 0,                floattov10(-1.0), 0)
glLight(1, rgb15(31, 0, 31),  0,                floattov10(1) - 1, 0)
glLight(2, rgb15(0, 31, 0),   floattov10(-1.0), 0,                0)
glLight(3, rgb15(0, 0, 31),   floattov10(1.0) - 1, 0,             0)

glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
          | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
          | UInt32(POLY_FORMAT_LIGHT2.rawValue) | UInt32(POLY_FORMAT_LIGHT3.rawValue))

// stable pointer to the linked display-list blob
let teapot = nds_asset_teapot_bin()!.assumingMemoryBound(to: UInt32.self)

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	let keys = keysHeld()

	if keys & KEY_START != 0 { break }
	if keys & KEY_UP == 0    { rotateX += 3 }
	if keys & KEY_DOWN == 0  { rotateX -= 3 }
	if keys & KEY_LEFT == 0  { rotateY += 3 }
	if keys & KEY_RIGHT == 0 { rotateY -= 3 }

	glPushMatrix()

	glRotateX(rotateX)
	glRotateY(rotateY)

	glCallList(teapot)

	glPopMatrix(1)

	glFlush(0)
}
