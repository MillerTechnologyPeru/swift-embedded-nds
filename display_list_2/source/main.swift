//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Display_List_2 example.
//
//  Renders a lit teapot from a precompiled GPU display list (teapot.bin, a raw
//  binary blob embedded with bin2s). Four coloured lights surround it.
//
//---------------------------------------------------------------------------------

import NDS

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

GL.lookAt(eye: (0.0, 0.0, 3.5), center: (0.0, 0.0, 0.0), up: (0.0, 1.0, 0.0))

GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0,                y: floattov10(-1.0), z: 0)
GL.light(1, color: Color(r: 31, g: 0, b: 31),  x: 0,                y: floattov10(1) - 1, z: 0)
GL.light(2, color: Color(r: 0, g: 31, b: 0),   x: floattov10(-1.0), y: 0,                z: 0)
GL.light(3, color: Color(r: 0, g: 0, b: 31),   x: floattov10(1.0) - 1, y: 0,             z: 0)

GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
           | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
           | UInt32(POLY_FORMAT_LIGHT2.rawValue) | UInt32(POLY_FORMAT_LIGHT3.rawValue))

// stable pointer to the linked display-list blob
let teapot = nds_asset_teapot_bin()!.assumingMemoryBound(to: UInt32.self)

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	let keys = Keys.held

	if keys.contains(.start) { break }
	if !keys.contains(.up)    { rotateX += 3 }
	if !keys.contains(.down)  { rotateX -= 3 }
	if !keys.contains(.left)  { rotateY += 3 }
	if !keys.contains(.right) { rotateY -= 3 }

	GL.pushMatrix()

	GL.rotateX(rotateX)
	GL.rotateY(rotateY)

	GL.callList(teapot)

	GL.popMatrix()

	GL.flush()
}
