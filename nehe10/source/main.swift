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

import NDS

// LUT-based sin/cos (matches the C, which avoids libm). Angle in degrees.
@inline(__always) func luSin(_ angle: Float) -> Float {
	let a = angle.truncatingRemainder(dividingBy: 360)
	let idx = Int16(truncatingIfNeeded: Int32(a * Float(DEGREES_IN_CIRCLE) / 360))
	return Float(Math.sin(idx)) / 4096.0
}
@inline(__always) func luCos(_ angle: Float) -> Float {
	let a = angle.truncatingRemainder(dividingBy: 360)
	let idx = Int16(truncatingIfNeeded: Int32(a * Float(DEGREES_IN_CIRCLE) / 360))
	return Float(Math.cos(idx)) / 4096.0
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
	texture.withUnsafeMutableBufferPointer { _ = GL.genTextures(2, $0.baseAddress!) }

	var pcx = sImage()
	loadPCX(nds_asset_Mud_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	GL.bindTexture(0, texture[0])
	_ = GL.texImage2D(target: 0, type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue | GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue),
	                  texture: pcx.image.data8)
	imageDestroy(&pcx)

	loadPCX(nds_asset_drunkenlogo_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	GL.bindTexture(0, texture[1])
	_ = GL.texImage2D(target: 0, type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: pcx.image.data8)
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
	GL.rotate(cubeRotY, 0, 1, 0)
}

func emitCube() {
	GL.pushMatrix()
	GL.scale(0.03, 0.03, 0.03)
	GL.rotate(cubeRotY, 0, 1, 0)

	GL.begin(.quads)
	// Front
	GL.texCoord(0, 0); GL.vertex(-1, -1,  1)
	GL.texCoord(1, 0); GL.vertex( 1, -1,  1)
	GL.texCoord(1, 1); GL.vertex( 1,  1,  1)
	GL.texCoord(0, 1); GL.vertex(-1,  1,  1)
	// Back
	GL.texCoord(1, 0); GL.vertex(-1, -1, -1)
	GL.texCoord(1, 1); GL.vertex(-1,  1, -1)
	GL.texCoord(0, 1); GL.vertex( 1,  1, -1)
	GL.texCoord(0, 0); GL.vertex( 1, -1, -1)
	// Top
	GL.texCoord(0, 1); GL.vertex(-1,  1, -1)
	GL.texCoord(0, 0); GL.vertex(-1,  1,  1)
	GL.texCoord(1, 0); GL.vertex( 1,  1,  1)
	GL.texCoord(1, 1); GL.vertex( 1,  1, -1)
	// Bottom
	GL.texCoord(1, 1); GL.vertex(-1, -1, -1)
	GL.texCoord(0, 1); GL.vertex( 1, -1, -1)
	GL.texCoord(0, 0); GL.vertex( 1, -1,  1)
	GL.texCoord(1, 0); GL.vertex(-1, -1,  1)
	// Right
	GL.texCoord(1, 0); GL.vertex( 1, -1, -1)
	GL.texCoord(1, 1); GL.vertex( 1,  1, -1)
	GL.texCoord(0, 1); GL.vertex( 1,  1,  1)
	GL.texCoord(0, 0); GL.vertex( 1, -1,  1)
	// Left
	GL.texCoord(0, 0); GL.vertex(-1, -1, -1)
	GL.texCoord(1, 0); GL.vertex(-1, -1,  1)
	GL.texCoord(1, 1); GL.vertex(-1,  1,  1)
	GL.texCoord(0, 1); GL.vertex(-1,  1, -1)
	GL.end()
	GL.popMatrix()
}

func shadowDemo() {
	cubeRotY += 0.8

	// the cube itself, up in the air
	GL.pushMatrix()
	GL.translate(0, 0.4, -0.4)
	transformCube()
	GL.bindTexture(Int32(GL_TEXTURE_2D.rawValue), texture[1])
	emitCube()
	GL.popMatrix()

	// the shadow on the ground (DS shadow polygons, two passes)
	GL.pushMatrix()
	GL.translate(0, 0, -0.4)
	transformCube()

	GL.bindTexture(0, 0)
	GL.color(Color(r: 0, g: 8, b: 0))   // green, just to show colour is possible

	// 1st pass: shadow mask — front cull, polyID 0, alpha 1-30
	GL.polyFmt(UInt32(POLY_SHADOW.rawValue) | UInt32(POLY_CULL_FRONT.rawValue)
	           | POLY_ALPHA(15) | POLY_ID(0))
	emitCube()

	// 2nd pass: shadow render — no cull, polyID 1-63, alpha 1-30, fogged
	GL.polyFmt(UInt32(POLY_SHADOW.rawValue) | UInt32(POLY_CULL_NONE.rawValue)
	           | POLY_ALPHA(15) | POLY_ID(1) | UInt32(POLY_FOG.rawValue))
	emitCube()

	// reset poly attributes
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue)
	           | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FOG.rawValue))
	GL.popMatrix()
}

func drawGLScene() {
	let xtrans = -xpos
	let ztrans = -zpos
	let ytrans = -walkbias - 0.25
	let sceneroty = 360.0 - yrot

	GL.loadIdentity()
	GL.rotate(lookupdown, 1, 0, 0)
	GL.rotate(sceneroty, 0, 1, 0)
	GL.translate(xtrans, ytrans, ztrans)
	GL.bindTexture(Int32(GL_TEXTURE_2D.rawValue), texture[0])

	for tri in world {
		GL.begin(.triangles)
		GL.normal(0, 0, 1)
		for vert in 0 ..< 3 {
			GL.texCoord(tri.v[vert].u, tri.v[vert].v)
			GL.vertex(tri.v[vert].x, tri.v[vert].y, tri.v[vert].z)
		}
		GL.end()
	}

	shadowDemo()
}

//---------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------
Video.setMode(.mode0_3D)
Video.setBankA(VRAM_A_TEXTURE)
Console.demoInit()

GL.initialize()
GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.enable(Int32(GL_ANTIALIAS.rawValue))
GL.enable(Int32(GL_BLEND.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)

loadGLTextures()
setupWorld()

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)

GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0, y: floattov10(-1.0), z: 0)

GL.material(GL_AMBIENT,  Color(r: 16, g: 16, b: 16))
GL.material(GL_DIFFUSE,  Color(r: 16, g: 16, b: 16))
GL.material(GL_SPECULAR, Color(rawValue: (UInt16(1) << 15) | Color(r: 8, g: 8, b: 8).rawValue))
GL.material(GL_EMISSION, Color(r: 16, g: 16, b: 16))
GL.materialShininess()

GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue)
           | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FOG.rawValue))

GL.matrixMode(.modelview)

// fog parameters (arbitrary, tuned to illustrate fog)
GL.enable(Int32(GL_FOG.rawValue))
GL.fogShift(2)
GL.fogColor(r: 0, g: 0, b: 0, a: 0)
for i in Int32(0) ..< 32 { GL.fogDensity(index: i, i * 4) }
GL.fogDensity(index: 31, 127)
GL.fogOffset(0x6000)

while System.mainLoop {
	Keys.scan()
	let held = Keys.held

	if held.contains(.a) { lookupdown -= 1 }
	if held.contains(.b) { lookupdown += 1 }
	if held.contains(.left)  { heading += 1; yrot = heading }
	if held.contains(.right) { heading -= 1; yrot = heading }
	if held.contains(.down) {
		xpos += luSin(heading) * 0.05
		zpos += luCos(heading) * 0.05
		walkbiasangle = walkbiasangle >= 359 ? 0 : walkbiasangle + 10
		walkbias = luSin(walkbiasangle) / 20
	}
	if held.contains(.up) {
		xpos -= luSin(heading) * 0.05
		zpos -= luCos(heading) * 0.05
		walkbiasangle = walkbiasangle <= 1 ? 359 : walkbiasangle - 10
		walkbias = luSin(walkbiasangle) / 20
	}

	GL.color(1, 1, 1)
	drawGLScene()

	// don't auto-sort translucent polys — respect shadow draw order
	GL.flush(UInt32(GL_TRANS_MANUALSORT.rawValue))
	System.waitForVBlank()

	if held.contains(.start) { break }
}
