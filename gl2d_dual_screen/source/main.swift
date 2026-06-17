//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Easy GL2D "dual_screen" example (Relminator).
//
//  Renders the GL2D primitive demos and mirrors the 3D output onto the other
//  screen using the display-capture unit + a grid of bitmap sprites, alternating
//  every frame (so each screen updates at 30fps).
//
//---------------------------------------------------------------------------------

import CNDS

let HALF_WIDTH: Int32 = 128
let HALF_HEIGHT: Int32 = 96
let BRAD_PI: Int32 = 1 << 14

@inline(__always) func rgb15(_ r: Int32, _ g: Int32, _ b: Int32) -> Int32 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func slerp(_ a: Int32) -> Int32 { Int32(sinLerp(Int16(truncatingIfNeeded: a))) }
@inline(__always) func clerp(_ a: Int32) -> Int32 { Int32(cosLerp(Int16(truncatingIfNeeded: a))) }

func simple(_ frame: Int32) {
	glBegin2D()
	let red = abs(slerp(frame &* 220) * 31) >> 12
	let green = abs(slerp(frame &* 140) * 31) >> 12
	let blue = abs(slerp(frame &* 40) * 31) >> 12

	glBoxFilledGradient(0, 0, 255, 191,
	                    rgb15(red, green, blue), rgb15(blue, 31 - red, green),
	                    rgb15(green, blue, 31 - red), rgb15(31 - green, red, blue))
	glBoxFilled(200, 10, 250, 180, rgb15(0, 0, 0))
	glBox(200, 10, 250, 180, rgb15(0, 31, 0))
	glTriangleFilled(20, 100, 200, 30, 60, 40, rgb15(31, 0, 31))
	glTriangleFilledGradient(20, 100, 200, 30, 60, 40,
	                         rgb15(blue, red, green), rgb15(green, blue, red), rgb15(red, green, blue))

	glPolyFmt(POLY_ALPHA(16) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(1))
	glBoxFilledGradient(10, 50, 230, 150,
	                    rgb15(green, 0, 0), rgb15(0, red, 0), rgb15(31, 0, blue), rgb15(0, red, 31))
	glPolyFmt(POLY_ALPHA(16) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(2))
	glTriangleFilledGradient(70, 10, 20, 130, 230, 180,
	                         rgb15(red, green, blue), rgb15(blue, red, green), rgb15(green, blue, red))
	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue) | POLY_ID(3))

	for i in stride(from: 0, to: BRAD_PI * 2, by: 256) {
		let x = (clerp(i) * 80) >> 12
		let y = (slerp(i) * 70) >> 12
		glPutPixel(HALF_WIDTH + x, HALF_HEIGHT + y, rgb15(red, green, blue))
	}
	glEnd2D()
}

func lines(_ frame: Int32) {
	let red = abs(slerp(frame &* 220) * 31) >> 12
	let green = abs(slerp(frame &* 140) * 31) >> 12
	let blue = abs(slerp(frame &* 40) * 31) >> 12

	glBegin2D()
	var i = frame
	while i < (1 << 12) + frame {
		let px = ((slerp(frame &* 130) * 130) >> 12) * clerp(i &* 100)
		let py = ((slerp(frame &* 280) * 70) >> 12) * slerp(i &* 200)
		let px2 = ((slerp(frame &* 330) * 100) >> 12) * clerp(i &* 300 &+ BRAD_PI)
		let py2 = ((slerp(frame &* 140) * 80) >> 12) * slerp(i &* 400 &+ BRAD_PI)
		glLine(HALF_WIDTH + (px >> 12), HALF_HEIGHT + (py >> 12),
		       HALF_WIDTH + (px2 >> 12), HALF_HEIGHT + (py2 >> 12), rgb15(red, green, blue))
		glLine(HALF_WIDTH + (py2 >> 12), HALF_HEIGHT + (px >> 12),
		       HALF_WIDTH + (py >> 12), HALF_HEIGHT + (px2 >> 12), rgb15(green, blue, red))
		i += 32
	}
	glEnd2D()
}

func pixels(_ frame: Int32) {
	let radius = 40 + (abs(slerp(frame &* 20) * 80) >> 12)
	let red = abs(slerp(frame &* 220) * 31) >> 12
	let green = abs(slerp(frame &* 140) * 31) >> 12
	let blue = abs(slerp(frame &* 40) * 31) >> 12
	let i = (frame &* 140) & 32767

	glBegin2D()
	for angle in stride(from: 0, to: BRAD_PI * 2, by: 64) {
		let a2 = angle + i
		var x = clerp(angle &* 2) * radius
		var y = slerp(x / 32 + a2) * radius
		x = clerp(y / 64 + angle) * (radius + 20)
		y = slerp(x / 64 + a2) * radius
		let x2 = -y
		let y2 = x
		glPutPixel(HALF_WIDTH + (x >> 12), HALF_HEIGHT + (y >> 12), rgb15(red, green, blue))
		glPutPixel(HALF_WIDTH + (x2 >> 12), HALF_HEIGHT + (y2 >> 12), rgb15(green, blue, red))
	}
	glEnd2D()
}

videoSetMode(MODE_5_3D.rawValue)
videoSetModeSub(MODE_5_2D.rawValue)

nds_init_sub_sprites_grid()              // OAM grid that displays the captured image
bgInitSub(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0)

glScreen2D()

var frame: Int32 = 0
var demonum = 0

while pmMainLoop() {
	frame += 1

	scanKeys()
	let key = keysDown()
	if key & KEY_DOWN != 0 || key & KEY_RIGHT != 0 { demonum = (demonum + 1) % 3 }
	if key & KEY_UP != 0 || key & KEY_LEFT != 0 { demonum -= 1; if demonum < 0 { demonum = 2 } }

	while nds_dispcap_busy() != 0 {}   // wait for the capture unit

	// alternate which screen shows the live 3D render each frame
	if frame & 1 == 0 {
		lcdMainOnBottom()
		vramSetBankC(VRAM_C_LCD)
		vramSetBankD(VRAM_D_SUB_SPRITE)
		nds_dispcap_to_bank(2)
	} else {
		lcdMainOnTop()
		vramSetBankD(VRAM_D_LCD)
		vramSetBankC(VRAM_C_SUB_BG)
		nds_dispcap_to_bank(3)
	}

	let even = frame & 1 == 0
	switch demonum {
	case 0: even ? pixels(frame) : lines(frame)
	case 1: even ? lines(frame) : pixels(frame)
	case 2: even ? simple(frame) : lines(frame)
	default: even ? pixels(frame) : lines(frame)
	}

	glFlush(0)
	threadWaitForVBlank()
	if keysDown() & KEY_START != 0 { break }
}
