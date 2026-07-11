//---------------------------------------------------------------------------------
//
//  Swift port of the libnds console_windows example.
//
//  Two consoles backed by the same map, each confined to a different window;
//  touching the left/right half of the screen prints into that window.
//
//---------------------------------------------------------------------------------

import NDS

let border =
	"------------" +
	"|          |" + "|          |" + "|          |" + "|          |" +
	"|          |" + "|          |" + "|          |" + "|          |" +
	"|          |" + "|          |" + "|          |" + "|          |" +
	"|          |" + "|          |" +
	"------------"

var touch = touchPosition()

// consoleDemoInit returns a pointer to the demo console; copy it for the second.
let left = Console.demoInit()!
var right = left.pointee

Console.setWindow(left, x: 15, y: 1, width: 12, height: 16)
Console.setWindow(&right, x: 1, y: 1, width: 12, height: 16)

Console.select(left)
Console.print(border)
Console.select(&right)
Console.print(border)

Console.setWindow(left, x: 2, y: 2, width: 10, height: 14)
Console.setWindow(&right, x: 16, y: 2, width: 10, height: 14)

while System.mainLoop {
	Keys.scan()

	if Keys.held.contains(.start) { break }

	if Touch.read(into: &touch) {
		if touch.px < 128 {
			Console.select(left)
		} else {
			Console.select(&right)
		}

		Console.printf("\nT: %i", Int32(touch.px))
	}

	System.waitForVBlank()
}
