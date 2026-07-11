//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 11 example -- waving texture.
//
//  A PCX texture mapped onto a 32x32 grid whose z-values ripple, producing a
//  waving "flag" that scrolls its wave each couple of frames.
//
//---------------------------------------------------------------------------------

import NDS

// points[64][32][3] of v16; flat-indexed.  stride: x -> 32*3, y -> 3
var points = [Int16](repeating: 0, count: 64 * 32 * 3)
@inline(__always) func pidx(_ x: Int, _ y: Int, _ c: Int) -> Int { (x * 32 + y) * 3 + c }

var wiggleCount = 0
var xrot: Float = 0, yrot: Float = 0, zrot: Float = 0
var texture0: Int32 = 0

func loadGLTextures() {
	var pcx = sImage()
	loadPCX(nds_asset_drunkenlogo_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16(&pcx)
	_ = GL.genTextures(1, &texture0)
	GL.bindTexture(0, texture0)
	_ = GL.texImage2D(target: 0, type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: pcx.image.data8)
	imageDestroy(&pcx)
}

func drawGLScene() {
	GL.color(r: 255, g: 255, b: 255)
	GL.loadIdentity()
	GL.translate(0, 0, -12.0)
	GL.rotate(xrot, 1, 0, 0)
	GL.rotate(yrot, 0, 1, 0)
	GL.rotate(zrot, 0, 0, 1)
	GL.bindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	GL.begin(.quads)
	for x in 0 ..< 31 {
		for y in 0 ..< 31 {
			let fx = inttot16(Int32(x)) << 2
			let fy = inttot16(Int32(y)) << 2
			let fxb = inttot16(Int32(x + 1)) << 2
			let fyb = inttot16(Int32(y + 1)) << 2
			GL.texCoord16(fx, fy)
			GL.vertex16(points[pidx(x, y, 0)], points[pidx(x, y, 1)], points[pidx(x, y, 2)])
			GL.texCoord16(fx, fyb)
			GL.vertex16(points[pidx(x, y + 1, 0)], points[pidx(x, y + 1, 1)], points[pidx(x, y + 1, 2)])
			GL.texCoord16(fxb, fyb)
			GL.vertex16(points[pidx(x + 1, y + 1, 0)], points[pidx(x + 1, y + 1, 1)], points[pidx(x + 1, y + 1, 2)])
			GL.texCoord16(fxb, fy)
			GL.vertex16(points[pidx(x + 1, y, 0)], points[pidx(x + 1, y, 1)], points[pidx(x + 1, y, 2)])
		}
	}
	GL.end()

	// every couple of frames, scroll the wave one column along x
	if wiggleCount == 2 {
		for y in 0 ..< 32 {
			let hold = points[pidx(0, y, 2)]
			for x in 0 ..< 32 {
				points[pidx(x, y, 2)] = points[pidx(x + 1, y, 2)]
			}
			points[pidx(31, y, 2)] = hold
		}
		wiggleCount = 0
	}
	wiggleCount += 1
	xrot += 0.3
	yrot += 0.2
	zrot += 0.4
}

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

// build the grid: x/y on a plane, z a sine ripple (v16, wide intermediate)
for x in 0 ..< 32 {
	for y in 0 ..< 32 {
		points[pidx(x, y, 0)] = Int16((Int32(x) << 12) / 4)
		points[pidx(x, y, 1)] = Int16((Int32(y) << 12) / 4)
		points[pidx(x, y, 2)] = Math.sin(Int16(truncatingIfNeeded: Int32(x) * ((1 << 15) / 32)))
	}
}

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 45, aspect: 256.0 / 192.0, near: 0.1, far: 100)
GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
GL.matrixMode(.modelview)

while System.mainLoop {
	drawGLScene()
	GL.flush()
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
