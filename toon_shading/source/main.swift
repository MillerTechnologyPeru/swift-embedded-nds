//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Toon_Shading example.
//
//  Renders a statue display list (statue.bin) with the hardware toon table for
//  two-tone cel shading. D-pad or stylus drag rotates it.
//
//---------------------------------------------------------------------------------

import NDS

// State for the stylus-drag rotation (the original used function-static locals).
var prevPenX: Int32 = 0x7FFFFFFF
var prevPenY: Int32 = 0x7FFFFFFF

func getPenDelta() -> (Int32, Int32) {
	let keys = Keys.held
	var touchXY = touchPosition()

	if keys.contains(.touch) {
		_ = Touch.read(into: &touchXY)
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

var rotateX: Int32 = 0
var rotateY: Int32 = 0

Video.setMode(.mode0_3D)
GL.initialize()
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)

GL.viewport(0, 0, 255, 191)

// toon-table entry 0 is fully unlit up to 31 fully lit; two block-fills give a
// cartoony 2-tone look.
GL.setToonTableRange(start: 0, end: 15, color: Color(r: 8, g: 8, b: 8))
GL.setToonTableRange(start: 16, end: 31, color: Color(r: 24, g: 24, b: 24))

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 40)

// When toon shading, the hw ignores lights 2 and 3, and uses the RED component
// of the lit vertex to index the toon table.
GL.light(0, color: Color(r: 16, g: 16, b: 16), x: 0,                y: floattov10(-1.0), z: 0)
GL.light(1, color: Color(r: 16, g: 16, b: 16), x: floattov10(-1.0), y: 0,                z: 0)

GL.lookAt(eye: (0.0, 0.0, -3.0), center: (0.0, 0.0, 0.0), up: (0.0, 1.0, 0.0))

let statue = nds_asset_statue_bin()!.assumingMemoryBound(to: UInt32.self)

while System.mainLoop {
	GL.matrixMode(.modelview)
	GL.pushMatrix()

	GL.rotateXi(rotateX)
	GL.rotateYi(rotateY)

	GL.material(GL_AMBIENT, Color(r: 8, g: 8, b: 8))
	GL.material(GL_DIFFUSE, Color(r: 24, g: 24, b: 24))
	GL.material(GL_SPECULAR, Color(r: 0, g: 0, b: 0))
	GL.material(GL_EMISSION, Color(r: 0, g: 0, b: 0))

	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
	           | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
	           | UInt32(POLY_TOON_HIGHLIGHT.rawValue))

	Keys.scan()
	let keys = Keys.held

	if keys.contains(.up) { rotateX += 1 }
	if keys.contains(.down) { rotateX -= 1 }
	if keys.contains(.left) { rotateY += 1 }
	if keys.contains(.right) { rotateY -= 1 }

	let (dx, dy) = getPenDelta()
	rotateY -= dx
	rotateX -= dy

	GL.callList(statue)
	GL.popMatrix()

	GL.flush()

	System.waitForVBlank()

	if keys.contains(.start) { break }
}
