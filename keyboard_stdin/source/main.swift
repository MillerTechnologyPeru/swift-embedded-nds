//---------------------------------------------------------------------------------
//
//  Swift port of the libnds keyboard_stdin example.
//
//  Brings up the on-screen keyboard, echoes key presses, and reads a name from
//  stdin with iscanf.
//
//---------------------------------------------------------------------------------

import NDS

// Called by libnds for each key press. Non-capturing, so it bridges to the
// C `void (*)(int)` function-pointer field on the Keyboard struct.
private func onKeyPressed(_ key: Int32) {
	if key > 0 {
		Console.printf("%c", key)
	}
}

Console.demoInit()

let kbd = OnScreenKeyboard.demoInit()!
kbd.pointee.OnKeyPressed = onKeyPressed

var askname = true

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()

	let keys = Keys.down
	if keys.contains(.start) {
		break
	} else if !keys.isEmpty {
		askname = true
	}

	if askname {
		var myName = [CChar](repeating: 0, count: 256)

		Console.clear()
		Console.print("What is your name?\n")
		myName.withUnsafeMutableBufferPointer { Console.scanString(into: $0.baseAddress!) }

		Console.print("\nHello ")
		myName.withUnsafeBufferPointer { Console.print($0.baseAddress!) }
		askname = false
	}
}
