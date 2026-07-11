//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 3D_Both_Screens example.
//
//  Renders a spinning cube on the top screen and a pyramid on the bottom by
//  alternating the live 3D output between screens each frame via display capture
//  (the other screen shows the captured image through a grid of bitmap sprites).
//
//---------------------------------------------------------------------------------

import NDS

@inline(__always) func degreesToAngle(_ d: Int32) -> Int32 { d * (1 << 15) / 360 }

var angle: Int32 = 0

func renderCube(_ angle: Int32) {
	GL.pushMatrix()
	GL.translate(0, 0, -4)
	GL.rotatef32i(degreesToAngle(angle), inttof32(1), inttof32(1), inttof32(1))
	GL.begin(.quads)
	let faces: [(Float, Float, Float)] = [
		(-1, 1, 1), (1, 1, 1), (1, -1, 1), (-1, -1, 1),
		(-1, 1, -1), (1, 1, -1), (1, -1, -1), (-1, -1, -1),
		(-1, 1, 1), (1, 1, 1), (1, 1, -1), (-1, 1, -1),
		(-1, -1, 1), (1, -1, 1), (1, -1, -1), (-1, -1, -1),
		(1, 1, -1), (1, 1, 1), (1, -1, 1), (1, -1, -1),
		(-1, 1, -1), (-1, 1, 1), (-1, -1, 1), (-1, -1, -1),
	]
	let cols: [(UInt8, UInt8, UInt8)] = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
	for (i, v) in faces.enumerated() {
		let c = cols[i % 4]
		GL.color(r: c.0, g: c.1, b: c.2)
		GL.vertex(v.0, v.1, v.2)
	}
	GL.end()
	GL.popMatrix()
}

func renderPyramid(_ angle: Int32) {
	GL.pushMatrix()
	GL.translate(0, 0, -4)
	GL.rotatef32i(degreesToAngle(angle), inttof32(1), inttof32(1), inttof32(1))
	GL.begin(.quads)
		GL.color(r: 255, g: 0, b: 0); GL.vertex(-1, -1, 1)
		GL.color(r: 0, g: 255, b: 0); GL.vertex(1, -1, 1)
		GL.color(r: 0, g: 0, b: 255); GL.vertex(1, -1, -1)
		GL.color(r: 255, g: 255, b: 0); GL.vertex(-1, -1, -1)
	GL.end()
	GL.begin(.triangles)
	let tris: [(Float, Float, Float)] = [
		(0, 1, 0), (-1, -1, 1), (1, -1, 1),
		(0, 1, 0), (-1, -1, -1), (1, -1, -1),
		(0, 1, 0), (-1, -1, 1), (-1, -1, -1),
		(0, 1, 0), (1, -1, 1), (1, -1, -1),
	]
	let cols: [(UInt8, UInt8, UInt8)] = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
	for (i, v) in tris.enumerated() {
		let c = cols[i % 3]
		GL.color(r: c.0, g: c.1, b: c.2)
		GL.vertex(v.0, v.1, v.2)
	}
	GL.end()
	GL.popMatrix()
}

func renderScene(_ top: Bool) {
	if top { renderCube(angle) } else { renderPyramid(angle) }
	angle += 1
}

Video.setMode(.mode0_3D)
Video.setModeSub(.mode5_2D)
GL.initialize()
OAM.initSubSpritesGrid()
_ = Background.sub(layer: 3, kind: .bmp16, size: BgSize_B16_256x256, mapBase: 0, tileBase: 0)

GL.enable(Int32(GL_ANTIALIAS.rawValue))
GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)
GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)
GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

var top = true

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }

	while DisplayCapture.isBusy {}
	top.toggle()
	if top {
		System.lcdMainOnBottom()
		Video.setBankC(VRAM_C_LCD)
		Video.setBankD(VRAM_D_SUB_SPRITE)
		DisplayCapture.toBank(2)
	} else {
		System.lcdMainOnTop()
		Video.setBankD(VRAM_D_LCD)
		Video.setBankC(VRAM_C_SUB_BG)
		DisplayCapture.toBank(3)
	}

	renderScene(top)
	GL.flush()
}
