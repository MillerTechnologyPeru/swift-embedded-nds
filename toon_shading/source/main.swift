//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Toon_Shading example.
//
//  Renders a statue display list (statue.bin) with the hardware toon table for
//  two-tone cel shading. D-pad or stylus drag rotates it.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}

// State for the stylus-drag rotation (the original used function-static locals).
var prevPenX: Int32 = 0x7FFFFFFF
var prevPenY: Int32 = 0x7FFFFFFF

func getPenDelta() -> (Int32, Int32) {
	let keys = keysHeld()
	var touchXY = touchPosition()

	if keys & KEY_TOUCH != 0 {
		touchRead(&touchXY)
		var dx: Int32 = 0
		var dy: Int32 = 0
		if prevPenX != 0x7FFFFFFF {
			dx = prevPenX - Int32(touchXY.rawx)
			dy = prevPenY - Int32(touchXY.rawy)
		}
		prevPenX = Int32(touchXY.rawx)
		prevPenY = Int32(touchXY.rawy)
		return (dx, dy)
	} else {
		prevPenX = 0x7FFFFFFF
		prevPenY = 0x7FFFFFFF
		return (0, 0)
	}
}

let KEY_TOUCH: UInt32 = 1 << 14

var rotateX: Int32 = 0
var rotateY: Int32 = 0

videoSetMode(MODE_0_3D.rawValue)
glInit()
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)

glViewport(0, 0, 255, 191)

// toon-table entry 0 is fully unlit up to 31 fully lit; two block-fills give a
// cartoony 2-tone look.
glSetToonTableRange(0, 15, rgb15(8, 8, 8))
glSetToonTableRange(16, 31, rgb15(24, 24, 24))

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 40)

// When toon shading, the hw ignores lights 2 and 3, and uses the RED component
// of the lit vertex to index the toon table.
glLight(0, rgb15(16, 16, 16), 0,                floattov10(-1.0), 0)
glLight(1, rgb15(16, 16, 16), floattov10(-1.0), 0,                0)

gluLookAt(0.0, 0.0, -3.0,
          0.0, 0.0, 0.0,
          0.0, 1.0, 0.0)

let statue = nds_asset_statue_bin()!.assumingMemoryBound(to: UInt32.self)

while pmMainLoop() {
	glMatrixMode(GL_MODELVIEW)
	glPushMatrix()

	glRotateXi(rotateX)
	glRotateYi(rotateY)

	glMaterialf(GL_AMBIENT, rgb15(8, 8, 8))
	glMaterialf(GL_DIFFUSE, rgb15(24, 24, 24))
	glMaterialf(GL_SPECULAR, rgb15(0, 0, 0))
	glMaterialf(GL_EMISSION, rgb15(0, 0, 0))

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
	          | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
	          | UInt32(POLY_TOON_HIGHLIGHT.rawValue))

	scanKeys()
	let keys = keysHeld()

	if keys & KEY_UP != 0 { rotateX += 1 }
	if keys & KEY_DOWN != 0 { rotateX -= 1 }
	if keys & KEY_LEFT != 0 { rotateY += 1 }
	if keys & KEY_RIGHT != 0 { rotateY -= 1 }

	let (dx, dy) = getPenDelta()
	rotateY -= dx
	rotateX -= dy

	glCallList(statue)
	glPopMatrix(1)

	glFlush(0)

	threadWaitForVBlank()

	if keys & KEY_START != 0 { break }
}
