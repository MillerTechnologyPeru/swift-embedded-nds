//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Textured_Cube example.
//
//  A lit, textured cube built by hand from vertex/normal/uv tables, with an
//  optional motion-blur trail (toggle with A) via the display-capture unit.
//
//---------------------------------------------------------------------------------

import NDS

// cube vertices (v16), 8 corners x (x,y,z)
let cubeVectors: [Int16] = [
	floattov16(-0.5), floattov16(-0.5), floattov16(0.5),
	floattov16(0.5),  floattov16(-0.5), floattov16(0.5),
	floattov16(0.5),  floattov16(-0.5), floattov16(-0.5),
	floattov16(-0.5), floattov16(-0.5), floattov16(-0.5),
	floattov16(-0.5), floattov16(0.5),  floattov16(0.5),
	floattov16(0.5),  floattov16(0.5),  floattov16(0.5),
	floattov16(0.5),  floattov16(0.5),  floattov16(-0.5),
	floattov16(-0.5), floattov16(0.5),  floattov16(-0.5),
]

// face index quads
let cubeFaces: [Int] = [
	3, 2, 1, 0,
	0, 1, 5, 4,
	1, 2, 6, 5,
	2, 3, 7, 6,
	3, 0, 4, 7,
	5, 6, 7, 4,
]

// texture coordinates per face corner
let uv: [UInt32] = [
	TEXTURE_PACK(inttot16(128), 0),
	TEXTURE_PACK(inttot16(128), inttot16(128)),
	TEXTURE_PACK(0, inttot16(128)),
	TEXTURE_PACK(0, 0),
]

// per-face normals
let normals: [UInt32] = [
	NORMAL_PACK(0, floattov10(-0.97), 0),
	NORMAL_PACK(0, 0, floattov10(0.97)),
	NORMAL_PACK(floattov10(0.97), 0, 0),
	NORMAL_PACK(0, 0, floattov10(-0.97)),
	NORMAL_PACK(floattov10(-0.97), 0, 0),
	NORMAL_PACK(0, floattov10(0.97), 0),
]

func drawQuad(_ poly: Int) {
	let f1 = cubeFaces[poly * 4]
	let f2 = cubeFaces[poly * 4 + 1]
	let f3 = cubeFaces[poly * 4 + 2]
	let f4 = cubeFaces[poly * 4 + 3]

	GL.normal(normals[poly])

	GL.submitPackedTexCoord(uv[0])
	GL.vertex16(cubeVectors[f1 * 3], cubeVectors[f1 * 3 + 1], cubeVectors[f1 * 3 + 2])
	GL.submitPackedTexCoord(uv[1])
	GL.vertex16(cubeVectors[f2 * 3], cubeVectors[f2 * 3 + 1], cubeVectors[f2 * 3 + 2])
	GL.submitPackedTexCoord(uv[2])
	GL.vertex16(cubeVectors[f3 * 3], cubeVectors[f3 * 3 + 1], cubeVectors[f3 * 3 + 2])
	GL.submitPackedTexCoord(uv[3])
	GL.vertex16(cubeVectors[f4 * 3], cubeVectors[f4 * 3 + 1], cubeVectors[f4 * 3 + 2])
}

var textureID: Int32 = 0
var rotateX: Float = 0.0
var rotateY: Float = 0.0

Video.setMode(.mode0_3D)
GL.initialize()
GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.viewport(0, 0, 255, 191)
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)

MotionBlur.setup()
MotionBlur.enable()
var displayBlurred = true

Video.setBankA(VRAM_A_TEXTURE)

_ = GL.genTextures(1, &textureID)
GL.bindTexture(0, textureID)
_ = GL.texImage2D(target: 0, type: GL_RGB,
                  sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: nds_asset_texture_bin())

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 40)
GL.lookAt(eye: (0.0, 0.0, 1.0), center: (0.0, 0.0, 0.0), up: (0.0, 1.0, 0.0))

while System.mainLoop {
	GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0,                y: floattov10(-1.0), z: 0)
	GL.light(1, color: Color(r: 31, g: 0, b: 31),  x: 0,                y: floattov10(1) - 1, z: 0)
	GL.light(2, color: Color(r: 0, g: 31, b: 0),   x: floattov10(-1.0), y: 0,                z: 0)
	GL.light(3, color: Color(r: 0, g: 0, b: 31),   x: floattov10(1) - 1, y: 0,               z: 0)

	GL.pushMatrix()

	GL.translatef32(0, 0, floattof32(-1))
	GL.rotateX(rotateX)
	GL.rotateY(rotateY)

	GL.matrixMode(.texture)
	GL.loadIdentity()
	GL.matrixMode(.modelview)

	GL.material(GL_AMBIENT, Color(r: 8, g: 8, b: 8))
	GL.material(GL_DIFFUSE, Color(r: 16, g: 16, b: 16))
	GL.material(GL_SPECULAR, Color(rawValue: (UInt16(1) << 15) | Color(r: 8, g: 8, b: 8).rawValue))
	GL.material(GL_EMISSION, Color(r: 5, g: 5, b: 5))
	GL.materialShininess()

	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
	           | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
	           | UInt32(POLY_FORMAT_LIGHT2.rawValue) | UInt32(POLY_FORMAT_LIGHT3.rawValue))

	Keys.scan()
	let keys = Keys.held

	if keys.contains(.up)    { rotateX += 3 }
	if keys.contains(.down)  { rotateX -= 3 }
	if keys.contains(.left)  { rotateY += 3 }
	if keys.contains(.right) { rotateY -= 3 }

	if Keys.down.contains(.a) {
		displayBlurred.toggle()
		if displayBlurred { MotionBlur.enable() } else { MotionBlur.disable() }
	}

	GL.bindTexture(0, textureID)

	GL.begin(.quads)
	for i in 0 ..< 6 { drawQuad(i) }
	GL.end()

	GL.popMatrix()
	GL.flush()

	System.waitForVBlank()

	if keys.contains(.start) { break }

	// capture-enable must be re-set every frame to keep capturing
	MotionBlur.continue()
}
