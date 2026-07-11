//---------------------------------------------------------------------------------
//
//  Swift port of the libnds BoxTest example.
//
//  Demonstrates the geometry engine's hardware bounding-box test against the
//  view frustum, and shows how culling/clipping affect vertex/polygon RAM usage.
//  A spinning colour cube on the top screen; a live readout (test result, timing,
//  RAM usage) on the sub-screen console.
//
//  Controls: D-pad rotate camera, L/R zoom, A toggle culling, B ortho/persp,
//  touch-drag to rotate the cube.
//
//---------------------------------------------------------------------------------

import NDS

//---------------------------------------------------------------------------------
// Draws an axis-aligned box, one coloured GL_QUAD per face.
//---------------------------------------------------------------------------------
func drawBox(_ x: Float, _ y: Float, _ z: Float,
             _ width: Float, _ height: Float, _ depth: Float) {
	GL.begin(.quads)

	// z face
	GL.color(1, 0, 0)
	GL.vertex(x,         y,          z)
	GL.vertex(x + width, y,          z)
	GL.vertex(x + width, y + height, z)
	GL.vertex(x,         y + height, z)

	// z + depth face
	GL.color(1, 0, 1)
	GL.vertex(x,         y,          z + depth)
	GL.vertex(x,         y + height, z + depth)
	GL.vertex(x + width, y + height, z + depth)
	GL.vertex(x + width, y,          z + depth)

	// x face
	GL.color(1, 1, 0)
	GL.vertex(x, y,          z)
	GL.vertex(x, y + height, z)
	GL.vertex(x, y + height, z + depth)
	GL.vertex(x, y,          z + depth)

	// x + width face
	GL.color(1, 1, 1)
	GL.vertex(x + width, y,          z)
	GL.vertex(x + width, y,          z + depth)
	GL.vertex(x + width, y + height, z + depth)
	GL.vertex(x + width, y + height, z)

	// y face
	GL.color(0, 1, 0)
	GL.vertex(x,         y, z)
	GL.vertex(x,         y, z + depth)
	GL.vertex(x + width, y, z + depth)
	GL.vertex(x + width, y, z)

	// y + height face
	GL.color(0, 1, 1)
	GL.vertex(x,         y + height, z)
	GL.vertex(x + width, y + height, z)
	GL.vertex(x + width, y + height, z + depth)
	GL.vertex(x,         y + height, z + depth)

	GL.end()
}

var touchXY = touchPosition()

// 3D on the top screen; console on the bottom.
System.lcdMainOnTop()
Console.demoInit()

Video.setMode(.mode0_3D)
GL.initialize()
GL.enable(Int32(GL_ANTIALIAS.rawValue))

// rear plane: opaque + unique poly ID so antialiasing works
GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)

// camera
var rotX: Float = 0, rotY: Float = 0
var translate: Float = -5

// vertex/polygon RAM counters
var polygonCount: Int32 = 0
var vertexCount: Int32 = 0

// object rotation (driven by touch)
var rx: Int32 = 50, ry: Int32 = 15
var oldx: Int32 = 0, oldy: Int32 = 0

Console.print("\u{1b}[10;0HPress A to change culling")
Console.print("\n\nPress B to change Ortho vs Persp")
Console.print("\nLeft/Right/Up/Down to rotate")
Console.print("\nPress L and R to zoom")
Console.print("\nTouch screen to rotate cube")

while System.mainLoop {
	Keys.scan()
	_ = Touch.read(into: &touchXY)

	let held = Keys.held
	let pressed = Keys.down

	if held.contains(.left)  { rotY += 1 }
	if held.contains(.right) { rotY -= 1 }
	if held.contains(.up)    { rotX += 1 }
	if held.contains(.down)  { rotX -= 1 }
	if held.contains(.l)     { translate += 0.1 }
	if held.contains(.r)     { translate -= 0.1 }

	// reset reference point when the user first touches
	if pressed.contains(.touch) {
		oldx = Int32(touchXY.px)
		oldy = Int32(touchXY.py)
	}

	// drag delta rotates the cube
	if held.contains(.touch) {
		rx += Int32(touchXY.px) - oldx
		ry += Int32(touchXY.py) - oldy
		oldx = Int32(touchXY.px)
		oldy = Int32(touchXY.py)
	}

	// ortho vs perspective
	GL.matrixMode(.projection)
	GL.loadIdentity()
	if held.contains(.b) {
		GL.ortho(-4, 4, -3, 3, 0.1, 10)
	} else {
		GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 10)
	}

	// cull mode
	if held.contains(.a) {
		GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	} else {
		GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_FRONT.rawValue))
	}

	GL.matrixMode(.modelview)
	GL.loadIdentity()

	// camera
	GL.rotateY(rotY)
	GL.rotateX(rotX)
	GL.translate(0, 0, translate)

	// cube
	GL.rotateX(Float(ry))
	GL.rotateY(Float(rx))

	drawBox(-1, -1, -1, 2, 2, 2)

	System.waitForVBlank()
	Console.print("\u{1b}[0;0HBox test cycle count")

	CPUTiming.start()
	let hit = BoxTest.test(x: -1.0, y: -1.0, z: -1.0, width: 2.0, height: 2.0, depth: 2.0)
	Console.printf("\nSingle test (float): %lu us", Int32(bitPattern: Timer.ticksToMicroseconds(CPUTiming.end())))

	CPUTiming.start()
	_ = BoxTest.test(x: inttov16(-1), y: inttov16(-1), z: inttov16(-1), width: inttov16(2), height: inttov16(2), depth: inttov16(2))
	Console.printf("\nSingle test (fixed): %lu us", Int32(bitPattern: Timer.ticksToMicroseconds(CPUTiming.end())))

	CPUTiming.start()
	for _ in 0 ..< 64 {
		_ = BoxTest.test(x: inttov16(-1), y: inttov16(-1), z: inttov16(-1), width: inttov16(2), height: inttov16(2), depth: inttov16(2))
	}
	Console.printf("\n64 tests avg. (fixed): %lu us", Int32(bitPattern: Timer.ticksToMicroseconds(CPUTiming.end() / 64)))
	Console.printf("\nBox Test result: %s", hit ? "hit" : "miss")

	while GL.isBusy {} // wait for the geometry engine

	glGetInt(GL_GET_VERTEX_RAM_COUNT, &vertexCount)
	glGetInt(GL_GET_POLYGON_RAM_COUNT, &polygonCount)

	Console.printf("\n\nRam usage: Culling %s", held.contains(.a) ? "none" : "back faces")
	Console.printf("\nVertex ram: %i", vertexCount)
	Console.printf("\nPolygon ram: %i", polygonCount)

	GL.flush()
}
