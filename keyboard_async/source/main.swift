//---------------------------------------------------------------------------------
//
//  Swift port of the libnds keyboard_async example.
//
//  Polls the on-screen keyboard each frame with keyboardUpdate and echoes keys.
//
//---------------------------------------------------------------------------------

import NDS

Console.demoInit()   // setup the sub screen for printing

OnScreenKeyboard.demoInit()
OnScreenKeyboard.show()

while System.mainLoop {
	let key = OnScreenKeyboard.update()

	if key > 0 {
		Console.printf("%c", key)
	}

	System.waitForVBlank()
	Keys.scan()

	if Keys.down.contains(.start) { break }
}
