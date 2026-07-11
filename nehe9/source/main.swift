//---------------------------------------------------------------------------------
//
//  Swift port of the libnds NeHe Lesson 09 example -- blended star field.
//
//  50 additively-blended, colour-cycling "star" quads (a transparent PCX) spiral
//  in and out toward the camera.
//
//---------------------------------------------------------------------------------

import NDS

let NUM = 50

struct Star {
	var r: Int32 = 0, g: Int32 = 0, b: Int32 = 0
	var dist: Float = 0
	var angle: Float = 0
}

var stars = [Star](repeating: Star(), count: NUM)
let twinkle = false
var zoom: Float = -15.0
var tilt: Float = 90.0
var spin: Float = 0
var texture0: Int32 = 0

func loadGLTextures() {
	var pcx = sImage()
	loadPCX(nds_asset_Star_pcx()!.assumingMemoryBound(to: UInt8.self), &pcx)
	image8to16trans(&pcx, 0)
	_ = GL.genTextures(1, &texture0)
	GL.bindTexture(0, texture0)
	_ = GL.texImage2D(target: 0, type: GL_RGBA, sizeX: Int32(TEXTURE_SIZE_128.rawValue), sizeY: Int32(TEXTURE_SIZE_128.rawValue),
	                  param: Int32(TEXGEN_TEXCOORD.rawValue), texture: pcx.image.data8)
	imageDestroy(&pcx)
}

func quad() {
	GL.begin(.quads)
		GL.texCoord(0, 0); GL.vertex(-1, -1, 0)
		GL.texCoord(1, 0); GL.vertex(1, -1, 0)
		GL.texCoord(1, 1); GL.vertex(1, 1, 0)
		GL.texCoord(0, 1); GL.vertex(-1, 1, 0)
	GL.end()
}

func drawGLScene() {
	GL.bindTexture(Int32(GL_TEXTURE_2D.rawValue), texture0)
	for loop in 0 ..< NUM {
		GL.loadIdentity()
		GL.translate(0, 0, zoom)
		GL.rotate(tilt, 1, 0, 0)
		GL.rotate(stars[loop].angle, 0, 1, 0)
		GL.translate(stars[loop].dist, 0, 0)
		GL.rotate(-stars[loop].angle, 0, 1, 0)
		GL.rotate(-tilt, 1, 0, 0)
		if twinkle {
			let t = stars[NUM - loop - 1]
			GL.color(r: UInt8(truncatingIfNeeded: t.r), g: UInt8(truncatingIfNeeded: t.g), b: UInt8(truncatingIfNeeded: t.b))
			quad()
		}
		GL.rotate(spin, 0, 0, 1)
		GL.color(r: UInt8(truncatingIfNeeded: stars[loop].r),
		         g: UInt8(truncatingIfNeeded: stars[loop].g),
		         b: UInt8(truncatingIfNeeded: stars[loop].b))
		quad()

		spin += 0.01
		stars[loop].angle += Float(loop) / Float(NUM)
		stars[loop].dist -= 0.01
		if stars[loop].dist < 0 {
			stars[loop].dist += 5.0
			stars[loop].r = rand() % 256
			stars[loop].g = rand() % 256
			stars[loop].b = rand() % 256
		}
	}
}

Video.setMode(.mode0_3D)
Video.setBankA(VRAM_A_TEXTURE)
GL.initialize()
GL.enable(Int32(GL_ANTIALIAS.rawValue))

GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.enable(Int32(GL_TEXTURE_2D.rawValue))
GL.enable(Int32(GL_BLEND.rawValue))
GL.viewport(0, 0, 255, 191)

loadGLTextures()

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)
GL.color(1, 1, 1)

GL.light(0, color: Color(r: 31, g: 31, b: 31), x: 0, y: 0, z: floattov10(-1.0))
GL.material(GL_AMBIENT, Color(r: 16, g: 16, b: 16))
GL.material(GL_DIFFUSE, Color(r: 16, g: 16, b: 16))
GL.material(GL_SPECULAR, Color(rawValue: (UInt16(1) << 15) | Color(r: 8, g: 8, b: 8).rawValue))
GL.material(GL_EMISSION, Color(r: 16, g: 16, b: 16))
GL.materialShininess()
GL.polyFmt(POLY_ALPHA(15) | UInt32(POLY_CULL_BACK.rawValue) | UInt32(POLY_FORMAT_LIGHT0.rawValue))
GL.matrixMode(.modelview)

while System.mainLoop {
	drawGLScene()
	GL.flush()
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
