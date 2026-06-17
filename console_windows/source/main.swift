//---------------------------------------------------------------------------------
//
//  Swift port of the libnds console_windows example.
//
//  Two consoles backed by the same map, each confined to a different window;
//  touching the left/right half of the screen prints into that window.
//
//---------------------------------------------------------------------------------

import CNDS

let border =
	"------------" +
	"|          |" + "|          |" + "|          |" + "|          |" +
	"|          |" + "|          |" + "|          |" + "|          |" +
	"|          |" + "|          |" + "|          |" + "|          |" +
	"|          |" + "|          |" +
	"------------"

var touch = touchPosition()

// consoleDemoInit returns a pointer to the demo console; copy it for the second.
let left = consoleDemoInit()!
var right = left.pointee

consoleSetWindow(left, 15, 1, 12, 16)
consoleSetWindow(&right, 1, 1, 12, 16)

consoleSelect(left)
nds_puts(border)
consoleSelect(&right)
nds_puts(border)

consoleSetWindow(left, 2, 2, 10, 14)
consoleSetWindow(&right, 16, 2, 10, 14)

while pmMainLoop() {
	scanKeys()

	if keysHeld() & KEY_START != 0 { break }

	if touchRead(&touch) {
		if touch.px < 128 {
			consoleSelect(left)
		} else {
			consoleSelect(&right)
		}

		nds_printf_1i("\nT: %i", Int32(touch.px))
	}

	threadWaitForVBlank()
}
