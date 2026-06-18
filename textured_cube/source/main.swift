//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Textured_Cube example.
//
//  A lit, textured cube built by hand from vertex/normal/uv tables, with an
//  optional motion-blur trail (toggle with A) via the display-capture unit.
//
//---------------------------------------------------------------------------------

import CNDS
import _Volatile

// The GE texture-coordinate register, accessed directly from Swift via the
// Embedded `_Volatile` module instead of a C shim. (GFX_TEX_COORD == 0x04000488)
let GFX_TEX_COORD = VolatileMappedRegister<UInt32>(unsafeBitPattern: 0x04000488)

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattof32(_ n: Float) -> Int32 { Int32(n * Float(1 << 12)) }
@inline(__always) func floattov16(_ n: Float) -> Int16 { Int16(n * Float(1 << 12)) }
@inline(__always) func floattov10(_ n: Float) -> Int32 {
	n > 0.998 ? 0x1FF : Int32(n * Float(1 << 9))
}
@inline(__always) func inttot16(_ n: Int32) -> Int32 { n << 4 }
@inline(__always) func texturePack(_ u: Int32, _ v: Int32) -> UInt32 {
	UInt32(bitPattern: (u & 0xFFFF) | (v << 16))
}
@inline(__always) func normalPack(_ x: Int32, _ y: Int32, _ z: Int32) -> UInt32 {
	UInt32(bitPattern: (x & 0x3FF) | ((y & 0x3FF) << 10) | (z << 20))
}

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
	texturePack(inttot16(128), 0),
	texturePack(inttot16(128), inttot16(128)),
	texturePack(0, inttot16(128)),
	texturePack(0, 0),
]

// per-face normals
let normals: [UInt32] = [
	normalPack(0, floattov10(-0.97), 0),
	normalPack(0, 0, floattov10(0.97)),
	normalPack(floattov10(0.97), 0, 0),
	normalPack(0, 0, floattov10(-0.97)),
	normalPack(floattov10(-0.97), 0, 0),
	normalPack(0, floattov10(0.97), 0),
]

func drawQuad(_ poly: Int) {
	let f1 = cubeFaces[poly * 4]
	let f2 = cubeFaces[poly * 4 + 1]
	let f3 = cubeFaces[poly * 4 + 2]
	let f4 = cubeFaces[poly * 4 + 3]

	glNormal(normals[poly])

	GFX_TEX_COORD.store(uv[0])
	glVertex3v16(cubeVectors[f1 * 3], cubeVectors[f1 * 3 + 1], cubeVectors[f1 * 3 + 2])
	GFX_TEX_COORD.store(uv[1])
	glVertex3v16(cubeVectors[f2 * 3], cubeVectors[f2 * 3 + 1], cubeVectors[f2 * 3 + 2])
	GFX_TEX_COORD.store(uv[2])
	glVertex3v16(cubeVectors[f3 * 3], cubeVectors[f3 * 3 + 1], cubeVectors[f3 * 3 + 2])
	GFX_TEX_COORD.store(uv[3])
	glVertex3v16(cubeVectors[f4 * 3], cubeVectors[f4 * 3 + 1], cubeVectors[f4 * 3 + 2])
}

var textureID: Int32 = 0
var rotateX: Float = 0.0
var rotateY: Float = 0.0

videoSetMode(MODE_0_3D.rawValue)
glInit()
glEnable(Int32(GL_TEXTURE_2D.rawValue))
glViewport(0, 0, 255, 191)
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)

nds_motion_blur_setup()
nds_motion_blur_enable()
var displayBlurred = true

vramSetBankA(VRAM_A_TEXTURE)

glGenTextures(1, &textureID)
glBindTexture(0, textureID)
glTexImage2D(0, 0, GL_RGB,
             Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue), 0,
             Int32(TEXGEN_TEXCOORD.rawValue), nds_asset_texture_bin())

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 40)
gluLookAt(0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)

while pmMainLoop() {
	glLight(0, rgb15(31, 31, 31), 0,                  Int16(floattov10(-1.0)), 0)
	glLight(1, rgb15(31, 0, 31),  0,                  Int16(floattov10(1) - 1), 0)
	glLight(2, rgb15(0, 31, 0),   Int16(floattov10(-1.0)), 0,             0)
	glLight(3, rgb15(0, 0, 31),   Int16(floattov10(1) - 1), 0,           0)

	glPushMatrix()

	glTranslatef32(0, 0, floattof32(-1))
	glRotateX(rotateX)
	glRotateY(rotateY)

	glMatrixMode(GL_TEXTURE)
	glLoadIdentity()
	glMatrixMode(GL_MODELVIEW)

	glMaterialf(GL_AMBIENT, rgb15(8, 8, 8))
	glMaterialf(GL_DIFFUSE, rgb15(16, 16, 16))
	glMaterialf(GL_SPECULAR, (UInt16(1) << 15) | rgb15(8, 8, 8))
	glMaterialf(GL_EMISSION, rgb15(5, 5, 5))
	glMaterialShinyness()

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue)
	          | UInt32(POLY_FORMAT_LIGHT0.rawValue) | UInt32(POLY_FORMAT_LIGHT1.rawValue)
	          | UInt32(POLY_FORMAT_LIGHT2.rawValue) | UInt32(POLY_FORMAT_LIGHT3.rawValue))

	scanKeys()
	let keys = keysHeld()

	if keys & KEY_UP != 0    { rotateX += 3 }
	if keys & KEY_DOWN != 0  { rotateX -= 3 }
	if keys & KEY_LEFT != 0  { rotateY += 3 }
	if keys & KEY_RIGHT != 0 { rotateY -= 3 }

	if keysDown() & KEY_A != 0 {
		displayBlurred.toggle()
		if displayBlurred { nds_motion_blur_enable() } else { nds_motion_blur_disable() }
	}

	glBindTexture(0, textureID)

	glBegin(GL_QUAD)
	for i in 0 ..< 6 { drawQuad(i) }
	glEnd()

	glPopMatrix(1)
	glFlush(0)

	threadWaitForVBlank()

	if keys & KEY_START != 0 { break }

	// capture-enable must be re-set every frame to keep capturing
	nds_motion_blur_continue()
}
