//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Env_Mapping example.
//
//  Spherical reflection mapping: TEXGEN_NORMAL feeds vertex normals through the
//  texture matrix so a "cafe" texture is mapped onto a teapot display list as if
//  reflected from the environment. D-pad / stylus rotate.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func floattof32(_ n: Float) -> Int32 { Int32(n * Float(1 << 12)) }

var prevPenX: Int32 = 0x7FFFFFFF
var prevPenY: Int32 = 0x7FFFFFFF

func getPenDelta() -> (Int32, Int32) {
	var touchXY = touchPosition()
	if touchRead(&touchXY) {
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

videoSetMode(MODE_0_3D.rawValue)
glInit()
glEnable(Int32(GL_ANTIALIAS.rawValue))

glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)

glViewport(0, 0, 255, 191)

vramSetBankA(VRAM_A_TEXTURE)
glEnable(Int32(GL_TEXTURE_2D.rawValue))

var cafeTexId: Int32 = 0
glGenTextures(1, &cafeTexId)
glBindTexture(0, cafeTexId)
glTexImage2D(0, 0, GL_RGB,
             Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue), 0,
             GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue | TEXGEN_NORMAL.rawValue,
             nds_asset_cafe_bin())

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 40)

let teapot = nds_asset_teapot_bin()!.assumingMemoryBound(to: UInt32.self)

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	let keys = keysHeld()

	if keys & KEY_START != 0 { break }
	if keys & KEY_UP != 0    { rotateX += 1 << 7 }
	if keys & KEY_DOWN != 0  { rotateX -= 1 << 7 }
	if keys & KEY_LEFT != 0  { rotateY += 1 << 7 }
	if keys & KEY_RIGHT != 0 { rotateY -= 1 << 7 }

	// TEXGEN_NORMAL feeds our normals through this matrix as texcoords.
	glMatrixMode(GL_TEXTURE)
	glLoadIdentity()
	var texScale = GLvector(x: 64 << 16, y: -64 << 16, z: 1 << 16)
	glScalev(&texScale)   // scale normals from (-1,1) into texcoords
	glRotateXi(rotateX)   // rotate texture matrix to match the camera
	glRotateYi(rotateY)

	glMatrixMode(GL_POSITION)
	glLoadIdentity()
	glTranslatef32(0, 0, floattof32(-3))
	glRotateXi(rotateX)
	glRotateYi(rotateY)

	glMaterialf(GL_EMISSION, rgb15(31, 31, 31))

	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue))

	let (dx, dy) = getPenDelta()
	rotateY -= dx << 2
	rotateX -= dy << 2

	glBindTexture(0, cafeTexId)
	glCallList(teapot)

	glFlush(0)
}
