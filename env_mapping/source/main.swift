//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Env_Mapping example.
//
//  Spherical reflection mapping: TEXGEN_NORMAL feeds vertex normals through the
//  texture matrix so a "cafe" texture is mapped onto a teapot display list as if
//  reflected from the environment. D-pad / stylus rotate.
//
//---------------------------------------------------------------------------------

import NDS

var prevPenX: Int32 = 0x7FFFFFFF
var prevPenY: Int32 = 0x7FFFFFFF

func getPenDelta() -> (Int32, Int32) {
	var touchXY = touchPosition()
	if Touch.read(into: &touchXY) {
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

Video.setMode(.mode0_3D)
GL.initialize()
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)

GL.viewport(0, 0, 255, 191)

Video.setBankA(VRAM_A_TEXTURE)
GL.enable(Int32(GL_TEXTURE_2D.rawValue))

var cafeTexId: Int32 = 0
_ = GL.genTextures(1, &cafeTexId)
GL.bindTexture(0, cafeTexId)
_ = GL.texImage2D(target: 0, type: GL_RGB,
                  sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
                  param: Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue | TEXGEN_NORMAL.rawValue),
                  texture: nds_asset_cafe_bin())

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 40)

let teapot = nds_asset_teapot_bin()!.assumingMemoryBound(to: UInt32.self)

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	let keys = Keys.held

	if keys.contains(.start) { break }
	if keys.contains(.up)    { rotateX += 1 << 7 }
	if keys.contains(.down)  { rotateX -= 1 << 7 }
	if keys.contains(.left)  { rotateY += 1 << 7 }
	if keys.contains(.right) { rotateY -= 1 << 7 }

	// TEXGEN_NORMAL feeds our normals through this matrix as texcoords.
	GL.matrixMode(.texture)
	GL.loadIdentity()
	var texScale = GLvector(x: 64 << 16, y: -64 << 16, z: 1 << 16)
	glScalev(&texScale)   // scale normals from (-1,1) into texcoords
	GL.rotateXi(rotateX)  // rotate texture matrix to match the camera
	GL.rotateYi(rotateY)

	GL.matrixMode(.position)
	GL.loadIdentity()
	GL.translatef32(0, 0, floattof32(-3))
	GL.rotateXi(rotateX)
	GL.rotateYi(rotateY)

	GL.material(GL_EMISSION, Color(r: 31, g: 31, b: 31))

	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_BACK.rawValue))

	let (dx, dy) = getPenDelta()
	rotateY -= dx << 2
	rotateX -= dy << 2

	GL.bindTexture(0, cafeTexId)
	GL.callList(teapot)

	GL.flush()
}
