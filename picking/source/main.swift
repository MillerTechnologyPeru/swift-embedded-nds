//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Picking example (Gabe Ghearing, public domain).
//
//  3D picking: the scene is drawn a second time through a tiny gluPickMatrix
//  frustum under the stylus; a per-object position test finds the nearest object
//  hit, which is then edge-outlined.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattof32(_ n: Float) -> Int32 { Int32(n * Float(1 << 12)) }
@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}

enum Clickable: UInt32 { case nothing, cone, cylinder, sphere }

var clicked: Clickable = .nothing   // what is under the cursor
var closeW: Int32 = 0x7FFFFFFF      // closest distance to camera
var polyCount: UInt32 = 0           // polygon count snapshot

// run before drawing an object during the picking pass
func startCheck() {
	while nds_gfx_busy() != 0 {}     // wait for the previous object
	while PosTestBusy() {}           // wait for any position test
	PosTest_Asynch(0, 0, 0)          // start a test at the current position
	polyCount = nds_gfx_polygon_ram_usage()
}

// run after drawing an object during the picking pass
func endCheck(_ obj: Clickable) {
	while nds_gfx_busy() != 0 {}
	while PosTestBusy() {}
	if nds_gfx_polygon_ram_usage() > polyCount {   // a polygon was drawn
		if PosTestWresult() <= closeW {
			closeW = PosTestWresult()
			clicked = obj
		}
	}
}

glInit()

var rotateX: Int32 = 0
var rotateY: Int32 = 0

videoSetMode(MODE_0_3D.rawValue)

var touchXY = touchPosition()

lcdMainOnBottom()   // we will be touching the 3D display

glEnable(Int32(GL_OUTLINE.rawValue))
glSetOutlineColor(0, rgb15(31, 31, 31))   // first outline colour = white

var viewport: [Int32] = [0, 0, 255, 191]

glClearColor(0, 0, 0, 0)
glClearPolyID(0)
glClearDepth(0x7FFF)

gluLookAt(0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)

glLight(0, rgb15(31, 31, 31), 0, floattov10(-1.0), 0)

let cone = nds_asset_cone_bin()!.assumingMemoryBound(to: UInt32.self)
let cylinder = nds_asset_cylinder_bin()!.assumingMemoryBound(to: UInt32.self)
let sphere = nds_asset_sphere_bin()!.assumingMemoryBound(to: UInt32.self)

func polyFmt(outline: Bool) {
	let id = POLY_ID(outline ? 1 : 0)
	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
	          | UInt32(POLY_FORMAT_LIGHT0.rawValue) | id)
}

while pmMainLoop() {
	threadWaitForVBlank()

	scanKeys()
	let keys = keysHeld()
	if keys & KEY_UP == 0    { rotateX += 3 }
	if keys & KEY_DOWN == 0  { rotateX -= 3 }
	if keys & KEY_LEFT == 0  { rotateY += 3 }
	if keys & KEY_RIGHT == 0 { rotateY -= 3 }

	touchRead(&touchXY)

	glViewport(0, 0, 255, 191)

	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	gluPerspective(60, 256.0 / 192.0, 0.1, 20)

	glMatrixMode(GL_MODELVIEW)

	glPushMatrix()

	glTranslatef32(0, 0, floattof32(-6))
	glRotateXi(rotateX)
	glRotateYi(rotateY)

	// ---- pass 1: draw the scene for display ----
	glPushMatrix()

	glTranslatef32(floattof32(2.9), floattof32(0), floattof32(0))
	polyFmt(outline: clicked == .cone)
	glCallList(cone)   // green cone

	glTranslatef32(floattof32(-3), floattof32(1.8), floattof32(2))
	polyFmt(outline: clicked == .cylinder)
	glCallList(cylinder)   // blue cylinder

	glTranslatef32(floattof32(0.5), floattof32(-2.6), floattof32(-4))
	polyFmt(outline: clicked == .sphere)
	glCallList(sphere)   // red sphere

	glPopMatrix(1)

	// ---- pass 2: draw again, off-screen, for picking ----
	clicked = .nothing
	closeW = 0x7FFFFFFF

	glViewport(0, 192, 0, 192)   // off-screen: hides the picking render

	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	viewport.withUnsafeBufferPointer { vp in
		gluPickMatrix(Int32(touchXY.px), 191 - Int32(touchXY.py), 4, 4, vp.baseAddress)
	}
	gluPerspective(60, 256.0 / 192.0, 0.1, 20)   // must match the display frustum

	glMatrixMode(GL_MODELVIEW)

	glTranslatef32(floattof32(2.9), floattof32(0), floattof32(0))
	startCheck(); glCallList(cone); endCheck(.cone)

	glTranslatef32(floattof32(-3), floattof32(1.8), floattof32(2))
	startCheck(); glCallList(cylinder); endCheck(.cylinder)

	glTranslatef32(floattof32(0.5), floattof32(-2.6), floattof32(-4))
	startCheck(); glCallList(sphere); endCheck(.sphere)

	glPopMatrix(1)

	glFlush(0)

	if keys & KEY_START != 0 { break }
}
