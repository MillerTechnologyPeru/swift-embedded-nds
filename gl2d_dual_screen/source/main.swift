//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "dual_screen" example (Relminator).
//
//  Renders the GL2D primitive demos and mirrors the 3D output onto the other
//  screen using the display-capture unit + a grid of bitmap sprites, alternating
//  every frame (so each screen updates at 30fps).
//
//---------------------------------------------------------------------------------

import NDS

let HALF_WIDTH: Int32 = 128
let HALF_HEIGHT: Int32 = 96
let BRAD_PI: Int32 = 1 << 14

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> Int32 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func slerp(_ a: Int32) -> Int32 { Int32(Math.sin(Int16(truncatingIfNeeded: a))) }
@inline(__always) func clerp(_ a: Int32) -> Int32 { Int32(Math.cos(Int16(truncatingIfNeeded: a))) }

func simple(_ frame: Int32) {
	GL2D.begin2D()
	let red = abs(slerp(frame &* 220) * 31) >> 12
	let green = abs(slerp(frame &* 140) * 31) >> 12
	let blue = abs(slerp(frame &* 40) * 31) >> 12

	GL2D.boxFilledGradient(x1: 0, y1: 0, x2: 255, y2: 191,
	                       color1: rgb15(red, green, blue), color2: rgb15(blue, 31 - red, green),
	                       color3: rgb15(green, blue, 31 - red), color4: rgb15(31 - green, red, blue))
	GL2D.boxFilled(x1: 200, y1: 10, x2: 250, y2: 180, color: rgb15(0, 0, 0))
	GL2D.box(x1: 200, y1: 10, x2: 250, y2: 180, color: rgb15(0, 31, 0))
	GL2D.triangleFilled(x1: 20, y1: 100, x2: 200, y2: 30, x3: 60, y3: 40, color: rgb15(31, 0, 31))
	GL2D.triangleFilledGradient(x1: 20, y1: 100, x2: 200, y2: 30, x3: 60, y3: 40,
	                            color1: rgb15(blue, red, green), color2: rgb15(green, blue, red), color3: rgb15(red, green, blue))

	GL.polyFmt(POLY_ALPHA(16) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
	GL2D.boxFilledGradient(x1: 10, y1: 50, x2: 230, y2: 150,
	                       color1: rgb15(green, 0, 0), color2: rgb15(0, red, 0), color3: rgb15(31, 0, blue), color4: rgb15(0, red, 31))
	GL.polyFmt(POLY_ALPHA(16) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(2))
	GL2D.triangleFilledGradient(x1: 70, y1: 10, x2: 20, y2: 130, x3: 230, y3: 180,
	                            color1: rgb15(red, green, blue), color2: rgb15(blue, red, green), color3: rgb15(green, blue, red))
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(3))

	for i in stride(from: 0, to: BRAD_PI * 2, by: 256) {
		let x = (clerp(i) * 80) >> 12
		let y = (slerp(i) * 70) >> 12
		GL2D.putPixel(x: HALF_WIDTH + x, y: HALF_HEIGHT + y, color: rgb15(red, green, blue))
	}
	GL2D.end2D()
}

func lines(_ frame: Int32) {
	let red = abs(slerp(frame &* 220) * 31) >> 12
	let green = abs(slerp(frame &* 140) * 31) >> 12
	let blue = abs(slerp(frame &* 40) * 31) >> 12

	GL2D.begin2D()
	var i = frame
	while i < (1 << 12) + frame {
		let px = ((slerp(frame &* 130) * 130) >> 12) * clerp(i &* 100)
		let py = ((slerp(frame &* 280) * 70) >> 12) * slerp(i &* 200)
		let px2 = ((slerp(frame &* 330) * 100) >> 12) * clerp(i &* 300 &+ BRAD_PI)
		let py2 = ((slerp(frame &* 140) * 80) >> 12) * slerp(i &* 400 &+ BRAD_PI)
		GL2D.line(x1: HALF_WIDTH + (px >> 12), y1: HALF_HEIGHT + (py >> 12),
		          x2: HALF_WIDTH + (px2 >> 12), y2: HALF_HEIGHT + (py2 >> 12), color: rgb15(red, green, blue))
		GL2D.line(x1: HALF_WIDTH + (py2 >> 12), y1: HALF_HEIGHT + (px >> 12),
		          x2: HALF_WIDTH + (py >> 12), y2: HALF_HEIGHT + (px2 >> 12), color: rgb15(green, blue, red))
		i += 32
	}
	GL2D.end2D()
}

func pixels(_ frame: Int32) {
	let radius = 40 + (abs(slerp(frame &* 20) * 80) >> 12)
	let red = abs(slerp(frame &* 220) * 31) >> 12
	let green = abs(slerp(frame &* 140) * 31) >> 12
	let blue = abs(slerp(frame &* 40) * 31) >> 12
	let i = (frame &* 140) & 32767

	GL2D.begin2D()
	for angle in stride(from: 0, to: BRAD_PI * 2, by: 64) {
		let a2 = angle + i
		var x = clerp(angle &* 2) * radius
		var y = slerp(x / 32 + a2) * radius
		x = clerp(y / 64 + angle) * (radius + 20)
		y = slerp(x / 64 + a2) * radius
		let x2 = -y
		let y2 = x
		GL2D.putPixel(x: HALF_WIDTH + (x >> 12), y: HALF_HEIGHT + (y >> 12), color: rgb15(red, green, blue))
		GL2D.putPixel(x: HALF_WIDTH + (x2 >> 12), y: HALF_HEIGHT + (y2 >> 12), color: rgb15(green, blue, red))
	}
	GL2D.end2D()
}

Video.setMode(.mode5_3D)
Video.setModeSub(.mode5_2D)

OAM.initSubSpritesGrid()              // OAM grid that displays the captured image
_ = Background.sub(layer: 3, kind: .bmp16, size: BgSize_B16_256x256, mapBase: 0, tileBase: 0)

GL2D.screen2D()

var frame: Int32 = 0
var demonum = 0

while System.mainLoop {
	frame += 1

	Keys.scan()
	let key = Keys.down
	if key.contains(.down) || key.contains(.right) { demonum = (demonum + 1) % 3 }
	if key.contains(.up) || key.contains(.left) { demonum -= 1; if demonum < 0 { demonum = 2 } }

	while DisplayCapture.isBusy {}   // wait for the capture unit

	// alternate which screen shows the live 3D render each frame
	if frame & 1 == 0 {
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

	let even = frame & 1 == 0
	switch demonum {
	case 0: even ? pixels(frame) : lines(frame)
	case 1: even ? lines(frame) : pixels(frame)
	case 2: even ? simple(frame) : lines(frame)
	default: even ? pixels(frame) : lines(frame)
	}

	GL.flush()
	System.waitForVBlank()
	if Keys.down.contains(.start) { break }
}
