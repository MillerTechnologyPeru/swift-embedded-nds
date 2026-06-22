//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 10 example (dovoto).
//
//  A first-person walk through a textured world loaded from an embedded text
//  file (World.txt, parsed at runtime), with hardware fog and a shadow-casting
//  spinning cube (DS shadow polygons).
//
//  Controls: D-pad walk/turn, A/B look up/down, START to quit.
//
//---------------------------------------------------------------------------------

import CNDS
import _Volatile

//---------------------------------------------------------------------------------
// Small helpers for function-like libnds macros the importer drops.
//---------------------------------------------------------------------------------
@inline(__always) func RGB15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}

// LUT-based sin/cos (matches the C, which avoids libm). Angle in degrees.
@inline(__always) func luSin(_ angle: Float) -> Float {
	let a = angle.truncatingRemainder(dividingBy: 360)
	let idx = Int16(truncatingIfNeeded: Int32(a * Float(DEGREES_IN_CIRCLE) / 360))
	return Float(sinLerp(idx)) / 4096.0
}
@inline(__always) func luCos(_ angle: Float) -> Float {
	let a = angle.truncatingRemainder(dividingBy: 360)
	let idx = Int16(truncatingIfNeeded: Int32(a * Float(DEGREES_IN_CIRCLE) / 360))
	return Float(cosLerp(idx)) / 4096.0
}

//---------------------------------------------------------------------------------
// World model: triangles of textured vertices, parsed from the embedded World.bin.
//---------------------------------------------------------------------------------
struct Vertex { var x: Float = 0, y: Float = 0, z: Float = 0, u: Float = 0, v: Float = 0 }
struct Triangle { var v = [Vertex](repeating: Vertex(), count: 3) }

var world = [Triangle]()

// --- minimal text scanning over the embedded byte buffer -------------------------
let worldPtr = nds_asset_World_bin()!.assumingMemoryBound(to: UInt8.self)
let worldLen = Int(World_bin_size)
var cursor = 0

// Read one line (bytes up to '\n' / 0x0D), advancing the cursor.
func getLine() -> [UInt8] {
	var out = [UInt8]()
	while cursor < worldLen {
		let c = worldPtr[cursor]; cursor += 1
		if c == 0x0A || c == 0x0D { break }
		out.append(c)
	}
	return out
}

// Skip blank and comment ('/') lines, like the C readstr().
func readstr() -> [UInt8] {
	while cursor < worldLen {
		let line = getLine()
		if line.isEmpty { continue }
		if line[0] == UInt8(ascii: "/") { continue }
		return line
	}
	return []
}

@inline(__always) func isDigit(_ c: UInt8) -> Bool { c >= 0x30 && c <= 0x39 }

func skipSpaces(_ b: [UInt8], _ i: inout Int) {
	while i < b.count, b[i] == 0x20 || b[i] == 0x09 { i += 1 }
}

// Parse a decimal float (sign, int part, optional fraction; no exponent).
func parseFloat(_ b: [UInt8], _ i: inout Int) -> Float {
	skipSpaces(b, &i)
	var neg = false
	if i < b.count, b[i] == UInt8(ascii: "-") || b[i] == UInt8(ascii: "+") {
		neg = b[i] == UInt8(ascii: "-"); i += 1
	}
	var val: Float = 0
	while i < b.count, isDigit(b[i]) { val = val * 10 + Float(b[i] - 0x30); i += 1 }
	if i < b.count, b[i] == UInt8(ascii: ".") {
		i += 1
		var scale: Float = 1
		while i < b.count, isDigit(b[i]) {
			scale *= 10; val += Float(b[i] - 0x30) / scale; i += 1
		}
	}
	return neg ? -val : val
}

// Parse the first integer found in a line (e.g. "NUMPOLLIES 36").
func parseFirstInt(_ b: [UInt8]) -> Int {
	var i = 0
	while i < b.count, !isDigit(b[i]) { i += 1 }
	var val = 0
	while i < b.count, isDigit(b[i]) { val = val * 10 + Int(b[i] - 0x30); i += 1 }
	return val
}

func setupWorld() {
	let header = readstr()
	let numtriangles = parseFirstInt(header)   // "NUMPOLLIES n"
	world.reserveCapacity(numtriangles)

	for _ in 0 ..< numtriangles {
		var tri = Triangle()
		for vert in 0 ..< 3 {
			let line = readstr()
			var i = 0
			tri.v[vert].x = parseFloat(line, &i)
			tri.v[vert].y = parseFloat(line, &i)
			tri.v[vert].z = parseFloat(line, &i)
			tri.v[vert].u = parseFloat(line, &i)
			tri.v[vert].v = parseFloat(line, &i)
		}
		world.append(tri)
	}
}

//---------------------------------------------------------------------------------
// Textures
//---------------------------------------------------------------------------------
var texture = [Int32](repeating: 0, count: 2)

func loadGLTextures() {
	texture.withUnsafeMutableBufferPointer { glGenTextures(2, $0.baseAddress) }

	var pcx = sImage()
	loadPCX(nds_asset_Mud_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	glBindTexture(0, texture[0])
	glTexImage2D(0, 0, GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue), 0,
	             Int32(TEXGEN_TEXCOORD.rawValue | GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue),
	             pcx.image.data8)
	imageDestroy(&pcx)

	loadPCX(nds_asset_drunkenlogo_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	glBindTexture(0, texture[1])
	glTexImage2D(0, 0, GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue), 0,
	             Int32(TEXGEN_TEXCOORD.rawValue), pcx.image.data8)
	imageDestroy(&pcx)
}

//---------------------------------------------------------------------------------
// Camera / movement state
//---------------------------------------------------------------------------------
var heading: Float = 0
var xpos: Float = 0
var zpos: Float = 0
var yrot: Float = 0
var walkbias: Float = 0
var walkbiasangle: Float = 0
var lookupdown: Float = 0

var cubeRotY: Float = 0

func transformCube() {
	glRotatef(cubeRotY, 0, 1, 0)
}

func emitCube() {
	glPushMatrix()
	glScalef(0.03, 0.03, 0.03)
	glRotatef(cubeRotY, 0, 1, 0)

	glBegin(GL_QUADS)
	// Front
	glTexCoord2f(0, 0); glVertex3f(-1, -1,  1)
	glTexCoord2f(1, 0); glVertex3f( 1, -1,  1)
	glTexCoord2f(1, 1); glVertex3f( 1,  1,  1)
	glTexCoord2f(0, 1); glVertex3f(-1,  1,  1)
	// Back
	glTexCoord2f(1, 0); glVertex3f(-1, -1, -1)
	glTexCoord2f(1, 1); glVertex3f(-1,  1, -1)
	glTexCoord2f(0, 1); glVertex3f( 1,  1, -1)
	glTexCoord2f(0, 0); glVertex3f( 1, -1, -1)
	// Top
	glTexCoord2f(0, 1); glVertex3f(-1,  1, -1)
	glTexCoord2f(0, 0); glVertex3f(-1,  1,  1)
	glTexCoord2f(1, 0); glVertex3f( 1,  1,  1)
	glTexCoord2f(1, 1); glVertex3f( 1,  1, -1)
	// Bottom
	glTexCoord2f(1, 1); glVertex3f(-1, -1, -1)
	glTexCoord2f(0, 1); glVertex3f( 1, -1, -1)
	glTexCoord2f(0, 0); glVertex3f( 1, -1,  1)
	glTexCoord2f(1, 0); glVertex3f(-1, -1,  1)
	// Right
	glTexCoord2f(1, 0); glVertex3f( 1, -1, -1)
	glTexCoord2f(1, 1); glVertex3f( 1,  1, -1)
	glTexCoord2f(0, 1); glVertex3f( 1,  1,  1)
	glTexCoord2f(0, 0); glVertex3f( 1, -1,  1)
	// Left
	glTexCoord2f(0, 0); glVertex3f(-1, -1, -1)
	glTexCoord2f(1, 0); glVertex3f(-1, -1,  1)
	glTexCoord2f(1, 1); glVertex3f(-1,  1,  1)
	glTexCoord2f(0, 1); glVertex3f(-1,  1, -1)
	glEnd()
	glPopMatrix(1)
}

func shadowDemo() {
	cubeRotY += 0.8

	// the cube itself, up in the air
	glPushMatrix()
	glTranslatef(0, 0.4, -0.4)
	transformCube()
	glBindTexture(Int32(GL_TEXTURE_2D.rawValue), texture[1])
	emitCube()
	glPopMatrix(1)

	// the shadow on the ground (DS shadow polygons, two passes)
	glPushMatrix()
	glTranslatef(0, 0, -0.4)
	transformCube()

	glBindTexture(0, 0)
	glColor(RGB15(0, 8, 0))   // green, just to show colour is possible

	// 1st pass: shadow mask — front cull, polyID 0, alpha 1-30
	glPolyFmt(UInt32(POLY_SHADOW.rawValue) | UInt32(POLY_CULL_FRONT.rawValue)
	          | POLY_ALPHA(15) | POLY_ID(0))
	emitCube()

	// 2nd pass: shadow render — no cull, polyID 1-63, alpha 1-30, fogged
	glPolyFmt(UInt32(POLY_SHADOW.rawValue) | UInt32(POLY_CULL_NONE.rawValue)
	          | POLY_ALPHA(15) | POLY_ID(1) | UInt32(POLY_FOG.rawValue))
	emitCube()

	// reset poly attributes
	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue)
	          | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FOG.rawValue))
	glPopMatrix(1)
}

func drawGLScene() {
	let xtrans = -xpos
	let ztrans = -zpos
	let ytrans = -walkbias - 0.25
	let sceneroty = 360.0 - yrot

	glLoadIdentity()
	glRotatef(lookupdown, 1, 0, 0)
	glRotatef(sceneroty, 0, 1, 0)
	glTranslatef(xtrans, ytrans, ztrans)
	glBindTexture(Int32(GL_TEXTURE_2D.rawValue), texture[0])

	for tri in world {
		glBegin(GL_TRIANGLES)
		glNormal3f(0, 0, 1)
		for vert in 0 ..< 3 {
			glTexCoord2f(tri.v[vert].u, tri.v[vert].v)
			glVertex3f(tri.v[vert].x, tri.v[vert].y, tri.v[vert].z)
		}
		glEnd()
	}

	shadowDemo()
}

//---------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------
videoSetMode(MODE_0_3D.rawValue)
vramSetBankA(VRAM_A_TEXTURE)
_ = consoleDemoInit()

glInit()
glEnable(Int32(GL_TEXTURE_2D.rawValue))
glEnable(Int32(GL_ANTIALIAS.rawValue))
glEnable(Int32(GL_BLEND.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glViewport(0, 0, 255, 191)

loadGLTextures()
setupWorld()

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 100)

glLight(0, RGB15(31, 31, 31), 0, floattov10(-1.0), 0)

glMaterialf(GL_AMBIENT,  RGB15(16, 16, 16))
glMaterialf(GL_DIFFUSE,  RGB15(16, 16, 16))
glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | RGB15(8, 8, 8))
glMaterialf(GL_EMISSION, RGB15(16, 16, 16))
glMaterialShinyness()

glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue)
          | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FOG.rawValue))

glMatrixMode(GL_MODELVIEW)

// fog parameters (arbitrary, tuned to illustrate fog)
glEnable(Int32(GL_FOG.rawValue))
glFogShift(2)
glFogColor(0, 0, 0, 0)
for i in Int32(0) ..< 32 { glFogDensity(i, i * 4) }
glFogDensity(31, 127)
glFogOffset(0x6000)

while pmMainLoop() {
	scanKeys()
	let held = keysHeld()

	if held & KEY_A != 0 { lookupdown -= 1 }
	if held & KEY_B != 0 { lookupdown += 1 }
	if held & KEY_LEFT  != 0 { heading += 1; yrot = heading }
	if held & KEY_RIGHT != 0 { heading -= 1; yrot = heading }
	if held & KEY_DOWN != 0 {
		xpos += luSin(heading) * 0.05
		zpos += luCos(heading) * 0.05
		walkbiasangle = walkbiasangle >= 359 ? 0 : walkbiasangle + 10
		walkbias = luSin(walkbiasangle) / 20
	}
	if held & KEY_UP != 0 {
		xpos -= luSin(heading) * 0.05
		zpos -= luCos(heading) * 0.05
		walkbiasangle = walkbiasangle <= 1 ? 359 : walkbiasangle - 10
		walkbias = luSin(walkbiasangle) / 20
	}

	glColor3f(1, 1, 1)
	drawGLScene()

	// don't auto-sort translucent polys — respect shadow draw order
	glFlush(UInt32(GL_TRANS_MANUALSORT.rawValue))
	threadWaitForVBlank()

	if held & KEY_START != 0 { break }
}
