//---------------------------------------------------------------------------------
//
//  Swift port of the libnds keyboard_stdin example.
//
//  Brings up the on-screen keyboard, echoes key presses, and reads a name from
//  stdin with iscanf.
//
//---------------------------------------------------------------------------------

import CNDS

// Called by libnds for each key press. Non-capturing, so it bridges to the
// C `void (*)(int)` function-pointer field on the Keyboard struct.
private func onKeyPressed(_ key: Int32) {
	if key > 0 {
		nds_printf_1i("%c", key)
	}
}

consoleDemoInit()

let kbd = keyboardDemoInit()!
kbd.pointee.OnKeyPressed = onKeyPressed

var askname = true

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()

	let keys = keysDown()
	if keys & KEY_START != 0 {
		break
	} else if keys != 0 {
		askname = true
	}

	if askname {
		var myName = [CChar](repeating: 0, count: 256)

		consoleClear()
		nds_puts("What is your name?\n")
		myName.withUnsafeMutableBufferPointer { nds_scanf_str($0.baseAddress!) }

		nds_puts("\nHello ")
		myName.withUnsafeBufferPointer { nds_puts($0.baseAddress!) }
		askname = false
	}
}
