//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 10b example (dovoto).
//
//  The all-fixed-point variant of lesson 10: the textured world is stored as
//  v16/t16 fixed-point vertices and the camera runs entirely on integer LUT
//  angles (Math.sin/Math.cos, GL.rotatef32i) — no floats, no fog, no shadow cube.
//
//  Controls: D-pad walk/turn, A/B look up/down, START to quit.
//
//---------------------------------------------------------------------------------

import NDS

let LUT_SIZE: Int32 = 1 << 15   // full circle in sinLerp angle units

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
	_ = GL.genTextures(1, &texture)
	GL.bindTexture(0, texture)
	_ = GL.texImage2D(target: 0, type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue | GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue),
	                  texture: pcx.image.data8)
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

	GL.loadIdentity()
	GL.rotatef32i(lookupdown, 1 << 12, 0, 0)
	GL.rotatef32i(sceneroty, 0, 1 << 12, 0)
	GL.translatef32(xtrans, ytrans, ztrans)
	GL.bindTexture(Int32(GL_TEXTURE_2D.rawValue), texture)

	for tri in world {
		GL.begin(.triangles)
		GL.normal(NORMAL_PACK(0, 0, 1 << 10))
		for vert in 0 ..< 3 {
			GL.texCoord16(tri.v[vert].u, tri.v[vert].v)
			GL.vertex16(tri.v[vert].x, tri.v[vert].y, tri.v[vert].z)
		}
		GL.end()
	}
}

//---------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------
Video.setMode(.mode0_3D)
Video.setBankA(VRAM_A_TEXTURE)

GL.initialize()
GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)

loadGLTextures()
setupWorld()

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)

GL.color(1, 1, 1)
GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0, y: floattov10(-1.0), z: 0)

GL.material(GL_AMBIENT,  Color(r: 16, g: 16, b: 16))
GL.material(GL_DIFFUSE,  Color(r: 16, g: 16, b: 16))
GL.material(GL_SPECULAR, Color(rawValue: (UInt16(1) << 15) | Color(r: 8, g: 8, b: 8).rawValue))
GL.material(GL_EMISSION, Color(r: 16, g: 16, b: 16))
GL.materialShininess()

GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | UInt32(POLY_FORMAT_LIGHT0.rawValue))
GL.matrixMode(.modelview)

while System.mainLoop {
	Keys.scan()
	let held = Keys.held

	if held.contains(.a) { lookupdown -= 1 }
	if held.contains(.b) { lookupdown += 1 }
	if held.contains(.left)  { heading += 64; yrot = heading }
	if held.contains(.right) { heading -= 64; yrot = heading }
	if held.contains(.down) {
		xpos += Int32(Math.sin(Int16(truncatingIfNeeded: heading))) / 20
		zpos += Int32(Math.cos(Int16(truncatingIfNeeded: heading))) / 20
		walkbiasangle += 640
		walkbias = Int32(Math.sin(Int16(truncatingIfNeeded: walkbiasangle))) / 20
	}
	if held.contains(.up) {
		xpos -= Int32(Math.sin(Int16(truncatingIfNeeded: heading))) / 20
		zpos -= Int32(Math.cos(Int16(truncatingIfNeeded: heading))) / 20
		walkbiasangle -= 640
		walkbias = Int32(Math.sin(Int16(truncatingIfNeeded: walkbiasangle))) / 20
	}

	drawGLScene()
	GL.flush()
	System.waitForVBlank()

	if held.contains(.start) { break }
}
