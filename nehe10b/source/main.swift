//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 10b example (dovoto).
//
//  The all-fixed-point variant of lesson 10: the textured world is stored as
//  v16/t16 fixed-point vertices and the camera runs entirely on integer LUT
//  angles (sinLerp/cosLerp, glRotatef32i) — no floats, no fog, no shadow cube.
//
//  Controls: D-pad walk/turn, A/B look up/down, START to quit.
//
//---------------------------------------------------------------------------------

import CNDS

let LUT_SIZE: Int32 = 1 << 15   // full circle in sinLerp angle units

//---------------------------------------------------------------------------------
// Fixed-point conversion helpers (function-like macros that don't import).
//---------------------------------------------------------------------------------
@inline(__always) func RGB15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattov10(_ n: Float) -> Int16 {
	n > 0.998 ? 0x1FF : Int16(n * Float(1 << 9))
}
@inline(__always) func floattov16(_ n: Float) -> Int16 {
	Int16(truncatingIfNeeded: Int32(n * Float(1 << 12)))
}
@inline(__always) func floattot16(_ n: Float) -> Int16 {
	Int16(truncatingIfNeeded: Int32(n * Float(1 << 4)))
}
@inline(__always) func normalPack(_ x: Int32, _ y: Int32, _ z: Int32) -> UInt32 {
	UInt32(bitPattern: (x & 0x3FF) | ((y & 0x3FF) << 10) | (z << 20))
}

//---------------------------------------------------------------------------------
// World model: fixed-point textured triangles, parsed from the embedded World.bin.
//---------------------------------------------------------------------------------
struct Vertex { var x: Int16 = 0, y: Int16 = 0, z: Int16 = 0, u: Int16 = 0, v: Int16 = 0 }
struct Triangle { var v = [Vertex](repeating: Vertex(), count: 3) }

var world = [Triangle]()

let worldPtr = nds_asset_World_bin()!.assumingMemoryBound(to: UInt8.self)
let worldLen = Int(World_bin_size)
var cursor = 0

func getLine() -> [UInt8] {
	var out = [UInt8]()
	while cursor < worldLen {
		let c = worldPtr[cursor]; cursor += 1
		if c == 0x0A || c == 0x0D { break }
		out.append(c)
	}
	return out
}

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

func parseFirstInt(_ b: [UInt8]) -> Int {
	var i = 0
	while i < b.count, !isDigit(b[i]) { i += 1 }
	var val = 0
	while i < b.count, isDigit(b[i]) { val = val * 10 + Int(b[i] - 0x30); i += 1 }
	return val
}

func setupWorld() {
	let numtriangles = parseFirstInt(readstr())   // "NUMPOLLIES n"
	world.reserveCapacity(numtriangles)

	for _ in 0 ..< numtriangles {
		var tri = Triangle()
		for vert in 0 ..< 3 {
			let line = readstr()
			var i = 0
			let x = parseFloat(line, &i)
			let y = parseFloat(line, &i)
			let z = parseFloat(line, &i)
			let u = parseFloat(line, &i)
			let v = parseFloat(line, &i)
			tri.v[vert].x = floattov16(x)
			tri.v[vert].y = floattov16(y)
			tri.v[vert].z = floattov16(z)
			tri.v[vert].u = floattot16(u * 128)
			tri.v[vert].v = floattot16(v * 128)
		}
		world.append(tri)
	}
}

//---------------------------------------------------------------------------------
// Texture (single Mud texture for this demo)
//---------------------------------------------------------------------------------
var texture: Int32 = 0

func loadGLTextures() {
	var pcx = sImage()
	loadPCX(nds_asset_Mud_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	glGenTextures(1, &texture)
	glBindTexture(0, texture)
	glTexImage2D(0, 0, GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue), 0,
	             Int32(TEXGEN_TEXCOORD.rawValue | GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue),
	             pcx.image.data8)
	imageDestroy(&pcx)
}

//---------------------------------------------------------------------------------
// Camera / movement state (all integer LUT angles / fixed-point positions)
//---------------------------------------------------------------------------------
var heading: Int32 = 0
var xpos: Int32 = 0
var zpos: Int32 = 0
var yrot: Int32 = 0
var walkbias: Int32 = 0
var walkbiasangle: Int32 = 0
var lookupdown: Int32 = 0

func drawGLScene() {
	let xtrans = -xpos
	let ztrans = -zpos
	let ytrans = -walkbias - (1 << 10)
	let sceneroty = LUT_SIZE - yrot

	glLoadIdentity()
	glRotatef32i(lookupdown, 1 << 12, 0, 0)
	glRotatef32i(sceneroty, 0, 1 << 12, 0)
	glTranslatef32(xtrans, ytrans, ztrans)
	glBindTexture(Int32(GL_TEXTURE_2D.rawValue), texture)

	for tri in world {
		glBegin(GL_TRIANGLES)
		glNormal(normalPack(0, 0, 1 << 10))
		for vert in 0 ..< 3 {
			glTexCoord2t16(tri.v[vert].u, tri.v[vert].v)
			glVertex3v16(tri.v[vert].x, tri.v[vert].y, tri.v[vert].z)
		}
		glEnd()
	}
}

//---------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------
videoSetMode(MODE_0_3D.rawValue)
vramSetBankA(VRAM_A_TEXTURE)

glInit()
glEnable(Int32(GL_TEXTURE_2D.rawValue))
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glViewport(0, 0, 255, 191)

loadGLTextures()
setupWorld()

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 100)

glColor3f(1, 1, 1)
glLight(0, RGB15(31, 31, 31), 0, floattov10(-1.0), 0)

glMaterialf(GL_AMBIENT,  RGB15(16, 16, 16))
glMaterialf(GL_DIFFUSE,  RGB15(16, 16, 16))
glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | RGB15(8, 8, 8))
glMaterialf(GL_EMISSION, RGB15(16, 16, 16))
glMaterialShinyness()

glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | UInt32(POLY_FORMAT_LIGHT0.rawValue))
glMatrixMode(GL_MODELVIEW)

while pmMainLoop() {
	scanKeys()
	let held = keysHeld()

	if held & KEY_A != 0 { lookupdown -= 1 }
	if held & KEY_B != 0 { lookupdown += 1 }
	if held & KEY_LEFT  != 0 { heading += 64; yrot = heading }
	if held & KEY_RIGHT != 0 { heading -= 64; yrot = heading }
	if held & KEY_DOWN != 0 {
		xpos += Int32(sinLerp(Int16(truncatingIfNeeded: heading))) / 20
		zpos += Int32(cosLerp(Int16(truncatingIfNeeded: heading))) / 20
		walkbiasangle += 640
		walkbias = Int32(sinLerp(Int16(truncatingIfNeeded: walkbiasangle))) / 20
	}
	if held & KEY_UP != 0 {
		xpos -= Int32(sinLerp(Int16(truncatingIfNeeded: heading))) / 20
		zpos -= Int32(cosLerp(Int16(truncatingIfNeeded: heading))) / 20
		walkbiasangle -= 640
		walkbias = Int32(sinLerp(Int16(truncatingIfNeeded: walkbiasangle))) / 20
	}

	drawGLScene()
	glFlush(0)
	threadWaitForVBlank()

	if held & KEY_START != 0 { break }
}
