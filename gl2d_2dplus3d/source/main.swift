//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "2Dplus3D" example (Relminator).
//
//  Combines a real 3D textured mesh (a procedurally-built grid "vertex buffer",
//  ported from the example's C++ Cvertexbuffer class) with GL2D 2D sprites
//  composited on top.
//
//---------------------------------------------------------------------------------

import CNDS

let GRID_RINGS = 2, GRID_BANDS = 2
let GRID_WIDTH: Float = 15, GRID_HEIGHT: Float = 12
let BRAD_PI: Int32 = 1 << 14

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> UInt16 {
	UInt16(truncatingIfNeeded: r | (g << 5) | (b << 10))
}
@inline(__always) func slerp(_ a: Int32) -> Int32 { Int32(sinLerp(Int16(truncatingIfNeeded: a))) }
@inline(__always) func clerp(_ a: Int32) -> Int32 { Int32(cosLerp(Int16(truncatingIfNeeded: a))) }
@inline(__always) func floattof32(_ n: Float) -> Int32 { Int32(n * Float(1 << 12)) }
@inline(__always) func floattov16(_ n: Float) -> Int16 { Int16(truncatingIfNeeded: Int32(n * Float(1 << 12))) }
@inline(__always) func inttof32(_ n: Int32) -> Int32 { n * (1 << 12) }

// Ported from the example's C++ Cvertexbuffer class (the parts 2Dplus3D uses).
struct Vec3 { var x: Int16 = 0, y: Int16 = 0, z: Int16 = 0 }
struct TexCoord { var u: Int32 = 0, v: Int32 = 0 }
struct ColorF { var r: Int32 = 0, g: Int32 = 0, b: Int32 = 0 }
struct Poly { var v1 = 0, v2 = 0, v3 = 0 }

final class VertexBuffer {
	var maxPoly = 0
	var textureID: Int32 = 0
	var vertex: [Vec3] = []
	var texcoord: [TexCoord] = []
	var color: [ColorF] = []
	var poly: [Poly] = []

	func loadTexture(_ gfx: UnsafePointer<UInt8>) {
		glGenTextures(1, &textureID)
		glBindTexture(0, textureID)
		glTexImage2D(0, 0, GL_RGB, Int32(TEXTURE_SIZE_128.rawValue), Int32(TEXTURE_SIZE_128.rawValue),
		             0, Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue | TEXGEN_TEXCOORD.rawValue), gfx)
	}

	func render(_ offU: Int32, _ offV: Int32, _ colorize: Bool) {
		glEnable(Int32(GL_TEXTURE_2D.rawValue))
		glBindTexture(0, textureID)
		glBegin(GL_TRIANGLES)
		for i in 0 ..< maxPoly {
			for vi in [poly[i].v1, poly[i].v2, poly[i].v3] {
				if colorize {
					glColor3b(UInt8(truncatingIfNeeded: color[vi].r),
					          UInt8(truncatingIfNeeded: color[vi].g),
					          UInt8(truncatingIfNeeded: color[vi].b))
				}
				glTexCoord2f32(texcoord[vi].u + offU, texcoord[vi].v + offV)
				glVertex3v16(vertex[vi].x, vertex[vi].y, vertex[vi].z)
			}
		}
		glEnd()
	}
}

func initGrid(rings: Int, bands: Int, width: Float, height: Float, uscale: Int32, vscale: Int32) -> VertexBuffer {
	let vb = VertexBuffer()
	let maxPoint = rings * bands
	vb.vertex = [Vec3](repeating: Vec3(), count: maxPoint)
	vb.texcoord = [TexCoord](repeating: TexCoord(), count: maxPoint)
	vb.color = [ColorF](repeating: ColorF(), count: maxPoint)
	vb.poly = [Poly](repeating: Poly(), count: maxPoint * 2)
	vb.maxPoly = maxPoint * 2

	// connectivity (lathing)
	var i = 0
	for s in 0 ..< rings {
		let slice = s * bands
		for u in 0 ..< bands {
			vb.poly[i].v1 = (u + bands + 1 + slice) % maxPoint
			vb.poly[i].v2 = (u + bands + slice) % maxPoint
			vb.poly[i].v3 = (u + slice) % maxPoint
			vb.poly[i + 1].v1 = (u + slice) % maxPoint
			vb.poly[i + 1].v2 = (u + 1 + slice) % maxPoint
			vb.poly[i + 1].v3 = (u + bands + 1 + slice) % maxPoint
			i += 2
		}
	}

	let halfWidth = width / 2
	let halfHeight = height / 2
	let a1 = 2 * width / Float(rings)
	let a2 = 2 * height / Float(bands)
	var k = 0
	for i in 0 ..< rings {
		for j in 0 ..< bands {
			let x = -halfWidth + (Float(i) * a1)
			let z = -halfHeight + (Float(j) * a2)
			vb.vertex[k] = Vec3(x: floattov16(x), y: 0, z: floattov16(z))

			let c = Int32((1.0 - (Float(j * 4) / Float(bands))) * 255)
			vb.color[k] = ColorF(r: c, g: c, b: c)

			let u = (Float(i) / Float(rings)) * Float(uscale)
			let v = (Float(j) / Float(bands)) * Float(vscale)
			vb.texcoord[k] = TexCoord(u: floattof32(u), v: floattof32(v))
			k += 1
		}
	}
	return vb
}

let texParam = Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue
                     | TEXGEN_OFF.rawValue | GL_TEXTURE_COLOR0_TRANSPARENT.rawValue)

var enemies = [glImage](repeating: glImage(), count: Int(ENEMIES_NUM_IMAGES))
var shuttle = [glImage](repeating: glImage(), count: 1)
var flyer = [glImage](repeating: glImage(), count: 1)

let vb = initGrid(rings: GRID_RINGS, bands: GRID_BANDS, width: GRID_WIDTH, height: GRID_HEIGHT, uscale: 8, vscale: 8)

videoSetMode(MODE_5_3D.rawValue)
consoleDemoInit()
glScreen2D()
vramSetBankA(VRAM_A_TEXTURE)
vramSetBankE(VRAM_E_TEX_PALETTE)

vb.loadTexture(nds_asset_organ16Bitmap()!.assumingMemoryBound(to: UInt8.self))

enemies.withUnsafeMutableBufferPointer { buf in
	_ = glLoadSpriteSet(buf.baseAddress, UInt32(ENEMIES_NUM_IMAGES),
	                    nds_asset_enemies_texcoords()!.assumingMemoryBound(to: UInt32.self),
	                    GL_RGB256, Int32(TEXTURE_SIZE_256.rawValue), Int32(TEXTURE_SIZE_256.rawValue),
	                    texParam, 256, nds_asset_enemiesPal()!.assumingMemoryBound(to: UInt16.self),
	                    nds_asset_enemiesBitmap()!.assumingMemoryBound(to: UInt8.self))
}
shuttle.withUnsafeMutableBufferPointer { buf in
	_ = glLoadTileSet(buf.baseAddress, 64, 64, 64, 64, GL_RGB16,
	                  Int32(TEXTURE_SIZE_64.rawValue), Int32(TEXTURE_SIZE_64.rawValue),
	                  texParam, 16, nds_asset_shuttlePal()!.assumingMemoryBound(to: UInt16.self),
	                  nds_asset_shuttleBitmap()!.assumingMemoryBound(to: UInt8.self))
}
flyer.withUnsafeMutableBufferPointer { buf in
	_ = glLoadTileSet(buf.baseAddress, 64, 64, 64, 64, GL_RGB16,
	                  Int32(TEXTURE_SIZE_64.rawValue), Int32(TEXTURE_SIZE_64.rawValue),
	                  texParam, 16, nds_asset_flyerPal()!.assumingMemoryBound(to: UInt16.self),
	                  nds_asset_flyerBitmap()!.assumingMemoryBound(to: UInt8.self))
}

nds_puts("\u{1b}[1;1HEasy GL2D + 3D")
nds_puts("\u{1b}[2;1HRelminator")
nds_puts("\u{1b}[4;1HHttp://Rel.Phatcode.Net")
nds_puts("\u{1b}[6;1HCombining 3D and 2D")

var gridU: Int32 = 0
var gridV: Int32 = 0
var gridFrame: Int32 = 0

func drawGrid() {
	gridFrame += 1
	glPushMatrix()
	glLoadIdentity()
	glTranslatef32(0, 0, floattof32(3.0))
	glScalef32(floattof32(1), floattof32(1.5), floattof32(1.5))
	glPushMatrix()
	glTranslatef32(0, -1 << 12, -2 << 12)
	glRotateXi(inttof32(244))
	vb.render(gridU, gridV, true)
	glPopMatrix(1)
	glPushMatrix()
	glTranslatef32(0, 1 << 12, -2 << 12)
	glRotateXi(inttof32(180))
	vb.render(gridU, gridV, true)
	glPopMatrix(1)
	glPopMatrix(1)
	gridU = (slerp(gridFrame &* 30) &* 2) & 4095
	gridV = (slerp(-gridFrame &* 50) &* 3) & 4095
}

var ox: Int32 = 0, oy: Int32 = 0
var frame: Int32 = 0
var phoenixFrame = 0
var beeFrame: Int32 = 0

while pmMainLoop() {
	frame += 1
	let rotation = frame &* 240
	if frame & 7 == 0 {
		beeFrame = (beeFrame + 1) & 1
		phoenixFrame += 1
		if phoenixFrame > 2 { phoenixFrame = 0 }
	}

	let x = 128 + ((clerp(frame) + slerp(BRAD_PI &+ rotation) &* 70) >> 12)
	let y = 96 + ((clerp(frame) + clerp(-rotation) &* 50) >> 12)
	var sx = (clerp(frame &* 150) + slerp(frame &* 70)) &* (256 / 4)
	var sy = (slerp(-(frame &* 80)) + slerp(frame &* 190)) &* (192 / 4)
	let angle = Int32(bitPattern: nds_atan2_lerp(ox - sx, oy - sy))
	ox = sx; oy = sy
	sx = 128 + (sx >> 12)
	sy = 96 + (sy >> 12)

	drawGrid()

	glBegin2D()
	enemies.withUnsafeBufferPointer { e in
		glSpriteRotate(x, y, rotation, Int32(GL_FLIP_NONE.rawValue), e.baseAddress! + 30 + Int(beeFrame))
		glSpriteRotate(255 - x, 191 - y, rotation &* 4, Int32(GL_FLIP_H.rawValue), e.baseAddress! + 84)
		glSpriteRotate(255 - x, y, -rotation, Int32(GL_FLIP_V.rawValue), e.baseAddress! + 32)
		glSpriteRotate(x, 191 - y, -rotation &* 3, Int32(GL_FLIP_H.rawValue | GL_FLIP_V.rawValue), e.baseAddress! + 81)
		glSprite(200, 30, Int32(GL_FLIP_NONE.rawValue), e.baseAddress! + 87 + phoenixFrame)
		glColor(rgb15(31, 0, 0))
		glSprite(200, 60, Int32(GL_FLIP_H.rawValue), e.baseAddress! + 87 + phoenixFrame)
		glPolyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
		glColor(rgb15(0, 31, 20))
		glSprite(200, 90, Int32(GL_FLIP_V.rawValue), e.baseAddress! + 87 + phoenixFrame)
		glColor(rgb15(0, 0, 0))
		glSprite(200, 130, Int32(GL_FLIP_V.rawValue | GL_FLIP_H.rawValue), e.baseAddress! + 87 + phoenixFrame)
	}
	glColor(rgb15(31, 31, 31))
	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	shuttle.withUnsafeBufferPointer {
		glSpriteRotate(sx, sy, angle - (BRAD_PI / 2), Int32(GL_FLIP_NONE.rawValue), $0.baseAddress)
	}
	glPolyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(2))
	flyer.withUnsafeBufferPointer {
		glSpriteRotateScaleXY(128, 96, frame &* 140, slerp(frame &* 120) &* 3, slerp(frame &* 210) &* 2,
		                      Int32(GL_FLIP_NONE.rawValue), $0.baseAddress)
	}
	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	glEnd2D()

	glFlush(0)
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
