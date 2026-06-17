//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 11 example -- waving texture.
//
//  A PCX texture mapped onto a 32x32 grid whose z-values ripple, producing a
//  waving "flag" that scrolls its wave each couple of frames.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func inttov16(_ n: Int32) -> Int32 { n << 12 }
@inline(__always) func inttot16(_ n: Int32) -> Int16 { Int16(n << 4) }

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
	glGenTextures(1, &texture0)
	glBindTexture(0, texture0)
	glTexImage2D(0, 0, GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
	             0, Int32(TEXGEN_TEXCOORD.rawValue), pcx.image.data8)
	imageDestroy(&pcx)
}

func drawGLScene() {
	glColor3b(255, 255, 255)
	glLoadIdentity()
	glTranslatef(0, 0, -12.0)
	glRotatef(xrot, 1, 0, 0)
	glRotatef(yrot, 0, 1, 0)
	glRotatef(zrot, 0, 0, 1)
	glBindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	glBegin(GL_QUADS)
	for x in 0 ..< 31 {
		for y in 0 ..< 31 {
			let fx = inttot16(Int32(x)) << 2
			let fy = inttot16(Int32(y)) << 2
			let fxb = inttot16(Int32(x + 1)) << 2
			let fyb = inttot16(Int32(y + 1)) << 2
			glTexCoord2t16(fx, fy)
			glVertex3v16(points[pidx(x, y, 0)], points[pidx(x, y, 1)], points[pidx(x, y, 2)])
			glTexCoord2t16(fx, fyb)
			glVertex3v16(points[pidx(x, y + 1, 0)], points[pidx(x, y + 1, 1)], points[pidx(x, y + 1, 2)])
			glTexCoord2t16(fxb, fyb)
			glVertex3v16(points[pidx(x + 1, y + 1, 0)], points[pidx(x + 1, y + 1, 1)], points[pidx(x + 1, y + 1, 2)])
			glTexCoord2t16(fxb, fy)
			glVertex3v16(points[pidx(x + 1, y, 0)], points[pidx(x + 1, y, 1)], points[pidx(x + 1, y, 2)])
		}
	}
	glEnd()

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

// build the grid: x/y on a plane, z a sine ripple
for x in 0 ..< 32 {
	for y in 0 ..< 32 {
		points[pidx(x, y, 0)] = Int16(inttov16(Int32(x)) / 4)
		points[pidx(x, y, 1)] = Int16(inttov16(Int32(y)) / 4)
		points[pidx(x, y, 2)] = sinLerp(Int16(truncatingIfNeeded: Int32(x) * ((1 << 15) / 32)))
	}
}

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(45, 256.0 / 192.0, 0.1, 100)
glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
glMatrixMode(GL_MODELVIEW)

while pmMainLoop() {
	drawGLScene()
	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
