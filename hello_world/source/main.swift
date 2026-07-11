//---------------------------------------------------------------------------------
//
//  Simple console print demo -- Swift port of the libnds hello_world example.
//  Original C++ by dovoto.
//
//  This version uses the idiomatic `NDS` overlay (the Swift package) instead of
//  raw `import CNDS`. `import NDS` still re-exports the raw libnds API, so the
//  two styles can be mixed freely.
//
//---------------------------------------------------------------------------------

import NDS

// Updated from inside the VBlank IRQ handler, so it must be globally mutable.
private var frame: Int32 = 0

//---------------------------------------------------------------------------------
// VBlank interrupt handler. This runs in IRQ mode -- be careful!
//
// A non-capturing top-level Swift function bridges automatically to the
// C `void (*)(void)` function pointer that IRQ.set() expects.
//---------------------------------------------------------------------------------
private func vblank() {
	frame += 1
}

// In a file named main.swift, top-level code is the program entry point, so
// there is no need for @main (which can't coexist with top-level statements).
var touchXY = touchPosition()

IRQ.vblank.set(vblank)

Console.demoInit()

Console.print("      Hello DS dev'rs\n")
Console.print("     \u{1b}[32mwww.devkitpro.org\n")
Console.print("   \u{1b}[32;1mwww.drunkencoders.com\u{1b}[39m")

while System.mainLoop {

	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }

	_ = Touch.read(into: &touchXY)

	// print using the ansi escape sequence \x1b[line;columnH
	Console.printf("\u{1b}[10;0HFrame = %d", frame)
	Console.printf("\u{1b}[16;0HTouch x = %04X, %04X\n",
	               Int32(touchXY.rawx), Int32(touchXY.px))
	Console.printf("Touch y = %04X, %04X\n",
	               Int32(touchXY.rawy), Int32(touchXY.py))
}
