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

import CNDS
import _Volatile

// GFX_STATUS geometry-engine status register (busy bit = 1<<27).
let GFX_STATUS = VolatileMappedRegister<UInt32>(unsafeBitPattern: 0x04000600)

// KEY_TOUCH is BIT(14), a function-like macro that doesn't import.
let KEY_TOUCH: UInt32 = 1 << 14

// inttov16 is a function-like macro: int -> 4.12 fixed-point v16.
@inline(__always) func inttov16(_ n: Int32) -> Int16 { Int16(n << 12) }

//---------------------------------------------------------------------------------
// Draws an axis-aligned box, one coloured GL_QUAD per face.
//---------------------------------------------------------------------------------
func drawBox(_ x: Float, _ y: Float, _ z: Float,
             _ width: Float, _ height: Float, _ depth: Float) {
	glBegin(GL_QUADS)

	// z face
	glColor3f(1, 0, 0)
	glVertex3f(x,         y,          z)
	glVertex3f(x + width, y,          z)
	glVertex3f(x + width, y + height, z)
	glVertex3f(x,         y + height, z)

	// z + depth face
	glColor3f(1, 0, 1)
	glVertex3f(x,         y,          z + depth)
	glVertex3f(x,         y + height, z + depth)
	glVertex3f(x + width, y + height, z + depth)
	glVertex3f(x + width, y,          z + depth)

	// x face
	glColor3f(1, 1, 0)
	glVertex3f(x, y,          z)
	glVertex3f(x, y + height, z)
	glVertex3f(x, y + height, z + depth)
	glVertex3f(x, y,          z + depth)

	// x + width face
	glColor3f(1, 1, 1)
	glVertex3f(x + width, y,          z)
	glVertex3f(x + width, y,          z + depth)
	glVertex3f(x + width, y + height, z + depth)
	glVertex3f(x + width, y + height, z)

	// y face
	glColor3f(0, 1, 0)
	glVertex3f(x,         y, z)
	glVertex3f(x,         y, z + depth)
	glVertex3f(x + width, y, z + depth)
	glVertex3f(x + width, y, z)

	// y + height face
	glColor3f(0, 1, 1)
	glVertex3f(x,         y + height, z)
	glVertex3f(x + width, y + height, z)
	glVertex3f(x + width, y + height, z + depth)
	glVertex3f(x,         y + height, z + depth)

	glEnd()
}

var touchXY = touchPosition()

// 3D on the top screen; console on the bottom.
lcdMainOnTop()
_ = consoleDemoInit()

videoSetMode(MODE_0_3D.rawValue)
glInit()
glEnable(Int32(GL_ANTIALIAS.rawValue))

// rear plane: opaque + unique poly ID so antialiasing works
glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glViewport(0, 0, 255, 191)

// camera
var rotX: Float = 0, rotY: Float = 0
var translate: Float = -5

// vertex/polygon RAM counters
var polygonCount: Int32 = 0
var vertexCount: Int32 = 0

// object rotation (driven by touch)
var rx: Int32 = 50, ry: Int32 = 15
var oldx: Int32 = 0, oldy: Int32 = 0

nds_puts("\u{1b}[10;0HPress A to change culling")
nds_puts("\n\nPress B to change Ortho vs Persp")
nds_puts("\nLeft/Right/Up/Down to rotate")
nds_puts("\nPress L and R to zoom")
nds_puts("\nTouch screen to rotate cube")

while pmMainLoop() {
	scanKeys()
	_ = touchRead(&touchXY)

	let held = keysHeld()
	let pressed = keysDown()

	if held & KEY_LEFT  != 0 { rotY += 1 }
	if held & KEY_RIGHT != 0 { rotY -= 1 }
	if held & KEY_UP    != 0 { rotX += 1 }
	if held & KEY_DOWN  != 0 { rotX -= 1 }
	if held & KEY_L     != 0 { translate += 0.1 }
	if held & KEY_R     != 0 { translate -= 0.1 }

	// reset reference point when the user first touches
	if pressed & KEY_TOUCH != 0 {
		oldx = Int32(touchXY.px)
		oldy = Int32(touchXY.py)
	}

	// drag delta rotates the cube
	if held & KEY_TOUCH != 0 {
		rx += Int32(touchXY.px) - oldx
		ry += Int32(touchXY.py) - oldy
		oldx = Int32(touchXY.px)
		oldy = Int32(touchXY.py)
	}

	// ortho vs perspective
	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	if held & KEY_B != 0 {
		glOrtho(-4, 4, -3, 3, 0.1, 10)
	} else {
		gluPerspective(70, 256.0 / 192.0, 0.1, 10)
	}

	// cull mode
	if held & KEY_A != 0 {
		glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	} else {
		glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_FRONT.rawValue))
	}

	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()

	// camera
	glRotateY(rotY)
	glRotateX(rotX)
	glTranslatef(0, 0, translate)

	// cube
	glRotateX(Float(ry))
	glRotateY(Float(rx))

	drawBox(-1, -1, -1, 2, 2, 2)

	threadWaitForVBlank()
	nds_puts("\u{1b}[0;0HBox test cycle count")

	cpuStartTiming(0)
	let hit = BoxTestf(-1, -1, -1, 2, 2, 2)
	nds_printf_1i("\nSingle test (float): %lu us", Int32(bitPattern: timerTicks2usec(cpuEndTiming())))

	cpuStartTiming(0)
	_ = BoxTest(inttov16(-1), inttov16(-1), inttov16(-1), inttov16(2), inttov16(2), inttov16(2))
	nds_printf_1i("\nSingle test (fixed): %lu us", Int32(bitPattern: timerTicks2usec(cpuEndTiming())))

	cpuStartTiming(0)
	for _ in 0 ..< 64 {
		_ = BoxTest(inttov16(-1), inttov16(-1), inttov16(-1), inttov16(2), inttov16(2), inttov16(2))
	}
	nds_printf_1i("\n64 tests avg. (fixed): %lu us", Int32(bitPattern: timerTicks2usec(cpuEndTiming() / 64)))
	nds_printf_str("\nBox Test result: %s", hit != 0 ? "hit" : "miss")

	while GFX_STATUS.load() & (1 << 27) != 0 {} // wait for the geometry engine

	glGetInt(GL_GET_VERTEX_RAM_COUNT, &vertexCount)
	glGetInt(GL_GET_POLYGON_RAM_COUNT, &polygonCount)

	nds_printf_str("\n\nRam usage: Culling %s", (held & KEY_A != 0) ? "none" : "back faces")
	nds_printf_1i("\nVertex ram: %i", vertexCount)
	nds_printf_1i("\nPolygon ram: %i", polygonCount)

	glFlush(0)
}
