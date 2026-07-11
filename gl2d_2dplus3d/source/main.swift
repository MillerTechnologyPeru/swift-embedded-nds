//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "2Dplus3D" example (Relminator).
//
//  Combines a real 3D textured mesh (a procedurally-built grid "vertex buffer",
//  ported from the example's C++ Cvertexbuffer class) with GL2D 2D sprites
//  composited on top.
//
//---------------------------------------------------------------------------------

import NDS

let GRID_RINGS = 2, GRID_BANDS = 2
let GRID_WIDTH: Float = 15, GRID_HEIGHT: Float = 12
let BRAD_PI: Int32 = 1 << 14
let FLIP_NONE = Int32(GL_FLIP_NONE.rawValue)
let FLIP_H = Int32(GL_FLIP_H.rawValue)
let FLIP_V = Int32(GL_FLIP_V.rawValue)

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> Color {
	Color(rawValue: UInt16(truncatingIfNeeded: r | (g << 5) | (b << 10)))
}
@inline(__always) func slerp(_ a: Int32) -> Int32 { Int32(Math.sin(Int16(truncatingIfNeeded: a))) }
@inline(__always) func clerp(_ a: Int32) -> Int32 { Int32(Math.cos(Int16(truncatingIfNeeded: a))) }

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
		_ = GL.genTextures(1, &textureID)
		GL.bindTexture(0, textureID)
		_ = GL.texImage2D(target: 0, type: GL_RGB, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
		                  param: Int32(GL_TEXTURE_WRAP_S.rawValue | GL_TEXTURE_WRAP_T.rawValue | TEXGEN_TEXCOORD.rawValue), texture: gfx)
	}

	func render(_ offU: Int32, _ offV: Int32, _ colorize: Bool) {
		GL.enable(Int32(GL_TEXTURE_2D.rawValue))
		GL.bindTexture(0, textureID)
		GL.begin(.triangles)
		for i in 0 ..< maxPoly {
			for vi in [poly[i].v1, poly[i].v2, poly[i].v3] {
				if colorize {
					GL.color(r: UInt8(truncatingIfNeeded: color[vi].r),
					         g: UInt8(truncatingIfNeeded: color[vi].g),
					         b: UInt8(truncatingIfNeeded: color[vi].b))
				}
				GL.texCoordf32(texcoord[vi].u + offU, texcoord[vi].v + offV)
				GL.vertex16(vertex[vi].x, vertex[vi].y, vertex[vi].z)
			}
		}
		GL.end()
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

Video.setMode(.mode5_3D)
Console.demoInit()
GL2D.screen2D()
Video.setBankA(VRAM_A_TEXTURE)
Video.setBankE(VRAM_E_TEX_PALETTE)

vb.loadTexture(nds_asset_organ16Bitmap()!.assumingMemoryBound(to: UInt8.self))

enemies.withUnsafeMutableBufferPointer { buf in
	GL2D.loadSpriteSet(buf.baseAddress!, frames: UInt32(ENEMIES_NUM_IMAGES),
	                   texcoords: nds_asset_enemies_texcoords()!.assumingMemoryBound(to: UInt32.self),
	                   type: GL_RGB256, sizeX: Int32(TEXTURE_SIZE_256.rawValue), sizeY: Int32(TEXTURE_SIZE_256.rawValue),
	                   param: texParam, paletteWidth: 256, palette: nds_asset_enemiesPal()!.assumingMemoryBound(to: UInt16.self),
	                   texture: nds_asset_enemiesBitmap()!.assumingMemoryBound(to: UInt8.self))
}
shuttle.withUnsafeMutableBufferPointer { buf in
	GL2D.loadTileSet(buf.baseAddress!, tileWidth: 64, tileHeight: 64, bmpWidth: 64, bmpHeight: 64, type: GL_RGB16,
	                 sizeX: Int32(TEXTURE_SIZE_64.rawValue), sizeY: Int32(TEXTURE_SIZE_64.rawValue),
	                 param: texParam, paletteWidth: 16, palette: nds_asset_shuttlePal()!.assumingMemoryBound(to: UInt16.self),
	                 texture: nds_asset_shuttleBitmap()!.assumingMemoryBound(to: UInt8.self))
}
flyer.withUnsafeMutableBufferPointer { buf in
	GL2D.loadTileSet(buf.baseAddress!, tileWidth: 64, tileHeight: 64, bmpWidth: 64, bmpHeight: 64, type: GL_RGB16,
	                 sizeX: Int32(TEXTURE_SIZE_64.rawValue), sizeY: Int32(TEXTURE_SIZE_64.rawValue),
	                 param: texParam, paletteWidth: 16, palette: nds_asset_flyerPal()!.assumingMemoryBound(to: UInt16.self),
	                 texture: nds_asset_flyerBitmap()!.assumingMemoryBound(to: UInt8.self))
}

Console.print("\u{1b}[1;1HEasy GL2D + 3D")
Console.print("\u{1b}[2;1HRelminator")
Console.print("\u{1b}[4;1HHttp://Rel.Phatcode.Net")
Console.print("\u{1b}[6;1HCombining 3D and 2D")

var gridU: Int32 = 0
var gridV: Int32 = 0
var gridFrame: Int32 = 0

func drawGrid() {
	gridFrame += 1
	GL.pushMatrix()
	GL.loadIdentity()
	GL.translatef32(0, 0, floattof32(3.0))
	GL.scalef32(floattof32(1), floattof32(1.5), floattof32(1.5))
	GL.pushMatrix()
	GL.translatef32(0, -1 << 12, -2 << 12)
	GL.rotateXi(inttof32(244))
	vb.render(gridU, gridV, true)
	GL.popMatrix()
	GL.pushMatrix()
	GL.translatef32(0, 1 << 12, -2 << 12)
	GL.rotateXi(inttof32(180))
	vb.render(gridU, gridV, true)
	GL.popMatrix()
	GL.popMatrix()
	gridU = (slerp(gridFrame &* 30) &* 2) & 4095
	gridV = (slerp(-gridFrame &* 50) &* 3) & 4095
}

var ox: Int32 = 0, oy: Int32 = 0
var frame: Int32 = 0
var phoenixFrame = 0
var beeFrame: Int32 = 0

while System.mainLoop {
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
	let angle = Int32(bitPattern: Math.atan2(x: ox - sx, y: oy - sy))
	ox = sx; oy = sy
	sx = 128 + (sx >> 12)
	sy = 96 + (sy >> 12)

	drawGrid()

	GL2D.begin2D()
	enemies.withUnsafeBufferPointer { e in
		GL2D.spriteRotate(x: x, y: y, angle: rotation, flip: FLIP_NONE, e.baseAddress! + 30 + Int(beeFrame))
		GL2D.spriteRotate(x: 255 - x, y: 191 - y, angle: rotation &* 4, flip: FLIP_H, e.baseAddress! + 84)
		GL2D.spriteRotate(x: 255 - x, y: y, angle: -rotation, flip: FLIP_V, e.baseAddress! + 32)
		GL2D.spriteRotate(x: x, y: 191 - y, angle: -rotation &* 3, flip: FLIP_H | FLIP_V, e.baseAddress! + 81)
		GL2D.sprite(x: 200, y: 30, flip: FLIP_NONE, e.baseAddress! + 87 + phoenixFrame)
		GL.color(rgb15(31, 0, 0))
		GL2D.sprite(x: 200, y: 60, flip: FLIP_H, e.baseAddress! + 87 + phoenixFrame)
		GL.polyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
		GL.color(rgb15(0, 31, 20))
		GL2D.sprite(x: 200, y: 90, flip: FLIP_V, e.baseAddress! + 87 + phoenixFrame)
		GL.color(rgb15(0, 0, 0))
		GL2D.sprite(x: 200, y: 130, flip: FLIP_V | FLIP_H, e.baseAddress! + 87 + phoenixFrame)
	}
	GL.color(rgb15(31, 31, 31))
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	shuttle.withUnsafeBufferPointer {
		GL2D.spriteRotate(x: sx, y: sy, angle: angle - (BRAD_PI / 2), flip: FLIP_NONE, $0.baseAddress!)
	}
	GL.polyFmt(POLY_ALPHA(20) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(2))
	flyer.withUnsafeBufferPointer {
		GL2D.spriteRotateScaleXY(x: 128, y: 96, angle: frame &* 140, scaleX: slerp(frame &* 120) &* 3, scaleY: slerp(frame &* 210) &* 2,
		                         flip: FLIP_NONE, $0.baseAddress!)
	}
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
	GL2D.end2D()

	GL.flush()
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
