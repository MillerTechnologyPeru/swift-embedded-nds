//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Picking example (Gabe Ghearing, public domain).
//
//  3D picking: the scene is drawn a second time through a tiny gluPickMatrix
//  frustum under the stylus; a per-object position test finds the nearest object
//  hit, which is then edge-outlined.
//
//---------------------------------------------------------------------------------

import NDS

enum Clickable: UInt32 { case nothing, cone, cylinder, sphere }

var clicked: Clickable = .nothing   // what is under the cursor
var closeW: Int32 = 0x7FFFFFFF      // closest distance to camera
var polyCount: UInt32 = 0           // polygon count snapshot

// run before drawing an object during the picking pass
func startCheck() {
	while GL.isBusy {}               // wait for the previous object
	while PosTest.isBusy {}          // wait for any position test
	PosTest.testAsync(x: 0, y: 0, z: 0)   // start a test at the current position
	polyCount = GL.polygonRamUsage
}

// run after drawing an object during the picking pass
func endCheck(_ obj: Clickable) {
	while GL.isBusy {}
	while PosTest.isBusy {}
	if GL.polygonRamUsage > polyCount {   // a polygon was drawn
		if PosTest.w <= closeW {
			closeW = PosTest.w
			clicked = obj
		}
	}
}

GL.initialize()

var rotateX: Int32 = 0
var rotateY: Int32 = 0

Video.setMode(.mode0_3D)

var touchXY = touchPosition()

System.lcdMainOnBottom()   // we will be touching the 3D display

GL.enable(Int32(GL_OUTLINE.rawValue))
GL.setOutlineColor(id: 0, color: Color(r: 31, g: 31, b: 31))   // first outline colour = white

var viewport: [Int32] = [0, 0, 255, 191]

GL.clearColor(r: 0, g: 0, b: 0, a: 0)
GL.clearPolyID(0)
GL.clearDepth(0x7FFF)

GL.lookAt(eye: (0.0, 0.0, 1.0), center: (0.0, 0.0, 0.0), up: (0.0, 1.0, 0.0))

GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0, y: floattov10(-1.0), z: 0)

let cone = nds_asset_cone_bin()!.assumingMemoryBound(to: UInt32.self)
let cylinder = nds_asset_cylinder_bin()!.assumingMemoryBound(to: UInt32.self)
let sphere = nds_asset_sphere_bin()!.assumingMemoryBound(to: UInt32.self)

func polyFmt(outline: Bool) {
	let id = POLY_ID(outline ? 1 : 0)
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
	           | UInt32(POLY_FORMAT_LIGHT0.rawValue) | id)
}

while System.mainLoop {
	System.waitForVBlank()

	Keys.scan()
	let keys = Keys.held
	if !keys.contains(.up)    { rotateX += 3 }
	if !keys.contains(.down)  { rotateX -= 3 }
	if !keys.contains(.left)  { rotateY += 3 }
	if !keys.contains(.right) { rotateY -= 3 }

	_ = Touch.read(into: &touchXY)

	GL.viewport(0, 0, 255, 191)

	GL.matrixMode(.projection)
	GL.loadIdentity()
	GL.perspective(fovy: 60, aspect: 256.0 / 192.0, near: 0.1, far: 20)

	GL.matrixMode(.modelview)

	GL.pushMatrix()

	GL.translatef32(0, 0, floattof32(-6))
	GL.rotateXi(rotateX)
	GL.rotateYi(rotateY)

	// ---- pass 1: draw the scene for display ----
	GL.pushMatrix()

	GL.translatef32(floattof32(2.9), floattof32(0), floattof32(0))
	polyFmt(outline: clicked == .cone)
	GL.callList(cone)   // green cone

	GL.translatef32(floattof32(-3), floattof32(1.8), floattof32(2))
	polyFmt(outline: clicked == .cylinder)
	GL.callList(cylinder)   // blue cylinder

	GL.translatef32(floattof32(0.5), floattof32(-2.6), floattof32(-4))
	polyFmt(outline: clicked == .sphere)
	GL.callList(sphere)   // red sphere

	GL.popMatrix()

	// ---- pass 2: draw again, off-screen, for picking ----
	clicked = .nothing
	closeW = 0x7FFFFFFF

	GL.viewport(0, 192, 0, 192)   // off-screen: hides the picking render

	GL.matrixMode(.projection)
	GL.loadIdentity()
	viewport.withUnsafeBufferPointer { vp in
		gluPickMatrix(Int32(touchXY.px), 191 - Int32(touchXY.py), 4, 4, vp.baseAddress)
	}
	GL.perspective(fovy: 60, aspect: 256.0 / 192.0, near: 0.1, far: 20)   // must match the display frustum

	GL.matrixMode(.modelview)

	GL.translatef32(floattof32(2.9), floattof32(0), floattof32(0))
	startCheck(); GL.callList(cone); endCheck(.cone)

	GL.translatef32(floattof32(-3), floattof32(1.8), floattof32(2))
	startCheck(); GL.callList(cylinder); endCheck(.cylinder)

	GL.translatef32(floattof32(0.5), floattof32(-2.6), floattof32(-4))
	startCheck(); GL.callList(sphere); endCheck(.sphere)

	GL.popMatrix()

	GL.flush()

	if keys.contains(.start) { break }
}
