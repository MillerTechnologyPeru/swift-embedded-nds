//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Mixed_Text_3D example.
//
//  Renders a rotating NeHe triangle + quad on the 3D engine while a text console
//  shares the same screen on a higher-priority background.
//
//---------------------------------------------------------------------------------

import NDS

var rtri: Float = 0
var rquad: Float = 0

func drawGLScene() {
	GL.loadIdentity()
	GL.translate(-1.5, 0.0, -6.0)
	GL.rotate(rtri, 0.0, 1.0, 0.0)
	GL.color(1, 1, 1)
	GL.begin(.triangles)
		GL.color(1.0, 0.0, 0.0)
		GL.vertex(0.0, 1.0, 0.0)
		GL.color(0.0, 1.0, 0.0)
		GL.vertex(-1.0, -1.0, 0.0)
		GL.color(0.0, 0.0, 1.0)
		GL.vertex(1.0, -1.0, 0.0)
	GL.end()
	GL.loadIdentity()
	GL.translate(1.5, 0.0, -6.0)
	GL.rotate(rquad, 1.0, 0.0, 0.0)
	GL.color(0.5, 0.5, 1.0)
	GL.begin(.quads)
		GL.vertex(-1.0, 1.0, 0.0)
		GL.vertex(1.0, 1.0, 0.0)
		GL.vertex(1.0, -1.0, 0.0)
		GL.vertex(-1.0, -1.0, 0.0)
	GL.end()
}

GL.initialize()
Video.setMode(.mode0_3D)

// map some vram to background for printing
Video.setBankC(VRAM_C_MAIN_BG_0x06000000)
Console.initialize(nil, layer: 1, kind: .text4bpp, size: BgSize_T_256x256, mapBase: 31, tileBase: 0, mainDisplay: true)

// put bg 0 (the 3D layer) below the text background
Background(id: 0).priority = 1

GL.enable(Int32(GL_ANTIALIAS.rawValue))
GL.clearColor(r: 0, g: 0, b: 0, a: 31)
GL.clearPolyID(63)
GL.clearDepth(0x7FFF)
GL.viewport(0, 0, 255, 191)

GL.matrixMode(.projection)
GL.loadIdentity()
GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)

GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))
GL.matrixMode(.modelview)

Console.print("      Hello DS World\n")
Console.print("     www.devkitpro.org\n")
Console.print("   www.drunkencoders.com\n")

while System.mainLoop {
	drawGLScene()
	GL.flush()
	System.waitForVBlank()

	Keys.scan()
	if Keys.down.contains(.start) { break }

	Console.printf("\u{1b}[15;5H rtri  = %f     \n", Double(rtri))
	Console.printf("\u{1b}[16;5H rquad = %f     \n", Double(rquad))
	rtri += 0.9
	rquad -= 0.75
	rtri = rtri.truncatingRemainder(dividingBy: 360)
	rquad = rquad.truncatingRemainder(dividingBy: 360)
}
