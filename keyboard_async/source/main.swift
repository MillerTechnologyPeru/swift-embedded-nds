//---------------------------------------------------------------------------------
//
//  Swift port of the libnds keyboard_async example.
//
//  Polls the on-screen keyboard each frame with keyboardUpdate and echoes keys.
//
//---------------------------------------------------------------------------------

import CNDS

consoleDemoInit()   // setup the sub screen for printing

keyboardDemoInit()
keyboardShow()

while pmMainLoop() {
	let key = keyboardUpdate()

	if key > 0 {
		nds_printf_1i("%c", key)
	}

	threadWaitForVBlank()
	scanKeys()

	if keysDown() & KEY_START != 0 { break }
}
