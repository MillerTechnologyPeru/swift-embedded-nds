//---------------------------------------------------------------------------------
//
//  Swift port of the libnds 3D_Both_Screens example.
//
//  Renders a spinning cube on the top screen and a pyramid on the bottom by
//  alternating the live 3D output between screens each frame via display capture
//  (the other screen shows the captured image through a grid of bitmap sprites).
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func degreesToAngle(_ d: Int32) -> Int32 { d * (1 << 15) / 360 }
@inline(__always) func inttof32(_ n: Int32) -> Int32 { n << 12 }

var angle: Int32 = 0

func renderCube(_ angle: Int32) {
	glPushMatrix()
	glTranslatef(0, 0, -4)
	glRotatef32i(degreesToAngle(angle), inttof32(1), inttof32(1), inttof32(1))
	glBegin(GL_QUADS)
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
		glColor3b(c.0, c.1, c.2)
		glVertex3f(v.0, v.1, v.2)
	}
	glEnd()
	glPopMatrix(1)
}

func renderPyramid(_ angle: Int32) {
	glPushMatrix()
	glTranslatef(0, 0, -4)
	glRotatef32i(degreesToAngle(angle), inttof32(1), inttof32(1), inttof32(1))
	glBegin(GL_QUADS)
		glColor3b(255, 0, 0); glVertex3f(-1, -1, 1)
		glColor3b(0, 255, 0); glVertex3f(1, -1, 1)
		glColor3b(0, 0, 255); glVertex3f(1, -1, -1)
		glColor3b(255, 255, 0); glVertex3f(-1, -1, -1)
	glEnd()
	glBegin(GL_TRIANGLES)
	let tris: [(Float, Float, Float)] = [
		(0, 1, 0), (-1, -1, 1), (1, -1, 1),
		(0, 1, 0), (-1, -1, -1), (1, -1, -1),
		(0, 1, 0), (-1, -1, 1), (-1, -1, -1),
		(0, 1, 0), (1, -1, 1), (1, -1, -1),
	]
	let cols: [(UInt8, UInt8, UInt8)] = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
	for (i, v) in tris.enumerated() {
		let c = cols[i % 3]
		glColor3b(c.0, c.1, c.2)
		glVertex3f(v.0, v.1, v.2)
	}
	glEnd()
	glPopMatrix(1)
}

func renderScene(_ top: Bool) {
	if top { renderCube(angle) } else { renderPyramid(angle) }
	angle += 1
}

videoSetMode(MODE_0_3D.rawValue)
videoSetModeSub(MODE_5_2D.rawValue)
glInit()
nds_init_sub_sprites_grid()
bgInitSub(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0)

glEnable(Int32(GL_ANTIALIAS.rawValue))
glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glViewport(0, 0, 255, 191)
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 100)
glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

var top = true

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	while nds_dispcap_busy() != 0 {}
	top.toggle()
	if top {
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

	renderScene(top)
	glFlush(0)
}
