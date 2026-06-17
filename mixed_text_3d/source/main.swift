//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Mixed_Text_3D example.
//
//  Renders a rotating NeHe triangle + quad on the 3D engine while a text console
//  shares the same screen on a higher-priority background.
//
//---------------------------------------------------------------------------------

import CNDS

var rtri: Float = 0
var rquad: Float = 0

func drawGLScene() {
	glLoadIdentity()
	glTranslatef(-1.5, 0.0, -6.0)
	glRotatef(rtri, 0.0, 1.0, 0.0)
	glColor3f(1, 1, 1)
	glBegin(GL_TRIANGLES)
		glColor3f(1.0, 0.0, 0.0)
		glVertex3f(0.0, 1.0, 0.0)
		glColor3f(0.0, 1.0, 0.0)
		glVertex3f(-1.0, -1.0, 0.0)
		glColor3f(0.0, 0.0, 1.0)
		glVertex3f(1.0, -1.0, 0.0)
	glEnd()
	glLoadIdentity()
	glTranslatef(1.5, 0.0, -6.0)
	glRotatef(rquad, 1.0, 0.0, 0.0)
	glColor3f(0.5, 0.5, 1.0)
	glBegin(GL_QUADS)
		glVertex3f(-1.0, 1.0, 0.0)
		glVertex3f(1.0, 1.0, 0.0)
		glVertex3f(1.0, -1.0, 0.0)
		glVertex3f(-1.0, -1.0, 0.0)
	glEnd()
}

glInit()
videoSetMode(MODE_0_3D.rawValue)

// map some vram to background for printing
vramSetBankC(VRAM_C_MAIN_BG_0x06000000)
consoleInit(nil, 1, BgType_Text4bpp, BgSize_T_256x256, 31, 0, true, true)

// put bg 0 (the 3D layer) below the text background
bgSetPriority(0, 1)

glEnable(Int32(GL_ANTIALIAS.rawValue))
glClearColor(0, 0, 0, 31)
glClearPolyID(63)
glClearDepth(0x7FFF)
glViewport(0, 0, 255, 191)

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, 256.0 / 192.0, 0.1, 100)

glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
glMatrixMode(GL_MODELVIEW)

nds_puts("      Hello DS World\n")
nds_puts("     www.devkitpro.org\n")
nds_puts("   www.drunkencoders.com\n")

while pmMainLoop() {
	drawGLScene()
	glFlush(0)
	threadWaitForVBlank()

	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	nds_printf_1f("\u{1b}[15;5H rtri  = %f     \n", Double(rtri))
	nds_printf_1f("\u{1b}[16;5H rquad = %f     \n", Double(rquad))
	rtri += 0.9
	rquad -= 0.75
	rtri = rtri.truncatingRemainder(dividingBy: 360)
	rquad = rquad.truncatingRemainder(dividingBy: 360)
}
