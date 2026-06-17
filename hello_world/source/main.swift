//---------------------------------------------------------------------------------
//
//  Simple console print demo -- Swift port of the libnds hello_world example.
//  Original C++ by dovoto.
//
//---------------------------------------------------------------------------------

import CNDS

// Updated from inside the VBlank IRQ handler, so it must be globally mutable.
private var frame: Int32 = 0

//---------------------------------------------------------------------------------
// VBlank interrupt handler. This runs in IRQ mode -- be careful!
//
// A non-capturing top-level Swift function bridges automatically to the
// C `void (*)(void)` function pointer that irqSet() expects.
//---------------------------------------------------------------------------------
private func vblank() {
	frame += 1
}

// In a file named main.swift, top-level code is the program entry point, so
// there is no need for @main (which can't coexist with top-level statements).
var touchXY = touchPosition()

irqSet(IRQ_VBLANK, vblank)

consoleDemoInit()

nds_puts("      Hello DS dev'rs\n")
nds_puts("     \u{1b}[32mwww.devkitpro.org\n")
nds_puts("   \u{1b}[32;1mwww.drunkencoders.com\u{1b}[39m")

// swiWaitForVBlank is a macro alias for this inline function in modern libnds.
while pmMainLoop() {

	threadWaitForVBlank()
	scanKeys()
	let keys = keysDown()
	if keys & KEY_START != 0 { break }

	touchRead(&touchXY)

	// print using the ansi escape sequence \x1b[line;columnH
	nds_printf_1i("\u{1b}[10;0HFrame = %d", frame)
	nds_printf_2i("\u{1b}[16;0HTouch x = %04X, %04X\n",
	              Int32(touchXY.rawx), Int32(touchXY.px))
	nds_printf_2i("Touch y = %04X, %04X\n",
	              Int32(touchXY.rawy), Int32(touchXY.py))
}
